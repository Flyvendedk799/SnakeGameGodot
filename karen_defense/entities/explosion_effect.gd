class_name ExplosionEffect
extends Node2D

var duration: float = 0.45
var timer: float = 0.0
var blast_radius: float = 85.0
var fired_once: bool = false

func setup(at_pos: Vector2, radius: float):
	position = at_pos
	blast_radius = radius
	timer = duration
	fired_once = true

func update_effect(delta: float) -> bool:
	timer -= delta
	queue_redraw()
	return timer <= 0

func _draw():
	var t = 1.0 - clampf(timer / maxf(duration, 0.001), 0.0, 1.0)
	var flash = maxf(0.0, 1.0 - t * 2.5)
	var smoke = clampf((t - 0.1) / 0.9, 0.0, 1.0)
	var blast = ease(1.0 - t, 2.0)

	if flash > 0.01:
		draw_circle(Vector2.ZERO, blast_radius * 0.45 * (1.0 + t), Color(1.0, 0.95, 0.75, flash * 0.8))
		draw_circle(Vector2.ZERO, blast_radius * 0.28 * (1.0 + t * 1.2), Color(1.0, 0.55, 0.2, flash * 0.85))

	var fire_r = blast_radius * (0.35 + blast * 0.5)
	draw_circle(Vector2.ZERO, fire_r, Color(1.0, 0.35, 0.12, (1.0 - t) * 0.55))
	draw_circle(Vector2.ZERO, fire_r * 0.65, Color(1.0, 0.72, 0.28, (1.0 - t) * 0.45))

	if smoke > 0.01:
		for i in range(8):
			var a = TAU * float(i) / 8.0 + t * 1.7
			var p = Vector2.from_angle(a) * blast_radius * (0.2 + smoke * 0.9)
			draw_circle(p, 10.0 + smoke * 18.0, Color(0.18, 0.18, 0.2, 0.2 * (1.0 - smoke)))
