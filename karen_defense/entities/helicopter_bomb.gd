class_name HelicopterBombEntity
extends Node2D

var game = null
var drop_pos: Vector2
var phase: String = "fly"
var timer: float = 0.0
var fly_duration: float = 1.2
var drop_duration: float = 0.5
var start_pos: Vector2
var bomb_ground_pos: Vector2
const BLAST_RADIUS: float = 90.0
const DAMAGE: int = 60

func setup(game_ref, world_pos: Vector2):
	game = game_ref
	drop_pos = world_pos
	var map = game.map
	start_pos = Vector2(map.FORT_LEFT - 80, map.get_fort_center().y)
	position = start_pos

func update_helicopter(delta: float) -> bool:
	timer += delta
	if phase == "fly":
		var t = clampf(timer / fly_duration, 0, 1)
		position = start_pos.lerp(Vector2(drop_pos.x, start_pos.y), t)
		if t >= 1:
			phase = "drop"
			timer = 0
			bomb_ground_pos = drop_pos
			position = Vector2(drop_pos.x, start_pos.y)
	elif phase == "drop":
		if timer >= drop_duration:
			_explode()
			return true
	queue_redraw()
	return false

func _explode():
	for enemy in game.enemy_container.get_children():
		if enemy.state in [EnemyEntity.EnemyState.DEAD, EnemyEntity.EnemyState.DYING]: continue
		var dist = bomb_ground_pos.distance_to(enemy.position)
		if dist <= BLAST_RADIUS:
			var falloff = 1.0 - (dist / BLAST_RADIUS) * 0.5
			var dmg = int(DAMAGE * falloff)
			enemy.last_damager = game.player_node
			enemy.take_damage(dmg, game)
			game.spawn_damage_number(enemy.position, str(dmg), Color8(255, 180, 50))
	game.particles.emit_burst(bomb_ground_pos.x, bomb_ground_pos.y, Color8(255, 160, 30), 20, 0.6)
	game.start_shake(5.0, 0.2)
	if game.sfx:
		game.sfx.play_grenade_explode()
	queue_free()

func _draw():
	if phase == "fly":
		draw_circle(Vector2.ZERO, 18, Color.DARK_GRAY)
		draw_circle(Vector2(-8, -12), 6, Color.GRAY)
		draw_circle(Vector2(8, -12), 6, Color.GRAY)
	elif phase == "drop":
		var fall_y = -50 * (1 - timer / drop_duration)
		draw_circle(Vector2(0, fall_y), 12, Color8(80, 60, 40))
