extends Node2D

const SCREEN_W = 1280
const SCREEN_H = 720

var options: Array[String] = ["Main Game", "Karen Defense", "Snake Game"]
var hover_index: int = -1
var kb_index: int = 0
var anim_time: float = 0.0

func _ready():
	pass

func _process(delta):
	anim_time += delta
	var mouse = get_global_mouse_position()
	for i in range(options.size()):
		var btn_rect = _get_button_rect(i)
		if btn_rect.has_point(mouse):
			kb_index = i
			break
	hover_index = kb_index
	queue_redraw()

func _input(event):
	# Mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover_index >= 0:
			_launch_game(hover_index)
			return

	# Action-based navigation (works for keyboard, D-pad, AND controller stick)
	if event.is_action_pressed("ui_nav_up"):
		kb_index = maxi(0, kb_index - 1)
		hover_index = kb_index
		return
	if event.is_action_pressed("ui_nav_down"):
		kb_index = mini(options.size() - 1, kb_index + 1)
		hover_index = kb_index
		return

	# Confirm: Space/Enter/A/Cross button
	if event.is_action_pressed("confirm"):
		_launch_game(kb_index)
		return

	# Keyboard shortcuts (fallback)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			kb_index = maxi(0, kb_index - 1)
			hover_index = kb_index
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			kb_index = mini(options.size() - 1, kb_index + 1)
			hover_index = kb_index
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_launch_game(kb_index)
		elif event.keycode == KEY_1:
			_launch_game(0)
		elif event.keycode == KEY_2:
			_launch_game(1)
		elif event.keycode == KEY_3:
			_launch_game(2)

func _get_button_rect(index: int) -> Rect2:
	var btn_w = 380.0
	var btn_h = 75.0
	var x = (SCREEN_W - btn_w) / 2.0
	var y = 310.0 + index * 105.0
	return Rect2(x, y, btn_w, btn_h)

func _launch_game(index: int):
	match index:
		0:
			get_tree().change_scene_to_file("res://main_game/ui/level_select.tscn")
		1:
			get_tree().change_scene_to_file("res://karen_defense/karen_defense.tscn")
		2:
			get_tree().change_scene_to_file("res://main.tscn")

func _draw():
	# Background
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color8(22, 18, 28))

	# Animated background particles
	for i in range(30):
		var bx = fmod(i * 67.0 + anim_time * 6.0 * (0.4 + fmod(i * 0.3, 1.0)), SCREEN_W)
		var by = fmod(i * 43.0 + anim_time * 2.5 * (0.3 + fmod(i * 0.7, 1.0)), SCREEN_H)
		var ba = 0.06 + 0.04 * sin(anim_time * 2.0 + i)
		draw_circle(Vector2(bx, by), 2 + fmod(i, 3), Color(0.5, 0.3, 0.8, ba))

	var font = ThemeDB.fallback_font

	# Title with glow
	var glow_alpha = 0.12 + 0.04 * sin(anim_time * 1.5)
	draw_rect(Rect2(340, 100, 600, 80), Color(0.6, 0.3, 0.8, glow_alpha))
	draw_string(font, Vector2(SCREEN_W / 2.0 - 200, 160), "GAME LAUNCHER", HORIZONTAL_ALIGNMENT_CENTER, 400, 48, Color8(210, 200, 230))

	# Subtitle
	draw_string(font, Vector2(SCREEN_W / 2.0 - 200, 220), "Pick your vibe, dude", HORIZONTAL_ALIGNMENT_CENTER, 400, 18, Color8(145, 140, 165))
	# Decorative line
	draw_line(Vector2(450, 235), Vector2(830, 235), Color8(80, 65, 110, 120), 1.0)

	# Buttons (cartoony with shadow)
	for i in range(options.size()):
		var rect = _get_button_rect(i)
		var is_hovered = hover_index == i

		# Shadow
		_draw_pill(Rect2(rect.position.x + 4, rect.position.y + 4, rect.size.x, rect.size.y), Color(0, 0, 0, 0.3))
		# Background
		var bg_color = Color8(70, 60, 95) if is_hovered else Color8(42, 38, 58)
		_draw_pill(rect, bg_color)
		# Border
		var border_color = Color8(180, 160, 230) if is_hovered else Color8(100, 88, 140)
		draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x - 4, rect.size.y - 4), border_color, false, 3.0 if is_hovered else 1.5)
		# Selection indicator
		if is_hovered:
			draw_rect(Rect2(rect.position.x + 4, rect.position.y + 4, 4, rect.size.y - 8), Color8(180, 160, 255))
			var pulse = 0.15 + 0.1 * sin(anim_time * 5.0)
			draw_rect(Rect2(rect.position.x - 2, rect.position.y - 2, rect.size.x + 4, rect.size.y + 4), Color(0.7, 0.6, 1.0, pulse), false, 2.0)
		# Top accent line
		_draw_pill(Rect2(rect.position.x, rect.position.y, rect.size.x, 3), Color8(140, 120, 200) if is_hovered else Color8(80, 70, 110))

		# Text
		var text_col = Color.WHITE if is_hovered else Color8(185, 180, 205)
		var prefix = "> " if is_hovered else "  "
		draw_string(font, Vector2(rect.position.x + rect.size.x / 2 - 110, rect.position.y + rect.size.y / 2 + 8), prefix + "[%d] %s" % [i + 1, options[i]], HORIZONTAL_ALIGNMENT_CENTER, 240, 22, text_col)

	# Footer with controller-friendly hint
	draw_string(font, Vector2(SCREEN_W / 2.0 - 200, SCREEN_H - 50), "D-Pad/Stick: Navigate  |  Cross/Space: Select  |  1/2/3: Shortcut", HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color8(110, 105, 130))

func _draw_pill(rect: Rect2, color: Color):
	var r = minf(rect.size.y / 2.0, 6.0)
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2), color)
	for corner in [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
		Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
	]:
		draw_circle(corner, r, color)
