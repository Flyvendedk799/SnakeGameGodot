class_name TileMapLevelLoader
extends RefCounted
## Converts a Godot TileMap into level_config format for LinearMap.
## Tile atlas coords: (0,0)=floor, (1,0)=platform, (2,0)=checkpoint, (3,0)=goal, (4,0)=grapple, (5,0)=chain
## Use layer 0 for collision (floor/platform), or all layers are read.

enum TileType { NONE, FLOOR, PLATFORM, CHECKPOINT, GOAL, GRAPPLE, CHAIN }

static func get_level_config_from_tilemap(tile_map: TileMap) -> Dictionary:
	var tile_size = _get_tile_size(tile_map)
	if tile_size <= 0:
		tile_size = 64
	var layer_count = tile_map.get_layers_count()
	var floor_cells: Array[Vector2i] = []
	var platform_cells: Array[Vector2i] = []
	var checkpoint_cells: Array[Vector2i] = []
	var goal_cells: Array[Vector2i] = []
	var grapple_cells: Array[Vector2i] = []
	var chain_cells: Array[Vector2i] = []

	for layer in range(layer_count):
		var used = tile_map.get_used_cells(layer)
		for cell in used:
			var tid = tile_map.get_cell_source_id(layer, cell)
			var atlas = tile_map.get_cell_atlas_coords(layer, cell)
			var t = _atlas_to_type(atlas)
			match t:
				TileType.FLOOR: floor_cells.append(cell)
				TileType.PLATFORM: platform_cells.append(cell)
				TileType.CHECKPOINT: checkpoint_cells.append(cell)
				TileType.GOAL: goal_cells.append(cell)
				TileType.GRAPPLE: grapple_cells.append(cell)
				TileType.CHAIN: chain_cells.append(cell)

	var floor_rects_raw = _merge_cells_to_rects(floor_cells, tile_size)
	var platform_rects_raw = _merge_cells_to_rects(platform_cells, tile_size)
	var floor_segments = floor_rects_raw
	var platforms: Array = []
	for r in platform_rects_raw:
		platforms.append({
			"x": r.x_min, "y": r.y_min,
			"w": r.x_max - r.x_min, "h": minf(22.0, r.y_max - r.y_min)
		})
	var width = 2600.0
	var height = 720.0
	if floor_segments.size() > 0 or platform_cells.size() > 0:
		var all_cells = floor_cells + platform_cells + checkpoint_cells + goal_cells
		if all_cells.size() > 0:
			var min_x = INF
			var max_x = -INF
			var min_y = INF
			var max_y = -INF
			for c in all_cells:
				min_x = minf(min_x, c.x * tile_size)
				max_x = maxf(max_x, (c.x + 1) * tile_size)
				min_y = minf(min_y, c.y * tile_size)
				max_y = maxf(max_y, (c.y + 1) * tile_size)
			width = maxf(width, max_x - min_x + 400)
			height = maxf(height, max_y - min_y + 200)

	var checkpoints: Array = []
	for i in range(checkpoint_cells.size()):
		var c = checkpoint_cells[i]
		var x = c.x * tile_size + tile_size / 2.0
		var y = c.y * tile_size + tile_size / 2.0
		checkpoints.append({
			"x": x, "y": y,
			"rect": Rect2(x - 50, y - 60, 100, 120),
			"layer": "surface"
		})

	var goal_rect = Rect2(width - 50, 250, 50, 220)
	if goal_cells.size() > 0:
		var c = goal_cells[0]
		var x = c.x * tile_size
		var y = c.y * tile_size
		goal_rect = Rect2(x, y, tile_size, tile_size * 2)

	var grapple_anchors: Array = []
	for c in grapple_cells:
		grapple_anchors.append({"x": c.x * tile_size + tile_size / 2.0, "y": c.y * tile_size + tile_size / 2.0})

	var chain_links: Array = []
	for c in chain_cells:
		chain_links.append({"x": c.x * tile_size + tile_size / 2.0, "y": c.y * tile_size + tile_size / 2.0})

	var segments = _build_segments_from_floors(floor_segments)
	var layers = [
		{"id": "surface", "y_min": 0, "y_max": int(height), "type": "ground"},
		{"id": "platform", "y_min": 0, "y_max": int(height), "type": "platform"}
	]

	return {
		"id": 1,
		"name": "TileMap Level",
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

static func _atlas_to_type(atlas: Vector2i) -> TileType:
	if atlas.y != 0:
		return TileType.NONE
	match atlas.x:
		0: return TileType.FLOOR
		1: return TileType.PLATFORM
		2: return TileType.CHECKPOINT
		3: return TileType.GOAL
		4: return TileType.GRAPPLE
		5: return TileType.CHAIN
		_: return TileType.NONE

static func _get_tile_size(tile_map: TileMap) -> int:
	if not tile_map.tile_set:
		return 0
	var count = tile_map.tile_set.get_source_count()
	for i in range(count):
		var sid = tile_map.tile_set.get_source_id(i)
		var src = tile_map.tile_set.get_source(sid)
		if src is TileSetAtlasSource:
			var sz = (src as TileSetAtlasSource).texture_region_size
			return int(maxf(sz.x, sz.y))
	return 0

static func _merge_cells_to_rects(cells: Array, tile_size: float) -> Array:
	if cells.is_empty():
		return []
	var by_row: Dictionary = {}
	for c in cells:
		var row = c.y
		if not by_row.has(row):
			by_row[row] = []
		by_row[row].append(c.x)
	var result: Array = []
	for row in by_row.keys():
		var cols = by_row[row]
		cols.sort()
		var start_x = cols[0]
		var prev_x = cols[0]
		for i in range(1, cols.size()):
			if cols[i] == prev_x + 1:
				prev_x = cols[i]
			else:
				result.append({
					"x_min": start_x * tile_size,
					"x_max": (prev_x + 1) * tile_size,
					"y_min": row * tile_size,
					"y_max": (row + 1) * tile_size
				})
				start_x = cols[i]
				prev_x = cols[i]
		result.append({
			"x_min": start_x * tile_size,
			"x_max": (prev_x + 1) * tile_size,
			"y_min": row * tile_size,
			"y_max": (row + 1) * tile_size
		})
	result.sort_custom(func(a, b): return a.x_min < b.x_min)
	return result

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
