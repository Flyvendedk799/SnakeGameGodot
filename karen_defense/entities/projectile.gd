class_name ProjectileEntity
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var proj_speed: float = 350.0
var damage: int = 10
var source: String = "player"  # "player" or "enemy"
var owner_player = null  # PlayerEntity for kill credit when source == "player"
var lifetime: float = 2.0
var age: float = 0.0

var SIZE: float = 9.0

func update_projectile(delta: float):
	position += direction * proj_speed * delta
	age += delta
	if age >= lifetime or _is_off_screen():
		queue_free()
	queue_redraw()

func _is_off_screen() -> bool:
	return position.x < -50 or position.x > 5200 or position.y < -50 or position.y > 2920

func _draw():
	var color: Color
	var glow_color: Color
	if source == "player":
		color = Color8(255, 230, 100)
		glow_color = Color8(255, 200, 50, 60)
	else:
		color = Color8(220, 80, 220)
		glow_color = Color8(200, 60, 200, 60)

	# Glow
	draw_circle(Vector2.ZERO, SIZE + 4, glow_color)
	# Main body
	draw_circle(Vector2.ZERO, SIZE, color)
	# Bright center
	draw_circle(Vector2.ZERO, SIZE * 0.4, Color.WHITE)
	# Trail
	var trail_end = -direction * 20.0
	draw_line(Vector2.ZERO, trail_end, Color(color, 0.4), 4.0)
	draw_line(Vector2.ZERO, trail_end * 0.6, Color(color, 0.6), 2.0)
