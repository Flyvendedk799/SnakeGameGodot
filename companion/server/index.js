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

const sessions = new Map();
const COOLDOWN_BOMB_MS = 30000;
const COOLDOWN_SUPPLY_MS = 45000;
const BOMBS_PER_WAVE = 2;
const SUPPLIES_PER_WAVE = 1;
const MAX_MSG_SIZE = 512;
const RATE_LIMIT_MSGS = 15;
const RATE_LIMIT_WINDOW_MS = 10000;
const SESSION_EXPIRY_MS = 2 * 60 * 60 * 1000; // 2 hours

app.use(express.static(path.join(__dirname, 'client')));

app.get('/health', (req, res) => res.json({ ok: true }));

app.get('/session/create', (req, res) => {
  let code;
  do { code = makeCode(); } while (sessions.has(code));
  sessions.set(code, {
    game: null,
    companion: null,
    createdAt: Date.now(),
    dropsThisWave: 0,
    suppliesThisWave: 0,
    lastDropAt: 0,
    lastSupplyAt: 0
  });
  res.json({ code });
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
    if (++ws.msgCount > RATE_LIMIT_MSGS) return;
    try {
      const msg = JSON.parse(raw.toString());
      if (typeof msg !== 'object' || msg === null) return;
      const t = msg.type;
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
        }
        safeSend(ws, { type: 'joined', code });
        if (s.game) safeSend(s.game, { type: 'companion_connected' });
        if (s.companion) safeSend(s.companion, { type: 'game_connected' });
      } else if (t === 'helicopter_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        if (s.dropsThisWave >= BOMBS_PER_WAVE || (now - s.lastDropAt) < COOLDOWN_BOMB_MS) return;
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.dropsThisWave++;
        s.lastDropAt = now;
        safeSend(s.game, { type: 'bomb_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'bomb', remaining: BOMBS_PER_WAVE - s.dropsThisWave });
      } else if (t === 'supply_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        if (s.suppliesThisWave >= SUPPLIES_PER_WAVE || (now - s.lastSupplyAt) < COOLDOWN_SUPPLY_MS) return;
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.suppliesThisWave++;
        s.lastSupplyAt = now;
        safeSend(s.game, { type: 'supply_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'supply', remaining: SUPPLIES_PER_WAVE - s.suppliesThisWave });
      } else if (t === 'new_wave' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s) {
          s.dropsThisWave = 0;
          s.suppliesThisWave = 0;
          if (s.companion) safeSend(s.companion, { type: 'new_wave' });
        }
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
