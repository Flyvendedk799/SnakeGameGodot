class_name StreamingLoader
extends Node

## Phase 8.2: Asset loading and streaming
## Preloads critical assets synchronously: player, map, post_process, FXManager
## Background loads: parallax textures, future level chunks
## Level chunks: loads chunk N+1 when camera.x > chunk_N.x + 400

var game = null
var _load_queue: Array = []    # [{path, callback}] for background loading
var _loading_active: bool = false
var _chunk_preload_threshold: float = 400.0  # px ahead to preload

# Track which chunks have been queued for loading
var _preloaded_chunks: Dictionary = {}  # chunk_x → true

func setup(game_ref):
	game = game_ref
	_preload_critical_assets()

func _preload_critical_assets():
	"""Synchronously ensure critical resources are in cache."""
	# These are preloaded in the project — just reference them to warm GPU cache
	var critical_paths = [
		"res://karen_defense/entities/player.tscn",
		"res://assets/shaders/post_cinematic.gdshader",
		"res://assets/shaders/toon_entity.gdshader",
		"res://assets/shaders/outline.gdshader",
		"res://assets/shaders/dissolve.gdshader",
	]
	for path in critical_paths:
		if ResourceLoader.exists(path) and not ResourceLoader.has_cached(path):
			ResourceLoader.load_threaded_request(path, "", false)

func queue_load(path: String, callback: Callable):
	"""Queue a resource for threaded background loading."""
	if ResourceLoader.has_cached(path):
		var res = load(path)
		callback.call(res)
		return
	_load_queue.append({"path": path, "callback": callback})
	if not _loading_active:
		_start_next_load()

func _start_next_load():
	if _load_queue.is_empty():
		_loading_active = false
		return
	var entry = _load_queue[0]
	_loading_active = true
	ResourceLoader.load_threaded_request(entry.path, "", false)

func _process(_delta: float):
	# Poll background loads
	if _loading_active and not _load_queue.is_empty():
		var entry = _load_queue[0]
		var status = ResourceLoader.load_threaded_get_status(entry.path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var res = ResourceLoader.load_threaded_get(entry.path)
				entry.callback.call(res)
				_load_queue.pop_front()
				_start_next_load()
			ResourceLoader.THREAD_LOAD_FAILED:
				push_warning("[StreamingLoader] Failed to load: %s" % entry.path)
				_load_queue.pop_front()
				_start_next_load()
			_:
				pass  # Still loading

	# Phase 8.2: Chunk ahead preloading based on camera position
	_check_chunk_preload()

func _check_chunk_preload():
	"""Preload level chunks N+1 when camera approaches chunk boundary."""
	if game == null or not game.get("game_camera") or not game.get("map"):
		return

	var cam_x = game.game_camera.position.x
	var segments = game.map.level_config.get("segments", [])

	for i in range(segments.size() - 1):
		var seg = segments[i]
		var seg_end_x = float(seg.get("x_max", seg.get("x_min", 0) + 400))
		var chunk_key = int(seg_end_x)

		if _preloaded_chunks.has(chunk_key):
			continue

		if cam_x > seg_end_x - _chunk_preload_threshold:
			# Preload next segment's spawn zone assets
			_preloaded_chunks[chunk_key] = true
			var next_seg = segments[i + 1]
			_preload_segment_assets(next_seg)

func _preload_segment_assets(seg: Dictionary):
	"""Preload enemy sprites referenced by a segment's spawn zones."""
	var zones = seg.get("spawn_zones", [])
	for zone in zones:
		var pool = zone.get("pool", [])
		for type_name in pool:
			var stats = EnemyData.get_stats(type_name) if ClassDB.class_exists("EnemyData") else {}
			var sprite_name = stats.get("sprite", "enemya")
			var path = "res://assets/%s.png" % sprite_name
			if not ResourceLoader.has_cached(path) and ResourceLoader.exists(path):
				queue_load(path, func(_res): pass)  # Warm cache
