extends Node2D

## World Map: visual overworld showing 5 worlds with levels as nodes.
## Replaces the flat level select with a more engaging visual.

const SCREEN_W = 1280
const SCREEN_H = 720

var selected_world: int = 0
var selected_level_in_world: int = 0  # 0-4 (0-3 = regular, 4 = boss)
var progress: Dictionary = {}
var upgrades: Dictionary = {}
var anim_time: float = 0.0
var mode: int = 0  # 0 = world select, 1 = level select, 2 = upgrade shop
var selected_upgrade: int = 0
var upgrade_types: Array = ["hp", "speed", "potions"]
var upgrade_names: Array = ["+10% Max HP", "+5% Move Speed", "+1 Starting Potion"]

# World visual positions (node graph layout)
var world_positions: Array[Vector2] = [
	Vector2(200, 500),   # Grasslands (bottom left)
	Vector2(400, 380),   # Caves
	Vector2(640, 260),   # Sky Realm (center)
	Vector2(880, 380),   # Summit
	Vector2(1080, 500),  # Final Gauntlet (bottom right)
]

func _ready():
	progress = SaveManager.load_main_game_progress()
	upgrades = SaveManager.load_upgrades()
	# Sync souls from progress
	if progress.has("souls"):
		upgrades["souls"] = progress.get("souls", 0)

func _process(delta):
	anim_time += delta
	queue_redraw()

func _input(event):
	if mode == 0:
		_input_world_select(event)
	elif mode == 1:
		_input_level_select(event)
	elif mode == 2:
		_input_upgrade_shop(event)

func _input_upgrade_shop(event):
	if event.is_action_pressed("ui_nav_up"):
		selected_upgrade = maxi(0, selected_upgrade - 1)
	elif event.is_action_pressed("ui_nav_down"):
		selected_upgrade = mini(upgrade_types.size() - 1, selected_upgrade + 1)
	elif event.is_action_pressed("confirm"):
		var type = upgrade_types[selected_upgrade]
		if SaveManager.buy_upgrade(type, upgrades):
			upgrades = SaveManager.load_upgrades()
	elif event.is_action_pressed("ui_back"):
		mode = 0

func _input_world_select(event):
	if event.is_action_pressed("ui_nav_left") or event.is_action_pressed("ui_nav_up"):
		selected_world = maxi(0, selected_world - 1)
	elif event.is_action_pressed("ui_nav_right") or event.is_action_pressed("ui_nav_down"):
		selected_world = mini(WorldConfig.WORLDS.size() - 1, selected_world + 1)
	elif event.is_action_pressed("confirm"):
		if _is_world_unlocked(selected_world):
			mode = 1
			selected_level_in_world = 0
	elif event.is_action_pressed("ui_back"):
		get_tree().change_scene_to_file("res://launcher.tscn")
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		mode = 2
		selected_upgrade = 0
	elif event is InputEventKey and event.pressed and event.keycode == KEY_D:
		# Cycle difficulty
		var d = DifficultyManager.current_difficulty
		DifficultyManager.current_difficulty = (d + 1) % 3 as DifficultyManager.DifficultyMode
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(WorldConfig.WORLDS.size()):
			var wp = world_positions[i]
			if event.position.distance_to(wp) < 60 and _is_world_unlocked(i):
				selected_world = i
				mode = 1
				selected_level_in_world = 0  # Reset to first level when entering world
				return

func _input_level_select(event):
	var w = WorldConfig.WORLDS[selected_world]
	var total = w.levels.size() + 1  # +1 for boss
	if event.is_action_pressed("ui_nav_left") or event.is_action_pressed("ui_nav_up"):
		selected_level_in_world = maxi(0, selected_level_in_world - 1)
	elif event.is_action_pressed("ui_nav_right") or event.is_action_pressed("ui_nav_down"):
		selected_level_in_world = mini(total - 1, selected_level_in_world + 1)
	elif event.is_action_pressed("confirm"):
		var level_id = _get_selected_level_id()
		if _is_level_unlocked(level_id):
			_launch_level(level_id)
	elif event.is_action_pressed("ui_back"):
		mode = 0
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(total):
			var lp = _get_level_node_pos(i, total)
			if event.position.distance_to(lp) < 35:
				selected_level_in_world = i
				var level_id = _get_selected_level_id()
				if _is_level_unlocked(level_id):
					_launch_level(level_id)
				return

func _get_selected_level_id() -> int:
	var w = WorldConfig.WORLDS[selected_world]
	if selected_level_in_world < w.levels.size():
		return w.levels[selected_level_in_world]
	return w.boss_level

func _is_world_unlocked(world_idx: int) -> bool:
	if world_idx == 0:
		return true
	# World N is unlocked when the boss of world N-1 is completed
	var prev_world = WorldConfig.WORLDS[world_idx - 1]
	return _is_level_completed(prev_world.boss_level)

func _is_level_unlocked(level_id: int) -> bool:
	return SaveManager.is_level_unlocked(level_id, progress)

func _is_level_completed(level_id: int) -> bool:
	var completed: Array = progress.get("levels_completed", [])
	for v in completed:
		if int(v) == level_id:
			return true
	return false

func _launch_level(level_id: int):
	MainGameManager.current_level = level_id
	get_tree().change_scene_to_file("res://main_game/main_game.tscn")

func _get_level_node_pos(index: int, total: int) -> Vector2:
	# Arrange level nodes in a horizontal row in the center panel
	var panel_x = 200.0
	var panel_w = SCREEN_W - 400.0
	var y = SCREEN_H / 2.0 + 40
	var spacing = panel_w / float(total + 1)
	return Vector2(panel_x + spacing * (index + 1), y)

func _draw():
	# Background
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color8(18, 15, 25))

	# Stars background
	for i in range(50):
		var sx = fmod(i * 53.0 + anim_time * 3.0 * (0.2 + fmod(i * 0.17, 0.8)), SCREEN_W)
		var sy = fmod(i * 37.0 + anim_time * 1.2 * (0.1 + fmod(i * 0.23, 0.6)), SCREEN_H)
		var sa = 0.08 + 0.06 * sin(anim_time * 1.5 + i)
		draw_circle(Vector2(sx, sy), 1.5 + fmod(i, 2), Color(0.6, 0.5, 0.9, sa))

	var font = ThemeDB.fallback_font

	if mode == 0:
		_draw_world_select(font)
	elif mode == 1:
		_draw_level_select(font)
	elif mode == 2:
		_draw_upgrade_shop(font)

func _draw_world_select(font: Font):
	# Title
	draw_string(font, Vector2(SCREEN_W / 2.0 - 120, 80), "WORLD MAP", HORIZONTAL_ALIGNMENT_CENTER, 240, 36, Color8(220, 210, 240))

	# Draw path between worlds
	for i in range(world_positions.size() - 1):
		var from = world_positions[i]
		var to = world_positions[i + 1]
		var path_col = Color8(80, 70, 100) if _is_world_unlocked(i + 1) else Color8(40, 35, 50)
		draw_line(from, to, path_col, 3.0)
		# Dashed pattern
		var steps = 8
		for s in range(steps):
			var t = float(s) / float(steps)
			var p = from.lerp(to, t)
			draw_circle(p, 2.5, path_col.lightened(0.2))

	# Draw world nodes
	for i in range(WorldConfig.WORLDS.size()):
		var w = WorldConfig.WORLDS[i]
		var wp = world_positions[i]
		var unlocked = _is_world_unlocked(i)
		var is_sel = (i == selected_world)
		var boss_beaten = _is_level_completed(w.boss_level)

		# Node circle
		var radius = 45.0 if is_sel else 38.0
		var pulse = 1.0 + 0.08 * sin(anim_time * 3.0 + i) if is_sel else 1.0

		# Glow for selected
		if is_sel and unlocked:
			draw_circle(wp, radius + 12, Color(w.color.r, w.color.g, w.color.b, 0.15 * pulse))

		# Base circle
		var bg_col = w.color.darkened(0.5) if unlocked else Color8(30, 28, 38)
		draw_circle(wp, radius, bg_col)

		# Border
		var border_col = w.color if unlocked else Color8(60, 55, 75)
		if is_sel and unlocked:
			border_col = w.color.lightened(0.3)
		_draw_circle_outline(wp, radius, border_col, 3.0 if is_sel else 2.0)

		# World number
		var num_col = Color.WHITE if unlocked else Color8(90, 85, 110)
		draw_string(font, wp + Vector2(-8, -5), str(w.id), HORIZONTAL_ALIGNMENT_CENTER, 20, 24, num_col)

		# World name below
		var name_col = Color8(200, 195, 220) if unlocked else Color8(80, 75, 100)
		draw_string(font, wp + Vector2(-50, radius + 22), w.name, HORIZONTAL_ALIGNMENT_CENTER, 100, 14, name_col)

		# Check mark if boss beaten
		if boss_beaten:
			draw_string(font, wp + Vector2(radius - 8, -radius + 14), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color8(255, 220, 60))

		# Lock icon if not unlocked
		if not unlocked:
			draw_string(font, wp + Vector2(-5, 8), "🔒", HORIZONTAL_ALIGNMENT_CENTER, 20, 16, Color8(120, 110, 140))

	# Selected world description
	if selected_world >= 0 and selected_world < WorldConfig.WORLDS.size():
		var sw = WorldConfig.WORLDS[selected_world]
		var desc_y = 140.0
		draw_string(font, Vector2(SCREEN_W / 2.0 - 200, desc_y), sw.name, HORIZONTAL_ALIGNMENT_CENTER, 400, 22, sw.color.lightened(0.2))
		draw_string(font, Vector2(SCREEN_W / 2.0 - 300, desc_y + 30), sw.description, HORIZONTAL_ALIGNMENT_CENTER, 600, 13, Color8(170, 165, 190))

	# Difficulty display
	var diff_name = DifficultyManager.get_difficulty_name()
	var diff_col = Color8(100, 220, 130)
	if DifficultyManager.current_difficulty == DifficultyManager.DifficultyMode.HARD:
		diff_col = Color8(255, 180, 50)
	elif DifficultyManager.current_difficulty == DifficultyManager.DifficultyMode.NIGHTMARE:
		diff_col = Color8(255, 60, 60)
	draw_string(font, Vector2(SCREEN_W - 200, 40), "Difficulty: " + diff_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, diff_col)
	draw_string(font, Vector2(SCREEN_W - 200, 58), "[D] to change", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(120, 115, 140))

	# Souls display
	var soul_count = int(upgrades.get("souls", 0))
	draw_string(font, Vector2(30, 40), "Souls: %d" % soul_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(200, 180, 255))

	# Controls
	draw_string(font, Vector2(SCREEN_W / 2.0 - 350, SCREEN_H - 40), "Arrows: Navigate  |  Enter: Select  |  Tab: Upgrades  |  D: Difficulty  |  Esc: Back", HORIZONTAL_ALIGNMENT_CENTER, 700, 12, Color8(110, 105, 130))

func _draw_level_select(font: Font):
	var w = WorldConfig.WORLDS[selected_world]
	var total = w.levels.size() + 1  # +1 for boss

	# Title
	draw_string(font, Vector2(SCREEN_W / 2.0 - 150, 60), "World %d: %s" % [w.id, w.name], HORIZONTAL_ALIGNMENT_CENTER, 300, 28, w.color.lightened(0.2))
	draw_string(font, Vector2(SCREEN_W / 2.0 - 250, 90), w.description, HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color8(160, 155, 180))

	# Draw connections between level nodes
	for i in range(total - 1):
		var from = _get_level_node_pos(i, total)
		var to = _get_level_node_pos(i + 1, total)
		var next_id = w.levels[i + 1] if i + 1 < w.levels.size() else w.boss_level
		var path_col = Color8(80, 110, 80) if _is_level_unlocked(next_id) else Color8(40, 38, 50)
		draw_line(from, to, path_col, 2.0)

	# Draw level nodes
	for i in range(total):
		var lp = _get_level_node_pos(i, total)
		var level_id: int
		var is_boss: bool = false
		if i < w.levels.size():
			level_id = w.levels[i]
		else:
			level_id = w.boss_level
			is_boss = true

		var unlocked = _is_level_unlocked(level_id)
		var completed = _is_level_completed(level_id)
		var is_sel = (i == selected_level_in_world)

		var radius = 30.0 if is_boss else 24.0
		if is_sel:
			radius += 6.0

		# Glow
		if is_sel and unlocked:
			var glow_col = Color(1.0, 0.3, 0.3, 0.2) if is_boss else Color(0.3, 0.8, 0.4, 0.15)
			draw_circle(lp, radius + 10, glow_col)

		# Node
		var bg: Color
		if is_boss:
			bg = Color8(140, 40, 40) if unlocked else Color8(40, 25, 25)
		elif unlocked:
			bg = Color8(50, 70, 55)
		else:
			bg = Color8(32, 30, 40)
		draw_circle(lp, radius, bg)

		# Border
		var bdr: Color
		if is_boss:
			bdr = Color8(255, 100, 80) if is_sel else Color8(180, 60, 50)
		elif completed:
			bdr = Color8(100, 220, 130)
		elif unlocked:
			bdr = Color8(150, 200, 160) if is_sel else Color8(90, 140, 100)
		else:
			bdr = Color8(60, 55, 75)
		_draw_circle_outline(lp, radius, bdr, 3.0 if is_sel else 2.0)

		# Label
		var label: String
		if is_boss:
			label = "BOSS"
		else:
			label = "%d-%d" % [w.id, i + 1]
		var label_col = Color.WHITE if unlocked else Color8(90, 85, 110)
		draw_string(font, lp + Vector2(-18, 6), label, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, label_col)

		# Level name below
		var level_cfg = LinearMapConfig.get_level(level_id)
		var lname = level_cfg.get("name", "Level %d" % level_id)
		draw_string(font, lp + Vector2(-40, radius + 18), lname, HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color8(160, 155, 180) if unlocked else Color8(70, 65, 90))

		# Star / check
		if completed:
			draw_string(font, lp + Vector2(radius - 8, -radius + 10), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(255, 220, 60))

		# Lock
		if not unlocked:
			draw_string(font, lp + Vector2(-4, 6), "X", HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color8(120, 110, 140))

	# Selected level info panel
	var sel_id = _get_selected_level_id()
	var sel_cfg = LinearMapConfig.get_level(sel_id)
	var panel_y = SCREEN_H / 2.0 + 120
	draw_rect(Rect2(SCREEN_W / 2.0 - 220, panel_y, 440, 100), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(SCREEN_W / 2.0 - 220, panel_y, 440, 100), Color8(80, 75, 100), false, 1.5)
	draw_string(font, Vector2(SCREEN_W / 2.0 - 100, panel_y + 28), sel_cfg.get("name", ""), HORIZONTAL_ALIGNMENT_CENTER, 200, 20, Color.WHITE)
	var world_label = WorldConfig.get_level_name_in_world(sel_id)
	draw_string(font, Vector2(SCREEN_W / 2.0 - 100, panel_y + 50), "Level " + world_label, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, Color8(170, 165, 190))
	if _is_level_unlocked(sel_id):
		var status = "COMPLETED" if _is_level_completed(sel_id) else "READY"
		var status_col = Color8(100, 220, 130) if _is_level_completed(sel_id) else Color8(220, 200, 100)
		draw_string(font, Vector2(SCREEN_W / 2.0 - 40, panel_y + 78), status, HORIZONTAL_ALIGNMENT_CENTER, 80, 14, status_col)
	else:
		draw_string(font, Vector2(SCREEN_W / 2.0 - 50, panel_y + 78), "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, 100, 14, Color8(140, 60, 60))

	# Controls
	draw_string(font, Vector2(SCREEN_W / 2.0 - 250, SCREEN_H - 40), "Arrow Keys: Navigate  |  Enter/Space: Play  |  Esc: Back to Map", HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color8(110, 105, 130))

func _draw_upgrade_shop(font: Font):
	# Title
	draw_string(font, Vector2(SCREEN_W / 2.0 - 120, 80), "UPGRADE SHOP", HORIZONTAL_ALIGNMENT_CENTER, 240, 32, Color8(255, 220, 100))

	# Souls display
	var souls = int(upgrades.get("souls", 0))
	draw_string(font, Vector2(SCREEN_W / 2.0 - 60, 120), "Souls: %d" % souls, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color8(200, 180, 255))

	# Upgrade list
	var start_y = 180.0
	var card_h = 90.0
	var card_w = 500.0
	var card_x = (SCREEN_W - card_w) / 2.0

	for i in range(upgrade_types.size()):
		var type = upgrade_types[i]
		var key = type + "_level"
		if type == "potions":
			key = "potions"
		var current = int(upgrades.get(key, 0))
		var max_lvl = SaveManager.get_max_upgrade_level(type)
		var cost = SaveManager.get_upgrade_cost(type, current)
		var maxed = current >= max_lvl
		var can_buy = not maxed and souls >= cost
		var is_sel = (i == selected_upgrade)

		var y = start_y + i * (card_h + 15)
		var bg = Color8(60, 50, 80) if is_sel else Color8(38, 34, 52)
		draw_rect(Rect2(card_x, y, card_w, card_h), bg)
		var bdr = Color8(200, 180, 255) if is_sel else Color8(80, 70, 100)
		draw_rect(Rect2(card_x, y, card_w, card_h), bdr, false, 2.0 if is_sel else 1.0)

		# Name
		draw_string(font, Vector2(card_x + 20, y + 30), upgrade_names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

		# Level indicator
		var level_str = "Lv %d / %d" % [current, max_lvl]
		if maxed:
			level_str = "MAXED"
		draw_string(font, Vector2(card_x + 20, y + 55), level_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(160, 220, 130) if maxed else Color8(180, 170, 200))

		# Cost
		if not maxed:
			var cost_col = Color8(100, 220, 130) if can_buy else Color8(180, 80, 80)
			draw_string(font, Vector2(card_x + card_w - 120, y + 40), "Cost: %d" % cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cost_col)

		# Selection indicator
		if is_sel:
			draw_string(font, Vector2(card_x - 25, y + 40), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(255, 220, 100))

	# Controls
	draw_string(font, Vector2(SCREEN_W / 2.0 - 250, SCREEN_H - 40), "Up/Down: Navigate  |  Enter: Buy  |  Esc: Back to Map", HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color8(110, 105, 130))

func _draw_circle_outline(center: Vector2, radius: float, color: Color, width: float = 2.0):
	var points = 32
	for i in range(points):
		var a1 = TAU * i / float(points)
		var a2 = TAU * (i + 1) / float(points)
		draw_line(center + Vector2(cos(a1), sin(a1)) * radius, center + Vector2(cos(a2), sin(a2)) * radius, color, width)
