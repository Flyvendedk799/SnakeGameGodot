class_name CombatSystem
extends Node

var game = null

func setup(game_ref):
	game = game_ref

var frame_delta: float = 0.016

func _get_active_players() -> Array:
	var players = []
	if not game.player_node.is_dead:
		players.append(game.player_node)
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		players.append(game.player2_node)
	return players

func resolve_frame(delta: float = 0.016):
	frame_delta = delta
	_check_player_melee_hits()
	_check_projectile_hits()
	_check_gold_pickups()

func _check_player_melee_hits():
	var players = _get_active_players()
	for p in players:
		if not p.is_attacking_melee or p.melee_hit_done:
			continue
		p.melee_hit_done = true

		# Get combo config for current hit (combo_index was already advanced, so -1)
		var combo_idx = (p.combo_index - 1) % p.COMBO_COUNT if p.combo_window > 0 else 0
		var combo_cfg = p.COMBO_CONFIGS[combo_idx]
		var effective_arc = p.melee_arc * combo_cfg.arc_mult
		var dmg_mult = combo_cfg.damage_mult

		var hits = 0
		# Combo hit 3 (spin) can hit more targets
		var max_targets = p.max_melee_targets + (2 if combo_idx == 2 else 0)
		var range_sq = p.melee_range * p.melee_range
		var candidates = game.get("spatial_grid").get_enemies_near(p.position, p.melee_range) if game.get("spatial_grid") else game.enemy_container.get_children()
		for enemy in candidates:
			if hits >= max_targets:
				break
			if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
				continue
			if p.position.distance_squared_to(enemy.position) > range_sq:
				continue
			# Main Game: melee only hits same-tier enemies
			if game.has_method("can_deal_damage_to") and not game.can_deal_damage_to(p, enemy):
				continue
			var angle_to_enemy = (enemy.position - p.position).angle()
			var angle_diff = _angle_diff(angle_to_enemy, p.facing_angle)
			# Side-view: restrict to front-facing cone (±0.5 rad); top-down: use full arc
			var arc_half = 0.5 if _is_sideview(game) else effective_arc / 2.0
			if angle_diff < arc_half:
				var dmg = int(p.melee_damage * dmg_mult * p.temp_damage_mult)
				var is_crit = randf() < p.crit_chance
				if is_crit:
					dmg *= 2
				var hit_dir = (enemy.position - p.position).normalized()
				# Combo-colored particles
				var hit_colors = [Color.WHITE, Color8(100, 200, 255), Color8(255, 120, 50)]
				game.particles.emit_directional(enemy.position.x, enemy.position.y, hit_dir, hit_colors[combo_idx], 5 + combo_idx * 2)
				if is_crit:
					# Phase 6: Route crit through FX bus
					if game.get("fx_manager"):
						game.fx_manager.emit_melee_crit({"position": enemy.position, "direction": hit_dir})
					else:
						game.particles.emit_burst(enemy.position.x, enemy.position.y, Color.YELLOW, 5)
					p.spawn_impact_ring(enemy.position - p.position, 40.0, Color(1.0, 1.0, 0.0, 0.8), 3.5)
				enemy.last_damager = p
				enemy.take_damage(dmg, game)
				var dmg_col = Color.YELLOW if is_crit else [Color.WHITE, Color8(100, 200, 255), Color8(255, 120, 50)][combo_idx]
				var use_bounce = combo_idx >= 1
				game.spawn_damage_number(enemy.position, str(dmg) + ("!" if is_crit else ""), dmg_col, use_bounce)

				# Combo multiplier display
				if combo_idx > 0 and hits == 1:
					var combo_text = "x%d" % (combo_idx + 1)
					game.spawn_damage_number(enemy.position + Vector2(0, -30), combo_text, Color(1.0, 0.8, 0.0), false)

				hits += 1
				if game.sfx:
					game.sfx.play_hit()
		if hits > 0:
			# AAA Upgrade: Mark hit landed time for attack canceling
			p.last_hit_landed_time = 0.0

			# AAA Upgrade: Spawn combo visual trail
			var hit_pos = p.position + Vector2.from_angle(p.facing_angle) * p.melee_range * 0.7
			p.spawn_combo_visual(combo_idx, hit_pos)

			# Phase 6: Route through Combat Visual Event Bus
			if game.get("fx_manager"):
				var payload = {
					"position": hit_pos,
					"direction": Vector2.from_angle(p.facing_angle),
					"combo_index": combo_idx,
					"intensity": 1.0 + combo_idx * 0.4,
				}
				game.fx_manager.emit_melee_hit(payload)
				if combo_idx == 2:
					game.fx_manager.emit_combo_finisher(payload)
					p.spawn_impact_ring(Vector2.ZERO, 65.0, Color(1.0, 0.3, 0.1, 0.95), 5.0)
			else:
				# Fallback: legacy direct calls
				game.start_shake(3.0 + combo_idx * 2.0, 0.08 + combo_idx * 0.04)
				var hitstop_duration = combo_cfg.get("hitstop", 0.02)
				game.start_hitstop(hitstop_duration, 1.0)
				if combo_idx == 2:
					p.spawn_impact_ring(Vector2.ZERO, 65.0, Color(1.0, 0.3, 0.1, 0.95), 5.0)
					if game.has_method("trigger_camera_zoom_pulse"):
						game.trigger_camera_zoom_pulse(2.8)

			# Lifesteal on melee
			if p.lifesteal > 0 and p.current_hp < p.max_hp:
				var heal = p.lifesteal * hits
				p.heal(heal)

func _check_projectile_hits():
	var active_players = _get_active_players()
	for proj in game.projectile_container.get_children():
		# Skip grenades — they handle their own damage in _explode()
		if proj is GrenadeEntity:
			continue
		# Skip explosion visuals (no source/damage)
		if proj is ExplosionEffect:
			continue
		# Skip companion entities (no source property)
		if proj is HelicopterBombEntity or proj is SupplyDropEntity or proj is CompanionHelicopterEntity:
			continue
		if proj.source == "player":
			var check_radius = 80.0  # Max entity_size + proj.SIZE
			var candidates = game.get("spatial_grid").get_enemies_near(proj.position, check_radius) if game.get("spatial_grid") else game.enemy_container.get_children()
			for enemy in candidates:
				if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
					continue
				var threshold = enemy.entity_size + proj.SIZE
				if proj.position.distance_squared_to(enemy.position) < threshold * threshold:
					if proj.get("owner_player") and is_instance_valid(proj.owner_player):
						enemy.last_damager = proj.owner_player
					enemy.take_damage(proj.damage, game)
					var hit_dir = proj.direction
					game.particles.emit_directional(enemy.position.x, enemy.position.y, hit_dir, Color.WHITE, 5)
					game.start_shake(2.5, 0.08)
					game.spawn_damage_number(enemy.position, str(proj.damage), Color.WHITE)
					# Tiny hitstop on ranged hit for feel
					game.start_hitstop(0.01)
					if game.sfx:
						game.sfx.play_hit()
					# Lifesteal on ranged
					var owner_p = proj.get("owner_player")
					if owner_p and is_instance_valid(owner_p) and owner_p.lifesteal > 0 and owner_p.current_hp < owner_p.max_hp:
						owner_p.heal(owner_p.lifesteal)
					proj.queue_free()
					break
		elif proj.source == "enemy":
			# Check all active players (spatial grid for when many projectiles)
			var hit_player = false
			var player_candidates = game.get("spatial_grid").get_players_near(proj.position, 50.0) if game.get("spatial_grid") else active_players
			for p in player_candidates:
				var thresh = p.BODY_RADIUS + proj.SIZE
				if proj.position.distance_squared_to(p.position) < thresh * thresh:
					p.take_damage(proj.damage, game)
					proj.queue_free()
					hit_player = true
					break
			if hit_player:
				continue
			# Check allies (spatial grid)
			var ally_candidates = game.get("spatial_grid").get_allies_near(proj.position, 50.0) if game.get("spatial_grid") else game.ally_container.get_children()
			for ally in ally_candidates:
				if ally.current_hp <= 0:
					continue
				var thresh = ally.entity_size + proj.SIZE
				if proj.position.distance_squared_to(ally.position) < thresh * thresh:
					ally.take_damage_ally(proj.damage, game)
					proj.queue_free()
					break

func _check_gold_pickups():
	var active_players = _get_active_players()
	var pickup_radius_sq = 35.0 * 35.0
	for gold in game.gold_container.get_children():
		var picked = false
		# Magnet pull toward nearest player with magnet
		for p in active_players:
			var dist_sq = p.position.distance_squared_to(gold.position)
			var magnet_sq = p.magnet_radius * p.magnet_radius
			if p.has_magnet and dist_sq < magnet_sq and dist_sq > pickup_radius_sq:
				var pull_dir = (p.position - gold.position).normalized()
				gold.position += pull_dir * 250.0 * frame_delta
		# Pickup by nearest player
		for p in active_players:
			if p.position.distance_squared_to(gold.position) < pickup_radius_sq:
				var amount = int(gold.amount * p.gold_multiplier)
				game.economy.add_gold(amount, p.player_index)
				if game.sfx:
					game.sfx.play_gold_pickup()
				game.particles.emit_burst(gold.position.x, gold.position.y, Color.GOLD, 6)
				game.spawn_damage_number(gold.position, "+%d" % amount, Color.GOLD)
				gold.queue_free()
				picked = true
				break
		if picked:
			continue

func _is_sideview(game) -> bool:
	return game != null and game.map != null and game.map.has_method("resolve_sideview_collision")

func _angle_diff(a: float, b: float) -> float:
	var diff = fmod(a - b + PI, TAU)
	if diff < 0:
		diff += TAU
	return abs(diff - PI)
