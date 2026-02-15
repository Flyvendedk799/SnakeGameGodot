class_name EnemyEntity
extends Node2D

enum EnemyState { APPROACHING, ATTACKING_BARRICADE, BREACHED, CHASING, ATTACKING, ATTACKING_DOOR, DYING, DEAD }
var state: EnemyState = EnemyState.APPROACHING

# Sprite texture cache (shared across all instances)
static var _tex_cache: Dictionary = {}

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
var chase_target = null
var target_door = null  # DoorEntity reference when attacking a door
var anim_time: float = 0.0
var dying_timer: float = 0.0
var last_dir: Vector2 = Vector2.LEFT
# Kill attribution: PlayerEntity who gets gold/XP (set by combat_system or ally when dealing damage)
var last_damager = null
var nav_waypoint: Vector2 = Vector2.ZERO
var nav_repath_timer: float = 0.0
var stuck_timer: float = 0.0
var last_pos: Vector2 = Vector2.ZERO

# Visual juice (Brotato-style)
var squash_factor: float = 1.0
var squash_velocity: float = 0.0
var knockback_offset: Vector2 = Vector2.ZERO
var trail_history: Array = []
var trail_timer: float = 0.0

func initialize(type: String, stats: Dictionary):
	enemy_type = type
	max_hp = stats.hp
	current_hp = stats.hp
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

func update_enemy(delta: float, game):
	hit_flash_timer = maxf(0, hit_flash_timer - delta)
	attack_timer = maxf(0, attack_timer - delta)
	nav_repath_timer = maxf(0, nav_repath_timer - delta)
	anim_time += delta
	_update_squash(delta)
	_update_trail(delta)
	knockback_offset = knockback_offset.lerp(Vector2.ZERO, delta * 12.0)

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
	position += dir.normalized() * move_speed * delta

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
	# Check for nearby closed doors (inner keep / compartment doors)
	var door = game.map.get_nearest_closed_door(position, 60.0)
	if door:
		target_door = door
		state = EnemyState.ATTACKING_DOOR
		return

	# Build candidate list from all alive players + allies — chase across entire map
	# Prioritize players over allies (enemies are drawn to the main threat)
	var best_target = null
	var best_dist = INF
	var best_priority = 0  # Higher = more attractive target

	if not game.player_node.is_dead:
		var d = position.distance_to(game.player_node.position)
		# Players get priority bonus (enemies prefer attacking players)
		var priority = 3
		# Low-HP player is even more attractive (go for the kill!)
		if game.player_node.current_hp < game.player_node.max_hp * 0.4:
			priority += 1
		if priority > best_priority or (priority == best_priority and d < best_dist):
			best_dist = d
			best_target = game.player_node
			best_priority = priority
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		var d = position.distance_to(game.player2_node.position)
		var priority = 3
		if game.player2_node.current_hp < game.player2_node.max_hp * 0.4:
			priority += 1
		if priority > best_priority or (priority == best_priority and d < best_dist):
			best_dist = d
			best_target = game.player2_node
			best_priority = priority
	for ally in game.ally_container.get_children():
		if ally.current_hp <= 0 or ally.state == AllyEntity.AllyState.DEAD: continue
		var d = position.distance_to(ally.position)
		var priority = 1
		# Nearby allies are more attractive than distant players
		if d < 120.0:
			priority = 2
		if priority > best_priority or (priority == best_priority and d < best_dist):
			best_dist = d
			best_target = ally
			best_priority = priority
	if best_target == null:
		# No valid targets, move toward fort center
		best_target = game.player_node
		best_dist = position.distance_to(game.player_node.position)
	chase_target = best_target
	var attack_range = ranged_range if is_ranged else 28.0
	if best_dist <= attack_range:
		state = EnemyState.ATTACKING
		return
	var chase_point = _resolve_chase_point(best_target.position, game)
	var dir = (chase_point - position)
	if dir.length() > 1:
		last_dir = dir.normalized()
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
	if nav_repath_timer <= 0 or nav_waypoint == Vector2.ZERO or position.distance_to(nav_waypoint) < 22.0:
		nav_waypoint = Vector2.ZERO
		if not game.map.is_line_walkable(position, target_pos, entity_size):
			var best = Vector2.ZERO
			var best_score = INF
			for wp in game.map.get_navigation_waypoints():
				if not game.map.is_line_walkable(position, wp, entity_size):
					continue
				if not game.map.is_line_walkable(wp, target_pos, entity_size):
					continue
				var score = position.distance_to(wp) + wp.distance_to(target_pos)
				if score < best_score:
					best_score = score
					best = wp
			nav_waypoint = best
		nav_repath_timer = 0.25
	return nav_waypoint if nav_waypoint != Vector2.ZERO else target_pos

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
	if drop_loot:
		var credit_player = last_damager if (last_damager and is_instance_valid(last_damager)) else game.player_node
		var gold_mult: float = credit_player.enemy_gold_mult if credit_player else 1.0
		var zone_mult: float = 1.0
		if game.map and game.map.has_method("get_zone_gold_mult"):
			zone_mult = game.map.get_zone_gold_mult(position)
		var direct_gold: int = int(gold_value * gold_mult * zone_mult)
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

# --- Drawing (Brotato-style enhanced) ---

func _draw():
	if state == EnemyState.DEAD: return
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

		# Draw sprite outline (slightly larger, dark)
		var outline_bump = 1.06
		draw_set_transform(
			Vector2(offset_x * dying_scale, sprite_y * dying_scale),
			tilt,
			Vector2(scale_x * flip_sign * dying_scale * outline_bump, scale_y * dying_scale * outline_bump)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(0, 0, 0, 0.5))

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

func _draw_shadow_ellipse(rect: Rect2, col: Color):
	"""Enhanced shadow with dual-layer gradient falloff (optimized)."""
	var center = rect.position + rect.size / 2

	# Layer 1: Outer soft shadow (ambient shadow)
	var outer_points = PackedVector2Array()
	for i in range(12):  # Reduced for performance
		var angle = TAU * i / 12.0
		outer_points.append(center + Vector2(
			cos(angle) * rect.size.x * 0.6,
			sin(angle) * rect.size.y * 0.6
		))
	draw_colored_polygon(outer_points, Color(col.r, col.g, col.b, col.a * 0.25))

	# Layer 2: Inner contact shadow
	var inner_points = PackedVector2Array()
	for i in range(12):
		var angle = TAU * i / 12.0
		inner_points.append(center + Vector2(
			cos(angle) * rect.size.x * 0.4,
			sin(angle) * rect.size.y * 0.4
		))
	draw_colored_polygon(inner_points, col)
