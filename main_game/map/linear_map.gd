class_name LinearMap
extends Node2D

var game = null
var level_config: Dictionary = {}
var level_width: float = 2400
var level_height: float = 720

# Compatibility with FortMap (for player.gd)
var SCREEN_W: float = 2400
var SCREEN_H: float = 720
var FORT_LEFT: float = 0
var FORT_RIGHT: float = 2400
var FORT_TOP: float = 0
var FORT_BOTTOM: float = 720
var keep_left: float = 0
var keep_right: float = 2400
var keep_top: float = 0
var keep_bottom: float = 720
var barricades: Array = []
var doors: Array = []
var entrance_positions: Array[Vector2] = []
var keep_entrance_positions: Array[Vector2] = []

# Collision
var floor_rects: Array[Rect2] = []
var wall_rects: Array[Rect2] = []
var platform_rects: Array[Rect2] = []
var obstacle_rects: Array[Rect2] = []

# Checkpoints and goal
var checkpoints: Array = []
var goal_rect: Rect2 = Rect2.ZERO
var checkpoint_rects: Array[Rect2] = []

# Waypoints for pathfinding (platform corners, ramp positions, etc.)
var waypoints: Array[Vector2] = []

# Visual
var anim_time: float = 0.0
var bg_tint: Color = Color(1.0, 1.0, 1.0)
var bg_texture: Texture2D = null

# Alias for HUD/shop compatibility
var map_config: Dictionary:
	get: return level_config

func setup(game_ref, level_id: int):
	game = game_ref
	level_config = LinearMapConfig.get_level(level_id)
	level_width = float(level_config.get("width", 2400))
	level_height = float(level_config.get("height", 720))
	SCREEN_W = level_width
	SCREEN_H = level_height
	FORT_LEFT = 0
	FORT_RIGHT = level_width
	FORT_TOP = 0
	FORT_BOTTOM = level_height
	keep_left = level_width * 0.2
	keep_right = level_width * 0.8
	keep_top = level_height * 0.2
	keep_bottom = level_height * 0.8
	entrance_positions = [Vector2(level_width * 0.5, 0), Vector2(level_width, level_height * 0.5), Vector2(level_width * 0.5, level_height), Vector2(0, level_height * 0.5)]
	keep_entrance_positions = [Vector2(keep_left, keep_top), Vector2(keep_right, keep_top), Vector2(keep_left, keep_bottom), Vector2(keep_right, keep_bottom)]

	_build_collision()
	_build_checkpoints()
	_build_waypoints()
	
	var tex_path = level_config.get("bg_texture_path", "")
	if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
		bg_texture = load(tex_path)
	else:
		bg_texture = null
	bg_tint = Color(1.0, 1.0, 1.0)
	queue_redraw()

func _build_collision():
	floor_rects.clear()
	wall_rects.clear()
	platform_rects.clear()
	obstacle_rects.clear()
	
	var layers = level_config.get("layers", [])
	
	for layer in layers:
		var layer_id = layer.get("id", "surface")
		var y_min = float(layer.get("y_min", 280))
		var y_max = float(layer.get("y_max", 420))
		var layer_type = layer.get("type", "ground")
		
		if layer_type == "ground" or layer_type == "cave":
			floor_rects.append(Rect2(0, y_min, level_width, y_max - y_min))
		elif layer_type == "platform" or layer_type == "skybridge":
			var platform_height = 20.0
			var step = 400.0
			var x = 0.0
			while x < level_width:
				platform_rects.append(Rect2(x, y_max - platform_height, minf(step, level_width - x), platform_height))
				x += step
	
	# Walls: left, right, top, bottom
	var wall_w = 50.0
	wall_rects.append(Rect2(-wall_w, -wall_w, wall_w, level_height + wall_w * 2))
	wall_rects.append(Rect2(level_width, -wall_w, wall_w, level_height + wall_w * 2))
	wall_rects.append(Rect2(-wall_w, -wall_w, level_width + wall_w * 2, wall_w))
	wall_rects.append(Rect2(-wall_w, level_height, level_width + wall_w * 2, wall_w))

func _build_checkpoints():
	checkpoints = level_config.get("checkpoints", [])
	checkpoint_rects.clear()
	for cp in checkpoints:
		var r = cp.get("rect", Rect2(0, 0, 100, 120))
		checkpoint_rects.append(r)
	goal_rect = level_config.get("goal_rect", Rect2(level_width - 50, 250, 50, 220))

func _build_waypoints():
	waypoints.clear()
	for cp in checkpoints:
		waypoints.append(Vector2(cp.get("x", 0), cp.get("y", 350)))
	waypoints.append(Vector2(level_width / 2.0, level_height / 2.0))
	waypoints.append(goal_rect.position + goal_rect.size / 2.0)

func get_player_anchor() -> Vector2:
	if game == null:
		return Vector2(level_width / 2.0, level_height / 2.0)
	var p = game.player_node
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		var mid = (p.position + game.player2_node.position) * 0.5
		var rightmost = p.position.x if p.position.x > game.player2_node.position.x else game.player2_node.position.x
		return Vector2(rightmost - 60, mid.y)
	if p.is_dead:
		return p.position
	var move_right = p.last_move_dir.x > 0.1
	var offset = Vector2(60, 0) if move_right else Vector2(-60, 0)
	return p.position + offset

func get_navigation_waypoints() -> Array[Vector2]:
	return waypoints

func is_in_goal(pos: Vector2) -> bool:
	return goal_rect.has_point(pos)

func get_checkpoint_index_at(pos: Vector2) -> int:
	for i in range(checkpoint_rects.size()):
		if checkpoint_rects[i].has_point(pos):
			return i
	return -1

func get_checkpoint_position(index: int) -> Vector2:
	if index >= 0 and index < checkpoints.size():
		var cp = checkpoints[index]
		return Vector2(cp.get("x", 0), cp.get("y", 350))
	return Vector2.ZERO

func resolve_collision(pos: Vector2, radius: float) -> Vector2:
	for rect in wall_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	for rect in floor_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	for rect in platform_rects:
		if pos.y + radius > rect.position.y and pos.y - radius < rect.position.y + rect.size.y:
			pos = _push_out_of_rect(pos, radius, rect)
	for rect in obstacle_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	return pos

func _push_out_of_rect(pos: Vector2, radius: float, rect: Rect2) -> Vector2:
	var closest_x = clampf(pos.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clampf(pos.y, rect.position.y, rect.position.y + rect.size.y)
	var diff = pos - Vector2(closest_x, closest_y)
	var dist = diff.length()
	if dist < radius and dist > 0.001:
		pos = Vector2(closest_x, closest_y) + diff.normalized() * radius
	elif dist < 0.001:
		var to_left = pos.x - rect.position.x
		var to_right = rect.position.x + rect.size.x - pos.x
		var to_top = pos.y - rect.position.y
		var to_bottom = rect.position.y + rect.size.y - pos.y
		var min_d = minf(minf(to_left, to_right), minf(to_top, to_bottom))
		if min_d == to_left:
			pos.x = rect.position.x - radius
		elif min_d == to_right:
			pos.x = rect.position.x + rect.size.x + radius
		elif min_d == to_top:
			pos.y = rect.position.y - radius
		else:
			pos.y = rect.position.y + rect.size.y + radius
	return pos

func is_line_walkable(from_pos: Vector2, to_pos: Vector2, radius: float = 10.0) -> bool:
	var dist = from_pos.distance_to(to_pos)
	if dist <= 1.0:
		return true
	var steps = int(ceil(dist / 22.0))
	for i in range(steps + 1):
		var t = float(i) / float(maxi(steps, 1))
		var sample = from_pos.lerp(to_pos, t)
		var resolved = resolve_collision(sample, radius)
		if resolved.distance_to(sample) > 0.75:
			return false
	return true

func get_nearest_barricade_in_range(_pos: Vector2, _range_dist: float):
	return null

func get_nearest_door_in_range(_pos: Vector2, _range_dist: float):
	return null

func get_outside_ally_position(player_index: int) -> Vector2:
	var anchor = get_player_anchor()
	if player_index == 1:
		return anchor + Vector2(-60, 60)
	return anchor + Vector2(-60, -60)

func get_random_spawn_in_zone(zone: Dictionary) -> Vector2:
	var x_min = float(zone.get("x_min", 0))
	var x_max = float(zone.get("x_max", 100))
	var y_min = float(zone.get("y_min", 300))
	var y_max = float(zone.get("y_max", 420))
	var x = randf_range(x_min, x_max)
	var y = randf_range(y_min, y_max)
	return Vector2(x, y)

func get_zone_gold_mult(pos: Vector2) -> float:
	var segments = level_config.get("segments", [])
	for seg in segments:
		for zone in seg.get("spawn_zones", []):
			var mult = zone.get("gold_multiplier", 1.0)
			if mult <= 1.0:
				continue
			var x_min = float(zone.get("x_min", 0))
			var x_max = float(zone.get("x_max", 0))
			var y_min = float(zone.get("y_min", 0))
			var y_max = float(zone.get("y_max", 720))
			if pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max:
				return mult
	return 1.0

func _draw():
	if bg_texture:
		var tex_size = bg_texture.get_size()
		var sx = level_width / tex_size.x
		var sy = level_height / tex_size.y
		draw_set_transform(Vector2.ZERO, 0, Vector2(sx, sy))
		draw_texture(bg_texture, Vector2.ZERO, bg_tint)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_rect(Rect2(0, 0, level_width, level_height), Color8(52, 90, 40))
	
	# Floor
	for rect in floor_rects:
		draw_rect(rect, Color8(85, 70, 50, 180))
	
	# Platforms
	for rect in platform_rects:
		draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x, rect.size.y), Color8(60, 50, 40))
		draw_rect(rect, Color8(120, 95, 70))
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 4), Color8(145, 115, 85))
	
	# Checkpoint markers
	var font = ThemeDB.fallback_font
	for i in range(checkpoints.size()):
		var cp = checkpoints[i]
		var cx = cp.get("x", 0)
		var cy = cp.get("y", 350)
		draw_rect(Rect2(cx - 30, cy - 40, 60, 80), Color8(100, 180, 120, 100))
		draw_rect(Rect2(cx - 30, cy - 40, 60, 80), Color8(80, 200, 100), false, 2.0)
		draw_string(font, Vector2(cx - 10, cy + 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 20, 14, Color.WHITE)
	
	# Goal
	draw_rect(goal_rect, Color8(255, 200, 50, 150))
	draw_rect(goal_rect, Color8(255, 220, 80), false, 3.0)
	draw_string(font, goal_rect.position + Vector2(goal_rect.size.x / 2 - 15, goal_rect.size.y / 2 + 5), "GOAL", HORIZONTAL_ALIGNMENT_CENTER, 30, 16, Color.WHITE)
	
	# Grid
	var grid_spacing = 80.0
	var grid_col = Color8(120, 100, 75, 20)
	var gx = 0.0
	while gx <= level_width:
		draw_line(Vector2(gx, 0), Vector2(gx, level_height), grid_col, 0.5)
		gx += grid_spacing
	var gy = 0.0
	while gy <= level_height:
		draw_line(Vector2(0, gy), Vector2(level_width, gy), grid_col, 0.5)
		gy += grid_spacing
