class_name WorldSelect
extends Node2D

var game = null
var active: bool = false
var selected_index: int = 0
var unlocked_worlds: Dictionary = {}
var world_time: float = 0.0

# World node positions (Mario-style overworld layout)
var world_rects: Array[Rect2] = []
const NODE_W: float = 180.0
const NODE_H: float = 100.0

func setup(game_ref):
	game = game_ref

func show_select():
	active = true
	selected_index = 0
	unlocked_worlds = SaveManager.load_unlocks()
	world_time = 0.0
	_build_world_rects()
	queue_redraw()

func hide_select():
	active = false
	queue_redraw()

func _build_world_rects():
	# Three nodes in a row: World 1 (left), 2 (center), 3 (right)
	var base_y = 320.0
	var gap = 80.0
	var total_w = 3 * NODE_W + 2 * gap
	var start_x = (1280.0 - total_w) / 2.0 + NODE_W / 2.0 + gap / 2.0
	world_rects.clear()
	for i in range(3):
		var x = start_x + i * (NODE_W + gap)
		world_rects.append(Rect2(x - NODE_W / 2.0, base_y - NODE_H / 2.0, NODE_W, NODE_H))

func _is_unlocked(world_id: int) -> bool:
	if world_id == 1:
		return true
	if world_id == 2:
		return unlocked_worlds.get("world2", false)
	if world_id == 3:
		return unlocked_worlds.get("world3", false)
	return false

func handle_input(event) -> bool:
	if not active:
		return false
	# Navigate
	if event.is_action_pressed("ui_nav_left"):
		selected_index = maxi(0, selected_index - 1)
		return true
	if event.is_action_pressed("ui_nav_right"):
		selected_index = mini(2, selected_index + 1)
		return true
	if event.is_action_pressed("ui_nav_up") or event.is_action_pressed("ui_nav_down"):
		# Optional: vertical layout
		return true
	# Confirm
	if event.is_action_pressed("confirm"):
		var world_id = selected_index + 1
		if _is_unlocked(world_id):
			_select_world(world_id)
		return true
	# Mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse = event.position
		for i in range(world_rects.size()):
			if world_rects[i].has_point(mouse) and _is_unlocked(i + 1):
				_select_world(i + 1)
				return true
	return false

func _select_world(world_id: int):
	game.current_map_id = world_id
	game.map.load_map_config(world_id)
	game.economy.configure_for_map(game.map.map_config)
	hide_select()
	game.state = game.GameState.TITLE
	game._update_visibility()
	queue_redraw()

func _process(delta: float):
	if active:
		world_time += delta
		# Update selected from mouse hover
		var mouse = get_global_mouse_position()
		for i in range(world_rects.size()):
			if world_rects[i].has_point(mouse):
				selected_index = i
				break
		queue_redraw()

func _draw():
	if not active:
		return
	var font = ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.05, 0.04, 0.08, 0.95))

	# Animated background particles
	for i in range(20):
		var bx = fmod(i * 73.0 + world_time * 5.0 * (0.4 + fmod(i * 0.3, 1.0)), 1280.0)
		var by = fmod(i * 47.0 + world_time * 2.0 * (0.3 + fmod(i * 0.7, 1.0)), 720.0)
		var ba = 0.06 + 0.03 * sin(world_time * 2.0 + i)
		draw_circle(Vector2(bx, by), 2 + fmod(i, 3), Color(0.4, 0.3, 0.7, ba))

	# Title with glow
	var glow_alpha = 0.1 + 0.03 * sin(world_time * 1.5)
	draw_rect(Rect2(340, 65, 600, 70), Color(0.6, 0.4, 0.8, glow_alpha))
	draw_string(font, Vector2(0, 120), "SELECT WORLD", HORIZONTAL_ALIGNMENT_CENTER, 1280, 48, Color8(220, 200, 255))
	draw_string(font, Vector2(0, 170), "Choose your territory, dude", HORIZONTAL_ALIGNMENT_CENTER, 1280, 18, Color8(160, 150, 180))
	draw_line(Vector2(400, 185), Vector2(880, 185), Color8(80, 65, 110, 120), 1.0)

	# World theme colors
	var theme_colors = [
		Color8(220, 180, 80),   # Desert: warm gold
		Color8(100, 180, 240),  # Snow: ice blue
		Color8(80, 200, 120),   # Jungle: lush green
	]

	# World nodes
	var configs = [
		MapConfig.get_map_config(1),
		MapConfig.get_map_config(2),
		MapConfig.get_map_config(3),
	]

	for i in range(3):
		var rect = world_rects[i]
		var cfg = configs[i]
		var unlocked = _is_unlocked(i + 1)
		var is_selected = selected_index == i
		var theme_col = theme_colors[i]

		# Card shadow
		_draw_pill(Rect2(rect.position.x + 4, rect.position.y + 4, rect.size.x, rect.size.y), Color(0, 0, 0, 0.35))

		# Card background
		var bg_col: Color
		if unlocked:
			bg_col = Color8(45, 52, 78) if is_selected else Color8(32, 36, 54)
		else:
			bg_col = Color8(22, 22, 32)
		_draw_pill(rect, bg_col)

		# Top accent strip in theme color
		if unlocked:
			_draw_pill(Rect2(rect.position.x, rect.position.y, rect.size.x, 4), theme_col)

		# Border
		var border_col = theme_col if (is_selected and unlocked) else Color8(65, 58, 85)
		draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x - 4, rect.size.y - 4), border_col, false, 3.0 if is_selected else 1.5)

		# Selection glow
		if is_selected and unlocked:
			var pulse = 0.2 + 0.12 * sin(world_time * 4.0)
			draw_rect(Rect2(rect.position.x - 2, rect.position.y - 2, rect.size.x + 4, rect.size.y + 4), Color(theme_col.r, theme_col.g, theme_col.b, pulse * 0.2), false, 2.0)

		var cx = rect.position.x + rect.size.x / 2.0
		var ty = rect.position.y + 14

		if unlocked:
			# World number badge
			draw_circle(Vector2(rect.position.x + 22, ty + 12), 12, theme_col)
			draw_string(font, Vector2(rect.position.x + 17, ty + 17), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color8(20, 20, 30))
			# World name
			draw_string(font, Vector2(cx - 60, ty + 24), cfg.get("name", "World %d" % (i + 1)), HORIZONTAL_ALIGNMENT_CENTER, 140, 16, Color.WHITE)
			# Wave count
			draw_string(font, Vector2(cx - 60, ty + 46), "%d Waves" % cfg.get("max_waves", 15), HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color8(175, 175, 200))
			# Theme label
			var theme_name = cfg.get("theme", "").to_upper()
			draw_string(font, Vector2(cx - 60, ty + 66), theme_name, HORIZONTAL_ALIGNMENT_CENTER, 140, 10, theme_col)
		else:
			draw_string(font, Vector2(cx - 60, ty + 24), "???", HORIZONTAL_ALIGNMENT_CENTER, 140, 22, Color8(90, 85, 110))
			draw_string(font, Vector2(cx - 60, ty + 54), "Beat World %d" % i, HORIZONTAL_ALIGNMENT_CENTER, 140, 10, Color8(120, 75, 75))

	# Path lines between nodes (Mario-style dotted)
	for i in range(2):
		var a = world_rects[i].position + Vector2(world_rects[i].size.x, world_rects[i].size.y / 2)
		var b = world_rects[i + 1].position + Vector2(0, world_rects[i + 1].size.y / 2)
		var path_col = Color8(90, 80, 120, 180) if _is_unlocked(i + 2) else Color8(50, 45, 65, 100)
		# Draw dotted line
		var dir = (b - a)
		var dist = dir.length()
		var step = 12.0
		var n_dots = int(dist / step)
		for d in range(n_dots):
			var t = float(d) / float(n_dots)
			var p = a.lerp(b, t)
			draw_circle(p, 2.0, path_col)

	# Footer
	draw_string(font, Vector2(0, 660), "D-Pad/L Stick: Select  |  Cross/Space: Start  |  Circle/Esc: Back to Launcher", HORIZONTAL_ALIGNMENT_CENTER, 1280, 14, Color8(130, 130, 150))

func _draw_pill(rect: Rect2, color: Color):
	var r = minf(rect.size.y / 2.0, 8.0)
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2), color)
	for corner in [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
		Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
	]:
		draw_circle(corner, r, color)
