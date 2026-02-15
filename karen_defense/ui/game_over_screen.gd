class_name GameOverScreen
extends Node2D

var game = null
var active: bool = false
var hover_index: int = -1
var kb_index: int = 0
var options: Array = ["Try Again", "Quit to Launcher"]
var is_victory: bool = false
var fade_alpha: float = 0.0

var tex_gameover: Texture2D = null

func _ready():
	tex_gameover = load("res://assets/Gameover.png")

func setup(game_ref):
	game = game_ref

func show_menu(victory: bool = false):
	active = true
	is_victory = victory
	hover_index = -1
	kb_index = 0
	var is_main_game = game != null and game.get("world_select") == null
	options = (["Level Select", "Quit to Launcher"] if is_main_game else ["World Select", "Quit to Launcher"]) if victory else ["Try Again", "Quit to Launcher"]
	fade_alpha = 0.0

func hide_menu():
	active = false
	queue_redraw()

func _process(delta):
	if not active:
		return
	fade_alpha = minf(fade_alpha + delta * 2.0, 1.0)
	var mouse = get_global_mouse_position()
	for i in range(options.size()):
		var rect = _get_button_rect(i)
		if rect.has_point(mouse):
			kb_index = i
			break
	hover_index = kb_index
	queue_redraw()

func handle_input(event) -> bool:
	if not active or fade_alpha < 0.8:
		return false
	# Mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover_index >= 0:
			_select_option(hover_index)
			return true
	# Action-based navigation (works for keyboard, D-pad, AND stick)
	if event.is_action_pressed("ui_nav_up"):
		kb_index = maxi(0, kb_index - 1)
		hover_index = kb_index
		return true
	if event.is_action_pressed("ui_nav_down"):
		kb_index = mini(options.size() - 1, kb_index + 1)
		hover_index = kb_index
		return true
	if event.is_action_pressed("confirm"):
		if kb_index >= 0 and kb_index < options.size():
			_select_option(kb_index)
			return true
	return false

func _select_option(index: int):
	match index:
		0:
			if is_victory:
				hide_menu()
				if game.get("world_select") != null:
					var next_id = game.current_map_id + 1
					if next_id <= 3:
						var unlocks = SaveManager.load_unlocks()
						SaveManager.unlock_world(next_id, unlocks)
					game.state = game.GameState.WORLD_SELECT
					game.world_select.show_select()
					game._update_visibility()
				else:
					get_tree().change_scene_to_file("res://main_game/ui/level_select.tscn")
			else:
				hide_menu()
				game.restart_game()
		1:  # Quit
			get_tree().change_scene_to_file("res://launcher.tscn")

func _get_button_rect(index: int) -> Rect2:
	var btn_w = 280.0
	var btn_h = 52.0
	var x = (1280 - btn_w) / 2.0
	var y = 440 + index * 72.0
	return Rect2(x, y, btn_w, btn_h)

func _draw():
	if not active:
		return
	var font = ThemeDB.fallback_font
	var alpha = fade_alpha

	# Dark overlay
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.7 * alpha))

	# Title graphic
	if is_victory:
		var level_label = "LEVEL" if game.get("world_select") == null else "WORLD"
		draw_string(font, Vector2(0, 140), "%s %d COMPLETE!" % [level_label, game.current_map_id], HORIZONTAL_ALIGNMENT_CENTER, 1280, 44, Color(0.3, 1.0, 0.5, alpha))
		var next_id = game.current_map_id + 1
		var max_levels = 5 if game.get("world_select") == null else 3
		if next_id <= max_levels:
			draw_string(font, Vector2(0, 195), ("Level %d " if game.get("world_select") == null else "World %d ") % next_id + "unlocked!", HORIZONTAL_ALIGNMENT_CENTER, 1280, 20, Color(0.8, 0.9, 0.7, alpha))
		else:
			draw_string(font, Vector2(0, 195), "You beat them all, dude!", HORIZONTAL_ALIGNMENT_CENTER, 1280, 20, Color(0.8, 0.9, 0.7, alpha))
	elif tex_gameover:
		var tex_size = tex_gameover.get_size()
		var target_h = 120.0
		var s = target_h / tex_size.y
		var draw_w = tex_size.x * s
		draw_set_transform(Vector2((1280 - draw_w) / 2.0, 100), 0, Vector2(s, s))
		draw_texture(tex_gameover, Vector2.ZERO, Color(1, 1, 1, alpha))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_string(font, Vector2(440, 180), "GAME OVER, DUDE", HORIZONTAL_ALIGNMENT_CENTER, 400, 36, Color(1, 0.3, 0.3, alpha))
	if not is_victory:
		draw_string(font, Vector2(390, 240), "That's harsh... The Karens got you.", HORIZONTAL_ALIGNMENT_CENTER, 500, 14, Color(0.8, 0.8, 0.9, alpha))

	# Stats
	var stats_x = 490.0
	var stats_y = 280.0
	if is_victory:
		stats_y = 240.0
	var stat_lines = [
		"Wave Reached: %d" % game.current_wave,
		"Karens Defeated: %d" % game.enemies_killed_total,
		"Gold Earned: %d" % game.total_gold_earned,
		("Level: %d" % game.progression.get_level(0)) if not game.p2_joined else ("P1 Lv.%d  P2 Lv.%d" % [game.progression.get_level(0), game.progression.get_level(1)]),
		"Time Survived: %d:%02d" % [int(game.time_elapsed) / 60, int(game.time_elapsed) % 60],
	]
	for i in range(stat_lines.size()):
		draw_string(font, Vector2(stats_x, stats_y + i * 22), stat_lines[i], HORIZONTAL_ALIGNMENT_CENTER, 300, 14, Color(0.9, 0.9, 1.0, alpha))

	# Flavor text
	var flavor_texts = [
		"Maybe try a different strain next time?",
		"Even the chillest dude has bad days.",
		"The Karens win this round...",
		"Duuude... that was gnarly.",
	]
	var flavor = flavor_texts[game.current_wave % flavor_texts.size()]
	draw_string(font, Vector2(390, 390), flavor, HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color(0.7, 0.7, 0.5, alpha))

	# Buttons
	if alpha > 0.8:
		for i in range(options.size()):
			var rect = _get_button_rect(i)
			var is_hovered = hover_index == i
			draw_rect(rect, Color8(60, 55, 80) if is_hovered else Color8(40, 35, 55))
			draw_rect(rect, Color8(120, 100, 160) if not is_hovered else Color8(180, 160, 220), false, 2.0 if is_hovered else 1.5)
			var prefix = "> " if is_hovered else "  "
			draw_string(font, Vector2(rect.position.x + rect.size.x / 2 - 60, rect.position.y + 32), prefix + options[i], HORIZONTAL_ALIGNMENT_CENTER, 140, 16, Color.WHITE)

		# Navigation hint
		draw_string(font, Vector2(490, 590), "D-Pad: Navigate  |  Cross/Space: Select", HORIZONTAL_ALIGNMENT_CENTER, 300, 11, Color8(140, 140, 160))
