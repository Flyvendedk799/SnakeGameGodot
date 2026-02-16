class_name Particle
extends RefCounted

enum Shape { CIRCLE, SQUARE, STREAK, SPARK, GLOW, TEXTURED, SMOKE_PUFF }  # AAA Visual Overhaul: Added TEXTURED, SMOKE_PUFF

var x: float
var y: float
var vx: float
var vy: float
var color: Color
var lifetime: float
var age: float = 0.0
var size: float
var shape: Shape = Shape.CIRCLE
var rotation: float = 0.0
var spin_speed: float = 0.0
var gravity_mult: float = 1.0
var ground_y: float = -1.0
var bounce_damping: float = 0.5
var streak_length: float = 8.0
# AAA Upgrade: Enhanced particle features
var has_collision: bool = false  # Enable world collision
var color_end: Color = Color.WHITE  # Color to fade to over lifetime
# AAA Visual Overhaul: Texture-based rendering
var texture: Texture2D = null  # Optional texture for TEXTURED shape
var scale_curve: float = 0.5  # How much size shrinks over lifetime (0=none, 1=full)
var is_sub_emitter: bool = false  # Secondary particle (e.g. smoke from death burst)
var sub_emit_timer: float = 0.0  # Timer for delayed sub-emitter spawn

# Static texture cache (loaded once)
static var _circle_tex: Texture2D = null
static var _streak_tex: Texture2D = null
static var _spark_tex: Texture2D = null
static var _smoke_tex: Texture2D = null
static var _textures_attempted: bool = false

static func _load_particle_textures():
	if _textures_attempted:
		return
	_textures_attempted = true
	if ResourceLoader.exists("res://assets/textures/particle_circle.png"):
		_circle_tex = load("res://assets/textures/particle_circle.png")
	if ResourceLoader.exists("res://assets/textures/particle_streak.png"):
		_streak_tex = load("res://assets/textures/particle_streak.png")
	if ResourceLoader.exists("res://assets/textures/particle_spark.png"):
		_spark_tex = load("res://assets/textures/particle_spark.png")
	if ResourceLoader.exists("res://assets/textures/particle_smoke.png"):
		_smoke_tex = load("res://assets/textures/particle_smoke.png")

func _init(px: float, py: float, pvx: float, pvy: float, pcol: Color, plifetime: float, psize: int = 4):
	x = px
	y = py
	vx = pvx
	vy = pvy
	color = pcol
	lifetime = plifetime
	size = float(psize)

func update(dt: float):
	# AAA Visual Overhaul: Handle sub-emitter delayed spawn
	if is_sub_emitter and sub_emit_timer > 0:
		sub_emit_timer -= dt
		if sub_emit_timer > 0:
			return  # Don't update until spawn delay expires

	x += vx * dt
	y += vy * dt
	vy += 400.0 * gravity_mult * dt
	vx *= (1.0 - 2.0 * dt)
	rotation += spin_speed * dt
	age += dt

	# AAA Upgrade: Particle-to-world collision (bounce off ground)
	if has_collision and ground_y > 0 and y > ground_y:
		y = ground_y
		vy = -abs(vy) * bounce_damping
		vx *= 0.7
	elif ground_y > 0 and y > ground_y:
		y = ground_y
		vy = -abs(vy) * bounce_damping
		vx *= 0.7

func draw_particle(canvas: CanvasItem):
	if age >= lifetime:
		return
	var t = age / lifetime
	var alpha = 1.0 - t * t
	# AAA Visual Overhaul: Scale curve support
	var size_decay = lerpf(0.5, 1.0, 1.0 - scale_curve)
	var current_size = maxf(1.0, size * lerpf(1.0, size_decay, t))

	# AAA Upgrade: Color shift over lifetime (fade to darker hue)
	var interpolated_color = color.lerp(color_end, t * 0.6) if color_end != Color.WHITE else color
	var current_color = Color(interpolated_color.r, interpolated_color.g, interpolated_color.b, alpha * 0.9)
	var pos = Vector2(x, y)

	# AAA Visual Overhaul: TEXTURED shape - use texture if available
	if shape == Shape.TEXTURED and texture != null:
		var tex_size = Vector2(texture.get_width(), texture.get_height()) * (current_size / maxf(texture.get_width(), texture.get_height()))
		canvas.draw_set_transform(pos, rotation, Vector2.ONE)
		canvas.draw_texture_rect(texture, Rect2(-tex_size * 0.5, tex_size), current_color)
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return

	match shape:
		Shape.CIRCLE:
			canvas.draw_circle(pos, current_size, current_color)
			if current_size > 2.5:
				canvas.draw_circle(pos, current_size * 0.35, Color(1, 1, 1, alpha * 0.4))
		Shape.SQUARE:
			var half = current_size
			canvas.draw_set_transform(pos, rotation, Vector2.ONE)
			canvas.draw_rect(Rect2(-half, -half, half * 2, half * 2), current_color)
			canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		Shape.STREAK:
			var speed = Vector2(vx, vy).length()
			var dir = Vector2(vx, vy).normalized() if speed > 1.0 else Vector2.RIGHT
			# AAA Upgrade: Velocity-based motion blur (faster = longer streak)
			var speed_mult = clampf(speed / 200.0, 1.0, 2.5)
			var length = clampf(speed * 0.04 * speed_mult, 3.0, streak_length * (1.0 - t))
			var end_pos = pos - dir * length
			canvas.draw_line(pos, end_pos, current_color, maxf(1.0, current_size * 0.6))
			canvas.draw_circle(pos, current_size * 0.4, Color(1, 1, 1, alpha * 0.35))
		Shape.SPARK:
			# AAA Upgrade: Jagged spark with multiple segments
			var speed = Vector2(vx, vy).length()
			var dir = Vector2(vx, vy).normalized() if speed > 1.0 else Vector2.RIGHT
			var seg_count = 3
			var seg_len = current_size * 2.0
			var prev = pos
			for i in range(seg_count):
				var offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
				var next = prev - dir * seg_len + offset
				canvas.draw_line(prev, next, current_color, 1.5)
				prev = next
		Shape.GLOW:
			# AAA Upgrade: Soft glow with multiple radii
			var glow_alpha = alpha * 0.15
			canvas.draw_circle(pos, current_size * 2.5, Color(current_color.r, current_color.g, current_color.b, glow_alpha))
			canvas.draw_circle(pos, current_size * 1.5, Color(current_color.r, current_color.g, current_color.b, glow_alpha * 2))
			canvas.draw_circle(pos, current_size, current_color)
		Shape.SMOKE_PUFF:
			# AAA Visual Overhaul: Expanding smoke puff with soft edges
			var expand = 1.0 + t * 1.5  # Grows to 2.5x size
			var smoke_alpha = alpha * (1.0 - t * 0.7)
			var smoke_col = Color(current_color.r, current_color.g, current_color.b, smoke_alpha * 0.3)
			canvas.draw_circle(pos, current_size * expand * 1.8, smoke_col)
			canvas.draw_circle(pos, current_size * expand * 1.2, Color(smoke_col.r, smoke_col.g, smoke_col.b, smoke_alpha * 0.5))
			canvas.draw_circle(pos, current_size * expand * 0.6, Color(smoke_col.r, smoke_col.g, smoke_col.b, smoke_alpha * 0.7))

func is_alive() -> bool:
	return age < lifetime
