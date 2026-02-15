class_name FortMap
extends Node2D

var SCREEN_W: float = 1280.0
var SCREEN_H: float = 720.0

# Fort dimensions - centered, with room for spawns outside
var FORT_LEFT: float = 290.0
var FORT_RIGHT: float = 990.0
var FORT_TOP: float = 120.0
var FORT_BOTTOM: float = 600.0
const WALL_THICKNESS = 22.0
const ENTRANCE_WIDTH = 70.0

var map_scale: float = 1.0

# Inner keep (compartmentalization)
const KEEP_INSET = 0.22  # Keep starts 22% inset from each fort edge
var keep_left: float = 0.0
var keep_right: float = 0.0
var keep_top: float = 0.0
var keep_bottom: float = 0.0
var keep_wall_rects: Array[Rect2] = []
var keep_entrance_positions: Array[Vector2] = []
var doors: Array = []

# Maze corridor system
var corridor_wall_rects: Array[Rect2] = []
var maze_door_defs: Array = []  # [{pos: Vector2, is_vertical: bool}, ...]
var ring_left: float = 0.0
var ring_right: float = 0.0
var ring_top: float = 0.0
var ring_bottom: float = 0.0

# Spawn distance from fort walls (fixed, doesn't grow with scale)
const SPAWN_MARGIN = 220.0

# Colors
const GRASS_DARK = Color8(52, 90, 40)
const GRASS_LIGHT = Color8(62, 105, 48)
const DIRT_DARK = Color8(85, 70, 50)
const DIRT_LIGHT = Color8(100, 82, 58)
const WALL_FILL = Color8(120, 95, 70)
const WALL_TOP = Color8(145, 115, 85)
const WALL_SHADOW = Color8(70, 55, 40)
const PATH_COLOR = Color8(110, 95, 65, 180)
const KEEP_WALL_FILL = Color8(100, 80, 60)
const KEEP_WALL_TOP = Color8(130, 105, 80)
const KEEP_WALL_SHADOW = Color8(50, 40, 30)
const KEEP_FLOOR = Color8(65, 55, 40, 160)

var entrance_positions: Array[Vector2] = []
var barricades: Array = []
var spawn_points: Array[Vector2] = []
var wall_rects: Array[Rect2] = []
var obstacle_rects: Array[Rect2] = []
var bg_texture: Texture2D = null
var bg_tint: Color = Color(1.0, 1.0, 1.0)
var map_config: Dictionary = {}
var anim_time: float = 0.0

func setup(game, map_id: int = 1):
	map_config = MapConfig.get_map_config(map_id)
	var tex_path = map_config.get("bg_texture_path", "res://assets/Map1.png")
	if ResourceLoader.exists(tex_path):
		bg_texture = load(tex_path)
	else:
		bg_texture = null
	bg_tint = map_config.get("bg_tint", Color(1.0, 1.0, 1.0))

	# Apply initial scale (sets all dimensions before entity creation)
	var initial_scale = map_config.get("initial_scale", 1.0)
	_apply_dimensions(initial_scale)

	# Create barricades at outer entrances
	var barricade_container = game.barricade_container
	for i in range(4):
		var b = BarricadeEntity.new()
		b.position = entrance_positions[i]
		if i == 1 or i == 3:
			b.is_vertical = true
		barricades.append(b)
		barricade_container.add_child(b)

	# Create inner keep doors
	_create_doors(game)

func load_map_config(map_id: int):
	map_config = MapConfig.get_map_config(map_id)
	var tex_path = map_config.get("bg_texture_path", "res://assets/Map1.png")
	if ResourceLoader.exists(tex_path):
		bg_texture = load(tex_path)
	else:
		bg_texture = null
	bg_tint = map_config.get("bg_tint", Color(1.0, 1.0, 1.0))
	_rebuild_obstacles()
	queue_redraw()

func _apply_dimensions(new_scale: float):
	"""Recalculate all world/fort/keep dimensions for a given scale."""
	map_scale = new_scale
	SCREEN_W = 1280.0 * new_scale
	SCREEN_H = 720.0 * new_scale

	var cx = SCREEN_W / 2.0
	var cy = SCREEN_H / 2.0
	var fort_w = 700.0 * new_scale
	var fort_h = 480.0 * new_scale
	FORT_LEFT = cx - fort_w / 2.0
	FORT_RIGHT = cx + fort_w / 2.0
	FORT_TOP = cy - fort_h / 2.0
	FORT_BOTTOM = cy + fort_h / 2.0

	# Outer entrance positions
	entrance_positions = [
		Vector2(cx, FORT_TOP),
		Vector2(FORT_RIGHT, cy),
		Vector2(cx, FORT_BOTTOM),
		Vector2(FORT_LEFT, cy),
	]

	# Spawn points: fixed distance from fort walls (not at world edges)
	spawn_points = [
		Vector2(cx, FORT_TOP - SPAWN_MARGIN),
		Vector2(FORT_RIGHT + SPAWN_MARGIN, cy),
		Vector2(cx, FORT_BOTTOM + SPAWN_MARGIN),
		Vector2(FORT_LEFT - SPAWN_MARGIN, cy),
	]

	# Outer wall collision rects
	var he = ENTRANCE_WIDTH / 2.0
	var wt = WALL_THICKNESS
	wall_rects = [
		# Top wall segments
		Rect2(FORT_LEFT - wt, FORT_TOP - wt, cx - he - FORT_LEFT + wt, wt),
		Rect2(cx + he, FORT_TOP - wt, FORT_RIGHT + wt - cx - he, wt),
		# Bottom wall segments
		Rect2(FORT_LEFT - wt, FORT_BOTTOM, cx - he - FORT_LEFT + wt, wt),
		Rect2(cx + he, FORT_BOTTOM, FORT_RIGHT + wt - cx - he, wt),
		# Left wall segments
		Rect2(FORT_LEFT - wt, FORT_TOP - wt, wt, cy - he - FORT_TOP + wt),
		Rect2(FORT_LEFT - wt, cy + he, wt, FORT_BOTTOM + wt - cy - he),
		# Right wall segments
		Rect2(FORT_RIGHT, FORT_TOP - wt, wt, cy - he - FORT_TOP + wt),
		Rect2(FORT_RIGHT, cy + he, wt, FORT_BOTTOM + wt - cy - he),
	]

	# Inner keep dimensions
	keep_left = FORT_LEFT + fort_w * KEEP_INSET
	keep_right = FORT_RIGHT - fort_w * KEEP_INSET
	keep_top = FORT_TOP + fort_h * KEEP_INSET
	keep_bottom = FORT_BOTTOM - fort_h * KEEP_INSET

	# Keep entrance positions (for doors) — aligned with outer entrances
	keep_entrance_positions = [
		Vector2(cx, keep_top),       # North keep door
		Vector2(keep_right, cy),     # East keep door
		Vector2(cx, keep_bottom),    # South keep door
		Vector2(keep_left, cy),      # West keep door
	]

	# Inner keep wall rects (8 segments with gaps for door openings)
	keep_wall_rects = [
		# Top wall segments
		Rect2(keep_left - wt, keep_top - wt, cx - he - keep_left + wt, wt),
		Rect2(cx + he, keep_top - wt, keep_right + wt - cx - he, wt),
		# Bottom wall segments
		Rect2(keep_left - wt, keep_bottom, cx - he - keep_left + wt, wt),
		Rect2(cx + he, keep_bottom, keep_right + wt - cx - he, wt),
		# Left wall segments
		Rect2(keep_left - wt, keep_top - wt, wt, cy - he - keep_top + wt),
		Rect2(keep_left - wt, cy + he, wt, keep_bottom + wt - cy - he),
		# Right wall segments
		Rect2(keep_right, keep_top - wt, wt, cy - he - keep_top + wt),
		Rect2(keep_right, cy + he, wt, keep_bottom + wt - cy - he),
	]

	# Maze ring (midpoint between outer wall and keep on each side)
	ring_left = (FORT_LEFT + keep_left) / 2.0
	ring_right = (FORT_RIGHT + keep_right) / 2.0
	ring_top = (FORT_TOP + keep_top) / 2.0
	ring_bottom = (FORT_BOTTOM + keep_bottom) / 2.0

	# Build maze corridor walls and door positions
	_build_maze()

	# Reposition existing barricades
	for i in range(barricades.size()):
		barricades[i].position = entrance_positions[i]

	# Reposition existing doors (keep + maze)
	for i in range(doors.size()):
		if i < 4:
			if i < keep_entrance_positions.size():
				doors[i].position = keep_entrance_positions[i]
		else:
			var mi = i - 4
			if mi < maze_door_defs.size():
				doors[i].position = maze_door_defs[mi].pos
				doors[i].is_vertical = maze_door_defs[mi].is_vertical

	_rebuild_obstacles()
	queue_redraw()

func expand(new_scale: float):
	_apply_dimensions(new_scale)

func _create_doors(game):
	if not game.door_container:
		return
	# Keep doors (4 at inner keep entrances)
	for i in range(4):
		var d = DoorEntity.new()
		d.position = keep_entrance_positions[i]
		d.is_vertical = (i == 1 or i == 3)
		d.door_index = i
		doors.append(d)
		game.door_container.add_child(d)
	# Maze corridor doors
	for i in range(maze_door_defs.size()):
		var d = DoorEntity.new()
		d.position = maze_door_defs[i].pos
		d.is_vertical = maze_door_defs[i].is_vertical
		d.door_index = 4 + i
		doors.append(d)
		game.door_container.add_child(d)

func _rebuild_obstacles():
	var fort_w = FORT_RIGHT - FORT_LEFT
	var fort_h = FORT_BOTTOM - FORT_TOP
	obstacle_rects.clear()
	for r in MapConfig.obstacles_to_rects(
		map_config.get("obstacles", []),
		FORT_LEFT, FORT_TOP, fort_w, fort_h
	):
		obstacle_rects.append(r)

func _build_maze():
	"""Generate internal corridor walls and door positions for the maze layout."""
	corridor_wall_rects.clear()
	maze_door_defs.clear()

	var cx = (FORT_LEFT + FORT_RIGHT) / 2.0
	var cy = (FORT_TOP + FORT_BOTTOM) / 2.0
	var wt = WALL_THICKNESS
	var fort_w = FORT_RIGHT - FORT_LEFT
	var fort_h = FORT_BOTTOM - FORT_TOP

	# Gap offset for zigzag paths (doors aren't aligned, forcing weaving)
	var offset_x = fort_w * 0.06
	var offset_y = fort_h * 0.06

	# === RING WALLS (primary maze boundary between outer courtyard and inner area) ===
	_maze_wall_h(ring_left, ring_right, ring_top, cx + offset_x)
	_maze_wall_h(ring_left, ring_right, ring_bottom, cx - offset_x)
	_maze_wall_v(ring_top, ring_bottom, ring_left, cy - offset_y)
	_maze_wall_v(ring_top, ring_bottom, ring_right, cy + offset_y)

	# === OUTER CORRIDOR GATES (between outer entrances and ring) ===
	var n_gate_y = (FORT_TOP + ring_top) / 2.0
	var s_gate_y = (ring_bottom + FORT_BOTTOM) / 2.0
	var w_gate_x = (FORT_LEFT + ring_left) / 2.0
	var e_gate_x = (ring_right + FORT_RIGHT) / 2.0

	# Gates extend slightly beyond ring to close off easy corner bypasses
	_maze_wall_h(ring_left - wt, ring_right + wt, n_gate_y, cx)
	_maze_wall_h(ring_left - wt, ring_right + wt, s_gate_y, cx)
	_maze_wall_v(ring_top - wt, ring_bottom + wt, w_gate_x, cy)
	_maze_wall_v(ring_top - wt, ring_bottom + wt, e_gate_x, cy)

	# === INNER GATES (between ring interior and keep) ===
	var wi_x = (ring_left + keep_left) / 2.0
	var ei_x = (keep_right + ring_right) / 2.0
	var ni_y = (ring_top + keep_top) / 2.0
	var si_y = (keep_bottom + ring_bottom) / 2.0

	# Gaps offset opposite to ring gaps for maximum zigzag
	_maze_wall_h(wi_x, ei_x, ni_y, cx - offset_x * 0.5)
	_maze_wall_h(wi_x, ei_x, si_y, cx + offset_x * 0.5)
	_maze_wall_v(ni_y, si_y, wi_x, cy + offset_y * 0.5)
	_maze_wall_v(ni_y, si_y, ei_x, cy - offset_y * 0.5)

	# === CORNER ROOM PARTIAL WALLS (no doors, just barriers for cover/routing) ===
	var corner_ext_x = (ring_left - FORT_LEFT) * 0.45
	var corner_ext_y = (ring_top - FORT_TOP) * 0.45

	# Horizontal stubs from outer wall into corner rooms (at gate Y positions)
	corridor_wall_rects.append(Rect2(FORT_LEFT, n_gate_y - wt / 2.0, corner_ext_x, wt))
	corridor_wall_rects.append(Rect2(FORT_RIGHT - corner_ext_x, n_gate_y - wt / 2.0, corner_ext_x, wt))
	corridor_wall_rects.append(Rect2(FORT_LEFT, s_gate_y - wt / 2.0, corner_ext_x, wt))
	corridor_wall_rects.append(Rect2(FORT_RIGHT - corner_ext_x, s_gate_y - wt / 2.0, corner_ext_x, wt))

	# Vertical stubs from outer wall into corner rooms (at gate X positions)
	corridor_wall_rects.append(Rect2(w_gate_x - wt / 2.0, FORT_TOP, wt, corner_ext_y))
	corridor_wall_rects.append(Rect2(e_gate_x - wt / 2.0, FORT_TOP, wt, corner_ext_y))
	corridor_wall_rects.append(Rect2(w_gate_x - wt / 2.0, FORT_BOTTOM - corner_ext_y, wt, corner_ext_y))
	corridor_wall_rects.append(Rect2(e_gate_x - wt / 2.0, FORT_BOTTOM - corner_ext_y, wt, corner_ext_y))

func _maze_wall_h(x_start: float, x_end: float, y: float, gap_x: float):
	"""Add a horizontal maze wall with a doorway gap. Creates wall rects and a door def."""
	var wt = WALL_THICKNESS
	var he = ENTRANCE_WIDTH / 2.0
	var left_end = gap_x - he
	var right_start = gap_x + he
	if left_end > x_start + 1:
		corridor_wall_rects.append(Rect2(x_start, y - wt / 2.0, left_end - x_start, wt))
	if x_end > right_start + 1:
		corridor_wall_rects.append(Rect2(right_start, y - wt / 2.0, x_end - right_start, wt))
	maze_door_defs.append({"pos": Vector2(gap_x, y), "is_vertical": false})

func _maze_wall_v(y_start: float, y_end: float, x: float, gap_y: float):
	"""Add a vertical maze wall with a doorway gap. Creates wall rects and a door def."""
	var wt = WALL_THICKNESS
	var he = ENTRANCE_WIDTH / 2.0
	var top_end = gap_y - he
	var bot_start = gap_y + he
	if top_end > y_start + 1:
		corridor_wall_rects.append(Rect2(x - wt / 2.0, y_start, wt, top_end - y_start))
	if y_end > bot_start + 1:
		corridor_wall_rects.append(Rect2(x - wt / 2.0, bot_start, wt, y_end - bot_start))
	maze_door_defs.append({"pos": Vector2(x, gap_y), "is_vertical": true})

# --- Query helpers ---

func get_nearest_entrance(from_pos: Vector2) -> int:
	var best = 0
	var best_dist = INF
	for i in range(entrance_positions.size()):
		var d = from_pos.distance_to(entrance_positions[i])
		if d < best_dist:
			best_dist = d
			best = i
	return best

func get_entrance_position(index: int) -> Vector2:
	return entrance_positions[index]

func get_barricade(index: int):
	if index >= 0 and index < barricades.size():
		return barricades[index]
	return null

func get_random_spawn_point() -> Vector2:
	var idx = randi() % spawn_points.size()
	var base = spawn_points[idx]
	var offset: Vector2
	if idx == 0 or idx == 2:
		offset = Vector2(randf_range(-200, 200), randf_range(-20, 20))
	else:
		offset = Vector2(randf_range(-20, 20), randf_range(-200, 200))
	return base + offset

func get_fort_center() -> Vector2:
	return Vector2((FORT_LEFT + FORT_RIGHT) / 2.0, (FORT_TOP + FORT_BOTTOM) / 2.0)

func get_keep_center() -> Vector2:
	return Vector2((keep_left + keep_right) / 2.0, (keep_top + keep_bottom) / 2.0)

func get_outside_ally_position(player_index: int) -> Vector2:
	var cx = (FORT_LEFT + FORT_RIGHT) / 2.0
	if player_index == 1:
		return Vector2(cx, FORT_BOTTOM + 90)
	return Vector2(cx, FORT_TOP - 90)

func is_inside_fort(pos: Vector2) -> bool:
	return pos.x > FORT_LEFT and pos.x < FORT_RIGHT and pos.y > FORT_TOP and pos.y < FORT_BOTTOM

func is_inside_keep(pos: Vector2) -> bool:
	return pos.x > keep_left and pos.x < keep_right and pos.y > keep_top and pos.y < keep_bottom


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

func get_navigation_waypoints() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for ep in entrance_positions:
		points.append(ep)
	for kp in keep_entrance_positions:
		points.append(kp)
	for d in doors:
		points.append(d.position)
	points.append(get_fort_center())
	points.append(get_keep_center())
	return points

func get_nearest_barricade_in_range(pos: Vector2, range_dist: float):
	var best = null
	var best_dist = INF
	for b in barricades:
		var d = pos.distance_to(b.position)
		if d < range_dist and d < best_dist:
			best_dist = d
			best = b
	return best

func get_nearest_door_in_range(pos: Vector2, range_dist: float):
	"""Returns the nearest door within range (any state)."""
	var best = null
	var best_dist = INF
	for d in doors:
		var dist = pos.distance_to(d.position)
		if dist < range_dist and dist < best_dist:
			best_dist = dist
			best = d
	return best

func get_nearest_closed_door(pos: Vector2, range_dist: float):
	"""Returns the nearest closed (blocking) door within range."""
	var best = null
	var best_dist = INF
	for d in doors:
		if d.is_blocking():
			var dist = pos.distance_to(d.position)
			if dist < range_dist and dist < best_dist:
				best_dist = dist
				best = d
	return best

# --- Collision ---

func resolve_collision(pos: Vector2, radius: float) -> Vector2:
	# Push out of outer wall segments
	for rect in wall_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	# Push out of inner keep wall segments
	for rect in keep_wall_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	# Push out of corridor maze walls
	for rect in corridor_wall_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	# Push out of obstacles
	for rect in obstacle_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	# Push out of intact barricades
	for b in barricades:
		if b.is_intact():
			var bw = b.BAR_H if b.is_vertical else b.BAR_W
			var bh = b.BAR_W if b.is_vertical else b.BAR_H
			var b_rect = Rect2(b.position.x - bw / 2, b.position.y - bh / 2, bw, bh)
			pos = _push_out_of_rect(pos, radius, b_rect)
	# Push out of closed doors
	for d in doors:
		var d_rect = d.get_collision_rect()
		if d_rect.size.length() > 0:
			pos = _push_out_of_rect(pos, radius, d_rect)
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

# --- Drawing ---

func _draw():
	# === BACKGROUND ===
	if bg_texture:
		var tex_size = bg_texture.get_size()
		var sx = SCREEN_W / tex_size.x
		var sy = SCREEN_H / tex_size.y
		draw_set_transform(Vector2.ZERO, 0, Vector2(sx, sy))
		draw_texture(bg_texture, Vector2.ZERO, bg_tint)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), GRASS_DARK)

	# === FORT INTERIOR (lighter area inside outer walls) ===
	draw_rect(Rect2(FORT_LEFT, FORT_TOP, FORT_RIGHT - FORT_LEFT, FORT_BOTTOM - FORT_TOP), Color8(85, 70, 50, 140))

	# === RING INTERIOR FLOOR (between ring walls and keep) ===
	draw_rect(Rect2(ring_left, ring_top, ring_right - ring_left, ring_bottom - ring_top), Color8(75, 62, 45, 100))

	# === INNER GATE AREA FLOOR (between inner gates and keep) ===
	var wig_x = (ring_left + keep_left) / 2.0
	var eig_x = (keep_right + ring_right) / 2.0
	var nig_y = (ring_top + keep_top) / 2.0
	var sig_y = (keep_bottom + ring_bottom) / 2.0
	draw_rect(Rect2(wig_x, nig_y, eig_x - wig_x, sig_y - nig_y), Color8(70, 58, 42, 100))

	# === INNER KEEP FLOOR (darker area inside keep) ===
	draw_rect(Rect2(keep_left, keep_top, keep_right - keep_left, keep_bottom - keep_top), KEEP_FLOOR)

	# === OBSTACLES (crates) ===
	_draw_obstacles()

	# === OUTER WALLS ===
	_draw_walls()

	# === INNER KEEP WALLS ===
	_draw_keep_walls()

	# === CORRIDOR MAZE WALLS ===
	_draw_corridor_walls()

	# === OUTER ENTRANCE LABELS ===
	var font = ThemeDB.fallback_font
	var labels = ["NORTH", "EAST", "SOUTH", "WEST"]
	var label_offsets = [Vector2(-20, -WALL_THICKNESS - 8), Vector2(WALL_THICKNESS + 4, 5), Vector2(-20, WALL_THICKNESS + 14), Vector2(-WALL_THICKNESS - 50, 5)]
	for i in range(4):
		draw_string(font, entrance_positions[i] + label_offsets[i], labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(200, 180, 150, 140))

	# === INNER KEEP ENTRANCE LABELS ===
	var keep_labels = ["KEEP N", "KEEP E", "KEEP S", "KEEP W"]
	var keep_label_offsets = [Vector2(-22, -WALL_THICKNESS - 6), Vector2(WALL_THICKNESS + 4, 4), Vector2(-22, WALL_THICKNESS + 12), Vector2(-WALL_THICKNESS - 52, 4)]
	for i in range(keep_entrance_positions.size()):
		draw_string(font, keep_entrance_positions[i] + keep_label_offsets[i], keep_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(180, 160, 130, 180))

	# === FORT CENTER MARKER ===
	var fc = get_fort_center()
	draw_circle(fc, 8, Color8(150, 130, 100, 40))
	draw_circle(fc, 8, Color8(150, 130, 100, 60), false, 1.0)

	# === FLOOR GRID (inside fort) ===
	var grid_spacing = 40.0
	var grid_col = Color8(120, 100, 75, 25)
	var gx = FORT_LEFT
	while gx <= FORT_RIGHT:
		draw_line(Vector2(gx, FORT_TOP), Vector2(gx, FORT_BOTTOM), grid_col, 0.5)
		gx += grid_spacing
	var gy = FORT_TOP
	while gy <= FORT_BOTTOM:
		draw_line(Vector2(FORT_LEFT, gy), Vector2(FORT_RIGHT, gy), grid_col, 0.5)
		gy += grid_spacing

	# === KEEP FLOOR GRID (slightly different pattern) ===
	var keep_grid_col = Color8(100, 85, 65, 30)
	var keep_grid_spacing = 32.0
	gx = keep_left
	while gx <= keep_right:
		draw_line(Vector2(gx, keep_top), Vector2(gx, keep_bottom), keep_grid_col, 0.5)
		gx += keep_grid_spacing
	gy = keep_top
	while gy <= keep_bottom:
		draw_line(Vector2(keep_left, gy), Vector2(keep_right, gy), keep_grid_col, 0.5)
		gy += keep_grid_spacing

	# === AMBIENT DUST PARTICLES ===
	var t = anim_time
	for i in range(30):
		var dx = fmod(float(i) * 97.0 + t * 12.0 * (0.4 + fmod(float(i) * 0.37, 0.6)), SCREEN_W)
		var dy = fmod(float(i) * 53.0 + t * 6.0 * (0.3 + fmod(float(i) * 0.61, 0.7)), SCREEN_H)
		var da = 0.06 + 0.04 * sin(t * 1.5 + float(i))
		draw_circle(Vector2(dx, dy), 1.5 + fmod(float(i), 2.0), Color(0.9, 0.85, 0.7, da))

	# === VIGNETTE (scaled for large maps) ===
	var vig_size = clampf(120.0 * map_scale * 0.5, 120.0, 600.0)
	draw_rect(Rect2(0, 0, SCREEN_W, vig_size), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(0, SCREEN_H - vig_size, SCREEN_W, vig_size), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(0, 0, vig_size, SCREEN_H), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(SCREEN_W - vig_size, 0, vig_size, SCREEN_H), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(0, 0, vig_size, vig_size), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(SCREEN_W - vig_size, 0, vig_size, vig_size), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(0, SCREEN_H - vig_size, vig_size, vig_size), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(SCREEN_W - vig_size, SCREEN_H - vig_size, vig_size, vig_size), Color(0, 0, 0, 0.1))

func _draw_walls():
	var cx = (FORT_LEFT + FORT_RIGHT) / 2.0
	var cy = (FORT_TOP + FORT_BOTTOM) / 2.0
	var he = ENTRANCE_WIDTH / 2.0
	var wt = WALL_THICKNESS

	_draw_wall_block(FORT_LEFT - wt, FORT_TOP - wt, cx - he - FORT_LEFT + wt, wt)
	_draw_wall_block(cx + he, FORT_TOP - wt, FORT_RIGHT + wt - cx - he, wt)
	_draw_wall_block(FORT_LEFT - wt, FORT_BOTTOM, cx - he - FORT_LEFT + wt, wt)
	_draw_wall_block(cx + he, FORT_BOTTOM, FORT_RIGHT + wt - cx - he, wt)
	_draw_wall_block(FORT_LEFT - wt, FORT_TOP - wt, wt, cy - he - FORT_TOP + wt)
	_draw_wall_block(FORT_LEFT - wt, cy + he, wt, FORT_BOTTOM + wt - cy - he)
	_draw_wall_block(FORT_RIGHT, FORT_TOP - wt, wt, cy - he - FORT_TOP + wt)
	_draw_wall_block(FORT_RIGHT, cy + he, wt, FORT_BOTTOM + wt - cy - he)

func _draw_keep_walls():
	var cx = (keep_left + keep_right) / 2.0
	var cy = (keep_top + keep_bottom) / 2.0
	var he = ENTRANCE_WIDTH / 2.0
	var wt = WALL_THICKNESS

	# Top wall segments
	_draw_keep_block(keep_left - wt, keep_top - wt, cx - he - keep_left + wt, wt)
	_draw_keep_block(cx + he, keep_top - wt, keep_right + wt - cx - he, wt)
	# Bottom wall segments
	_draw_keep_block(keep_left - wt, keep_bottom, cx - he - keep_left + wt, wt)
	_draw_keep_block(cx + he, keep_bottom, keep_right + wt - cx - he, wt)
	# Left wall segments
	_draw_keep_block(keep_left - wt, keep_top - wt, wt, cy - he - keep_top + wt)
	_draw_keep_block(keep_left - wt, cy + he, wt, keep_bottom + wt - cy - he)
	# Right wall segments
	_draw_keep_block(keep_right, keep_top - wt, wt, cy - he - keep_top + wt)
	_draw_keep_block(keep_right, cy + he, wt, keep_bottom + wt - cy - he)

	# Corner pillars (decorative reinforcement at keep corners)
	var pillar_s = wt * 1.5
	for corner in [Vector2(keep_left - wt, keep_top - wt), Vector2(keep_right, keep_top - wt),
					Vector2(keep_left - wt, keep_bottom), Vector2(keep_right, keep_bottom)]:
		draw_rect(Rect2(corner.x - 2, corner.y - 2, pillar_s + 4, pillar_s + 4), Color8(80, 65, 45))
		draw_rect(Rect2(corner.x, corner.y, pillar_s, pillar_s), Color8(120, 100, 75))
		draw_rect(Rect2(corner.x, corner.y, pillar_s, pillar_s), Color8(60, 50, 35), false, 1.5)

func _draw_obstacles():
	for rect in obstacle_rects:
		draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x, rect.size.y), Color8(40, 35, 45))
		draw_rect(rect, Color8(139, 90, 43))
		draw_rect(rect, Color8(100, 70, 30), false, 2.0)
		var cx = rect.position.x + rect.size.x / 2
		var cy = rect.position.y + rect.size.y / 2
		draw_line(rect.position + Vector2(2, 2), rect.position + rect.size - Vector2(2, 2), Color8(80, 55, 25), 1.5)
		draw_line(Vector2(rect.position.x + rect.size.x - 2, rect.position.y + 2), Vector2(rect.position.x + 2, rect.position.y + rect.size.y - 2), Color8(80, 55, 25), 1.5)

func _draw_wall_block(x: float, y: float, w: float, h: float):
	if w < 1 or h < 1:
		return
	draw_rect(Rect2(x + 3, y + 3, w, h), WALL_SHADOW)
	draw_rect(Rect2(x, y, w, h), WALL_FILL)
	draw_rect(Rect2(x, y, w, maxf(h * 0.3, 4)), WALL_TOP)
	draw_rect(Rect2(x, y, w, h), WALL_SHADOW, false, 1.5)
	var brick_h = 11.0
	var brick_w = 22.0
	for by in range(int(y), int(y + h), int(brick_h)):
		var offset_x = brick_w * 0.5 if int((by - y) / brick_h) % 2 == 1 else 0.0
		for bx_start in range(int(x + offset_x), int(x + w), int(brick_w)):
			var bx_end = minf(bx_start + brick_w, x + w)
			if bx_end > x:
				draw_line(Vector2(bx_start, by), Vector2(bx_end, by), Color8(90, 72, 50, 80), 1.0)
		draw_line(Vector2(x, by), Vector2(x + w, by), Color8(90, 72, 50, 40), 0.5)

func _draw_keep_block(x: float, y: float, w: float, h: float):
	if w < 1 or h < 1:
		return
	# Shadow
	draw_rect(Rect2(x + 3, y + 3, w, h), KEEP_WALL_SHADOW)
	# Main fill (slightly different from outer walls)
	draw_rect(Rect2(x, y, w, h), KEEP_WALL_FILL)
	# Top highlight
	draw_rect(Rect2(x, y, w, maxf(h * 0.3, 4)), KEEP_WALL_TOP)
	# Border
	draw_rect(Rect2(x, y, w, h), KEEP_WALL_SHADOW, false, 1.5)
	# Brick pattern (smaller bricks for inner walls)
	var brick_h = 9.0
	var brick_w = 18.0
	for by in range(int(y), int(y + h), int(brick_h)):
		var offset_x = brick_w * 0.5 if int((by - y) / brick_h) % 2 == 1 else 0.0
		for bx_start in range(int(x + offset_x), int(x + w), int(brick_w)):
			var bx_end = minf(bx_start + brick_w, x + w)
			if bx_end > x:
				draw_line(Vector2(bx_start, by), Vector2(bx_end, by), Color8(70, 56, 38, 80), 1.0)
		draw_line(Vector2(x, by), Vector2(x + w, by), Color8(70, 56, 38, 40), 0.5)

func _draw_corridor_walls():
	"""Draw all internal corridor maze walls."""
	for rect in corridor_wall_rects:
		_draw_corridor_block(rect.position.x, rect.position.y, rect.size.x, rect.size.y)

func _draw_corridor_block(x: float, y: float, w: float, h: float):
	if w < 1 or h < 1:
		return
	# Shadow
	draw_rect(Rect2(x + 2, y + 2, w, h), Color8(45, 36, 25))
	# Main fill (distinct from keep/outer walls - slightly reddish stone)
	draw_rect(Rect2(x, y, w, h), Color8(110, 85, 60))
	# Top highlight
	draw_rect(Rect2(x, y, w, maxf(h * 0.25, 3)), Color8(135, 108, 78))
	# Border
	draw_rect(Rect2(x, y, w, h), Color8(60, 48, 32), false, 1.5)
	# Brick pattern (medium bricks for corridor walls)
	var brick_h = 10.0
	var brick_w = 20.0
	for by in range(int(y), int(y + h), int(brick_h)):
		var off_x = brick_w * 0.5 if int((by - y) / brick_h) % 2 == 1 else 0.0
		for bx_start in range(int(x + off_x), int(x + w), int(brick_w)):
			var bx_end = minf(bx_start + brick_w, x + w)
			if bx_end > x:
				draw_line(Vector2(bx_start, by), Vector2(bx_end, by), Color8(80, 64, 44, 70), 0.8)
