class_name CharacterVisual
extends Node2D

## AAA Visual Overhaul: Shader-capable entity rendering for Main Game
## Wraps Sprite2D with outline shader + toon shading material
## Receives transform (scale, flip, tilt) from entity logic
## Handles hit flash, dissolve death, outline per entity
## Phase 3.2: Squash & stretch system (land, jump, strike anticipation)
## Phase 3.4: Dissolve direction, death types (poof / explode / freeze), ragdoll fall

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

# Phase 3.2: Squash & stretch
var squash_stretch_scale: Vector2 = Vector2.ONE   # Applied on top of entity_scale
var _ss_target: Vector2 = Vector2.ONE
var _ss_velocity: Vector2 = Vector2.ZERO
const SS_SPRING_K: float = 220.0   # Spring stiffness
const SS_DAMPING: float = 14.0     # Critical-ish damping

# Phase 3.4: Death types
enum DeathType { POOF, EXPLODE, FREEZE, RAGDOLL }
var death_type: DeathType = DeathType.POOF
var ragdoll_velocity: Vector2 = Vector2.ZERO
var ragdoll_timer: float = 0.0
const RAGDOLL_DURATION: float = 0.3

# Phase 3.4: Dissolve origin direction
enum DissolveOrigin { CENTER, TOP_DOWN, BOTTOM_UP, LEFT, RIGHT }
var dissolve_origin: DissolveOrigin = DissolveOrigin.TOP_DOWN

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
	death_type = config.get("death_type", DeathType.POOF)

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
	# Phase 3.2: Apply squash/stretch on top of entity scale
	var final_scale = entity_scale * squash_stretch_scale
	if sprite:
		sprite.flip_h = flip_h
		sprite.scale = final_scale
		sprite.rotation = entity_rotation
	if outline_sprite:
		outline_sprite.flip_h = flip_h
		outline_sprite.scale = final_scale
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

# ---------------------------------------------------------------------------
# Phase 3.2: Squash & Stretch API
# ---------------------------------------------------------------------------

func squash_land():
	"""Phase 3.2: Squash on land — wide and flat for 2 frames, spring back."""
	_ss_target = Vector2(1.3, 0.7)  # Wide, squashed
	squash_stretch_scale = Vector2(1.3, 0.7)
	_ss_velocity = Vector2.ZERO

func squash_jump():
	"""Phase 3.2: Stretch on jump — tall and thin during ascent."""
	_ss_target = Vector2.ONE
	squash_stretch_scale = Vector2(0.9, 1.15)  # Immediate stretch
	_ss_velocity = Vector2.ZERO

func squash_anticipate():
	"""Phase 3.2: Strike anticipation — slight pull-back."""
	squash_stretch_scale = Vector2(0.95, 1.0)
	_ss_target = Vector2.ONE
	_ss_velocity = Vector2.ZERO

func squash_strike():
	"""Phase 3.2: Snap to forward stretch on strike."""
	squash_stretch_scale = Vector2(1.1, 0.95)
	_ss_target = Vector2.ONE
	_ss_velocity = Vector2.ZERO

func apply_squash(data: Dictionary):
	"""Phase 3.2: Generic squash/stretch. data: {squash: float, axis: 'x'|'y'}"""
	var s: float = data.get("squash", 1.0)
	var axis: String = data.get("axis", "y")
	if axis == "y":
		squash_stretch_scale = Vector2(2.0 - s, s)
	else:
		squash_stretch_scale = Vector2(s, 2.0 - s)
	_ss_target = Vector2.ONE
	_ss_velocity = Vector2.ZERO

# ---------------------------------------------------------------------------
# Phase 3.4: Death types
# ---------------------------------------------------------------------------

func start_dissolve(duration: float = 0.6, color: Color = Color(1.0, 0.4, 0.1), d_type: DeathType = DeathType.POOF):
	"""Start death dissolve effect with typed death."""
	is_dissolving = true
	dissolve_timer = 0.0
	dissolve_duration = duration
	death_type = d_type

	# Adjust origin and color per death type
	match d_type:
		DeathType.POOF:
			dissolve_origin = DissolveOrigin.CENTER
			if dissolve_material:
				dissolve_material.set_shader_parameter("dissolve_color", color)
				dissolve_material.set_shader_parameter("noise_scale", 10.0)
		DeathType.EXPLODE:
			dissolve_origin = DissolveOrigin.CENTER
			if dissolve_material:
				dissolve_material.set_shader_parameter("dissolve_color", Color(1.0, 0.6, 0.1))
				dissolve_material.set_shader_parameter("noise_scale", 6.0)
		DeathType.FREEZE:
			dissolve_origin = DissolveOrigin.TOP_DOWN
			if dissolve_material:
				dissolve_material.set_shader_parameter("dissolve_color", Color(0.6, 0.9, 1.0))
				dissolve_material.set_shader_parameter("noise_scale", 16.0)
		DeathType.RAGDOLL:
			dissolve_origin = DissolveOrigin.BOTTOM_UP
			ragdoll_timer = 0.0
			# Ragdoll velocity: brief downward + horizontal momentum before dissolve
			ragdoll_velocity = Vector2(randf_range(-80, 80), 200.0)

	# Set dissolve origin UV offset in shader (if supported)
	if dissolve_material:
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

	# Phase 3.2: Squash/stretch spring physics
	_update_squash_spring(delta)

	# Phase 3.4: Ragdoll fall before dissolve
	if is_dissolving and death_type == DeathType.RAGDOLL and ragdoll_timer < RAGDOLL_DURATION:
		ragdoll_timer += delta
		position += ragdoll_velocity * delta
		ragdoll_velocity.y += 600.0 * delta  # Gravity
		rotation += ragdoll_velocity.x * 0.001 * delta

	# Dissolve progression
	if is_dissolving:
		dissolve_timer += delta
		var t = clampf(dissolve_timer / dissolve_duration, 0.0, 1.0)

		# Phase 3.4: Direction-based dissolve curve
		var dissolve_t = t
		match dissolve_origin:
			DissolveOrigin.TOP_DOWN:
				dissolve_t = t  # Linear top-down
			DissolveOrigin.CENTER:
				dissolve_t = t  # Center outward (shader handles via noise)
			_:
				dissolve_t = t

		if dissolve_material:
			dissolve_material.set_shader_parameter("dissolve_amount", dissolve_t)
		# Fade outline too
		if outline_sprite:
			outline_sprite.modulate.a = 1.0 - t

func _update_squash_spring(delta: float):
	"""Phase 3.2: Spring-damped squash/stretch return to 1.0."""
	var diff = _ss_target - squash_stretch_scale
	if diff.length() < 0.001 and _ss_velocity.length() < 0.001:
		squash_stretch_scale = _ss_target
		_ss_velocity = Vector2.ZERO
		return

	# Spring: F = k * displacement - damping * velocity
	var spring_force = diff * SS_SPRING_K
	var damping_force = _ss_velocity * SS_DAMPING
	var acc = spring_force - damping_force
	_ss_velocity += acc * delta
	squash_stretch_scale += _ss_velocity * delta

func is_dissolve_complete() -> bool:
	return is_dissolving and dissolve_timer >= dissolve_duration

func set_theme_lighting(theme: String):
	"""Apply theme-specific lighting to toon shader."""
	if not toon_material:
		return

	var theme_cfg = ThemeConfig.load_theme(theme)
	var light_dir = theme_cfg.lighting_direction
	toon_material.set_shader_parameter("light_direction", Color(light_dir.x, light_dir.y, light_dir.z, 1.0))
	toon_material.set_shader_parameter("light_intensity", theme_cfg.lighting_intensity)
	toon_material.set_shader_parameter("ambient_color", theme_cfg.ambient_color)

	outline_color = CartoonPalette.get_outline_color(theme)
	if outline_material:
		outline_material.set_shader_parameter("outline_color", outline_color)

func set_modulate_color(color: Color):
	"""Set sprite modulate (tint) color."""
	if sprite:
		sprite.modulate = color
	if outline_sprite:
		outline_sprite.modulate = Color(outline_sprite.modulate.r, outline_sprite.modulate.g, outline_sprite.modulate.b, color.a)
