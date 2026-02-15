class_name CompanionSessionManager
extends Node

signal bomb_drop_requested_at_normalized(x: float, y: float)
signal chopper_input_received(ax: float, ay: float)
signal supply_drop_requested_at_normalized(x: float, y: float)
signal emp_drop_requested_at_normalized(x: float, y: float)
signal radar_ping_requested()
signal connection_status_changed(connected: bool)

@export var server_url: String = "wss://snakegamegodot-production.up.railway.app/ws"

var _ws: WebSocketPeer
var _code: String = ""
var _reconnect_token: String = ""
var _connecting: bool = false
var _reconnect_timer: float = 0.0
var _reconnect_backoff: float = 2.0
const RECONNECT_MAX: float = 30.0
const MINIMAP_PROTOCOL_VERSION: int = 1
const MINIMAP_KEYFRAME_SECONDS: float = 2.0
const MINIMAP_QUANT_MAX: int = 1023

var _minimap_seq: int = 0
var _minimap_last_sent_ms: int = 0
var _minimap_last_full_ms: int = 0
var _minimap_prev_enemies: Dictionary = {}
var _minimap_prev_allies: Dictionary = {}
var _minimap_prev_players: Dictionary = {}
var _minimap_prev_chopper: Variant = null

func connect_with_code(code: String):
	_code = code.to_upper().strip_edges()
	if _code.length() != 6: return
	if server_url.is_empty(): return
	_disconnect()
	_reconnect_timer = 0.0
	_reconnect_backoff = 2.0
	_reset_minimap_stream_state()
	_connect()

func _connect():
	_ws = WebSocketPeer.new()
	_ws.connect_to_url(server_url)
	_connecting = true
	connection_status_changed.emit(false)
	# Add jitter to backoff to prevent thundering herd
	var jitter = randf_range(-2.0, 2.0)
	_reconnect_backoff = clampf(_reconnect_backoff + jitter, 2.0, RECONNECT_MAX)

func _process(delta: float):
	if _ws == null:
		# Auto-reconnect when we had a code and lost connection
		if _code.length() == 6 and server_url.length() > 0:
			_reconnect_timer -= delta
			if _reconnect_timer <= 0:
				_connect()
				_reconnect_timer = _reconnect_backoff
				_reconnect_backoff = minf(RECONNECT_MAX, _reconnect_backoff * 2.0)
		return
	_ws.poll()
	var state = _ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if _connecting:
			_reconnect_backoff = 2.0
			_connecting = false
			_reset_minimap_stream_state()
			# Use token-based rejoin if we have it, otherwise use code
			if _reconnect_token.length() == 12:
				_ws.send_text(JSON.stringify({ type = "rejoin", token = _reconnect_token, role = "game" }))
			else:
				_ws.send_text(JSON.stringify({ type = "join", code = _code, role = "game" }))
		while _ws != null and _ws.get_available_packet_count() > 0:
			var pkt = _ws.get_packet()
			if pkt.size() == 0: continue
			var txt = pkt.get_string_from_utf8()
			if txt.is_empty(): continue
			var data = JSON.parse_string(txt)
			if not data is Dictionary: continue
			if not data.has("type"): continue
			if data is Dictionary:
				match data.get("type"):
					"joined":
						# Store reconnect token for future reconnections
						if data.has("token"):
							_reconnect_token = str(data.get("token"))
						connection_status_changed.emit(true)
					"error":
						connection_status_changed.emit(false)
						_code = ""
						_reconnect_token = ""
						_disconnect()
						return
					"bomb_drop":
						var x = float(data.get("x", 0.5))
						var y = float(data.get("y", 0.5))
						bomb_drop_requested_at_normalized.emit(x, y)
					"supply_drop":
						var x = float(data.get("x", 0.5))
						var y = float(data.get("y", 0.5))
						supply_drop_requested_at_normalized.emit(x, y)
					"emp_drop":
						var x = float(data.get("x", 0.5))
						var y = float(data.get("y", 0.5))
						emp_drop_requested_at_normalized.emit(x, y)
					"radar_ping":
						radar_ping_requested.emit()
					"chopper_input":
						var ax = float(data.get("x", 0))
						var ay = float(data.get("y", 0))
						chopper_input_received.emit(ax, ay)
	elif state == WebSocketPeer.STATE_CLOSED:
		connection_status_changed.emit(false)
		_ws = null
		_reconnect_timer = _reconnect_backoff

func notify_new_wave():
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify({ type = "new_wave" }))

func send_minimap(enemies: Array, allies: Array, players: Array):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var payload = { type = "minimap", enemies = enemies, allies = allies, players = players }
	_ws.send_text(JSON.stringify(payload))

func send_minimap_with_state(enemies: Array, allies: Array, players: Array, wave: int, state: String, chopper_pos = null):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var now_ms := Time.get_ticks_msec()
	var full_due := _minimap_last_full_ms == 0 or (now_ms - _minimap_last_full_ms) >= int(MINIMAP_KEYFRAME_SECONDS * 1000.0)

	var current_enemies := _serialize_entity_group(enemies, true)
	var current_allies := _serialize_entity_group(allies, false)
	var current_players := _serialize_entity_group(players, false)
	var current_chopper = _serialize_chopper(chopper_pos)

	_minimap_seq += 1
	var payload: Dictionary
	if full_due:
		payload = {
			type = "minimap_full",
			v = MINIMAP_PROTOCOL_VERSION,
			seq = _minimap_seq,
			wave = wave,
			state = state,
			enemies = _map_values_array(current_enemies),
			allies = _map_values_array(current_allies),
			players = _map_values_array(current_players)
		}
		if current_chopper != null:
			payload["chopper"] = current_chopper
		_minimap_last_full_ms = now_ms
	else:
		payload = {
			type = "minimap_delta",
			v = MINIMAP_PROTOCOL_VERSION,
			seq = _minimap_seq,
			base_seq = _minimap_seq - 1,
			wave = wave,
			state = state,
			enemies = _build_group_delta(_minimap_prev_enemies, current_enemies),
			allies = _build_group_delta(_minimap_prev_allies, current_allies),
			players = _build_group_delta(_minimap_prev_players, current_players)
		}
		if current_chopper != null:
			if _minimap_prev_chopper == null or not _entries_equal(_minimap_prev_chopper, current_chopper):
				payload["chopper"] = current_chopper
		elif _minimap_prev_chopper != null:
			payload["chopper_removed"] = true

	_ws.send_text(JSON.stringify(payload))
	_minimap_last_sent_ms = now_ms
	_minimap_prev_enemies = current_enemies
	_minimap_prev_allies = current_allies
	_minimap_prev_players = current_players
	_minimap_prev_chopper = current_chopper


func _reset_minimap_stream_state():
	_minimap_seq = 0
	_minimap_last_sent_ms = 0
	_minimap_last_full_ms = 0
	_minimap_prev_enemies.clear()
	_minimap_prev_allies.clear()
	_minimap_prev_players.clear()
	_minimap_prev_chopper = null

func _serialize_entity_group(raw_entries: Array, include_boss: bool) -> Dictionary:
	var out: Dictionary = {}
	for entry in raw_entries:
		if not entry is Dictionary:
			continue
		var id := str(entry.get("id", "")).strip_edges()
		if id.is_empty():
			continue
		var encoded = {
			id = id,
			x = _quantize_normalized(float(entry.get("x", 0.0))),
			y = _quantize_normalized(float(entry.get("y", 0.0)))
		}
		if include_boss:
			encoded["boss"] = bool(entry.get("boss", false))
		out[id] = encoded
	return out

func _serialize_chopper(chopper_pos):
	if chopper_pos == null:
		return null
	if not (chopper_pos is Array) or chopper_pos.size() < 2:
		return null
	return {
		id = "chopper",
		x = _quantize_normalized(float(chopper_pos[0])),
		y = _quantize_normalized(float(chopper_pos[1]))
	}

func _quantize_normalized(value: float) -> int:
	return int(round(clampf(value, 0.0, 1.0) * float(MINIMAP_QUANT_MAX)))

func _map_values_array(map: Dictionary) -> Array:
	var out: Array = []
	for value in map.values():
		out.append(value)
	return out

func _build_group_delta(prev_map: Dictionary, current_map: Dictionary) -> Dictionary:
	var upserts: Array = []
	var removed: Array = []
	for id in current_map.keys():
		if not prev_map.has(id) or not _entries_equal(prev_map[id], current_map[id]):
			upserts.append(current_map[id])
	for id in prev_map.keys():
		if not current_map.has(id):
			removed.append(id)
	return { upserts = upserts, removed = removed }

func _entries_equal(a, b) -> bool:
	if not (a is Dictionary and b is Dictionary):
		return false
	return int(a.get("x", -1)) == int(b.get("x", -2)) \
		and int(a.get("y", -1)) == int(b.get("y", -2)) \
		and bool(a.get("boss", false)) == bool(b.get("boss", false))

func send_bomb_impact(nx: float, ny: float, kills: int):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({ type = "bomb_impact", x = clampf(nx, 0, 1), y = clampf(ny, 0, 1), kills = kills }))

func send_supply_impact(nx: float, ny: float):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({ type = "supply_impact", x = clampf(nx, 0, 1), y = clampf(ny, 0, 1) }))

func send_game_state(state_name: String):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({ type = "game_state", state = state_name }))

func is_session_connected() -> bool:
	return _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN

func disconnect_session():
	_code = ""
	_reconnect_token = ""
	_disconnect()
	connection_status_changed.emit(false)

func _disconnect():
	if _ws != null:
		_ws.close()
		_ws = null
	_connecting = false
	_reset_minimap_stream_state()
