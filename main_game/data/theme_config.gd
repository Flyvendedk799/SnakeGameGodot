class_name ThemeConfig
extends Resource

## AAA Visual Upgrade: Per-theme visual settings
## Centralizes theme-specific colors, lighting, and particle palettes

@export var theme_name: String = "grass"

# Color palette
@export var palette: Dictionary = {
	"ground": Color8(75, 95, 55),
	"sky": Color8(135, 205, 235),
	"accent1": Color8(95, 160, 95),
	"accent2": Color8(140, 115, 80)
}

# Sprite outline settings
@export var outline_color: Color = Color(0.1, 0.08, 0.15, 0.8)
@export var outline_width: float = 1.5

# Particle colors
@export var particle_primary: Color = Color8(180, 220, 255)
@export var particle_secondary: Color = Color8(255, 200, 100)

# Visual adjustments
@export var saturation_boost: float = 1.08  # 1.0 = normal, 1.1 = 10% boost

# Lighting (for future use)
@export var lighting_direction: Vector3 = Vector3(-0.5, -0.7, 0.5)
@export var lighting_intensity: float = 0.6
@export var ambient_color: Color = Color(0.85, 0.90, 0.95, 1.0)

# Static theme registry
static var themes: Dictionary = {}

static func load_theme(theme_name: String) -> ThemeConfig:
	"""Load theme configuration, creating default if not found."""
	if not themes.has(theme_name):
		var path = "res://main_game/data/themes/%s_theme.tres" % theme_name
		if ResourceLoader.exists(path):
			themes[theme_name] = load(path)
		else:
			# Fallback to generated defaults
			themes[theme_name] = _create_default_theme(theme_name)
	return themes[theme_name]

static func _create_default_theme(name: String) -> ThemeConfig:
	"""Generate default theme configuration."""
	var config = ThemeConfig.new()
	config.theme_name = name

	match name:
		"grass":
			config.palette = {
				"ground": Color8(75, 95, 55),
				"sky": Color8(135, 205, 235),
				"accent1": Color8(95, 160, 95),
				"accent2": Color8(140, 115, 80)
			}
			config.particle_primary = Color8(180, 220, 255)
			config.particle_secondary = Color8(160, 200, 120)
			config.lighting_direction = Vector3(-0.5, -0.7, 0.5)
			config.lighting_intensity = 0.6
			config.ambient_color = Color(0.85, 0.90, 0.95)

		"cave":
			config.palette = {
				"ground": Color8(45, 40, 50),
				"sky": Color8(18, 15, 28),
				"accent1": Color8(55, 50, 62),
				"accent2": Color8(95, 85, 90)
			}
			config.particle_primary = Color8(160, 140, 180)
			config.particle_secondary = Color8(120, 100, 140)
			config.lighting_direction = Vector3(0.0, -1.0, 0.3)
			config.lighting_intensity = 0.2
			config.ambient_color = Color(0.25, 0.22, 0.35)

		"sky":
			config.palette = {
				"ground": Color8(120, 140, 160),
				"sky": Color8(180, 220, 255),
				"accent1": Color8(160, 140, 180),
				"accent2": Color8(165, 175, 195)
			}
			config.particle_primary = Color8(200, 230, 255)
			config.particle_secondary = Color8(255, 220, 180)
			config.lighting_direction = Vector3(-0.3, -0.8, 0.5)
			config.lighting_intensity = 0.7
			config.ambient_color = Color(0.90, 0.93, 1.0)

		"summit":
			config.palette = {
				"ground": Color8(160, 165, 175),
				"sky": Color8(200, 230, 255),
				"accent1": Color8(140, 150, 165),
				"accent2": Color8(170, 178, 188)
			}
			config.particle_primary = Color8(220, 240, 255)
			config.particle_secondary = Color8(200, 220, 240)
			config.lighting_direction = Vector3(-0.4, -0.6, 0.6)
			config.lighting_intensity = 0.65
			config.ambient_color = Color(0.88, 0.92, 1.0)

		"lava":
			config.palette = {
				"ground": Color8(60, 35, 25),
				"sky": Color8(60, 20, 15),
				"accent1": Color8(80, 35, 20),
				"accent2": Color8(95, 55, 45)
			}
			config.particle_primary = Color8(255, 120, 60)
			config.particle_secondary = Color8(255, 200, 80)
			config.lighting_direction = Vector3(0.0, 1.0, 0.4)
			config.lighting_intensity = 0.4
			config.ambient_color = Color(0.80, 0.35, 0.20)

		"ice":
			config.palette = {
				"ground": Color8(140, 160, 180),
				"sky": Color8(200, 230, 250),
				"accent1": Color8(120, 160, 190),
				"accent2": Color8(185, 200, 215)
			}
			config.particle_primary = Color8(200, 240, 255)
			config.particle_secondary = Color8(180, 220, 255)
			config.lighting_direction = Vector3(-0.5, -0.5, 0.7)
			config.lighting_intensity = 0.7
			config.ambient_color = Color(0.85, 0.92, 1.0)

	return config
