class_name DoorEntity
extends Node2D

var is_open: bool = false
var is_vertical: bool = false  # true = door in vertical wall (panels slide up/down)
var open_progress: float = 0.0  # 0.0 = fully closed, 1.0 = fully open
var reinforced: bool = false
var reinforcement_hp: int = 0
var max_reinforcement_hp: int = 5  # Enemy strikes needed to force open
var door_index: int = -1

const DOOR_W = 70.0   # Width of the doorway opening (matches ENTRANCE_WIDTH)
const DOOR_H = 22.0   # Thickness of the door (matches WALL_THICKNESS)
const ANIM_SPEED = 5.0 # Smooth animation lerp speed

var hit_flash_timer: float = 0.0
var anim_time: float = 0.0

func _process(delta):
	var target = 1.0 if is_open else 0.0
	open_progress = lerpf(open_progress, target, delta * ANIM_SPEED)
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	anim_time += delta
	queue_redraw()

# --- Public API ---

func toggle_door():
	"""Player toggles the door open or closed."""
	is_open = not is_open

func open_door():
	is_open = true

func close_door():
	is_open = false

func try_enemy_open() -> bool:
	"""Enemy attempts to force the door open. Returns true if the door opened."""
	if is_open:
		return true
	if reinforced and reinforcement_hp > 0:
		reinforcement_hp -= 1
		hit_flash_timer = 0.15
		if reinforcement_hp <= 0:
			reinforced = false
			open_door()
			return true
		return false
	# Not reinforced — opens immediately
	open_door()
	return true

func try_ally_open() -> bool:
	"""Ally opens the door (cannot close it). Returns true if door opened."""
	if is_open:
		return true
	open_door()
	return true

func apply_reinforcement():
	"""Reinforce the door so enemies must strike it multiple times."""
	reinforced = true
	reinforcement_hp = max_reinforcement_hp

func is_blocking() -> bool:
	"""Returns true when the door is solid enough to block passage."""
	return not is_open and open_progress < 0.5

func get_collision_rect() -> Rect2:
	"""Collision rect that shrinks as the door animates open."""
	if open_progress > 0.8:
		return Rect2()  # No collision when mostly/fully open
	var close_factor = 1.0 - open_progress * 0.9
	if is_vertical:
		var w = DOOR_H
		var h = DOOR_W * close_factor
		return Rect2(position.x - w / 2.0, position.y - h / 2.0, w, h)
	else:
		var w = DOOR_W * close_factor
		var h = DOOR_H
		return Rect2(position.x - w / 2.0, position.y - h / 2.0, w, h)

func reset():
	is_open = false
	open_progress = 0.0
	reinforced = false
	reinforcement_hp = 0
	hit_flash_timer = 0.0

# --- Drawing ---

func _draw():
	var flash = hit_flash_timer > 0

	if is_vertical:
		# Door in vertical wall — panels slide up/down
		var w = DOOR_H
		var h = DOOR_W
		var half_h = h / 2.0 - 1
		var slide = open_progress * half_h * 0.85
		# Top half slides up
		_draw_door_panel(-w / 2.0, -h / 2.0 - slide, w, half_h, flash)
		# Bottom half slides down
		_draw_door_panel(-w / 2.0, 1.0 + slide, w, half_h, flash)
	else:
		# Door in horizontal wall — panels slide left/right
		var w = DOOR_W
		var h = DOOR_H
		var half_w = w / 2.0 - 1
		var slide = open_progress * half_w * 0.85
		# Left half slides left
		_draw_door_panel(-w / 2.0 - slide, -h / 2.0, half_w, h, flash)
		# Right half slides right
		_draw_door_panel(1.0 + slide, -h / 2.0, half_w, h, flash)

	# Reinforcement HP bar
	if reinforced and reinforcement_hp > 0:
		var offset_y = (DOOR_W / 2.0 if not is_vertical else DOOR_H / 2.0) + 10
		var bar_w = 50.0
		var bar_h = 6.0
		var ratio = float(reinforcement_hp) / float(max_reinforcement_hp)
		draw_rect(Rect2(-bar_w / 2.0, offset_y, bar_w, bar_h), Color8(20, 20, 40, 200))
		draw_rect(Rect2(-bar_w / 2.0, offset_y, bar_w * ratio, bar_h), Color8(80, 160, 255))
		draw_rect(Rect2(-bar_w / 2.0, offset_y, bar_w, bar_h), Color8(60, 120, 200, 150), false, 1.0)
		# Shield icon
		var shield_y = offset_y - 6.0
		draw_circle(Vector2(0, shield_y), 5, Color8(80, 160, 255, 180))
		var font2 = ThemeDB.fallback_font
		draw_string(font2, Vector2(-3, shield_y + 4), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	# Open/Closed label
	var font = ThemeDB.fallback_font
	var label_y = (DOOR_W / 2.0 if not is_vertical else DOOR_H / 2.0) + 20
	if reinforced and reinforcement_hp > 0:
		label_y += 14
	var label: String
	var label_col: Color
	if is_open:
		label = "OPEN"
		label_col = Color8(100, 220, 100, 200)
	elif reinforced and reinforcement_hp > 0:
		label = "LOCKED"
		label_col = Color8(80, 160, 255, 200)
	else:
		label = "CLOSED"
		label_col = Color8(220, 160, 80, 200)
	draw_string(font, Vector2(-20, label_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, label_col)

func _draw_door_panel(x: float, y: float, w: float, h: float, flash: bool):
	if w < 1 or h < 1:
		return
	# Shadow
	draw_rect(Rect2(x + 2, y + 2, w, h), Color8(30, 20, 15))
	# Main panel
	var base_col = Color8(140, 105, 60) if not flash else Color8(255, 240, 200)
	draw_rect(Rect2(x, y, w, h), base_col)
	# Top highlight
	draw_rect(Rect2(x, y, w, maxf(h * 0.2, 3)), Color8(175, 140, 90) if not flash else Color8(255, 250, 230))
	# Border
	draw_rect(Rect2(x, y, w, h), Color8(90, 65, 35), false, 1.5)
	# Iron bands across the larger dimension
	var is_horiz = w >= h
	var band_dim = w if is_horiz else h
	var band_count = maxi(1, int(band_dim / 20.0))
	for i in range(band_count):
		if is_horiz:
			var band_y2 = y + (i + 1) * h / (band_count + 1)
			draw_line(Vector2(x + 2, band_y2), Vector2(x + w - 2, band_y2), Color8(70, 70, 80, 200), 2.0)
			draw_circle(Vector2(x + 4, band_y2), 2, Color8(90, 90, 100))
			draw_circle(Vector2(x + w - 4, band_y2), 2, Color8(90, 90, 100))
		else:
			var band_x2 = x + (i + 1) * w / (band_count + 1)
			draw_line(Vector2(band_x2, y + 2), Vector2(band_x2, y + h - 2), Color8(70, 70, 80, 200), 2.0)
			draw_circle(Vector2(band_x2, y + 4), 2, Color8(90, 90, 100))
			draw_circle(Vector2(band_x2, y + h - 4), 2, Color8(90, 90, 100))
