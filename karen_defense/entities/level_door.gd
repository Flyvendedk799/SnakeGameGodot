class_name LevelDoor
extends Node2D

## Phase 5.2: Locked door requiring keys
## Player must have key_count >= keys_required to open
## Visual: door frame + lock icon + key count display
## Opens permanently, does not block after player has enough keys

var keys_required: int = 1
var is_open: bool = false
var width: float = 40.0
var height: float = 80.0
var door_color: Color = Color8(120, 80, 40)
var lock_color: Color = Color8(255, 200, 50)

signal door_opened

func try_open(player) -> bool:
	"""Attempt to open door. Returns true if opened."""
	if is_open:
		return true
	if player.get("key_count") == null:
		return false
	if player.key_count >= keys_required:
		player.key_count -= keys_required
		_open()
		return true
	return false

func _open():
	is_open = true
	emit_signal("door_opened")
	# Play open animation then remove collision
	queue_redraw()

func _draw():
	if is_open:
		# Faded open state (door swung open)
		var open_col = door_color
		open_col.a = 0.2
		draw_rect(Rect2(-width / 2.0, -height / 2.0, width, height), open_col)
		return

	# Closed door
	draw_rect(Rect2(-width / 2.0, -height / 2.0, width, height), door_color)

	# Door frame
	var frame_col = door_color.darkened(0.3)
	draw_rect(Rect2(-width / 2.0, -height / 2.0, 4, height), frame_col)
	draw_rect(Rect2(width / 2.0 - 4, -height / 2.0, 4, height), frame_col)
	draw_rect(Rect2(-width / 2.0, -height / 2.0, width, 4), frame_col)

	# Lock icon (circle)
	draw_circle(Vector2(0, 0), 10.0, lock_color)
	draw_circle(Vector2(0, 0), 7.0, door_color)

	# Key count label
	var font = ThemeDB.fallback_font
	var label = "x%d" % keys_required
	draw_string(font, Vector2(-8, 25), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func get_collision_rect() -> Rect2:
	if is_open:
		return Rect2(0, 0, 0, 0)  # No collision when open
	return Rect2(position.x - width / 2.0, position.y - height / 2.0, width, height)

func is_blocking() -> bool:
	return not is_open
