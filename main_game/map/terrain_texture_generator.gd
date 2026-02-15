class_name TerrainTextureGenerator
extends RefCounted

## Procedural texture generator for terrain tiles
## Generates tiled textures with normal maps for all 6 themes

const TILE_SIZE = 64  # 64x64 pixel tiles

# Cache for generated textures
static var _texture_cache: Dictionary = {}
static var _normal_cache: Dictionary = {}

## Generate or retrieve cached terrain texture for a theme
static func get_terrain_texture(theme: String) -> ImageTexture:
	if theme in _texture_cache:
		return _texture_cache[theme]

	var texture = _generate_terrain_texture(theme)
	_texture_cache[theme] = texture
	return texture

## Generate or retrieve cached normal map for a theme
static func get_normal_map(theme: String) -> ImageTexture:
	if theme in _normal_cache:
		return _normal_cache[theme]

	var normal = _generate_normal_map(theme)
	_normal_cache[theme] = normal
	return normal

## Generate terrain texture for a specific theme
static func _generate_terrain_texture(theme: String) -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Get base color for theme
	var base_color = _get_base_color(theme)

	# Fill with base color
	img.fill(base_color)

	# Add noise-based variation
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme)

	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var noise_val = _perlin_noise(x / 8.0, y / 8.0, rng.seed)
			var detail_noise = _perlin_noise(x / 2.0, y / 2.0, rng.seed + 1337)

			# Combine noise layers
			var combined = noise_val * 0.7 + detail_noise * 0.3
			var brightness = 1.0 + (combined - 0.5) * 0.3  # ±15% variation

			var pixel_color = Color(
				base_color.r * brightness,
				base_color.g * brightness,
				base_color.b * brightness,
				1.0
			)

			# Add theme-specific details
			pixel_color = _add_theme_details(pixel_color, theme, x, y, rng)

			img.set_pixel(x, y, pixel_color)

	return ImageTexture.create_from_image(img)

## Generate normal map from height data
static func _generate_normal_map(theme: String) -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Create height map first
	var height_map = []
	height_map.resize(TILE_SIZE * TILE_SIZE)

	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme)

	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var noise = _perlin_noise(x / 8.0, y / 8.0, rng.seed)
			height_map[y * TILE_SIZE + x] = noise

	# Calculate normals from height map
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var left = height_map[y * TILE_SIZE + max(x - 1, 0)]
			var right = height_map[y * TILE_SIZE + min(x + 1, TILE_SIZE - 1)]
			var up = height_map[max(y - 1, 0) * TILE_SIZE + x]
			var down = height_map[min(y + 1, TILE_SIZE - 1) * TILE_SIZE + x]

			# Calculate gradients
			var dx = (right - left) * 0.5
			var dy = (down - up) * 0.5

			# Convert to normal vector
			var normal = Vector3(-dx, -dy, 1.0).normalized()

			# Map to 0-1 range for RGB
			var normal_color = Color(
				normal.x * 0.5 + 0.5,
				normal.y * 0.5 + 0.5,
				normal.z * 0.5 + 0.5,
				1.0
			)

			img.set_pixel(x, y, normal_color)

	return ImageTexture.create_from_image(img)

## Simple Perlin-like noise function
static func _perlin_noise(x: float, y: float, seed: int) -> float:
	# Simple gradient noise implementation
	var xi = int(floor(x))
	var yi = int(floor(y))
	var xf = x - xi
	var yf = y - yi

	# Smooth interpolation
	var u = xf * xf * (3.0 - 2.0 * xf)
	var v = yf * yf * (3.0 - 2.0 * yf)

	# Hash corners
	var aa = _hash2d(xi, yi, seed)
	var ab = _hash2d(xi, yi + 1, seed)
	var ba = _hash2d(xi + 1, yi, seed)
	var bb = _hash2d(xi + 1, yi + 1, seed)

	# Bilinear interpolation
	var x1 = lerp(aa, ba, u)
	var x2 = lerp(ab, bb, u)
	return lerp(x1, x2, v)

## 2D hash function
static func _hash2d(x: int, y: int, seed: int) -> float:
	var h = (x * 374761393 + y * 668265263 + seed) & 0x7FFFFFFF
	h = (h ^ (h >> 13)) * 1274126177
	return float(h & 0xFFFFFF) / float(0xFFFFFF)

## Get base color for theme
static func _get_base_color(theme: String) -> Color:
	match theme:
		"grass":
			return Color8(75, 95, 55)
		"cave":
			return Color8(58, 50, 62)
		"sky":
			return Color8(135, 150, 175)
		"summit":
			return Color8(155, 165, 175)
		"lava":
			return Color8(65, 35, 30)
		"ice":
			return Color8(165, 185, 200)
		_:
			return Color8(100, 100, 100)

## Add theme-specific detail patterns
static func _add_theme_details(col: Color, theme: String, x: int, y: int, rng: RandomNumberGenerator) -> Color:
	var result = col

	match theme:
		"grass":
			# Add dirt patches and grass texture
			if _hash2d(x / 4, y / 4, rng.seed) > 0.7:
				result = result.darkened(0.15)  # Dirt patches
			# Vertical grass grain
			if (x + y / 2) % 3 == 0:
				result = result.lightened(0.05)

		"cave":
			# Add mineral veins and cracks
			if _hash2d(x / 3, y / 8, rng.seed) > 0.85:
				result = result.lightened(0.2)  # Crystal veins
			# Horizontal stratification
			if y % 8 < 2:
				result = result.darkened(0.08)

		"sky":
			# Add cloud-like wisps
			var cloud_noise = _perlin_noise(x / 6.0, y / 6.0, rng.seed + 777)
			if cloud_noise > 0.6:
				result = result.lightened(0.12)

		"summit", "ice":
			# Add ice crystals and snow texture
			if _hash2d(x / 2, y / 2, rng.seed) > 0.8:
				result = result.lightened(0.15)  # Ice sparkles
			# Grainy snow texture
			if (x + y) % 2 == 0:
				result = result.lightened(0.03)

		"lava":
			# Add glowing cracks and embers
			var glow_noise = _perlin_noise(x / 4.0, y / 4.0, rng.seed + 999)
			if glow_noise > 0.75:
				# Hot spots
				result = Color(
					min(result.r + 0.3, 1.0),
					result.g,
					result.b,
					1.0
				)

	return result

## Generate platform texture with bevel
static func get_platform_texture(theme: String) -> ImageTexture:
	var cache_key = theme + "_platform"
	if cache_key in _texture_cache:
		return _texture_cache[cache_key]

	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Get platform colors
	var base_color = _get_platform_color(theme)
	var top_color = base_color.lightened(0.2)
	var shadow_color = base_color.darkened(0.2)

	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme + "_plat")

	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var col = base_color

			# Top bevel (bright)
			if y < 6:
				var bevel_t = float(6 - y) / 6.0
				col = base_color.lerp(top_color, bevel_t)
			# Bottom edge (shadow)
			elif y > TILE_SIZE - 4:
				col = shadow_color
			# Left/right edges
			if x < 3 or x > TILE_SIZE - 4:
				col = col.darkened(0.1)

			# Add texture noise
			var noise = _perlin_noise(x / 4.0, y / 4.0, rng.seed)
			col = Color(
				col.r * (0.95 + noise * 0.1),
				col.g * (0.95 + noise * 0.1),
				col.b * (0.95 + noise * 0.1),
				1.0
			)

			img.set_pixel(x, y, col)

	var texture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = texture
	return texture

## Get platform base color for theme
static func _get_platform_color(theme: String) -> Color:
	match theme:
		"grass":
			return Color8(140, 115, 80)
		"cave":
			return Color8(95, 85, 90)
		"sky":
			return Color8(165, 175, 195)
		"summit":
			return Color8(170, 178, 188)
		"lava":
			return Color8(95, 55, 45)
		"ice":
			return Color8(185, 200, 215)
		_:
			return Color8(120, 120, 120)
