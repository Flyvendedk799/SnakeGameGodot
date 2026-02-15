class_name BarricadeEntity
extends Node2D

var max_hp: int = 120
var current_hp: int = 120
var is_spiked: bool = false
var spike_damage: int = 5
var is_vertical: bool = false
var repair_accum: float = 0.0

const BAR_W = 80.0
const BAR_H = 24.0

# Sprites
var tex_full: Texture2D = null
var tex_damaged: Texture2D = null

func _ready():
	tex_full = load("res://assets/barrier.png")
	tex_damaged = load("res://assets/barrier50.png")

func is_intact() -> bool:
	return current_hp > 0

func take_damage(amount: int) -> int:
	current_hp = maxi(0, current_hp - amount)
	queue_redraw()
	if is_spiked and current_hp > 0:
		return spike_damage
	return 0

func repair(amount: float):
	repair_accum += amount
	var whole = int(repair_accum)
	if whole > 0:
		current_hp = mini(max_hp, current_hp + whole)
		repair_accum -= whole
	queue_redraw()

func partial_repair(fraction: float):
	repair(int(max_hp * fraction))

func full_repair():
	current_hp = max_hp
	queue_redraw()

func reset():
	current_hp = max_hp
	is_spiked = false
	repair_accum = 0.0
	queue_redraw()

func _draw():
	var w = BAR_H if is_vertical else BAR_W
	var h = BAR_W if is_vertical else BAR_H
	var hp_ratio = float(current_hp) / float(max_hp)

	if current_hp <= 0:
		# Rubble — small scattered pieces
		for i in range(5):
			var rx = -w / 2 + (i + 1) * w / 6.0
			var ry = -h / 2 + fmod((i + 1) * 3.7, h)
			draw_rect(Rect2(rx - 3, ry - 2, 6, 4), Color8(100, 80, 60, 100))
		draw_rect(Rect2(-w / 2, -h / 2, w, h), Color8(120, 80, 60, 50), false, 1.0)
		var font = ThemeDB.fallback_font
		draw_string(font, Vector2(-w / 2 - 2, h / 2 + 14), "BROKEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(220, 80, 80))
		return

	# Pick texture based on HP
	var tex = tex_full if hp_ratio > 0.5 else tex_damaged
	if tex:
		var tex_size = tex.get_size()
		# Scale uniformly to fit the entrance width, preserving aspect ratio
		var target_w = (h if is_vertical else w) + 16.0
		var s = target_w / tex_size.x
		if is_vertical:
			# Rotate 90 degrees for vertical barricades
			draw_set_transform(Vector2.ZERO, -PI / 2.0, Vector2(s, s))
		else:
			draw_set_transform(Vector2.ZERO, 0, Vector2(s, s))
		draw_texture(tex, -tex_size / 2.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# HP bar (only when damaged)
	if current_hp < max_hp:
		var bar_total = w + 16
		var bar_y = -h / 2 - 14
		draw_rect(Rect2(-bar_total / 2, bar_y, bar_total, 6), Color8(30, 0, 0, 200))
		var hp_col = Color8(220, 50, 50) if hp_ratio < 0.3 else Color8(220, 180, 50) if hp_ratio < 0.6 else Color8(60, 220, 60)
		draw_rect(Rect2(-bar_total / 2, bar_y, bar_total * hp_ratio, 6), hp_col)
