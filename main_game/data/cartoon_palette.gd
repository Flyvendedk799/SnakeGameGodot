class_name CartoonPalette
extends RefCounted

## AAA Visual Overhaul: Per-theme cel-shade color palettes
## Provides base, shadow, midtone, highlight, accent colors for posterization
## Used by post_cel shader and toon_entity shader

# Per-theme palette: {base, shadow_1, shadow_2, midtone, highlight, accent}
const PALETTES = {
	"grass": {
		"base": Color8(95, 160, 95),
		"shadow_1": Color8(55, 100, 70),
		"shadow_2": Color8(35, 70, 50),
		"midtone": Color8(120, 180, 110),
		"highlight": Color8(200, 230, 170),
		"accent": Color8(255, 210, 80),
		"outline": Color8(25, 40, 30),
		"sky_tint": Color8(135, 205, 235),
	},
	"cave": {
		"base": Color8(58, 50, 72),
		"shadow_1": Color8(35, 28, 48),
		"shadow_2": Color8(20, 15, 30),
		"midtone": Color8(80, 70, 95),
		"highlight": Color8(140, 130, 170),
		"accent": Color8(100, 180, 255),
		"outline": Color8(15, 12, 25),
		"sky_tint": Color8(30, 25, 45),
	},
	"sky": {
		"base": Color8(140, 180, 220),
		"shadow_1": Color8(100, 140, 180),
		"shadow_2": Color8(70, 110, 160),
		"midtone": Color8(170, 200, 235),
		"highlight": Color8(220, 240, 255),
		"accent": Color8(255, 220, 180),
		"outline": Color8(50, 70, 100),
		"sky_tint": Color8(180, 220, 255),
	},
	"summit": {
		"base": Color8(155, 165, 175),
		"shadow_1": Color8(110, 120, 135),
		"shadow_2": Color8(75, 85, 100),
		"midtone": Color8(180, 190, 200),
		"highlight": Color8(230, 240, 250),
		"accent": Color8(200, 220, 255),
		"outline": Color8(50, 55, 65),
		"sky_tint": Color8(200, 230, 255),
	},
	"lava": {
		"base": Color8(80, 40, 30),
		"shadow_1": Color8(50, 22, 15),
		"shadow_2": Color8(30, 12, 8),
		"midtone": Color8(120, 60, 40),
		"highlight": Color8(255, 150, 80),
		"accent": Color8(255, 80, 30),
		"outline": Color8(25, 10, 8),
		"sky_tint": Color8(60, 20, 15),
	},
	"ice": {
		"base": Color8(165, 195, 220),
		"shadow_1": Color8(120, 155, 185),
		"shadow_2": Color8(80, 115, 150),
		"midtone": Color8(195, 215, 235),
		"highlight": Color8(240, 248, 255),
		"accent": Color8(180, 230, 255),
		"outline": Color8(50, 70, 90),
		"sky_tint": Color8(200, 230, 250),
	},
}

static func get_palette(theme: String) -> Dictionary:
	return PALETTES.get(theme, PALETTES["grass"])

static func get_outline_color(theme: String) -> Color:
	return get_palette(theme).get("outline", Color8(25, 20, 35))

static func get_accent_color(theme: String) -> Color:
	return get_palette(theme).get("accent", Color8(255, 210, 80))

static func get_highlight_color(theme: String) -> Color:
	return get_palette(theme).get("highlight", Color8(200, 230, 170))

## Returns toon_entity shader uniforms for given theme
static func get_entity_shader_params(theme: String) -> Dictionary:
	var pal = get_palette(theme)
	var theme_cfg = ThemeConfig.load_theme(theme)
	var light_dir = theme_cfg.lighting_direction

	return {
		"light_direction": Vector4(light_dir.x, light_dir.y, light_dir.z, 1.0),
		"light_intensity": theme_cfg.lighting_intensity,
		"ambient_color": theme_cfg.ambient_color,
		"toon_steps": 3,
		"toon_strength": 0.5,
		"rim_strength": 0.3,
		"rim_color": pal.highlight,
	}

## Returns the 5-step posterization palette for this theme (for CPU fallback)
static func get_posterize_ramp(theme: String) -> Array:
	var pal = get_palette(theme)
	return [pal.shadow_2, pal.shadow_1, pal.base, pal.midtone, pal.highlight]
