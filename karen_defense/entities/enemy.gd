class_name EnemyEntity
extends Node2D

enum EnemyState { APPROACHING, ATTACKING_BARRICADE, BREACHED, CHASING, ATTACKING, ATTACKING_DOOR, DYING, DEAD }
var state: EnemyState = EnemyState.APPROACHING

# Sprite texture cache (shared across all instances)
static var _tex_cache: Dictionary = {}
# Pathfinding budget: only N enemies can run A* per frame (prevents 1 FPS when many enemies)
static var _pathfind_budget: int = 3

static func _get_texture(sprite_name: String) -> Texture2D:
	if not _tex_cache.has(sprite_name):
		_tex_cache[sprite_name] = load("res://assets/%s.png" % sprite_name)
	return _tex_cache[sprite_name]

# Stats
var enemy_type: String = "complainer"
var max_hp: int = 30
var current_hp: int = 30
var damage: int = 5
var move_speed: float = 55.0
var attack_cooldown: float = 1.0
var gold_value: int = 5
var xp_value: int = 10
var is_ranged: bool = false
var ranged_range: float = 120.0
var is_bomber: bool = false
var is_boss: bool = false
var entity_size: float = 12.0
var color: Color = Color8(255, 130, 170)
var label_short: String = "CK"
var sprite_texture: Texture2D = null

# Runtime
var game = null  # Reference to main game node
var target_entrance: int = -1
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
# Physics for collision
var velocity: Vector2 = Vector2.ZERO
const GRAVITY: float = 600.0
var is_on_ground: bool = false
var pit_check_timer: float = 0.0  # Check for pits periodically
const PIT_CHECK_DISTANCE: float = 25.0  # Look ahead this far
var chase_target = null
var target_door = null  # DoorEntity reference when attacking a door
var anim_time: float = 0.0
var dying_timer: float = 0.0
var last_dir: Vector2 = Vector2.LEFT
# Kill attribution: PlayerEntity who gets gold/XP (set by combat_system or ally when dealing damage)
var last_damager = null
var nav_waypoint: Vector2 = Vector2.ZERO
var nav_repath_timer: float = 0.0
var nav_path: Array[Vector2] = []
var nav_path_index: int = 0
var stuck_timer: float = 0.0
var last_pos: Vector2 = Vector2.ZERO

# Visual juice (Brotato-style)
var squash_factor: float = 1.0
var squash_velocity: float = 0.0
var knockback_offset: Vector2 = Vector2.ZERO
var trail_history: Array = []
var trail_timer: float = 0.0

# AAA Animation upgrade - spawn animation
var spawn_timer: float = 0.0
var spawn_complete: bool = false

# AAA Visual Overhaul: Shader-capable rendering (Main Game only)
var character_visual: CharacterVisual = null
var _use_shader_visual: bool = false

func initialize(type: String, stats: Dictionary):
	enemy_type = type
	max_hp = stats.hp
	current_hp = stats.hp
	# AAA Upgrade: Initialize spawn animation
	var config = AnimationConfig.get_config()
	spawn_timer = config.spawn_duration
	spawn_complete = false
	squash_factor = config.spawn_scale_start
	damage = stats.damage
	move_speed = stats.speed
	gold_value = stats.gold
	xp_value = stats.xp
	color = stats.color
	is_ranged = stats.get("is_ranged", false)
	ranged_range = stats.get("ranged_range", 120.0)
	attack_cooldown = stats.get("attack_cd", 1.0)
	is_bomber = stats.get("is_bomber", false)
	is_boss = stats.get("is_boss", false)
	entity_size = stats.get("size", 12.0)
	label_short = stats.get("short", "K")
	sprite_texture = _get_texture(stats.get("sprite", "enemya"))
	anim_time = randf() * 10.0
	# AAA Visual Overhaul: Setup shader visual for Main Game
	_setup_shader_visual()
	if Engine.get_main_loop() and Engine.get_main_loop().current_scene and Engine.get_main_loop().current_scene.has_method("get_enemy_hp_multiplier"):
		var game_scene = Engine.get_main_loop().current_scene
		var hp_mult = game_scene.get_enemy_hp_multiplier()
		var dmg_mult = game_scene.get_enemy_damage_multiplier()
		max_hp = maxi(1, int(round(max_hp * hp_mult)))
		current_hp = max_hp
		damage = maxi(1, int(round(damage * dmg_mult)))
		if game_scene.challenge_manager:
			move_speed *= game_scene.challenge_manager.get_enemy_speed_mult()

func update_enemy(delta: float, game):
	hit_flash_timer = maxf(0, hit_flash_timer - delta)
	attack_timer = maxf(0, attack_timer - delta)
	nav_repath_timer = maxf(0, nav_repath_timer - delta)
	anim_time += delta
	_update_squash(delta)
	_update_trail(delta)
	knockback_offset = knockback_offset.lerp(Vector2.ZERO, delta * 12.0)

	# AAA Upgrade: Spawn animation
	if not spawn_complete:
		spawn_timer -= delta
		if spawn_timer > 0:
			var config = AnimationConfig.get_config()
			var progress = 1.0 - (spawn_timer / config.spawn_duration)
			var ease_progress = AnimationConfig.apply_ease(progress, AnimationConfig.EaseCurve.EASE_OUT_BACK)
			squash_factor = lerpf(config.spawn_scale_start, 1.0, ease_progress)
			return  # Skip state machine during spawn
		else:
			spawn_complete = true
			squash_factor = 1.0

	match state:
		EnemyState.APPROACHING: _state_approaching(delta, game)
		EnemyState.ATTACKING_BARRICADE: _state_attacking_barricade(delta, game)
		EnemyState.BREACHED: _state_breached(delta, game)
		EnemyState.CHASING: _state_chasing(delta, game)
		EnemyState.ATTACKING: _state_attacking(delta, game)
		EnemyState.ATTACKING_DOOR: _state_attacking_door(delta, game)
		EnemyState.DYING:
			dying_timer -= delta
			if dying_timer <= 0:
				state = EnemyState.DEAD
				queue_free()
				return

	# Fall-to-death: check if enemy fell below level bottom
	var level_bottom = 720.0
	if game.map and game.map.get("level_height"):
		level_bottom = game.map.level_height
	if position.y + entity_size >= level_bottom:
		# Instant death from falling into void
		take_damage(current_hp + 999, game)
		return

	queue_redraw()

func _state_approaching(delta, game):
	if target_entrance == -1:
		target_entrance = game.map.get_nearest_entrance(position)
	var target_pos = game.map.get_entrance_position(target_entrance)
	var dir = (target_pos - position)
	if dir.length() < 15:
		var barricade = game.map.get_barricade(target_entrance)
		if barricade and barricade.is_intact():
			state = EnemyState.ATTACKING_BARRICADE
		else:
			state = EnemyState.BREACHED
		return
	last_dir = dir.normalized()

	# Check for pit ahead before moving
	var should_move = true
	if is_on_ground and _is_pit_ahead(dir.normalized(), game):
		# Stop at edge of pit - don't walk into certain death
		should_move = false
		velocity.x = 0

	# Apply physics: horizontal movement + gravity
	if should_move:
		velocity.x = dir.normalized().x * move_speed
	velocity.y += GRAVITY * delta

	# Apply velocity
	position += velocity * delta

	# Collision detection (only in sideview mode)
	if game.map and game.map.has_method("resolve_sideview_collision"):
		var result = game.map.resolve_sideview_collision(position, velocity, entity_size, false)
		position = result.position
		velocity = result.velocity
		# Check if on ground (vertical velocity stopped)
		is_on_ground = absf(velocity.y) < 10.0 and result.velocity.y == 0

func _state_attacking_barricade(_delta, game):
	var barricade = game.map.get_barricade(target_entrance)
	if not barricade or not barricade.is_intact():
		state = EnemyState.BREACHED
		return
	if is_bomber:
		var _spike = barricade.take_damage(damage)
		if game.sfx: game.sfx.play_barricade_hit()
		game.particles.emit_burst(position.x, position.y, Color8(255, 160, 50), 18)
		die(game, false)
		return
	if attack_timer <= 0:
		var spike_dmg = barricade.take_damage(damage)
		attack_timer = attack_cooldown
		if game.sfx: game.sfx.play_barricade_hit()
		if not barricade.is_intact():
			if game.sfx: game.sfx.play_barricade_break()
			game.particles.emit_burst(barricade.position.x, barricade.position.y, Color8(139, 90, 43), 14)
		if spike_dmg > 0:
			take_damage(spike_dmg, game)

func _state_breached(_delta, _game):
	state = EnemyState.CHASING

func _state_attacking_door(_delta, game):
	if target_door == null or not is_instance_valid(target_door) or not target_door.is_blocking():
		target_door = null
		state = EnemyState.CHASING
		return
	if attack_timer <= 0:
		var opened = target_door.try_enemy_open()
		attack_timer = attack_cooldown
		if opened:
			target_door = null
			state = EnemyState.CHASING
		else:
			# Door is reinforced — show hit effect
			if game.sfx:
				game.sfx.play_barricade_hit()
			game.particles.emit_burst(position.x, position.y, Color8(120, 120, 140), 4)

func _state_chasing(delta, game):
	# Build candidate list from all alive players + allies — chase across entire map
	# Prioritize players over allies (enemies are drawn to the main threat)
	var best_target = null
	var best_dist_sq = INF
	var best_priority = 0  # Higher = more attractive target

	if not game.player_node.is_dead:
		var d_sq = position.distance_squared_to(game.player_node.position)
		var priority = 3
		if game.player_node.current_hp < game.player_node.max_hp * 0.4:
			priority += 1
		if priority > best_priority or (priority == best_priority and d_sq < best_dist_sq):
			best_dist_sq = d_sq
			best_target = game.player_node
			best_priority = priority
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		var d_sq = position.distance_squared_to(game.player2_node.position)
		var priority = 3
		if game.player2_node.current_hp < game.player2_node.max_hp * 0.4:
			priority += 1
		if priority > best_priority or (priority == best_priority and d_sq < best_dist_sq):
			best_dist_sq = d_sq
			best_target = game.player2_node
			best_priority = priority
	var nearby_sq = 120.0 * 120.0
	var ally_candidates = game.get("spatial_grid").get_allies_near(position, 200.0) if game.get("spatial_grid") else game.ally_container.get_children()
	for ally in ally_candidates:
		if ally.current_hp <= 0 or ally.state == AllyEntity.AllyState.DEAD: continue
		var d_sq = position.distance_squared_to(ally.position)
		var priority = 2 if d_sq < nearby_sq else 1
		if priority > best_priority or (priority == best_priority and d_sq < best_dist_sq):
			best_dist_sq = d_sq
			best_target = ally
			best_priority = priority
	if best_target == null:
		best_target = game.player_node
		best_dist_sq = position.distance_squared_to(game.player_node.position)
	chase_target = best_target
	var attack_range = ranged_range if is_ranged else 28.0
	if best_dist_sq <= attack_range * attack_range:
		state = EnemyState.ATTACKING
		return

	# If a blocking door is right in front of us, prioritize forcing it.
	var direct_door = game.map.get_blocking_door_on_line(position, best_target.position, entity_size)
	if direct_door and position.distance_to(direct_door.position) < 70.0:
		target_door = direct_door
		state = EnemyState.ATTACKING_DOOR
		return

	var chase_point = _resolve_chase_point(best_target.position, game)
	var path_door = game.map.get_blocking_door_on_line(position, chase_point, entity_size)
	if path_door and position.distance_to(path_door.position) < 70.0:
		target_door = path_door
		state = EnemyState.ATTACKING_DOOR
		return
	var dir = (chase_point - position)
	if dir.length() > 1:
		last_dir = dir.normalized()

		# Check if sideview mode for proper physics
		if game.map and game.map.has_method("resolve_sideview_collision"):
			# Check for pit ahead before moving
			var should_move = true
			if is_on_ground and _is_pit_ahead(dir.normalized(), game):
				# Stop at edge of pit
				should_move = false
				velocity.x = 0
				stuck_timer += delta  # Mark as stuck to trigger repath

			# Sideview: Use velocity + gravity physics
			if should_move:
				velocity.x = dir.normalized().x * move_speed
			velocity.y += GRAVITY * delta
			position += velocity * delta

			var result = game.map.resolve_sideview_collision(position, velocity, entity_size, false)
			position = result.position
			velocity = result.velocity
			is_on_ground = absf(velocity.y) < 10.0 and result.velocity.y == 0

			if result.position.distance_to(position) < move_speed * delta * 0.2:
				stuck_timer += delta
			else:
				stuck_timer = 0.0
		else:
			# Top-down: Use simple collision
			var desired_pos = position + dir.normalized() * move_speed * delta
			var resolved_pos = game.map.resolve_collision(desired_pos, entity_size)
			if resolved_pos.distance_to(position) < move_speed * delta * 0.2:
				stuck_timer += delta
			else:
				stuck_timer = 0.0
			position = resolved_pos
		if stuck_timer > 0.35:
			nav_repath_timer = 0.0
			stuck_timer = 0.0

func _resolve_chase_point(target_pos: Vector2, game) -> Vector2:
	# Main Game (LinearMap): side-scroll levels - skip A*, chase directly (huge perf win)
	if game.map.has_method("resolve_sideview_collision"):
		return target_pos
	if nav_repath_timer <= 0 or nav_path.is_empty():
		# Only N enemies can pathfind per frame to prevent freeze (Karen Defense fort)
		if _pathfind_budget > 0:
			_pathfind_budget -= 1
			_build_nav_path(target_pos, game)
		# Repath less often when many enemies (reduces A* load during waves)
		var enemy_count = game.enemy_container.get_child_count()
		nav_repath_timer = 0.7 if enemy_count > 15 else 0.5
	if not nav_path.is_empty():
		if nav_path_index < nav_path.size() and position.distance_to(nav_path[nav_path_index]) < 24.0:
			nav_path_index += 1
		if nav_path_index < nav_path.size():
			nav_waypoint = nav_path[nav_path_index]
			return nav_waypoint
		nav_path.clear()
		nav_path_index = 0
	return target_pos

func _build_nav_path(target_pos: Vector2, game):
	nav_path.clear()
	nav_path_index = 0
	if game.map.is_line_walkable_static(position, target_pos, entity_size):
		return
	var points = game.map.get_navigation_waypoints()
	points.append(position)
	var start_idx = points.size() - 1
	points.append(target_pos)
	var goal_idx = points.size() - 1
	var g_score: Dictionary = {start_idx: 0.0}
	var f_score: Dictionary = {start_idx: position.distance_to(target_pos)}
	var came_from: Dictionary = {}
	var open: Array[int] = [start_idx]

	while not open.is_empty():
		var current = open[0]
		var current_f = f_score.get(current, INF)
		for idx in open:
			var cand_f = f_score.get(idx, INF)
			if cand_f < current_f:
				current_f = cand_f
				current = idx
		if current == goal_idx:
			_reconstruct_nav_path(came_from, points, goal_idx)
			return
		open.erase(current)
		for neighbor in range(points.size()):
			if neighbor == current:
				continue
			if not game.map.is_line_walkable_static(points[current], points[neighbor], entity_size):
				continue
			var tentative_g = g_score.get(current, INF) + points[current].distance_to(points[neighbor])
			if tentative_g >= g_score.get(neighbor, INF):
				continue
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g
			f_score[neighbor] = tentative_g + points[neighbor].distance_to(points[goal_idx])
			if not open.has(neighbor):
				open.append(neighbor)

func _reconstruct_nav_path(came_from: Dictionary, points: Array, goal_idx: int):
	var path_idxs: Array[int] = [goal_idx]
	var cur = goal_idx
	while came_from.has(cur):
		cur = came_from[cur]
		path_idxs.push_front(cur)
	nav_path.clear()
	for idx in path_idxs:
		nav_path.append(points[idx])
	if not nav_path.is_empty() and position.distance_to(nav_path[0]) < 8.0:
		nav_path.remove_at(0)

func _state_attacking(_delta, game):
	if chase_target == null or (chase_target is AllyEntity and chase_target.current_hp <= 0):
		state = EnemyState.CHASING
		return
	var dist = position.distance_to(chase_target.position)
	var attack_range = ranged_range if is_ranged else 28.0
	if dist > attack_range + 20:
		state = EnemyState.CHASING
		return
	if attack_timer <= 0:
		if is_ranged:
			_fire_ranged(game)
		else:
			_do_melee(game)
		attack_timer = attack_cooldown

func _do_melee(game):
	# Small lunge toward target on attack (makes combat feel aggressive)
	if chase_target and is_instance_valid(chase_target):
		var lunge_dir = (chase_target.position - position).normalized()
		var lunge_dist = 6.0
		position += lunge_dir * lunge_dist
		position = game.map.resolve_collision(position, entity_size)
	squash_factor = 1.3  # Attack squash
	if chase_target is PlayerEntity:
		chase_target.take_damage(damage, game)
		game.spawn_damage_number(chase_target.position, str(damage), Color8(255, 80, 80))
	elif chase_target is AllyEntity:
		chase_target.take_damage_ally(damage, game)
		game.spawn_damage_number(chase_target.position, str(damage), Color8(255, 80, 80))

func _fire_ranged(game):
	var proj = ProjectileEntity.new()
	proj.position = position
	proj.direction = (chase_target.position - position).normalized()
	proj.damage = damage
	proj.source = "enemy"
	proj.proj_speed = 220.0
	game.projectile_container.add_child(proj)

func _is_pit_ahead(direction: Vector2, game) -> bool:
	"""Check if there's a pit/drop-off ahead in the given direction."""
	if not game.map or not game.map.has_method("get_ground_surface_y"):
		return false  # Only check in sideview mode

	# Check a point ahead in movement direction
	var check_pos = position + direction.normalized() * PIT_CHECK_DISTANCE
	var ground_y = game.map.get_ground_surface_y(check_pos, entity_size)

	# If no ground found, or ground is much lower than current position, it's a pit
	if ground_y <= 0:
		return true  # No ground = pit

	var ground_drop = ground_y - position.y
	if ground_drop > entity_size * 3:  # Drop more than 3x entity height = pit
		return true

	return false

func take_damage(amount: int, game):
	current_hp -= amount
	hit_flash_timer = 0.1
	squash_factor = 0.6
	# Visual knockback from damage source
	if last_damager and is_instance_valid(last_damager):
		knockback_offset = (position - last_damager.position).normalized() * 8.0
	if current_hp <= 0:
		die(game)

func die(game, drop_loot: bool = true):
	# Prevent double-death (already dying or dead)
	if state == EnemyState.DYING or state == EnemyState.DEAD:
		return

	if drop_loot:
		var credit_player = last_damager if (last_damager and is_instance_valid(last_damager)) else game.player_node
		var gold_mult: float = credit_player.enemy_gold_mult if credit_player else 1.0
		var zone_mult: float = 1.0
		if game.map and game.map.has_method("get_zone_gold_mult"):
			zone_mult = game.map.get_zone_gold_mult(position)
		var run_gold_mult = game.get_gold_multiplier() if game.has_method("get_gold_multiplier") else 1.0
		var direct_gold: int = int(gold_value * gold_mult * zone_mult * run_gold_mult)
		var credit_index: int = 0
		if credit_player and credit_player == game.player2_node:
			credit_index = 1
		# Always give direct gold to the killing player
		game.economy.add_gold(direct_gold, credit_index)
		game.spawn_damage_number(position, "+%d" % direct_gold, Color.GOLD)
		# Ground drop only 20% of the time
		if randf() < 0.20:
			var gold = GoldDrop.new()
			gold.position = position
			gold.amount = int(direct_gold)
			gold.player_index_hint = credit_index
			game.gold_container.add_child(gold)
		game.progression.add_xp_for_player(credit_index, xp_value)
		game.enemies_killed_total += 1
		if game.has_method("on_enemy_killed"):
			game.on_enemy_killed()
		# Lifesteal for all alive players
		if not game.player_node.is_dead and game.player_node.lifesteal > 0:
			game.player_node.heal(game.player_node.lifesteal)
		if game.p2_joined and game.player2_node and not game.player2_node.is_dead and game.player2_node.lifesteal > 0:
			game.player2_node.heal(game.player2_node.lifesteal)
	game.particles.emit_death_burst(position.x, position.y, color)
	if game.sfx: game.sfx.play_enemy_death()
	# Chromatic aberration on death
	if is_boss:
		game.start_chromatic(6.0)
	state = EnemyState.DYING
	dying_timer = 0.3
	# AAA Visual Overhaul: Start dissolve shader on death
	if _use_shader_visual and character_visual:
		character_visual.start_dissolve(0.3, color)

# --- Visual juice helpers ---

func _update_squash(delta: float):
	var force = (1.0 - squash_factor) * 180.0
	squash_velocity += force * delta
	squash_velocity *= exp(-12.0 * delta)
	squash_factor += squash_velocity * delta

func _update_trail(delta: float):
	trail_timer += delta
	var is_active = (state == EnemyState.APPROACHING or state == EnemyState.CHASING) and sprite_texture != null
	if is_active and trail_timer >= 0.04:
		trail_timer = 0.0
		trail_history.push_front({"pos": position, "alpha": 0.3})
		if trail_history.size() > 3:
			trail_history.pop_back()
	var i = trail_history.size() - 1
	while i >= 0:
		trail_history[i].alpha -= delta * 3.5
		if trail_history[i].alpha <= 0.0:
			trail_history.remove_at(i)
		i -= 1

func _setup_shader_visual():
	"""AAA Visual Overhaul: Create CharacterVisual for shader rendering in Main Game."""
	# Check if we're in sideview Main Game
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if scene and scene.get("is_sideview_game") and scene.is_sideview_game and sprite_texture:
		_use_shader_visual = true
		character_visual = CharacterVisual.new()
		character_visual.name = "Visual"
		add_child(character_visual)
		var theme = "grass"
		if scene.get("map") and scene.map.get("level_config"):
			theme = scene.map.level_config.get("theme", "grass")
		character_visual.setup(sprite_texture, {
			"outline_width": 1.8 if is_boss else 1.5,
			"outline_color": CartoonPalette.get_outline_color(theme),
			"tint": color,
		})
		character_visual.set_theme_lighting(theme)
		# Dissolve color matches enemy color
		if character_visual.dissolve_material:
			character_visual.dissolve_material.set_shader_parameter("dissolve_color", color)

# --- Drawing (Brotato-style enhanced) ---

func _draw():
	if state == EnemyState.DEAD: return
	# Viewport culling: skip expensive draw when off-screen (shadow, sprite, trail, etc.)
	if game and game.has_method("get_visible_world_rect"):
		var vis = game.get_visible_world_rect()
		if not vis.has_point(position):
			return  # Fully cull - nothing to draw when off-screen

	# AAA Visual Overhaul: Update shader visual if active
	if _use_shader_visual and character_visual:
		_update_shader_visual()
		# EARLY RETURN - CharacterVisual handles all rendering
		return

	var dying_scale = 1.0
	if state == EnemyState.DYING:
		var t = dying_timer / 0.3
		modulate.a = t
		dying_scale = 0.3 + 0.7 * t
		draw_set_transform(Vector2.ZERO, 0, Vector2(dying_scale, dying_scale))
	var flash = hit_flash_timer > 0
	var s = entity_size
	var kb = knockback_offset

	# Enhanced shadow with depth-based scaling and directional offset
	var shadow_pulse = 1.0
	if state == EnemyState.APPROACHING or state == EnemyState.CHASING:
		shadow_pulse = 1.0 + abs(sin(anim_time * 8.0)) * 0.15

	# Apply depth scaling to shadow
	var shadow_depth_scale = 1.0
	var shadow_offset_x = 0.0
	var shadow_alpha = 0.38
	if game and game.is_sideview_game:
		shadow_depth_scale = DepthPlanes.get_scale_for_y(position.y)
		# Directional shadow: offset based on depth
		var y_factor = (position.y - 280.0) / 300.0
		shadow_offset_x = y_factor * 5.0
		shadow_alpha = clampf(0.32 + y_factor * 0.12, 0.22, 0.42)

	var shadow_w = s * 2.8 * shadow_pulse * shadow_depth_scale
	var shadow_h = s * 1.0 * shadow_pulse * shadow_depth_scale
	var shadow_y_off = s * 0.7 + 8.0
	_draw_shadow_ellipse(
		Rect2(kb.x - shadow_w / 2 + shadow_offset_x, shadow_y_off - shadow_h / 2 + kb.y, shadow_w, shadow_h),
		Color(0, 0, 0, shadow_alpha)
	)

	# Boss aura (behind sprite)
	if is_boss:
		var aura_alpha = 0.12 + 0.06 * sin(anim_time * 4.0)
		draw_circle(kb, s + 8, Color(1, 0.2, 0.3, aura_alpha))

	# Sprite with animation
	if sprite_texture:
		var tex_size = sprite_texture.get_size()
		var target_h = s * 4.5
		var base_scale = target_h / tex_size.y

		var offset_x = kb.x
		var offset_y = kb.y
		var tilt = 0.0
		var scale_x = base_scale
		var scale_y = base_scale
		var flip_sign = -1.0 if last_dir.x > 0 else 1.0

		if state == EnemyState.APPROACHING or state == EnemyState.CHASING:
			# Walking: amplified bob + lean + squash/stretch (2x+)
			offset_y += abs(sin(anim_time * 8.0)) * -7.0
			tilt = sin(anim_time * 8.0) * 0.12
			scale_x = base_scale * (1.0 + cos(anim_time * 8.0) * 0.07)
			scale_y = base_scale * (1.0 - cos(anim_time * 8.0) * 0.07)
		elif state == EnemyState.ATTACKING or state == EnemyState.ATTACKING_BARRICADE:
			# Attack: amplified lunge + squash
			var attack_ratio = attack_timer / attack_cooldown if attack_cooldown > 0 else 0.0
			if attack_ratio > 0.75:
				var punch = sin((1.0 - attack_ratio) / 0.25 * PI)
				var lunge_dir = last_dir
				if chase_target and is_instance_valid(chase_target):
					lunge_dir = (chase_target.position - position).normalized()
				offset_x += lunge_dir.x * punch * 12.0
				offset_y += lunge_dir.y * punch * 12.0 - abs(punch) * 4.0
				scale_x = base_scale * (1.0 + punch * 0.15)
				scale_y = base_scale * (1.0 - punch * 0.12)
			else:
				var breath = sin(anim_time * 3.0)
				scale_y = base_scale * (1.0 + breath * 0.04)
				scale_x = base_scale * (1.0 - breath * 0.025)
		else:
			# Idle: amplified breathing
			var breath = sin(anim_time * 2.5)
			scale_y = base_scale * (1.0 + breath * 0.04)
			scale_x = base_scale * (1.0 - breath * 0.025)

		# Apply perspective depth scaling
		if game and game.is_sideview_game:
			var depth_scale = DepthPlanes.get_scale_for_y(position.y)
			# Add slight vertical squash for perspective
			var y_factor = clampf((position.y - 280.0) / 300.0, -0.3, 0.3)
			var perspective_squash = 1.0 - abs(y_factor) * 0.08
			scale_x *= depth_scale
			scale_y *= depth_scale * perspective_squash

		# Apply spring squash factor
		scale_y *= squash_factor
		scale_x *= (2.0 - squash_factor)

		var sprite_y = -target_h * 0.15 + offset_y

		# Draw afterimage trails
		if state != EnemyState.DYING:
			for trail in trail_history:
				var trail_offset = trail.pos - position
				draw_set_transform(
					Vector2(trail_offset.x + offset_x, trail_offset.y + sprite_y) * dying_scale,
					tilt,
					Vector2(scale_x * flip_sign * dying_scale, scale_y * dying_scale)
				)
				draw_texture(sprite_texture, -tex_size / 2.0, Color(color.r, color.g, color.b, trail.alpha))

		# CARTOON: Bold outline + rim lighting (match player style)
		var outline_scale = 1.12
		draw_set_transform(
			Vector2(offset_x * dying_scale, sprite_y * dying_scale),
			tilt,
			Vector2(scale_x * flip_sign * dying_scale * outline_scale, scale_y * dying_scale * outline_scale)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(0.08, 0.05, 0.15, 0.6))
		var inner_outline = 1.05
		draw_set_transform(
			Vector2(offset_x * dying_scale, sprite_y * dying_scale),
			tilt,
			Vector2(scale_x * flip_sign * dying_scale * inner_outline, scale_y * dying_scale * inner_outline)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(0.02, 0.01, 0.08, 0.9))
		# Rim light
		var rim_offset = Vector2(-flip_sign * 2.5, -3.0)
		var rim_scale = 1.04
		draw_set_transform(
			Vector2((offset_x + rim_offset.x) * dying_scale, (sprite_y + rim_offset.y) * dying_scale),
			tilt,
			Vector2(scale_x * flip_sign * dying_scale * rim_scale, scale_y * dying_scale * rim_scale)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(1.0, 0.95, 0.9, 0.4))

		# Draw main sprite
		draw_set_transform(
			Vector2(offset_x * dying_scale, sprite_y * dying_scale),
			tilt,
			Vector2(scale_x * flip_sign * dying_scale, scale_y * dying_scale)
		)
		if flash:
			draw_texture(sprite_texture, -tex_size / 2.0, Color(4.0, 4.0, 4.0, 1.0))
		else:
			draw_texture(sprite_texture, -tex_size / 2.0)

		# Restore transform
		if state == EnemyState.DYING:
			draw_set_transform(Vector2.ZERO, 0, Vector2(dying_scale, dying_scale))
		else:
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Boss crown (on top of sprite)
	if is_boss:
		var crown_y = -s * 3.0 - 6 + kb.y
		var cx = kb.x
		draw_colored_polygon(PackedVector2Array([
			Vector2(-14 + cx, crown_y), Vector2(-11 + cx, crown_y - 16), Vector2(-4 + cx, crown_y - 7),
			Vector2(cx, crown_y - 19), Vector2(4 + cx, crown_y - 7),
			Vector2(11 + cx, crown_y - 16), Vector2(14 + cx, crown_y)
		]), Color.GOLD)

	# Bomber fuse
	if is_bomber:
		var fuse_glow = 0.5 + 0.5 * sin(anim_time * 8.0)
		draw_circle(Vector2(kb.x, -s * 2.25 - 4 + kb.y), 4, Color(1, fuse_glow, 0))
		draw_line(Vector2(kb.x, -s * 2.25 + kb.y), Vector2(kb.x, -s * 2.25 - 4 + kb.y), Color8(80, 60, 40), 2.0)

	# HP bar (stays at entity anchor for visual separation on knockback)
	var bar_w = s * 2.0 + 16
	var hp_ratio = float(current_hp) / float(max_hp)
	var bar_y = -s * 3.0 - 10
	var bar_alpha = 200 if current_hp < max_hp else 80
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 8), Color8(40, 0, 0, bar_alpha))
	var hp_col = Color8(220, 50, 50) if hp_ratio < 0.3 else Color8(220, 180, 50) if hp_ratio < 0.6 else Color8(50, 200, 50)
	hp_col.a = bar_alpha / 255.0
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, 8), hp_col)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 8), Color8(200, 150, 150, bar_alpha / 3), false, 1.0)

	# Label
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(-s, s + 18), label_short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	if state == EnemyState.DYING:
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _update_shader_visual():
	"""AAA Visual Overhaul: Update CharacterVisual transforms and effects."""
	if not character_visual:
		return

	var delta = get_process_delta_time()
	character_visual.update_visual(delta)

	# Flash on hit
	if hit_flash_timer > 0 and not character_visual.is_dissolving:
		if character_visual.flash_timer <= 0:
			character_visual.trigger_flash(0.1)

	# Calculate visual scale (same logic as procedural _draw)
	var s = entity_size
	var target_h = s * 4.5
	var tex_size = sprite_texture.get_size() if sprite_texture else Vector2(64, 64)
	var base_scale = target_h / tex_size.y
	var scale_x = base_scale
	var scale_y = base_scale

	# Apply squash
	scale_y *= squash_factor
	scale_x *= (2.0 - squash_factor)

	# Depth scaling
	if game and game.is_sideview_game:
		var depth_scale = DepthPlanes.get_scale_for_y(position.y)
		var y_factor = clampf((position.y - 280.0) / 300.0, -0.3, 0.3)
		var perspective_squash = 1.0 - abs(y_factor) * 0.08
		scale_x *= depth_scale
		scale_y *= depth_scale * perspective_squash

	var flip_h = last_dir.x > 0
	var flip_sign = -1.0 if flip_h else 1.0

	character_visual.update_transform(flip_h, Vector2(scale_x * flip_sign, scale_y))

	# Position the visual at the sprite offset
	var sprite_y = -target_h * 0.15 + knockback_offset.y
	character_visual.position = Vector2(knockback_offset.x, sprite_y)

func _draw_shadow_soft(body_radius: float, depth_y: float, pulse: float = 1.0, offset_x: float = 0.0, offset_y: float = 26.0):
	"""CARTOON: Strong contact shadow for weight and grounding."""
	var shadow_alpha = DepthPlanes.get_shadow_alpha_for_y(depth_y)
	var shadow_scale = DepthPlanes.get_shadow_scale_for_y(depth_y)
	var shadow_offset = Vector2(offset_x, offset_y)
	var core_radius_x = body_radius * shadow_scale * pulse * 0.85
	var core_radius_y = core_radius_x * 0.4
	var contact_alpha = minf(0.85, shadow_alpha * 1.4)
	var core_points = PackedVector2Array()
	for j in range(16):
		var angle = float(j) / 16.0 * TAU
		var px = shadow_offset.x + cos(angle) * core_radius_x
		var py = shadow_offset.y + sin(angle) * core_radius_y
		core_points.append(Vector2(px, py))
	draw_polygon(core_points, PackedColorArray([Color(0.05, 0.05, 0.12, contact_alpha)]))
	for i in range(2):
		var layer_t = float(i + 1) / 3.0
		var radius_x = core_radius_x * (1.0 + layer_t * 0.5)
		var radius_y = core_radius_y * (1.0 + layer_t * 0.5)
		var alpha = shadow_alpha * 0.4 * (1.0 - layer_t)
		var points = PackedVector2Array()
		for j in range(12):
			var angle = float(j) / 12.0 * TAU
			var px = shadow_offset.x + cos(angle) * radius_x
			var py = shadow_offset.y + sin(angle) * radius_y
			points.append(Vector2(px, py))
		draw_polygon(points, PackedColorArray([Color(0.08, 0.06, 0.15, alpha)]))

func _draw_shadow_ellipse(rect: Rect2, col: Color):
	"""Legacy shadow function - redirects to soft shadow for backward compatibility."""
	var center_x = rect.position.x + rect.size.x / 2.0
	var center_y = rect.position.y + rect.size.y / 2.0
	var body_radius = rect.size.x / 2.0
	_draw_shadow_soft(body_radius, position.y, 1.0, center_x, center_y)
