class_name ParticleSystem
extends RefCounted

var particles: Array = []
const MAX_PARTICLES = 350
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
	_enforce_limit(25)
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
	for i in range(6):
		var angle = randf_range(-PI * 0.8, -PI * 0.2)
		var spd = randf_range(200.0, 450.0)
		var p = Particle.new(x, y, cos(angle) * spd, sin(angle) * spd, color.lightened(0.3), 0.6, randi_range(2, 4))
		p.shape = Particle.Shape.STREAK
		p.streak_length = 14.0
		p.gravity_mult = 0.4
		particles.append(p)
	for i in range(3):
		var p = Particle.new(x + randf_range(-5, 5), y + randf_range(-5, 5), randf_range(-30, 30), randf_range(-60, -20), Color.WHITE, 0.2, randi_range(5, 9))
		p.gravity_mult = 0.0
		particles.append(p)

func emit_speed_streak(x: float, y: float, dir: Vector2, color: Color):
	if particles.size() >= MAX_PARTICLES:
		return
	var p = Particle.new(x + randf_range(-4, 4), y + randf_range(-4, 4), -dir.x * 30.0, -dir.y * 30.0, Color(color.r, color.g, color.b, 0.3), 0.25, 2)
	p.shape = Particle.Shape.STREAK
	p.streak_length = 10.0
	p.gravity_mult = 0.0
	particles.append(p)

func _enforce_limit(incoming: int):
	if particles.size() + incoming <= MAX_PARTICLES:
		return
	var excess = (particles.size() + incoming) - MAX_PARTICLES
	for i in range(excess):
		particles.pop_front()

func update(dt: float):
	var alive: Array = []
	for p in particles:
		if p.is_alive():
			p.update(dt)
			alive.append(p)
	particles = alive

func draw(canvas: CanvasItem):
	for p in particles:
		p.draw_particle(canvas)

func clear():
	particles.clear()
