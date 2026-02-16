class_name PostProcessSimple
extends CanvasLayer

## AAA Visual Overhaul: Simplified post-processing that actually works in Godot 4
## Uses a single ColorRect overlay with screen-space shader

var game = null
var shader_rect: ColorRect = null
var shader_mat: ShaderMaterial = null

# Dynamic effect state
var dynamic_bloom: float = 0.0
var dynamic_chromatic: float = 0.0
var impact_strength: float = 0.0
var impact_center: Vector2 = Vector2(0.5, 0.5)

# Theme settings
var current_theme: String = "grass"

func setup(game_ref):
	game = game_ref
	layer = 20  # Above game content

	# Create full-screen overlay ColorRect
	shader_rect = ColorRect.new()
	shader_rect.name = "PostProcessOverlay"
	shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Make it cover the full screen
	shader_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	shader_rect.size = Vector2(1280, 720)

	# Load and apply shader
	var shader = load("res://assets/shaders/post_working.gdshader") as Shader
	if shader:
		shader_mat = ShaderMaterial.new()
		shader_mat.shader = shader
		shader_rect.material = shader_mat
		_set_defaults()

	add_child(shader_rect)

func _set_defaults():
	if not shader_mat:
		return

	# Set default values - SUBTLE for less "filter" feeling
	shader_mat.set_shader_parameter("cel_steps", 6)  # More steps = smoother
	shader_mat.set_shader_parameter("cel_strength", 0.25)  # Reduced cel effect
	shader_mat.set_shader_parameter("bloom_intensity", 0.15)  # Subtle bloom
	shader_mat.set_shader_parameter("vignette_strength", 0.15)  # Light vignette
	shader_mat.set_shader_parameter("saturation", 1.05)  # Slight boost only
	shader_mat.set_shader_parameter("contrast", 1.02)  # Minimal contrast
	shader_mat.set_shader_parameter("grain_amount", 0.01)  # Very subtle grain

func set_theme(theme: String):
	current_theme = theme
	if not shader_mat:
		return

	# Adjust vignette per theme
	match theme:
		"cave":
			shader_mat.set_shader_parameter("vignette_strength", 0.4)
		"lava":
			shader_mat.set_shader_parameter("vignette_strength", 0.35)
		_:
			shader_mat.set_shader_parameter("vignette_strength", 0.25)

func _process(delta: float):
	if not shader_mat or not game:
		return

	# Decay dynamic effects - faster decay, lower max values
	if dynamic_bloom > 0.01:
		dynamic_bloom = lerpf(dynamic_bloom, 0.0, delta * 5.0)  # Faster decay
	shader_mat.set_shader_parameter("bloom_intensity", 0.15 + dynamic_bloom * 0.5)  # Lower max

	if dynamic_chromatic > 0.001:
		dynamic_chromatic = lerpf(dynamic_chromatic, 0.0, delta * 8.0)  # Faster decay
	shader_mat.set_shader_parameter("chromatic_amount", dynamic_chromatic * 0.3)  # Much subtler

	if impact_strength > 0.001:
		impact_strength = lerpf(impact_strength, 0.0, delta * 8.0)
	shader_mat.set_shader_parameter("distort_strength", impact_strength)
	shader_mat.set_shader_parameter("distort_center", impact_center)

	# HP-reactive vignette
	if game.player_node and not game.player_node.is_dead:
		var hp_ratio = float(game.player_node.current_hp) / float(game.player_node.max_hp)
		var base_vig = 0.25
		if current_theme == "cave":
			base_vig = 0.4
		var hp_vig = lerpf(0.0, 0.25, clampf(1.0 - hp_ratio / 0.3, 0.0, 1.0))
		shader_mat.set_shader_parameter("vignette_strength", base_vig + hp_vig)

# Public API
func trigger_bloom_boost(intensity: float = 0.4):
	dynamic_bloom = clampf(dynamic_bloom + intensity, 0.0, 1.0)

func trigger_chromatic(intensity: float = 0.01):
	dynamic_chromatic = clampf(intensity, 0.0, 0.03)

func trigger_impact_distortion(screen_pos: Vector2, strength: float = 0.5):
	impact_center = screen_pos
	impact_strength = clampf(strength, 0.0, 1.0)
