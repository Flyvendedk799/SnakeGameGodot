# Companion App Implementation – Claude AI Instructions

**Task**: Implement a mobile-ready companion web app for Karen Defense. Companion creates a session, gets a 6-char host code, and can drop helicopter bombs on the map. Main player (Godot) enters the code to connect. Hold D-pad Up (or L) to pan camera to the helicopter.

**Success criteria**: (1) Companion web app runs on Railway and shows host code. (2) Godot game connects via code and receives bomb drops. (3) Helicopter flies in, drops bomb, deals AoE damage. (4) Camera pans to helicopter when button held.

**Implementation order**: Execute steps 1–8 in sequence. Each step is self-contained.

---

## Step 1: Create companion/server/package.json

Create file `companion/server/package.json` with:

```json
{"name":"karen-defense-companion","version":"1.0.0","type":"module","scripts":{"start":"node index.js"},"dependencies":{"express":"^4.18.2","ws":"^8.14.2"}}
```

---

## Step 2: Create companion/server/index.js

Create file `companion/server/index.js` with this exact content:

```javascript
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
const COOLDOWN_MS = 30000;
const BOMBS_PER_WAVE = 2;

app.use(express.static(path.join(__dirname, 'client')));

app.get('/health', (req, res) => res.json({ ok: true }));

app.get('/session/create', (req, res) => {
  let code;
  do { code = makeCode(); } while (sessions.has(code));
  sessions.set(code, { game: null, companion: null, createdAt: Date.now(), dropsThisWave: 0, lastDropAt: 0 });
  res.json({ code });
});

const server = createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws) => {
  ws.role = null;
  ws.code = null;
  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw.toString());
      if (msg.type === 'join' && msg.code && msg.role) {
        const s = sessions.get(String(msg.code).toUpperCase());
        if (!s) { ws.send(JSON.stringify({ type: 'error', message: 'Invalid code' })); return; }
        ws.role = msg.role;
        ws.code = msg.code;
        if (msg.role === 'game') { s.game = ws; } else if (msg.role === 'companion') { s.companion = ws; s.dropsThisWave = 0; }
        ws.send(JSON.stringify({ type: 'joined', code: msg.code }));
        if (s.game) s.game.send(JSON.stringify({ type: 'companion_connected' }));
        if (s.companion) s.companion.send(JSON.stringify({ type: 'game_connected' }));
      } else if (msg.type === 'helicopter_drop' && ws.role === 'companion' && ws.code) {
        const s = sessions.get(ws.code);
        if (!s || !s.game) return;
        const now = Date.now();
        if (s.dropsThisWave >= BOMBS_PER_WAVE || (now - s.lastDropAt) < COOLDOWN_MS) return;
        const x = Math.max(0, Math.min(1, Number(msg.x) ?? 0.5));
        const y = Math.max(0, Math.min(1, Number(msg.y) ?? 0.5));
        s.dropsThisWave++; s.lastDropAt = now;
        s.game.send(JSON.stringify({ type: 'bomb_drop', x, y }));
        ws.send(JSON.stringify({ type: 'drop_ack', x, y }));
      } else if (msg.type === 'new_wave' && ws.role === 'game' && ws.code) {
        const s = sessions.get(ws.code);
        if (s) { s.dropsThisWave = 0; if (s.companion) s.companion.send(JSON.stringify({ type: 'new_wave' })); }
      }
    } catch (e) { /* ignore */ }
  });
  ws.on('close', () => {
    if (ws.code && ws.role) {
      const s = sessions.get(ws.code);
      if (s) {
        if (ws.role === 'game') s.game = null; else if (ws.role === 'companion') s.companion = null;
        if (!s.game && !s.companion) sessions.delete(ws.code);
      }
    }
  });
});

server.listen(PORT, () => console.log('Companion server on', PORT));
```

---

## Step 3: Create companion/client/index.html

Create file `companion/client/index.html` with:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
  <title>Karen Defense Companion</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div id="landing">
    <h1>Karen Defense</h1>
    <p>Companion Mode</p>
    <button id="start">Start as Companion</button>
  </div>
  <div id="waiting" class="hidden">
    <p>Share this code:</p>
    <p id="code"></p>
    <button id="copy">Copy</button>
    <p id="status">Waiting for game...</p>
  </div>
  <div id="connected" class="hidden">
    <p>Connected! Tap map to drop bomb.</p>
    <canvas id="minimap" width="300" height="300"></canvas>
    <p id="cooldown"></p>
  </div>
  <script src="app.js"></script>
</body>
</html>
```

---

## Step 4: Create companion/client/style.css

Create file `companion/client/style.css` with:

```css
* { box-sizing: border-box; }
body { margin: 0; min-height: 100vh; background: #1a1520; color: #e0d8e8; font-family: system-ui, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 1rem; }
#landing, #waiting, #connected { text-align: center; max-width: 400px; }
h1 { font-size: 1.8rem; margin-bottom: 0.3rem; }
p { color: #a0a0b0; margin: 0.5rem 0; }
button { min-width: 180px; min-height: 48px; font-size: 1.1rem; background: #4a3f6a; color: #fff; border: 2px solid #6a5a8a; border-radius: 8px; cursor: pointer; margin: 0.5rem; }
button:active { background: #5a4f7a; }
#code { font-size: 2.5rem; letter-spacing: 0.3em; font-weight: bold; color: #80ff90; margin: 1rem 0; }
#minimap { background: #0d0a12; border: 2px solid #3a3050; border-radius: 8px; margin: 1rem; touch-action: none; cursor: pointer; max-width: 100%; }
.hidden { display: none !important; }
```

---

## Step 5: Create companion/client/app.js

Create file `companion/client/app.js` with:

```javascript
const landing = document.getElementById('landing');
const waiting = document.getElementById('waiting');
const connected = document.getElementById('connected');
const codeEl = document.getElementById('code');
const cooldownEl = document.getElementById('cooldown');
const startBtn = document.getElementById('start');
const copyBtn = document.getElementById('copy');
const minimap = document.getElementById('minimap');

let ws = null, sessionCode = null, lastDropAt = 0;

startBtn.onclick = async () => {
  const r = await fetch('/session/create');
  const d = await r.json();
  sessionCode = d.code;
  codeEl.textContent = sessionCode;
  landing.classList.add('hidden');
  waiting.classList.remove('hidden');
  const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
  ws = new WebSocket(proto + '//' + location.host + '/ws');
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    if (m.type === 'game_connected') {
      waiting.classList.add('hidden');
      connected.classList.remove('hidden');
    } else if (m.type === 'drop_ack') {
      lastDropAt = Date.now();
    }
  };
  ws.onopen = () => ws.send(JSON.stringify({ type: 'join', code: sessionCode, role: 'companion' }));
};

copyBtn.onclick = () => navigator.clipboard.writeText(sessionCode);

function canDrop() { return !lastDropAt || (Date.now() - lastDropAt) >= 30000; }

function drawMap() {
  const c = minimap.getContext('2d');
  c.fillStyle = '#1a1520';
  c.fillRect(0, 0, 300, 300);
  c.strokeStyle = '#4a3f6a';
  c.strokeRect(10, 10, 280, 280);
}

function doDrop(e) {
  if (!canDrop() || !ws || ws.readyState !== 1) return;
  const r = minimap.getBoundingClientRect();
  const cx = e.clientX ?? (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
  const cy = e.clientY ?? (e.touches && e.touches[0] ? e.touches[0].clientY : 0);
  const x = (cx - r.left) / r.width, y = (cy - r.top) / r.height;
  if (x >= 0 && x <= 1 && y >= 0 && y <= 1) ws.send(JSON.stringify({ type: 'helicopter_drop', x, y }));
}

minimap.addEventListener('pointerdown', (e) => { e.preventDefault(); doDrop(e); }, { passive: false });

setInterval(() => {
  const rem = Math.max(0, 30 - (Date.now() - lastDropAt) / 1000);
  cooldownEl.textContent = rem > 0 ? 'Cooldown: ' + Math.ceil(rem) + 's' : 'Ready to drop';
}, 500);

drawMap();
```

---

## Step 6: Create companion/Dockerfile

Create file `companion/Dockerfile` with:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY server/package*.json ./
RUN npm ci --omit=dev
COPY server/ ./
COPY client/ ./client/
EXPOSE 3000
CMD ["node", "index.js"]
```

---

## Step 7: Create karen_defense/systems/companion_session.gd

Create file `karen_defense/systems/companion_session.gd` with:

```gdscript
class_name CompanionSessionManager
extends Node

signal bomb_drop_requested_at_normalized(x: float, y: float)
signal connection_status_changed(connected: bool)

@export var server_url: String = "wss://your-app.up.railway.app/ws"

var _ws: WebSocketPeer
var _code: String = ""
var _connecting: bool = false

func connect_with_code(code: String):
	_code = code.to_upper().strip_edges()
	if _code.length() != 6: return
	if server_url.is_empty(): return
	_disconnect()
	_ws = WebSocketPeer.new()
	_ws.connect_to_url(server_url)
	_connecting = true
	connection_status_changed.emit(false)

func _process(_delta: float):
	if _ws == null: return
	_ws.poll()
	var state = _ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if _connecting:
			_connecting = false
			_ws.send_text(JSON.stringify({ type = "join", code = _code, role = "game" }))
		while _ws.get_available_packet_count() > 0:
			var pkt = _ws.get_packet()
			var txt = pkt.get_string_from_utf8()
			var data = JSON.parse_string(txt)
			if data is Dictionary:
				if data.get("type") == "joined":
					connection_status_changed.emit(true)
				elif data.get("type") == "error":
					connection_status_changed.emit(false)
					_disconnect()
				elif data.get("type") == "bomb_drop":
					var x = float(data.get("x", 0.5))
					var y = float(data.get("y", 0.5))
					bomb_drop_requested_at_normalized.emit(x, y)
	elif state == WebSocketPeer.STATE_CLOSED:
		connection_status_changed.emit(false)
		_ws = null

func notify_new_wave():
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify({ type = "new_wave" }))

func is_connected() -> bool:
	return _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN

func disconnect_session():
	_disconnect()
	connection_status_changed.emit(false)

func _disconnect():
	if _ws != null:
		_ws.close()
		_ws = null
	_connecting = false
```

---

## Step 8: Create karen_defense/entities/helicopter_bomb.gd

Create file `karen_defense/entities/helicopter_bomb.gd` with:

```gdscript
class_name HelicopterBombEntity
extends Node2D

var game = null
var drop_pos: Vector2
var phase: String = "fly"
var timer: float = 0.0
var fly_duration: float = 1.2
var drop_duration: float = 0.5
var start_pos: Vector2
var bomb_ground_pos: Vector2
const BLAST_RADIUS: float = 90.0
const DAMAGE: int = 60

func setup(game_ref, world_pos: Vector2):
	game = game_ref
	drop_pos = world_pos
	var map = game.map
	start_pos = Vector2(map.FORT_LEFT - 80, map.get_fort_center().y)
	position = start_pos

func update_helicopter(delta: float) -> bool:
	timer += delta
	if phase == "fly":
		var t = clampf(timer / fly_duration, 0, 1)
		position = start_pos.lerp(Vector2(drop_pos.x, start_pos.y), t)
		if t >= 1:
			phase = "drop"
			timer = 0
			bomb_ground_pos = drop_pos
			position = Vector2(drop_pos.x, start_pos.y)
	elif phase == "drop":
		if timer >= drop_duration:
			_explode()
			return true
	queue_redraw()
	return false

func _explode():
	for enemy in game.enemy_container.get_children():
		if enemy.state in [EnemyEntity.EnemyState.DEAD, EnemyEntity.EnemyState.DYING]: continue
		var dist = bomb_ground_pos.distance_to(enemy.position)
		if dist <= BLAST_RADIUS:
			var falloff = 1.0 - (dist / BLAST_RADIUS) * 0.5
			var dmg = int(DAMAGE * falloff)
			enemy.last_damager = game.player_node
			enemy.take_damage(dmg, game)
			game.spawn_damage_number(enemy.position, str(dmg), Color8(255, 180, 50))
	game.particles.emit_burst(bomb_ground_pos.x, bomb_ground_pos.y, Color8(255, 160, 30), 20, 0.6)
	game.start_shake(5.0, 0.2)
	if game.sfx:
		game.sfx.play_grenade_explode()
	queue_free()

func _draw():
	if phase == "fly":
		draw_circle(Vector2.ZERO, 18, Color.DARK_GRAY)
		draw_circle(Vector2(-8, -12), 6, Color.GRAY)
		draw_circle(Vector2(8, -12), 6, Color.GRAY)
	elif phase == "drop":
		var fall_y = -50 * (1 - timer / drop_duration)
		draw_circle(Vector2(0, fall_y), 12, Color8(80, 60, 40))
```

---

## Step 9: Edit project.godot – add look_at_helicopter input

In the `[input]` section, after the `p2_sprint` block and before `[physics]`, insert:

```
look_at_helicopter={
"deadzone": 0.5,
"events": [Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":11,"pressure":0.0,"pressed":true,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":76,"physical_keycode":0,"key_label":0,"unicode":108,"location":0,"echo":false,"script":null)
]
}
```

---

## Step 10: Edit karen_defense/karen_defense.gd

**10a. Add variables** at class level (with other vars):
```gdscript
var companion_session: CompanionSessionManager
var helicopter_entity: Node2D
```

**10b. In `_setup_systems()`**, insert the following block **after** `game_over_screen.setup(self)` and **before** `world_select.setup(self)`:
```gdscript
companion_session = CompanionSessionManager.new()
companion_session.name = "CompanionSession"
add_child(companion_session)
companion_session.bomb_drop_requested_at_normalized.connect(_on_companion_bomb_drop)
```

**10c. Add function `_on_companion_bomb_drop(x: float, y: float)`**:
```gdscript
func _on_companion_bomb_drop(x: float, y: float):
	var map = self.map
	var wx = map.FORT_LEFT + x * (map.FORT_RIGHT - map.FORT_LEFT)
	var wy = map.FORT_TOP + y * (map.FORT_BOTTOM - map.FORT_TOP)
	var heli = HelicopterBombEntity.new()
	heli.setup(self, Vector2(wx, wy))
	projectile_container.add_child(heli)
	if helicopter_entity and is_instance_valid(helicopter_entity):
		helicopter_entity.queue_free()
	helicopter_entity = heli
```

**10d. In `_process_wave()`**, after the grenade/projectile loop and **before** `combat_system.resolve_frame(delta)`, add:
```gdscript
if helicopter_entity and is_instance_valid(helicopter_entity):
	if helicopter_entity.update_helicopter(delta):
		helicopter_entity = null
```

**10e. In `start_wave()`**, add at the end (before the closing of the function):
```gdscript
if companion_session and companion_session.is_connected():
	companion_session.notify_new_wave()
```

**10f. In `_update_camera_follow(delta)`**, replace the first line `var target = map.get_fort_center()` with:
```gdscript
var target: Vector2
var use_helicopter = companion_session and companion_session.is_connected() and helicopter_entity and is_instance_valid(helicopter_entity) and Input.is_action_pressed("look_at_helicopter")
if use_helicopter:
	target = helicopter_entity.position
else:
	target = map.get_fort_center()
	if not player_node.is_dead:
		target = player_node.position
		if player_node.is_moving:
			target += player_node.last_move_dir * 60.0
	if p2_joined and player2_node and not player2_node.is_dead:
		if not player_node.is_dead:
			target = (player_node.position + player2_node.position) / 2.0
			if player_node.is_moving:
				target += player_node.last_move_dir * 30.0
			if player2_node.is_moving:
				target += player2_node.last_move_dir * 30.0
		else:
			target = player2_node.position
			if player2_node.is_moving:
				target += player2_node.last_move_dir * 60.0
	elif player_node.is_dead and p2_joined and player2_node:
		target = player2_node.position
```

(Keep the existing clamp/lerp block that follows unchanged.)

---

## Step 11: Edit karen_defense/ui/world_select.gd

**11a. Add variables** at class level:
```gdscript
var companion_code: String = ""
var companion_connect_rect: Rect2
var companion_status: String = ""
```

**11b. In `_build_world_rects()`**, add at the end (before the function closes):
```gdscript
companion_connect_rect = Rect2(500, 620, 280, 50)
```

**11c. In `setup(game_ref)`**, add:
```gdscript
game.companion_session.connection_status_changed.connect(_on_companion_status)
```

**11d. Add function `_on_companion_status(connected: bool)`**:
```gdscript
func _on_companion_status(connected: bool):
	companion_status = "Connected!" if connected else "Disconnected"
```

**11e. In `handle_input(event)`**, add **before** the final `return false`:
```gdscript
# Companion code input (keyboard)
if event is InputEventKey and event.pressed and not event.echo:
	if event.keycode == KEY_BACKSPACE:
		companion_code = companion_code.substr(0, companion_code.length() - 1)
		return true
	var ch = String.chr(event.unicode).to_upper()
	if ch.length() == 1 and ("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains(ch)) and companion_code.length() < 6:
		companion_code += ch
		return true

# Companion Connect button
if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
	if companion_connect_rect.has_point(event.position) and companion_code.length() == 6:
		game.companion_session.connect_with_code(companion_code)
		companion_status = "Connecting..."
		return true
```

**11f. In `_draw()`**, add at the end (after the footer draw_string):
```gdscript
# Companion section
draw_string(font, Vector2(500, 600), "Companion: Enter 6-char code", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(180, 170, 200))
draw_rect(companion_connect_rect, Color8(60, 55, 80))
draw_string(font, Vector2(510, 652), (companion_code + "______").substr(0, 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
var status_txt = "Connected!" if game.companion_session.is_connected() else (companion_status if companion_status else "Connect")
draw_string(font, Vector2(510, 675), status_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(100, 220, 150))
```

---

## Post-Implementation

1. Deploy `companion/` to Railway (root directory `companion/`).
2. Set `CompanionSession.server_url` in Godot Inspector to `wss://YOUR_RAILWAY_URL/ws`.
3. Test: companion opens web app, gets code; Godot enters code on World Select; play a wave; companion taps minimap to drop bombs; main player holds D-pad Up to look at helicopter.
