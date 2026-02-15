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
		for enemy in game.enemy_container.get_children():
			if hits >= max_targets:
				break
			if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
				continue
			var dist = p.position.distance_to(enemy.position)
			if dist > p.melee_range:
				continue
			var angle_to_enemy = (enemy.position - p.position).angle()
			var angle_diff = _angle_diff(angle_to_enemy, p.facing_angle)
			if angle_diff < effective_arc / 2.0:
				var dmg = int(p.melee_damage * dmg_mult)
				var is_crit = randf() < p.crit_chance
				if is_crit:
					dmg *= 2
				var hit_dir = (enemy.position - p.position).normalized()
				# Combo-colored particles
				var hit_colors = [Color.WHITE, Color8(100, 200, 255), Color8(255, 120, 50)]
				game.particles.emit_directional(enemy.position.x, enemy.position.y, hit_dir, hit_colors[combo_idx], 5 + combo_idx * 2)
				if is_crit:
					game.particles.emit_burst(enemy.position.x, enemy.position.y, Color.YELLOW, 5)
				enemy.last_damager = p
				enemy.take_damage(dmg, game)
				var dmg_col = Color.YELLOW if is_crit else [Color.WHITE, Color8(100, 200, 255), Color8(255, 120, 50)][combo_idx]
				game.spawn_damage_number(enemy.position, str(dmg) + ("!" if is_crit else ""), dmg_col)
				hits += 1
				if game.sfx:
					game.sfx.play_hit()
		if hits > 0:
			# Stronger shake for later combo hits
			game.start_shake(3.0 + combo_idx * 2.0, 0.08 + combo_idx * 0.04)
			# Micro hitstop for combat feel (subtle, scales with combo)
			game.start_hitstop(0.015 + combo_idx * 0.01)
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
		if proj.source == "player":
			for enemy in game.enemy_container.get_children():
				if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
					continue
				if proj.position.distance_to(enemy.position) < enemy.entity_size + proj.SIZE:
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
			# Check all active players
			var hit_player = false
			for p in active_players:
				if proj.position.distance_to(p.position) < p.BODY_RADIUS + proj.SIZE:
					p.take_damage(proj.damage, game)
					proj.queue_free()
					hit_player = true
					break
			if hit_player:
				continue
			# Check allies
			for ally in game.ally_container.get_children():
				if ally.current_hp <= 0:
					continue
				if proj.position.distance_to(ally.position) < ally.entity_size + proj.SIZE:
					ally.take_damage_ally(proj.damage, game)
					proj.queue_free()
					break

func _check_gold_pickups():
	var active_players = _get_active_players()
	for gold in game.gold_container.get_children():
		var picked = false
		# Magnet pull toward nearest player with magnet
		for p in active_players:
			var dist = p.position.distance_to(gold.position)
			if p.has_magnet and dist < p.magnet_radius and dist > 35:
				var pull_dir = (p.position - gold.position).normalized()
				gold.position += pull_dir * 250.0 * frame_delta
		# Pickup by nearest player
		for p in active_players:
			var dist = p.position.distance_to(gold.position)
			if dist < 35:
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

func _angle_diff(a: float, b: float) -> float:
	var diff = fmod(a - b + PI, TAU)
	if diff < 0:
		diff += TAU
	return abs(diff - PI)
