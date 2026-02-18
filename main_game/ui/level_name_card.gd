class_name LevelNameCard
extends Node2D

## Phase 6.2: Level intro name card overlay.
## Created programmatically by main_game._show_level_name_card() and placed on
## a CanvasLayer at layer 15 (screen-space). Fades in over 0.5s, holds, then
## fades out over 0.8s as the level begins.

var level_name: String = ""
var level_num: int = 1
var accent_color: Color = Color(0.7, 0.9, 0.5)
var total_duration: float = 3.5
var _time_remaining: float = 3.5

func _init(name_str: String, num: int, accent: Color, duration: float):
	level_name = name_str
	level_num = num
	accent_color = accent
	total_duration = duration
	_time_remaining = duration

func set_time(remaining: float):
	_time_remaining = remaining

func _compute_alpha() -> float:
	var elapsed = total_duration - _time_remaining
	# Fade in: 0 -> 1 over 0.5s
	if elapsed < 0.5:
		return elapsed / 0.5
	# Hold: 1.0 from 0.5 to (total - 0.8)
	if _time_remaining > 0.8:
		return 1.0
	# Fade out: 1 -> 0 over 0.8s
	return _time_remaining / 0.8

func _draw():
	var alpha = _compute_alpha()
	if alpha < 0.01:
		return

	# Screen-space coordinates (this node lives on a CanvasLayer, so pos (0,0) = top-left)
	var sw = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
	var sh = ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	var cx = sw * 0.5
	var bar_y = sh * 0.62  # Lower third of screen

	var font = ThemeDB.fallback_font

	# Cinematic letterbox bars (top + bottom) - subtle, 24px
	draw_rect(Rect2(0, 0, sw, 24), Color(0, 0, 0, 0.55 * alpha))
	draw_rect(Rect2(0, sh - 24, sw, 24), Color(0, 0, 0, 0.55 * alpha))

	# Semi-transparent wide bar behind text
	var bar_h = 64.0
	draw_rect(Rect2(0, bar_y - 4, sw, bar_h + 8), Color(0, 0, 0, 0.42 * alpha))

	# Accent line above text bar
	draw_rect(Rect2(cx - 200, bar_y - 6, 400, 2), Color(accent_color.r, accent_color.g, accent_color.b, 0.9 * alpha))

	# Level number label (small, above name)
	var sub_text = "Level %d" % level_num
	draw_string(font, Vector2(cx - 100, bar_y + 14), sub_text,
		HORIZONTAL_ALIGNMENT_CENTER, 200, 16,
		Color(accent_color.r, accent_color.g, accent_color.b, 0.85 * alpha))

	# Level name (large, bold)
	var name_font_size = 36
	# Drop shadow
	draw_string(font, Vector2(cx - 249, bar_y + 50), level_name,
		HORIZONTAL_ALIGNMENT_CENTER, 500, name_font_size,
		Color(0, 0, 0, 0.55 * alpha))
	# Main text
	draw_string(font, Vector2(cx - 250, bar_y + 49), level_name,
		HORIZONTAL_ALIGNMENT_CENTER, 500, name_font_size,
		Color(1.0, 1.0, 1.0, alpha))

	# Accent line below text
	draw_rect(Rect2(cx - 180, bar_y + bar_h - 2, 360, 2),
		Color(accent_color.r, accent_color.g, accent_color.b, 0.6 * alpha))
