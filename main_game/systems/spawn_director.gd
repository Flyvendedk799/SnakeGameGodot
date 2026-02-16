class_name SpawnDirector
extends Node

var game = null
var active_segment_indices: Array = []
var zone_spawn_timers: Dictionary = {}
var global_max_enemies: int = 14
var spawn_interval: float = 2.8

var base_global_max_enemies: int = 14
var base_spawn_interval: float = 2.8
var recovery_window_timer: float = 0.0
var recent_kill_times: Array[float] = []

func setup(game_ref):
	game = game_ref
	active_segment_indices.clear()
	zone_spawn_timers.clear()
	recent_kill_times.clear()
	recovery_window_timer = 0.0
	base_global_max_enemies = global_max_enemies
	base_spawn_interval = spawn_interval

func notify_enemy_killed():
	recent_kill_times.append(Time.get_ticks_msec() / 1000.0)

func start_recovery_window(duration: float = 10.0):
	recovery_window_timer = maxf(recovery_window_timer, duration)

func update(delta: float):
	if game == null or game.map == null:
		return
	if recovery_window_timer > 0:
		recovery_window_timer = maxf(0.0, recovery_window_timer - delta)

	var pressure = _compute_pressure()
	var interval_mult = lerpf(1.35, 0.72, pressure)
	var cap_mult = lerpf(0.8, 1.2, pressure)
	if recovery_window_timer > 0:
		interval_mult *= 1.5
		cap_mult *= 0.75

	var diff_spawn_mult = game.get_spawn_rate_multiplier() if game.has_method("get_spawn_rate_multiplier") else 1.0
	var effective_interval = maxf(0.5, (base_spawn_interval * interval_mult) / maxf(diff_spawn_mult, 0.1))
	var effective_cap = maxi(5, int(round(base_global_max_enemies * cap_mult * maxf(diff_spawn_mult, 0.5))))

	var player_x = _get_rightmost_player_x()
	var segments: Array = game.map.level_config.get("segments", [])

	for si in range(segments.size()):
		var seg = segments[si]
		var x_min = float(seg.get("x_min", 0))
		if player_x >= x_min - 100 and not active_segment_indices.has(si):
			active_segment_indices.append(si)
			var zones = seg.get("spawn_zones", [])
			for zi in range(zones.size()):
				var key = "%d_%d" % [si, zi]
				zone_spawn_timers[key] = 0.0
				_try_spawn_in_zone(segments[si], zi, effective_cap, pressure)

	for key in zone_spawn_timers.keys():
		zone_spawn_timers[key] += delta
		if zone_spawn_timers[key] >= effective_interval:
			zone_spawn_timers[key] = 0.0
			var parts = key.split("_")
			if parts.size() >= 2:
				var si = int(parts[0])
				var zi = int(parts[1])
				if si >= 0 and si < segments.size():
					_sustain_zone(segments[si], zi, effective_cap, pressure)

func _compute_pressure() -> float:
	var hp_ratio = float(game.player_node.current_hp) / maxf(float(game.player_node.max_hp), 1.0)
	var health_pressure = 1.0 - clampf(hp_ratio, 0.0, 1.0)

	var now = Time.get_ticks_msec() / 1000.0
	while recent_kill_times.size() > 0 and now - recent_kill_times[0] > 10.0:
		recent_kill_times.remove_at(0)
	var kill_rate = recent_kill_times.size() / 10.0
	var kill_pressure = clampf(kill_rate / 1.5, 0.0, 1.0)

	var near_enemy_count = 0
	for enemy in game.enemy_container.get_children():
		if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
			continue
		if enemy.position.distance_to(game.player_node.position) < 180.0:
			near_enemy_count += 1
	var crowd_pressure = clampf(float(near_enemy_count) / 7.0, 0.0, 1.0)

	var respawn_pressure = 0.0
	if game.checkpoint_manager and game.checkpoint_manager.has_method("get_recent_respawn_pressure"):
		respawn_pressure = game.checkpoint_manager.get_recent_respawn_pressure()

	# High kill speed increases pressure; low HP / crowd / recent respawn reduces it.
	var offense = kill_pressure
	var fatigue = (health_pressure * 0.5) + (crowd_pressure * 0.35) + (respawn_pressure * 0.25)
	return clampf(0.15 + offense * 0.85 - fatigue * 0.7, 0.05, 1.0)

func _get_rightmost_player_x() -> float:
	var x = game.player_node.position.x
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		x = maxf(x, game.player2_node.position.x)
	return x

func _try_spawn_in_zone(seg: Dictionary, zone_idx: int, effective_cap: int, pressure: float):
	var zones = seg.get("spawn_zones", [])
	if zone_idx >= zones.size():
		return
	var zone = zones[zone_idx]
	var trigger_x = float(zone.get("trigger_x", 0))
	if _get_rightmost_player_x() < trigger_x - 50:
		return

	var count = _count_enemies_in_zone(zone)
	var max_c = int(zone.get("max_concurrent", 4))
	var density = float(zone.get("density", 0.5)) * lerpf(0.8, 1.2, pressure)
	if count < max_c * density and game.enemy_container.get_child_count() < effective_cap:
		_spawn_one(zone)

func _sustain_zone(seg: Dictionary, zone_idx: int, effective_cap: int, pressure: float):
	var zones = seg.get("spawn_zones", [])
	if zone_idx >= zones.size():
		return
	var zone = zones[zone_idx]
	var count = _count_enemies_in_zone(zone)
	var max_c = int(zone.get("max_concurrent", 4))
	var density = float(zone.get("density", 0.5)) * lerpf(0.8, 1.2, pressure)
	if count < max_c * density and game.enemy_container.get_child_count() < effective_cap:
		_spawn_one(zone)

func _count_enemies_in_zone(zone: Dictionary) -> int:
	var x_min = float(zone.get("x_min", 0))
	var x_max = float(zone.get("x_max", 100))
	var y_min = float(zone.get("y_min", 0))
	var y_max = float(zone.get("y_max", 720))
	var count = 0
	for enemy in game.enemy_container.get_children():
		if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
			continue
		if enemy.position.x >= x_min and enemy.position.x <= x_max and enemy.position.y >= y_min and enemy.position.y <= y_max:
			count += 1
	return count

func _spawn_one(zone: Dictionary):
	var pool = zone.get("pool", ["complainer"])
	if pool.is_empty():
		pool = ["complainer"]
	var type_name = pool[randi() % pool.size()]

	var stats = EnemyData.get_stats(type_name)
	var enemy = EnemyEntity.new()
	enemy.initialize(type_name, stats)
	enemy.state = EnemyEntity.EnemyState.CHASING
	enemy.chase_target = game.player_node
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		if game.player2_node.position.x > game.player_node.position.x:
			enemy.chase_target = game.player2_node

	var pos: Vector2
	if zone.get("ambush", false):
		# Spawn behind rear player (leftmost) - chase from behind
		var px = game.player_node.position.x
		var py = game.player_node.position.y
		if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
			if game.player2_node.position.x < px:
				px = game.player2_node.position.x
				py = game.player2_node.position.y
		var y_min = float(zone.get("y_min", 300))
		var y_max = float(zone.get("y_max", 420))
		pos = Vector2(maxf(zone.get("x_min", 0), px - 180), clampf(py + randf_range(-80, 80), y_min, y_max))
	else:
		pos = game.map.get_random_spawn_in_zone(zone)
	pos = game.map.resolve_collision(pos, enemy.entity_size)

	# Fix spawn position for sideview mode - place enemy on ground
	if game.map.has_method("get_ground_surface_y"):
		var ground_y = game.map.get_ground_surface_y(pos, enemy.entity_size)
		if ground_y > 0:
			pos.y = ground_y - enemy.entity_size  # Place feet on ground

	enemy.position = pos

	game.enemy_container.add_child(enemy)
