class_name PauseMenu
extends Node2D

var game = null
var active: bool = false
var hover_index: int = -1
var kb_index: int = 0
var options: Array[String] = ["Resume", "Controls", "Restart", "Quit to Launcher"]
var showing_controls: bool = false
var controls_scroll: float = 0.0  # For smooth scroll if needed

func setup(game_ref):
	game = game_ref

func show_menu():
	active = true
	hover_index = -1
	kb_index = 0
	showing_controls = false
	controls_scroll = 0.0

func hide_menu():
	active = false
	showing_controls = false
	queue_redraw()

func _process(_delta):
	if not active:
		return
	if showing_controls:
		queue_redraw()
		return
	var mouse = get_global_mouse_position()
	for i in range(options.size()):
		var rect = _get_button_rect(i)
		if rect.has_point(mouse):
			kb_index = i
			break
	hover_index = kb_index
	queue_redraw()

func handle_input(event) -> bool:
	if not active:
		return false

	# Controls screen: any back input returns to pause menu
	if showing_controls:
		if event.is_action_pressed("ui_back") or event.is_action_pressed("confirm"):
			showing_controls = false
			return true
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			showing_controls = false
			return true
		if event.is_action_pressed("pause"):
			showing_controls = false
			return true
		return true  # Consume all input while in controls view

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
	if event.is_action_pressed("ui_back"):
		hide_menu()
		game.unpause()
		return true
	return false

func _select_option(index: int):
	match index:
		0:  # Resume
			hide_menu()
			game.unpause()
		1:  # Controls
			showing_controls = true
		2:  # Restart
			hide_menu()
			game.restart_game()
		3:  # Quit to launcher
			get_tree().change_scene_to_file("res://launcher.tscn")

func _get_button_rect(index: int) -> Rect2:
	var btn_w = 300.0
	var btn_h = 48.0
	var x = (1280 - btn_w) / 2.0
	var y = 290 + index * 62.0
	return Rect2(x, y, btn_w, btn_h)

func _draw():
	if not active:
		return

	if showing_controls:
		_draw_controls_screen()
		return

	var font = ThemeDB.fallback_font

	# Dark overlay
	draw_rect(Rect2(0, 0, 1280, 720), Color8(0, 0, 0, 190))

	# Title with decorative line
	draw_string(font, Vector2(540, 230), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 200, 38, Color.WHITE)
	draw_line(Vector2(520, 240), Vector2(760, 240), Color8(100, 90, 130, 120), 1.0)
	draw_string(font, Vector2(470, 272), "Take a breather, dude", HORIZONTAL_ALIGNMENT_CENTER, 340, 13, Color8(170, 170, 195))

	# Current stats with decorative panel
	var stat_rect = Rect2(370, 280, 540, 0)
	_draw_panel_bg(stat_rect)

	# Buttons
	for i in range(options.size()):
		var rect = _get_button_rect(i)
		var is_hovered = hover_index == i
		# Button background
		var bg_col = Color8(65, 58, 85) if is_hovered else Color8(38, 33, 52)
		_draw_rounded_rect(rect, bg_col)
		# Border
		var border_col = Color8(180, 160, 220) if is_hovered else Color8(100, 88, 140)
		draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2), border_col, false, 2.0 if is_hovered else 1.5)
		# Selection indicator
		if is_hovered:
			draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, 4, rect.size.y - 4), Color8(180, 160, 255))
		# Text
		var text_col = Color.WHITE if is_hovered else Color8(180, 175, 200)
		var prefix = "> " if is_hovered else "  "
		draw_string(font, Vector2(rect.position.x + rect.size.x / 2 - 70, rect.position.y + 31), prefix + options[i], HORIZONTAL_ALIGNMENT_CENTER, 160, 17, text_col)

	# Navigation hint
	var hint_y = 290 + options.size() * 62.0 + 30
	draw_string(font, Vector2(370, hint_y), "D-Pad: Navigate  |  Cross/Space: Select  |  Circle/Esc: Resume", HORIZONTAL_ALIGNMENT_CENTER, 540, 11, Color8(130, 130, 155))

func _draw_controls_screen():
	var font = ThemeDB.fallback_font

	# Dark overlay
	draw_rect(Rect2(0, 0, 1280, 720), Color8(0, 0, 0, 210))

	# Title
	draw_string(font, Vector2(490, 54), "CONTROLS", HORIZONTAL_ALIGNMENT_CENTER, 300, 32, Color.WHITE)
	draw_line(Vector2(490, 62), Vector2(790, 62), Color8(120, 100, 180, 140), 1.0)

	# Two columns: Keyboard (left) and PlayStation Controller (right)
	var col_left = 80.0
	var col_right = 660.0
	var col_w = 520.0
	var start_y = 90.0

	# --- KEYBOARD COLUMN ---
	_draw_rounded_rect(Rect2(col_left - 10, start_y - 6, col_w, 560), Color8(30, 25, 45, 220))
	draw_rect(Rect2(col_left - 10, start_y - 6, col_w, 560), Color8(80, 70, 110, 80), false, 1.0)
	draw_string(font, Vector2(col_left + 10, start_y + 16), "KEYBOARD + MOUSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(200, 190, 230))
	draw_line(Vector2(col_left, start_y + 22), Vector2(col_left + col_w - 20, start_y + 22), Color8(80, 70, 110, 120), 1.0)

	var kb_controls = [
		["WASD", "Move"],
		["Mouse", "Aim"],
		["Left Click / Space", "Attack"],
		["Right Click / V", "Block"],
		["Shift", "Dash"],
		["Left Ctrl", "Sprint"],
		["Q", "Weapon Wheel (hold) / Quick Swap (tap)"],
		["F", "Repair / Open Door"],
		["G", "Regroup Allies"],
		["C", "Grapple Hook"],
		["R", "Use Potion"],
		["Tab", "Open Shop"],
		["Esc", "Pause"],
	]
	var ky = start_y + 38
	for entry in kb_controls:
		_draw_key_binding(font, col_left + 16, ky, entry[0], entry[1], false)
		ky += 28

	# Grenade tip
	ky += 10
	draw_string(font, Vector2(col_left + 16, ky), "Grenade: Switch to GRENADE mode (Q), hold Attack to aim,", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 180, 100))
	ky += 16
	draw_string(font, Vector2(col_left + 16, ky), "release to throw. W/S adjusts distance while aiming.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 180, 100))

	# --- PLAYSTATION COLUMN ---
	_draw_rounded_rect(Rect2(col_right - 10, start_y - 6, col_w, 560), Color8(30, 25, 45, 220))
	draw_rect(Rect2(col_right - 10, start_y - 6, col_w, 560), Color8(80, 70, 110, 80), false, 1.0)
	draw_string(font, Vector2(col_right + 10, start_y + 16), "PLAYSTATION CONTROLLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(200, 190, 230))
	draw_line(Vector2(col_right, start_y + 22), Vector2(col_right + col_w - 20, start_y + 22), Color8(80, 70, 110, 120), 1.0)

	var ps_controls = [
		["Left Stick", "Move"],
		["Right Stick", "Aim"],
		["R2 (Right Trigger)", "Attack"],
		["L2 (Left Trigger)", "Block"],
		["Cross (X)", "Dash"],
		["R1 (Right Bumper)", "Sprint"],
		["L1 (Left Bumper)", "Weapon Wheel (hold) / Quick Swap (tap)"],
		["Triangle", "Repair / Open Door"],
		["Square", "Regroup Allies"],
		["L3 (Left Stick Press)", "Grapple Hook"],
		["Circle", "Use Potion"],
		["Touchpad / Select", "Open Shop"],
		["Options", "Pause"],
	]
	var py = start_y + 38
	for entry in ps_controls:
		_draw_key_binding(font, col_right + 16, py, entry[0], entry[1], true)
		py += 28

	# Grenade tip for controller
	py += 10
	draw_string(font, Vector2(col_right + 16, py), "Grenade: Switch to GRENADE mode (L1), hold R2 to aim,", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 180, 100))
	py += 16
	draw_string(font, Vector2(col_right + 16, py), "release R2 to throw. Left Stick adjusts distance.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 180, 100))

	# Back hint at bottom
	draw_string(font, Vector2(430, 680), "Press any button to return", HORIZONTAL_ALIGNMENT_CENTER, 420, 14, Color8(160, 155, 185))

func _draw_key_binding(font: Font, x: float, y: float, key: String, action: String, is_ps: bool):
	"""Draw a single control binding row with styled key badge."""
	# Key badge
	var key_w = maxf(font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 16, 60.0)
	var badge_rect = Rect2(x, y - 12, key_w, 20)

	var badge_bg: Color
	var badge_border: Color
	var key_col: Color
	if is_ps:
		badge_bg = Color8(30, 40, 70, 200)
		badge_border = Color8(70, 100, 180, 150)
		key_col = Color8(140, 175, 255)
	else:
		badge_bg = Color8(50, 42, 65, 200)
		badge_border = Color8(120, 100, 160, 150)
		key_col = Color8(220, 210, 240)

	_draw_rounded_rect(badge_rect, badge_bg)
	draw_rect(Rect2(badge_rect.position.x + 1, badge_rect.position.y + 1, badge_rect.size.x - 2, badge_rect.size.y - 2), badge_border, false, 1.0)
	draw_string(font, Vector2(x + 6, y + 2), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, key_col)

	# Action text
	draw_string(font, Vector2(x + key_w + 12, y + 2), action, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(200, 195, 215))

func _draw_rounded_rect(rect: Rect2, color: Color):
	"""Simple rounded rect using overlapping rects and corner circles."""
	var r = 4.0
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2), color)
	for corner in [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
		Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
	]:
		draw_circle(corner, r, color)

func _draw_panel_bg(rect: Rect2):
	pass
