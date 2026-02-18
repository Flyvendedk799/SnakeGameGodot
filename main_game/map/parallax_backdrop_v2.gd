class_name ParallaxBackdropV2
extends ParallaxBackground

## AAA Visual Overhaul: Proper ParallaxBackground with multiple layers
## Phase 2.1: 5-7 layers with distinct motion scales for deep parallax
##   Scales: 0.0 (fixed sky), 0.08 (horizon glow), 0.2 (far mountains),
##           0.4 (mid hills), 0.65 (near hills), 0.85 (foreground silhouettes), 0.98 (vines/leaves)
## Phase 2.2: Dynamic time-of-day — sky gradient, horizon tint, far layer tint
## Theme-based color palettes per layer

var game = null
var theme_name: String = "grass"
var level_width: float = 2400
var level_height: float = 720

# Time-of-day state (Phase 2.2)
var time_of_day: float = 0.5  # 0=midnight, 0.25=dawn, 0.5=noon, 0.75=dusk, 1=midnight
var time_advance_rate: float = 0.0  # Set to 0.02/60 for slow progression

# Layer nodes (5-7 layers)
var sky_layer: ParallaxLayer = null        # 0.0  - fixed sky gradient
var horizon_layer: ParallaxLayer = null    # 0.08 - horizon glow / moon
var far_layer: ParallaxLayer = null        # 0.2  - distant mountains
var mid_layer: ParallaxLayer = null        # 0.4  - mid hills / clouds
var near_layer: ParallaxLayer = null       # 0.65 - near hills / trees
var silhouette_layer: ParallaxLayer = null # 0.85 - foreground silhouettes
var fg_layer: ParallaxLayer = null         # 0.98 - vines / leaves / motes

# Sprites for time-of-day modulation
var sky_sprite: Sprite2D = null
var horizon_sprite: Sprite2D = null
var far_sprite: Sprite2D = null

# Theme palettes (6 colors per theme: sky-top, sky-mid, sky-bot, hill-far, hill-mid, hill-near)
const THEMES = {
	"grass": [Color8(135, 205, 235), Color8(100, 180, 220), Color8(70, 160, 200), Color8(55, 120, 70), Color8(75, 140, 85), Color8(95, 160, 95)],
	"cave":  [Color8(18, 15, 28),   Color8(28, 24, 40),   Color8(38, 34, 52),   Color8(42, 38, 50),  Color8(48, 44, 55),  Color8(55, 50, 62)],
	"sky":   [Color8(180, 220, 255), Color8(140, 190, 240), Color8(100, 160, 220), Color8(200, 180, 220), Color8(180, 160, 200), Color8(160, 140, 180)],
	"summit":[Color8(200, 230, 255), Color8(170, 200, 235), Color8(140, 170, 210), Color8(120, 140, 160), Color8(140, 150, 165), Color8(160, 165, 175)],
	"lava":  [Color8(60, 20, 15),   Color8(80, 30, 18),   Color8(110, 40, 20),  Color8(50, 25, 15),  Color8(65, 30, 18),  Color8(80, 35, 20)],
	"ice":   [Color8(200, 230, 250), Color8(170, 210, 240), Color8(140, 190, 230), Color8(160, 180, 200), Color8(140, 170, 195), Color8(120, 160, 190)]
}

# Time-of-day sky colors (midnight → dawn → noon → dusk → midnight)
const TOD_MIDNIGHT = Color8(10, 10, 25)
const TOD_DAWN     = Color8(255, 130, 60)
const TOD_NOON     = Color8(135, 205, 235)
const TOD_DUSK     = Color8(255, 100, 70)
const TOD_WARM_TINT = Color(1.05, 0.92, 0.78)
const TOD_COOL_TINT = Color(0.85, 0.92, 1.10)

# Phase 5.2: Biome crossfade state
var _crossfade_active: bool = false
var _crossfade_timer: float = 0.0
var _crossfade_duration: float = 1.5
var _crossfade_target_theme: String = ""

# Phase 2.1: Foreground particle emitter for leaves/vines/motes
var _fg_particles: GPUParticles2D = null

func setup(game_ref, theme: String, width: float, height: float):
	game = game_ref
	theme_name = theme if theme in THEMES else "grass"
	level_width = width
	level_height = height

	# Set time of day from level config if available
	if game and game.map and game.map.level_config.has("time_of_day"):
		time_of_day = float(game.map.level_config.get("time_of_day", 0.5))

	for child in get_children():
		child.queue_free()

	_create_layers()
	_create_foreground_particles()

func _create_layers():
	"""Phase 2.1: Create 5-7 parallax layers with distinct motion scales."""
	var pal = THEMES.get(theme_name, THEMES["grass"])

	# Layer 1: Sky gradient (0.0 — fixed)
	sky_layer = _make_layer(Vector2(0.0, 0.0), "SkyLayer")
	sky_sprite = _make_procedural_sprite(Vector2(level_width + 1600, level_height + 600), pal, "sky")
	sky_sprite.position = Vector2(-800, -300)
	sky_layer.add_child(sky_sprite)
	add_child(sky_layer)

	# Layer 2: Horizon glow / moon / sun (0.08)
	horizon_layer = _make_layer(Vector2(0.08, 0.04), "HorizonLayer")
	horizon_sprite = _make_procedural_sprite(Vector2(level_width + 800, level_height), pal, "horizon")
	horizon_sprite.position = Vector2(-400, 0)
	horizon_layer.add_child(horizon_sprite)
	add_child(horizon_layer)

	# Layer 3: Distant mountains / cave stalactites (0.2)
	far_layer = _make_layer(Vector2(0.2, 0.12), "FarLayer")
	far_sprite = _make_procedural_sprite(Vector2(level_width + 800, level_height), pal, "far_hills")
	far_sprite.position = Vector2(-400, 0)
	# 2.5D: Far layer — strong atmospheric blue haze, clearly receded
	far_sprite.modulate = Color(0.72, 0.80, 1.0, 0.75)
	far_layer.add_child(far_sprite)
	add_child(far_layer)

	# Layer 4: Mid hills (0.4) — slight depth haze
	mid_layer = _make_layer(Vector2(0.4, 0.3), "MidLayer")
	var mid_sprite = _make_procedural_sprite(Vector2(level_width + 400, level_height), pal, "mid_hills")
	mid_sprite.position = Vector2(-200, 0)
	mid_sprite.modulate = Color(0.88, 0.92, 1.0, 0.92)  # 2.5D: mild depth tint
	mid_layer.add_child(mid_sprite)
	add_child(mid_layer)

	# Layer 5: Near hills / trees (0.65)
	near_layer = _make_layer(Vector2(0.65, 0.6), "NearLayer")
	var near_sprite = _make_procedural_sprite(Vector2(level_width + 200, level_height), pal, "near_hills")
	near_sprite.position = Vector2(-100, 0)
	near_layer.add_child(near_sprite)
	add_child(near_layer)

	# Layer 6: Foreground silhouettes — 2.5D: must feel CLOSE, dark and solid
	silhouette_layer = _make_layer(Vector2(0.85, 0.8), "SilhouetteLayer")
	var sil_sprite = _make_procedural_sprite(Vector2(level_width + 100, level_height), pal, "silhouette")
	sil_sprite.position = Vector2(-50, 0)
	sil_sprite.modulate = Color(0.12, 0.10, 0.18, 1.0)  # 2.5D: very dark silhouette for strong foreground
	silhouette_layer.add_child(sil_sprite)
	add_child(silhouette_layer)

	# Layer 7: Near foreground vines / leaves / motes (0.98)
	fg_layer = _make_layer(Vector2(0.98, 0.95), "ForegroundLayer")
	var fg_sprite = _make_procedural_sprite(Vector2(level_width + 60, level_height), pal, "foreground")
	fg_sprite.position = Vector2(-30, 0)
	fg_layer.add_child(fg_sprite)
	add_child(fg_layer)

func _make_layer(motion: Vector2, layer_name: String) -> ParallaxLayer:
	"""Create a ParallaxLayer with given motion scale."""
	var layer = ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(level_width * 2, 0)
	return layer

func _make_procedural_sprite(size: Vector2, pal: Array, layer_type: String) -> Sprite2D:
	"""Create a Sprite2D with procedurally generated texture for this layer."""
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	match layer_type:
		"sky":       _render_sky_gradient(img, pal)
		"horizon":   _render_horizon(img, pal)
		"far_hills": _render_far_hills(img, pal)
		"mid_hills": _render_mid_hills(img, pal)
		"near_hills": _render_near_hills(img, pal)
		"silhouette": _render_silhouette(img, pal)
		"foreground": _render_foreground(img, pal)

	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	return sprite

func _render_sky_gradient(img: Image, pal: Array):
	"""Render vertical sky gradient. Phase 2.2: Time-of-day applied via modulate."""
	var h = img.get_height()
	for y in range(h):
		var t = float(y) / float(h)
		var col = pal[0].lerp(pal[2], t)
		for x in range(img.get_width()):
			img.set_pixel(x, y, col)

func _render_horizon(img: Image, pal: Array):
	"""Render horizon glow band and distant haze."""
	var w = img.get_width()
	var h = img.get_height()
	# Soft horizontal gradient at horizon height (60-70% from top)
	var horizon_y = int(h * 0.65)
	for y in range(h):
		var dist_from_h = absf(float(y) - horizon_y) / float(h * 0.2)
		var glow = clampf(1.0 - dist_from_h * dist_from_h, 0.0, 1.0) * 0.25
		if glow < 0.01:
			continue
		var glow_col = Color(pal[1].r + 0.1, pal[1].g * 0.9, pal[1].b * 0.7, glow)
		for x in range(w):
			img.set_pixel(x, y, glow_col)

func _render_far_hills(img: Image, pal: Array):
	"""Render distant mountain silhouettes with variation."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 1

	for i in range(int(w / 100) + 4):
		var hx = i * 100.0 + rng.randf_range(-15, 15)
		var hy = h - h * rng.randf_range(0.32, 0.55)
		var hw = rng.randf_range(90, 170)
		var hh = h - hy
		var hill_col = pal[3].darkened(0.38)
		# Slight rounded top using triangle
		_fill_rounded_hill(img, int(hx), int(hy), int(hw), int(hh), hill_col, rng)

func _render_mid_hills(img: Image, pal: Array):
	"""Render mid-ground hills."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 2

	for i in range(int(w / 75) + 5):
		var hx = i * 75.0
		var hy = h - h * rng.randf_range(0.28, 0.42)
		var hw = 80.0
		var hh = h - hy
		var hill_col = pal[4].darkened(0.15)
		_fill_rect(img, int(hx), int(hy), int(hw), int(hh), hill_col)

func _render_near_hills(img: Image, pal: Array):
	"""Render near-ground hills with slight lightening."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 3

	for i in range(int(w / 50) + 7):
		var hx = i * 50.0
		var hy = h - h * rng.randf_range(0.22, 0.33)
		var hw = 55.0
		var hh = h - hy
		var hill_col = pal[5].darkened(0.05)
		_fill_rect(img, int(hx), int(hy), int(hw), int(hh), hill_col)

func _render_silhouette(img: Image, pal: Array):
	"""Phase 2.1: Dark foreground silhouettes for depth — trees, rocks."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 6
	var sil_col = pal[5].darkened(0.5)
	sil_col.a = 0.7

	match theme_name:
		"grass", "summit":
			# Tree trunks + canopy bumps
			for i in range(int(w / 120) + 3):
				var tx = i * 120.0 + rng.randf_range(-30, 30)
				var ty = h * 0.72
				# Trunk
				_fill_rect(img, int(tx - 5), int(ty), 10, int(h - ty), sil_col)
				# Canopy
				_fill_ellipse(img, int(tx), int(ty - 25), 35, 30, sil_col, rng)
		"cave":
			# Stalactites hanging from top
			for i in range(int(w / 90) + 4):
				var sx = i * 90.0 + rng.randf_range(-20, 20)
				var sh = int(rng.randf_range(60, 160))
				_fill_rect(img, int(sx - 8), 0, 16, sh, sil_col)
		"lava":
			# Rock formations at ground
			for i in range(int(w / 100) + 4):
				var rx = i * 100.0 + rng.randf_range(-20, 20)
				var ry = h * 0.75
				_fill_rect(img, int(rx - 20), int(ry), 40, int(h - ry), sil_col)
		_:
			pass  # Other themes: sparse silhouettes

func _render_foreground(img: Image, pal: Array):
	"""Phase 2.1: Near foreground leaves / vines (semi-transparent)."""
	# Sparse corner decoration only — preserves gameplay visibility
	var w = img.get_width()
	var h = img.get_height()
	var fg_col = pal[5].darkened(0.3)
	fg_col.a = 0.45
	# Bottom corners: sparse leaf clusters
	_fill_rect(img, 0, int(h * 0.85), 60, int(h * 0.15), fg_col)

# ---------------------------------------------------------------------------
# Phase 2.2: Dynamic time-of-day
# ---------------------------------------------------------------------------

## Phase 5.2: Switch theme mid-level with crossfade
func set_theme(new_theme: String):
	"""Immediately switch theme (no crossfade). For instant transitions."""
	if new_theme == theme_name:
		return
	theme_name = new_theme if new_theme in THEMES else "grass"
	_rebuild_layers()

func crossfade_to_theme(new_theme: String, duration: float = 1.5):
	"""Smoothly crossfade to a new parallax theme over 'duration' seconds."""
	if new_theme == theme_name or new_theme == _crossfade_target_theme:
		return
	_crossfade_target_theme = new_theme if new_theme in THEMES else "grass"
	_crossfade_duration = maxf(duration, 0.1)
	_crossfade_timer = 0.0
	_crossfade_active = true

func _rebuild_layers():
	"""Rebuild all layers for a theme change."""
	for child in get_children():
		child.queue_free()
	sky_layer = null; horizon_layer = null; far_layer = null
	mid_layer = null; near_layer = null; silhouette_layer = null; fg_layer = null
	sky_sprite = null; horizon_sprite = null; far_sprite = null
	_fg_particles = null
	_create_layers()
	_create_foreground_particles()

func _process(delta: float):
	if time_advance_rate > 0:
		time_of_day = fmod(time_of_day + time_advance_rate * delta, 1.0)
		_apply_time_of_day()

	# Phase 5.2: Handle crossfade timer
	if _crossfade_active and not _crossfade_target_theme.is_empty():
		_crossfade_timer += delta
		var t = clampf(_crossfade_timer / _crossfade_duration, 0.0, 1.0)
		# Fade all layer modulates toward target as t→1; at t=1 rebuild fully
		if fg_layer:
			fg_layer.modulate.a = 1.0 - t * 0.5  # gentle fade
		if t >= 1.0:
			_crossfade_active = false
			theme_name = _crossfade_target_theme
			_crossfade_target_theme = ""
			_rebuild_layers()

func _apply_time_of_day():
	"""Phase 2.2: Modulate sky and horizon sprites based on time_of_day."""
	# Sky gradient color
	var sky_col = _get_sky_color()
	if sky_sprite:
		sky_sprite.modulate = sky_col

	# Horizon: warm at dawn/dusk, cool at noon, dark at midnight
	var warm_t = _get_warmth()
	var h_tint = Color(
		1.0 + warm_t * 0.15,
		1.0 - absf(warm_t - 0.5) * 0.05,
		1.0 - warm_t * 0.2,
		1.0
	)
	if horizon_sprite:
		horizon_sprite.modulate = h_tint

	# Far layer: blue tint increases at dusk
	if far_sprite:
		var dusk_blue = lerpf(0.85, 1.0, 1.0 - warm_t)
		far_sprite.modulate = Color(dusk_blue * 0.88, dusk_blue * 0.92, 1.0, 0.85)

func _get_sky_color() -> Color:
	"""Phase 2.2: Sky color lerp through midnight→dawn→noon→dusk→midnight."""
	var t = time_of_day  # 0-1
	var cycle_t = t * 4.0
	var phase = int(cycle_t) % 4
	var sub_t = fmod(cycle_t, 1.0)

	match phase:
		0: return TOD_MIDNIGHT.lerp(TOD_DAWN, sub_t)   # midnight→dawn
		1: return TOD_DAWN.lerp(TOD_NOON, sub_t)       # dawn→noon
		2: return TOD_NOON.lerp(TOD_DUSK, sub_t)       # noon→dusk
		_: return TOD_DUSK.lerp(TOD_MIDNIGHT, sub_t)   # dusk→midnight

func _get_warmth() -> float:
	"""Returns 0.0 (cool/night) to 1.0 (warm dawn/dusk)."""
	return sin(time_of_day * TAU) * 0.5 + 0.5

func set_time_of_day(t: float):
	"""External time_of_day setter — 0.0=midnight, 0.5=noon."""
	time_of_day = clampf(t, 0.0, 1.0)
	_apply_time_of_day()

# ---------------------------------------------------------------------------
# Image drawing helpers
# ---------------------------------------------------------------------------

## Phase 2.1: Foreground GPUParticles2D — leaves / vines / motes / snowflakes
func _create_foreground_particles():
	"""Create theme-appropriate foreground ambient particles."""
	if fg_layer == null:
		return

	var mat = ParticleProcessMaterial.new()
	var amount := 0
	var col := Color(0.3, 0.5, 0.2, 0.6)

	match theme_name:
		"grass", "summit":
			# Falling leaves drifting across screen
			amount = 28
			col = Color8(85, 130, 60, 160)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(level_width * 0.6, 8, 0)
			mat.direction = Vector3(0.3, 1.0, 0).normalized()
			mat.spread = 20.0
			mat.initial_velocity_min = 18.0
			mat.initial_velocity_max = 45.0
			mat.gravity = Vector3(0, 25, 0)
			mat.damping_min = 2.0; mat.damping_max = 8.0
			mat.scale_min = 2.0; mat.scale_max = 5.0
			mat.angle_min = 0.0; mat.angle_max = 360.0
		"cave":
			# Upward drifting spore motes in blue-purple
			amount = 22
			col = Color8(120, 140, 200, 110)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(level_width * 0.5, 8, 0)
			mat.direction = Vector3(0.1, -1.0, 0).normalized()
			mat.spread = 35.0
			mat.initial_velocity_min = 8.0
			mat.initial_velocity_max = 28.0
			mat.gravity = Vector3(0, -15, 0)
			mat.damping_min = 1.0; mat.damping_max = 4.0
			mat.scale_min = 1.5; mat.scale_max = 3.5
		"lava":
			# Hot ember sparks drifting upward
			amount = 35
			col = Color8(255, 140, 40, 130)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(level_width * 0.5, 10, 0)
			mat.direction = Vector3(0.2, -1.0, 0).normalized()
			mat.spread = 40.0
			mat.initial_velocity_min = 20.0
			mat.initial_velocity_max = 60.0
			mat.gravity = Vector3(0, -30, 0)
			mat.damping_min = 3.0; mat.damping_max = 10.0
			mat.scale_min = 1.0; mat.scale_max = 2.5
		"sky":
			# Soft cloud wisps drifting horizontally
			amount = 15
			col = Color8(240, 245, 255, 55)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(level_width * 0.6, 8, 0)
			mat.direction = Vector3(1.0, 0.05, 0).normalized()
			mat.spread = 8.0
			mat.initial_velocity_min = 12.0
			mat.initial_velocity_max = 28.0
			mat.gravity = Vector3(0, 0, 0)
			mat.damping_min = 0.5; mat.damping_max = 2.0
			mat.scale_min = 4.0; mat.scale_max = 10.0
		"ice":
			# Snowflake particles drifting down and sideways
			amount = 32
			col = Color8(220, 235, 255, 160)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(level_width * 0.6, 8, 0)
			mat.direction = Vector3(0.15, 1.0, 0).normalized()
			mat.spread = 22.0
			mat.initial_velocity_min = 15.0
			mat.initial_velocity_max = 35.0
			mat.gravity = Vector3(0, 20, 0)
			mat.damping_min = 1.0; mat.damping_max = 5.0
			mat.scale_min = 1.5; mat.scale_max = 4.0
		_:
			return  # No particles for unknown themes

	if amount == 0:
		return

	# Color over lifetime: appear → fade out
	var grad = Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
	grad.add_point(0.15, col)
	grad.add_point(0.75, col)
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp = GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp

	_fg_particles = GPUParticles2D.new()
	_fg_particles.name = "FGParticles"
	_fg_particles.amount = amount
	_fg_particles.lifetime = 5.5
	_fg_particles.explosiveness = 0.0
	_fg_particles.randomness = 1.0
	_fg_particles.one_shot = false
	_fg_particles.emitting = true
	_fg_particles.process_material = mat
	_fg_particles.texture = _make_fg_particle_texture()
	# Place at top of screen area, spanning level width
	_fg_particles.position = Vector2(level_width * 0.5, 30)
	fg_layer.add_child(_fg_particles)

func _make_fg_particle_texture() -> ImageTexture:
	"""Soft round particle for foreground particles."""
	var size = 10
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var ctr = Vector2(size / 2.0, size / 2.0)
	for y in range(size):
		for x in range(size):
			var d = Vector2(x, y).distance_to(ctr) / (size / 2.0)
			var a = clampf(1.0 - d * d * 2.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------------------
# Image drawing helpers
# ---------------------------------------------------------------------------

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	for py in range(y, min(y + h, img.get_height())):
		for px in range(x, min(x + w, img.get_width())):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)

func _fill_rounded_hill(img: Image, x: int, y: int, w: int, h: int, col: Color, rng: RandomNumberGenerator):
	"""Fill a trapezoidal hill with rounded top."""
	var cx = x + w / 2
	for py in range(y, min(y + h, img.get_height())):
		var rel = float(py - y) / float(maxf(h, 1))
		var half_w = int(w * 0.5 * (1.0 + rel * 0.5))
		for px in range(cx - half_w, cx + half_w):
			if px >= 0 and px < img.get_width() and py >= 0:
				img.set_pixel(px, py, col)

func _fill_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color, _rng: RandomNumberGenerator):
	"""Fill a rough ellipse for tree canopy."""
	for py in range(cy - ry, cy + ry):
		for px in range(cx - rx, cx + rx):
			if px < 0 or px >= img.get_width() or py < 0 or py >= img.get_height():
				continue
			var dx = float(px - cx) / float(rx)
			var dy = float(py - cy) / float(ry)
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(px, py, col)
