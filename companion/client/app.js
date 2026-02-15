const landing = document.getElementById('landing');
const waiting = document.getElementById('waiting');
const connected = document.getElementById('connected');
const codeEl = document.getElementById('code');
const cooldownEl = document.getElementById('cooldown');
const remainingEl = document.getElementById('remaining');
const abilityHintEl = document.getElementById('abilityHint');
const connStatusEl = document.getElementById('connStatus');
const startBtn = document.getElementById('start');
const copyBtn = document.getElementById('copy');
const reconnectBtn = document.getElementById('reconnect');
const minimap = document.getElementById('minimap');
const btnBomb = document.getElementById('btnBomb');
const btnSupply = document.getElementById('btnSupply');

const COOLDOWN_BOMB_MS = 30000;
const COOLDOWN_SUPPLY_MS = 45000;
const BOMBS_PER_WAVE = 2;
const SUPPLIES_PER_WAVE = 1;

let ws = null, sessionCode = null;
let lastBombAt = 0, lastSupplyAt = 0;
let bombsRemaining = BOMBS_PER_WAVE, suppliesRemaining = SUPPLIES_PER_WAVE;
let selectedAbility = 'bomb';

const abilityInfo = {
  bomb: { cooldownMs: COOLDOWN_BOMB_MS, maxPerWave: BOMBS_PER_WAVE, hint: 'Tap map to drop bomb' },
  supply: { cooldownMs: COOLDOWN_SUPPLY_MS, maxPerWave: SUPPLIES_PER_WAVE, hint: 'Tap map to drop supply crate' }
};

function setupWsHandlers(socket) {
  socket.onmessage = (e) => {
    let m;
    try { m = JSON.parse(e.data); } catch (_) { return; }
    if (m.type === 'game_connected') {
      bombsRemaining = BOMBS_PER_WAVE;
      suppliesRemaining = SUPPLIES_PER_WAVE;
      waiting.classList.add('hidden');
      connected.classList.remove('hidden');
      connStatusEl.innerHTML = '<span class="status-dot online"></span> Connected';
    } else if (m.type === 'drop_ack') {
      if (m.ability === 'bomb') lastBombAt = Date.now();
      else if (m.ability === 'supply') lastSupplyAt = Date.now();
      if (typeof m.remaining === 'number') {
        if (m.ability === 'bomb') bombsRemaining = m.remaining;
        else if (m.ability === 'supply') suppliesRemaining = m.remaining;
      }
      _hapticFeedback();
    } else if (m.type === 'new_wave') {
      bombsRemaining = BOMBS_PER_WAVE;
      suppliesRemaining = SUPPLIES_PER_WAVE;
    }
  };
  socket.onclose = () => {
    ws = null;
    connected.classList.add('hidden');
    waiting.classList.remove('hidden');
    statusEl.textContent = 'Disconnected. Tap Reconnect to rejoin with the same code.';
    reconnectBtn.classList.remove('hidden');
    connStatusEl.innerHTML = '<span class="status-dot offline"></span> Disconnected';
  };
  socket.onerror = () => {};
}

function _hapticFeedback() {
  if (navigator.vibrate) navigator.vibrate(30);
}

startBtn.onclick = async () => {
  try {
    const r = await fetch('/session/create');
    const d = await r.json();
    sessionCode = d.code;
    codeEl.textContent = sessionCode;
    landing.classList.add('hidden');
    waiting.classList.remove('hidden');
    hideReconnect();
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(proto + '//' + location.host + '/ws');
    setupWsHandlers(ws);
    ws.onopen = () => ws.send(JSON.stringify({ type: 'join', code: sessionCode, role: 'companion' }));
  } catch (err) {
    statusEl.textContent = 'Failed to create session. Retry?';
    if (reconnectBtn) reconnectBtn.classList.remove('hidden');
  }
};

const statusEl = document.getElementById('status');
function hideReconnect() {
  reconnectBtn.classList.add('hidden');
  statusEl.textContent = 'Waiting for game...';
}

reconnectBtn.onclick = () => {
  if (!sessionCode || ws) return;
  hideReconnect();
  const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
  ws = new WebSocket(proto + '//' + location.host + '/ws');
  setupWsHandlers(ws);
  ws.onopen = () => ws.send(JSON.stringify({ type: 'join', code: sessionCode, role: 'companion' }));
};

copyBtn.onclick = () => {
  if (sessionCode) navigator.clipboard.writeText(sessionCode);
  _hapticFeedback();
};

function canDrop(ability) {
  const info = abilityInfo[ability];
  if (!info) return false;
  const lastAt = ability === 'bomb' ? lastBombAt : lastSupplyAt;
  if (!lastAt) return true;
  if (Date.now() - lastAt < info.cooldownMs) return false;
  const rem = ability === 'bomb' ? bombsRemaining : suppliesRemaining;
  return rem > 0;
}

function getCooldownRemaining(ability) {
  const lastAt = ability === 'bomb' ? lastBombAt : lastSupplyAt;
  if (!lastAt) return 0;
  const info = abilityInfo[ability];
  return Math.max(0, info.cooldownMs - (Date.now() - lastAt));
}

function drawMap() {
  const c = minimap.getContext('2d');
  c.fillStyle = '#1a1520';
  c.fillRect(0, 0, 300, 300);
  c.strokeStyle = '#4a3f6a';
  c.strokeRect(10, 10, 280, 280);
}

function doDrop(e) {
  if (!ws || ws.readyState !== 1) return;
  if (!canDrop(selectedAbility)) {
    minimap.classList.add('reject-flash');
    setTimeout(() => minimap.classList.remove('reject-flash'), 200);
    return;
  }
  const r = minimap.getBoundingClientRect();
  const rw = Math.max(1, r.width);
  const rh = Math.max(1, r.height);
  const cx = e.clientX ?? (e.touches && e.touches[0] ? e.touches[0].clientX : r.left);
  const cy = e.clientY ?? (e.touches && e.touches[0] ? e.touches[0].clientY : r.top);
  const x = Math.max(0, Math.min(1, (cx - r.left) / rw));
  const y = Math.max(0, Math.min(1, (cy - r.top) / rh));
  const msg = selectedAbility === 'bomb'
    ? { type: 'helicopter_drop', x, y }
    : { type: 'supply_drop', x, y };
  ws.send(JSON.stringify(msg));
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
  abilityHintEl.textContent = abilityInfo.bomb.hint;
};
btnSupply.onclick = () => {
  selectedAbility = 'supply';
  btnSupply.classList.add('selected');
  btnBomb.classList.remove('selected');
  abilityHintEl.textContent = abilityInfo.supply.hint;
};

setInterval(() => {
  const info = abilityInfo[selectedAbility];
  const rem = getCooldownRemaining(selectedAbility);
  const remSec = Math.ceil(rem / 1000);
  cooldownEl.textContent = rem > 0 ? `Cooldown: ${remSec}s` : 'Ready!';
  const left = selectedAbility === 'bomb' ? bombsRemaining : suppliesRemaining;
  remainingEl.textContent = `${left}/${info.maxPerWave} left this wave`;
}, 400);

drawMap();
