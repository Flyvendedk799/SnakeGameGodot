import express from 'express';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import { SessionStore } from './src/session_store.js';
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const PORT = process.env.PORT || 3000;

const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function makeCode() { return Array.from({length:6}, () => CHARS[Math.floor(Math.random()*CHARS.length)]).join(''); }
function makeToken() { return Array.from({length:12}, () => CHARS[Math.floor(Math.random()*CHARS.length)]).join(''); }

const COOLDOWN_BOMB_MS = 30000;
const COOLDOWN_SUPPLY_MS = 45000;
const COOLDOWN_RADAR_MS = 60000;
const COOLDOWN_EMP_MS = 90000;
const BOMBS_PER_WAVE = 2;
const SUPPLIES_PER_WAVE = 1;
const RADAR_PER_WAVE = 1;
const EMP_PER_WAVE = 1;
const MAX_MSG_SIZE = 4096;
const RATE_LIMIT_MSGS = 50;
const RATE_LIMIT_WINDOW_MS = 10000;
const SESSION_EXPIRY_MS = 2 * 60 * 60 * 1000; // 2 hours
const sessions = new SessionStore({ sessionExpiryMs: SESSION_EXPIRY_MS });

app.use(express.static(path.join(__dirname, 'client')));

app.get('/health', (req, res) => res.json({ ok: true }));

app.get('/session/create', (req, res) => {
  let code;
  do { code = makeCode(); } while (sessions.hasCode(code));
  const token = makeToken();
  sessions.create({ code, reconnectToken: token });
  res.json({ code, token });
});

function safeSend(ws, obj) {
  if (!ws || ws.readyState !== 1) return false;
  try {
    const str = JSON.stringify(obj);
    if (str.length > MAX_MSG_SIZE) return false;
    ws.send(str);
    return true;
  } catch (e) { return false; }
}

const server = createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

const HEARTBEAT_MS = 25000;
function heartbeat(ws) { ws.isAlive = true; }
function noop() {}

wss.on('connection', (ws) => {
  ws.role = null;
  ws.code = null;
  ws.isAlive = true;
  ws.msgCount = 0;
  ws.msgWindowStart = Date.now();
  ws.on('pong', () => heartbeat(ws));
  ws.on('message', (raw) => {
    const now = Date.now();
    if (raw.length > MAX_MSG_SIZE) return;
    if (ws.msgWindowStart + RATE_LIMIT_WINDOW_MS < now) {
      ws.msgWindowStart = now;
      ws.msgCount = 0;
    }
    let msg, t;
    try {
      msg = JSON.parse(raw.toString());
      if (typeof msg !== 'object' || msg === null || Array.isArray(msg)) return;
      t = msg.type;
      if (typeof t !== 'string') return;
    } catch (e) { return; }
    if (t !== 'chopper_input' && ++ws.msgCount > RATE_LIMIT_MSGS) return;
    try {
      if (t === 'join' && msg.code && msg.role) {
        const code = String(msg.code).toUpperCase();
        if (code.length !== 6) return;
        const codeLookup = sessions.inspectByCode(code);
        let s = codeLookup.session;
        if (!s) {
          safeSend(ws, { type: 'error', message: codeLookup.expired ? 'Session expired' : 'Invalid code' });
          return;
        }
        ws.role = msg.role === 'game' ? 'game' : msg.role === 'companion' ? 'companion' : null;
        if (!ws.role) return;
        ws.code = code;
        if (ws.role === 'game') s.game = ws;
        else if (ws.role === 'companion') {
          s.companion = ws;
          s.dropsThisWave = 0;
          s.suppliesThisWave = 0;
          s.radarsThisWave = 0;
          s.empsThisWave = 0;
        }
        safeSend(ws, { type: 'joined', code, token: s.reconnectToken });
        if (s.game && s.companion) {
          safeSend(s.game, { type: 'companion_connected' });
          safeSend(s.companion, { type: 'game_connected' });
        }
      } else if (t === 'rejoin' && msg.token && msg.role) {
        // Reconnect with token instead of code
        const token = String(msg.token).toUpperCase();
        if (token.length !== 12) return;
        const tokenLookup = sessions.inspectByToken(token);
        const foundSession = tokenLookup.session;
        const foundCode = foundSession?.code;
        if (!foundSession) {
          safeSend(ws, { type: 'error', message: tokenLookup.expired ? 'Session expired' : 'Invalid token' });
          return;
        }
        ws.role = msg.role === 'game' ? 'game' : msg.role === 'companion' ? 'companion' : null;
        if (!ws.role) return;
        ws.code = foundCode;
        if (ws.role === 'game') foundSession.game = ws;
        else if (ws.role === 'companion') {
          foundSession.companion = ws;
          foundSession.dropsThisWave = 0;
          foundSession.suppliesThisWave = 0;
          foundSession.radarsThisWave = 0;
          foundSession.empsThisWave = 0;
        }
        safeSend(ws, { type: 'joined', code: foundCode, token: foundSession.reconnectToken });
        if (foundSession.game && foundSession.companion) {
          safeSend(foundSession.game, { type: 'companion_connected' });
          safeSend(foundSession.companion, { type: 'game_connected' });
        }
      } else if (t === 'helicopter_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (!s || !s.game) return;
        const dropResult = sessions.consumeAbility(ws.code, {
          perWaveKey: 'dropsThisWave',
          lastAtKey: 'lastDropAt',
          perWaveLimit: BOMBS_PER_WAVE,
          cooldownMs: COOLDOWN_BOMB_MS,
          now
        });
        if (!dropResult.ok) return;
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        safeSend(s.game, { type: 'bomb_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'bomb', remaining: dropResult.remaining });
      } else if (t === 'supply_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (!s || !s.game) return;
        const supplyResult = sessions.consumeAbility(ws.code, {
          perWaveKey: 'suppliesThisWave',
          lastAtKey: 'lastSupplyAt',
          perWaveLimit: SUPPLIES_PER_WAVE,
          cooldownMs: COOLDOWN_SUPPLY_MS,
          now
        });
        if (!supplyResult.ok) return;
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        safeSend(s.game, { type: 'supply_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'supply', remaining: supplyResult.remaining });
      } else if (t === 'chopper_input' && ws.role === 'companion' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (!s || !s.game) return;
        const x = Math.max(-1, Math.min(1, Number(msg.x) ?? 0));
        const y = Math.max(-1, Math.min(1, Number(msg.y) ?? 0));
        safeSend(s.game, { type: 'chopper_input', x, y });
      } else if (t === 'radar_ping' && ws.role === 'companion' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (!s || !s.game) return;
        const radarResult = sessions.consumeAbility(ws.code, {
          perWaveKey: 'radarsThisWave',
          lastAtKey: 'lastRadarAt',
          perWaveLimit: RADAR_PER_WAVE,
          cooldownMs: COOLDOWN_RADAR_MS,
          now
        });
        if (!radarResult.ok) return;
        safeSend(s.game, { type: 'radar_ping' });
        safeSend(ws, { type: 'radar_ack', remaining: radarResult.remaining });
      } else if (t === 'new_wave' && ws.role === 'game' && ws.code) {
        const s = sessions.resetWaveCounters(ws.code);
        if (s) {
          if (s.companion) safeSend(s.companion, { type: 'new_wave' });
        }
      } else if (t === 'minimap' && ws.role === 'game' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (s && s.companion) {
          const fwd = { type: 'minimap', enemies: msg.enemies || [], allies: msg.allies || [], players: msg.players || [], wave: msg.wave, state: msg.state, chopper: msg.chopper };
          safeSend(s.companion, fwd);
        }
      } else if (t === 'bomb_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (s && s.companion) {
          const kills = msg.kills ?? 0;
          const isMega = kills >= 5;
          safeSend(s.companion, { type: 'bomb_impact', x: msg.x, y: msg.y, kills, mega: isMega });
        }
      } else if (t === 'supply_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (s && s.companion) safeSend(s.companion, { type: 'supply_impact', x: msg.x, y: msg.y });
      } else if (t === 'game_state' && ws.role === 'game' && ws.code) {
        const s = sessions.getByCode(ws.code);
        if (s && s.companion) safeSend(s.companion, { type: 'game_state', state: msg.state });
      } else if (t === 'ping' && ws.role === 'companion') {
        if (ws.code && typeof msg.timestamp === 'number') {
          sessions.recordRoundTrip(ws.code, now - msg.timestamp);
        }
        safeSend(ws, { type: 'pong', timestamp: msg.timestamp });
      }
    } catch (e) { /* ignore malformed */ }
  });
  ws.on('close', () => {
    if (ws.code && ws.role) {
      const s = sessions.detachRole(ws.code, ws.role);
      if (s) {
        if (!s.game && !s.companion) sessions.removeByCode(ws.code);
      }
    }
  });
});

const heartbeatInterval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping(noop);
  });
}, HEARTBEAT_MS);

const expiryInterval = setInterval(() => {
  sessions.sweepExpired((s) => {
    if (s.game) s.game.terminate?.();
    if (s.companion) s.companion.terminate?.();
  });
}, 60 * 1000);

wss.on('close', () => {
  clearInterval(heartbeatInterval);
  clearInterval(expiryInterval);
});

server.listen(PORT, () => console.log('Companion server on', PORT));
