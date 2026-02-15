class_name LockedDoorEntity
extends Node2D

var is_locked: bool = true
var door_id: String = ""
var required_keys: int = 1
var anim_time: float = 0.0
var open_timer: float = 0.0  # Opening animation
var door_width: float = 40.0
var door_height: float = 60.0

func initialize(id: String, keys_needed: int = 1):
	door_id = id
	required_keys = keys_needed

func try_open(player, game) -> bool:
	if not is_locked:
		return true
	if not player.has_method("get") or player.get("key_count") == null:
		return false
	if player.key_count >= required_keys:
		player.key_count -= required_keys
		is_locked = false
		open_timer = 0.6
		if game.sfx:
			game.sfx.play_door_open()
		game.particles.emit_burst(position.x, position.y, Color8(255, 215, 0), 15)
		game.spawn_damage_number(position, "UNLOCKED!", Color8(255, 215, 0), true)
		return true
	else:
		game.spawn_damage_number(position, "NEED KEY", Color8(255, 80, 80))
		if game.sfx:
			game.sfx.play_error()
		return false

func is_blocking() -> bool:
	return is_locked

func update_door(delta: float):
	anim_time += delta
	if open_timer > 0:
		open_timer -= delta
	queue_redraw()

func _draw():
	if is_locked:
		# Door frame
		draw_rect(Rect2(-door_width/2 - 3, -door_height, door_width + 6, door_height + 3), Color8(60, 50, 40))
		# Door panels
		draw_rect(Rect2(-door_width/2, -door_height, door_width/2 - 1, door_height), Color8(140, 100, 60))
		draw_rect(Rect2(1, -door_height, door_width/2 - 1, door_height), Color8(130, 90, 55))
		# Lock
		var lock_y = -door_height * 0.4
		draw_circle(Vector2(0, lock_y), 6, Color8(200, 170, 50))
		draw_rect(Rect2(-4, lock_y, 8, 8), Color8(180, 150, 40))
		# Keyhole
		draw_circle(Vector2(0, lock_y + 2), 2, Color8(40, 30, 20))
		# Key count needed
		var txt = "x%d" % required_keys if required_keys > 1 else ""
		if txt != "":
			draw_string(ThemeDB.fallback_font, Vector2(8, lock_y + 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(255, 220, 100))
		# Glow pulse
		var pulse = sin(anim_time * 2.0) * 0.1 + 0.2
		draw_rect(Rect2(-door_width/2, -door_height, door_width, door_height), Color(0.8, 0.6, 0.2, pulse))
	elif open_timer > 0:
		# Opening animation
		var t = 1.0 - (open_timer / 0.6)
		var offset = t * door_width * 0.6
		draw_rect(Rect2(-door_width/2 - 3, -door_height, door_width + 6, door_height + 3), Color8(60, 50, 40))
		draw_rect(Rect2(-door_width/2 - offset, -door_height, door_width/2 - 1, door_height), Color8(140, 100, 60, int(255 * (1.0 - t))))
		draw_rect(Rect2(1 + offset, -door_height, door_width/2 - 1, door_height), Color8(130, 90, 55, int(255 * (1.0 - t))))
	# If fully open, draw nothing (or thin frame)
	elif not is_locked:
		draw_rect(Rect2(-door_width/2 - 3, -door_height, 3, door_height + 3), Color8(60, 50, 40, 100))
		draw_rect(Rect2(door_width/2, -door_height, 3, door_height + 3), Color8(60, 50, 40, 100))
