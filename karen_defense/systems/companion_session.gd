class_name CompanionSessionManager
extends Node

signal bomb_drop_requested_at_normalized(x: float, y: float)
signal supply_drop_requested_at_normalized(x: float, y: float)
signal connection_status_changed(connected: bool)

@export var server_url: String = "wss://snakegamegodot-production.up.railway.app/ws"

var _ws: WebSocketPeer
var _code: String = ""
var _connecting: bool = false
var _reconnect_timer: float = 0.0
var _reconnect_backoff: float = 2.0
const RECONNECT_MAX: float = 30.0

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
			_ws.send_text(JSON.stringify({ type = "join", code = _code, role = "game" }))
		while _ws != null and _ws.get_available_packet_count() > 0:
			var pkt = _ws.get_packet()
			var txt = pkt.get_string_from_utf8()
			var data = JSON.parse_string(txt)
			if data is Dictionary:
				match data.get("type"):
					"joined":
						connection_status_changed.emit(true)
					"error":
						connection_status_changed.emit(false)
						_code = ""
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

func send_bomb_impact(nx: float, ny: float, kills: int):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({ type = "bomb_impact", x = clampf(nx, 0, 1), y = clampf(ny, 0, 1), kills = kills }))

func send_supply_impact(nx: float, ny: float):
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({ type = "supply_impact", x = clampf(nx, 0, 1), y = clampf(ny, 0, 1) }))

func is_session_connected() -> bool:
	return _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN

func disconnect_session():
	_code = ""
	_disconnect()
	connection_status_changed.emit(false)

func _disconnect():
	if _ws != null:
		_ws.close()
		_ws = null
	_connecting = false
