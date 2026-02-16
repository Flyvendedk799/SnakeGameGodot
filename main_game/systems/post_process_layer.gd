class_name PostProcessLayer
extends CanvasLayer

## AAA Visual Upgrade: Multi-pass GPU post-processing pipeline
## Orchestrates SubViewport rendering + shader chain
## Passes: Bloom -> Tonemap -> Cel-shading -> LUT/Grading (+ impact distortion)

var game = null

# SubViewport for rendering game scene
var sub_viewport: SubViewport = null
var viewport_texture_rect: TextureRect = null

# Shader pass nodes (each is a ColorRect with a ShaderMaterial)
var bloom_pass: ColorRect = null
var tonemap_pass: ColorRect = null
var cel_pass: ColorRect = null
var lut_pass: ColorRect = null
var distort_pass: ColorRect = null
var perspective_pass: ColorRect = null

# Shader materials
var bloom_mat: ShaderMaterial = null
var tonemap_mat: ShaderMaterial = null
var cel_mat: ShaderMaterial = null
var lut_mat: ShaderMaterial = null
var distort_mat: ShaderMaterial = null
var perspective_mat: ShaderMaterial = null

# Dynamic effect state
var impact_strength: float = 0.0
var impact_center: Vector2 = Vector2(0.5, 0.5)
var dynamic_bloom_boost: float = 0.0  # Added during dashes, crits
var dynamic_chromatic: float = 0.0  # Chromatic aberration intensity

# Theme-driven settings
var current_theme: String = "grass"

# Per-theme cel-shade settings
const THEME_CEL_SETTINGS = {
	"grass": {"warm": Color(1.0, 0.96, 0.88), "cool": Color(0.75, 0.82, 0.95), "steps": 5, "edge": 0.55},
	"cave": {"warm": Color(0.95, 0.9, 0.85), "cool": Color(0.6, 0.65, 0.8), "steps": 5, "edge": 0.7},
	"sky": {"warm": Color(1.0, 0.98, 0.92), "cool": Color(0.8, 0.85, 1.0), "steps": 6, "edge": 0.45},
	"summit": {"warm": Color(0.98, 0.96, 0.94), "cool": Color(0.8, 0.85, 0.95), "steps": 5, "edge": 0.5},
	"lava": {"warm": Color(1.0, 0.85, 0.65), "cool": Color(0.55, 0.4, 0.5), "steps": 5, "edge": 0.65},
	"ice": {"warm": Color(0.95, 0.97, 1.0), "cool": Color(0.7, 0.8, 0.95), "steps": 6, "edge": 0.5},
}

# Per-theme color grading
const THEME_GRADE_SETTINGS = {
	"grass": {"lift_b": 0.01, "gamma_g": 1.02, "gain_r": 1.03, "vignette": 0.3},
	"cave": {"lift_b": 0.04, "gamma_g": 0.96, "gain_r": 0.95, "vignette": 0.5},
	"sky": {"lift_b": 0.02, "gamma_g": 1.0, "gain_r": 1.0, "vignette": 0.25},
	"summit": {"lift_b": 0.03, "gamma_g": 0.98, "gain_r": 0.98, "vignette": 0.35},
	"lava": {"lift_b": -0.02, "gamma_g": 0.94, "gain_r": 1.08, "vignette": 0.45},
	"ice": {"lift_b": 0.05, "gamma_g": 0.97, "gain_r": 0.96, "vignette": 0.35},
}

func setup(game_ref, viewport_size: Vector2 = Vector2(1280, 720)):
	game = game_ref
	layer = 20  # Above FX layer (15) and UI layer (10)

	# CRITICAL: Add BackBufferCopy for screen_texture access in Godot 4
	var backbuffer = BackBufferCopy.new()
	backbuffer.name = "BackBufferCopy"
	backbuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(backbuffer)

	_create_shader_passes(viewport_size)
	_apply_theme("grass")

func _create_shader_passes(vp_size: Vector2):
	# Load simple test shader first to verify setup works
	var combined_shader = load("res://assets/shaders/post_simple_test.gdshader") as Shader

	if combined_shader:
		# Create single material with all effects
		cel_mat = ShaderMaterial.new()
		cel_mat.shader = combined_shader

		# Initialize defaults
		cel_mat.set_shader_parameter("bloom_threshold", 0.7)
		cel_mat.set_shader_parameter("bloom_intensity", 0.8)
		cel_mat.set_shader_parameter("bloom_radius", 3.0)
		cel_mat.set_shader_parameter("exposure", 1.0)
		cel_mat.set_shader_parameter("contrast", 1.1)
		cel_mat.set_shader_parameter("saturation", 1.08)
		cel_mat.set_shader_parameter("color_steps", 5)
		cel_mat.set_shader_parameter("posterize_strength", 0.6)
		cel_mat.set_shader_parameter("vignette_strength", 0.3)
		cel_mat.set_shader_parameter("chromatic_strength", 0.0)
		cel_mat.set_shader_parameter("grain_strength", 0.025)
		cel_mat.set_shader_parameter("impact_strength", 0.0)
		cel_mat.set_shader_parameter("impact_center", Vector2(0.5, 0.5))
		cel_mat.set_shader_parameter("perspective_amount", 0.025)
		cel_mat.set_shader_parameter("perspective_enabled", true)

		# Create single full-screen pass
		cel_pass = _make_pass_rect(vp_size, cel_mat, "PostProcessPass")
		add_child(cel_pass)

func _make_pass_rect(vp_size: Vector2, material: ShaderMaterial, pass_name: String) -> ColorRect:
	var rect = ColorRect.new()
	rect.name = pass_name
	rect.material = material

	# CRITICAL: Set anchors to cover full screen
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.size = vp_size
	rect.position = Vector2.ZERO
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# TRANSPARENT - let the shader do all the work
	rect.color = Color(1, 1, 1, 0)

	return rect

func _apply_theme(theme: String):
	current_theme = theme

	if not cel_mat:
		return

	# Cel-shading settings
	var cel_cfg = THEME_CEL_SETTINGS.get(theme, THEME_CEL_SETTINGS["grass"])
	cel_mat.set_shader_parameter("warm_tint", cel_cfg.warm)
	cel_mat.set_shader_parameter("cool_tint", cel_cfg.cool)
	cel_mat.set_shader_parameter("color_steps", cel_cfg.steps)
	cel_mat.set_shader_parameter("posterize_strength", 0.6)

	# Color grading/vignette settings
	var grade_cfg = THEME_GRADE_SETTINGS.get(theme, THEME_GRADE_SETTINGS["grass"])
	cel_mat.set_shader_parameter("vignette_strength", grade_cfg.vignette)
	cel_mat.set_shader_parameter("grain_strength", 0.025)

func set_theme(theme: String):
	_apply_theme(theme)

func _process(delta: float):
	if game == null or not cel_mat:
		return

	# Decay impact distortion
	if impact_strength > 0.001:
		impact_strength = lerpf(impact_strength, 0.0, delta * 8.0)
		cel_mat.set_shader_parameter("impact_strength", impact_strength)
		cel_mat.set_shader_parameter("impact_center", impact_center)
	else:
		cel_mat.set_shader_parameter("impact_strength", 0.0)

	# Dynamic bloom boost (dashes, crits)
	if dynamic_bloom_boost > 0.01:
		dynamic_bloom_boost = lerpf(dynamic_bloom_boost, 0.0, delta * 4.0)
	cel_mat.set_shader_parameter("bloom_intensity", 0.8 + dynamic_bloom_boost)

	# Dynamic chromatic aberration
	if dynamic_chromatic > 0.0001:
		dynamic_chromatic = lerpf(dynamic_chromatic, 0.0, delta * 6.0)
	cel_mat.set_shader_parameter("chromatic_strength", dynamic_chromatic)

	# HP-reactive vignette: stronger at low HP
	if game.player_node and not game.player_node.is_dead:
		var hp_ratio = float(game.player_node.current_hp) / float(game.player_node.max_hp)
		var base_vig = THEME_GRADE_SETTINGS.get(current_theme, {}).get("vignette", 0.3)
		var hp_vig = lerpf(0.0, 0.3, clampf(1.0 - hp_ratio / 0.3, 0.0, 1.0))
		cel_mat.set_shader_parameter("vignette_strength", base_vig + hp_vig)

## Public API for game systems to trigger effects

func trigger_impact_distortion(screen_pos: Vector2, strength: float = 0.5):
	"""Trigger radial screen warp from impact point. screen_pos in normalized 0-1 coords."""
	impact_center = screen_pos
	impact_strength = clampf(strength, 0.0, 1.0)

func trigger_bloom_boost(intensity: float = 0.5):
	"""Temporarily boost bloom for emphasis (dash, crit, power-up)."""
	dynamic_bloom_boost = clampf(dynamic_bloom_boost + intensity, 0.0, 1.5)

func trigger_chromatic(intensity: float = 0.005):
	"""Trigger chromatic aberration (crits, heavy hits)."""
	dynamic_chromatic = clampf(intensity, 0.0, 0.015)
