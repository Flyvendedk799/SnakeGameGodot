class_name GoldDrop
extends Node2D

var amount: int = 5
var player_index_hint: int = 0  # Which player gets credit when picked up
var lifetime: float = 15.0
var age: float = 0.0
var bob_offset: float = 0.0

var tex: Texture2D = null
const SPRITE_H = 34.0

func _ready():
	tex = load("res://assets/100kr.png")

func update_drop(delta: float):
	age += delta
	bob_offset = sin(age * 3.0) * 3.0
	if age >= lifetime:
		queue_free()
	queue_redraw()

func is_flashing() -> bool:
	return age >= lifetime - 3.0

func _draw():
	var alpha = 1.0
	if is_flashing():
		alpha = 0.4 + 0.6 * abs(sin(age * 8.0))

	# Shadow
	draw_circle(Vector2(1, bob_offset + 14), 14.0, Color(0, 0, 0, 0.15 * alpha))

	# Draw joint sprite
	if tex:
		var tex_size = tex.get_size()
		var s = SPRITE_H / tex_size.y
		draw_set_transform(Vector2(0, bob_offset), 0, Vector2(s, s))
		draw_texture(tex, -tex_size / 2.0, Color(1, 1, 1, alpha))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		# Fallback circle
		draw_circle(Vector2(0, bob_offset), 10.0, Color(1.0, 0.85, 0.0, alpha))

	# Amount label above
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(-12, bob_offset - 20), "+%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 0.6, alpha))
