class_name SpawnDirector
extends Node

## Phase 5.1: Per-segment spawn config with intensity_curve pacing
## Phase 6.2: Formation spawning (line / surround / ambush), trigger system, wave mode
## Recovery window extends to 15s. Safe zone 80px around checkpoint = no spawns.

var game = null
var active_segment_indices: Array = []
var zone_spawn_timers: Dictionary = {}
var global_max_enemies: int = 14
var spawn_interval: float = 2.8

var base_global_max_enemies: int = 14
var base_spawn_interval: float = 2.8
var recovery_window_timer: float = 0.0
var recent_kill_times: Array[float] = []

# Phase 6.2: Trigger system — each trigger fires once when player_x >= trigger.x
var _fired_trigger_ids: Dictionary = {}   # trigger_id → true (already fired)

# Phase 6.2: Wave mode — arena segments with N enemies, wait for all dead, next wave
var _wave_active: bool = false
var _wave_segment_idx: int = -1
var _wave_index: int = 0
var _wave_enemies_spawned: Array = []  # Track enemy nodes in current wave

# Phase 5.1: Intensity curve — list of {x_min: float, intensity: float}
# E.g. [{"x_min": 0, "intensity": 0.5}, {"x_min": 1000, "intensity": 1.0}, {"x_min": 2000, "intensity": 1.3}]
var _intensity_curve: Array = []

func setup(game_ref):
	game = game_ref
	active_segment_indices.clear()
	zone_spawn_timers.clear()
	recent_kill_times.clear()
	_fired_trigger_ids.clear()
	_wave_active = false
	_wave_index = 0
	_wave_enemies_spawned.clear()
	recovery_window_timer = 0.0
	base_global_max_enemies = global_max_enemies
	base_spawn_interval = spawn_interval

	# Load intensity curve from level config (supports array or preset string name)
	var raw_curve = game.map.level_config.get("intensity_curve", [])
	if raw_curve is String:
		_intensity_curve = _resolve_intensity_preset(raw_curve,
			float(game.map.level_config.get("width", 2600)))
	else:
		_intensity_curve = raw_curve

func notify_enemy_killed():
	recent_kill_times.append(Time.get_ticks_msec() / 1000.0)
	# Phase 6.2: Check if wave is complete
	if _wave_active:
		_wave_enemies_spawned = _wave_enemies_spawned.filter(func(e): return is_instance_valid(e) and e.state != EnemyEntity.EnemyState.DEAD and e.state != EnemyEntity.EnemyState.DYING)
		if _wave_enemies_spawned.is_empty():
			_advance_wave()

func start_recovery_window(duration: float = 15.0):
	"""Phase 5.1: Extended recovery window — 15s."""
	recovery_window_timer = maxf(recovery_window_timer, duration)

func update(delta: float):
	if game == null or game.map == null:
		return
	if recovery_window_timer > 0:
		recovery_window_timer = maxf(0.0, recovery_window_timer - delta)

	var player_x = _get_rightmost_player_x()

	# Phase 6.2: Check event triggers
	_check_triggers(player_x)

	# Phase 6.2: Wave mode — skip normal spawning while a wave is active
	if _wave_active:
		return

	var pressure = _compute_pressure()
	var curve_intensity = _get_intensity_at(player_x)
	pressure = clampf(pressure * curve_intensity, 0.05, 1.5)

	var interval_mult = lerpf(1.35, 0.72, pressure)
	var cap_mult = lerpf(0.8, 1.2, pressure)
	if recovery_window_timer > 0:
		interval_mult *= 1.5
		cap_mult *= 0.75

	var diff_spawn_mult = game.get_spawn_rate_multiplier() if game.has_method("get_spawn_rate_multiplier") else 1.0
	var effective_interval = maxf(0.5, (base_spawn_interval * interval_mult) / maxf(diff_spawn_mult, 0.1))
	var effective_cap = maxi(5, int(round(base_global_max_enemies * cap_mult * maxf(diff_spawn_mult, 0.5))))

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

# ---------------------------------------------------------------------------
# Phase 5.1: Intensity curve
# ---------------------------------------------------------------------------

func _get_intensity_at(player_x: float) -> float:
	"""Get intensity multiplier from the pacing curve at player_x."""
	if _intensity_curve.is_empty():
		return 1.0
	var best_intensity = _intensity_curve[0].get("intensity", 1.0)
	for entry in _intensity_curve:
		if player_x >= float(entry.get("x_min", 0)):
			best_intensity = float(entry.get("intensity", 1.0))
	return best_intensity

# ---------------------------------------------------------------------------
# Phase 5.1: Safe zone — no spawns within 80px of checkpoint
# ---------------------------------------------------------------------------

func _is_in_safe_zone(pos: Vector2) -> bool:
	"""Returns true if pos is within 80px of a checkpoint."""
	if not game.map.level_config.has("checkpoints"):
		return false
	for cp in game.map.level_config.get("checkpoints", []):
		var cp_x = float(cp.get("x", -9999))
		if absf(pos.x - cp_x) < 80.0:
			return true
	return false

# ---------------------------------------------------------------------------
# Phase 6.2: Trigger system
# ---------------------------------------------------------------------------

func _check_triggers(player_x: float):
	"""Fire one-shot triggers when player reaches their x position."""
	var triggers: Array = game.map.level_config.get("triggers", [])
	for i in range(triggers.size()):
		var trig = triggers[i]
		var tid = trig.get("id", str(i))
		if _fired_trigger_ids.has(tid):
			continue
		if player_x >= float(trig.get("x", INF)):
			_fired_trigger_ids[tid] = true
			_execute_trigger(trig)

func _execute_trigger(trig: Dictionary):
	"""Execute a level trigger event."""
	var event = trig.get("event", "")
	match event:
		"spawn_formation":
			_spawn_formation(trig)
		"start_wave":
			_start_wave(trig)
		"recovery_window":
			start_recovery_window(float(trig.get("duration", 15.0)))
		"spawn_boss":
			_spawn_boss(trig)

# ---------------------------------------------------------------------------
# Phase 6.2: Formation spawning
# ---------------------------------------------------------------------------

func _spawn_formation(trig: Dictionary):
	"""Spawn enemies in a named formation."""
	var formation = trig.get("formation", "line")
	var enemy_types = trig.get("enemies", ["complainer"])
	var center_pos = Vector2(float(trig.get("x", 1200)), float(trig.get("y", 400)))

	match formation:
		"line":
			_spawn_line(enemy_types, center_pos, trig.get("direction", "right"))
		"surround":
			_spawn_surround(enemy_types, center_pos)
		"ambush":
			_spawn_ambush(enemy_types, center_pos)
		_:
			_spawn_line(enemy_types, center_pos, "right")

func _spawn_line(types: Array, center: Vector2, direction: String):
	"""Spawn enemies in a horizontal line."""
	var spacing = 60.0
	var count = types.size()
	for i in range(count):
		var offset_x = (i - count / 2.0) * spacing
		var spawn_x = center.x + (offset_x if direction == "right" else -offset_x)
		var pos = Vector2(spawn_x, center.y)
		_spawn_typed(types[i % types.size()], pos)

func _spawn_surround(types: Array, center: Vector2):
	"""Spawn enemies in a ring around the center."""
	var count = maxi(types.size(), 4)
	var radius = 180.0
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		_spawn_typed(types[i % types.size()], pos)

func _spawn_ambush(types: Array, center: Vector2):
	"""Spawn enemies just off-screen behind the player."""
	var player_x = game.player_node.position.x
	var spawn_x = player_x - 200.0  # Behind player
	for i in range(types.size()):
		var pos = Vector2(spawn_x - i * 50.0, center.y)
		_spawn_typed(types[i % types.size()], pos)

func _spawn_typed(type_name: String, pos: Vector2) -> EnemyEntity:
	if _is_in_safe_zone(pos):
		return null
	var stats = EnemyData.get_stats(type_name)
	var enemy = EnemyEntity.new()
	enemy.initialize(type_name, stats)
	enemy.state = EnemyEntity.EnemyState.CHASING
	enemy.chase_target = game.player_node
	pos = game.map.resolve_collision(pos, enemy.entity_size)
	if game.map.has_method("get_ground_surface_y"):
		var gy = game.map.get_ground_surface_y(pos, enemy.entity_size)
		if gy > 0:
			pos.y = gy - enemy.entity_size
	enemy.position = pos
	game.enemy_container.add_child(enemy)
	return enemy

func _spawn_boss(trig: Dictionary):
	"""Spawn a boss enemy."""
	var type_name = trig.get("boss_type", "boss")
	var spawn_x = float(trig.get("x", 2000))
	var pos = Vector2(spawn_x, float(trig.get("y", 400)))
	var boss = _spawn_typed(type_name, pos)
	if boss and game.get("boss_manager") and game.boss_manager:
		game.boss_manager.register_boss(boss)

# ---------------------------------------------------------------------------
# Phase 6.2: Wave mode
# ---------------------------------------------------------------------------

func _start_wave(trig: Dictionary):
	"""Start arena wave mode for a segment."""
	var waves = trig.get("waves", [])
	if waves.is_empty():
		return
	_wave_active = true
	_wave_index = 0
	_wave_enemies_spawned.clear()
	_wave_segment_idx = trig.get("segment", -1)
	_spawn_wave(waves[_wave_index])
	# Store waves in trigger for advancement
	_current_waves = waves

var _current_waves: Array = []

func _spawn_wave(wave_def: Dictionary):
	"""Spawn all enemies for a wave definition."""
	var types = wave_def.get("enemies", ["complainer"])
	var count = int(wave_def.get("count", types.size()))
	var center = Vector2(float(wave_def.get("x", 1200)), float(wave_def.get("y", 400)))
	_wave_enemies_spawned.clear()
	for i in range(count):
		var t = types[i % types.size()]
		var pos = center + Vector2(randf_range(-150, 150), randf_range(-50, 50))
		var e = _spawn_typed(t, pos)
		if e:
			_wave_enemies_spawned.append(e)

func _advance_wave():
	"""Move to next wave or end wave mode."""
	_wave_index += 1
	if _wave_index < _current_waves.size():
		_spawn_wave(_current_waves[_wave_index])
	else:
		_wave_active = false
		_wave_index = 0
		# Resume normal spawning + grant recovery window
		start_recovery_window(5.0)

# ---------------------------------------------------------------------------
# Existing pressure/zone logic (unchanged + safe zone check added)
# ---------------------------------------------------------------------------

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

	# Phase 5.1: Check safe zone
	if _is_in_safe_zone(pos):
		return

	pos = game.map.resolve_collision(pos, enemy.entity_size)
	if game.map.has_method("get_ground_surface_y"):
		var ground_y = game.map.get_ground_surface_y(pos, enemy.entity_size)
		if ground_y > 0:
			pos.y = ground_y - enemy.entity_size

	enemy.position = pos
	game.enemy_container.add_child(enemy)

# ---------------------------------------------------------------------------
# Phase 5.1: Named intensity curve presets
# ---------------------------------------------------------------------------

func _resolve_intensity_preset(preset_name: String, level_width: float) -> Array:
	"""Convert a string preset name into the [{x_min, intensity}] array format."""
	var w = maxf(level_width, 1000.0)
	match preset_name:
		"steady":
			return [{"x_min": 0, "intensity": 1.0}]
		"escalating":
			return [
				{"x_min": 0,         "intensity": 0.65},
				{"x_min": w * 0.25,  "intensity": 0.85},
				{"x_min": w * 0.50,  "intensity": 1.10},
				{"x_min": w * 0.75,  "intensity": 1.35},
				{"x_min": w * 0.90,  "intensity": 1.50},
			]
		"burst_rest":
			return [
				{"x_min": 0,         "intensity": 0.55},
				{"x_min": w * 0.15,  "intensity": 1.30},
				{"x_min": w * 0.30,  "intensity": 0.40},
				{"x_min": w * 0.45,  "intensity": 1.40},
				{"x_min": w * 0.60,  "intensity": 0.35},
				{"x_min": w * 0.75,  "intensity": 1.50},
				{"x_min": w * 0.90,  "intensity": 0.45},
			]
		"final_boss":
			return [
				{"x_min": 0,         "intensity": 0.75},
				{"x_min": w * 0.40,  "intensity": 1.00},
				{"x_min": w * 0.65,  "intensity": 1.30},
				{"x_min": w * 0.80,  "intensity": 1.60},
				{"x_min": w * 0.92,  "intensity": 1.80},
			]
		_:
			return []  # Fallback: _get_intensity_at returns 1.0 for empty
