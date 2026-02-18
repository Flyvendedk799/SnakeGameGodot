class_name CompanionHelicopterEntity
extends Node2D

## Persistent helicopter controlled by companion joystick. Visible only in the game.
## Can patrol (joystick) and perform bomb drops when companion taps minimap.

var game = null
var move_input: Vector2 = Vector2.ZERO
var phase: String = "patrol"  # "patrol" or "bomb_run"
var bomb_target: Vector2 = Vector2.ZERO

const BLAST_RADIUS: float = 90.0
const DAMAGE: int = 60
const SPEED: float = 280.0
const BOMB_RUN_SPEED: float = 350.0
const ARRIVE_DIST: float = 25.0

func setup(game_ref):
	game = game_ref
	var m = game.map
	position = Vector2(m.FORT_LEFT - 60, m.FORT_TOP - 80)
	phase = "patrol"

func set_joystick_input(ax: float, ay: float):
	move_input.x = clampf(ax, -1.0, 1.0)
	move_input.y = clampf(ay, -1.0, 1.0)
	# Dead zone - small inputs ignored
	if move_input.length() < 0.15:
		move_input = Vector2.ZERO

func request_bomb_drop(world_pos: Vector2) -> bool:
	if phase != "patrol":
		return false
	phase = "bomb_run"
	bomb_target = world_pos
	return true

func _clamp_to_bounds() -> Vector2:
	var m = game.map
	var margin_x = 100.0
	var margin_y = 80.0
	var x = clampf(position.x, m.FORT_LEFT - margin_x, m.FORT_RIGHT + margin_x)
	var y = clampf(position.y, m.FORT_TOP - margin_y, m.FORT_BOTTOM + margin_y)
	return Vector2(x, y)

func update_helicopter(delta: float) -> void:
	if phase == "patrol":
		if move_input.length_squared() > 0.01:
			var dir = move_input.normalized()
			position += dir * SPEED * delta
		position = _clamp_to_bounds()
	elif phase == "bomb_run":
		var to_target = bomb_target - position
		var dist = to_target.length()
		if dist <= ARRIVE_DIST:
			_explode()
			phase = "patrol"
		else:
			var dir = to_target.normalized()
			position += dir * BOMB_RUN_SPEED * delta
			position = _clamp_to_bounds()
	queue_redraw()

func _explode():
	var bomb_ground_pos = bomb_target
	var kills := 0
	for enemy in game.enemy_container.get_children():
		if enemy.state in [EnemyEntity.EnemyState.DEAD, EnemyEntity.EnemyState.DYING]: continue
		var dist = bomb_ground_pos.distance_to(enemy.position)
		if dist <= BLAST_RADIUS:
			var falloff = 1.0 - (dist / BLAST_RADIUS) * 0.5
			var dmg = int(DAMAGE * falloff)
			enemy.last_damager = game.player_node
			enemy.take_damage(dmg, game)
			if enemy.state == EnemyEntity.EnemyState.DYING:
				kills += 1
			game.spawn_damage_number(enemy.position, str(dmg), Color8(255, 180, 50))

	var is_mega = kills >= 5
	if is_mega:
		game.spawn_damage_number(bomb_ground_pos, "MEGA STRIKE!", Color8(255, 100, 255))
		game.particles.emit_burst(bomb_ground_pos.x, bomb_ground_pos.y, Color8(255, 100, 255), 30, 0.8)
		game.start_shake(8.0, 0.3)
		game.start_chromatic(12.0)
	else:
		game.particles.emit_burst(bomb_ground_pos.x, bomb_ground_pos.y, Color8(255, 160, 30), 20, 0.6)
		game.start_shake(5.0, 0.2)

	if game.sfx:
		game.sfx.play_grenade_explode()
	if game.companion_session:
		game._on_companion_bomb_landed(bomb_ground_pos, kills)

func fire_burst(world_pos: Vector2) -> void:
	## Chopper strafing burst: instant damage to enemies near world_pos.
	## Does NOT interrupt patrol — fires from wherever the chopper is.
	const BURST_RADIUS: float = 80.0
	const BURST_DAMAGE: int = 25
	var hits := 0
	for enemy in game.enemy_container.get_children():
		if enemy.state in [EnemyEntity.EnemyState.DEAD, EnemyEntity.EnemyState.DYING]:
			continue
		if world_pos.distance_to(enemy.position) <= BURST_RADIUS:
			var falloff = 1.0 - (world_pos.distance_to(enemy.position) / BURST_RADIUS) * 0.4
			var dmg = int(BURST_DAMAGE * falloff)
			enemy.last_damager = game.player_node
			enemy.take_damage(dmg, game)
			hits += 1
			game.spawn_damage_number(enemy.position, str(dmg), Color8(150, 220, 255))
	if hits > 0:
		game.particles.emit_burst(world_pos.x, world_pos.y, Color8(150, 220, 255), 10, 0.4)
		game.start_shake(2.0, 0.08)
	else:
		game.particles.emit_burst(world_pos.x, world_pos.y, Color8(200, 200, 255), 5, 0.2)

func _draw():
	draw_circle(Vector2.ZERO, 18, Color.DARK_GRAY)
	draw_circle(Vector2(-8, -12), 6, Color.GRAY)
	draw_circle(Vector2(8, -12), 6, Color.GRAY)
