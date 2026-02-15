class_name LevelUpMenu
extends Node2D

var game = null
var active: bool = false
var skill_choices: Array = []
var hover_index: int = -1
var kb_index: int = 0
var level_up_player_index: int = 0  # which player (0=P1, 1=P2) is picking the skill

const CARD_W = 220.0
const CARD_H = 140.0
const CARD_GAP = 30.0

func setup(game_ref):
	game = game_ref

func show_menu(for_player_index: int = 0):
	active = true
	level_up_player_index = clampi(for_player_index, 0, 1)
	skill_choices = SkillData.get_random_skills(3, game.progression.get_skills_picked(level_up_player_index))
	hover_index = -1
	kb_index = 0

func hide_menu():
	active = false
	queue_redraw()

func _process(_delta):
	if not active:
		return
	# Mouse hover updates kb_index only for P1 (avoid P2's selection jumping from P1's mouse)
	if level_up_player_index == 0:
		var mouse = get_global_mouse_position()
		for i in range(skill_choices.size()):
			var rect = _get_card_rect(i)
			if rect.has_point(mouse):
				kb_index = i
				break
	hover_index = kb_index
	queue_redraw()

func _is_input_from_leveling_player(event) -> bool:
	# Only the player who leveled up can control the upgrade selection
	# P1: keyboard/mouse (device -1) or controller 0
	# P2: controller 1 only
	var device = event.device if event.get("device") != null else -1
	if level_up_player_index == 0:
		return device == -1 or device == 0
	return device == 1

func handle_input(event) -> bool:
	if not active:
		return false
	if not _is_input_from_leveling_player(event):
		return true
	# Mouse click (P1 only - mouse is device -1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and level_up_player_index == 0:
		if hover_index >= 0 and hover_index < skill_choices.size():
			_pick_skill(hover_index)
			return true
	# Action-based navigation
	if event.is_action_pressed("ui_nav_left"):
		kb_index = maxi(0, kb_index - 1)
		hover_index = kb_index
		return true
	if event.is_action_pressed("ui_nav_right"):
		kb_index = mini(skill_choices.size() - 1, kb_index + 1)
		hover_index = kb_index
		return true
	# Number keys (keyboard only - P1)
	if event is InputEventKey and event.pressed and level_up_player_index == 0:
		if event.keycode == KEY_1 and skill_choices.size() >= 1:
			_pick_skill(0)
			return true
		if event.keycode == KEY_2 and skill_choices.size() >= 2:
			_pick_skill(1)
			return true
		if event.keycode == KEY_3 and skill_choices.size() >= 3:
			_pick_skill(2)
			return true
	if event.is_action_pressed("confirm"):
		if kb_index >= 0 and kb_index < skill_choices.size():
			_pick_skill(kb_index)
			return true
	return false

func _pick_skill(index: int):
	var skill = skill_choices[index]
	game.progression.pick_skill(skill.id, level_up_player_index)
	hide_menu()
	game.resume_from_level_up()

func _get_card_rect(index: int) -> Rect2:
	var total_w = skill_choices.size() * CARD_W + (skill_choices.size() - 1) * CARD_GAP
	var start_x = (1280 - total_w) / 2.0
	var x = start_x + index * (CARD_W + CARD_GAP)
	var y = (720 - CARD_H) / 2.0
	return Rect2(x, y, CARD_W, CARD_H)

func _draw():
	if not active:
		return
	var font = ThemeDB.fallback_font

	# Dark overlay
	draw_rect(Rect2(0, 0, 1280, 720), Color8(0, 0, 0, 180))

	# Title
	draw_string(font, Vector2(490, 200), "LEVEL UP, DUDE!", HORIZONTAL_ALIGNMENT_CENTER, 300, 28, Color8(255, 220, 100))
	var p_label = "P%d " % (level_up_player_index + 1) if game.p2_joined else ""
	draw_string(font, Vector2(440, 235), "Pick a new ability (%sLevel %d)" % [p_label, game.progression.get_level(level_up_player_index)], HORIZONTAL_ALIGNMENT_CENTER, 400, 14, Color8(200, 200, 220))

	# Skill cards
	for i in range(skill_choices.size()):
		var skill = skill_choices[i]
		var rect = _get_card_rect(i)
		var is_hovered = hover_index == i

		var bg = Color8(55, 50, 70, 240) if not is_hovered else Color8(70, 65, 90, 240)
		draw_rect(rect, bg)
		var border_color = skill.color if is_hovered else skill.color.darkened(0.3)
		draw_rect(rect, border_color, false, 2.0 if not is_hovered else 3.0)

		# Category color strip at top
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 4), skill.color)

		var tx = rect.position.x + 12
		var ty = rect.position.y + 30

		# Number key hint
		draw_string(font, Vector2(rect.position.x + rect.size.x - 24, ty), "[%d]" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(150, 150, 170))

		draw_string(font, Vector2(tx, ty), skill.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		var scope = skill.get("scope", "player")
		var scope_label = "TEAM" if scope == "global" else ("P%d" % (level_up_player_index + 1))
		var scope_color = Color8(100, 200, 255) if scope == "global" else Color8(255, 200, 100)
		draw_string(font, Vector2(tx, ty + 20), "[%s] %s" % [skill.category.to_upper(), scope_label], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, scope_color)
		draw_string(font, Vector2(tx, ty + 45), skill.description, HORIZONTAL_ALIGNMENT_LEFT, int(CARD_W - 24), 12, Color8(200, 200, 220))

		if is_hovered:
			draw_string(font, Vector2(tx, ty + 85), "Cross / Space to select", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(180, 255, 180))

	# Navigation hint - show who controls
	var ctrl_hint = "P1: L/R or D-Pad | 1/2/3 | Cross/Space" if level_up_player_index == 0 else "P2: D-Pad | Cross to confirm (Controller 2)"
	draw_string(font, Vector2(340, 470), ctrl_hint, HORIZONTAL_ALIGNMENT_CENTER, 600, 11, Color8(140, 140, 160))
