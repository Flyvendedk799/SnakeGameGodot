const landing = document.getElementById('landing');
const waiting = document.getElementById('waiting');
const connected = document.getElementById('connected');
const codeEl = document.getElementById('code');
const cooldownEl = document.getElementById('cooldown');
const remainingEl = document.getElementById('remaining');
const abilityHintEl = document.getElementById('abilityHint');
const connStatusEl = document.getElementById('connStatus');
const waveInfoEl = document.getElementById('waveInfo');
const startBtn = document.getElementById('start');
const copyBtn = document.getElementById('copy');
const reconnectBtn = document.getElementById('reconnect');
const minimap = document.getElementById('minimap');
const btnBomb = document.getElementById('btnBomb');
const btnSupply = document.getElementById('btnSupply');
const btnRadar = document.getElementById('btnRadar');
const btnEmp = document.getElementById('btnEmp');
const btnStats = document.getElementById('btnStats');
const btnToggleSound = document.getElementById('btnToggleSound');
const btnCloseStats = document.getElementById('btnCloseStats');
const statsPanel = document.getElementById('statsPanel');
const statsContent = document.getElementById('statsContent');

const COOLDOWN_BOMB_MS = 30000;
const COOLDOWN_SUPPLY_MS = 45000;
const COOLDOWN_RADAR_MS = 60000;
const COOLDOWN_EMP_MS = 90000;
const BOMBS_PER_WAVE = 2;
const SUPPLIES_PER_WAVE = 1;
const RADAR_PER_WAVE = 1;
const EMP_PER_WAVE = 1;
const MM_SIZE = 300;
const PAD = 10;
const CHOPPER_INPUT_THROTTLE_MS = 50;  // ~20 Hz for snappier chopper control

let ws = null, sessionCode = null, reconnectToken = null;
let lastBombAt = 0, lastSupplyAt = 0, lastRadarAt = 0, lastEmpAt = 0;
let bombsRemaining = BOMBS_PER_WAVE, suppliesRemaining = SUPPLIES_PER_WAVE, radarsRemaining = RADAR_PER_WAVE, empsRemaining = EMP_PER_WAVE;
let selectedAbility = 'bomb';
let gameState = 'wave_active';
let currentWave = 0;
let radarRevealActive = false;

// Connection quality
let latencyMs = 0;
let lastPingAt = 0;

// Stats tracking
let stats = {
  totalBombs: 0,
  totalKills: 0,
  totalSupplies: 0,
  totalRadars: 0,
  totalEmps: 0,
  megaStrikes: 0,
  wavesAssisted: 0
};

function loadStats() {
  try {
    const saved = localStorage.getItem('companion_stats');
    if (saved) stats = { ...stats, ...JSON.parse(saved) };
  } catch (_) { /* ignore */ }
}

function saveStats() {
  try {
    localStorage.setItem('companion_stats', JSON.stringify(stats));
  } catch (_) { /* ignore */ }
}

loadStats();

// Sound effects (Web Audio API) - lazy resume on mobile (blocks until first tap)
let soundEnabled = true;
let audioCtx = null;
function getAudioCtx() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === 'suspended') audioCtx.resume();
  return audioCtx;
}

function playSoundEffect(type) {
  if (!soundEnabled) return;
  const ctx = getAudioCtx();
  if (!ctx) return;
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);

  const t = ctx.currentTime;
  switch(type) {
    case 'drop':
      osc.frequency.setValueAtTime(600, t);
      osc.frequency.exponentialRampToValueAtTime(200, t + 0.15);
      gain.gain.setValueAtTime(0.15, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.15);
      osc.start(t);
      osc.stop(t + 0.15);
      break;
    case 'impact':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(80, t);
      gain.gain.setValueAtTime(0.2, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.2);
      osc.start(t);
      osc.stop(t + 0.2);
      break;
    case 'supply':
      osc.type = 'sine';
      osc.frequency.setValueAtTime(523, t);
      osc.frequency.setValueAtTime(659, t + 0.08);
      gain.gain.setValueAtTime(0.12, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.25);
      osc.start(t);
      osc.stop(t + 0.25);
      break;
    case 'radar':
      osc.type = 'square';
      osc.frequency.setValueAtTime(880, t);
      gain.gain.setValueAtTime(0.1, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.1);
      osc.start(t);
      osc.stop(t + 0.1);
      break;
    case 'mega':
      [440, 554, 659].forEach((freq, i) => {
        const o = ctx.createOscillator();
        const g = ctx.createGain();
        o.connect(g);
        g.connect(ctx.destination);
        o.type = 'triangle';
        o.frequency.setValueAtTime(freq, t);
        g.gain.setValueAtTime(0.08, t);
        g.gain.exponentialRampToValueAtTime(0.01, t + 0.4);
        o.start(t + i * 0.05);
        o.stop(t + 0.4 + i * 0.05);
      });
      break;
  }
}

try {
  const savedSound = localStorage.getItem('companion_sound');
  if (savedSound !== null) soundEnabled = savedSound === 'true';
} catch (_) { /* ignore */ }

// Tutorial system
const tutorialOverlay = document.getElementById('tutorialOverlay');
const tutorialStep1 = document.getElementById('tutorialStep1');
const tutorialStep2 = document.getElementById('tutorialStep2');
const tutorialStep3 = document.getElementById('tutorialStep3');
const tutorialNext1 = document.getElementById('tutorialNext1');
const tutorialNext2 = document.getElementById('tutorialNext2');
const tutorialDone = document.getElementById('tutorialDone');
const tutorialSkip = document.getElementById('tutorialSkip');

function showTutorial() {
  try {
    const seen = localStorage.getItem('companion_tutorial_seen');
    if (seen === 'true') return false;
  } catch (_) { /* ignore */ }

  tutorialOverlay.classList.remove('hidden');
  return true;
}

function hideTutorial() {
  tutorialOverlay.classList.add('hidden');
  try {
    localStorage.setItem('companion_tutorial_seen', 'true');
  } catch (_) { /* ignore */ }
}

tutorialNext1.onclick = () => {
  tutorialStep1.classList.add('hidden');
  tutorialStep2.classList.remove('hidden');
};

tutorialNext2.onclick = () => {
  tutorialStep2.classList.add('hidden');
  tutorialStep3.classList.remove('hidden');
};

tutorialDone.onclick = hideTutorial;
tutorialSkip.onclick = hideTutorial;

// Error toast system
const errorToast = document.getElementById('errorToast');
const errorTitle = document.getElementById('errorTitle');
const errorMessage = document.getElementById('errorMessage');
let errorTimeout = null;

function showError(title, message, duration = 4000) {
  errorTitle.textContent = title;
  errorMessage.textContent = message;
  errorToast.classList.remove('hidden');

  if (errorTimeout) clearTimeout(errorTimeout);
  errorTimeout = setTimeout(() => {
    errorToast.classList.add('hidden');
  }, duration);
}

function hideError() {
  errorToast.classList.add('hidden');
  if (errorTimeout) clearTimeout(errorTimeout);
}

// Impact history timeline
const historyList = document.getElementById('historyList');
const impactHistory = [];
const MAX_HISTORY = 5;

function addToHistory(icon, text, subtext = '') {
  const timestamp = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  impactHistory.unshift({ icon, text, subtext, timestamp, id: Date.now() });
  if (impactHistory.length > MAX_HISTORY) impactHistory.pop();

  updateHistoryDisplay();
}

function updateHistoryDisplay() {
  historyList.innerHTML = impactHistory.map((entry, index) => {
    const age = index * 0.1;
    return `
      <div style="
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.5rem 0.75rem;
        background: rgba(0, 0, 0, ${0.3 - age * 0.05});
        border-left: 3px solid rgba(138, 122, 202, ${1 - age});
        border-radius: 8px;
        animation: slideInLeft 0.3s ease;
        opacity: ${1 - age * 0.15};
      ">
        <span style="font-size: 1.2rem;">${entry.icon}</span>
        <div style="flex: 1; font-size: 0.85rem;">
          <div style="font-weight: 600; color: #e0d8e8;">${entry.text}</div>
          ${entry.subtext ? `<div style="font-size: 0.75rem; color: #9a8aca;">${entry.subtext}</div>` : ''}
        </div>
        <span style="font-size: 0.7rem; color: #6a5a8a;">${entry.timestamp}</span>
      </div>
    `;
  }).join('');
}

// Add CSS animation
const style = document.createElement('style');
style.textContent = `
  @keyframes slideInLeft {
    from { transform: translateX(-20px); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }
`;
document.head.appendChild(style);

const MINIMAP_PROTOCOL_VERSION = 1;
const MINIMAP_QUANT_MAX = 1023;

let minimapData = { enemies: [], allies: [], players: [], chopper: null };
let minimapStore = {
  enemies: new Map(),
  allies: new Map(),
  players: new Map(),
  chopper: null
};
let lastMinimapSeq = 0;
let waitingForFullSnapshot = true;

// Joystick state for helicopter control
let joystickActive = false;
let joystickLastSent = 0;
let impactFlash = null;

const abilityInfo = {
  bomb: { cooldownMs: COOLDOWN_BOMB_MS, maxPerWave: BOMBS_PER_WAVE, hint: 'Tap map to drop bomb', needsTap: true },
  supply: { cooldownMs: COOLDOWN_SUPPLY_MS, maxPerWave: SUPPLIES_PER_WAVE, hint: 'Tap map to drop supply crate', needsTap: true },
  radar: { cooldownMs: COOLDOWN_RADAR_MS, maxPerWave: RADAR_PER_WAVE, hint: 'Reveal enemies for 5 seconds', needsTap: false },
  emp: { cooldownMs: COOLDOWN_EMP_MS, maxPerWave: EMP_PER_WAVE, hint: 'Tap map to stun enemies (2s)', needsTap: true }
};

function setupWsHandlers(socket) {
  socket.onmessage = (e) => {
    let m;
    try { m = JSON.parse(e.data); } catch (_) { return; }
    // Validate message structure
    if (typeof m !== 'object' || m === null || Array.isArray(m)) return;
    if (typeof m.type !== 'string') return;

    if (m.type === 'error') {
      const msg = m.message || 'Unknown error';
      if (msg.includes('Invalid code')) {
        showError('Invalid Code', 'The session code is incorrect or expired. Please create a new session.');
      } else if (msg.includes('expired')) {
        showError('Session Expired', 'Your session has expired after 2 hours. Please create a new session.');
      } else {
        showError('Connection Error', msg);
      }
      return;
    }

    if (m.type === 'joined' && m.token) {
      hideError();
      reconnectToken = m.token;
      try {
        localStorage.setItem('companion_reconnect_token', reconnectToken);
        localStorage.setItem('companion_session_code', sessionCode);
      } catch (_) { /* ignore storage errors */ }
    } else if (m.type === 'game_connected') {
      hideError();
      bombsRemaining = BOMBS_PER_WAVE;
      suppliesRemaining = SUPPLIES_PER_WAVE;
      resetMinimapState();
      waiting.classList.add('hidden');
      connected.classList.remove('hidden');
      connStatusEl.innerHTML = '<span class="status-dot online"></span> Connected';
    } else if (m.type === 'drop_ack') {
      if (m.ability === 'bomb') {
        lastBombAt = Date.now();
        stats.totalBombs++;
        addToHistory('💣', 'Bomb deployed', 'Incoming strike!');
      } else if (m.ability === 'supply') {
        lastSupplyAt = Date.now();
        stats.totalSupplies++;
        addToHistory('📦', 'Supply drop', 'Repairs + gold incoming');
      } else if (m.ability === 'emp') {
        lastEmpAt = Date.now();
        stats.totalEmps++;
        addToHistory('⚡', 'EMP deployed', 'Stunning enemies...');
      }
      if (typeof m.remaining === 'number') {
        if (m.ability === 'bomb') bombsRemaining = m.remaining;
        else if (m.ability === 'supply') suppliesRemaining = m.remaining;
        else if (m.ability === 'emp') empsRemaining = m.remaining;
      }
      saveStats();
      playSoundEffect('drop');
      _hapticFeedback();
    } else if (m.type === 'radar_ack') {
      lastRadarAt = Date.now();
      stats.totalRadars++;
      addToHistory('📡', 'Radar active', 'Enemies revealed!');
      if (typeof m.remaining === 'number') radarsRemaining = m.remaining;
      radarRevealActive = true;
      setTimeout(() => { radarRevealActive = false; }, 5000);
      saveStats();
      playSoundEffect('radar');
      _hapticFeedback();
    } else if (m.type === 'new_wave') {
      bombsRemaining = BOMBS_PER_WAVE;
      suppliesRemaining = SUPPLIES_PER_WAVE;
      radarsRemaining = RADAR_PER_WAVE;
      empsRemaining = EMP_PER_WAVE;
      stats.wavesAssisted++;
      saveStats();
    } else if (m.type === 'minimap_full') {
      applyMinimapFull(m);
      if (typeof m.wave === 'number') currentWave = m.wave;
      if (typeof m.state === 'string') gameState = m.state;
    } else if (m.type === 'minimap_delta') {
      applyMinimapDelta(m);
      if (typeof m.wave === 'number') currentWave = m.wave;
      if (typeof m.state === 'string') gameState = m.state;
    } else if (m.type === 'bomb_impact') {
      const isMega = m.mega === true || (m.kills >= 5);
      const kills = m.kills || 0;
      stats.totalKills += kills;
      if (isMega) {
        stats.megaStrikes++;
        addToHistory('💥', `MEGA STRIKE! ${kills} kills`, 'Devastating!');
      } else if (kills > 0) {
        addToHistory('💣', `Bomb hit: ${kills} kills`, 'Nice!');
      } else {
        addToHistory('💣', 'Bomb landed', 'No hits');
      }
      saveStats();
      playSoundEffect(isMega ? 'mega' : 'impact');
      impactFlash = { x: m.x, y: m.y, kills, type: 'bomb', at: Date.now(), mega: isMega };
      if (navigator.vibrate) {
        if (isMega) {
          // Stronger haptic pattern for mega strike
          navigator.vibrate([100, 50, 100, 50, 150]);
        } else {
          navigator.vibrate(100);
        }
      }
    } else if (m.type === 'supply_impact') {
      addToHistory('📦', 'Supply delivered', 'Team supported!');
      impactFlash = { x: m.x, y: m.y, type: 'supply', at: Date.now() };
      playSoundEffect('supply');
    } else if (m.type === 'game_state') {
      gameState = m.state || 'wave_active';
    } else if (m.type === 'pong') {
      if (m.timestamp && lastPingAt) {
        latencyMs = Date.now() - lastPingAt;
      }
    }
  };
  socket.onclose = () => {
    ws = null;
    connected.classList.add('hidden');
    waiting.classList.remove('hidden');
    statusEl.innerHTML = 'Connection lost<span class="reconnecting-indicator"></span>';
    reconnectBtn.classList.remove('hidden');
    connStatusEl.innerHTML = '<span class="status-dot offline"></span> Disconnected';
    showError('Connection Lost', 'Trying to reconnect automatically...', 6000);
  };
  socket.onerror = (err) => {
    console.error('WebSocket error:', err);
    showError('Connection Error', 'Unable to connect to the server. Please check your internet connection.');
  };
}

function _hapticFeedback() {
  if (navigator.vibrate) navigator.vibrate(30);
}

startBtn.onclick = async () => {
  try {
    const r = await fetch('/session/create');
    const d = await r.json();
    sessionCode = d.code;
    reconnectToken = d.token;
    codeEl.textContent = sessionCode;
    landing.classList.add('hidden');
    waiting.classList.remove('hidden');
    hideReconnect();

    // Show tutorial on first use
    showTutorial();

    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(proto + '//' + location.host + '/ws');
    setupWsHandlers(ws);
    ws.onopen = () => {
      hideError();
      ws.send(JSON.stringify({ type: 'join', code: sessionCode, role: 'companion' }));
    };
  } catch (err) {
    statusEl.textContent = 'Failed to create session. Retry?';
    showError('Connection Failed', 'Unable to create a session. Please check your internet connection and try again.');
    if (reconnectBtn) reconnectBtn.classList.remove('hidden');
  }
};

const statusEl = document.getElementById('status');
function hideReconnect() {
  reconnectBtn.classList.add('hidden');
  statusEl.textContent = 'Waiting for game...';
}

reconnectBtn.onclick = () => {
  if (ws) return;
  // Try to load token from storage if we lost it
  if (!reconnectToken) {
    try {
      reconnectToken = localStorage.getItem('companion_reconnect_token');
      sessionCode = localStorage.getItem('companion_session_code');
    } catch (_) { /* ignore */ }
  }
  if (!reconnectToken && !sessionCode) return;
  hideReconnect();
  const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
  ws = new WebSocket(proto + '//' + location.host + '/ws');
  setupWsHandlers(ws);
  ws.onopen = () => {
    // Prefer token-based rejoin if we have it
    if (reconnectToken) {
      ws.send(JSON.stringify({ type: 'rejoin', token: reconnectToken, role: 'companion' }));
    } else {
      ws.send(JSON.stringify({ type: 'join', code: sessionCode, role: 'companion' }));
    }
  };
};

copyBtn.onclick = () => {
  if (sessionCode) navigator.clipboard.writeText(sessionCode);
  _hapticFeedback();
};

function canUseAbility(ability) {
  // Disable abilities when not in active wave
  if (gameState !== 'wave_active') return false;
  const info = abilityInfo[ability];
  if (!info) return false;
  const lastAt = ability === 'bomb' ? lastBombAt : ability === 'supply' ? lastSupplyAt : ability === 'radar' ? lastRadarAt : lastEmpAt;
  if (!lastAt) return true;
  if (Date.now() - lastAt < info.cooldownMs) return false;
  const rem = ability === 'bomb' ? bombsRemaining : ability === 'supply' ? suppliesRemaining : ability === 'radar' ? radarsRemaining : empsRemaining;
  return rem > 0;
}

function canDrop(ability) {
  return canUseAbility(ability);
}

function getCooldownRemaining(ability) {
  const lastAt = ability === 'bomb' ? lastBombAt : ability === 'supply' ? lastSupplyAt : ability === 'radar' ? lastRadarAt : lastEmpAt;
  if (!lastAt) return 0;
  const info = abilityInfo[ability];
  return Math.max(0, info.cooldownMs - (Date.now() - lastAt));
}


function resetMinimapState() {
  minimapStore = {
    enemies: new Map(),
    allies: new Map(),
    players: new Map(),
    chopper: null
  };
  minimapData = { enemies: [], allies: [], players: [], chopper: null };
  lastMinimapSeq = 0;
  waitingForFullSnapshot = true;
}

function dequantizeCoord(v) {
  return Math.max(0, Math.min(1, Number(v) / MINIMAP_QUANT_MAX));
}

function decodeEntity(entry, includeBoss = false) {
  if (!entry || typeof entry !== 'object') return null;
  const id = typeof entry.id === 'string' ? entry.id : '';
  if (!id) return null;
  const out = [dequantizeCoord(entry.x), dequantizeCoord(entry.y)];
  if (includeBoss) out.push(entry.boss === true);
  return { id, value: out };
}

function rebuildMinimapDataFromStore() {
  minimapData = {
    enemies: Array.from(minimapStore.enemies.values()),
    allies: Array.from(minimapStore.allies.values()),
    players: Array.from(minimapStore.players.values()),
    chopper: minimapStore.chopper
  };
}

function applyFullGroup(targetMap, entries, includeBoss = false) {
  targetMap.clear();
  if (!Array.isArray(entries)) return;
  for (const entry of entries) {
    const decoded = decodeEntity(entry, includeBoss);
    if (!decoded) continue;
    targetMap.set(decoded.id, decoded.value);
  }
}

function applyDeltaGroup(targetMap, delta, includeBoss = false) {
  if (!delta || typeof delta !== 'object') return;
  if (Array.isArray(delta.upserts)) {
    for (const entry of delta.upserts) {
      const decoded = decodeEntity(entry, includeBoss);
      if (!decoded) continue;
      targetMap.set(decoded.id, decoded.value);
    }
  }
  if (Array.isArray(delta.removed)) {
    for (const id of delta.removed) {
      if (typeof id === 'string') targetMap.delete(id);
    }
  }
}

function applyMinimapFull(message) {
  if (Number(message.v) !== MINIMAP_PROTOCOL_VERSION) return;
  applyFullGroup(minimapStore.enemies, message.enemies, true);
  applyFullGroup(minimapStore.allies, message.allies, false);
  applyFullGroup(minimapStore.players, message.players, false);
  minimapStore.chopper = decodeEntity(message.chopper, false)?.value ?? null;
  lastMinimapSeq = Number(message.seq) || 0;
  waitingForFullSnapshot = false;
  rebuildMinimapDataFromStore();
}

function applyMinimapDelta(message) {
  if (Number(message.v) !== MINIMAP_PROTOCOL_VERSION) return;
  const seq = Number(message.seq);
  const baseSeq = Number(message.base_seq);
  if (waitingForFullSnapshot || !Number.isFinite(seq) || !Number.isFinite(baseSeq) || baseSeq !== lastMinimapSeq || seq !== lastMinimapSeq + 1) {
    waitingForFullSnapshot = true;
    return;
  }

  applyDeltaGroup(minimapStore.enemies, message.enemies, true);
  applyDeltaGroup(minimapStore.allies, message.allies, false);
  applyDeltaGroup(minimapStore.players, message.players, false);
  if (message.chopper_removed === true) {
    minimapStore.chopper = null;
  } else if (message.chopper && typeof message.chopper === 'object') {
    minimapStore.chopper = decodeEntity(message.chopper, false)?.value ?? minimapStore.chopper;
  }

  lastMinimapSeq = seq;
  rebuildMinimapDataFromStore();
}

function drawMinimap() {
  const c = minimap.getContext('2d');
  const inner = MM_SIZE - PAD * 2;
  c.fillStyle = '#1a1520';
  c.fillRect(0, 0, MM_SIZE, MM_SIZE);
  c.strokeStyle = '#4a3f6a';
  c.strokeRect(PAD, PAD, inner, inner);

  const toPx = (nx, ny) => [PAD + nx * inner, PAD + ny * inner];

  // Draw fort outline (main area)
  c.fillStyle = 'rgba(85, 70, 50, 0.4)';
  c.fillRect(PAD + inner * 0.1, PAD + inner * 0.05, inner * 0.8, inner * 0.7);
  c.strokeStyle = 'rgba(140, 115, 85, 0.6)';
  c.lineWidth = 1.5;
  c.strokeRect(PAD + inner * 0.1, PAD + inner * 0.05, inner * 0.8, inner * 0.7);

  // Draw keep outline (inner safe zone)
  c.fillStyle = 'rgba(65, 55, 40, 0.5)';
  c.fillRect(PAD + inner * 0.35, PAD + inner * 0.35, inner * 0.3, inner * 0.3);
  c.strokeStyle = 'rgba(130, 105, 80, 0.7)';
  c.lineWidth = 1.0;
  c.strokeRect(PAD + inner * 0.35, PAD + inner * 0.35, inner * 0.3, inner * 0.3);

  // Draw from keyed entity store snapshots; cap at 50 enemies on mobile for perf
  const enemyCap = window.innerWidth < 768 ? 50 : 80;
  const pulsePhase = radarRevealActive ? Math.sin(Date.now() / 200) * 1.5 : 0;
  for (let i = 0; i < Math.min(minimapData.enemies.length, enemyCap); i++) {
    const e = minimapData.enemies[i];
    const [px, py] = toPx(e[0], e[1]);
    const isBoss = e.length > 2 && e[2] === true;
    const dotSize = isBoss ? 3 : 1.5;
    c.fillStyle = isBoss ? '#ff2828' : 'rgba(255, 80, 80, 0.95)';
    c.beginPath();
    c.arc(px, py, dotSize, 0, Math.PI * 2);
    c.fill();
    if (radarRevealActive) {
      c.strokeStyle = 'rgba(100, 200, 255, 0.6)';
      c.lineWidth = 1;
      c.beginPath();
      c.arc(px, py, dotSize + 3 + pulsePhase, 0, Math.PI * 2);
      c.stroke();
    }
  }
  for (const a of minimapData.allies.slice(0, 24)) {
    const [px, py] = toPx(a[0], a[1]);
    c.fillStyle = 'rgba(80, 160, 255, 0.9)';
    c.beginPath();
    c.arc(px, py, 1.8, 0, Math.PI * 2);
    c.fill();
  }
  for (const p of minimapData.players) {
    const [px, py] = toPx(p[0], p[1]);
    c.fillStyle = 'rgba(80, 255, 120, 1)';
    c.beginPath();
    c.arc(px, py, 3, 0, Math.PI * 2);
    c.fill();
  }
  if (minimapData.chopper) {
    const [px, py] = toPx(minimapData.chopper[0], minimapData.chopper[1]);
    c.fillStyle = 'rgba(200, 180, 80, 1)';
    c.strokeStyle = 'rgba(255, 220, 100, 0.9)';
    c.lineWidth = 1.5;
    c.beginPath();
    c.arc(px, py, 4, 0, Math.PI * 2);
    c.fill();
    c.stroke();
  }

  if (impactFlash) {
    const age = (Date.now() - impactFlash.at) / 1000;
    if (age > 1.2) impactFlash = null;
    else {
      const [px, py] = toPx(impactFlash.x, impactFlash.y);
      const alpha = Math.max(0, 1 - age / 1.2);
      const r = 8 + age * 15;
      c.strokeStyle = impactFlash.type === 'bomb' ? `rgba(255, 150, 50, ${alpha * 0.8})` : `rgba(100, 220, 120, ${alpha * 0.8})`;
      c.lineWidth = 3;
      c.beginPath();
      c.arc(px, py, r, 0, Math.PI * 2);
      c.stroke();
      if (impactFlash.type === 'bomb' && impactFlash.kills > 0 && age < 0.8) {
        c.textAlign = 'center';
        if (impactFlash.mega) {
          // MEGA STRIKE! special display
          c.font = 'bold 18px system-ui';
          c.fillStyle = `rgba(255, 100, 255, ${alpha})`;
          c.fillText('MEGA STRIKE!', px, py - r - 20);
          c.font = 'bold 16px system-ui';
          c.fillStyle = `rgba(255, 220, 100, ${alpha})`;
          c.fillText(impactFlash.kills + ' KILLS!', px, py - r - 4);
          // Extra glow
          const glowAlpha = alpha * 0.3 * (1 + Math.sin(age * 20));
          c.strokeStyle = `rgba(255, 100, 255, ${glowAlpha})`;
          c.lineWidth = 3;
          c.beginPath();
          c.arc(px, py, r + 5, 0, Math.PI * 2);
          c.stroke();
        } else {
          c.font = 'bold 14px system-ui';
          c.fillStyle = `rgba(255, 220, 100, ${alpha})`;
          c.fillText(impactFlash.kills + ' KILLS!', px, py - r - 4);
        }
      }
    }
  }
}

function doDrop(e) {
  if (!ws || ws.readyState !== 1) return;
  if (!canDrop(selectedAbility)) {
    minimap.classList.add('reject-flash');
    setTimeout(() => minimap.classList.remove('reject-flash'), 200);
    return;
  }
  // Immediate visual feedback before server ack (feels more responsive)
  _hapticFeedback();
  minimap.classList.add('drop-flash');
  setTimeout(() => minimap.classList.remove('drop-flash'), 150);
  const r = minimap.getBoundingClientRect();
  const rw = Math.max(1, r.width);
  const rh = Math.max(1, r.height);
  const cx = e.clientX ?? (e.touches && e.touches[0] ? e.touches[0].clientX : r.left);
  const cy = e.clientY ?? (e.touches && e.touches[0] ? e.touches[0].clientY : r.top);
  const x = Math.max(0, Math.min(1, (cx - r.left) / rw));
  const y = Math.max(0, Math.min(1, (cy - r.top) / rh));
  const msg = selectedAbility === 'bomb' ? { type: 'helicopter_drop', x, y } :
               selectedAbility === 'supply' ? { type: 'supply_drop', x, y } :
               selectedAbility === 'emp' ? { type: 'emp_drop', x, y } : null;
  if (msg) ws.send(JSON.stringify(msg));
}

function onMinimapTap(e) {
  e.preventDefault();
  e.stopPropagation();
  doDrop(e);
}
minimap.addEventListener('pointerdown', onMinimapTap, { passive: false });
minimap.addEventListener('click', onMinimapTap, { passive: false });
minimap.addEventListener('touchend', (e) => {
  if (e.changedTouches && e.changedTouches[0]) {
    e.preventDefault();
    doDrop({ clientX: e.changedTouches[0].clientX, clientY: e.changedTouches[0].clientY });
  }
}, { passive: false });

btnBomb.onclick = () => {
  selectedAbility = 'bomb';
  btnBomb.classList.add('selected');
  btnSupply.classList.remove('selected');
  btnEmp.classList.remove('selected');
  abilityHintEl.textContent = abilityInfo.bomb.hint;
};
btnSupply.onclick = () => {
  selectedAbility = 'supply';
  btnSupply.classList.add('selected');
  btnBomb.classList.remove('selected');
  btnEmp.classList.remove('selected');
  abilityHintEl.textContent = abilityInfo.supply.hint;
};
btnEmp.onclick = () => {
  selectedAbility = 'emp';
  btnEmp.classList.add('selected');
  btnBomb.classList.remove('selected');
  btnSupply.classList.remove('selected');
  abilityHintEl.textContent = abilityInfo.emp.hint;
};
// Virtual joystick for helicopter control (only visible in game - companion watches TV)
function initJoystick() {
  const base = document.getElementById('joystickBase');
  const stick = document.getElementById('joystickStick');
  if (!base || !stick) return;

  const RADIUS = 42;  // max stick travel from center
  const BASE_RADIUS = 55;  // half of 110px base

  function sendChopperInput(x, y) {
    if (!ws || ws.readyState !== 1) return;
    const now = Date.now();
    if (x === 0 && y === 0) {
      ws.send(JSON.stringify({ type: 'chopper_input', x: 0, y: 0 }));
      joystickLastSent = now;
    } else if (now - joystickLastSent >= CHOPPER_INPUT_THROTTLE_MS) {
      ws.send(JSON.stringify({ type: 'chopper_input', x, y }));
      joystickLastSent = now;
    }
  }

  function getCenter(el) {
    const r = el.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  }

  function clampStick(dx, dy) {
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len <= 0) return { dx: 0, dy: 0, nx: 0, ny: 0 };
    const clamp = Math.min(len, RADIUS);
    const s = clamp / len;
    const cdx = dx * s, cdy = dy * s;
    return { dx: cdx, dy: cdy, nx: cdx / RADIUS, ny: cdy / RADIUS };
  }

  function updateStick(cdx, cdy) {
    stick.style.transform = `translate(calc(-50% + ${cdx}px), calc(-50% + ${cdy}px))`;
  }

  function onStart(e) {
    e.preventDefault();
    joystickActive = true;
    base.classList.add('active');
    const touch = e.touches ? e.touches[0] : e;
    if (touch) {
      const cx = getCenter(base);
      const dx = (touch.clientX - cx.x);
      const dy = (touch.clientY - cx.y);
      const { dx: cdx, dy: cdy, nx, ny } = clampStick(dx, dy);
      updateStick(cdx, cdy);
      sendChopperInput(nx, ny);
    }
  }

  function onMove(e) {
    if (!joystickActive) return;
    e.preventDefault();
    const touch = e.touches ? e.touches[0] : e;
    const cx = getCenter(base);
    const dx = (touch.clientX - cx.x);
    const dy = (touch.clientY - cx.y);
    const { dx: cdx, dy: cdy, nx, ny } = clampStick(dx, dy);
    updateStick(cdx, cdy);
    sendChopperInput(nx, ny);
  }

  function onEnd(e) {
    if (!joystickActive) return;
    e.preventDefault();
    joystickActive = false;
    base.classList.remove('active');
    updateStick(0, 0);
    sendChopperInput(0, 0);
  }

  base.addEventListener('pointerdown', onStart, { passive: false });
  base.addEventListener('touchstart', onStart, { passive: false });
  window.addEventListener('pointermove', onMove, { passive: false });
  window.addEventListener('touchmove', onMove, { passive: false });
  window.addEventListener('pointerup', onEnd, { passive: false });
  window.addEventListener('pointercancel', onEnd, { passive: false });
  window.addEventListener('touchend', onEnd, { passive: false });
  window.addEventListener('touchcancel', onEnd, { passive: false });
}
initJoystick();

btnRadar.onclick = () => {
  // Radar is instant - no map tap needed
  if (!ws || ws.readyState !== 1) return;
  if (!canUseAbility('radar')) {
    btnRadar.classList.add('reject-flash');
    setTimeout(() => btnRadar.classList.remove('reject-flash'), 200);
    return;
  }
  ws.send(JSON.stringify({ type: 'radar_ping' }));
};

// Ping interval for latency monitoring
setInterval(() => {
  if (ws && ws.readyState === 1) {
    lastPingAt = Date.now();
    ws.send(JSON.stringify({ type: 'ping', timestamp: lastPingAt }));
  }
}, 5000);

// Update ability button states
function updateAbilityButtons() {
  const abilities = [
    { btn: btnBomb, ability: 'bomb', remaining: bombsRemaining, cd: document.getElementById('cdBomb'), badge: document.getElementById('badgeBomb') },
    { btn: btnSupply, ability: 'supply', remaining: suppliesRemaining, cd: document.getElementById('cdSupply'), badge: document.getElementById('badgeSupply') },
    { btn: btnRadar, ability: 'radar', remaining: radarsRemaining, cd: document.getElementById('cdRadar'), badge: document.getElementById('badgeRadar') },
    { btn: btnEmp, ability: 'emp', remaining: empsRemaining, cd: document.getElementById('cdEmp'), badge: document.getElementById('badgeEmp') }
  ];

  abilities.forEach(({ btn, ability, remaining, cd, badge }) => {
    const canUse = canUseAbility(ability);
    const cooldown = getCooldownRemaining(ability);
    const cooldownSec = Math.ceil(cooldown / 1000);

    // Update badge
    if (badge) {
      badge.textContent = remaining;
      if (remaining === 0) {
        badge.style.background = 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)';
      } else {
        badge.style.background = 'linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%)';
      }
    }

    // Update cooldown display
    if (cd) {
      if (cooldown > 0) {
        cd.textContent = `${cooldownSec}s`;
      } else {
        cd.textContent = '';
      }
    }

    // Update button state
    if (gameState !== 'wave_active' || !canUse) {
      btn.classList.add('disabled');
      btn.classList.remove('ready');
    } else {
      btn.classList.remove('disabled');
      if (cooldown === 0 && remaining > 0) {
        btn.classList.add('ready');
      } else {
        btn.classList.remove('ready');
      }
    }
  });
}

// Cache last UI values to reduce DOM writes (better mobile perf)
let _lastCooldownText = '', _lastRemainingText = '', _lastWaveHtml = '', _lastMinimapOpacity = '';

setInterval(() => {
  updateAbilityButtons();

  const info = abilityInfo[selectedAbility];
  const rem = getCooldownRemaining(selectedAbility);
  const remSec = Math.ceil(rem / 1000);
  const left = selectedAbility === 'bomb' ? bombsRemaining : selectedAbility === 'supply' ? suppliesRemaining : selectedAbility === 'emp' ? empsRemaining : radarsRemaining;

  if (waveInfoEl) {
    const stateLabel = gameState === 'wave_active' ? 'In combat' :
                       gameState === 'between_waves' ? 'Shopping' :
                       gameState === 'paused' ? 'Paused' :
                       gameState === 'level_up' ? 'Leveling up' :
                       gameState === 'game_over' ? 'Game over' : 'Waiting';
    const latencyColor = latencyMs < 100 ? '#4ade80' : latencyMs < 200 ? '#facc15' : '#ef4444';
    const latencyDot = latencyMs > 0 ? `<span style="color:${latencyColor}">●</span> ${latencyMs}ms` : '';
    const waveHtml = currentWave > 0 ? `Wave ${currentWave} • ${stateLabel} ${latencyDot}` : `${stateLabel} ${latencyDot}`;
    if (waveHtml !== _lastWaveHtml) {
      waveInfoEl.innerHTML = waveHtml;
      _lastWaveHtml = waveHtml;
    }
  }

  if (gameState !== 'wave_active') {
    const cdText = 'Wait for combat...';
    const stateText = gameState === 'between_waves' ? 'Shop open' :
                      gameState === 'paused' ? 'Game paused' :
                      gameState === 'level_up' ? 'Level up' :
                      gameState === 'game_over' ? 'Game over' : 'Waiting...';
    if (cdText !== _lastCooldownText) { cooldownEl.textContent = cdText; _lastCooldownText = cdText; }
    if (stateText !== _lastRemainingText) { remainingEl.textContent = stateText; _lastRemainingText = stateText; }
    if (_lastMinimapOpacity !== '0.5') { minimap.style.opacity = '0.5'; _lastMinimapOpacity = '0.5'; }
  } else {
    const cdText = rem > 0 ? `Cooldown: ${remSec}s` : 'Ready!';
    const remText = selectedAbility === 'radar' ? `${radarsRemaining}/${RADAR_PER_WAVE} left` :
                    selectedAbility === 'emp' ? `${empsRemaining}/${EMP_PER_WAVE} left` :
                    `${left}/${info.maxPerWave} left`;
    if (cdText !== _lastCooldownText) { cooldownEl.textContent = cdText; _lastCooldownText = cdText; }
    if (remText !== _lastRemainingText) { remainingEl.textContent = remText; _lastRemainingText = remText; }
    if (_lastMinimapOpacity !== '1') { minimap.style.opacity = '1'; _lastMinimapOpacity = '1'; }
  }
}, 400);

// Throttle draw to 30fps on mobile for less lag and battery
let lastDrawTime = 0;
const DRAW_INTERVAL_MS = 16;  // 60fps for real-time minimap
function tick(now) {
  const t = typeof now === 'number' ? now : performance.now();
  if (connected.classList.contains('hidden') === false) {
    if (t - lastDrawTime >= DRAW_INTERVAL_MS) {
      lastDrawTime = t;
      drawMinimap();
    }
  }
  requestAnimationFrame(tick);
}
drawMinimap();
requestAnimationFrame(tick);

btnStats.onclick = () => {
  statsPanel.classList.remove('hidden');
  statsContent.innerHTML = `
    Bombs Dropped: <strong>${stats.totalBombs}</strong><br>
    Total Kills: <strong>${stats.totalKills}</strong><br>
    Mega Strikes: <strong>${stats.megaStrikes}</strong> 💥<br>
    Supplies: <strong>${stats.totalSupplies}</strong><br>
    Radars Used: <strong>${stats.totalRadars}</strong><br>
    EMPs Used: <strong>${stats.totalEmps}</strong><br>
    Waves Assisted: <strong>${stats.wavesAssisted}</strong>
  `;
};

btnCloseStats.onclick = () => {
  statsPanel.classList.add('hidden');
};

btnToggleSound.onclick = () => {
  soundEnabled = !soundEnabled;
  btnToggleSound.textContent = soundEnabled ? 'Sound: On' : 'Sound: Off';
  btnToggleSound.setAttribute('aria-label', soundEnabled ? 'Sound effects on. Click to turn off' : 'Sound effects off. Click to turn on');
  try {
    localStorage.setItem('companion_sound', soundEnabled.toString());
  } catch (_) { /* ignore */ }
  if (soundEnabled) playSoundEffect('radar');
};

// Keyboard navigation support
document.addEventListener('keydown', (e) => {
  // Number keys 1-4 to select abilities
  if (e.key >= '1' && e.key <= '4' && !e.ctrlKey && !e.metaKey) {
    const abilities = [btnBomb, btnSupply, btnRadar, btnEmp];
    const index = parseInt(e.key) - 1;
    if (abilities[index]) {
      abilities[index].click();
      e.preventDefault();
    }
  }

  // Space or Enter to use radar (instant ability)
  if ((e.key === ' ' || e.key === 'Enter') && selectedAbility === 'radar' && !e.target.closest('button')) {
    btnRadar.click();
    e.preventDefault();
  }
});
