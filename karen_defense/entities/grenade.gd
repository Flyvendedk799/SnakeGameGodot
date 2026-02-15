class_name GrenadeEntity
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var throw_speed: float = 350.0
var throw_distance: float = 200.0
var damage: int = 40
var blast_radius: float = 85.0
var owner_player = null  # PlayerEntity reference

# Arc trajectory
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var flight_time: float = 0.45  # Total arc time
var age: float = 0.0
var arc_height: float = 90.0  # Peak height of arc (higher for better visibility)

# Visual
var spin: float = 0.0
var has_exploded: bool = false

# Trail
var trail_points: Array = []
const MAX_TRAIL = 8

func setup(from: Vector2, dir: Vector2, dist: float, dmg: int, owner: PlayerEntity):
	start_pos = from
	position = from
	direction = dir.normalized()
	throw_distance = dist
	target_pos = from + direction * throw_distance
	damage = dmg
	owner_player = owner
	flight_time = clampf(throw_distance / throw_speed, 0.3, 0.7)

func update_grenade(delta: float, game) -> bool:
	"""Returns true when grenade should be removed."""
	if has_exploded:
		return true

	age += delta
	spin += delta * 14.0  # Spin the grenade

	var t = clampf(age / flight_time, 0.0, 1.0)

	# Lerp position along ground
	var ground_pos = start_pos.lerp(target_pos, t)

	# Parabolic arc height (peaks at t=0.5)
	var height = arc_height * 4.0 * t * (1.0 - t)

	# Store trail point
	if trail_points.size() == 0 or ground_pos.distance_to(trail_points[-1]) > 6.0:
		trail_points.append(ground_pos)
		if trail_points.size() > MAX_TRAIL:
			trail_points.pop_front()

	position = Vector2(ground_pos.x, ground_pos.y - height)

	# Reached target?
	if t >= 1.0:
		_explode(game)
		return true

	queue_redraw()
	return false

func _explode(game):
	has_exploded = true
	if game.projectile_container:
		var fx = ExplosionEffect.new()
		fx.setup(target_pos, blast_radius)
		game.projectile_container.add_child(fx)

	# Area damage to all enemies in blast radius
	for enemy in game.enemy_container.get_children():
		if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
			continue
		var dist = target_pos.distance_to(enemy.position)
		if dist <= blast_radius:
			# Damage falls off with distance
			var falloff = 1.0 - (dist / blast_radius) * 0.5
			var dmg = int(damage * falloff)
			if owner_player:
				enemy.last_damager = owner_player
			enemy.take_damage(dmg, game)
			game.spawn_damage_number(enemy.position, str(dmg), Color8(255, 180, 50))

	# Visual explosion
	game.particles.emit_burst(target_pos.x, target_pos.y, Color8(255, 160, 30), 20, 0.6)
	game.particles.emit_burst(target_pos.x, target_pos.y, Color8(255, 80, 20), 12, 0.5)
	game.particles.emit_burst(target_pos.x, target_pos.y, Color8(255, 255, 200), 6, 0.3)

	# Screen shake
	game.start_shake(5.0, 0.2)

	# Sound
	if game.sfx:
		game.sfx.play_grenade_explode()

func _draw():
	if has_exploded:
		return

	var t = clampf(age / flight_time, 0.0, 1.0)
	var height = arc_height * 4.0 * t * (1.0 - t)

	# Draw shadow on ground (grows as grenade gets higher)
	var shadow_size = 6.0 + height * 0.06
	var shadow_alpha = 0.3 - height * 0.001
	var ground_offset = Vector2(0, height)  # Shadow is below at ground level
	_draw_shadow_ellipse(
		Rect2(-shadow_size + ground_offset.x, -shadow_size * 0.4 + ground_offset.y,
			   shadow_size * 2, shadow_size * 0.8),
		Color(0, 0, 0, maxf(0.1, shadow_alpha))
	)

	# Draw trail
	for i in range(trail_points.size()):
		var alpha = float(i) / float(trail_points.size()) * 0.3
		var trail_offset = trail_points[i] - position + ground_offset
		draw_circle(trail_offset, 2.0, Color(1.0, 0.6, 0.2, alpha))

	# Draw grenade body (spinning, larger for visibility)
	draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)

	# Outline for visibility
	draw_circle(Vector2.ZERO, 9.0, Color8(30, 35, 30))
	# Outer body
	draw_circle(Vector2.ZERO, 7.5, Color8(65, 75, 60))
	# Inner ring
	draw_circle(Vector2.ZERO, 5.5, Color8(85, 95, 75))
	# Highlight
	draw_circle(Vector2(-2, -2), 2.5, Color8(125, 135, 115))
	# Band detail
	draw_arc(Vector2.ZERO, 6.0, -0.3, PI + 0.3, 8, Color8(50, 55, 45), 1.5)

	# Fuse spark (flickers, brighter)
	var spark_on = fmod(age * 20.0, 1.0) > 0.3
	if spark_on:
		var fuse_pos = Vector2(0, -9)
		draw_circle(fuse_pos, 4.0, Color8(255, 200, 30, 200))
		draw_circle(fuse_pos, 2.0, Color(1, 1, 1, 0.9))
		# Spark particles (tiny dots around fuse)
		var spark_angle = age * 30.0
		for si in range(2):
			var sa = spark_angle + si * PI
			var sp = fuse_pos + Vector2(cos(sa), sin(sa)) * 5.0
			draw_circle(sp, 1.0, Color(1.0, 0.85, 0.3, 0.6))

	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Blast radius indicator (fades in progressively during flight)
	if t > 0.4:
		var indicator_alpha = (t - 0.4) / 0.6 * 0.2
		# Dashed circle for blast zone
		var segs = 16
		for si in range(segs):
			if si % 2 == 0:
				var a1 = TAU * float(si) / float(segs)
				var a2 = TAU * float(si + 1) / float(segs)
				var p1 = ground_offset + Vector2.from_angle(a1) * blast_radius
				var p2 = ground_offset + Vector2.from_angle(a2) * blast_radius
				draw_line(p1, p2, Color(1.0, 0.4, 0.1, indicator_alpha), 1.5)
		# Center crosshair at landing
		if t > 0.7:
			var cross_a = indicator_alpha * 1.5
			var cs = 8.0
			draw_line(ground_offset + Vector2(-cs, 0), ground_offset + Vector2(cs, 0), Color(1.0, 0.5, 0.2, cross_a), 1.0)
			draw_line(ground_offset + Vector2(0, -cs), ground_offset + Vector2(0, cs), Color(1.0, 0.5, 0.2, cross_a), 1.0)

func _draw_shadow_ellipse(rect: Rect2, color: Color):
	var center = rect.position + rect.size / 2
	var points = PackedVector2Array()
	for i in range(12):
		var angle = TAU * i / 12.0
		points.append(center + Vector2(cos(angle) * rect.size.x / 2, sin(angle) * rect.size.y / 2))
	draw_colored_polygon(points, color)
