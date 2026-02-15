class_name StoryPanel
extends Node2D

## Simple cutscene/story panel for world intros and boss intros.
## Displays text + portrait in a cinematic overlay.

const SCREEN_W = 1280
const SCREEN_H = 720

var story_text: String = ""
var portrait_name: String = ""
var title_text: String = ""
var on_dismiss: Callable = Callable()
var anim_time: float = 0.0
var chars_revealed: int = 0
var reveal_speed: float = 40.0  # chars per second
var fully_revealed: bool = false
var dismiss_timer: float = 0.0

# World narrative data
const WORLD_INTROS = {
	1: {"title": "World 1: Grasslands", "text": "The Karens have invaded the peaceful grasslands.\nIt's up to you to push them back, one complaint at a time.", "portrait": "hero"},
	2: {"title": "World 2: Caves", "text": "Deep below the surface, the Karen horde has established\nunderground bases. The tunnels are dark and treacherous.", "portrait": "hero"},
	3: {"title": "World 3: Sky Realm", "text": "The Karens have taken to the skies, building floating\nfortresses above the clouds. Mind the gaps.", "portrait": "hero"},
	4: {"title": "World 4: Summit", "text": "The frozen summit is the last bastion before the\nKaren HQ. Ice, wind, and relentless enemies await.", "portrait": "hero"},
	5: {"title": "World 5: Final Gauntlet", "text": "This is it. Everything you've learned will be tested.\nThe ultimate Karen awaits at the end.", "portrait": "hero"},
}

const BOSS_INTROS = {
	5: {"title": "BOSS: Manager Karen", "text": "\"I want to speak to your manager's manager!\"", "portrait": "boss"},
	10: {"title": "BOSS: Cave Troll Karen", "text": "\"This cave is not up to code! Where's the manager?!\"", "portrait": "boss"},
	15: {"title": "BOSS: Storm Karen", "text": "\"I'll blow you away with my complaints!\"", "portrait": "boss"},
	20: {"title": "BOSS: Frost Guardian", "text": "\"You're giving me the cold shoulder? UNACCEPTABLE!\"", "portrait": "boss"},
	25: {"title": "BOSS: Final Karen", "text": "\"I AM the manager. And you're FIRED!\"", "portrait": "boss"},
}

func show_world_intro(world_id: int):
	if WORLD_INTROS.has(world_id):
		var data = WORLD_INTROS[world_id]
		title_text = data.title
		story_text = data.text
		portrait_name = data.portrait
	_reset_animation()
	visible = true

func show_boss_intro(level_id: int):
	if BOSS_INTROS.has(level_id):
		var data = BOSS_INTROS[level_id]
		title_text = data.title
		story_text = data.text
		portrait_name = data.portrait
	_reset_animation()
	visible = true

func _reset_animation():
	anim_time = 0.0
	chars_revealed = 0
	fully_revealed = false
	dismiss_timer = 0.0

func _process(delta):
	if not visible:
		return
	anim_time += delta
	if not fully_revealed:
		chars_revealed = int(anim_time * reveal_speed)
		if chars_revealed >= story_text.length():
			fully_revealed = true
			dismiss_timer = 0.0
	else:
		dismiss_timer += delta
	queue_redraw()

func _input(event):
	if not visible:
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("ui_accept"):
		if not fully_revealed:
			# Skip to full reveal
			fully_revealed = true
			chars_revealed = story_text.length()
		elif dismiss_timer > 0.3:
			visible = false
			if on_dismiss.is_valid():
				on_dismiss.call()
		get_viewport().set_input_as_handled()

func _draw():
	if not visible:
		return

	var font = ThemeDB.fallback_font

	# Cinematic bars
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color(0, 0, 0, 0.75))

	# Top and bottom cinematic bars
	var bar_h = 80.0
	draw_rect(Rect2(0, 0, SCREEN_W, bar_h), Color(0, 0, 0, 0.9))
	draw_rect(Rect2(0, SCREEN_H - bar_h, SCREEN_W, bar_h), Color(0, 0, 0, 0.9))

	# Title
	var title_alpha = minf(anim_time * 2.0, 1.0)
	var is_boss = portrait_name == "boss"
	var title_col = Color8(255, 100, 80, int(255 * title_alpha)) if is_boss else Color8(220, 210, 240, int(255 * title_alpha))
	draw_string(font, Vector2(SCREEN_W / 2.0 - 200, 200), title_text, HORIZONTAL_ALIGNMENT_CENTER, 400, 28, title_col)

	# Text (typewriter effect)
	var display_text = story_text.substr(0, chars_revealed)
	var lines = display_text.split("\n")
	var text_y = 280.0
	for line in lines:
		draw_string(font, Vector2(SCREEN_W / 2.0 - 300, text_y), line, HORIZONTAL_ALIGNMENT_CENTER, 600, 16, Color8(200, 195, 220))
		text_y += 28.0

	# Portrait placeholder (colored circle)
	var portrait_cx = 180.0
	var portrait_cy = SCREEN_H / 2.0
	var portrait_col = Color8(255, 80, 80) if is_boss else Color8(80, 160, 255)
	draw_circle(Vector2(portrait_cx, portrait_cy), 50, portrait_col.darkened(0.3))
	draw_circle(Vector2(portrait_cx, portrait_cy), 45, portrait_col)
	var icon_text = "B" if is_boss else "H"
	draw_string(font, Vector2(portrait_cx - 8, portrait_cy + 8), icon_text, HORIZONTAL_ALIGNMENT_CENTER, 20, 28, Color.WHITE)

	# Continue prompt
	if fully_revealed and dismiss_timer > 0.3:
		var prompt_alpha = 0.5 + 0.5 * sin(anim_time * 3.0)
		draw_string(font, Vector2(SCREEN_W / 2.0 - 100, SCREEN_H - 120), "Press Enter to continue", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color(1, 1, 1, prompt_alpha))
