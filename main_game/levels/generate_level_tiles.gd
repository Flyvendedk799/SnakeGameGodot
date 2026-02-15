@tool
extends Node
## Run this scene once to generate the level tile assets.
## Creates platformer_tiles.png and platformer_tileset.tres for Godot's TileMap level editor.

const TILES_PATH = "res://main_game/levels/platformer_tiles.png"
const TILESET_PATH = "res://main_game/levels/platformer_tileset.tres"
const LEVEL_01_PATH = "res://main_game/levels/level_01.tscn"
const TILE_SIZE = 64

func _ready():
	if Engine.is_editor_hint():
		# Only generate when explicitly run (Run Current Scene)
		call_deferred("_try_generate")

func _try_generate():
	var did_something = false
	if not FileAccess.file_exists(TILES_PATH):
		_generate_tiles()
		did_something = true
	if not FileAccess.file_exists(TILESET_PATH):
		_generate_tileset()
		did_something = true
	if not FileAccess.file_exists(LEVEL_01_PATH):
		_create_example_level()
		did_something = true
	if did_something:
		push_warning("Level tile assets generated at " + TILES_PATH + ". You can now design levels with TileMap.")

func _generate_tiles():
	var img = Image.create(TILE_SIZE * 6, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var colors = [
		Color(0.4, 0.35, 0.25),   # 0: floor (brown)
		Color(0.55, 0.45, 0.35),  # 1: platform (grey-brown)
		Color(0.2, 0.7, 0.35),    # 2: checkpoint (green)
		Color(0.9, 0.75, 0.2),    # 3: goal (gold)
		Color(0.3, 0.6, 0.95),    # 4: grapple anchor (blue)
		Color(0.6, 0.6, 0.65),   # 5: chain link (silver)
	]
	for ti in range(6):
		var col = colors[ti]
		for y in range(TILE_SIZE):
			for x in range(TILE_SIZE):
				var px = ti * TILE_SIZE + x
				# Add a border/darken edges for visibility
				var edge = 1.0
				if x < 2 or x >= TILE_SIZE - 2 or y < 2 or y >= TILE_SIZE - 2:
					edge = 0.7
				img.set_pixel(px, y, Color(col.r * edge, col.g * edge, col.b * edge, 1.0))
	img.save_png(TILES_PATH)

func _generate_tileset():
	# Load the freshly saved image (may need reimport in editor)
	ResourceLoader.load_threaded_request(TILES_PATH)
	var texture = load(TILES_PATH) as Texture2D
	if not texture:
		# Fallback: create from image we just made
		var img = Image.load_from_file(TILES_PATH)
		if img:
			texture = ImageTexture.create_from_image(img)
	if not texture:
		push_error("Could not load generated texture")
		return
	var ts = TileSet.new()
	var source = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in range(6):
		source.create_tile(Vector2i(i, 0))
	ts.add_source(source, 0)
	var err = ResourceSaver.save(ts, TILESET_PATH)
	if err != OK:
		push_error("Could not save TileSet: " + str(err))

func _create_example_level():
	var ts = load(TILESET_PATH) as TileSet
	if not ts:
		push_error("Tileset not found - run generator again after tiles are created.")
		return
	var root = Node2D.new()
	root.name = "Level01"
	var tilemap = TileMap.new()
	tilemap.name = "LevelTileMap"
	tilemap.tile_set = ts
	root.add_child(tilemap)
	tilemap.set_owner(root)
	# Paint: (0,0)=floor, (1,0)=platform, (2,0)=checkpoint, (3,0)=goal, (4,0)=grapple, (5,0)=chain
	# Floor row 6: cols 0-25 (main platform), gap, cols 30-42 (end platform)
	for col in range(26):
		tilemap.set_cell(0, Vector2i(col, 6), 0, Vector2i(0, 0))
	for col in range(30, 43):
		tilemap.set_cell(0, Vector2i(col, 6), 0, Vector2i(0, 0))
	# Floating platform row 4
	for col in range(12, 18):
		tilemap.set_cell(0, Vector2i(col, 4), 0, Vector2i(1, 0))
	# Checkpoint at (5,6) - replace floor with checkpoint
	tilemap.set_cell(0, Vector2i(5, 6), 0, Vector2i(2, 0))
	# Goal at (40,6)
	tilemap.set_cell(0, Vector2i(40, 6), 0, Vector2i(3, 0))
	# Grapple anchor above gap at (27,4)
	tilemap.set_cell(0, Vector2i(27, 4), 0, Vector2i(4, 0))
	# Chain link at pit ceiling (28,4)
	tilemap.set_cell(0, Vector2i(28, 4), 0, Vector2i(5, 0))
	var packed = PackedScene.new()
	var err = packed.pack(root)
	root.free()
	if err != OK:
		push_error("Could not pack level scene: " + str(err))
		return
	err = ResourceSaver.save(packed, LEVEL_01_PATH)
	if err != OK:
		push_error("Could not save level_01.tscn: " + str(err))
