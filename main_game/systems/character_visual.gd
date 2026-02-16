class_name CharacterVisual
extends Node2D

## AAA Visual Overhaul: Shader-capable entity rendering for Main Game
## Wraps Sprite2D with outline shader + toon shading material
## Receives transform (scale, flip, tilt) from entity logic
## Handles hit flash, dissolve death, outline per entity

var sprite: Sprite2D = null
var outline_sprite: Sprite2D = null  # Drawn behind main sprite for outline
var toon_material: ShaderMaterial = null
var outline_material: ShaderMaterial = null
var dissolve_material: ShaderMaterial = null

# State
var is_dissolving: bool = false
var dissolve_timer: float = 0.0
var dissolve_duration: float = 0.6
var flash_timer: float = 0.0
var flash_duration: float = 0.12

# Config
var outline_width: float = 1.5
var outline_color: Color = Color(0.1, 0.08, 0.15, 0.8)
var entity_tint: Color = Color.WHITE

# Cached shaders
static var _outline_shader: Shader = null
static var _toon_shader: Shader = null
static var _dissolve_shader: Shader = null

static func _load_shaders():
	if _outline_shader == null:
		_outline_shader = load("res://assets/shaders/outline.gdshader") as Shader
	if _toon_shader == null:
		_toon_shader = load("res://assets/shaders/toon_entity.gdshader") as Shader
	if _dissolve_shader == null:
		_dissolve_shader = load("res://assets/shaders/dissolve.gdshader") as Shader

func setup(texture: Texture2D, config: Dictionary = {}):
	"""Initialize the visual with a sprite texture and optional config."""
	_load_shaders()

	outline_width = config.get("outline_width", 1.5)
	outline_color = config.get("outline_color", Color(0.1, 0.08, 0.15, 0.8))
	entity_tint = config.get("tint", Color.WHITE)

	# Outline sprite (drawn behind, slightly larger)
	if _outline_shader:
		outline_sprite = Sprite2D.new()
		outline_sprite.name = "OutlineSprite"
		outline_sprite.texture = texture
		outline_sprite.z_index = -1
		outline_material = ShaderMaterial.new()
		outline_material.shader = _outline_shader
		outline_material.set_shader_parameter("outline_color", outline_color)
		outline_material.set_shader_parameter("outline_width", outline_width)
		outline_material.set_shader_parameter("enabled", true)
		outline_sprite.material = outline_material
		add_child(outline_sprite)

	# Main sprite with toon shading
	sprite = Sprite2D.new()
	sprite.name = "MainSprite"
	sprite.texture = texture

	if _toon_shader:
		toon_material = ShaderMaterial.new()
		toon_material.shader = _toon_shader
		toon_material.set_shader_parameter("toon_steps", 3)
		toon_material.set_shader_parameter("toon_strength", 0.5)
		toon_material.set_shader_parameter("flash_amount", 0.0)
		toon_material.set_shader_parameter("rim_strength", 0.3)
		sprite.material = toon_material

	add_child(sprite)

	# Pre-create dissolve material (not assigned until death)
	if _dissolve_shader:
		dissolve_material = ShaderMaterial.new()
		dissolve_material.shader = _dissolve_shader
		dissolve_material.set_shader_parameter("dissolve_amount", 0.0)
		dissolve_material.set_shader_parameter("dissolve_color", Color(1.0, 0.4, 0.1))
		dissolve_material.set_shader_parameter("noise_scale", 12.0)

func update_transform(flip_h: bool, entity_scale: Vector2, entity_rotation: float = 0.0):
	"""Update visual transform from entity logic."""
	if sprite:
		sprite.flip_h = flip_h
		sprite.scale = entity_scale
		sprite.rotation = entity_rotation
	if outline_sprite:
		outline_sprite.flip_h = flip_h
		outline_sprite.scale = entity_scale
		outline_sprite.rotation = entity_rotation

func set_texture(texture: Texture2D):
	"""Update the sprite texture (e.g., for animation frames)."""
	if sprite:
		sprite.texture = texture
	if outline_sprite:
		outline_sprite.texture = texture

func trigger_flash(duration: float = 0.12, color: Color = Color.WHITE):
	"""Trigger a hit flash effect."""
	flash_timer = duration
	flash_duration = duration
	if toon_material:
		toon_material.set_shader_parameter("flash_color", color)
		toon_material.set_shader_parameter("flash_amount", 1.0)

func start_dissolve(duration: float = 0.6, color: Color = Color(1.0, 0.4, 0.1)):
	"""Start death dissolve effect."""
	is_dissolving = true
	dissolve_timer = 0.0
	dissolve_duration = duration
	if dissolve_material:
		dissolve_material.set_shader_parameter("dissolve_color", color)
		dissolve_material.set_shader_parameter("dissolve_amount", 0.0)
		if sprite:
			sprite.material = dissolve_material

func update_visual(delta: float):
	"""Called each frame to update visual effects."""
	# Flash decay
	if flash_timer > 0:
		flash_timer -= delta
		var flash_t = clampf(flash_timer / flash_duration, 0.0, 1.0)
		if toon_material and not is_dissolving:
			toon_material.set_shader_parameter("flash_amount", flash_t)
	elif toon_material and not is_dissolving:
		toon_material.set_shader_parameter("flash_amount", 0.0)

	# Dissolve progression
	if is_dissolving:
		dissolve_timer += delta
		var t = clampf(dissolve_timer / dissolve_duration, 0.0, 1.0)
		if dissolve_material:
			dissolve_material.set_shader_parameter("dissolve_amount", t)
		# Fade outline too
		if outline_sprite:
			outline_sprite.modulate.a = 1.0 - t

func is_dissolve_complete() -> bool:
	return is_dissolving and dissolve_timer >= dissolve_duration

func set_theme_lighting(theme: String):
	"""Apply theme-specific lighting to toon shader."""
	if not toon_material:
		return

	# Load theme config for lighting
	var theme_cfg = ThemeConfig.load_theme(theme)
	var light_dir = theme_cfg.lighting_direction
	toon_material.set_shader_parameter("light_direction", Color(light_dir.x, light_dir.y, light_dir.z, 1.0))
	toon_material.set_shader_parameter("light_intensity", theme_cfg.lighting_intensity)
	toon_material.set_shader_parameter("ambient_color", theme_cfg.ambient_color)

	# Update outline color from palette
	outline_color = CartoonPalette.get_outline_color(theme)
	if outline_material:
		outline_material.set_shader_parameter("outline_color", outline_color)

func set_modulate_color(color: Color):
	"""Set sprite modulate (tint) color."""
	if sprite:
		sprite.modulate = color
	if outline_sprite:
		outline_sprite.modulate = Color(outline_sprite.modulate.r, outline_sprite.modulate.g, outline_sprite.modulate.b, color.a)
