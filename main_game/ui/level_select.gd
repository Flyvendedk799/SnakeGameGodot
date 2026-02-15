extends Node2D

const SCREEN_W = 1280
const SCREEN_H = 720
const LEVEL_NAMES = [
	"First Steps", "The Ascent", "Below", "High Wire", "The Summit",
	"Ambush Alley", "Gold Rush", "Safe Havens", "The Long March", "Elite Invasion",
	"Underground Gauntlet", "Sky Scramble", "Mixed Madness", "The Chase", "The Final Gauntlet"
]
const LEVEL_COUNT = 15

var selected_index: int = 0
var progress: Dictionary = {}
var anim_time: float = 0.0
var scroll_offset: float = 0.0

func _ready():
	progress = SaveManager.load_main_game_progress()

func _process(delta):
	anim_time += delta
	queue_redraw()

func _input(event):
	if event.is_action_pressed("ui_nav_up"):
		selected_index = maxi(0, selected_index - 1)
		_update_scroll()
		return
	if event.is_action_pressed("ui_nav_down"):
		selected_index = mini(LEVEL_COUNT - 1, selected_index + 1)
		_update_scroll()
		return
	if event.is_action_pressed("ui_nav_left"):
		selected_index = maxi(0, selected_index - 1)
		_update_scroll()
		return
	if event.is_action_pressed("ui_nav_right"):
		selected_index = mini(LEVEL_COUNT - 1, selected_index + 1)
		_update_scroll()
		return
	if event.is_action_pressed("confirm"):
		if _is_unlocked(selected_index + 1):
			_launch_level(selected_index + 1)
		return
	if event.is_action_pressed("ui_back"):
		get_tree().change_scene_to_file("res://launcher.tscn")
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse = event.position
		for i in range(LEVEL_COUNT):
			var rect = _get_level_rect(i)
			if rect.has_point(mouse) and _is_unlocked(i + 1):
				_launch_level(i + 1)
				return

func _is_unlocked(level_id: int) -> bool:
	return SaveManager.is_level_unlocked(level_id, progress)

func _launch_level(level_id: int):
	MainGameManager.current_level = level_id
	get_tree().change_scene_to_file("res://main_game/main_game.tscn")

func _update_scroll():
	var card_h = 100.0
	var gap = 30.0
	var start_y = 200.0
	var rows = ceili(LEVEL_COUNT / 3.0)
	var total_h = start_y + rows * (card_h + gap) - gap
	var max_scroll = maxf(0, total_h - (SCREEN_H - 120))
	var row = selected_index / 3
	var sel_y = start_y + row * (card_h + gap) + card_h / 2.0
	var visible_center = 380.0
	scroll_offset = clampf(sel_y - visible_center, 0, max_scroll)

func _get_level_rect(index: int) -> Rect2:
	var col = index % 3
	var row = index / 3
	var card_w = 380.0
	var card_h = 100.0
	var gap = 30.0
	var start_x = (SCREEN_W - (3 * card_w + 2 * gap)) / 2.0 + gap / 2.0
	var start_y = 200.0
	var x = start_x + col * (card_w + gap)
	var y = start_y + row * (card_h + gap) - scroll_offset
	return Rect2(x, y, card_w, card_h)

func _draw():
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color8(22, 18, 28))
	for i in range(30):
		var bx = fmod(i * 67.0 + anim_time * 6.0 * (0.4 + fmod(i * 0.3, 1.0)), SCREEN_W)
		var by = fmod(i * 43.0 + anim_time * 2.5 * (0.3 + fmod(i * 0.7, 1.0)), SCREEN_H)
		var ba = 0.06 + 0.04 * sin(anim_time * 2.0 + i)
		draw_circle(Vector2(bx, by), 2 + fmod(i, 3), Color(0.5, 0.3, 0.8, ba))

	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(SCREEN_W / 2.0 - 150, 120), "MAIN GAME", HORIZONTAL_ALIGNMENT_CENTER, 300, 40, Color8(210, 200, 230))
	draw_string(font, Vector2(SCREEN_W / 2.0 - 200, 170), "Select Level", HORIZONTAL_ALIGNMENT_CENTER, 400, 18, Color8(145, 140, 165))

	for i in range(LEVEL_COUNT):
		var rect = _get_level_rect(i)
		var is_hovered = selected_index == i
		var unlocked = _is_unlocked(i + 1)
		var completed = (i + 1) in progress.get("levels_completed", [])

		var bg_color: Color
		if not unlocked:
			bg_color = Color8(35, 32, 45)
		elif is_hovered:
			bg_color = Color8(70, 60, 95)
		else:
			bg_color = Color8(42, 38, 58)

		draw_rect(Rect2(rect.position.x + 4, rect.position.y + 4, rect.size.x, rect.size.y), Color(0, 0, 0, 0.3))
		draw_rect(rect, bg_color)
		var border_col = Color8(100, 220, 150) if unlocked else Color8(80, 70, 100)
		if is_hovered and unlocked:
			border_col = Color8(180, 255, 200)
		draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x - 4, rect.size.y - 4), border_col, false, 3.0 if is_hovered else 1.5)

		var num_col = Color.WHITE if unlocked else Color8(100, 95, 120)
		draw_string(font, Vector2(rect.position.x + 20, rect.position.y + 35), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, num_col)
		draw_string(font, Vector2(rect.position.x + 20, rect.position.y + 65), LEVEL_NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, num_col)
		if not unlocked:
			draw_string(font, Vector2(rect.position.x + 20, rect.position.y + 88), "Complete Level %d to unlock" % (i), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(130, 125, 150))
		elif completed:
			draw_string(font, Vector2(rect.position.x + rect.size.x - 30, rect.position.y + 50), "OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(100, 255, 150))

	draw_string(font, Vector2(SCREEN_W / 2.0 - 250, SCREEN_H - 50), "D-Pad: Navigate  |  Cross/Space: Select  |  Circle: Back to Launcher", HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color8(110, 105, 130))
