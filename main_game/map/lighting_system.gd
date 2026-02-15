class_name LightingSystem
extends RefCounted

## Directional lighting system for 2D terrain
## Provides normal-mapped lighting without requiring 3D

## Light direction per theme (normalized vectors pointing toward light source)
const THEME_LIGHT_DIRECTIONS = {
	"grass": Vector3(-0.5, -0.7, 0.5),      # Top-left sun
	"cave": Vector3(0.0, -1.0, 0.3),        # Dim overhead
	"sky": Vector3(-0.3, -0.8, 0.5),        # High sun
	"summit": Vector3(-0.4, -0.6, 0.6),     # Angled sunlight
	"lava": Vector3(0.0, 1.0, 0.4),         # Glow from below
	"ice": Vector3(-0.5, -0.5, 0.7),        # Crisp angled light
}

## Light intensity per theme
const THEME_LIGHT_INTENSITY = {
	"grass": 0.6,
	"cave": 0.2,
	"sky": 0.7,
	"summit": 0.65,
	"lava": 0.4,
	"ice": 0.7,
}

## Ambient light color per theme
const THEME_AMBIENT_COLOR = {
	"grass": Color(0.85, 0.90, 0.95, 1.0),
	"cave": Color(0.25, 0.22, 0.35, 1.0),
	"sky": Color(0.90, 0.93, 1.0, 1.0),
	"summit": Color(0.88, 0.92, 1.0, 1.0),
	"lava": Color(0.80, 0.35, 0.20, 1.0),
	"ice": Color(0.85, 0.92, 1.0, 1.0),
}

var theme: String = "grass"
var light_direction: Vector3
var light_intensity: float
var ambient_color: Color
var time_of_day: float = 0.5  # 0=midnight, 0.5=noon, 1.0=midnight

## Initialize lighting for a theme
func setup(theme_name: String):
	theme = theme_name
	light_direction = THEME_LIGHT_DIRECTIONS.get(theme, Vector3(-0.5, -0.7, 0.5)).normalized()
	light_intensity = THEME_LIGHT_INTENSITY.get(theme, 0.5)
	ambient_color = THEME_AMBIENT_COLOR.get(theme, Color(0.8, 0.8, 0.9, 1.0))

## Calculate lighting color for a normal vector
func calculate_lighting(normal: Vector3) -> Color:
	# Dot product for diffuse lighting (Lambert)
	var n_dot_l = max(0.0, normal.dot(light_direction))

	# Diffuse component
	var diffuse = n_dot_l * light_intensity

	# Ambient component
	var ambient = 0.3

	# Combine
	var total = ambient + diffuse

	# Apply ambient color tint
	return Color(
		ambient_color.r * total,
		ambient_color.g * total,
		ambient_color.b * total,
		1.0
	)

## Sample normal from normal map texture at UV coordinates
static func sample_normal_map(normal_map: ImageTexture, uv: Vector2) -> Vector3:
	var img = normal_map.get_image()
	var w = img.get_width()
	var h = img.get_height()

	# Wrap UV coordinates
	var u = fmod(uv.x, 1.0)
	var v = fmod(uv.y, 1.0)
	if u < 0: u += 1.0
	if v < 0: v += 1.0

	# Sample pixel
	var px = int(u * w) % w
	var py = int(v * h) % h
	var col = img.get_pixel(px, py)

	# Convert RGB to normal vector (-1 to 1 range)
	return Vector3(
		col.r * 2.0 - 1.0,
		col.g * 2.0 - 1.0,
		col.b * 2.0 - 1.0
	).normalized()

## Draw directional lighting overlay on a canvas
func draw_lighting_overlay(canvas: CanvasItem, rect: Rect2, normal_map: ImageTexture, resolution: int = 32):
	"""Draw lighting as a grid of colored rectangles based on normal map."""
	if not normal_map:
		return

	var step_x = rect.size.x / float(resolution)
	var step_y = rect.size.y / float(resolution)

	for gy in range(resolution):
		for gx in range(resolution):
			var x = rect.position.x + gx * step_x
			var y = rect.position.y + gy * step_y

			# Calculate UV coordinates
			var uv = Vector2(
				float(gx) / float(resolution),
				float(gy) / float(resolution)
			)

			# Sample normal map
			var normal = sample_normal_map(normal_map, uv)

			# Calculate lighting
			var light_col = calculate_lighting(normal)

			# Draw lit quad
			canvas.draw_rect(
				Rect2(x, y, step_x + 1, step_y + 1),
				Color(light_col.r, light_col.g, light_col.b, 0.4)
			)

## Calculate shadow casting from platform to ground
static func calculate_platform_shadow(platform_rect: Rect2, ground_y: float, light_dir: Vector3) -> Rect2:
	"""Returns shadow rectangle cast from platform onto ground."""
	# Project platform corners using light direction
	var shadow_offset_x = -light_dir.x / light_dir.y * (ground_y - platform_rect.position.y)
	var shadow_offset_y = ground_y - (platform_rect.position.y + platform_rect.size.y)

	# Shadow stretches based on height difference
	var stretch_factor = clampf(shadow_offset_y / 100.0, 0.5, 2.0)

	return Rect2(
		platform_rect.position.x + shadow_offset_x,
		ground_y,
		platform_rect.size.x * stretch_factor,
		20.0  # Shadow height on ground
	)

## Draw platform shadows on ground
func draw_platform_shadows(canvas: CanvasItem, platforms: Array, ground_y: float):
	"""Draw shadows cast by platforms onto the ground."""
	for plat in platforms:
		var shadow_rect = calculate_platform_shadow(plat, ground_y, light_direction)

		# Draw shadow with falloff
		var shadow_color = Color(0, 0, 0, 0.25)
		canvas.draw_rect(shadow_rect, shadow_color)

		# Soft edge falloff
		var edge_fade = 5.0
		canvas.draw_rect(
			Rect2(shadow_rect.position.x - edge_fade, shadow_rect.position.y, edge_fade, shadow_rect.size.y),
			Color(0, 0, 0, 0.0)
		)
		canvas.draw_rect(
			Rect2(shadow_rect.position.x + shadow_rect.size.x, shadow_rect.position.y, edge_fade, shadow_rect.size.y),
			Color(0, 0, 0, 0.0)
		)

## Draw ambient occlusion at corners
static func draw_ambient_occlusion(canvas: CanvasItem, rect: Rect2, corner_darkness: float = 0.3):
	"""Draw dark corners for ambient occlusion effect."""
	var ao_size = 20.0

	# Top-left corner
	canvas.draw_rect(
		Rect2(rect.position.x, rect.position.y, ao_size, ao_size),
		Color(0, 0, 0, corner_darkness)
	)

	# Top-right corner
	canvas.draw_rect(
		Rect2(rect.position.x + rect.size.x - ao_size, rect.position.y, ao_size, ao_size),
		Color(0, 0, 0, corner_darkness)
	)

	# Bottom corners (if terrain has depth)
	if rect.size.y > 60:
		canvas.draw_rect(
			Rect2(rect.position.x, rect.position.y + rect.size.y - ao_size, ao_size, ao_size),
			Color(0, 0, 0, corner_darkness * 0.5)
		)
		canvas.draw_rect(
			Rect2(rect.position.x + rect.size.x - ao_size, rect.position.y + rect.size.y - ao_size, ao_size, ao_size),
			Color(0, 0, 0, corner_darkness * 0.5)
		)

## Update time of day (for dynamic lighting - optional)
func update_time(delta: float, speed: float = 0.05):
	"""Slowly advance time of day for dynamic lighting."""
	time_of_day += delta * speed
	if time_of_day > 1.0:
		time_of_day -= 1.0

	# Modulate light direction based on time (sun position)
	var base_dir = THEME_LIGHT_DIRECTIONS.get(theme, Vector3(-0.5, -0.7, 0.5))
	var time_angle = (time_of_day - 0.5) * PI  # -PI/2 to PI/2

	# Rotate light around Y axis based on time
	light_direction = Vector3(
		base_dir.x * cos(time_angle) - base_dir.z * sin(time_angle),
		base_dir.y,
		base_dir.x * sin(time_angle) + base_dir.z * cos(time_angle)
	).normalized()

	# Modulate intensity (dimmer at night)
	var day_factor = abs(cos(time_of_day * TAU))  # 1 at noon/midnight, 0 at dawn/dusk
	light_intensity = THEME_LIGHT_INTENSITY.get(theme, 0.5) * (0.3 + 0.7 * day_factor)
