class_name WeatherSystem
extends Node2D

## Phase 2.3: Weather & Ambient Particles
## Theme-gated: rain in grass, dust in lava, snow in ice/summit, fog in cave
## Rain: 500 GPUParticles2D, direction Vector2(0,1)
## Snow: slow large flakes, wind drift
## Dust: ember-like drifting motes for lava/cave
## Light shafts (god rays): via light_shaft.gdshader on a fullscreen quad

var game = null
var weather_type: String = "none"
var intensity: float = 1.0

# GPUParticles2D for precipitation
var precip_particles: GPUParticles2D = null
var dust_particles: GPUParticles2D = null
var light_shaft_rect: ColorRect = null
var light_shaft_mat: ShaderMaterial = null

# Theme → weather type mapping
const THEME_WEATHER = {
	"grass":   "rain",
	"cave":    "dust",
	"sky":     "clouds",
	"summit":  "snow",
	"lava":    "dust",
	"ice":     "snow",
}

# Weather particle configs
const WEATHER_CONFIGS = {
	"rain": {
		"amount": 500,
		"lifetime": 0.8,
		"velocity_min": 300.0,
		"velocity_max": 500.0,
		"direction": Vector3(0.1, 1.0, 0),
		"spread": 5.0,
		"scale_min": 0.2,
		"scale_max": 0.5,
		"color": Color8(150, 200, 255, 100),
	},
	"snow": {
		"amount": 200,
		"lifetime": 4.0,
		"velocity_min": 20.0,
		"velocity_max": 80.0,
		"direction": Vector3(0.15, 1.0, 0),
		"spread": 25.0,
		"scale_min": 0.6,
		"scale_max": 1.4,
		"color": Color8(240, 245, 255, 180),
	},
	"dust": {
		"amount": 120,
		"lifetime": 3.0,
		"velocity_min": 15.0,
		"velocity_max": 60.0,
		"direction": Vector3(1.0, -0.2, 0),
		"spread": 45.0,
		"scale_min": 0.4,
		"scale_max": 1.2,
		"color": Color8(255, 180, 80, 90),
	},
	"clouds": {
		"amount": 30,
		"lifetime": 8.0,
		"velocity_min": 10.0,
		"velocity_max": 30.0,
		"direction": Vector3(1.0, 0.0, 0),
		"spread": 10.0,
		"scale_min": 2.0,
		"scale_max": 5.0,
		"color": Color8(255, 255, 255, 60),
	},
}

func setup(game_ref, theme: String, weather_intensity: float = 1.0):
	game = game_ref
	intensity = weather_intensity
	weather_type = THEME_WEATHER.get(theme, "none")
	_build_weather()

func _build_weather():
	"""Create weather particle systems for the current theme."""
	if weather_type == "none":
		return

	var cfg = WEATHER_CONFIGS.get(weather_type, null)
	if cfg == null:
		return

	# Primary precipitation
	precip_particles = GPUParticles2D.new()
	precip_particles.name = "WeatherParticles"
	precip_particles.amount = int(cfg.amount * intensity)
	precip_particles.lifetime = cfg.lifetime
	precip_particles.explosiveness = 0.0
	precip_particles.randomness = 1.0
	precip_particles.one_shot = false
	precip_particles.emitting = true
	precip_particles.position = Vector2(640, -50)  # Top of screen

	var mat = _make_weather_material(cfg)
	precip_particles.process_material = mat
	precip_particles.texture = _make_particle_texture(weather_type)
	add_child(precip_particles)

	# Dust: add secondary slow-drift motes
	if weather_type == "dust":
		_add_dust_motes()

	# Light shafts for applicable themes
	if weather_type in ["rain", "snow"]:
		_add_light_shaft()

func _make_weather_material(cfg: Dictionary) -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(700, 5, 0)
	mat.direction = cfg.direction.normalized()
	mat.spread = cfg.spread
	mat.initial_velocity_min = cfg.velocity_min * intensity
	mat.initial_velocity_max = cfg.velocity_max * intensity
	mat.gravity = Vector3(0, 100 if weather_type == "rain" else 30, 0)
	mat.damping_min = 0.0
	mat.damping_max = 5.0
	mat.scale_min = cfg.scale_min
	mat.scale_max = cfg.scale_max

	# Color over lifetime
	var col: Color = cfg.color
	var grad = Gradient.new()
	grad.set_color(0, col)
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp = GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	return mat

func _add_dust_motes():
	"""Secondary slow-rising dust motes for lava/cave."""
	dust_particles = GPUParticles2D.new()
	dust_particles.name = "DustMotes"
	dust_particles.amount = 40
	dust_particles.lifetime = 5.0
	dust_particles.emitting = true
	dust_particles.position = Vector2(640, 500)

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(640, 100, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 25.0
	mat.gravity = Vector3(0, -20, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8

	var col = Color8(255, 140, 60, 70)
	var grad = Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
	grad.add_point(0.2, col)
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp = GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	dust_particles.process_material = mat
	dust_particles.texture = _make_particle_texture("dust_mote")
	add_child(dust_particles)

func _add_light_shaft():
	"""Phase 2.3: God rays via light_shaft.gdshader on a fullscreen ColorRect."""
	var shader_path = "res://assets/shaders/light_shaft.gdshader"
	if not ResourceLoader.exists(shader_path):
		return  # Shader not yet created — skip gracefully

	var shader = load(shader_path) as Shader
	if shader == null:
		return

	light_shaft_mat = ShaderMaterial.new()
	light_shaft_mat.shader = shader
	light_shaft_mat.set_shader_parameter("ray_origin", Vector2(0.5, 0.0))
	light_shaft_mat.set_shader_parameter("ray_intensity", 0.12 * intensity)
	light_shaft_mat.set_shader_parameter("ray_color", Color(1.0, 0.95, 0.85, 1.0))
	light_shaft_mat.set_shader_parameter("num_samples", 32)
	light_shaft_mat.set_shader_parameter("decay", 0.94)
	light_shaft_mat.set_shader_parameter("density", 0.8)

	# Place in FX layer above game, below UI
	var canvas = CanvasLayer.new()
	canvas.layer = 8
	light_shaft_rect = ColorRect.new()
	light_shaft_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	light_shaft_rect.material = light_shaft_mat
	light_shaft_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light_shaft_rect.color = Color(0, 0, 0, 0)
	canvas.add_child(light_shaft_rect)
	add_child(canvas)

func _make_particle_texture(type: String) -> ImageTexture:
	"""Generate appropriate texture shape per weather type."""
	match type:
		"rain":
			# Thin vertical streak
			var img = Image.create(2, 8, false, Image.FORMAT_RGBA8)
			for y in range(8):
				var a = clampf(1.0 - float(y) / 8.0, 0.0, 1.0)
				img.set_pixel(0, y, Color(1, 1, 1, a))
				img.set_pixel(1, y, Color(1, 1, 1, a))
			return ImageTexture.create_from_image(img)
		"snow", "clouds":
			# Soft circle
			return _make_soft_circle(8)
		_:
			# Default: tiny soft circle
			return _make_soft_circle(4)

func _make_soft_circle(radius: int) -> ImageTexture:
	var size = radius * 2
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(radius, radius)
	for y in range(size):
		for x in range(size):
			var d = Vector2(x, y).distance_to(center) / float(radius)
			var a = clampf(1.0 - d * d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func set_intensity(new_intensity: float):
	"""Adjust weather intensity at runtime."""
	intensity = clampf(new_intensity, 0.0, 2.0)
	if precip_particles:
		var cfg = WEATHER_CONFIGS.get(weather_type, {})
		precip_particles.amount = int(cfg.get("amount", 100) * intensity)
		precip_particles.emitting = intensity > 0.0

func set_visible_weather(visible: bool):
	"""Toggle weather particles (e.g., indoors)."""
	if precip_particles:
		precip_particles.emitting = visible and intensity > 0.0
	if dust_particles:
		dust_particles.emitting = visible and intensity > 0.0

## Phase 2.3: Time-of-day driven light shaft ray origin
func set_time_of_day(tod: float):
	"""Update light shaft ray_origin based on sun/moon position.
	tod: 0.0=midnight, 0.25=dawn, 0.5=noon, 0.75=dusk, 1.0=midnight.
	Sun: horizontal drift + vertical arc based on tod.
	"""
	if light_shaft_mat == null:
		return

	# Horizontal drift: sun moves left→right across 0.1–0.9 screen width
	var sun_x = 0.5 + 0.38 * cos(tod * TAU - PI * 0.5)
	# Vertical position: 0.0 (top) when noon, deeper at dawn/dusk
	var sun_y_offset = 1.0 - absf(sin(tod * TAU))  # 0 at noon, 1 at midnight
	var sun_y = 0.05 + sun_y_offset * 0.35          # 0.05 (noon) to 0.40 (midnight)

	# At midnight (tod=0 or 1): disable shafts; at dawn/dusk: strong; noon: moderate
	var phase_intensity = maxf(0.0, sin(tod * TAU)) * 0.5 + 0.5  # 0=midnight, 1=noon-ish
	if absf(tod - 0.25) < 0.12 or absf(tod - 0.75) < 0.12:
		# Dawn / dusk: intense warm shafts
		phase_intensity = 1.3

	light_shaft_mat.set_shader_parameter("ray_origin", Vector2(sun_x, sun_y))
	light_shaft_mat.set_shader_parameter("ray_intensity", 0.12 * intensity * phase_intensity)
