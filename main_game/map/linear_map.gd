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
var ring_left: float = 0
var ring_right: float = 2400
var ring_top: float = 0
var ring_bottom: float = 720
var barricades: Array = []
var doors: Array = []
var entrance_positions: Array[Vector2] = []
var keep_entrance_positions: Array[Vector2] = []

# Collision
var floor_rects: Array[Rect2] = []
var wall_rects: Array[Rect2] = []
var platform_rects: Array[Rect2] = []      # Full rects for drawing
var platform_collision_rects: Array[Rect2] = []  # Surface-aligned for physics (platform sprite dependent)
const PLATFORM_SURFACE_FRACTION: float = 0.28  # Default: walkable surface offset in texture (tune per-platform)
var obstacle_rects: Array[Rect2] = []

# Checkpoints and goal
var checkpoints: Array = []
var goal_rect: Rect2 = Rect2(0, 0, 0, 0)
var checkpoint_rects: Array[Rect2] = []

# Grapple anchors - positions player can grapple to (Main Game mechanic)
var grapple_anchors: Array[Vector2] = []
# Chain links - always grapplable swing points (placed in pits for recovery)
var chain_links: Array = []  # Array of Vector2 or {x,y}

# Waypoints for pathfinding (platform corners, ramp positions, etc.)
var waypoints: Array[Vector2] = []

# Visual
var anim_time: float = 0.0
var bg_tint: Color = Color(1.0, 1.0, 1.0)
var bg_texture: Texture2D = null

# Terrain textures
var terrain_texture: ImageTexture = null
var terrain_normal: ImageTexture = null
var platform_texture: ImageTexture = null
var platform_sprite: Texture2D = null  # platform1.png - used when available

# Lighting system
var lighting_system: LightingSystem = null

# Alias for HUD/shop compatibility
var map_config: Dictionary:
	get: return level_config

# Procedural decor cache (built once per level)
var _decor_rocks: Array = []
var _decor_plants: Array = []
var _decor_props: Array = []
var _decor_pipes: Array = []   # Metal pipes/drains (Shantae-style foreground)
var _decor_posts: Array = []   # Wooden dock pilings

# Terrain fill (AAA upgrade - complete map appearance)
var _floor_fill_rects: Array[Rect2] = []
var _ceiling_fill_rects: Array[Rect2] = []
var _wall_fill_rects: Array[Rect2] = []

# Phase 3.2: Alternate route path type per platform ("main" | "high" | "low")
var _platform_path_types: Array = []  # Parallel to platform_rects

# Phase 2.1: Grass bend - cached player position for proximity bending
var _player_pos: Vector2 = Vector2.ZERO
# Phase 2.3: Water ripples [{pos, timer, max_timer}]
var _ripples: Array = []
# Phase 5.2: Lava bubbles [{x, y, phase, radius}]
var _lava_bubbles: Array = []
# Phase 2.4: Crack/stain decals [{x, y, type, seed}]
var _decor_cracks: Array = []
# Phase 3.1: Destructible wall nodes
var _destructible_walls: Array = []   # Array of LevelDestructible nodes
# Phase 3.3: Level lock nodes
var _level_locks: Array = []

func setup(game_ref, level_id: int):
	game = game_ref
	level_config = LinearMapConfig.get_level(level_id)
	_setup_from_config()

func setup_from_config(game_ref, config: Dictionary):
	"""Use pre-built level config (e.g. from TileMapLevelLoader)."""
	game = game_ref
	level_config = config
	_setup_from_config()

func _setup_from_config():
	if level_config.is_empty():
		return
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
	ring_left = level_width * 0.15
	ring_right = level_width * 0.85
	ring_top = level_height * 0.15
	ring_bottom = level_height * 0.85
	entrance_positions = [Vector2(level_width * 0.5, 0), Vector2(level_width, level_height * 0.5), Vector2(level_width * 0.5, level_height), Vector2(0, level_height * 0.5)]
	keep_entrance_positions = [Vector2(keep_left, keep_top), Vector2(keep_right, keep_top), Vector2(keep_left, keep_bottom), Vector2(keep_right, keep_bottom)]

	# Load platform sprite early so collision/hitbox can use its dimensions
	if ResourceLoader.exists("res://assets/platform1.png"):
		platform_sprite = load("res://assets/platform1.png") as Texture2D
	else:
		platform_sprite = null

	_build_collision()
	_build_checkpoints()
	_build_waypoints()
	_build_grapple_anchors()
	_build_chain_links()
	_build_procedural_decor()
	_build_terrain_fill()  # AAA upgrade - fill gaps for complete maps
	_build_destructible_walls()
	_build_level_locks()

	# Load procedural terrain textures for current theme
	var theme = level_config.get("theme", "grass")
	terrain_texture = TerrainTextureGenerator.get_terrain_texture(theme)
	terrain_normal = TerrainTextureGenerator.get_normal_map(theme)
	platform_texture = TerrainTextureGenerator.get_platform_texture(theme)

	# Initialize lighting system
	lighting_system = LightingSystem.new()
	lighting_system.setup(theme)

	bg_tint = Color(1.0, 1.0, 1.0)
	var tex_path = level_config.get("bg_texture_path", "")
	if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
		bg_texture = load(tex_path)
	else:
		bg_texture = null
	queue_redraw()

func _build_grapple_anchors():
	grapple_anchors.clear()
	for a in level_config.get("grapple_anchors", []):
		grapple_anchors.append(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))

func _build_chain_links():
	chain_links.clear()
	# Only use chain links explicitly placed in level (no procedural pit placement)
	for cl in level_config.get("chain_links", []):
		chain_links.append(Vector2(float(cl.get("x", 0)), float(cl.get("y", 0))))

## Phase 3.1: Build destructible wall nodes from config
func _build_destructible_walls():
	# Remove any existing destructible walls
	for dw in _destructible_walls:
		if is_instance_valid(dw):
			dw.queue_free()
	_destructible_walls.clear()

	var walls_cfg: Array = level_config.get("destructible_walls", [])
	for cfg in walls_cfg:
		var dw = LevelDestructible.new()
		dw.hp          = int(cfg.get("hp", 30))
		dw.max_hp      = dw.hp
		dw.width       = float(cfg.get("w", 32))
		dw.height      = float(cfg.get("h", 64))
		dw.loot_gold   = int(cfg.get("loot_gold", 20))
		dw.key_drop_chance = float(cfg.get("key_drop_chance", 0.25))
		dw.passage_type = str(cfg.get("passage_type", "secret_passage"))
		# Theme-based wall color
		var theme = level_config.get("theme", "grass")
		match theme:
			"cave":    dw.color = Color8(80, 70, 85)
			"lava":    dw.color = Color8(100, 55, 40)
			"sky":     dw.color = Color8(140, 150, 165)
			"summit":  dw.color = Color8(145, 150, 160)
			"ice":     dw.color = Color8(155, 180, 200)
			_:         dw.color = Color8(110, 95, 75)

		dw.position = Vector2(float(cfg.get("x", 0)), float(cfg.get("y", 360)))
		# Wire destroyed signal — remove obstacle_rect when broken
		dw.destroyed.connect(_on_destructible_destroyed.bind(dw))
		add_child(dw)
		_destructible_walls.append(dw)
		# Add collision rect so enemies/player can't pass
		obstacle_rects.append(dw.get_collision_rect())

## Phase 3.3: Build level lock nodes from config
func _build_level_locks():
	for lk in _level_locks:
		if is_instance_valid(lk):
			lk.queue_free()
	_level_locks.clear()

	var locks_cfg: Array = level_config.get("locks", [])
	for cfg in locks_cfg:
		var lk = LevelLock.new() if ClassDB.class_exists("LevelLock") else null
		if lk == null:
			continue
		lk.position = Vector2(float(cfg.get("x", 0)), float(cfg.get("y", 360)))
		lk.required_keys = int(cfg.get("required_keys", 1))
		lk.gate_width  = float(cfg.get("w", 48))
		lk.gate_height = float(cfg.get("h", 120))
		add_child(lk)
		_level_locks.append(lk)
		var gate_rect = Rect2(lk.position.x - lk.gate_width * 0.5,
			lk.position.y - lk.gate_height, lk.gate_width, lk.gate_height)
		obstacle_rects.append(gate_rect)
		# Remove collision when gate opens
		lk.unlocked.connect(_on_level_lock_unlocked.bind(gate_rect))

func _on_level_lock_unlocked(_gate_node: LevelLock, gate_rect: Rect2):
	"""Remove gate's obstacle_rect once it finishes opening."""
	for i in range(obstacle_rects.size()):
		if obstacle_rects[i].is_equal_approx(gate_rect):
			obstacle_rects.remove_at(i)
			break

func _on_destructible_destroyed(wall: LevelDestructible):
	"""Remove wall's obstacle_rect so player can pass through."""
	var wall_rect = wall.get_collision_rect()
	for i in range(obstacle_rects.size()):
		if obstacle_rects[i].is_equal_approx(wall_rect):
			obstacle_rects.remove_at(i)
			break
	_destructible_walls.erase(wall)

## Phase 3.1: Call this from player dash/ground-pound handling
func try_dash_break_walls(pos: Vector2, vel: Vector2, game_ref) -> bool:
	"""Returns true if a wall was broken at pos. Player dash: horizontal vel > 350."""
	var broken = false
	for dw in _destructible_walls.duplicate():  # Duplicate to allow safe removal
		if not is_instance_valid(dw) or dw.is_destroyed:
			continue
		var r = dw.get_collision_rect()
		if r.has_point(pos) or r.has_point(pos + Vector2(vel.normalized().x * 18, 0)):
			var hit_type = "ground_pound" if vel.y > 300 else "dash"
			var damage = 30 if hit_type == "ground_pound" else 15
			dw.take_damage(damage, game_ref, hit_type)
			broken = true
	return broken

func _build_procedural_decor():
	_decor_rocks.clear()
	_decor_plants.clear()
	_decor_props.clear()
	_decor_pipes.clear()
	_decor_posts.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = int(level_config.get("id", 1)) * 7919 + int(level_width)
	var theme = level_config.get("theme", "grass")
	# Rocks/debris along floor edges (dense scatter)
	for rect in floor_rects:
		var count = int(rect.size.x / 45) + 4
		for i in range(count):
			var fx = rect.position.x + rng.randf_range(10, rect.size.x - 10)
			var fy = rect.position.y + rect.size.y - rng.randf_range(0, 8)
			_decor_rocks.append({"x": fx, "y": fy, "w": rng.randf_range(8, 24), "h": rng.randf_range(4, 14), "seed": rng.randi()})
	# Plants/bushes on floor tops (rich vegetation)
	for rect in floor_rects:
		var count = int(rect.size.x / 80) + 3
		for i in range(count):
			var fx = rect.position.x + rng.randf_range(30, rect.size.x - 30)
			var fy = rect.position.y + rng.randf_range(0, 6)
			_decor_plants.append({"x": fx, "y": fy, "h": rng.randf_range(12, 28), "w": rng.randf_range(14, 22), "seed": rng.randi()})
	# Platform props (crystals on platform tops, vines, etc.)
	for rect in platform_rects:
		var count = int(rect.size.x / 50) + 2
		for i in range(count):
			var fx = rect.position.x + rng.randf_range(8, rect.size.x - 8)
			var fy = rect.position.y - rng.randf_range(2, 12)
			_decor_props.append({"x": fx, "y": fy, "type": theme, "seed": rng.randi()})
	# Pipes/drains integrated into floor segments (grass, cave - Shantae-style)
	if theme == "grass" or theme == "cave":
		for rect in floor_rects:
			var pipe_count = maxi(1, int(rect.size.x / 400))
			for i in range(pipe_count):
				var px = rect.position.x + rng.randf_range(40, maxf(80, rect.size.x - 40))
				_decor_pipes.append({
					"x": px,
					"y": rect.position.y,
					"h": rect.size.y + rng.randf_range(20, 50),
					"w": rng.randf_range(24, 40),
					"has_water": rng.randf() < 0.4,
					"seed": rng.randi()
				})
	# Wooden dock posts (grass theme - pilings rising from floor/water edge)
	if theme == "grass":
		for rect in floor_rects:
			var post_count = maxi(0, int(rect.size.x / 350))
			for i in range(post_count):
				var gx = rect.position.x + rng.randf_range(60, rect.size.x - 60)
				_decor_posts.append({
					"x": gx,
					"y": rect.position.y + rect.size.y,
					"h": rng.randf_range(45, 85),
					"w": rng.randf_range(12, 20),
					"seed": rng.randi()
				})
	# Explicit decor from config
	for d in level_config.get("decor", []):
		_decor_props.append({
			"x": float(d.get("x", 0)),
			"y": float(d.get("y", 0)),
			"type": str(d.get("type", theme)),
			"seed": d.get("seed", rng.randi()),
			"explicit": true
		})

	# Phase 2.4: Crack/stain decal overlays at floor corners (vary by theme)
	_decor_cracks.clear()
	var crack_types = {
		"cave":   ["crack_v", "stain_dark", "crack_h"],
		"lava":   ["scorch", "crack_v", "scorch"],
		"summit": ["ice_crack", "frost", "ice_crack"],
		"ice":    ["ice_crack", "frost", "ice_crack"],
		"sky":    ["chip", "chip", "chip"],
		"default": ["crack_v", "crack_h", "stain_moss"],
	}
	var ctypes = crack_types.get(theme, crack_types["default"]) if crack_types.has(theme) else crack_types["default"]
	for rect in floor_rects:
		# Left corner crack
		if rng.randf() < 0.65:
			_decor_cracks.append({"x": rect.position.x + rng.randf_range(4, 28), "y": rect.position.y + rng.randf_range(2, 12), "type": ctypes[0], "seed": rng.randi()})
		# Right corner crack
		if rng.randf() < 0.60:
			_decor_cracks.append({"x": rect.position.x + rect.size.x - rng.randf_range(4, 30), "y": rect.position.y + rng.randf_range(2, 12), "type": ctypes[2], "seed": rng.randi()})
		# Mid-floor stains (sparse)
		var stain_count = int(rect.size.x / 200)
		for _s in range(stain_count):
			_decor_cracks.append({"x": rect.position.x + rng.randf_range(40, rect.size.x - 40), "y": rect.position.y + rng.randf_range(0, 8), "type": ctypes[1], "seed": rng.randi()})

	# Phase 5.2: Lava bubbles - built once in pit areas for lava theme
	_lava_bubbles.clear()
	if theme == "lava":
		for pit in _get_pit_rects():
			var bubble_count = int(pit.size.x / 60) + 3
			for _b in range(bubble_count):
				_lava_bubbles.append({
					"x": pit.position.x + rng.randf_range(10, pit.size.x - 10),
					"y": pit.position.y + rng.randf_range(pit.size.y * 0.4, pit.size.y - 8),
					"phase": rng.randf_range(0, TAU),
					"radius": rng.randf_range(5.0, 14.0)
				})

func _build_terrain_fill():
	"""AAA Upgrade: Fill gaps between platforms and level bounds for complete maps."""
	_floor_fill_rects.clear()
	_ceiling_fill_rects.clear()
	_wall_fill_rects.clear()

	# FLOOR FILL: Connect floor_rects to level bottom
	for floor in floor_rects:
		var fill_depth = level_height - (floor.position.y + floor.size.y)
		if fill_depth > 5:  # Only fill significant gaps
			_floor_fill_rects.append(Rect2(
				floor.position.x,
				floor.position.y + floor.size.y,
				floor.size.x,
				fill_depth
			))

	# CEILING FILL: Connect top platforms to level top
	for plat in platform_rects:
		if plat.position.y < level_height * 0.4:  # Upper half platforms
			var fill_depth = plat.position.y
			if fill_depth > 5:
				_ceiling_fill_rects.append(Rect2(
					plat.position.x,
					0,
					plat.size.x,
					fill_depth
				))

	# WALL FILL: Vertical edges
	if floor_rects.size() > 0:
		var leftmost = floor_rects[0].position.x
		var rightmost = floor_rects[0].position.x + floor_rects[0].size.x
		for floor in floor_rects:
			leftmost = minf(leftmost, floor.position.x)
			rightmost = maxf(rightmost, floor.position.x + floor.size.x)

		# Left wall from top to bottom
		if leftmost > 50:
			_wall_fill_rects.append(Rect2(0, 0, leftmost, level_height))

		# Right wall
		if rightmost < level_width - 50:
			_wall_fill_rects.append(Rect2(rightmost, 0, level_width - rightmost, level_height))

func _build_collision():
	floor_rects.clear()
	wall_rects.clear()
	platform_rects.clear()
	platform_collision_rects.clear()
	obstacle_rects.clear()
	_platform_path_types.clear()
	
	# Explicit floor segments (hand-crafted geometry - pits, elevated walkways)
	var floor_segments = level_config.get("floor_segments", [])
	if floor_segments.size() > 0:
		for seg in floor_segments:
			var x_min = float(seg.get("x_min", 0))
			var x_max = float(seg.get("x_max", level_width))
			var y_min = float(seg.get("y_min", 300))
			var y_max = float(seg.get("y_max", 420))
			floor_rects.append(Rect2(x_min, y_min, x_max - x_min, y_max - y_min))
	else:
		# Fallback: build from layers (full-width strips)
		var layers = level_config.get("layers", [])
		for layer in layers:
			var layer_type = layer.get("type", "ground")
			if layer_type == "ground" or layer_type == "cave":
				var y_min = float(layer.get("y_min", 280))
				var y_max = float(layer.get("y_max", 420))
				floor_rects.append(Rect2(0, y_min, level_width, y_max - y_min))
	
	var layers = level_config.get("layers", [])
	var platform_layer_ids: Array[String] = []
	for layer in layers:
		var layer_type = layer.get("type", "ground")
		if layer_type == "platform" or layer_type == "skybridge":
			platform_layer_ids.append(str(layer.get("id", "platform")))
	
	# Explicit platforms from config - use config w,h (from LevelPlatform.size when node-based)
	var explicit_platforms = level_config.get("platforms", [])
	var use_sprite_surface = platform_sprite != null
	var default_frac = float(level_config.get("platform_surface_fraction", PLATFORM_SURFACE_FRACTION))
	for p in explicit_platforms:
		var x = float(p.get("x", 0))
		var y = float(p.get("y", 200))
		var w = float(p.get("w", 120))
		var h = float(p.get("h", 24))
		var full_rect: Rect2
		if p.get("centered", false):
			full_rect = Rect2(x - w / 2, y - h / 2, w, h)
		else:
			full_rect = Rect2(x, y, w, h)
		platform_rects.append(full_rect)
		_platform_path_types.append(str(p.get("path_type", "main")))
		# Collision: align to visual walkable surface (per-platform surface_fraction for different sprites)
		if use_sprite_surface:
			var frac = float(p.get("surface_fraction", default_frac))
			var surf_y = full_rect.position.y + full_rect.size.y * frac
			var coll_h = full_rect.size.y * (1.0 - frac)
			platform_collision_rects.append(Rect2(full_rect.position.x, surf_y, full_rect.size.x, coll_h))
		else:
			platform_collision_rects.append(full_rect)
	
	# Build from spawn zones (one platform per zone)
	var platform_height = 22.0
	var segments = level_config.get("segments", [])
	for seg in segments:
		for zone in seg.get("spawn_zones", []):
			var zone_layer = str(zone.get("layer", "surface"))
			if zone_layer in platform_layer_ids:
				var x_min = float(zone.get("x_min", 0))
				var x_max = float(zone.get("x_max", 100))
				var y_max_z = float(zone.get("y_max", 260))
				var w = maxf(60.0, x_max - x_min)
				var plat_y = y_max_z - platform_height
				var full_rect = Rect2(x_min, plat_y, w, platform_height)
				platform_rects.append(full_rect)
				if use_sprite_surface:
					var frac = float(level_config.get("platform_surface_fraction", PLATFORM_SURFACE_FRACTION))
					var surf_y = full_rect.position.y + full_rect.size.y * frac
					var coll_h = full_rect.size.y * (1.0 - frac)
					platform_collision_rects.append(Rect2(full_rect.position.x, surf_y, full_rect.size.x, coll_h))
				else:
					platform_collision_rects.append(full_rect)
	
	# Walls: left, right, top, bottom
	var wall_w = 50.0
	wall_rects.append(Rect2(-wall_w, -wall_w, wall_w, level_height + wall_w * 2))
	wall_rects.append(Rect2(level_width, -wall_w, wall_w, level_height + wall_w * 2))
	wall_rects.append(Rect2(-wall_w, -wall_w, level_width + wall_w * 2, wall_w))
	wall_rects.append(Rect2(-wall_w, level_height, level_width + wall_w * 2, wall_w))
	# Interior wall segments (for wall-jump sections)
	for w in level_config.get("wall_segments", []):
		var wx = float(w.get("x", 0))
		var wy = float(w.get("y", 0))
		var ww = float(w.get("w", 20))
		var wh = float(w.get("h", 200))
		wall_rects.append(Rect2(wx, wy, ww, wh))

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

## Returns spawn position for player. Uses floor_segments if present, else layer-based spawn.
func get_spawn_position() -> Vector2:
	if floor_rects.size() == 0:
		var layers = level_config.get("layers", [])
		var y_min = float(layers[0].get("y_min", 280)) if layers.size() > 0 else 280.0
		return Vector2(80.0, y_min - 26.0)
	# Use leftmost floor that contains x=80 or is near start
	var best = floor_rects[0]
	for rect in floor_rects:
		if rect.position.x < best.position.x:
			best = rect
		elif rect.position.x == best.position.x and rect.position.y < best.position.y:
			best = rect
	var spawn_x = clampf(80.0, best.position.x + 30, best.position.x + best.size.x - 30)
	return Vector2(spawn_x, best.position.y - 26.0)

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
	for rect in platform_collision_rects:
		if pos.y + radius > rect.position.y and pos.y - radius < rect.position.y + rect.size.y:
			pos = _push_out_of_rect(pos, radius, rect)
	for rect in obstacle_rects:
		pos = _push_out_of_rect(pos, radius, rect)
	return pos

## Sideview (front-view) collision for Main Game beat-em-up mode.
## Returns {position: Vector2, velocity: Vector2} with resolved collision and velocity.
func resolve_sideview_collision(pos: Vector2, vel: Vector2, radius: float, ignore_platforms: bool) -> Dictionary:
	for rect in wall_rects:
		var prev = pos
		pos = _push_out_of_rect(pos, radius, rect)
		# Only zero velocity if we actually collided with this wall (position changed)
		if pos.distance_to(prev) > 0.01:
			if rect.size.x < rect.size.y:
				vel.x = 0.0
			else:
				vel.y = 0.0
	for rect in floor_rects:
		var prev_pos = pos
		pos = _push_out_of_rect(pos, radius, rect)
		if pos.y < prev_pos.y:
			vel.y = 0.0
	for rect in platform_collision_rects:
		if ignore_platforms:
			continue
		if vel.y >= 0 and pos.y + radius >= rect.position.y - 2 and pos.y - radius <= rect.position.y + rect.size.y + 2:
			var prev_pos = pos
			pos = _push_out_of_rect(pos, radius, rect)
			if pos.y < prev_pos.y:
				vel.y = 0.0
	for rect in obstacle_rects:
		var prev = pos
		pos = _push_out_of_rect(pos, radius, rect)
		if pos.distance_to(prev) > 0.01:
			vel.x = 0.0
			vel.y = 0.0
	return {"position": pos, "velocity": vel}

## Returns true if position is standing on floor or platform (for sideview ground check).
func get_ground_check(pos: Vector2, radius: float) -> bool:
	return get_ground_surface_y(pos, radius) < INF

## Returns the Y coordinate of the top of the surface we're standing on (floor/platform).
## Returns INF if not on ground. Use for ground snap to prevent floating.
func get_ground_surface_y(pos: Vector2, radius: float) -> float:
	var foot_y = pos.y + radius
	var above_tolerance = 4.0   # Allow feet slightly above surface (pre-landing)
	var below_tolerance = 18.0  # Allow feet slightly into surface (post-collision)
	var best_surface_y = INF
	for rect in floor_rects:
		if pos.x + radius >= rect.position.x and pos.x - radius <= rect.position.x + rect.size.x:
			if foot_y >= rect.position.y - above_tolerance and foot_y <= rect.position.y + below_tolerance:
				best_surface_y = minf(best_surface_y, rect.position.y)
	for rect in platform_collision_rects:
		if pos.x + radius >= rect.position.x and pos.x - radius <= rect.position.x + rect.size.x:
			if foot_y >= rect.position.y - above_tolerance and foot_y <= rect.position.y + below_tolerance:
				best_surface_y = minf(best_surface_y, rect.position.y)
	return best_surface_y

## Returns true if there is a vertical wall within radius in the given direction (-1=left, 1=right). For wall jump.
func get_wall_at_position(pos: Vector2, radius: float, dir: int) -> bool:
	var check = pos + Vector2(radius * 1.5 * dir, 0)
	for rect in wall_rects:
		if rect.size.x < rect.size.y:
			if rect.has_point(check):
				return true
	return false

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

func is_line_walkable_static(from_pos: Vector2, to_pos: Vector2, radius: float = 10.0) -> bool:
	"""Line test against static world geometry. LinearMap has no dynamic blockers; same as is_line_walkable."""
	return is_line_walkable(from_pos, to_pos, radius)

func get_nearest_entrance(from_pos: Vector2) -> int:
	"""FortMap compatibility: return nearest entrance index. Uses entrance_positions."""
	if entrance_positions.is_empty():
		return 0
	var best = 0
	var best_dist = INF
	for i in range(entrance_positions.size()):
		var d = from_pos.distance_to(entrance_positions[i])
		if d < best_dist:
			best_dist = d
			best = i
	return best

func get_entrance_position(index: int) -> Vector2:
	"""FortMap compatibility: return entrance position by index."""
	if index >= 0 and index < entrance_positions.size():
		return entrance_positions[index]
	if entrance_positions.size() > 0:
		return entrance_positions[0]
	return Vector2(level_width * 0.5, level_height * 0.5)

func get_barricade(_index: int):
	"""FortMap compatibility: LinearMap has no barricades."""
	return null

func get_fort_center() -> Vector2:
	"""FortMap compatibility: return level center."""
	return Vector2(level_width * 0.5, level_height * 0.5)

func get_random_spawn_point() -> Vector2:
	"""FortMap compatibility: return random spawn in first zone or level center."""
	var segs = level_config.get("segments", [])
	for seg in segs:
		for zone in seg.get("spawn_zones", []):
			return get_random_spawn_in_zone(zone)
	return Vector2(level_width * 0.5, level_height * 0.5)

func get_nearest_barricade_in_range(_pos: Vector2, _range_dist: float):
	return null

func get_nearest_door_in_range(_pos: Vector2, _range_dist: float):
	return null

func get_nearest_closed_door(_pos: Vector2, _range_dist: float):
	"""Returns the nearest closed (blocking) door within range. LinearMap has no doors; stub for compatibility."""
	return null

func get_blocking_door_on_line(_from_pos: Vector2, _to_pos: Vector2, _radius: float = 10.0):
	"""Returns first closed door blocking travel along a segment. LinearMap has no doors; stub for compatibility."""
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

# Phase 3.2: Alternate route path type accent colors (used in _draw)
const PATH_ACCENT: Dictionary = {
	"high": Color(1.0, 0.85, 0.2, 0.80),  # Gold edge — high/risky route
	"low":  Color(0.3, 0.85, 0.7, 0.70),  # Teal edge — low/secret route
	"main": Color(0, 0, 0, 0),             # No accent for main path
}

# Theme-based colors: [floor_fill, floor_edge, platform_fill, platform_top, platform_shadow, decor_accent]
const THEME_COLORS = {
	"grass": [Color8(75, 95, 55), Color8(55, 75, 40), Color8(140, 115, 80), Color8(175, 145, 100), Color8(45, 55, 35), Color8(85, 140, 75)],
	"cave": [Color8(58, 50, 62), Color8(42, 36, 48), Color8(95, 85, 90), Color8(120, 108, 115), Color8(30, 26, 35), Color8(140, 160, 200)],
	"sky": [Color8(135, 150, 175), Color8(100, 120, 150), Color8(165, 175, 195), Color8(195, 205, 220), Color8(80, 95, 120), Color8(220, 230, 245)],
	"summit": [Color8(155, 165, 175), Color8(125, 135, 145), Color8(170, 178, 188), Color8(200, 208, 218), Color8(100, 110, 120), Color8(185, 195, 205)],
	"lava": [Color8(65, 35, 30), Color8(45, 22, 18), Color8(95, 55, 45), Color8(125, 75, 60), Color8(35, 18, 15), Color8(180, 85, 50)],
	"ice": [Color8(165, 185, 200), Color8(135, 160, 180), Color8(185, 200, 215), Color8(210, 225, 240), Color8(100, 120, 140), Color8(200, 220, 240)]
}

func _get_theme_colors() -> Array:
	var theme = level_config.get("theme", "grass")
	return THEME_COLORS.get(theme, THEME_COLORS["grass"])

func _get_pit_rects() -> Array:
	"""Returns rects for gaps between floor segments (pits/chasms to fill with dark)."""
	var pits: Array = []
	var floor_segments = level_config.get("floor_segments", [])
	if floor_segments.size() < 2:
		return pits
	var sorted = floor_segments.duplicate()
	sorted.sort_custom(func(a, b): return a.get("x_min", 0) < b.get("x_min", 0))
	for i in range(sorted.size() - 1):
		var left = sorted[i]
		var right = sorted[i + 1]
		var gap_start = left.get("x_max", 0)
		var gap_end = right.get("x_min", 0)
		if gap_end > gap_start:
			var pit_bottom = level_height + 50
			var pit_top = minf(float(left.get("y_min", 400)), float(right.get("y_min", 400))) - 5
			pits.append(Rect2(gap_start, pit_top, gap_end - gap_start, pit_bottom - pit_top))
	return pits

func is_position_over_pit(pos: Vector2) -> bool:
	"""Check if a position is over a pit/chasm."""
	for pit in _get_pit_rects():
		if pit.has_point(pos):
			return true
	return false

func _get_theme_fill_color(theme: String) -> Color:
	"""AAA Upgrade: Theme-specific fill colors for terrain completion."""
	match theme:
		"grass": return Color8(75, 95, 60)
		"cave": return Color8(45, 40, 50)
		"sky": return Color8(120, 140, 160)
		"summit": return Color8(160, 165, 175)
		"lava": return Color8(60, 35, 25)
		"ice": return Color8(140, 160, 180)
		_: return Color8(80, 80, 90)

func _draw():
	# Skip full background when ParallaxBackdrop is active (it draws themed sky/hills)
	var use_parallax = game != null and "parallax_backdrop" in game and game.parallax_backdrop != null
	if use_parallax:
		pass  # ParallaxBackdrop draws the background
	elif bg_texture:
		var tex_size = bg_texture.get_size()
		var sx = level_width / tex_size.x
		var sy = level_height / tex_size.y
		draw_set_transform(Vector2.ZERO, 0, Vector2(sx, sy))
		draw_texture(bg_texture, Vector2.ZERO, bg_tint)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_rect(Rect2(0, 0, level_width, level_height), Color8(52, 90, 40))

	# Pits/chasms - dark void with depth gradient (draw before floor so floor overlaps edges)
	var pit_colors = {"grass": Color8(25, 35, 30), "cave": Color8(8, 6, 12), "sky": Color8(60, 80, 120), "summit": Color8(40, 50, 65), "lava": Color8(20, 8, 6), "ice": Color8(50, 70, 90)}
	var theme = level_config.get("theme", "grass")
	var pit_col = pit_colors.get(theme, Color8(25, 35, 30))
	for pit in _get_pit_rects():
		draw_rect(pit, pit_col)
		# Inner darker strip (depth illusion)
		draw_rect(Rect2(pit.position.x + 8, pit.position.y, pit.size.x - 16, pit.size.y), pit_col.darkened(0.25))
		# Top edge shadow
		draw_rect(Rect2(pit.position.x, pit.position.y, pit.size.x, 8), Color(0, 0, 0, 0.4))

	# AAA Upgrade: Terrain fill - complete map appearance
	var fill_color = _get_theme_fill_color(theme)

	# Floor fill (below floor segments to level bottom)
	for rect in _floor_fill_rects:
		draw_rect(rect, fill_color)
		# Add texture overlay if available
		if terrain_texture:
			var tile_size = 64.0
			var tiles_x = int(ceil(rect.size.x / tile_size))
			var tiles_y = int(ceil(rect.size.y / tile_size))
			for ty in range(tiles_y):
				for tx in range(tiles_x):
					var tile_x = rect.position.x + tx * tile_size
					var tile_y = rect.position.y + ty * tile_size
					var tile_w = min(tile_size, rect.position.x + rect.size.x - tile_x)
					var tile_h = min(tile_size, rect.position.y + rect.size.y - tile_y)
					draw_texture_rect_region(terrain_texture,
						Rect2(tile_x, tile_y, tile_w, tile_h),
						Rect2(0, 0, tile_w, tile_h),
						Color(0.8, 0.8, 0.8, 1.0))  # Slightly darker
		# Top edge shadow (blend with floor segment)
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 8), Color(0, 0, 0, 0.3))

	# Ceiling fill (above upper platforms to level top)
	for rect in _ceiling_fill_rects:
		draw_rect(rect, fill_color.darkened(0.2))
		# Bottom edge shadow
		draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 6, rect.size.x, 6), Color(0, 0, 0, 0.25))

	# Wall fill (vertical edges)
	for rect in _wall_fill_rects:
		draw_rect(rect, fill_color.darkened(0.15))

	var pal = _get_theme_colors()
	var floor_fill: Color = pal[0]
	var floor_edge: Color = pal[1]
	var plat_fill: Color = pal[2]
	var plat_top: Color = pal[3]
	var plat_shadow: Color = pal[4]
	
	# Floor - textured with depth and lighting
	for rect in floor_rects:
		var edge_h = minf(14.0, rect.size.y * 0.2)

		# Draw tiled terrain texture
		if terrain_texture:
			var tile_size = 64.0
			var tiles_x = int(ceil(rect.size.x / tile_size))
			var tiles_y = int(ceil(rect.size.y / tile_size))

			for ty in range(tiles_y):
				for tx in range(tiles_x):
					var tile_x = rect.position.x + tx * tile_size
					var tile_y = rect.position.y + ty * tile_size
					var tile_w = min(tile_size, rect.position.x + rect.size.x - tile_x)
					var tile_h = min(tile_size, rect.position.y + rect.size.y - tile_y)

					# Apply lighting gradient (darker at bottom for depth)
					var depth_factor = float(ty) / max(tiles_y, 1)
					var tint = Color(1.0 - depth_factor * 0.15, 1.0 - depth_factor * 0.15, 1.0 - depth_factor * 0.15, 1.0)

					# Draw textured tile
					draw_texture_rect_region(
						terrain_texture,
						Rect2(tile_x, tile_y, tile_w, tile_h),
						Rect2(0, 0, tile_w, tile_h),
						tint
					)
		else:
			# Fallback to solid color if texture missing
			draw_rect(rect, floor_fill)

		# Top edge band (front face - the visible cliff/terrain edge)
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, edge_h), floor_edge.lightened(0.12))
		# Edge highlight line
		draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y), floor_edge.lightened(0.3), 1.5)

		# 2.5D: Depth recession gradient on floor surface — top of rect is far, darkens slightly
		# Simulates the ground plane receding away from the viewer (Hollow Knight / Shantae style)
		var grad_steps = 6
		var grad_zone = minf(rect.size.y * 0.45, 60.0)
		for gi in range(grad_steps):
			var t = float(gi) / float(grad_steps)
			var fog_alpha = t * t * 0.22   # quadratic: subtle at front, stronger at back
			var gy = rect.position.y + t * grad_zone
			var gh = grad_zone / float(grad_steps) + 1.0
			draw_rect(Rect2(rect.position.x, gy, rect.size.x, gh),
				Color(0.05, 0.08, 0.18, fog_alpha))
		# Left/right vertical edges (for segmented floors)
		draw_rect(Rect2(rect.position.x, rect.position.y, 6, rect.size.y), floor_edge.darkened(0.1))
		draw_rect(Rect2(rect.position.x + rect.size.x - 6, rect.position.y, 6, rect.size.y), floor_edge.darkened(0.1))

		# Edge detail along top (grass tufts, rocks, crystals by theme)
		var rng2 = RandomNumberGenerator.new()
		rng2.seed = int(rect.position.x) * 31 + int(rect.position.y)
		# Phase 2.4: 1.5x grass density (every 27px instead of 40px)
		var blade_spacing = 27 if theme == "grass" else 40
		for _j in range(int(rect.size.x / blade_spacing) + 1):
			var gx = rect.position.x + rng2.randf_range(8, rect.size.x - 8)
			var gy = rect.position.y + rng2.randf_range(0, 5)
			match theme:
				"grass":
					var gh = rng2.randf_range(6, 14)
					# Phase 2.1: Grass sway + player-proximity bend
					var tuft_seed = float(rng2.randi() % 1000) * 0.001
					# Phase 2.4: Primary + secondary wind layer (cos offset)
					var idle_sway_x = sin(tuft_seed * TAU + anim_time * 2.3) * 2.0 \
									 + cos(tuft_seed * TAU * 1.7 + anim_time * 1.2) * 1.5
					var tuft_pos = Vector2(gx, gy)
					var dist_to_player = _player_pos.distance_to(tuft_pos)
					var bend_x = 0.0
					if dist_to_player < 80.0:
						var bend_strength = 1.0 - clamp(dist_to_player / 80.0, 0.0, 1.0)
						var bend_dir = sign(tuft_pos.x - _player_pos.x) if tuft_pos.x != _player_pos.x else 1.0
						bend_x = bend_dir * bend_strength * gh * 0.45
					var tip_x = gx + idle_sway_x + bend_x
					var tip_y = gy - gh
					draw_line(Vector2(gx, gy), Vector2(tip_x, tip_y), pal[5], 1.5)
					# Darker base blade
					draw_line(Vector2(gx, gy), Vector2(gx + (tip_x - gx) * 0.5, gy - gh * 0.5), pal[5].darkened(0.2), 1.5)
					# Phase 2.4: Secondary shorter blade for depth layering
					if rng2.randf() < 0.55:
						var gh2 = gh * rng2.randf_range(0.45, 0.75)
						var gx2 = gx + rng2.randf_range(-5.0, 5.0)
						var sway2 = sin(tuft_seed * TAU * 2.1 + anim_time * 1.9) * 1.2
						var tip2_x = gx2 + sway2 * 0.6 + bend_x * 0.5
						draw_line(Vector2(gx2, gy), Vector2(tip2_x, gy - gh2), pal[5].darkened(0.12), 1.0)
				"cave":
					draw_rect(Rect2(gx - 2, gy - 6, 4, 6), floor_edge.lightened(0.1))
				"summit", "ice":
					draw_circle(Vector2(gx, gy - 2), 3, Color(0.95, 0.97, 1.0, 0.5))
				_:
					draw_rect(Rect2(gx - 1, gy - 4, 2, 4), floor_edge)
		# Subtle tile/crack lines (every 96px)
		var tile_w = 96.0
		var tx = rect.position.x + fmod(anim_time * 0.5, tile_w)
		while tx < rect.position.x + rect.size.x:
			draw_line(Vector2(tx, rect.position.y + edge_h), Vector2(tx, rect.position.y + rect.size.y), Color(0, 0, 0, 0.06), 1.0)
			tx += tile_w
	
	# Sky theme: support pillars/chains below platforms
	if theme == "sky":
		for rect in platform_rects:
			var cx = rect.position.x + rect.size.x * 0.5
			var top = rect.position.y + rect.size.y
			var pillar_h = minf(80.0, level_height - top - 50)
			if pillar_h > 15:
				draw_rect(Rect2(cx - 3, top, 6, pillar_h), Color8(100, 90, 75, 180))
				draw_rect(Rect2(cx - 2, top, 4, pillar_h * 0.3), Color8(130, 115, 95, 200))

	# Platforms - platform1.png sprite (1:1 fit) or fallback to procedural
	for _pi in range(platform_rects.size()):
		var rect = platform_rects[_pi]
		var px = rect.position.x
		var py = rect.position.y
		var pw = rect.size.x
		var ph = rect.size.y
		var path_type: String = _platform_path_types[_pi] if _pi < _platform_path_types.size() else "main"

		if platform_sprite:
			# Draw sprite at native size - no procedural shadow, image has its own shading
			draw_texture_rect(platform_sprite, Rect2(px, py, pw, ph), false)
		else:
			# Procedural platforms: shadow then texture
			var shadow_offset = 6.0
			draw_rect(Rect2(px + shadow_offset + 2, py + shadow_offset + 2, pw, ph), Color(0, 0, 0, 0.15))
			draw_rect(Rect2(px + shadow_offset, py + shadow_offset, pw, ph), Color(0, 0, 0, 0.25))
		if not platform_sprite and platform_texture:
			var tile_size = 64.0
			var tiles_x = int(ceil(pw / tile_size))
			var tiles_y = int(ceil(ph / tile_size))

			for ty in range(tiles_y):
				for tx in range(tiles_x):
					var tile_x = px + tx * tile_size
					var tile_y = py + ty * tile_size
					var tile_w = min(tile_size, px + pw - tile_x)
					var tile_h = min(tile_size, py + ph - tile_y)

					draw_texture_rect_region(
						platform_texture,
						Rect2(tile_x, tile_y, tile_w, tile_h),
						Rect2(0, 0, tile_w, tile_h),
						Color(1, 1, 1, 1)
					)
		elif not platform_sprite:
			# Fallback to beveled platform
			draw_rect(Rect2(px, py, pw, ph), plat_fill)
			draw_rect(Rect2(px, py, pw, 6), plat_top)
			draw_rect(Rect2(px, py + 6, 4, ph - 6), plat_fill.darkened(0.08))
			draw_rect(Rect2(px + pw - 4, py + 6, 4, ph - 6), plat_fill.darkened(0.08))

		# Theme-specific platform overlays (skip for sprite - has its own look)
		if not platform_sprite and (theme == "summit" or theme == "ice"):
			# Snow accumulation on platform tops
			draw_rect(Rect2(px, py - 2, pw, 4), Color(0.95, 0.98, 1.0, 0.7))
			draw_rect(Rect2(px + 4, py - 4, pw - 8, 3), Color(1, 1, 1, 0.5))

		# Phase 3.2: Alternate route accent edge (2px glowing top border)
		var path_accent: Color = PATH_ACCENT.get(path_type, Color(0, 0, 0, 0))
		if path_accent.a > 0.01:
			draw_rect(Rect2(px + 2, py, pw - 4, 2), path_accent)
			# Small bracket markers at corners to indicate route type
			draw_rect(Rect2(px, py - 2, 8, 4), path_accent)
			draw_rect(Rect2(px + pw - 8, py - 2, 8, 4), path_accent)

	# AAA Visual Overhaul Phase 7: Re-enable lighting with toon quantization
	if lighting_system and terrain_normal:
		# TOON-STEPPED LIGHTING: Quantize lighting to 3 discrete steps (shadow, mid, lit)
		# Reduced resolution (sample every 40px) for performance
		var sample_res = 40  # Sample grid resolution
		for rect in floor_rects:
			var cols = max(1, int(rect.size.x / sample_res))
			var rows = max(1, int(rect.size.y / sample_res))

			for ry in range(rows):
				for rx in range(cols):
					var sample_x = rect.position.x + rx * sample_res
					var sample_y = rect.position.y + ry * sample_res
					var uv = Vector2((sample_x - rect.position.x) / rect.size.x, (sample_y - rect.position.y) / rect.size.y)

					# Sample normal and calculate lighting
					var normal = lighting_system.sample_normal_map(terrain_normal, uv)
					var light_col = lighting_system.calculate_lighting(normal)

					# AAA: TOON QUANTIZATION - posterize to 3 steps
					var brightness = (light_col.r + light_col.g + light_col.b) / 3.0
					var toon_step = 0.0
					if brightness > 0.65:
						toon_step = 0.0  # Lit - no darkening
					elif brightness > 0.4:
						toon_step = 0.15  # Mid - slight darkening
					else:
						toon_step = 0.3  # Shadow - noticeable darkening

					# Apply toon-stepped lighting overlay
					if toon_step > 0.01:
						draw_rect(Rect2(sample_x, sample_y, sample_res, sample_res), Color(0, 0, 0, toon_step))

		# Ambient occlusion at terrain corners (cel-shaded hard edges)
		for rect in floor_rects:
			if rect.size.y > 60:
				# Sharp AO corners (no gradient - cartoon style)
				draw_rect(Rect2(rect.position.x, rect.position.y, 18, 18), Color(0, 0, 0, 0.2))
				draw_rect(Rect2(rect.position.x + rect.size.x - 18, rect.position.y, 18, 18), Color(0, 0, 0, 0.2))

	# Rocks/debris along floor bottoms
	var rock_col = floor_edge.darkened(0.2)
	for r in _decor_rocks:
		var rx = r.x - r.w * 0.5
		var ry = r.y - r.h
		draw_rect(Rect2(rx, ry, r.w, r.h), rock_col)
		draw_rect(Rect2(rx + 2, ry + 2, r.w * 0.6, r.h * 0.5), rock_col.lightened(0.1))

	# Plants/bushes on floor tops (theme-specific)
	for p in _decor_plants:
		var px = p.x - p.w * 0.5
		var py = p.y
		match theme:
			"grass":
				draw_rect(Rect2(px, py - p.h, p.w, p.h), pal[5].darkened(0.1))
				draw_rect(Rect2(px + p.w * 0.2, py - p.h * 0.6, p.w * 0.5, p.h * 0.5), pal[5])
				draw_circle(Vector2(px + p.w * 0.5, py - p.h + 6), 4, Color(1, 0.85, 0.3, 0.7))
			"cave":
				draw_rect(Rect2(px + p.w * 0.2, py - p.h * 0.5, 4, p.h * 0.5), Color8(90, 75, 65))
				draw_rect(Rect2(px, py - p.h * 0.4, p.w * 0.6, p.h * 0.25), Color8(120, 100, 110))
			"sky":
				draw_rect(Rect2(px, py - p.h * 0.8, p.w * 0.4, p.h * 0.8), Color8(140, 160, 180))
				draw_circle(Vector2(px + p.w * 0.5, py - p.h + 4), 6, Color8(200, 220, 240, 200))
			"summit", "ice":
				draw_rect(Rect2(px + 2, py - p.h * 0.6, 6, p.h * 0.6), Color8(180, 190, 200))
				draw_circle(Vector2(px + p.w * 0.5, py - p.h + 3), 5, Color(0.95, 0.97, 1.0, 0.8))
			_:
				draw_rect(Rect2(px, py - p.h, p.w, p.h), pal[5].darkened(0.15))

	# Platform props (crystals, vines, chains)
	for prop in _decor_props:
		var px = prop.x
		var py = prop.y
		var pt = str(prop.get("type", theme))
		match pt:
			"grass":
				draw_line(Vector2(px, py + 20), Vector2(px + 4, py), pal[5].darkened(0.2), 2.0)
				draw_circle(Vector2(px + 4, py - 2), 5, pal[5])
			"cave":
				draw_rect(Rect2(px - 3, py - 18, 6, 18), Color8(140, 160, 200, 220))
				draw_rect(Rect2(px - 2, py - 16, 4, 6), Color8(180, 200, 255, 150))
			"sky":
				draw_line(Vector2(px, py + 15), Vector2(px, py - 8), Color8(120, 100, 80), 1.5)
				draw_circle(Vector2(px, py - 10), 4, Color8(200, 190, 170))
			"summit", "ice":
				draw_rect(Rect2(px - 2, py - 14, 4, 14), Color(0.9, 0.95, 1.0, 0.6))
				draw_rect(Rect2(px - 1, py - 12, 2, 4), Color(1, 1, 1, 0.4))
			_:
				draw_circle(Vector2(px, py - 5), 4, pal[3])

	# Pipes/drains - metal structures in foreground (Shantae-style)
	var pipe_metal = Color8(55, 60, 65)
	var pipe_dark = Color8(38, 42, 48)
	for pipe in _decor_pipes:
		var pipe_x = pipe.x - pipe.w * 0.5
		var pipe_y = pipe.y
		# Pipe body (vertical cylinder illusion)
		draw_rect(Rect2(pipe_x + 2, pipe_y, pipe.w - 4, pipe.h), pipe_metal)
		draw_rect(Rect2(pipe_x, pipe_y + 4, 4, pipe.h - 8), pipe_dark)
		draw_rect(Rect2(pipe_x + pipe.w - 4, pipe_y + 4, 4, pipe.h - 8), pipe_metal.lightened(0.15))
		# Grate/opening at top
		draw_rect(Rect2(pipe_x + 4, pipe_y, pipe.w - 8, 6), pipe_dark)
		if pipe.get("has_water", false):
			# Green-tinted water flowing out
			draw_rect(Rect2(pipe_x + 6, pipe_y + 6, pipe.w - 12, 12), Color8(40, 100, 90, 180))
	# Wooden dock posts - pilings rising from floor edge (grass theme)
	var post_wood = Color8(75, 55, 40)
	var post_top = Color8(95, 75, 55)
	for pt in _decor_posts:
		var ptx = pt.x - pt.w * 0.5
		var pty = pt.y - pt.h
		draw_rect(Rect2(ptx, pty, pt.w, pt.h), post_wood)
		draw_rect(Rect2(ptx + 1, pty, pt.w - 2, 8), post_top)
		# Rope wrap / barnacle accent
		draw_rect(Rect2(ptx, pty + pt.h * 0.6, pt.w, 4), Color8(90, 85, 75))

	# Phase 2.4: Crack / stain decals at floor surface corners
	var crack_col = Color(0.0, 0.0, 0.0, 0.18)
	var stain_col = Color(0.05, 0.08, 0.02, 0.22)
	for cr in _decor_cracks:
		var cx = float(cr.x)
		var cy = float(cr.y)
		var ctype = str(cr.type)
		match ctype:
			"crack_v":
				# Vertical crack line with fork
				draw_line(Vector2(cx, cy), Vector2(cx + 2, cy + 12), crack_col, 1.2)
				draw_line(Vector2(cx + 2, cy + 12), Vector2(cx + 4, cy + 20), crack_col, 1.0)
				draw_line(Vector2(cx + 2, cy + 12), Vector2(cx - 2, cy + 18), crack_col, 0.8)
			"crack_h":
				# Horizontal crack
				draw_line(Vector2(cx, cy + 4), Vector2(cx + 22, cy + 5), crack_col, 1.1)
				draw_line(Vector2(cx + 8, cy + 5), Vector2(cx + 14, cy + 8), crack_col, 0.8)
			"stain_dark", "stain_moss":
				# Irregular stain patch
				draw_rect(Rect2(cx - 8, cy, 16, 5), stain_col)
				draw_rect(Rect2(cx - 5, cy + 2, 10, 4), stain_col)
			"scorch":
				# Lava scorch mark
				draw_rect(Rect2(cx - 10, cy, 20, 6), Color(0.0, 0.0, 0.0, 0.28))
				draw_circle(Vector2(cx, cy + 3), 4.0, Color(0.25, 0.08, 0.02, 0.35))
			"ice_crack":
				# Ice crack - thin and angular
				draw_line(Vector2(cx, cy), Vector2(cx + 8, cy + 6), Color(0.8, 0.9, 1.0, 0.35), 1.0)
				draw_line(Vector2(cx + 8, cy + 6), Vector2(cx + 16, cy + 3), Color(0.8, 0.9, 1.0, 0.25), 0.8)
			"frost":
				# Frost patch
				draw_rect(Rect2(cx - 7, cy, 14, 4), Color(0.85, 0.92, 1.0, 0.30))
			"chip":
				# Small chip mark
				draw_rect(Rect2(cx - 3, cy, 6, 4), crack_col)
			_:
				draw_line(Vector2(cx, cy), Vector2(cx + 6, cy + 8), crack_col, 1.0)

	# Chain links - grapplable swing points in pits (recovery mechanic)
	var chain_metal = Color8(70, 75, 85)
	var chain_highlight = Color8(100, 105, 115)
	for cl in chain_links:
		var cx = cl.x if cl is Vector2 else float(cl.get("x", 0))
		var cy = cl.y if cl is Vector2 else float(cl.get("y", 0))
		# Ring/hook at anchor point
		draw_rect(Rect2(cx - 10, cy - 4, 20, 10), chain_metal)
		draw_rect(Rect2(cx - 8, cy - 2, 16, 6), chain_highlight)
		# Hanging chain links below (3-4 oval links)
		var link_h = 8.0
		for i in range(4):
			var ly = cy + 4 + i * link_h
			draw_rect(Rect2(cx - 4, ly, 8, 6), chain_metal)
			draw_rect(Rect2(cx - 3, ly + 1, 6, 4), chain_highlight)
		# Subtle glow to indicate grapplable
		var pulse = 0.5 + 0.25 * sin(anim_time * 5.0 + cx * 0.01)
		draw_rect(Rect2(cx - 12, cy - 6, 24, 44), Color(0.3, 0.6, 1.0, pulse * 0.08))

	# Checkpoint markers - glowing posts
	var font = ThemeDB.fallback_font
	for i in range(checkpoints.size()):
		var cp = checkpoints[i]
		var cx = cp.get("x", 0)
		var cy = cp.get("y", 350)
		var pulse = 0.7 + 0.3 * sin(anim_time * 4.0 + i)
		draw_rect(Rect2(cx - 32, cy - 48, 64, 100), Color(0.2, 0.9, 0.5, 0.15 * pulse))
		draw_rect(Rect2(cx - 28, cy - 44, 56, 92), Color8(40, 180, 100, 200))
		draw_rect(Rect2(cx - 28, cy - 44, 56, 92), Color8(60, 220, 130, pulse * 255), false, 2.5)
		draw_string(font, Vector2(cx - 12, cy + 8), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 22, 16, Color.WHITE)
	
	# Goal - dramatic golden arch
	draw_rect(Rect2(goal_rect.position.x - 10, goal_rect.position.y - 20, goal_rect.size.x + 20, goal_rect.size.y + 40), Color(1.0, 0.85, 0.2, 0.25))
	draw_rect(goal_rect, Color8(255, 200, 50, 200))
	draw_rect(goal_rect, Color8(255, 235, 100), false, 4.0)
	var goal_pulse = 0.8 + 0.2 * sin(anim_time * 3.0)
	draw_string(font, goal_rect.position + Vector2(goal_rect.size.x / 2 - 18, goal_rect.size.y / 2 + 6), "GOAL", HORIZONTAL_ALIGNMENT_CENTER, 32, 18, Color(1, 1, 0.9, goal_pulse))

	# Phase 5.2: Lava bubbles - animated pulsing circles in lava pits
	if theme == "lava":
		for bubble in _lava_bubbles:
			var scale = 0.3 + 0.7 * (sin(anim_time * 3.0 + bubble.phase) * 0.5 + 0.5)
			var r = bubble.radius * scale
			var alpha = 0.35 + 0.25 * (sin(anim_time * 2.5 + bubble.phase + 1.2) * 0.5 + 0.5)
			draw_circle(Vector2(bubble.x, bubble.y), r, Color(0.85, 0.35, 0.08, alpha))
			# Bright highlight on top
			draw_circle(Vector2(bubble.x - r * 0.3, bubble.y - r * 0.3), r * 0.25, Color(1.0, 0.65, 0.2, alpha * 0.6))

	# Phase 5.3: Cave crystal glow - color pulse on platform prop crystals (cave theme)
	if theme == "cave":
		for prop in _decor_props:
			var px2 = prop.x
			var py2 = prop.y
			var seed_f = float(prop.get("seed", 0) % 1000) * 0.001
			var glow_alpha = 0.3 + 0.2 * sin(anim_time * 2.0 + seed_f * TAU)
			draw_circle(Vector2(px2, py2 - 8), 7.0, Color(0.6, 0.8, 1.0, glow_alpha))

	# Phase 2.3: Water/pit edge ripples (grass theme)
	if theme == "grass":
		var i2 = _ripples.size() - 1
		while i2 >= 0:
			var ripple = _ripples[i2]
			var t_r = 1.0 - (ripple.timer / ripple.max_timer)
			var r_radius = lerp(4.0, 40.0, t_r)
			var r_alpha = (1.0 - t_r) * 0.5
			draw_arc(ripple.pos, r_radius, 0, TAU, 20, Color(0.5, 0.8, 0.9, r_alpha), 1.5)
			draw_arc(ripple.pos, r_radius * 0.55, 0, TAU, 14, Color(0.5, 0.8, 0.9, r_alpha * 0.5), 1.0)
			i2 -= 1

func update_effects(delta: float):
	"""Phase 2.3+3.3: Update ripple timers, level locks, and other animated map elements."""
	# Phase 3.3: Update level lock animations / proximity checks
	for lk in _level_locks:
		if is_instance_valid(lk):
			lk.update(delta, game)
	var theme = level_config.get("theme", "grass")

	# Decay ripple timers
	var i = _ripples.size() - 1
	while i >= 0:
		_ripples[i].timer -= delta
		if _ripples[i].timer <= 0:
			_ripples.remove_at(i)
		i -= 1

	# Spawn ripples when player lands near drains (grass theme only)
	if theme == "grass" and game and game.get("player_node") and game.player_node:
		var player = game.player_node
		var was_grounded = player.get("was_on_ground")
		var is_grounded = player.get("is_on_ground")
		if is_grounded and was_grounded == false:
			# Player just landed - check pipe proximity
			for pipe in _decor_pipes:
				var pipe_pos = Vector2(pipe.x, pipe.y)
				if player.position.distance_to(pipe_pos) < 40.0:
					emit_ripple(player.position + Vector2(0, 20))
					break

func emit_ripple(world_pos: Vector2, duration: float = 0.7):
	"""Phase 2.3: Spawn a concentric ripple animation at position."""
	_ripples.append({
		"pos": world_pos,
		"timer": duration,
		"max_timer": duration
	})
