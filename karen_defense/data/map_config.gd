class_name MapConfig
extends RefCounted

# Base fort dimensions (used for obstacle positioning)
const BASE_FORT_W: float = 700.0
const BASE_FORT_H: float = 480.0

# Obstacle format: {"x": normalized 0-1, "y": normalized 0-1, "w": pixel width, "h": pixel height}
# These scale with the fort when map expands
static func get_map_config(map_id: int) -> Dictionary:
	match map_id:
		1:
			return {
				"id": 1,
				"name": "Desert Oasis",
				"max_waves": 15,
				"theme": "desert",
				"world_tier": 1,
				"bg_texture_path": "res://assets/Map1.png",
				"bg_tint": Color(1.05, 0.95, 0.85),
				"obstacles": _desert_obstacles(),
				"expand_waves": [8],
				"expand_scales": [7.5],
				"initial_scale": 6.0,
				"camera_base_zoom": 1.5,
			}
		2:
			return {
				"id": 2,
				"name": "Frozen Fortress",
				"max_waves": 30,
				"theme": "snow",
				"world_tier": 2,
				"bg_texture_path": "res://assets/map2.png",
				"bg_tint": Color(0.92, 0.95, 1.05),
				"obstacles": _snow_obstacles(),
				"expand_waves": [10, 20],
				"expand_scales": [7.5, 9.0],
				"initial_scale": 6.0,
				"camera_base_zoom": 1.5,
			}
		3:
			return {
				"id": 3,
				"name": "Jungle Base",
				"max_waves": 50,
				"theme": "jungle",
				"world_tier": 3,
				"bg_texture_path": "res://assets/Map1.png",
				"bg_tint": Color(0.75, 1.0, 0.85),
				"obstacles": _jungle_obstacles(),
				"expand_waves": [10, 30],
				"expand_scales": [7.5, 9.0],
				"initial_scale": 6.0,
				"camera_base_zoom": 1.5,
			}
		_:
			return get_map_config(1)

static func _desert_obstacles() -> Array:
	# Desert: open layout with corner bunkers and flanking rocks
	# All paths to entrances stay completely clear
	return [
		# NW corner bunker (L-shaped cover)
		{"x": 0.04, "y": 0.04, "w": 40, "h": 40},
		{"x": 0.04, "y": 0.15, "w": 24, "h": 30},
		{"x": 0.13, "y": 0.04, "w": 30, "h": 24},
		# NE corner bunker
		{"x": 0.96, "y": 0.04, "w": 40, "h": 40},
		{"x": 0.96, "y": 0.15, "w": 24, "h": 30},
		{"x": 0.87, "y": 0.04, "w": 30, "h": 24},
		# SW corner bunker
		{"x": 0.04, "y": 0.96, "w": 40, "h": 40},
		{"x": 0.04, "y": 0.85, "w": 24, "h": 30},
		{"x": 0.13, "y": 0.96, "w": 30, "h": 24},
		# SE corner bunker
		{"x": 0.96, "y": 0.96, "w": 40, "h": 40},
		{"x": 0.96, "y": 0.85, "w": 24, "h": 30},
		{"x": 0.87, "y": 0.96, "w": 30, "h": 24},
		# Inner flanking rocks (strategic cover near fort walls, not blocking paths)
		{"x": 0.25, "y": 0.22, "w": 20, "h": 20},
		{"x": 0.75, "y": 0.22, "w": 20, "h": 20},
		{"x": 0.25, "y": 0.78, "w": 20, "h": 20},
		{"x": 0.75, "y": 0.78, "w": 20, "h": 20},
	]

static func _snow_obstacles() -> Array:
	# Snow: ice pillars and frozen walls creating choke points and ambush spots
	return [
		# NW ice cluster
		{"x": 0.04, "y": 0.04, "w": 44, "h": 44},
		{"x": 0.13, "y": 0.04, "w": 28, "h": 28},
		{"x": 0.04, "y": 0.13, "w": 28, "h": 28},
		# NE ice cluster
		{"x": 0.96, "y": 0.04, "w": 44, "h": 44},
		{"x": 0.87, "y": 0.04, "w": 28, "h": 28},
		{"x": 0.96, "y": 0.13, "w": 28, "h": 28},
		# SW ice cluster
		{"x": 0.04, "y": 0.96, "w": 44, "h": 44},
		{"x": 0.13, "y": 0.96, "w": 28, "h": 28},
		{"x": 0.04, "y": 0.87, "w": 28, "h": 28},
		# SE ice cluster
		{"x": 0.96, "y": 0.96, "w": 44, "h": 44},
		{"x": 0.87, "y": 0.96, "w": 28, "h": 28},
		{"x": 0.96, "y": 0.87, "w": 28, "h": 28},
		# Mid-field frozen pillars (create interesting combat zones)
		{"x": 0.22, "y": 0.35, "w": 22, "h": 22},
		{"x": 0.78, "y": 0.35, "w": 22, "h": 22},
		{"x": 0.22, "y": 0.65, "w": 22, "h": 22},
		{"x": 0.78, "y": 0.65, "w": 22, "h": 22},
		# Ice walls near keep (horizontal cover)
		{"x": 0.35, "y": 0.25, "w": 40, "h": 16},
		{"x": 0.65, "y": 0.25, "w": 40, "h": 16},
		{"x": 0.35, "y": 0.75, "w": 40, "h": 16},
		{"x": 0.65, "y": 0.75, "w": 40, "h": 16},
	]

static func _jungle_obstacles() -> Array:
	# Jungle: dense vegetation clusters, ruins, and tactical vantage points
	# Most complex layout — creates interesting pathing and combat spaces
	return [
		# NW corner ruin cluster
		{"x": 0.04, "y": 0.04, "w": 48, "h": 48},
		{"x": 0.14, "y": 0.04, "w": 32, "h": 32},
		{"x": 0.04, "y": 0.14, "w": 32, "h": 32},
		{"x": 0.14, "y": 0.14, "w": 20, "h": 20},
		# NE corner ruin cluster
		{"x": 0.96, "y": 0.04, "w": 48, "h": 48},
		{"x": 0.86, "y": 0.04, "w": 32, "h": 32},
		{"x": 0.96, "y": 0.14, "w": 32, "h": 32},
		{"x": 0.86, "y": 0.14, "w": 20, "h": 20},
		# SW corner ruin cluster
		{"x": 0.04, "y": 0.96, "w": 48, "h": 48},
		{"x": 0.14, "y": 0.96, "w": 32, "h": 32},
		{"x": 0.04, "y": 0.86, "w": 32, "h": 32},
		{"x": 0.14, "y": 0.86, "w": 20, "h": 20},
		# SE corner ruin cluster
		{"x": 0.96, "y": 0.96, "w": 48, "h": 48},
		{"x": 0.86, "y": 0.96, "w": 32, "h": 32},
		{"x": 0.96, "y": 0.86, "w": 32, "h": 32},
		{"x": 0.86, "y": 0.86, "w": 20, "h": 20},
		# Inner flanking vegetation (creates lanes between cover)
		{"x": 0.20, "y": 0.30, "w": 26, "h": 26},
		{"x": 0.80, "y": 0.30, "w": 26, "h": 26},
		{"x": 0.20, "y": 0.70, "w": 26, "h": 26},
		{"x": 0.80, "y": 0.70, "w": 26, "h": 26},
		# Mid-wall terrain (asymmetric for interesting routing)
		{"x": 0.30, "y": 0.15, "w": 24, "h": 18},
		{"x": 0.70, "y": 0.85, "w": 24, "h": 18},
		{"x": 0.15, "y": 0.50, "w": 18, "h": 28},
		{"x": 0.85, "y": 0.50, "w": 18, "h": 28},
	]

static func obstacles_to_rects(obstacles: Array, fort_left: float, fort_top: float, fort_w: float, fort_h: float) -> Array:
	var rects: Array[Rect2] = []
	for obs in obstacles:
		var w = obs.get("w", 48) * (fort_w / BASE_FORT_W)
		var h = obs.get("h", 48) * (fort_h / BASE_FORT_H)
		var x = fort_left + obs.get("x", 0.5) * fort_w - w / 2.0
		var y = fort_top + obs.get("y", 0.5) * fort_h - h / 2.0
		rects.append(Rect2(x, y, w, h))
	return rects
