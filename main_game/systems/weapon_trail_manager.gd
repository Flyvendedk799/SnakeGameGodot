class_name WeaponTrailManager
extends Node

## AAA Visual Overhaul Phase 8: Weapon swing trail coordination
## Manages weapon trails for player combat (combo attacks)

var game = null
var active_trails: Array = []  # Array of TrailRenderer instances
const MAX_TRAILS = 3

func setup(game_ref):
	"""Initialize with game reference."""
	game = game_ref

func spawn_weapon_trail(start_pos: Vector2, end_pos: Vector2, combo_index: int = 0):
	"""Create weapon swing trail from start to end position."""
	# Clean up old trails
	_cleanup_dead_trails()

	# Create new trail
	var trail = TrailRenderer.new()
	trail.setup(TrailRenderer.TrailType.WEAPON_SWING, 12, 0.25)

	# Customize color based on combo index
	match combo_index:
		0:  # First hit - white/silver
			trail.base_color = Color(0.95, 0.95, 1.0, 0.6)
			trail.gradient_end_color = Color(0.7, 0.7, 0.8, 0.0)
		1:  # Second hit - blue
			trail.base_color = Color(0.6, 0.8, 1.0, 0.7)
			trail.gradient_end_color = Color(0.3, 0.5, 0.9, 0.0)
		2:  # Third hit (finisher) - orange/yellow
			trail.base_color = Color(1.0, 0.8, 0.4, 0.8)
			trail.gradient_end_color = Color(0.9, 0.5, 0.2, 0.0)
			trail.base_width = 8.0  # Thicker for finisher

	trail.start_trail(start_pos)

	# Sample points along arc for smooth trail
	var point_count = 8
	for i in range(point_count + 1):
		var t = float(i) / float(point_count)
		var pos = start_pos.lerp(end_pos, t)
		# Add slight arc (parabolic path)
		var arc_height = 15.0 * sin(t * PI)
		var dir = (end_pos - start_pos).normalized()
		var perp = Vector2(-dir.y, dir.x)
		pos += perp * arc_height
		trail.add_point(pos)

	trail.stop_trail()

	if game and game.game_layer:
		game.game_layer.add_child(trail)
		active_trails.append(trail)

	# Enforce trail limit
	if active_trails.size() > MAX_TRAILS:
		var old = active_trails.pop_front()
		if is_instance_valid(old):
			old.queue_free()

func update(delta: float):
	"""Update all active trails."""
	for trail in active_trails:
		if is_instance_valid(trail):
			trail.update_trail(delta)

func _cleanup_dead_trails():
	"""Remove trails that have finished."""
	var alive = []
	for trail in active_trails:
		if is_instance_valid(trail) and trail.is_alive():
			alive.append(trail)
		elif is_instance_valid(trail):
			trail.queue_free()
	active_trails = alive

func clear_all():
	"""Immediately clear all trails."""
	for trail in active_trails:
		if is_instance_valid(trail):
			trail.queue_free()
	active_trails.clear()
