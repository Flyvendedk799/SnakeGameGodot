class_name PostProcessLayer
extends CanvasLayer

## AAA Cinematic Post-Process Pipeline
## Uses post_cinematic.gdshader — full bloom, edge detection, lens distortion,
## cel-shading, chromatic aberration, speed lines, vignette, film grain.
## Replaces the old passthrough post_simple_test.gdshader.

var game = null
var cel_pass: ColorRect = null
var cel_mat: ShaderMaterial = null

# Dynamic effect state
var impact_strength: float = 0.0
var impact_center: Vector2 = Vector2(0.5, 0.5)
var dynamic_bloom_boost: float = 0.0
var dynamic_chromatic: float = 0.0
var dynamic_speed_lines: float = 0.0
var current_theme: String = "grass"

# -----------------------------------------------------------------------
# Per-theme presets — tuned for "AAA cinematic" look
# Fields: bloom_thresh, bloom_int, contrast, saturation, vignette,
#         lift, gamma, gain, cel_steps, edge, warm, cool, lens_dist
# -----------------------------------------------------------------------
const THEME_PRESETS = {
	"grass": {
		"bloom_threshold": 0.36,
		"bloom_intensity": 1.8,
		"bloom_radius": 4.5,
		"contrast": 1.22,
		"saturation": 1.28,
		"vignette": 0.62,
		"edge_strength": 0.52,
		"edge_threshold": 0.10,
		"lens_distortion": 0.042,
		"color_steps": 6,
		"posterize": 0.52,
		"warm_tint": Color(1.0, 0.93, 0.78),
		"cool_tint": Color(0.68, 0.80, 1.0),
		"lift": Vector3(0.01, 0.005, 0.0),
		"gamma": Vector3(1.0, 1.02, 0.97),
		"gain": Vector3(1.06, 1.0, 0.93),
		"exposure": 1.08,
		"exposure_shoulder": 0.72,
		"exposure_curve": 0.35,
		"grain": 0.038,
	},
	"cave": {
		"bloom_threshold": 0.26,
		"bloom_intensity": 2.4,
		"bloom_radius": 5.5,
		"contrast": 1.35,
		"saturation": 0.88,
		"vignette": 0.85,
		"edge_strength": 0.68,
		"edge_threshold": 0.08,
		"lens_distortion": 0.038,
		"color_steps": 5,
		"posterize": 0.62,
		"warm_tint": Color(0.95, 0.88, 0.80),
		"cool_tint": Color(0.55, 0.62, 0.95),
		"lift": Vector3(0.04, 0.02, 0.06),
		"gamma": Vector3(0.96, 0.97, 1.0),
		"gain": Vector3(0.92, 0.95, 1.08),
		"exposure": 1.15,
		"exposure_shoulder": 0.62,
		"exposure_curve": 0.55,
		"grain": 0.052,
	},
	"lava": {
		"bloom_threshold": 0.30,
		"bloom_intensity": 2.8,
		"bloom_radius": 5.0,
		"contrast": 1.28,
		"saturation": 1.45,
		"vignette": 0.72,
		"edge_strength": 0.60,
		"edge_threshold": 0.10,
		"lens_distortion": 0.048,
		"color_steps": 5,
		"posterize": 0.55,
		"warm_tint": Color(1.0, 0.82, 0.55),
		"cool_tint": Color(0.55, 0.35, 0.45),
		"lift": Vector3(-0.01, -0.02, -0.04),
		"gamma": Vector3(1.0, 0.93, 0.88),
		"gain": Vector3(1.10, 0.96, 0.82),
		"exposure": 1.12,
		"exposure_shoulder": 0.68,
		"exposure_curve": 0.48,
		"grain": 0.042,
	},
	"sky": {
		"bloom_threshold": 0.42,
		"bloom_intensity": 1.5,
		"bloom_radius": 4.0,
		"contrast": 1.15,
		"saturation": 1.32,
		"vignette": 0.48,
		"edge_strength": 0.42,
		"edge_threshold": 0.12,
		"lens_distortion": 0.036,
		"color_steps": 7,
		"posterize": 0.45,
		"warm_tint": Color(1.0, 0.96, 0.88),
		"cool_tint": Color(0.78, 0.86, 1.0),
		"lift": Vector3(0.01, 0.01, 0.02),
		"gamma": Vector3(1.0, 1.0, 1.02),
		"gain": Vector3(1.02, 1.02, 1.04),
		"exposure": 1.05,
		"exposure_shoulder": 0.78,
		"exposure_curve": 0.22,
		"grain": 0.028,
	},
	"summit": {
		"bloom_threshold": 0.38,
		"bloom_intensity": 1.6,
		"bloom_radius": 4.2,
		"contrast": 1.18,
		"saturation": 0.95,
		"vignette": 0.55,
		"edge_strength": 0.48,
		"edge_threshold": 0.11,
		"lens_distortion": 0.038,
		"color_steps": 6,
		"posterize": 0.50,
		"warm_tint": Color(0.98, 0.95, 0.92),
		"cool_tint": Color(0.75, 0.82, 1.0),
		"lift": Vector3(0.02, 0.02, 0.03),
		"gamma": Vector3(0.98, 0.99, 1.0),
		"gain": Vector3(0.98, 0.98, 1.02),
		"exposure": 1.06,
		"exposure_shoulder": 0.74,
		"exposure_curve": 0.30,
		"grain": 0.032,
	},
	"ice": {
		"bloom_threshold": 0.40,
		"bloom_intensity": 1.7,
		"bloom_radius": 4.3,
		"contrast": 1.16,
		"saturation": 0.90,
		"vignette": 0.58,
		"edge_strength": 0.50,
		"edge_threshold": 0.11,
		"lens_distortion": 0.040,
		"color_steps": 6,
		"posterize": 0.48,
		"warm_tint": Color(0.92, 0.96, 1.0),
		"cool_tint": Color(0.70, 0.82, 1.0),
		"lift": Vector3(0.02, 0.02, 0.04),
		"gamma": Vector3(0.98, 0.98, 1.0),
		"gain": Vector3(0.95, 0.97, 1.05),
		"exposure": 1.05,
		"exposure_shoulder": 0.76,
		"exposure_curve": 0.28,
		"grain": 0.030,
	},
}

func setup(game_ref, _viewport_size: Vector2 = Vector2(1280, 720)):
	game = game_ref
	layer = 20  # Above FX (15) and UI (10)
	_build_pass()
	_apply_theme("grass")

func _build_pass():
	var shader = load("res://assets/shaders/post_cinematic.gdshader") as Shader
	if shader == null:
		# Fallback: create a no-op pass so game doesn't crash
		push_warning("PostProcessLayer: post_cinematic.gdshader not found — using passthrough")
		return

	cel_mat = ShaderMaterial.new()
	cel_mat.shader = shader

	cel_pass = ColorRect.new()
	cel_pass.name = "CinematicPass"
	cel_pass.material = cel_mat
	cel_pass.set_anchors_preset(Control.PRESET_FULL_RECT)
	cel_pass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cel_pass.color = Color(1, 1, 1, 0)
	add_child(cel_pass)

func _apply_theme(theme: String):
	current_theme = theme
	if cel_mat == null:
		return

	var p = THEME_PRESETS.get(theme, THEME_PRESETS["grass"])

	cel_mat.set_shader_parameter("bloom_threshold",    p.bloom_threshold)
	cel_mat.set_shader_parameter("bloom_intensity",    p.bloom_intensity)
	cel_mat.set_shader_parameter("bloom_radius",       p.bloom_radius)
	cel_mat.set_shader_parameter("bloom_scatter",      0.72)
	cel_mat.set_shader_parameter("exposure",           p.exposure)
	cel_mat.set_shader_parameter("contrast",           p.contrast)
	cel_mat.set_shader_parameter("saturation",         p.saturation)
	cel_mat.set_shader_parameter("brightness",         1.03)
	cel_mat.set_shader_parameter("color_lift",         p.lift)
	cel_mat.set_shader_parameter("color_gamma",        p.gamma)
	cel_mat.set_shader_parameter("color_gain",         p.gain)
	cel_mat.set_shader_parameter("color_steps",        p.color_steps)
	cel_mat.set_shader_parameter("posterize_strength", p.posterize)
	cel_mat.set_shader_parameter("warm_tint",          p.warm_tint)
	cel_mat.set_shader_parameter("cool_tint",          p.cool_tint)
	cel_mat.set_shader_parameter("cel_blend",          0.50)
	cel_mat.set_shader_parameter("edge_strength",      p.edge_strength)
	cel_mat.set_shader_parameter("edge_color",         Color(0.0, 0.0, 0.04, 1.0))
	cel_mat.set_shader_parameter("edge_threshold",     p.edge_threshold)
	cel_mat.set_shader_parameter("lens_distortion",    p.lens_distortion * 1.6)  # 2.5D: deeper barrel
	cel_mat.set_shader_parameter("lens_zoom",          1.028)                     # 2.5D: tighter zoom
	cel_mat.set_shader_parameter("perspective_amount", 0.055)                     # 2.5D: 2.5x stronger stage tilt
	cel_mat.set_shader_parameter("perspective_enabled", true)
	cel_mat.set_shader_parameter("chromatic_base",     0.0022)
	cel_mat.set_shader_parameter("chromatic_strength", 0.0)
	cel_mat.set_shader_parameter("vignette_strength",  p.vignette * 1.35)  # 2.5D: stronger cinematic frame
	cel_mat.set_shader_parameter("vignette_softness",  0.85)               # 2.5D: tighter falloff (was 1.5)
	cel_mat.set_shader_parameter("vignette_color",     Color(0.0, 0.0, 0.04, 1.0))
	cel_mat.set_shader_parameter("grain_strength",     p.grain)
	cel_mat.set_shader_parameter("grain_size",         1.4)
	cel_mat.set_shader_parameter("scanline_strength",  0.055)
	cel_mat.set_shader_parameter("speed_line_intensity", 0.0)
	cel_mat.set_shader_parameter("speed_line_speed",   5.0)
	cel_mat.set_shader_parameter("impact_strength",    0.0)
	cel_mat.set_shader_parameter("impact_center",      Vector2(0.5, 0.5))
	# Phase 1.2: HDR exposure shoulder/curve per theme
	cel_mat.set_shader_parameter("exposure_shoulder",  p.get("exposure_shoulder", 0.72))
	cel_mat.set_shader_parameter("exposure_curve",     p.get("exposure_curve", 0.0))

func set_theme(theme: String):
	_apply_theme(theme)

func _process(delta: float):
	if game == null or cel_mat == null:
		return

	# Impact distortion decay
	if impact_strength > 0.002:
		impact_strength = lerpf(impact_strength, 0.0, delta * 9.0)
		cel_mat.set_shader_parameter("impact_strength", impact_strength)
		cel_mat.set_shader_parameter("impact_center",   impact_center)
	else:
		impact_strength = 0.0
		cel_mat.set_shader_parameter("impact_strength", 0.0)

	# Bloom boost decay
	if dynamic_bloom_boost > 0.01:
		dynamic_bloom_boost = lerpf(dynamic_bloom_boost, 0.0, delta * 4.0)
	var base_bloom = THEME_PRESETS.get(current_theme, THEME_PRESETS["grass"]).bloom_intensity
	cel_mat.set_shader_parameter("bloom_intensity", base_bloom + dynamic_bloom_boost)

	# Chromatic aberration decay
	if dynamic_chromatic > 0.0001:
		dynamic_chromatic = lerpf(dynamic_chromatic, 0.0, delta * 7.0)
	cel_mat.set_shader_parameter("chromatic_strength", dynamic_chromatic)

	# Speed lines decay
	if dynamic_speed_lines > 0.01:
		dynamic_speed_lines = lerpf(dynamic_speed_lines, 0.0, delta * 3.5)
	else:
		dynamic_speed_lines = 0.0
	cel_mat.set_shader_parameter("speed_line_intensity", dynamic_speed_lines)

	# HP-reactive vignette: swell as health drops
	if game.get("player_node") and game.player_node and not game.player_node.is_dead:
		var hp_ratio = float(game.player_node.current_hp) / float(max(game.player_node.max_hp, 1))
		var base_vig = THEME_PRESETS.get(current_theme, THEME_PRESETS["grass"]).vignette
		var hp_vig   = lerpf(0.0, 0.55, clampf(1.0 - hp_ratio / 0.35, 0.0, 1.0))
		var pulse_vig = sin(Time.get_ticks_msec() * 0.003) * 0.05 if hp_ratio < 0.3 else 0.0
		cel_mat.set_shader_parameter("vignette_strength", base_vig + hp_vig + pulse_vig)

## ---- Public API (same as PostProcessSimple) ----

func trigger_impact_distortion(screen_pos: Vector2, strength: float = 0.5):
	"""Radial screen warp at impact point (normalized 0-1 coords)."""
	impact_center   = screen_pos
	impact_strength = clampf(strength, 0.0, 1.0)

func trigger_bloom_boost(intensity: float = 0.5):
	"""Temporary bloom flare (dash, crit, power-up)."""
	dynamic_bloom_boost = clampf(dynamic_bloom_boost + intensity, 0.0, 3.0)

func trigger_chromatic(intensity: float = 0.005):
	"""Chromatic spike (heavy hits, crits)."""
	dynamic_chromatic = clampf(maxf(dynamic_chromatic, intensity), 0.0, 0.025)

func trigger_speed_lines(intensity: float = 1.0):
	"""Radial speed lines (sprinting, dash, ground pound)."""
	dynamic_speed_lines = clampf(maxf(dynamic_speed_lines, intensity), 0.0, 1.0)

## ---- Phase 1.1: LUT color grade API ----

func apply_lut_texture(lut: ImageTexture, strength: float = 0.72):
	"""Set LUT texture for this frame's color grading."""
	if cel_mat == null:
		return
	if lut != null:
		cel_mat.set_shader_parameter("lut_texture", lut)
		cel_mat.set_shader_parameter("lut_enabled", true)
		cel_mat.set_shader_parameter("lut_strength", strength)
	else:
		cel_mat.set_shader_parameter("lut_enabled", false)

func set_lut_enabled(enabled: bool):
	"""Enable or disable LUT grading pass."""
	if cel_mat:
		cel_mat.set_shader_parameter("lut_enabled", enabled)
