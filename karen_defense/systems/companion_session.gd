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

func _dict_has_only_keys(d: Dictionary, allowed: Array[String]) -> bool:
	if d.size() != allowed.size():
		return false
	for key in d.keys():
		if not allowed.has(str(key)):
			return false
	return true

func _num_in_range(v, min_v: float, max_v: float) -> bool:
	if not (v is float or v is int):
		return false
	var n := float(v)
	return is_finite(n) and n >= min_v and n <= max_v

func _parse_server_message(data: Dictionary) -> Dictionary:
	if not data.has("type") or not (data.get("type") is String):
		return {}
	var t := str(data.get("type"))
	match t:
		"joined":
			if not _dict_has_only_keys(data, ["type", "code", "token"]): return {}
			if not (data.get("code") is String) or not (data.get("token") is String): return {}
			return data
		"error":
			if not _dict_has_only_keys(data, ["type", "code"]): return {}
			if not (data.get("code") is String): return {}
			return data
		"bomb_drop", "supply_drop", "emp_drop":
			if not _dict_has_only_keys(data, ["type", "x", "y"]): return {}
			if not _num_in_range(data.get("x"), 0.0, 1.0) or not _num_in_range(data.get("y"), 0.0, 1.0): return {}
			return { "type": t, "x": float(data.get("x")), "y": float(data.get("y")) }
		"radar_ping", "companion_connected":
			if not _dict_has_only_keys(data, ["type"]): return {}
			return data
		"chopper_input":
			if not _dict_has_only_keys(data, ["type", "x", "y"]): return {}
			if not _num_in_range(data.get("x"), -1.0, 1.0) or not _num_in_range(data.get("y"), -1.0, 1.0): return {}
			return { "type": t, "x": float(data.get("x")), "y": float(data.get("y")) }
		_:
			return {}

func connect_with_code(code: String):
	_code = code.to_upper().strip_edges()
	if _code.length() != 6: return
	if server_url.is_empty(): return
	_disconnect()
	_reconnect_timer = 0.0
	_reconnect_backoff = 2.0
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
			var parsed := _parse_server_message(data)
			if parsed.is_empty():
				continue
			match parsed.get("type"):
					"joined":
						# Store reconnect token for future reconnections
						_reconnect_token = str(parsed.get("token"))
						connection_status_changed.emit(true)
					"error":
						connection_status_changed.emit(false)
						_code = ""
						_reconnect_token = ""
						_disconnect()
						return
					"bomb_drop":
						var x = float(parsed.get("x", 0.5))
						var y = float(parsed.get("y", 0.5))
						bomb_drop_requested_at_normalized.emit(x, y)
					"supply_drop":
						var x = float(parsed.get("x", 0.5))
						var y = float(parsed.get("y", 0.5))
						supply_drop_requested_at_normalized.emit(x, y)
					"emp_drop":
						var x = float(parsed.get("x", 0.5))
						var y = float(parsed.get("y", 0.5))
						emp_drop_requested_at_normalized.emit(x, y)
					"radar_ping":
						radar_ping_requested.emit()
					"chopper_input":
						var ax = float(parsed.get("x", 0))
						var ay = float(parsed.get("y", 0))
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
	var payload = { type = "minimap", enemies = enemies, allies = allies, players = players, wave = wave, state = state }
	if chopper_pos != null:
		payload["chopper"] = chopper_pos
	_ws.send_text(JSON.stringify(payload))

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
