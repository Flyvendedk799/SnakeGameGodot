class_name MusicController
extends Node

## Phase 7.1: Dynamic Music System with stems
## Three AudioStreamPlayers: Background (ambient), Percussion (combat), Melody (intensity)
## Intensity driver: combat_intensity = near_enemies * 0.2 + (1 - hp_ratio) * 0.3
## Percussion fades in over 2s when intensity > 0.5

var game = null

var ambient_player: AudioStreamPlayer = null
var percussion_player: AudioStreamPlayer = null
var melody_player: AudioStreamPlayer = null

# State
var combat_intensity: float = 0.0
var target_ambient_volume: float = 0.0
var target_percussion_volume: float = -INF
var target_melody_volume: float = -INF

const BASE_DB = -6.0          # Normal playing volume in dB
const SILENT_DB = -80.0        # Effectively silent
const FADE_SPEED = 0.8         # dB per second convergence (lerp factor)
const INTENSITY_RISE_SPEED = 0.4   # How fast intensity rises
const INTENSITY_FALL_SPEED = 0.15  # Slower falloff for combat feel

# Stem audio paths (populate with actual tracks)
const STEM_PATHS = {
	"grass": {
		"ambient":    "res://assets/audio/music/grass_ambient.ogg",
		"percussion": "res://assets/audio/music/grass_percussion.ogg",
		"melody":     "res://assets/audio/music/grass_melody.ogg",
	},
	"cave": {
		"ambient":    "res://assets/audio/music/cave_ambient.ogg",
		"percussion": "res://assets/audio/music/cave_percussion.ogg",
		"melody":     "res://assets/audio/music/cave_melody.ogg",
	},
	# Add more themes as audio assets become available
}

func setup(game_ref):
	game = game_ref
	_create_players()

func _create_players():
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientStem"
	ambient_player.bus = "Music"
	ambient_player.volume_db = SILENT_DB
	add_child(ambient_player)

	percussion_player = AudioStreamPlayer.new()
	percussion_player.name = "PercussionStem"
	percussion_player.bus = "Music"
	percussion_player.volume_db = SILENT_DB
	add_child(percussion_player)

	melody_player = AudioStreamPlayer.new()
	melody_player.name = "MelodyStem"
	melody_player.bus = "Music"
	melody_player.volume_db = SILENT_DB
	add_child(melody_player)

func set_theme(theme: String):
	"""Load and start playing stems for a theme."""
	var paths = STEM_PATHS.get(theme, {})
	_load_stem(ambient_player, paths.get("ambient", ""))
	_load_stem(percussion_player, paths.get("percussion", ""))
	_load_stem(melody_player, paths.get("melody", ""))

	# Start ambient immediately
	target_ambient_volume = BASE_DB
	target_percussion_volume = SILENT_DB
	target_melody_volume = SILENT_DB

func _load_stem(player: AudioStreamPlayer, path: String):
	"""Load an audio stream if the file exists."""
	if path.is_empty() or not ResourceLoader.exists(path):
		player.stream = null
		return
	var stream = load(path) as AudioStream
	if stream:
		player.stream = stream
		player.loop = true  # Loop all stems
		player.play()
		player.volume_db = SILENT_DB

func _process(delta: float):
	if game == null:
		return

	# Compute combat intensity
	var near_enemies = _count_near_enemies()
	var hp_ratio = 1.0
	if game.get("player_node") and game.player_node and not game.player_node.is_dead:
		hp_ratio = float(game.player_node.current_hp) / float(maxf(game.player_node.max_hp, 1))

	var target_intensity = clampf(near_enemies * 0.2 + (1.0 - hp_ratio) * 0.3, 0.0, 1.0)
	if target_intensity > combat_intensity:
		combat_intensity = lerpf(combat_intensity, target_intensity, delta * INTENSITY_RISE_SPEED)
	else:
		combat_intensity = lerpf(combat_intensity, target_intensity, delta * INTENSITY_FALL_SPEED)

	# Volume targets based on intensity
	target_ambient_volume = BASE_DB if ambient_player.stream else SILENT_DB
	target_percussion_volume = BASE_DB if (combat_intensity > 0.5 and percussion_player.stream) else SILENT_DB
	target_melody_volume = lerpf(SILENT_DB, BASE_DB, clampf((combat_intensity - 0.7) / 0.3, 0.0, 1.0)) if melody_player.stream else SILENT_DB

	# Smooth volume transitions (2s fade rate)
	_lerp_volume(ambient_player, target_ambient_volume, delta * 2.0)
	_lerp_volume(percussion_player, target_percussion_volume, delta * 0.5)  # Fade in over 2s
	_lerp_volume(melody_player, target_melody_volume, delta * 0.4)

func _lerp_volume(player: AudioStreamPlayer, target_db: float, speed: float):
	"""Smoothly lerp player volume toward target_db."""
	if player.stream == null:
		player.volume_db = SILENT_DB
		return
	if not player.is_playing() and target_db > SILENT_DB + 10.0:
		player.play()
	player.volume_db = lerpf(player.volume_db, target_db, speed)

func _count_near_enemies() -> int:
	if game == null or not game.get("enemy_container") or not game.get("player_node"):
		return 0
	var count = 0
	var player_pos = game.player_node.position
	for e in game.enemy_container.get_children():
		if e.get("state") != null and (e.state == EnemyEntity.EnemyState.DEAD or e.state == EnemyEntity.EnemyState.DYING):
			continue
		if player_pos.distance_to(e.position) < 300.0:
			count += 1
	return count

func stop_all():
	"""Fade out all stems."""
	target_ambient_volume = SILENT_DB
	target_percussion_volume = SILENT_DB
	target_melody_volume = SILENT_DB
