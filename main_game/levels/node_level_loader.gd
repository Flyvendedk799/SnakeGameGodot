class_name NodeLevelLoader
extends RefCounted
## Converts a node-based level scene into level_config for LinearMap.
## Add LevelFloorSegment, LevelPlatform, LevelCheckpoint, LevelGoal, LevelGrappleAnchor, LevelChainLink as children.
## Drag, move, delete like any node - true WYSIWYG level design.

static func get_level_config_from_nodes(root: Node) -> Dictionary:
	var floor_segments: Array = []
	var platforms: Array = []
	var checkpoints: Array = []
	var goals: Array = []
	var goal_rect = Rect2(2400, 250, 50, 220)
	var grapple_anchors: Array = []
	var chain_links: Array = []
	var all_points: Array[Vector2] = []

	_collect_nodes(root, floor_segments, platforms, checkpoints, goals, grapple_anchors, chain_links, all_points)

	if goals.size() > 0:
		var g = goals[0]
		var center = g.global_position
		var sz = g.size
		goal_rect = Rect2(center.x - sz.x * 0.5, center.y - sz.y * 0.5, sz.x, sz.y)
		all_points.append(center)

	# Compute bounds
	var width = 2600.0
	var height = 720.0
	if all_points.size() > 0 or floor_segments.size() > 0 or platforms.size() > 0:
		var min_x = INF
		var max_x = -INF
		var min_y = INF
		var max_y = -INF
		for p in all_points:
			min_x = minf(min_x, p.x)
			max_x = maxf(max_x, p.x)
			min_y = minf(min_y, p.y)
			max_y = maxf(max_y, p.y)
		for seg in floor_segments:
			min_x = minf(min_x, seg.x_min)
			max_x = maxf(max_x, seg.x_max)
			min_y = minf(min_y, seg.y_min)
			max_y = maxf(max_y, seg.y_max)
		for p in platforms:
			min_x = minf(min_x, p.x)
			max_x = maxf(max_x, p.x + p.w)
			min_y = minf(min_y, p.y)
			max_y = maxf(max_y, p.y + p.h)
		if min_x != INF:
			width = maxf(width, max_x - min_x + 400)
			height = maxf(height, max_y - min_y + 200)

	var segments = _build_segments_from_floors(floor_segments)
	var layers = [
		{"id": "surface", "y_min": 0, "y_max": int(height), "type": "ground"},
		{"id": "platform", "y_min": 0, "y_max": int(height), "type": "platform"}
	]

	return {
		"id": 1,
		"name": "Node Level",
		"width": width,
		"height": height,
		"theme": "grass",
		"bg_texture_path": "",
		"floor_segments": floor_segments,
		"platforms": platforms,
		"checkpoints": checkpoints,
		"goal_rect": goal_rect,
		"grapple_anchors": grapple_anchors,
		"chain_links": chain_links,
		"layers": layers,
		"segments": segments,
		"decor": [],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _collect_nodes(root: Node, floor_segments: Array, platforms: Array, checkpoints: Array, goals: Array, grapple_anchors: Array, chain_links: Array, all_points: Array[Vector2]):
	for c in root.get_children():
		if c is LevelGoal:
			goals.append(c)
		elif c is LevelFloorSegment:
			var f = c as LevelFloorSegment
			var pos = f.global_position
			var tr_scale = f.global_transform.get_scale()
			var sz = f.size * tr_scale  # Apply scale so bounds match actual geometry
			floor_segments.append({
				"x_min": pos.x, "x_max": pos.x + sz.x,
				"y_min": pos.y, "y_max": pos.y + sz.y
			})
			all_points.append(pos)
			all_points.append(pos + sz)
		elif c is LevelPlatform:
			var p = c as LevelPlatform
			var pos = p.global_position  # center of platform
			# Size (Inspector) * global scale (gizmo) = exported dimensions; both work
			var tr_scale = p.global_transform.get_scale()
			var sz = p.size * tr_scale
			platforms.append({"x": pos.x, "y": pos.y, "w": sz.x, "h": sz.y, "centered": true, "surface_fraction": p.surface_fraction})
			all_points.append(pos - sz / 2)
			all_points.append(pos + sz / 2)
		elif c is LevelCheckpoint:
			var cp = c as LevelCheckpoint
			var pos = cp.global_position
			checkpoints.append({
				"x": pos.x, "y": pos.y,
				"rect": Rect2(pos.x - 50, pos.y - 60, 100, 120),
				"layer": "surface"
			})
			all_points.append(pos)
		elif c is LevelGrappleAnchor:
			var g = c as LevelGrappleAnchor
			var pos = g.global_position
			grapple_anchors.append({"x": pos.x, "y": pos.y})
			all_points.append(pos)
		elif c is LevelChainLink:
			var cl = c as LevelChainLink
			var pos = cl.global_position
			chain_links.append({"x": pos.x, "y": pos.y})
			all_points.append(pos)
		_collect_nodes(c, floor_segments, platforms, checkpoints, goals, grapple_anchors, chain_links, all_points)

static func _build_segments_from_floors(floor_segments: Array) -> Array:
	var segments: Array = []
	for seg in floor_segments:
		var x_min = float(seg.get("x_min", 0))
		var x_max = float(seg.get("x_max", 100))
		var y_min = float(seg.get("y_min", 360))
		var y_max = float(seg.get("y_max", 480))
		segments.append({
			"x_min": x_min,
			"x_max": x_max,
			"spawn_zones": [{
				"x_min": x_min + 20, "x_max": x_max - 20,
				"y_min": y_min + 5, "y_max": y_max - 5,
				"layer": "surface",
				"pool": ["complainer"],
				"density": 0.5,
				"max_concurrent": 3,
				"trigger_x": x_min
			}]
		})
	return segments
