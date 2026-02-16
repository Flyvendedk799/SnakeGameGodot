class_name ParticleSystem
extends RefCounted

var particles: Array = []
const MAX_PARTICLES = 350  # AAA Upgrade: Increased for more dynamic effects
const PARTICLE_LIFETIME = 0.7

func emit_burst(x: float, y: float, color: Color, count: int = 12, lifetime: float = PARTICLE_LIFETIME):
	_enforce_limit(count)
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU + randf_range(-0.3, 0.3)
		var spd = randf_range(100.0, 350.0)
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, color, lifetime, randi_range(3, 6))
		p.shape = [Particle.Shape.CIRCLE, Particle.Shape.CIRCLE, Particle.Shape.SQUARE][randi() % 3]
		p.spin_speed = randf_range(-8.0, 8.0)
		p.gravity_mult = randf_range(0.6, 1.4)
		# AAA Upgrade: 20% of particles have collision and color fade
		p.has_collision = randf() < 0.2
		p.color_end = color.darkened(0.3)
		p.ground_y = y + randf_range(10, 30)
		particles.append(p)

func emit_directional(x: float, y: float, dir: Vector2, color: Color, count: int = 8):
	_enforce_limit(count)
	var base_angle = dir.angle()
	for i in range(count):
		var angle = base_angle + randf_range(-0.6, 0.6)
		var spd = randf_range(150.0, 400.0)
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, color, 0.5, randi_range(2, 5))
		p.shape = Particle.Shape.STREAK if randf() < 0.4 else Particle.Shape.CIRCLE
		p.spin_speed = randf_range(-6.0, 6.0)
		p.gravity_mult = randf_range(0.3, 1.0)
		particles.append(p)

func emit_death_burst(x: float, y: float, color: Color):
	_enforce_limit(30)  # AAA Visual Overhaul: Increased for sub-emitters
	# Primary burst particles
	for i in range(16):
		var angle = (float(i) / 16.0) * TAU + randf_range(-0.2, 0.2)
		var spd = randf_range(80.0, 350.0)
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd - 80.0, color, randf_range(0.5, 1.0), randi_range(3, 7))
		p.shape = [Particle.Shape.CIRCLE, Particle.Shape.SQUARE, Particle.Shape.STREAK][randi() % 3]
		p.spin_speed = randf_range(-10.0, 10.0)
		p.gravity_mult = randf_range(0.8, 2.0)
		p.ground_y = y + randf_range(10, 30)
		p.bounce_damping = randf_range(0.2, 0.5)
		particles.append(p)
	# Bright streaks
	for i in range(6):
		var angle = randf_range(-PI * 0.8, -PI * 0.2)
		var spd = randf_range(200.0, 450.0)
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, color.lightened(0.3), 0.6, randi_range(2, 4))
		p.shape = Particle.Shape.STREAK
		p.streak_length = 14.0
		p.gravity_mult = 0.4
		particles.append(p)
	# Flash sparks
	for i in range(3):
		var p = Particle.new(x + randf_range(-5, 5), y + randf_range(-5, 5), randf_range(-30, 30), randf_range(-60, -20), Color.WHITE, 0.2, randi_range(5, 9))
		p.gravity_mult = 0.0
		particles.append(p)
	# AAA Visual Overhaul: Sub-emitter smoke puffs (spawn after delay)
	for i in range(5):
		var smoke_col = Color(0.3, 0.3, 0.35, 0.6)
		var p = Particle.new(x + randf_range(-8, 8), y + randf_range(-8, 8), randf_range(-25, 25), randf_range(-40, -10), smoke_col, 1.2, randi_range(4, 8))
		p.shape = Particle.Shape.SMOKE_PUFF
		p.gravity_mult = -0.15  # Rises slowly
		p.spin_speed = randf_range(-2.0, 2.0)
		p.is_sub_emitter = true
		p.sub_emit_timer = randf_range(0.05, 0.15)  # Delayed spawn
		p.scale_curve = 0.3  # Grows over lifetime
		p.color_end = smoke_col.darkened(0.4)
		particles.append(p)

func emit_speed_streak(x: float, y: float, dir: Vector2, color: Color):
	if particles.size() >= MAX_PARTICLES:
		return
	var p = Particle.new(x + randf_range(-4, 4), y + randf_range(-4, 4), -dir.x * 30.0, -dir.y * 30.0, Color(color.r, color.g, color.b, 0.3), 0.25, 2)
	p.shape = Particle.Shape.STREAK
	p.streak_length = 10.0
	p.gravity_mult = 0.0
	particles.append(p)

func emit_ring(x: float, y: float, color: Color, count: int = 10):
	"""Perfect circular burst - good for double jumps, shockwaves."""
	_enforce_limit(count)
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU
		var spd = 200.0
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, color, 0.4, 3)
		p.shape = Particle.Shape.CIRCLE
		p.gravity_mult = 0.0
		particles.append(p)

func emit_fountain(x: float, y: float, color: Color, count: int = 12):
	"""Upward geyser effect."""
	_enforce_limit(count)
	for i in range(count):
		var spread = randf_range(-0.5, 0.5)
		var spd = randf_range(200.0, 400.0)
		var p = Particle.new(x, y, spread * 100.0, -spd, color, 0.6, randi_range(3, 5))
		p.gravity_mult = 1.5
		particles.append(p)

func emit_sparkle(x: float, y: float, color: Color, count: int = 6):
	"""Gentle floating sparkles."""
	_enforce_limit(count)
	for i in range(count):
		var p = Particle.new(x + randf_range(-20, 20), y + randf_range(-20, 20),
			randf_range(-20, 20), randf_range(-40, -10), color, 0.8, 2)
		p.gravity_mult = -0.3
		p.shape = Particle.Shape.CIRCLE
		particles.append(p)

func emit_trail_puff(x: float, y: float, color: Color):
	"""Single small puff for movement trails."""
	if particles.size() >= MAX_PARTICLES:
		return
	var p = Particle.new(x + randf_range(-3, 3), y, randf_range(-15, 15), randf_range(-30, -5), color, 0.3, 2)
	p.gravity_mult = 0.0
	particles.append(p)

func emit_fire(x: float, y: float, count: int = 8):
	"""Upward-drifting fire particles."""
	_enforce_limit(count)
	for i in range(count):
		var col = [Color8(255, 200, 50), Color8(255, 150, 30), Color8(255, 80, 20)][randi() % 3]
		var p = Particle.new(x + randf_range(-8, 8), y, randf_range(-20, 20), randf_range(-120, -60), col, 0.5, randi_range(2, 4))
		p.gravity_mult = -0.8
		p.shape = Particle.Shape.CIRCLE
		particles.append(p)

func emit_smoke(x: float, y: float, count: int = 5):
	"""Slow rising gray smoke."""
	_enforce_limit(count)
	for i in range(count):
		var gray = randf_range(0.3, 0.6)
		var col = Color(gray, gray, gray, 0.5)
		var p = Particle.new(x + randf_range(-10, 10), y, randf_range(-10, 10), randf_range(-40, -15), col, 1.0, randi_range(4, 7))
		p.gravity_mult = -0.2
		p.shape = Particle.Shape.CIRCLE
		particles.append(p)

func emit_blood(x: float, y: float, dir: Vector2, count: int = 8):
	"""Directional red splatter."""
	_enforce_limit(count)
	var base_angle = dir.angle()
	for i in range(count):
		var angle = base_angle + randf_range(-0.5, 0.5)
		var spd = randf_range(100.0, 300.0)
		var col = Color8(200, 20, 20).lerp(Color8(120, 10, 10), randf())
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, col, 0.4, randi_range(2, 4))
		p.gravity_mult = 1.5
		p.shape = Particle.Shape.STREAK if randf() < 0.3 else Particle.Shape.CIRCLE
		particles.append(p)

func emit_electric(x: float, y: float, count: int = 6):
	"""Fast jagged electric sparks (white/cyan)."""
	_enforce_limit(count)
	for i in range(count):
		var col = Color8(200, 240, 255) if randf() < 0.5 else Color8(100, 200, 255)
		var angle = randf() * TAU
		var spd = randf_range(250.0, 500.0)
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, col, 0.2, 2)
		p.gravity_mult = 0.0
		p.shape = Particle.Shape.STREAK
		p.streak_length = 8.0
		p.spin_speed = randf_range(-15.0, 15.0)
		particles.append(p)

func emit_heal(x: float, y: float, count: int = 6):
	"""Upward floating green sparkles."""
	_enforce_limit(count)
	for i in range(count):
		var col = Color8(80, 255, 120).lerp(Color8(150, 255, 200), randf())
		var p = Particle.new(x + randf_range(-15, 15), y + randf_range(-5, 5),
			randf_range(-15, 15), randf_range(-60, -30), col, 0.7, 3)
		p.gravity_mult = -0.3
		p.shape = Particle.Shape.SQUARE if randf() < 0.3 else Particle.Shape.CIRCLE
		particles.append(p)

func _enforce_limit(incoming: int):
	if particles.size() + incoming <= MAX_PARTICLES:
		return
	var excess = (particles.size() + incoming) - MAX_PARTICLES
	# Single slice instead of O(n) pop_front loop - prevents sudden frame spike
	particles = particles.slice(excess, particles.size())

func update(dt: float):
	# Only rebuild array when particles die (avoids allocation when all alive)
	var alive: Array = []
	for p in particles:
		if p.is_alive():
			p.update(dt)
			alive.append(p)
	if alive.size() < particles.size():
		particles = alive

func draw(canvas: CanvasItem):
	for p in particles:
		p.draw_particle(canvas)

func clear():
	particles.clear()

## Call when frame delta was large - trim particles to recover from lag spike
func trim_on_lag():
	if particles.size() > 100:
		particles = particles.slice(particles.size() - 80, particles.size())
