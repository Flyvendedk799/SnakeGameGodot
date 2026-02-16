class_name TrailRenderer
extends Node2D

## AAA Visual Overhaul: GPU ribbon trail rendering
## Dash trails, weapon swings, motion blur ribbons

enum TrailType { DASH, WEAPON_SWING, MOTION_BLUR, GRAPPLE }

var trail_type: TrailType = TrailType.DASH
var points: Array = []  # Array of Vector2
var colors: Array = []  # Array of Color per point
var widths: Array = []  # Array of float per point
var max_points: int = 20
var lifetime: float = 0.3
var age: float = 0.0
var active: bool = false

# Visual settings
var base_width: float = 8.0
var base_color: Color = Color(0.8, 0.9, 1.0, 0.6)
var gradient_end_color: Color = Color(0.4, 0.6, 0.9, 0.0)
var width_taper: float = 0.7  # How much width shrinks from base to tip

func setup(type: TrailType = TrailType.DASH, max_pts: int = 20, life: float = 0.3):
	trail_type = type
	max_points = max_pts
	lifetime = life
	active = false
	points.clear()
	colors.clear()
	widths.clear()

	# Configure based on type
	match trail_type:
		TrailType.DASH:
			base_width = 12.0
			base_color = Color(0.7, 0.85, 1.0, 0.5)
			gradient_end_color = Color(0.3, 0.5, 0.8, 0.0)
			width_taper = 0.6
		TrailType.WEAPON_SWING:
			base_width = 6.0
			base_color = Color(1.0, 0.9, 0.7, 0.7)
			gradient_end_color = Color(0.9, 0.5, 0.3, 0.0)
			width_taper = 0.4
		TrailType.MOTION_BLUR:
			base_width = 8.0
			base_color = Color(1.0, 1.0, 1.0, 0.3)
			gradient_end_color = Color(0.8, 0.8, 0.8, 0.0)
			width_taper = 0.8
		TrailType.GRAPPLE:
			base_width = 4.0
			base_color = Color(0.5, 0.9, 1.0, 0.6)
			gradient_end_color = Color(0.2, 0.6, 0.9, 0.0)
			width_taper = 0.5

func start_trail(start_pos: Vector2):
	"""Begin recording trail from starting position."""
	active = true
	age = 0.0
	points.clear()
	colors.clear()
	widths.clear()
	add_point(start_pos)

func add_point(pos: Vector2):
	"""Add a new point to the trail."""
	if not active:
		return
	points.append(pos)
	colors.append(base_color)
	widths.append(base_width)
	if points.size() > max_points:
		points.pop_front()
		colors.pop_front()
		widths.pop_front()

func stop_trail():
	"""Stop recording new points (trail will fade out)."""
	active = false

func update_trail(delta: float):
	"""Update trail decay and cleanup."""
	if not active:
		age += delta
		if age > lifetime:
			points.clear()
			colors.clear()
			widths.clear()
			return

	# Update colors and widths for fade-out
	var point_count = points.size()
	if point_count == 0:
		return

	for i in range(point_count):
		var t = float(i) / float(max(point_count - 1, 1))  # 0 at oldest, 1 at newest
		var decay = 1.0 if active else (1.0 - (age / lifetime))

		# Gradient from base_color (newest) to gradient_end_color (oldest)
		colors[i] = base_color.lerp(gradient_end_color, 1.0 - t) * decay

		# Width taper from base (newest) to narrow (oldest)
		widths[i] = base_width * lerpf(width_taper, 1.0, t) * decay

	queue_redraw()

func _draw():
	"""Render trail as ribbon using draw_polyline."""
	if points.size() < 2:
		return

	# Draw ribbon using antialiased polyline with varying width
	# Godot doesn't support per-vertex width, so we layer multiple polylines
	var layer_count = 3
	for layer in range(layer_count):
		var layer_t = float(layer) / float(layer_count)
		var layer_alpha = 1.0 - layer_t * 0.6
		var layer_points = []

		for i in range(points.size()):
			layer_points.append(points[i])

		# Draw with averaged color and width
		if layer_points.size() >= 2:
			var avg_color = Color(0, 0, 0, 0)
			var avg_width = 0.0
			for i in range(colors.size()):
				avg_color += colors[i]
				avg_width += widths[i]
			if colors.size() > 0:
				avg_color /= float(colors.size())
				avg_width /= float(widths.size())

			avg_color.a *= layer_alpha
			var width = avg_width * (1.0 - layer_t * 0.4)
			draw_polyline(layer_points, avg_color, width, true)

	# Draw glow layer for DASH and GRAPPLE types
	if trail_type == TrailType.DASH or trail_type == TrailType.GRAPPLE:
		if points.size() >= 2:
			var glow_col = base_color
			glow_col.a *= 0.15
			draw_polyline(points, glow_col, base_width * 2.0, true)

func is_alive() -> bool:
	"""Check if trail is still rendering."""
	return active or age < lifetime

func clear():
	"""Immediately clear trail."""
	active = false
	points.clear()
	colors.clear()
	widths.clear()
	age = lifetime
