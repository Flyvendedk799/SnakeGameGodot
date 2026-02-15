class_name EmpEffectEntity
extends Node2D

var game = null
var emp_pos: Vector2
var timer: float = 0.0
var duration: float = 0.3
const STUN_RADIUS: float = 80.0
const STUN_DURATION: float = 2.0

func setup(game_ref, world_pos: Vector2):
	game = game_ref
	emp_pos = world_pos
	position = emp_pos

	# Apply stun effect to all enemies in radius
	for enemy in game.enemy_container.get_children():
		if enemy.state in [EnemyEntity.EnemyState.DEAD, EnemyEntity.EnemyState.DYING]: continue
		var dist = emp_pos.distance_to(enemy.position)
		if dist <= STUN_RADIUS:
			enemy.stun_timer = STUN_DURATION
			game.spawn_damage_number(enemy.position, "STUNNED!", Color8(100, 200, 255))

	# Visual and audio feedback
	game.particles.emit_burst(emp_pos.x, emp_pos.y, Color8(100, 180, 255), 15, 0.5)
	game.start_shake(3.0, 0.15)
	if game.sfx:
		game.sfx.play_repair()  # Placeholder sound

func update_effect(delta: float) -> bool:
	timer += delta
	if timer >= duration:
		return true
	queue_redraw()
	return false

func _draw():
	var progress = timer / duration
	var alpha = 1.0 - progress
	var radius = STUN_RADIUS * (0.5 + progress * 0.5)
	# Electric ring effect
	draw_circle(Vector2.ZERO, radius, Color(0.4, 0.7, 1.0, alpha * 0.2))
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.8, 1.0, alpha * 0.6), false, 2.0)
	# Inner flash
	var inner_r = radius * 0.3
	draw_circle(Vector2.ZERO, inner_r, Color(0.7, 0.9, 1.0, alpha * 0.4))
