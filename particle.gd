class_name Particle
extends RefCounted

enum Shape { CIRCLE, SQUARE, STREAK }

var x: float
var y: float
var vx: float
var vy: float
var color: Color
var lifetime: float
var age: float = 0.0
var size: float
var shape: Shape = Shape.CIRCLE
var rotation: float = 0.0
var spin_speed: float = 0.0
var gravity_mult: float = 1.0
var ground_y: float = -1.0
var bounce_damping: float = 0.5
var streak_length: float = 8.0

func _init(px: float, py: float, pvx: float, pvy: float, pcol: Color, plifetime: float, psize: int = 4):
	x = px
	y = py
	vx = pvx
	vy = pvy
	color = pcol
	lifetime = plifetime
	size = float(psize)

func update(dt: float):
	x += vx * dt
	y += vy * dt
	vy += 400.0 * gravity_mult * dt
	vx *= (1.0 - 2.0 * dt)
	rotation += spin_speed * dt
	age += dt
	if ground_y > 0 and y > ground_y:
		y = ground_y
		vy = -abs(vy) * bounce_damping
		vx *= 0.7

func draw_particle(canvas: CanvasItem):
	if age >= lifetime:
		return
	var t = age / lifetime
	var alpha = 1.0 - t * t
	var current_size = maxf(1.0, size * (1.0 - t * 0.5))
	var current_color = Color(color.r, color.g, color.b, alpha * 0.9)
	var pos = Vector2(x, y)

	match shape:
		Shape.CIRCLE:
			canvas.draw_circle(pos, current_size, current_color)
			if current_size > 2.5:
				canvas.draw_circle(pos, current_size * 0.35, Color(1, 1, 1, alpha * 0.4))
		Shape.SQUARE:
			var half = current_size
			canvas.draw_set_transform(pos, rotation, Vector2.ONE)
			canvas.draw_rect(Rect2(-half, -half, half * 2, half * 2), current_color)
			canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		Shape.STREAK:
			var speed = Vector2(vx, vy).length()
			var dir = Vector2(vx, vy).normalized() if speed > 1.0 else Vector2.RIGHT
			var length = clampf(speed * 0.04, 3.0, streak_length * (1.0 - t))
			var end_pos = pos - dir * length
			canvas.draw_line(pos, end_pos, current_color, maxf(1.0, current_size * 0.6))
			canvas.draw_circle(pos, current_size * 0.4, Color(1, 1, 1, alpha * 0.35))

func is_alive() -> bool:
	return age < lifetime
