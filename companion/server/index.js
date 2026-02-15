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
const METRICS_WINDOW_MS = 5 * 60 * 1000;

const metrics = {
  pingSamples: [],
  relayLatencySamples: [],
  messageEvents: new Map(),
  rejectCountsByAbility: {
    bomb: 0,
    supply: 0,
    radar: 0,
    emp: 0,
    rate_limit: 0,
    invalid_session: 0
  }
};

function nowMs() { return Date.now(); }

function pruneOld(list, now = nowMs()) {
  while (list.length > 0 && (now - list[0].at) > METRICS_WINDOW_MS) list.shift();
}

function recordSample(list, value, now = nowMs()) {
  if (!Number.isFinite(value)) return;
  list.push({ at: now, value });
  pruneOld(list, now);
}

function recordMessageEvent(type, now = nowMs()) {
  if (!metrics.messageEvents.has(type)) metrics.messageEvents.set(type, []);
  const entries = metrics.messageEvents.get(type);
  entries.push(now);
  while (entries.length > 0 && (now - entries[0]) > METRICS_WINDOW_MS) entries.shift();
}

function percentileFromSamples(samples, pct) {
  if (samples.length === 0) return null;
  const sorted = samples.slice().sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((pct / 100) * sorted.length) - 1));
  return Math.round(sorted[idx] * 100) / 100;
}

function getRatesByType(now = nowMs()) {
  const rates = {};
  for (const [type, entries] of metrics.messageEvents.entries()) {
    while (entries.length > 0 && (now - entries[0]) > METRICS_WINDOW_MS) entries.shift();
    rates[type] = Number((entries.length / (METRICS_WINDOW_MS / 1000)).toFixed(3));
  }
  return rates;
}

function ensureSessionStats(s) {
  if (!s.stats) {
    s.stats = {
      pingSamples: [],
      relayLatencySamples: [],
      messageEvents: new Map(),
      rejectsByAbility: {
        bomb: 0,
        supply: 0,
        radar: 0,
        emp: 0,
        rate_limit: 0,
        invalid_session: 0
      },
      lastQos: null,
      qosSamples: []
    };
  }
  return s.stats;
}

function sessionRecordMessage(s, type, now = nowMs()) {
  const stats = ensureSessionStats(s);
  if (!stats.messageEvents.has(type)) stats.messageEvents.set(type, []);
  const entries = stats.messageEvents.get(type);
  entries.push(now);
  while (entries.length > 0 && (now - entries[0]) > METRICS_WINDOW_MS) entries.shift();
}

function sessionRecordSample(s, listName, value, now = nowMs()) {
  const stats = ensureSessionStats(s);
  recordSample(stats[listName], value, now);
}

function sessionRateByType(s, now = nowMs()) {
  const out = {};
  const stats = ensureSessionStats(s);
  for (const [type, entries] of stats.messageEvents.entries()) {
    while (entries.length > 0 && (now - entries[0]) > METRICS_WINDOW_MS) entries.shift();
    out[type] = Number((entries.length / (METRICS_WINDOW_MS / 1000)).toFixed(3));
  }
  return out;
}

function incrementReject(ability, s = null) {
  if (metrics.rejectCountsByAbility[ability] !== undefined) metrics.rejectCountsByAbility[ability]++;
  if (s) {
    const stats = ensureSessionStats(s);
    if (stats.rejectsByAbility[ability] !== undefined) stats.rejectsByAbility[ability]++;
  }
}

app.use(express.static(path.join(__dirname, 'client')));

app.get('/health', (req, res) => res.json({ ok: true }));

app.get('/metrics', (req, res) => {
  const now = nowMs();
  pruneOld(metrics.pingSamples, now);
  pruneOld(metrics.relayLatencySamples, now);
  const pingValues = metrics.pingSamples.map((s) => s.value);
  const sessionStats = {};
  for (const [code, s] of sessions.entries()) {
    const stats = ensureSessionStats(s);
    pruneOld(stats.pingSamples, now);
    pruneOld(stats.relayLatencySamples, now);
    pruneOld(stats.qosSamples, now);
    const qosLatest = stats.lastQos || null;
    sessionStats[code] = {
      token: s.reconnectToken,
      active: Boolean(s.game || s.companion),
      ping: {
        median: percentileFromSamples(stats.pingSamples.map((entry) => entry.value), 50),
        p95: percentileFromSamples(stats.pingSamples.map((entry) => entry.value), 95)
      },
      relayLatency: {
        median: percentileFromSamples(stats.relayLatencySamples.map((entry) => entry.value), 50),
        p95: percentileFromSamples(stats.relayLatencySamples.map((entry) => entry.value), 95)
      },
      messageRatesByType: sessionRateByType(s, now),
      rejectsByAbility: { ...stats.rejectsByAbility },
      lastQos: qosLatest
    };
    sessionStats[s.reconnectToken] = sessionStats[code];
  }

  res.json({
    activeSessions: Array.from(sessions.values()).filter((s) => s.game || s.companion).length,
    ping: {
      median: percentileFromSamples(pingValues, 50),
      p95: percentileFromSamples(pingValues, 95),
      sampleCount: pingValues.length
    },
    relayLatency: {
      median: percentileFromSamples(metrics.relayLatencySamples.map((s) => s.value), 50),
      p95: percentileFromSamples(metrics.relayLatencySamples.map((s) => s.value), 95)
    },
    messageRatesByType: getRatesByType(now),
    rejectCountsByAbility: { ...metrics.rejectCountsByAbility },
    sessions: sessionStats,
    windowMs: METRICS_WINDOW_MS
  });
});

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
    lastDropAt: 0,
    lastSupplyAt: 0,
    lastRadarAt: 0,
    lastEmpAt: 0,
    reconnectToken: token,
    relayStateSeq: 0
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

function relayWithTiming(targetWs, payload, ingressAt, session) {
  if (!safeSend(targetWs, payload)) return false;
  const latency = nowMs() - ingressAt;
  recordSample(metrics.relayLatencySamples, latency, nowMs());
  sessionRecordSample(session, 'relayLatencySamples', latency, nowMs());
  return true;
}

function relayWithMetadata(session, payload) {
  if (!session) return payload;
  session.relayStateSeq = (session.relayStateSeq || 0) + 1;
  return { ...payload, relay_ts: Date.now(), relay_seq: session.relayStateSeq };
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
    const ingressAt = now;
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
    recordMessageEvent(t, now);
    if (t !== 'chopper_input' && ++ws.msgCount > RATE_LIMIT_MSGS) {
      incrementReject('rate_limit', ws.code ? sessions.get(ws.code) : null);
      return;
    }
    try {
      if (t === 'join' && msg.code && msg.role) {
        const code = String(msg.code).toUpperCase();
        if (code.length !== 6) return;
        let s = sessions.get(code);
        if (!s) {
          incrementReject('invalid_session');
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
        sessionRecordMessage(s, t, now);
        if (ws.role === 'game') s.game = ws;
        else if (ws.role === 'companion') {
          s.companion = ws;
          s.relayStateSeq = 0;
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
        sessionRecordMessage(foundSession, t, now);
        if (ws.role === 'game') foundSession.game = ws;
        else if (ws.role === 'companion') {
          foundSession.companion = ws;
          foundSession.relayStateSeq = 0;
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
        sessionRecordMessage(s, t, now);
        if (s.dropsThisWave >= BOMBS_PER_WAVE || (now - s.lastDropAt) < COOLDOWN_BOMB_MS) {
          incrementReject('bomb', s);
          return;
        }
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.dropsThisWave++;
        s.lastDropAt = now;
        relayWithTiming(s.game, { type: 'bomb_drop', x, y }, ingressAt, s);
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'bomb', remaining: BOMBS_PER_WAVE - s.dropsThisWave });
      } else if (t === 'supply_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        sessionRecordMessage(s, t, now);
        if (s.suppliesThisWave >= SUPPLIES_PER_WAVE || (now - s.lastSupplyAt) < COOLDOWN_SUPPLY_MS) {
          incrementReject('supply', s);
          return;
        }
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.suppliesThisWave++;
        s.lastSupplyAt = now;
        relayWithTiming(s.game, { type: 'supply_drop', x, y }, ingressAt, s);
        safeSend(ws, { type: 'drop_ack', x, y, ability: 'supply', remaining: SUPPLIES_PER_WAVE - s.suppliesThisWave });
      } else if (t === 'chopper_input' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        sessionRecordMessage(s, t, now);
        const x = Math.max(-1, Math.min(1, Number(msg.x) ?? 0));
        const y = Math.max(-1, Math.min(1, Number(msg.y) ?? 0));
        relayWithTiming(s.game, { type: 'chopper_input', x, y }, ingressAt, s);
      } else if (t === 'radar_ping' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        sessionRecordMessage(s, t, now);
        if (s.radarsThisWave >= RADAR_PER_WAVE || (now - s.lastRadarAt) < COOLDOWN_RADAR_MS) {
          incrementReject('radar', s);
          return;
        }
        s.radarsThisWave++;
        s.lastRadarAt = now;
        relayWithTiming(s.game, { type: 'radar_ping' }, ingressAt, s);
        safeSend(ws, { type: 'radar_ack', remaining: RADAR_PER_WAVE - s.radarsThisWave });
      } else if (t === 'new_wave' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s) {
          sessionRecordMessage(s, t, now);
          s.dropsThisWave = 0;
          s.suppliesThisWave = 0;
          s.radarsThisWave = 0;
          if (s.companion) safeSend(s.companion, { type: 'new_wave' });
        }
      } else if ((t === 'minimap_full' || t === 'minimap_delta') && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          sessionRecordMessage(s, t, now);
          const fwd = {
            type: t,
            v: msg.v,
            seq: msg.seq,
            base_seq: msg.base_seq,
            wave: msg.wave,
            state: msg.state,
            enemies: msg.enemies || [],
            allies: msg.allies || [],
            players: msg.players || []
          };
          if (msg.chopper) fwd.chopper = msg.chopper;
          if (msg.chopper_removed) fwd.chopper_removed = true;
          const fwdWithMeta = relayWithMetadata(s, fwd);
          relayWithTiming(s.companion, fwdWithMeta, ingressAt, s);
        }
      } else if (t === 'bomb_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          sessionRecordMessage(s, t, now);
          const kills = msg.kills ?? 0;
          const isMega = kills >= 5;
          relayWithTiming(s.companion, { type: 'bomb_impact', x: msg.x, y: msg.y, kills, mega: isMega }, ingressAt, s);
        }
      } else if (t === 'supply_impact' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          sessionRecordMessage(s, t, now);
          relayWithTiming(s.companion, { type: 'supply_impact', x: msg.x, y: msg.y }, ingressAt, s);
        }
      } else if (t === 'game_state' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s && s.companion) {
          sessionRecordMessage(s, t, now);
          const stateSeq = Number.isFinite(Number(msg.state_seq)) ? Number(msg.state_seq) : 0;
          const wave = Number.isFinite(Number(msg.wave)) ? Number(msg.wave) : 0;
          const fwd = relayWithMetadata(s, { type: 'game_state', state: msg.state, state_seq: stateSeq, wave });
          relayWithTiming(s.companion, fwd, ingressAt, s);
        }
      } else if (t === 'ping' && ws.role === 'companion') {
        if (ws.code) {
          const s = sessions.get(ws.code);
          if (s) sessionRecordMessage(s, t, now);
        }
        safeSend(ws, { type: 'pong', timestamp: msg.timestamp });
      } else if (t === 'qos_sample' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s) return;
        sessionRecordMessage(s, t, now);
        const stats = ensureSessionStats(s);
        const rttMs = Number(msg.rttMs);
        const fps = Number(msg.fps);
        const packetGapCount = Number(msg.packetGapCount);
        const qos = {
          at: now,
          rttMs: Number.isFinite(rttMs) ? rttMs : null,
          fps: Number.isFinite(fps) ? fps : null,
          packetGapCount: Number.isFinite(packetGapCount) ? packetGapCount : null
        };
        stats.lastQos = qos;
        stats.qosSamples.push({ at: now, value: qos });
        pruneOld(stats.qosSamples, now);
        if (qos.rttMs !== null) {
          recordSample(metrics.pingSamples, qos.rttMs, now);
          sessionRecordSample(s, 'pingSamples', qos.rttMs, now);
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
