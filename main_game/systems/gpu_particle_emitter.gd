class_name GPUParticleEmitter
extends Node2D

## Phase 4.2: GPU Particle Emitter wrapper
## Manages GPUParticles2D nodes for 500+ particle bursts (explosions, death)
## Sub-emitters: death burst spawns ember trails on expiration
## Color over lifetime: gradient from hit_color to transparent
## For small counts (< 30), CPU particles via the existing ParticleSystem are preferred.

const MAX_EMITTERS: int = 8  # Pool size to prevent node explosion

var _pool: Array = []       # Pre-allocated GPUParticles2D pool
var _parent: Node = null

func setup(parent: Node):
	"""Initialize emitter pool under parent node."""
	_parent = parent
	for i in range(MAX_EMITTERS):
		var e = GPUParticles2D.new()
		e.name = "GPUEmitter_%d" % i
		e.emitting = false
		e.one_shot = true
		e.explosiveness = 1.0
		e.visible = false
		parent.add_child(e)
		_pool.append(e)

func emit_death_burst(world_pos: Vector2, col: Color, count: int = 60):
	"""Large GPU death burst: 60 particles, color-gradient, sub-ember emitter."""
	var e = _get_free_emitter()
	if e == null:
		return

	e.position = world_pos
	e.amount = count
	e.lifetime = 0.8
	e.explosiveness = 0.95
	e.one_shot = true

	var mat = _make_burst_material(col, count)
	e.process_material = mat
	e.texture = _make_circle_texture(6)
	e.visible = true
	e.emitting = true

	# Sub-emitter: spawn embers after main burst
	_schedule_ember_sub(world_pos, col)

func emit_explosion(world_pos: Vector2, col: Color, radius: float = 100.0):
	"""Large explosion: 120 particles, radial spread."""
	var e = _get_free_emitter()
	if e == null:
		return

	e.position = world_pos
	e.amount = 120
	e.lifetime = 1.0
	e.explosiveness = 1.0
	e.one_shot = true

	var mat = _make_explosion_material(col, radius)
	e.process_material = mat
	e.texture = _make_circle_texture(4)
	e.visible = true
	e.emitting = true

func _get_free_emitter() -> GPUParticles2D:
	"""Return a non-emitting emitter from pool, or oldest if all busy."""
	for e in _pool:
		if not e.emitting:
			return e
	# All busy: reuse the first (oldest)
	if _pool.size() > 0:
		_pool[0].emitting = false
		return _pool[0]
	return null

func _make_burst_material(col: Color, _count: int) -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 240.0
	mat.gravity = Vector3(0, 400, 0)
	mat.damping_min = 20.0
	mat.damping_max = 80.0
	mat.scale_min = 0.6
	mat.scale_max = 1.4

	# Color over lifetime: hit_color → transparent
	var grad = Gradient.new()
	grad.set_color(0, col)
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	return mat

func _make_explosion_material(col: Color, radius: float) -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = radius * 0.2
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = radius * 3.0
	mat.gravity = Vector3(0, 300, 0)
	mat.damping_min = 30.0
	mat.damping_max = 100.0
	mat.scale_min = 0.5
	mat.scale_max = 2.0

	var grad = Gradient.new()
	grad.add_point(0.0, Color(1.0, 1.0, 0.8, 1.0))  # bright flash
	grad.add_point(0.3, col)
	grad.add_point(1.0, Color(col.r * 0.5, col.g * 0.3, 0.0, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	return mat

func _schedule_ember_sub(world_pos: Vector2, col: Color):
	"""Delayed sub-emitter: emit ember sparks 0.4s after main burst."""
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func(): _emit_embers(world_pos, col))

func _emit_embers(world_pos: Vector2, col: Color):
	"""Ember sub-emitter: 20 small long-lived sparks drifting upward."""
	var e = _get_free_emitter()
	if e == null:
		return

	e.position = world_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	e.amount = 20
	e.lifetime = 1.2
	e.explosiveness = 0.5
	e.one_shot = true

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 16.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 80.0
	mat.gravity = Vector3(0, -60, 0)  # Float upward
	mat.damping_min = 5.0
	mat.damping_max = 20.0
	mat.scale_min = 0.3
	mat.scale_max = 0.8

	var ember_col = col.lightened(0.3)
	var grad = Gradient.new()
	grad.set_color(0, ember_col)
	grad.set_color(1, Color(ember_col.r, ember_col.g * 0.5, 0.0, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp

	e.process_material = mat
	e.texture = _make_circle_texture(3)
	e.visible = true
	e.emitting = true

func _make_circle_texture(radius: int) -> ImageTexture:
	"""Generate a soft circular particle texture."""
	var size = radius * 4
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for y in range(size):
		for x in range(size):
			var d = Vector2(x, y).distance_to(center) / float(radius * 2)
			var a = clampf(1.0 - d * d * 2.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
