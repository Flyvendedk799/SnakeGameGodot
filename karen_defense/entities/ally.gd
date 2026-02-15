class_name AllyEntity
extends Node2D

enum AllyState { IDLE, ENGAGING, ATTACKING, REGROUPING, DEAD }
var state: AllyState = AllyState.IDLE

# Stats
var ally_type: String = "chill_dude"
var max_hp: int = 80
var current_hp: int = 80
var damage: int = 8
var move_speed: float = 55.0
var attack_cooldown: float = 1.0
var is_ranged: bool = false
var ranged_range: float = 160.0
var detect_range: float = 150.0
var entity_size: float = 12.0
var color: Color = Color8(100, 160, 220)
var label_short: String = "CD"

# Sprite & weapon
var sprite_texture: Texture2D = null
var weapon_texture: Texture2D = null
var weapon_config: Dictionary = {}

# Anchor points on ally sprite (offset from texture center, in texture pixels)
const SPRITE_ANCHORS = {
	"right_hand": Vector2(15, -9),
	"left_hand": Vector2(-12, 12),
}

# Runtime
var target_enemy: EnemyEntity = null
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var rally_point: Vector2 = Vector2.ZERO
var damage_multiplier: float = 1.0
var anim_time: float = 0.0
var last_dir: Vector2 = Vector2.RIGHT
var owner_player_index: int = 0  # 0 = P1, 1 = P2 (for kill credit)
var is_outside_ally: bool = false  # placed outside barrier, does not count toward unit cap
var collects_gold: bool = false
var collect_radius: float = 40.0
var target_gold = null  # GoldDrop reference when collecting

# Visual juice (Brotato-style)
var squash_factor: float = 1.0
var squash_velocity: float = 0.0
var trail_history: Array = []
var trail_timer: float = 0.0

func initialize(type: String, stats: Dictionary):
	ally_type = type
	max_hp = stats.hp
	current_hp = stats.hp
	damage = stats.damage
	move_speed = stats.speed
	attack_cooldown = stats.get("attack_cd", 1.0)
	is_ranged = stats.get("is_ranged", false)
	ranged_range = stats.get("ranged_range", 160.0)
	detect_range = stats.get("detect_range", 150.0)
	entity_size = stats.get("size", 12.0)
	color = stats.color
	label_short = stats.get("short", "A")
	anim_time = randf() * 10.0
	collects_gold = stats.get("collects_gold", false)
	collect_radius = stats.get("collect_radius", 40.0)
	var sprite_name = stats.get("sprite", "")
	if sprite_name != "":
		sprite_texture = load("res://assets/%s.png" % sprite_name)
	var wep = stats.get("weapon", {})
	if not wep.is_empty():
		weapon_texture = load("res://assets/%s.png" % wep.sprite)
		weapon_config = wep

func update_ally(delta: float, game):
	if current_hp <= 0:
		return
	hit_flash_timer = maxf(0, hit_flash_timer - delta)
	attack_timer = maxf(0, attack_timer - delta)
	anim_time += delta
	_update_squash(delta)
	_update_trail(delta)
	if collects_gold:
		_update_coin_collector(delta, game)
		queue_redraw()
		return
	# Combine ally_damage_mult from both players (global buff stacks)
	var mult = game.player_node.ally_damage_multiplier
	if game.p2_joined and game.player2_node:
		mult *= game.player2_node.ally_damage_multiplier
	damage_multiplier = mult
	match state:
		AllyState.IDLE:
			_state_idle(delta, game)
		AllyState.ENGAGING:
			_state_engaging(delta, game)
		AllyState.ATTACKING:
			_state_attacking(delta, game)
		AllyState.REGROUPING:
			_state_regrouping(delta, game)

	queue_redraw()

func _state_idle(_delta, game):
	# Actively seek nearest enemy (no range cap in idle) so allies move toward enemies instead of waiting
	target_enemy = _find_nearest_enemy_any_distance(game)
	if target_enemy:
		state = AllyState.ENGAGING

func _state_engaging(delta, game):
	if not _is_valid_target(target_enemy):
		target_enemy = _find_best_enemy(game)
		if not target_enemy:
			state = AllyState.IDLE
			return

	# Re-evaluate target periodically — switch to higher-priority threats
	if fmod(anim_time, 1.5) < delta:
		var better = _find_best_enemy(game)
		if better and better != target_enemy:
			target_enemy = better

	# Open closed doors when nearby (allies can open but not close)
	var door = game.map.get_nearest_closed_door(position, 50.0)
	if door:
		door.try_ally_open()

	var dist = position.distance_to(target_enemy.position)
	var attack_range = ranged_range if is_ranged else 25.0

	if dist <= attack_range:
		state = AllyState.ATTACKING
		return

	var dir = (target_enemy.position - position).normalized()
	last_dir = dir
	position += dir * move_speed * delta
	# Collide with maze walls, keep walls, doors etc.
	position = game.map.resolve_collision(position, entity_size)
	# Avoid clumping with other allies
	_apply_separation(delta, game)

func _state_attacking(delta, game):
	if not _is_valid_target(target_enemy):
		target_enemy = _find_best_enemy(game)
		if not target_enemy:
			state = AllyState.IDLE
			return
		state = AllyState.ENGAGING
		return

	var dist = position.distance_to(target_enemy.position)
	var attack_range = ranged_range if is_ranged else 25.0
	var dir_to_target = (target_enemy.position - position)
	if dir_to_target.length() > 1:
		last_dir = dir_to_target.normalized()

	# Ranged units back up if enemy gets too close
	if is_ranged and dist < 40.0:
		var away = (position - target_enemy.position).normalized()
		position += away * move_speed * 0.7 * delta

	if dist > attack_range + 15:
		state = AllyState.ENGAGING
		return

	if attack_timer <= 0:
		var credit_player = _get_owner_player(game)
		if credit_player:
			target_enemy.last_damager = credit_player
		var dmg = int(damage * damage_multiplier)
		if is_ranged:
			var proj = ProjectileEntity.new()
			proj.position = position
			proj.direction = (target_enemy.position - position).normalized()
			proj.damage = dmg
			proj.source = "player"
			proj.owner_player = credit_player
			proj.proj_speed = 300.0
			game.projectile_container.add_child(proj)
		else:
			target_enemy.take_damage(dmg, game)
		attack_timer = attack_cooldown

	_apply_separation(delta, game)

func _state_regrouping(delta, game):
	var dist = position.distance_to(rally_point)
	if dist < 15:
		state = AllyState.IDLE
		return
	# Open closed doors when nearby
	var door = game.map.get_nearest_closed_door(position, 50.0)
	if door:
		door.try_ally_open()
	var dir = (rally_point - position).normalized()
	last_dir = dir
	position += dir * move_speed * delta
	# Collide with maze walls, keep walls, doors etc.
	position = game.map.resolve_collision(position, entity_size)

func regroup(point: Vector2):
	rally_point = point
	state = AllyState.REGROUPING

func _get_owner_player(game):
	if owner_player_index == 1 and game.p2_joined and game.player2_node and is_instance_valid(game.player2_node):
		return game.player2_node
	return game.player_node

func _update_coin_collector(delta: float, game):
	if target_gold and not is_instance_valid(target_gold):
		target_gold = null
	if target_gold == null:
		target_gold = _find_nearest_gold(game)
	if target_gold == null:
		last_dir = Vector2.RIGHT
		return
	var dist = position.distance_to(target_gold.position)
	if dist <= collect_radius:
		var amount = target_gold.amount
		game.economy.add_gold(amount, target_gold.player_index_hint)
		if game.sfx:
			game.sfx.play_gold_pickup()
		game.particles.emit_burst(target_gold.position.x, target_gold.position.y, Color.GOLD, 6)
		target_gold.queue_free()
		target_gold = null
		return
	var dir = (target_gold.position - position).normalized()
	last_dir = dir
	position += dir * move_speed * delta
	position.x = clampf(position.x, 20, game.map.SCREEN_W - 20)
	position.y = clampf(position.y, 20, game.map.SCREEN_H - 20)
	position = game.map.resolve_collision(position, entity_size)

func _find_nearest_gold(game):
	var best = null
	var best_dist = INF
	for gold in game.gold_container.get_children():
		if not is_instance_valid(gold):
			continue
		var d = position.distance_to(gold.position)
		if d < best_dist:
			best_dist = d
			best = gold
	return best

func _is_valid_target(enemy) -> bool:
	return is_instance_valid(enemy) and enemy.state != EnemyEntity.EnemyState.DEAD and enemy.state != EnemyEntity.EnemyState.DYING

const MAX_SEEK_DISTANCE: float = 700.0  # cap so normal allies don't run too far from fort
const OUTSIDE_ALLY_SEEK_RANGE: float = 550.0  # Gate Guard etc. seek within this range from themselves

func _find_nearest_enemy_any_distance(game) -> EnemyEntity:
	var best: EnemyEntity = null
	var best_dist: float = INF
	for enemy in game.enemy_container.get_children():
		if not _is_valid_target(enemy):
			continue
		var dist_to_me = position.distance_to(enemy.position)
		if is_outside_ally:
			if dist_to_me > OUTSIDE_ALLY_SEEK_RANGE:
				continue
		else:
			if enemy.position.distance_to(game.map.get_fort_center()) > MAX_SEEK_DISTANCE:
				continue
		if dist_to_me < best_dist:
			best_dist = dist_to_me
			best = enemy
	return best

func _find_best_enemy(game) -> EnemyEntity:
	var best: EnemyEntity = null
	var best_score: float = 999999.0
	var center_x = 640.0  # Map center — enemies closer to center are higher threat
	var max_seek_from_ally = detect_range * 2.0 if is_outside_ally else detect_range * 1.5
	for enemy in game.enemy_container.get_children():
		if not _is_valid_target(enemy):
			continue
		var dist_to_me = position.distance_to(enemy.position)
		if dist_to_me > max_seek_from_ally:
			continue
		# Score: prioritize nearby enemies, but also enemies closer to map center (deeper in)
		var threat = abs(enemy.position.x - center_x)  # Lower = deeper in = higher threat
		var score = dist_to_me * 0.6 + threat * 0.4
		# Bonus priority for enemies already attacking barricades
		if enemy.state == EnemyEntity.EnemyState.ATTACKING_BARRICADE:
			score -= 80.0
		# Reduce priority for enemies already targeted by many allies
		var allies_on_target = 0
		for ally in game.ally_container.get_children():
			if ally != self and ally.target_enemy == enemy:
				allies_on_target += 1
		score += allies_on_target * 30.0
		if score < best_score:
			best_score = score
			best = enemy
	return best

func _apply_separation(delta: float, game):
	var push = Vector2.ZERO
	for ally in game.ally_container.get_children():
		if ally == self:
			continue
		var d = position.distance_to(ally.position)
		if d < 20.0 and d > 0.1:
			push += (position - ally.position).normalized() * (20.0 - d)
	if push.length() > 0:
		position += push.normalized() * move_speed * 0.4 * delta

func take_damage_ally(amount: int, game):
	current_hp -= amount
	hit_flash_timer = 0.08
	squash_factor = 0.65
	if current_hp <= 0:
		current_hp = 0
		state = AllyState.DEAD
		game.particles.emit_death_burst(position.x, position.y, color)
		if game.sfx:
			game.sfx.play_enemy_death()
		queue_free()

# --- Visual juice helpers ---

func _update_squash(delta: float):
	var force = (1.0 - squash_factor) * 180.0
	squash_velocity += force * delta
	squash_velocity *= exp(-12.0 * delta)
	squash_factor += squash_velocity * delta

func _update_trail(delta: float):
	trail_timer += delta
	var is_active = (state == AllyState.ENGAGING or state == AllyState.REGROUPING) and sprite_texture != null
	if is_active and trail_timer >= 0.04:
		trail_timer = 0.0
		trail_history.push_front({"pos": position, "alpha": 0.25})
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
	if current_hp <= 0:
		return
	var flash = hit_flash_timer > 0
	var s = entity_size

	# Enhanced shadow (bigger, more offset, pulsing)
	var shadow_pulse = 1.0
	if state == AllyState.ENGAGING or state == AllyState.REGROUPING:
		shadow_pulse = 1.0 + abs(sin(anim_time * 8.0)) * 0.12
	var shadow_w = s * 2.6 * shadow_pulse
	var shadow_h = s * 0.9 * shadow_pulse
	var shadow_y_off = s * 0.6 + 7.0
	_draw_shadow_ellipse(Rect2(-shadow_w / 2, shadow_y_off - shadow_h / 2, shadow_w, shadow_h), Color(0, 0, 0, 0.32))

	if sprite_texture:
		_draw_sprite(flash, s)
	else:
		_draw_diamond(flash, s)

	# Friendly marker (green dot on top)
	var marker_y = -s * 3.0 - 4 if sprite_texture else -s - 4
	draw_circle(Vector2(0, marker_y), 3.5, Color8(80, 220, 80))

	# HP bar (always visible, dimmed when full)
	var bar_w = s * 2.0 + 14
	var hp_ratio = float(current_hp) / float(max_hp)
	var bar_y = (-s * 3.0 - 10) if sprite_texture else (-s - 12)
	var bar_alpha = 200 if current_hp < max_hp else 80
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 7), Color8(0, 0, 40, bar_alpha))
	var hp_col = Color8(100, 180, 255, bar_alpha)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, 7), hp_col)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 7), Color8(60, 120, 200, bar_alpha / 2), false, 1.0)

	# Label
	var font = ThemeDB.fallback_font
	var label_y = (s + 18) if sprite_texture else (s + 10)
	draw_string(font, Vector2(-s, label_y), label_short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_sprite(flash: bool, s: float):
	var tex_size = sprite_texture.get_size()
	var target_h = s * 4.5
	var base_scale = target_h / tex_size.y

	var offset_x = 0.0
	var offset_y = 0.0
	var tilt = 0.0
	var scale_x = base_scale
	var scale_y = base_scale
	var is_flipped = last_dir.x < 0
	var flip_sign = -1.0 if is_flipped else 1.0

	if state == AllyState.ENGAGING or state == AllyState.REGROUPING:
		# Walking: amplified bob + lean + squash/stretch (2x+)
		offset_y = abs(sin(anim_time * 8.0)) * -7.0
		tilt = sin(anim_time * 8.0) * 0.12
		scale_x = base_scale * (1.0 + cos(anim_time * 8.0) * 0.07)
		scale_y = base_scale * (1.0 - cos(anim_time * 8.0) * 0.07)
	elif state == AllyState.ATTACKING:
		# Attack: amplified lunge on hit, breathe between
		var attack_ratio = attack_timer / attack_cooldown if attack_cooldown > 0 else 0.0
		if attack_ratio > 0.75:
			var punch = sin((1.0 - attack_ratio) / 0.25 * PI)
			var lunge_dir = last_dir
			if target_enemy and is_instance_valid(target_enemy):
				lunge_dir = (target_enemy.position - position).normalized()
			offset_x = lunge_dir.x * punch * 12.0
			offset_y = lunge_dir.y * punch * 12.0 - abs(punch) * 4.0
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

	# Apply spring squash factor
	scale_y *= squash_factor
	scale_x *= (2.0 - squash_factor)

	var sprite_y = -target_h * 0.15 + offset_y

	# Draw afterimage trails (body only)
	for trail in trail_history:
		var trail_offset = trail.pos - position
		draw_set_transform(
			Vector2(trail_offset.x + offset_x, trail_offset.y + sprite_y),
			tilt,
			Vector2(scale_x * flip_sign, scale_y)
		)
		draw_texture(sprite_texture, -sprite_texture.get_size() / 2.0, Color(color.r, color.g, color.b, trail.alpha))

	# Draw sprite outline (slightly larger, dark)
	var outline_bump = 1.06
	draw_set_transform(
		Vector2(offset_x, sprite_y),
		tilt,
		Vector2(scale_x * flip_sign * outline_bump, scale_y * outline_bump)
	)
	draw_texture(sprite_texture, -sprite_texture.get_size() / 2.0, Color(0, 0, 0, 0.5))

	# Draw main sprite
	var sprite_xform = Transform2D(tilt, Vector2(scale_x * flip_sign, scale_y), 0.0, Vector2(offset_x, sprite_y))
	draw_set_transform(
		Vector2(offset_x, sprite_y),
		tilt,
		Vector2(scale_x * flip_sign, scale_y)
	)
	if flash:
		draw_texture(sprite_texture, -sprite_texture.get_size() / 2.0, Color(4.0, 4.0, 4.0, 1.0))
	else:
		draw_texture(sprite_texture, -sprite_texture.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Draw held weapon at anchor point
	if weapon_texture and not weapon_config.is_empty():
		_draw_held_weapon(sprite_xform, is_flipped)

func _draw_held_weapon(sprite_xform: Transform2D, is_flipped: bool):
	if not SPRITE_ANCHORS.has("right_hand"): return
	var anchor_pos = sprite_xform * SPRITE_ANCHORS["right_hand"]
	var tex_size = weapon_texture.get_size()
	var wep_scale = weapon_config.height / tex_size.y
	var facing = last_dir.angle()
	var rot = facing + weapon_config.get("rotation", 0.0)
	var flip_y = -1.0 if is_flipped else 1.0
	var grip = Vector2(tex_size.x * weapon_config.grip.x, tex_size.y * weapon_config.grip.y)
	draw_set_transform(anchor_pos, rot, Vector2(wep_scale, wep_scale * flip_y))
	draw_texture(weapon_texture, -grip)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_diamond(flash: bool, s: float):
	# Apply squash to diamond shape
	var sx = 2.0 - squash_factor
	var sy = squash_factor
	var c = Color.WHITE if flash else color
	var points = PackedVector2Array([
		Vector2(0, -s * sy), Vector2(s * sx, 0), Vector2(0, s * sy), Vector2(-s * sx, 0)
	])
	draw_colored_polygon(points, c)
	var border_col = color.darkened(0.3) if not flash else Color8(200, 200, 200)
	draw_polyline(points + PackedVector2Array([points[0]]), border_col, 2.0)
	if not flash:
		var inner = PackedVector2Array([
			Vector2(0, -s * 0.5 * sy), Vector2(s * 0.5 * sx, 0), Vector2(0, s * 0.5 * sy), Vector2(-s * 0.5 * sx, 0)
		])
		draw_colored_polygon(inner, color.lightened(0.15))
		if is_ranged:
			draw_circle(Vector2.ZERO, 3, Color.WHITE)
			draw_circle(Vector2.ZERO, 3, color.darkened(0.2), false, 1.0)
		else:
			draw_line(Vector2(0, -3), Vector2(0, 3), Color.WHITE, 1.5)
			draw_line(Vector2(-2, -1), Vector2(2, -1), Color.WHITE, 1.0)

func _draw_shadow_ellipse(rect: Rect2, col: Color):
	var center = rect.position + rect.size / 2
	var pts = PackedVector2Array()
	for i in range(16):
		var angle = TAU * i / 16.0
		pts.append(center + Vector2(cos(angle) * rect.size.x / 2, sin(angle) * rect.size.y / 2))
	draw_colored_polygon(pts, col)
