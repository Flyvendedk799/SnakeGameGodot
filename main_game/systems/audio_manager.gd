class_name AudioManager
extends Node

## Phase 7.2: Spatial Audio Manager
## AudioStreamPlayer2D for positional SFX (enemy attacks, pickups, ambients)
## AudioStreamPlayer for non-positional SFX (UI, music — handled by MusicController)
## Manages a pool of AudioStreamPlayer2D nodes for efficiency

var game = null

const POOL_SIZE: int = 16
var _2d_pool: Array = []      # AudioStreamPlayer2D pool
var _pool_index: int = 0       # Round-robin index

# Ambient source nodes (fixed 2D positions)
var _ambient_sources: Array = []

func setup(game_ref):
	game = game_ref
	_create_pool()

func _create_pool():
	"""Pre-allocate AudioStreamPlayer2D pool."""
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer2D.new()
		p.name = "SFX2D_%d" % i
		p.bus = "SFX"
		p.max_distance = 800.0
		p.attenuation = 1.0
		add_child(p)
		_2d_pool.append(p)

func play_at(stream_path: String, world_pos: Vector2, volume_db: float = 0.0, pitch: float = 1.0):
	"""Play a spatial SFX at world_pos. Silently skips if file not found."""
	if stream_path.is_empty() or not ResourceLoader.exists(stream_path):
		return
	var stream = load(stream_path) as AudioStream
	if stream == null:
		return
	var player = _get_free_player_2d()
	player.stream = stream
	player.position = world_pos
	player.volume_db = volume_db
	player.pitch_scale = pitch + randf_range(-0.05, 0.05)  # Slight pitch variation
	player.play()

func _get_free_player_2d() -> AudioStreamPlayer2D:
	"""Round-robin: get the next pool player (reusing even if still playing)."""
	var player = _2d_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	if player.is_playing():
		player.stop()
	return player

func play_projectile_hit(world_pos: Vector2):
	play_at("res://assets/audio/sfx/projectile_hit.ogg", world_pos, -4.0, 1.1)

func play_gold_pickup(world_pos: Vector2):
	play_at("res://assets/audio/sfx/gold_pickup.ogg", world_pos, -8.0, 1.0)

func play_enemy_attack(world_pos: Vector2):
	play_at("res://assets/audio/sfx/enemy_attack.ogg", world_pos, -6.0, 0.9)

func play_ambient_drip(world_pos: Vector2):
	"""Phase 7.2: Cave ambient drip sound at fixed position."""
	play_at("res://assets/audio/sfx/ambient/cave_drip.ogg", world_pos, -14.0, randf_range(0.8, 1.2))

func play_ambient_rustle(world_pos: Vector2):
	"""Phase 7.2: Grass rustle ambient at fixed position."""
	play_at("res://assets/audio/sfx/ambient/grass_rustle.ogg", world_pos, -16.0, randf_range(0.85, 1.15))

func setup_ambient_sources(theme: String, map_width: float):
	"""Place ambient sound sources based on theme."""
	# Clear old ambient sources
	for src in _ambient_sources:
		if is_instance_valid(src):
			src.stop()
	_ambient_sources.clear()

	match theme:
		"cave":
			# Cave drips every 400px
			var drip_count = int(map_width / 400)
			for i in range(drip_count):
				_schedule_ambient_drip(Vector2(i * 400.0 + 200.0, 300.0))
		"grass":
			# Grass rustle at random positions
			var rustle_count = int(map_width / 600)
			for i in range(rustle_count):
				_schedule_ambient_rustle(Vector2(i * 600.0 + 300.0, 400.0))

func _schedule_ambient_drip(pos: Vector2):
	"""Schedule periodic drip sound at pos."""
	var timer = get_tree().create_timer(randf_range(3.0, 8.0))
	timer.timeout.connect(func():
		play_ambient_drip(pos)
		_schedule_ambient_drip(pos)  # Reschedule
	)

func _schedule_ambient_rustle(pos: Vector2):
	var timer = get_tree().create_timer(randf_range(5.0, 12.0))
	timer.timeout.connect(func():
		play_ambient_rustle(pos)
		_schedule_ambient_rustle(pos)
	)
