class_name ParallaxBackdropV2
extends ParallaxBackground

## AAA Visual Overhaul: Proper ParallaxBackground with multiple layers
## Phase 6: Environment and parallax overhaul
## Replaces monolithic _draw() with structured ParallaxLayer nodes

var game = null
var theme_name: String = "grass"
var level_width: float = 2400
var level_height: float = 720

# Layer nodes
var sky_layer: ParallaxLayer = null
var far_layer: ParallaxLayer = null
var mid_layer: ParallaxLayer = null
var near_layer: ParallaxLayer = null
var foreground_layer: ParallaxLayer = null

# Theme palettes
const THEMES = {
	"grass": [Color8(135, 205, 235), Color8(100, 180, 220), Color8(70, 160, 200), Color8(55, 120, 70), Color8(75, 140, 85), Color8(95, 160, 95)],
	"cave": [Color8(18, 15, 28), Color8(28, 24, 40), Color8(38, 34, 52), Color8(42, 38, 50), Color8(48, 44, 55), Color8(55, 50, 62)],
	"sky": [Color8(180, 220, 255), Color8(140, 190, 240), Color8(100, 160, 220), Color8(200, 180, 220), Color8(180, 160, 200), Color8(160, 140, 180)],
	"summit": [Color8(200, 230, 255), Color8(170, 200, 235), Color8(140, 170, 210), Color8(120, 140, 160), Color8(140, 150, 165), Color8(160, 165, 175)],
	"lava": [Color8(60, 20, 15), Color8(80, 30, 18), Color8(110, 40, 20), Color8(50, 25, 15), Color8(65, 30, 18), Color8(80, 35, 20)],
	"ice": [Color8(200, 230, 250), Color8(170, 210, 240), Color8(140, 190, 230), Color8(160, 180, 200), Color8(140, 170, 195), Color8(120, 160, 190)]
}

func setup(game_ref, theme: String, width: float, height: float):
	game = game_ref
	theme_name = theme if theme in THEMES else "grass"
	level_width = width
	level_height = height

	# Clear existing layers
	for child in get_children():
		child.queue_free()

	_create_layers()

func _create_layers():
	"""AAA Visual Overhaul: Create structured parallax layers."""
	var pal = THEMES.get(theme_name, THEMES["grass"])

	# Layer 1: Sky gradient (motion_scale 0.0 - fixed)
	sky_layer = _make_layer(Vector2(0.0, 0.0), "SkyLayer")
	var sky_sprite = _make_procedural_sprite(Vector2(level_width + 1600, level_height + 600), pal, "sky")
	sky_sprite.position = Vector2(-800, -300)
	sky_layer.add_child(sky_sprite)
	add_child(sky_layer)

	# Layer 2: Far hills/mountains (motion_scale 0.15)
	far_layer = _make_layer(Vector2(0.15, 0.1), "FarLayer")
	var far_sprite = _make_procedural_sprite(Vector2(level_width + 800, level_height), pal, "far_hills")
	far_sprite.position = Vector2(-400, 0)
	far_layer.add_child(far_sprite)
	add_child(far_layer)

	# Layer 3: Mid hills/structures (motion_scale 0.4)
	mid_layer = _make_layer(Vector2(0.4, 0.3), "MidLayer")
	var mid_sprite = _make_procedural_sprite(Vector2(level_width + 400, level_height), pal, "mid_hills")
	mid_sprite.position = Vector2(-200, 0)
	mid_layer.add_child(mid_sprite)
	add_child(mid_layer)

	# Layer 4: Near hills/trees (motion_scale 0.65)
	near_layer = _make_layer(Vector2(0.65, 0.6), "NearLayer")
	var near_sprite = _make_procedural_sprite(Vector2(level_width + 200, level_height), pal, "near_hills")
	near_sprite.position = Vector2(-100, 0)
	near_layer.add_child(near_sprite)
	add_child(near_layer)

	# Layer 5: Foreground foliage (motion_scale 0.92 - almost 1:1)
	foreground_layer = _make_layer(Vector2(0.92, 0.9), "ForegroundLayer")
	var fg_sprite = _make_procedural_sprite(Vector2(level_width + 100, level_height), pal, "foreground")
	fg_sprite.position = Vector2(-50, 0)
	foreground_layer.add_child(fg_sprite)
	add_child(foreground_layer)

func _make_layer(motion: Vector2, layer_name: String) -> ParallaxLayer:
	"""Create a ParallaxLayer with given motion scale."""
	var layer = ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(level_width * 2, 0)  # Horizontal wrapping
	return layer

func _make_procedural_sprite(size: Vector2, pal: Array, layer_type: String) -> Sprite2D:
	"""Create a Sprite2D with procedurally generated texture for this layer."""
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Render to image based on layer type
	match layer_type:
		"sky":
			_render_sky_gradient(img, pal)
		"far_hills":
			_render_far_hills(img, pal)
		"mid_hills":
			_render_mid_hills(img, pal)
		"near_hills":
			_render_near_hills(img, pal)
		"foreground":
			_render_foreground(img, pal)

	var tex = ImageTexture.create_from_image(img)
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	return sprite

func _render_sky_gradient(img: Image, pal: Array):
	"""Render vertical sky gradient."""
	var h = img.get_height()
	for y in range(h):
		var t = float(y) / float(h)
		var col = pal[0].lerp(pal[2], t)
		for x in range(img.get_width()):
			img.set_pixel(x, y, col)

func _render_far_hills(img: Image, pal: Array):
	"""Render distant hill silhouettes."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 1

	# Draw hill shapes
	for i in range(int(w / 120) + 3):
		var hx = i * 120.0 + rng.randf_range(-20, 20)
		var hy = h - h * rng.randf_range(0.3, 0.5)
		var hw = rng.randf_range(80, 160)
		var hh = h - hy
		var hill_col = pal[3].darkened(0.35)
		_fill_rect(img, int(hx), int(hy), int(hw), int(hh), hill_col)

func _render_mid_hills(img: Image, pal: Array):
	"""Render mid-ground hills and structures."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 2

	for i in range(int(w / 80) + 4):
		var hx = i * 80.0
		var hy = h - h * rng.randf_range(0.28, 0.4)
		var hw = 85.0
		var hh = h - hy
		var hill_col = pal[4].darkened(0.12)
		_fill_rect(img, int(hx), int(hy), int(hw), int(hh), hill_col)

func _render_near_hills(img: Image, pal: Array):
	"""Render near-ground hills."""
	var w = img.get_width()
	var h = img.get_height()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + 3

	for i in range(int(w / 50) + 6):
		var hx = i * 50.0
		var hy = h - h * rng.randf_range(0.25, 0.35)
		var hw = 55.0
		var hh = h - hy
		var hill_col = pal[5].darkened(0.05)
		_fill_rect(img, int(hx), int(hy), int(hw), int(hh), hill_col)

func _render_foreground(img: Image, pal: Array):
	"""Render foreground foliage silhouettes."""
	# Sparse foreground elements for depth framing
	# Leave mostly transparent for gameplay visibility
	pass

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color):
	"""Fill rectangle in image."""
	for py in range(y, min(y + h, img.get_height())):
		for px in range(x, min(x + w, img.get_width())):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, col)
