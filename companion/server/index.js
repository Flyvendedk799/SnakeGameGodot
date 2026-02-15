import express from 'express';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const PORT = process.env.PORT || 3000;

const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function makeCode() { return Array.from({length:6}, () => CHARS[Math.floor(Math.random()*CHARS.length)]).join(''); }
function makeToken() { return Array.from({length:12}, () => CHARS[Math.floor(Math.random()*CHARS.length)]).join(''); }

const sessions = new Map();
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

app.use(express.static(path.join(__dirname, 'client')));

app.get('/health', (req, res) => res.json({ ok: true }));

app.get('/session/create', (req, res) => {
  let code;
  do { code = makeCode(); } while (sessions.has(code));
  const token = makeToken();
  sessions.set(code, {
    game: null,
    companion: null,
    createdAt: Date.now(),
    dropsThisWave: 0,
    suppliesThisWave: 0,
    radarsThisWave: 0,
    empsThisWave: 0,
    gameState: 'wave_active',
    lastDropAt: 0,
    lastSupplyAt: 0,
    lastRadarAt: 0,
    lastEmpAt: 0,
    reconnectToken: token
  });
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

function abilityStateForSession(s, ability, now) {
  if (!s) {
    return { remainingThisWave: 0, retryInMs: 0 };
  }

  const remainingThisWave = ability === 'bomb'
    ? Math.max(0, BOMBS_PER_WAVE - s.dropsThisWave)
    : ability === 'supply'
      ? Math.max(0, SUPPLIES_PER_WAVE - s.suppliesThisWave)
      : Math.max(0, RADAR_PER_WAVE - s.radarsThisWave);

  const cooldownMs = ability === 'bomb'
    ? COOLDOWN_BOMB_MS
    : ability === 'supply'
      ? COOLDOWN_SUPPLY_MS
      : COOLDOWN_RADAR_MS;

  const lastAt = ability === 'bomb'
    ? s.lastDropAt
    : ability === 'supply'
      ? s.lastSupplyAt
      : s.lastRadarAt;

  const retryInMs = Math.max(0, cooldownMs - (now - lastAt));
  return { remainingThisWave, retryInMs };
}

function sendAbilityReject(ws, s, ability, reason, now) {
  const { remainingThisWave, retryInMs } = abilityStateForSession(s, ability, now);
  safeSend(ws, {
    type: 'ability_reject',
    ability,
    reason,
    retry_in_ms: retryInMs,
    remaining_this_wave: remainingThisWave
  });
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
        let s = sessions.get(code);
        if (!s) {
          safeSend(ws, { type: 'error', message: 'Invalid code' });
          return;
        }
        if (now - s.createdAt > SESSION_EXPIRY_MS) {
          sessions.delete(code);
          safeSend(ws, { type: 'error', message: 'Session expired' });
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
        let foundSession = null;
        let foundCode = null;
        for (const [code, s] of sessions.entries()) {
          if (s.reconnectToken === token) {
            foundSession = s;
            foundCode = code;
            break;
          }
        }
        if (!foundSession) {
          safeSend(ws, { type: 'error', message: 'Invalid token' });
          return;
        }
        if (now - foundSession.createdAt > SESSION_EXPIRY_MS) {
          sessions.delete(foundCode);
          safeSend(ws, { type: 'error', message: 'Session expired' });
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
        const s = sessions.get(ws.code);
        if (!s || !s.game) {
          sendAbilityReject(ws, s, 'bomb', 'no_game_connected', now);
          return;
        }
        if (s.gameState && s.gameState !== 'wave_active') {
          sendAbilityReject(ws, s, 'bomb', 'invalid_state', now);
          return;
        }
        if (s.dropsThisWave >= BOMBS_PER_WAVE) {
          sendAbilityReject(ws, s, 'bomb', 'wave_limit', now);
          return;
        }
        if ((now - s.lastDropAt) < COOLDOWN_BOMB_MS) {
          sendAbilityReject(ws, s, 'bomb', 'cooldown', now);
          return;
        }
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.dropsThisWave++;
        s.lastDropAt = now;
        safeSend(s.game, { type: 'bomb_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'bomb', remaining: BOMBS_PER_WAVE - s.dropsThisWave });
      } else if (t === 'supply_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) {
          sendAbilityReject(ws, s, 'supply', 'no_game_connected', now);
          return;
        }
        if (s.gameState && s.gameState !== 'wave_active') {
          sendAbilityReject(ws, s, 'supply', 'invalid_state', now);
          return;
        }
        if (s.suppliesThisWave >= SUPPLIES_PER_WAVE) {
          sendAbilityReject(ws, s, 'supply', 'wave_limit', now);
          return;
        }
        if ((now - s.lastSupplyAt) < COOLDOWN_SUPPLY_MS) {
          sendAbilityReject(ws, s, 'supply', 'cooldown', now);
          return;
        }
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.suppliesThisWave++;
        s.lastSupplyAt = now;
        safeSend(s.game, { type: 'supply_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'supply', remaining: SUPPLIES_PER_WAVE - s.suppliesThisWave });
      } else if (t === 'chopper_input' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        const x = Math.max(-1, Math.min(1, Number(msg.x) ?? 0));
        const y = Math.max(-1, Math.min(1, Number(msg.y) ?? 0));
        safeSend(s.game, { type: 'chopper_input', x, y });
      } else if (t === 'radar_ping' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) {
          sendAbilityReject(ws, s, 'radar', 'no_game_connected', now);
          return;
        }
        if (s.gameState && s.gameState !== 'wave_active') {
          sendAbilityReject(ws, s, 'radar', 'invalid_state', now);
          return;
        }
        if (s.radarsThisWave >= RADAR_PER_WAVE) {
          sendAbilityReject(ws, s, 'radar', 'wave_limit', now);
          return;
        }
        if ((now - s.lastRadarAt) < COOLDOWN_RADAR_MS) {
          sendAbilityReject(ws, s, 'radar', 'cooldown', now);
          return;
        }
        s.radarsThisWave++;
        s.lastRadarAt = now;
        safeSend(s.game, { type: 'radar_ping' });
        safeSend(ws, { type: 'radar_ack', remaining: RADAR_PER_WAVE - s.radarsThisWave });
      } else if (t === 'new_wave' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s) {
          s.dropsThisWave = 0;
          s.suppliesThisWave = 0;
          s.radarsThisWave = 0;
          if (s.companion) safeSend(s.companion, { type: 'new_wave' });
        }
      } else if (t === 'minimap' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          const fwd = { type: 'minimap', enemies: msg.enemies || [], allies: msg.allies || [], players: msg.players || [], wave: msg.wave, state: msg.state, chopper: msg.chopper };
          safeSend(s.companion, fwd);
        }
      } else if (t === 'bomb_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          const kills = msg.kills ?? 0;
          const isMega = kills >= 5;
          safeSend(s.companion, { type: 'bomb_impact', x: msg.x, y: msg.y, kills, mega: isMega });
        }
      } else if (t === 'supply_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) safeSend(s.companion, { type: 'supply_impact', x: msg.x, y: msg.y });
      } else if (t === 'game_state' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s) {
          s.gameState = typeof msg.state === 'string' ? msg.state : s.gameState;
          if (s.companion) safeSend(s.companion, { type: 'game_state', state: msg.state });
        }
      } else if (t === 'ping' && ws.role === 'companion') {
        safeSend(ws, { type: 'pong', timestamp: msg.timestamp });
      }
    } catch (e) { /* ignore malformed */ }
  });
  ws.on('close', () => {
    if (ws.code && ws.role) {
      const s = sessions.get(ws.code);
      if (s) {
        if (ws.role === 'game') s.game = null;
        else if (ws.role === 'companion') s.companion = null;
        if (!s.game && !s.companion) sessions.delete(ws.code);
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
  const now = Date.now();
  for (const [code, s] of sessions.entries()) {
    if (now - s.createdAt > SESSION_EXPIRY_MS) {
      if (s.game) s.game.terminate?.();
      if (s.companion) s.companion.terminate?.();
      sessions.delete(code);
    }
  }
}, 60 * 1000);

wss.on('close', () => {
  clearInterval(heartbeatInterval);
  clearInterval(expiryInterval);
});

server.listen(PORT, () => console.log('Companion server on', PORT));
