class_name BossManager
extends Node

## Manages boss fights: spawning, phases, patterns, and victory.

var game = null
var boss_entity: EnemyEntity = null
var boss_config: Dictionary = {}
var current_phase: int = -1
var phase_triggered: Array = []
var boss_active: bool = false
var boss_defeated: bool = false
var defeat_timer: float = 0.0

func setup(game_ref):
	game = game_ref
	boss_entity = null
	boss_config = game.map.level_config.get("boss_config", {})
	current_phase = -1
	phase_triggered.clear()
	boss_active = false
	boss_defeated = false
	defeat_timer = 0.0

	if boss_config.is_empty():
		return

	# Mark phase tracking
	var phases = boss_config.get("phases", [])
	for i in range(phases.size()):
		phase_triggered.append(false)

func is_boss_level() -> bool:
	return not boss_config.is_empty()

func spawn_boss():
	"""Called when player reaches the boss trigger area."""
	if boss_active or boss_defeated:
		return

	var type_name = boss_config.get("type", "manager")
	var stats = EnemyData.get_stats("manager")  # Base stats
	stats = stats.duplicate()
	var hp_mult = float(boss_config.get("hp_mult", 5.0))
	stats.hp = int(stats.hp * hp_mult)
	stats.damage = int(stats.damage * 2)
	stats.speed = stats.speed * 0.8

	boss_entity = EnemyEntity.new()
	boss_entity.initialize(type_name, stats)
	boss_entity.is_boss = true
	boss_entity.state = EnemyEntity.EnemyState.CHASING
	boss_entity.chase_target = game.player_node

	var spawn_x = float(boss_config.get("spawn_x", 800))
	var spawn_y = float(boss_config.get("spawn_y", 400))
	var spawn_pos = Vector2(spawn_x, spawn_y)

	# Fix spawn position for sideview mode - place boss on ground
	if game.map.has_method("get_ground_surface_y"):
		var ground_y = game.map.get_ground_surface_y(spawn_pos, boss_entity.entity_size)
		if ground_y > 0:
			spawn_y = ground_y - boss_entity.entity_size
	elif game.map.has_method("get_ground_y_at_x"):
		spawn_y = game.map.get_ground_y_at_x(spawn_x) - boss_entity.entity_size

	boss_entity.position = Vector2(spawn_x, spawn_y)

	game.enemy_container.add_child(boss_entity)
	boss_active = true

	if game.sfx:
		game.sfx.play_boss_roar()
	game.start_shake(8.0, 0.3)

func update(delta: float):
	if not boss_active or boss_defeated:
		return

	if boss_entity == null or not is_instance_valid(boss_entity):
		_on_boss_defeated()
		return

	if boss_entity.state == EnemyEntity.EnemyState.DEAD or boss_entity.state == EnemyEntity.EnemyState.DYING:
		_on_boss_defeated()
		return

	# Check phase transitions
	_check_phases()

func _check_phases():
	if boss_entity == null or not is_instance_valid(boss_entity):
		return

	var hp_ratio = float(boss_entity.current_hp) / float(boss_entity.max_hp)
	var phases = boss_config.get("phases", [])

	for i in range(phases.size()):
		if phase_triggered[i]:
			continue
		var phase = phases[i]
		var threshold = float(phase.get("hp_pct", 0.5))
		if hp_ratio <= threshold:
			phase_triggered[i] = true
			current_phase = i
			_activate_phase(phase)

func _activate_phase(phase: Dictionary):
	var pattern = phase.get("pattern", "")

	# Visual feedback
	if game.sfx:
		game.sfx.play_boss_phase()
	game.start_shake(6.0, 0.2)

	match pattern:
		"charge":
			# Boss moves faster
			var speed_mult = float(phase.get("speed_mult", 1.5))
			boss_entity.move_speed *= speed_mult
		"minions":
			# Spawn support enemies
			var count = int(phase.get("spawn_count", 3))
			_spawn_minions(count)
		"ground_slam":
			# Area attack - damage all nearby players
			_boss_ground_slam()
		"enrage":
			# Boss gets faster and stronger
			boss_entity.move_speed *= 1.4
			boss_entity.damage = int(boss_entity.damage * 1.5)
		"boulder_throw":
			# Boss throws projectiles faster
			boss_entity.attack_cooldown *= 0.6
		"wind_blast", "lightning_rain", "tornado":
			# Various ranged patterns - spawn projectiles
			_boss_ranged_burst(3)
		"ice_shards", "freeze_wave", "blizzard":
			# Cold patterns
			_boss_ranged_burst(4)
			boss_entity.move_speed *= 1.2
		"summon_minions":
			_spawn_minions(int(phase.get("spawn_count", 4)))
		"arena_hazards":
			# Make boss faster in final phases
			boss_entity.move_speed *= 1.3
		"final_form", "desperation":
			boss_entity.move_speed *= 1.5
			boss_entity.damage = int(boss_entity.damage * 1.3)
			_spawn_minions(2)
		"rage_charge":
			boss_entity.move_speed *= 1.6
		_:
			# Default: speed up
			boss_entity.move_speed *= 1.2

func _spawn_minions(count: int):
	for i in range(count):
		var minion = EnemyEntity.new()
		var stats = EnemyData.get_stats("complainer")
		minion.initialize("complainer", stats)
		minion.state = EnemyEntity.EnemyState.CHASING
		minion.chase_target = game.player_node

		var offset_x = randf_range(-100, 100)
		var spawn_pos = boss_entity.position + Vector2(offset_x, 0)

		# Fix spawn position for sideview mode - place minion on ground
		if game.map.has_method("get_ground_surface_y"):
			var ground_y = game.map.get_ground_surface_y(spawn_pos, minion.entity_size)
			if ground_y > 0:
				spawn_pos.y = ground_y - minion.entity_size
		elif game.map.has_method("get_ground_y_at_x"):
			spawn_pos.y = game.map.get_ground_y_at_x(spawn_pos.x) - minion.entity_size

		minion.position = spawn_pos
		game.enemy_container.add_child(minion)

func _boss_ground_slam():
	"""AoE damage around boss position."""
	for p in [game.player_node, game.player2_node]:
		if p == null or p.is_dead:
			continue
		if p.position.distance_to(boss_entity.position) < 120:
			p.take_damage(boss_entity.damage, game)
			p.velocity.y = -250.0
	# VFX
	game.particles.emit_burst(boss_entity.position.x, boss_entity.position.y, Color8(200, 100, 50), 15)
	game.start_shake(10.0, 0.25)

func _boss_ranged_burst(count: int):
	"""Fire projectiles in multiple directions."""
	for i in range(count):
		var proj = ProjectileEntity.new()
		proj.position = boss_entity.position
		var angle = TAU * i / float(count) + randf_range(-0.2, 0.2)
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.damage = boss_entity.damage
		proj.source = "enemy"
		proj.proj_speed = 180.0
		game.projectile_container.add_child(proj)

func _on_boss_defeated():
	boss_defeated = true
	boss_active = false
	defeat_timer = 2.0

	if game.sfx:
		game.sfx.play_boss_defeat()
	game.start_shake(12.0, 0.5)
	game.start_chromatic(8.0)

	# Big particle burst
	if boss_entity and is_instance_valid(boss_entity):
		game.particles.emit_burst(boss_entity.position.x, boss_entity.position.y, Color.GOLD, 30)
		game.particles.emit_burst(boss_entity.position.x, boss_entity.position.y, Color8(255, 100, 50), 20)
