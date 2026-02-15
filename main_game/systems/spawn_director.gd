class_name SpawnDirector
extends Node

var game = null
var active_segment_indices: Array = []
var zone_spawn_timers: Dictionary = {}
var global_max_enemies: int = 25
var spawn_interval: float = 2.0

func setup(game_ref):
	game = game_ref
	active_segment_indices.clear()
	zone_spawn_timers.clear()

func update(delta: float):
	if game == null or game.map == null:
		return
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
				_try_spawn_in_zone(segments[si], zi)
	
	for key in zone_spawn_timers.keys():
		zone_spawn_timers[key] += delta
		if zone_spawn_timers[key] >= spawn_interval:
			zone_spawn_timers[key] = 0.0
			var parts = key.split("_")
			if parts.size() >= 2:
				var si = int(parts[0])
				var zi = int(parts[1])
				if si >= 0 and si < segments.size():
					_sustain_zone(segments[si], zi)

func _get_rightmost_player_x() -> float:
	var x = game.player_node.position.x
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		x = maxf(x, game.player2_node.position.x)
	return x

func _try_spawn_in_zone(seg: Dictionary, zone_idx: int):
	var zones = seg.get("spawn_zones", [])
	if zone_idx >= zones.size():
		return
	var zone = zones[zone_idx]
	var trigger_x = float(zone.get("trigger_x", 0))
	if _get_rightmost_player_x() < trigger_x - 50:
		return
	
	var count = _count_enemies_in_zone(zone)
	var max_c = int(zone.get("max_concurrent", 4))
	var density = float(zone.get("density", 0.5))
	if count < max_c * density:
		_spawn_one(zone)

func _sustain_zone(seg: Dictionary, zone_idx: int):
	var zones = seg.get("spawn_zones", [])
	if zone_idx >= zones.size():
		return
	var zone = zones[zone_idx]
	var count = _count_enemies_in_zone(zone)
	var max_c = int(zone.get("max_concurrent", 4))
	var density = float(zone.get("density", 0.5))
	if count < max_c * density and game.enemy_container.get_child_count() < global_max_enemies:
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
	enemy.position = pos
	
	game.enemy_container.add_child(enemy)
