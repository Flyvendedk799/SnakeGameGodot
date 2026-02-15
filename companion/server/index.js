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
const CREATE_WINDOW_MS = 60 * 1000;
const CREATE_MAX_PER_IP = 6;
const CREATE_MAX_ACTIVE_SESSIONS_PER_IP = 4;
const MAX_POINT_LIST_ITEMS = 256;

const createAttemptsByIp = new Map();

app.use(express.static(path.join(__dirname, 'client')));

app.get('/health', (req, res) => res.json({ ok: true }));

function getClientIp(req) {
  const fwd = req.headers['x-forwarded-for'];
  if (typeof fwd === 'string' && fwd.trim()) return fwd.split(',')[0].trim();
  return req.socket?.remoteAddress || 'unknown';
}

function logEvent(reason, details = {}) {
  console.warn(JSON.stringify({ level: 'warn', event: 'companion_server_reject', reason, at: Date.now(), ...details }));
}

function cleanupCreateAttempts(now) {
  for (const [ip, entries] of createAttemptsByIp.entries()) {
    const fresh = entries.filter((ts) => now - ts <= CREATE_WINDOW_MS);
    if (fresh.length) createAttemptsByIp.set(ip, fresh);
    else createAttemptsByIp.delete(ip);
  }
}

function cleanupExpiredSessions(now) {
  for (const [code, s] of sessions.entries()) {
    if (now - s.createdAt > SESSION_EXPIRY_MS) sessions.delete(code);
  }
}

function sendClientError(ws, code = 'request_rejected') {
  safeSend(ws, { type: 'error', code });
}

app.get('/session/create', (req, res) => {
  const now = Date.now();
  const ip = getClientIp(req);
  cleanupCreateAttempts(now);
  cleanupExpiredSessions(now);

  const attempts = createAttemptsByIp.get(ip) || [];
  const recentAttempts = attempts.filter((ts) => now - ts <= CREATE_WINDOW_MS);
  if (recentAttempts.length >= CREATE_MAX_PER_IP) {
    logEvent('session_create_rate_limited', { ip, recentAttempts: recentAttempts.length });
    res.status(429).json({ error: 'rate_limited' });
    return;
  }
  const activeSessions = Array.from(sessions.values()).filter((s) => s.ownerIp === ip).length;
  if (activeSessions >= CREATE_MAX_ACTIVE_SESSIONS_PER_IP) {
    logEvent('session_create_active_limit', { ip, activeSessions });
    res.status(429).json({ error: 'rate_limited' });
    return;
  }

  recentAttempts.push(now);
  createAttemptsByIp.set(ip, recentAttempts);

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
    lastDropAt: 0,
    lastSupplyAt: 0,
    lastRadarAt: 0,
    lastEmpAt: 0,
    reconnectToken: token,
    ownerIp: ip,
    burstBuckets: {
      bomb: [],
      supply: [],
      radar: [],
      emp: []
    }
  });
  res.json({ code, token });
});

function isObject(v) { return typeof v === 'object' && v !== null && !Array.isArray(v); }
function hasOnlyKeys(obj, allowed) {
  const keys = Object.keys(obj);
  return keys.length === allowed.length && keys.every((k) => allowed.includes(k));
}
function parseBoundedNumber(v, min, max) {
  if (typeof v !== 'number' || !Number.isFinite(v)) return null;
  if (v < min || v > max) return null;
  return v;
}
function parseBoundedInt(v, min, max) {
  if (typeof v !== 'number' || !Number.isInteger(v)) return null;
  if (v < min || v > max) return null;
  return v;
}
function parsePoint(v) {
  if (!Array.isArray(v) || v.length !== 2) return null;
  const x = parseBoundedNumber(v[0], 0, 1);
  const y = parseBoundedNumber(v[1], 0, 1);
  if (x === null || y === null) return null;
  return [x, y];
}
function parsePointList(v, maxItems = MAX_POINT_LIST_ITEMS) {
  if (!Array.isArray(v) || v.length > maxItems) return null;
  const parsed = [];
  for (const item of v) {
    const p = parsePoint(item);
    if (!p) return null;
    parsed.push(p);
  }
  return parsed;
}

function parseInboundMessage(msg) {
  if (!isObject(msg) || typeof msg.type !== 'string') return null;
  switch (msg.type) {
    case 'join': {
      if (!hasOnlyKeys(msg, ['type', 'code', 'role'])) return null;
      if (typeof msg.code !== 'string' || !/^[A-Z2-9]{6}$/.test(msg.code.toUpperCase())) return null;
      if (msg.role !== 'game' && msg.role !== 'companion') return null;
      return { type: 'join', code: msg.code.toUpperCase(), role: msg.role };
    }
    case 'rejoin': {
      if (!hasOnlyKeys(msg, ['type', 'token', 'role'])) return null;
      if (typeof msg.token !== 'string' || !/^[A-Z2-9]{12}$/.test(msg.token.toUpperCase())) return null;
      if (msg.role !== 'game' && msg.role !== 'companion') return null;
      return { type: 'rejoin', token: msg.token.toUpperCase(), role: msg.role };
    }
    case 'helicopter_drop':
    case 'supply_drop':
    case 'emp_drop': {
      if (!hasOnlyKeys(msg, ['type', 'x', 'y'])) return null;
      const x = parseBoundedNumber(msg.x, 0, 1);
      const y = parseBoundedNumber(msg.y, 0, 1);
      if (x === null || y === null) return null;
      return { type: msg.type, x, y };
    }
    case 'chopper_input': {
      if (!hasOnlyKeys(msg, ['type', 'x', 'y'])) return null;
      const x = parseBoundedNumber(msg.x, -1, 1);
      const y = parseBoundedNumber(msg.y, -1, 1);
      if (x === null || y === null) return null;
      return { type: 'chopper_input', x, y };
    }
    case 'radar_ping':
    case 'new_wave':
      if (!hasOnlyKeys(msg, ['type'])) return null;
      return { type: msg.type };
    case 'minimap': {
      const keys = ['type', 'enemies', 'allies', 'players', 'wave', 'state', 'chopper'];
      if (!Object.keys(msg).every((k) => keys.includes(k))) return null;
      const enemies = parsePointList(msg.enemies ?? []);
      const allies = parsePointList(msg.allies ?? []);
      const players = parsePointList(msg.players ?? []);
      if (!enemies || !allies || !players) return null;
      if (msg.wave !== undefined && parseBoundedInt(msg.wave, 0, 9999) === null) return null;
      if (msg.state !== undefined && typeof msg.state !== 'string') return null;
      if (msg.chopper !== undefined && parsePoint(msg.chopper) === null) return null;
      return { type: 'minimap', enemies, allies, players, wave: msg.wave, state: msg.state, chopper: msg.chopper };
    }
    case 'bomb_impact': {
      if (!hasOnlyKeys(msg, ['type', 'x', 'y', 'kills'])) return null;
      const x = parseBoundedNumber(msg.x, 0, 1);
      const y = parseBoundedNumber(msg.y, 0, 1);
      const kills = parseBoundedInt(msg.kills, 0, 999);
      if (x === null || y === null || kills === null) return null;
      return { type: 'bomb_impact', x, y, kills };
    }
    case 'supply_impact': {
      if (!hasOnlyKeys(msg, ['type', 'x', 'y'])) return null;
      const x = parseBoundedNumber(msg.x, 0, 1);
      const y = parseBoundedNumber(msg.y, 0, 1);
      if (x === null || y === null) return null;
      return { type: 'supply_impact', x, y };
    }
    case 'game_state': {
      if (!hasOnlyKeys(msg, ['type', 'state'])) return null;
      if (typeof msg.state !== 'string' || msg.state.length < 1 || msg.state.length > 64) return null;
      return { type: 'game_state', state: msg.state };
    }
    case 'ping': {
      if (!hasOnlyKeys(msg, ['type', 'timestamp'])) return null;
      if (parseBoundedInt(msg.timestamp, 0, Number.MAX_SAFE_INTEGER) === null) return null;
      return { type: 'ping', timestamp: msg.timestamp };
    }
    default:
      return null;
  }
}

const ABILITY_LIMITS = {
  bomb: { countKey: 'dropsThisWave', lastKey: 'lastDropAt', maxPerWave: BOMBS_PER_WAVE, cooldownMs: COOLDOWN_BOMB_MS, burstWindowMs: 10000, burstMax: 1 },
  supply: { countKey: 'suppliesThisWave', lastKey: 'lastSupplyAt', maxPerWave: SUPPLIES_PER_WAVE, cooldownMs: COOLDOWN_SUPPLY_MS, burstWindowMs: 10000, burstMax: 1 },
  radar: { countKey: 'radarsThisWave', lastKey: 'lastRadarAt', maxPerWave: RADAR_PER_WAVE, cooldownMs: COOLDOWN_RADAR_MS, burstWindowMs: 10000, burstMax: 1 },
  emp: { countKey: 'empsThisWave', lastKey: 'lastEmpAt', maxPerWave: EMP_PER_WAVE, cooldownMs: COOLDOWN_EMP_MS, burstWindowMs: 10000, burstMax: 1 }
};

function tryConsumeAbility(s, ability, now) {
  const cfg = ABILITY_LIMITS[ability];
  if (!cfg) return { ok: false, reason: 'unknown_ability' };
  if (s[cfg.countKey] >= cfg.maxPerWave) return { ok: false, reason: 'wave_budget_exhausted' };
  if ((now - s[cfg.lastKey]) < cfg.cooldownMs) return { ok: false, reason: 'cooldown_active' };
  const bucket = (s.burstBuckets?.[ability] || []).filter((ts) => now - ts <= cfg.burstWindowMs);
  if (bucket.length >= cfg.burstMax) return { ok: false, reason: 'burst_limit' };
  bucket.push(now);
  s.burstBuckets[ability] = bucket;
  s[cfg.countKey]++;
  s[cfg.lastKey] = now;
  return { ok: true, remaining: cfg.maxPerWave - s[cfg.countKey] };
}

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
    if (raw.length > MAX_MSG_SIZE) {
      logEvent('ws_message_too_large', { role: ws.role, code: ws.code, size: raw.length });
      return;
    }
    if (ws.msgWindowStart + RATE_LIMIT_WINDOW_MS < now) {
      ws.msgWindowStart = now;
      ws.msgCount = 0;
    }
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch (e) {
      logEvent('ws_json_parse_failed', { role: ws.role, code: ws.code });
      return;
    }
    const parsed = parseInboundMessage(msg);
    if (!parsed) {
      logEvent('ws_schema_invalid', { role: ws.role, code: ws.code });
      sendClientError(ws);
      return;
    }
    const t = parsed.type;
    if (t !== 'chopper_input' && ++ws.msgCount > RATE_LIMIT_MSGS) {
      logEvent('ws_rate_limited', { role: ws.role, code: ws.code });
      return;
    }
    try {
      if (t === 'join') {
        const code = parsed.code;
        let s = sessions.get(code);
        if (!s) {
          logEvent('join_invalid_code', { role: parsed.role, code });
          sendClientError(ws, 'invalid_session');
          return;
        }
        if (now - s.createdAt > SESSION_EXPIRY_MS) {
          sessions.delete(code);
          logEvent('join_session_expired', { role: parsed.role, code });
          sendClientError(ws, 'invalid_session');
          return;
        }
        ws.role = parsed.role;
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
      } else if (t === 'rejoin') {
        // Reconnect with token instead of code
        const token = parsed.token;
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
          logEvent('rejoin_invalid_token', { role: parsed.role });
          sendClientError(ws, 'invalid_session');
          return;
        }
        if (now - foundSession.createdAt > SESSION_EXPIRY_MS) {
          sessions.delete(foundCode);
          logEvent('rejoin_session_expired', { role: parsed.role, code: foundCode });
          sendClientError(ws, 'invalid_session');
          return;
        }
        ws.role = parsed.role;
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
        if (!s || !s.game) return;
        const use = tryConsumeAbility(s, 'bomb', now);
        if (!use.ok) {
          logEvent('ability_blocked', { ability: 'bomb', reason: use.reason, code: ws.code });
          return;
        }
        const { x, y } = parsed;
        safeSend(s.game, { type: 'bomb_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'bomb', remaining: use.remaining });
      } else if (t === 'supply_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        const use = tryConsumeAbility(s, 'supply', now);
        if (!use.ok) {
          logEvent('ability_blocked', { ability: 'supply', reason: use.reason, code: ws.code });
          return;
        }
        const { x, y } = parsed;
        safeSend(s.game, { type: 'supply_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'supply', remaining: use.remaining });
      } else if (t === 'emp_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        const use = tryConsumeAbility(s, 'emp', now);
        if (!use.ok) {
          logEvent('ability_blocked', { ability: 'emp', reason: use.reason, code: ws.code });
          return;
        }
        const { x, y } = parsed;
        safeSend(s.game, { type: 'emp_drop', x, y });
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'emp', remaining: use.remaining });
      } else if (t === 'chopper_input' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        const { x, y } = parsed;
        safeSend(s.game, { type: 'chopper_input', x, y });
      } else if (t === 'radar_ping' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        const use = tryConsumeAbility(s, 'radar', now);
        if (!use.ok) {
          logEvent('ability_blocked', { ability: 'radar', reason: use.reason, code: ws.code });
          return;
        }
        safeSend(s.game, { type: 'radar_ping' });
        safeSend(ws, { type: 'radar_ack', remaining: use.remaining });
      } else if (t === 'new_wave' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s) {
          s.dropsThisWave = 0;
          s.suppliesThisWave = 0;
          s.radarsThisWave = 0;
          s.empsThisWave = 0;
          s.burstBuckets = { bomb: [], supply: [], radar: [], emp: [] };
          if (s.companion) safeSend(s.companion, { type: 'new_wave' });
        }
      } else if (t === 'minimap' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          const fwd = { type: 'minimap', enemies: parsed.enemies, allies: parsed.allies, players: parsed.players, wave: parsed.wave, state: parsed.state, chopper: parsed.chopper };
          safeSend(s.companion, fwd);
        }
      } else if (t === 'bomb_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          const kills = parsed.kills;
          const isMega = kills >= 5;
          safeSend(s.companion, { type: 'bomb_impact', x: parsed.x, y: parsed.y, kills, mega: isMega });
        }
      } else if (t === 'supply_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) safeSend(s.companion, { type: 'supply_impact', x: parsed.x, y: parsed.y });
      } else if (t === 'game_state' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) safeSend(s.companion, { type: 'game_state', state: parsed.state });
      } else if (t === 'ping' && ws.role === 'companion') {
        safeSend(ws, { type: 'pong', timestamp: parsed.timestamp });
      }
    } catch (e) {
      logEvent('ws_handler_exception', { role: ws.role, code: ws.code, message: e?.message });
      sendClientError(ws);
    }
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
