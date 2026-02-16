class_name KarenSfxPlayer
extends Node

# AAA Upgrade: Multiple audio players for layered sound
var players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var sounds: Dictionary = {}
var player_priorities: Array[int] = []  # Track priority of currently playing sounds

func _ready():
	# Create 4 general-purpose players for SFX
	for i in range(4):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
		player_priorities.append(0)

	# Dedicated ambience loop player
	ambience_player = AudioStreamPlayer.new()
	add_child(ambience_player)

	# Dedicated music player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	# Pre-generate all game sounds
	sounds["swing"] = _generate_wav(200.0, 0.12, "saw", 400.0, 0.3)
	sounds["shoot"] = _generate_wav(800.0, 0.08, "square", 400.0, 0.3)
	sounds["hit"] = _generate_wav(150.0, 0.06, "square", 100.0, 0.35)
	sounds["enemy_death"] = _generate_wav(300.0, 0.15, "saw", 80.0, 0.35)
	sounds["player_hurt"] = _generate_wav(250.0, 0.2, "square", 100.0, 0.4)
	sounds["gold_pickup"] = _generate_wav(600.0, 0.05, "sine", 1200.0, 0.3)
	sounds["repair"] = _generate_wav(400.0, 0.06, "sine", 500.0, 0.2)
	sounds["barricade_hit"] = _generate_wav(100.0, 0.12, "saw", 60.0, 0.3)
	sounds["barricade_break"] = _generate_wav(80.0, 0.35, "saw", 30.0, 0.45)
	sounds["level_up"] = _generate_wav(400.0, 0.3, "sine", 800.0, 0.4)
	sounds["wave_start"] = _generate_wav(300.0, 0.18, "square", 600.0, 0.35)
	sounds["wave_complete"] = _generate_wav(500.0, 0.25, "sine", 1000.0, 0.4)
	sounds["purchase"] = _generate_wav(700.0, 0.1, "sine", 900.0, 0.3)
	sounds["error"] = _generate_wav(200.0, 0.15, "square", 150.0, 0.3)
	sounds["boss_roar"] = _generate_wav(60.0, 0.6, "saw", 30.0, 0.5)
	sounds["pause"] = _generate_wav(350.0, 0.08, "sine", 350.0, 0.25)
	sounds["grenade_throw"] = _generate_wav(350.0, 0.1, "sine", 600.0, 0.25)
	sounds["grenade_explode"] = _generate_wav(80.0, 0.4, "saw", 40.0, 0.55)
	sounds["dash"] = _generate_wav(500.0, 0.12, "sine", 300.0, 0.3)
	sounds["combo_hit1"] = _generate_wav(180.0, 0.1, "saw", 350.0, 0.3)
	sounds["combo_hit2"] = _generate_wav(220.0, 0.12, "saw", 400.0, 0.35)
	sounds["combo_hit3"] = _generate_wav(140.0, 0.18, "saw", 500.0, 0.4)
	# New weapon system sounds
	sounds["grapple_launch"] = _generate_wav(600.0, 0.1, "sine", 1200.0, 0.35)
	sounds["grapple_land"] = _generate_wav(150.0, 0.15, "saw", 80.0, 0.35)
	sounds["block_hit"] = _generate_wav(500.0, 0.08, "square", 500.0, 0.3)
	sounds["block_perfect"] = _generate_wav(700.0, 0.12, "sine", 900.0, 0.35)
	sounds["charge_fire"] = _generate_wav(800.0, 0.15, "saw", 200.0, 0.45)
	sounds["charge_ready"] = _generate_wav(400.0, 0.06, "sine", 600.0, 0.25)
	sounds["weapon_wheel_open"] = _generate_wav(500.0, 0.06, "sine", 700.0, 0.2)
	sounds["weapon_wheel_select"] = _generate_wav(600.0, 0.04, "sine", 800.0, 0.2)
	sounds["hammer_hit"] = _generate_wav(300.0, 0.08, "square", 200.0, 0.25)
	sounds["jump"] = _generate_wav(450.0, 0.12, "sine", 600.0, 0.3)
	sounds["land"] = _generate_wav(120.0, 0.08, "saw", 60.0, 0.25)

	# AAA Upgrade: Ambient sound loops
	sounds["ambient_wind"] = _generate_ambient_loop("wind", 4.0)
	sounds["ambient_cave"] = _generate_ambient_loop("cave", 4.0)
	sounds["ambient_factory"] = _generate_ambient_loop("factory", 4.0)

func _generate_wav(frequency: float, duration: float, wave_type: String, freq_end: float = -1.0, volume: float = 0.5) -> AudioStreamWAV:
	if freq_end < 0:
		freq_end = frequency
	var sample_rate := 22050
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var progress := float(i) / float(num_samples)
		var freq := lerpf(frequency, freq_end, progress)
		var phase := t * freq * TAU
		var sample := 0.0
		match wave_type:
			"sine":
				sample = sin(phase)
			"square":
				sample = 1.0 if fmod(phase, TAU) < PI else -1.0
			"saw":
				sample = 2.0 * (fmod(phase, TAU) / TAU) - 1.0
		var envelope := 1.0 - progress
		sample *= envelope * volume
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		var index := i * 2
		data[index] = value & 0xFF
		data[index + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _find_available_player(priority: int = 0) -> AudioStreamPlayer:
	"""AAA Upgrade: Find free player or lowest priority one."""
	# First, try to find a free player
	for i in range(players.size()):
		if not players[i].playing:
			player_priorities[i] = priority
			return players[i]

	# If all busy, find lowest priority player
	var lowest_idx = 0
	var lowest_priority = player_priorities[0]
	for i in range(1, players.size()):
		if player_priorities[i] < lowest_priority:
			lowest_priority = player_priorities[i]
			lowest_idx = i

	# Only interrupt if new sound has higher priority
	if priority >= lowest_priority:
		player_priorities[lowest_idx] = priority
		return players[lowest_idx]

	# Otherwise use first player (shouldn't happen often)
	return players[0]

func _play(sound_name: String, priority: int = 0, pitch_var: float = 0.05):
	"""AAA Upgrade: Play sound with priority and pitch variation."""
	if not sounds.has(sound_name):
		return

	var p = _find_available_player(priority)
	# AAA Upgrade: Random pitch variation for variety
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.stream = sounds[sound_name]
	p.play()

func play_swing(): _play("swing")
func play_shoot(): _play("shoot")
func play_hit(): _play("hit")
func play_enemy_death(): _play("enemy_death")
func play_player_hurt(): _play("player_hurt")
func play_gold_pickup(): _play("gold_pickup")
func play_repair(): _play("repair")
func play_barricade_hit(): _play("barricade_hit")
func play_barricade_break(): _play("barricade_break")
func play_level_up(): _play("level_up")
func play_wave_start(): _play("wave_start")
func play_wave_complete(): _play("wave_complete")
func play_purchase(): _play("purchase")
func play_error(): _play("error")
func play_boss_roar(): _play("boss_roar")
func play_pause(): _play("pause")
func play_grenade_throw(): _play("grenade_throw")
func play_grenade_explode(): _play("grenade_explode")
func play_dash(): _play("dash")
func play_combo_hit(index: int):
	match index:
		0: _play("combo_hit1")
		1: _play("combo_hit2")
		2: _play("combo_hit3")
func play_grapple_launch(): _play("grapple_launch")
func play_grapple_land(): _play("grapple_land")
func play_block_hit(): _play("block_hit")
func play_block_perfect(): _play("block_perfect")
func play_charge_fire(): _play("charge_fire")
func play_charge_ready(): _play("charge_ready")
func play_weapon_wheel_open(): _play("weapon_wheel_open")
func play_weapon_wheel_select(): _play("weapon_wheel_select")
func play_hammer_hit(): _play("hammer_hit")
func play_jump(): _play("jump")
func play_land(): _play("land")

func play_hit_at_position(pos: Vector2, camera_pos: Vector2):
	"""AAA Upgrade: Spatial audio - play hit sound with distance/position."""
	var dist = pos.distance_to(camera_pos)
	# Volume falloff: 100% at 0, 0% at 1000
	var volume_scale = clampf(1.0 - (dist / 1000.0), 0.0, 1.0)

	if volume_scale < 0.05:
		return  # Too far, don't play

	var p = _find_available_player(1)  # Medium priority

	# AAA Upgrade: Pitch modulation by distance (closer = higher pitch)
	p.pitch_scale = lerpf(0.95, 1.05, volume_scale)
	# Volume adjustment
	p.volume_db = linear_to_db(volume_scale)
	p.stream = sounds["hit"]
	p.play()

	# Reset volume after playing (for next sound)
	await p.finished
	p.volume_db = 0.0

func _generate_ambient_loop(type: String, duration: float) -> AudioStreamWAV:
	"""AAA Upgrade: Generate looping ambient sounds for atmosphere."""
	var sample_rate := 22050
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var sample := 0.0

		match type:
			"wind":
				# Layered noise for wind with slow undulation
				sample = randf_range(-0.3, 0.3)  # Base noise
				sample += sin(t * 0.5) * 0.1  # Slow wave
				sample += sin(t * 1.2) * 0.05  # Medium wave
			"cave":
				# Water drips with echo
				var drip_interval = 2.0  # Drip every 2 seconds
				var drip_phase = fmod(t, drip_interval)
				if drip_phase < 0.05:
					# Sharp drip sound
					sample = sin(drip_phase * 100.0) * 0.4 * (1.0 - drip_phase / 0.05)
				# Ambient cave reverb
				sample += randf_range(-0.1, 0.1)
			"factory":
				# Industrial hum with mechanical rhythm
				sample = sin(t * 60.0 * TAU) * 0.15  # 60Hz hum
				sample += sin(t * 120.0 * TAU) * 0.08  # Harmonic
				# Mechanical clanks
				var clank_phase = fmod(t, 1.5)
				if clank_phase < 0.02:
					sample += randf_range(-0.3, 0.3)

		sample *= 0.15  # Keep ambient quiet
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD  # Enable looping
	stream.data = data
	return stream

func play_ambient_loop(theme: String):
	"""AAA Upgrade: Start playing ambient loop for theme."""
	var sound_key = "ambient_" + theme
	if sounds.has(sound_key):
		ambience_player.stream = sounds[sound_key]
		ambience_player.volume_db = -18.0  # Quiet background layer
		ambience_player.play()

func stop_ambient():
	"""Stop ambient loop."""
	ambience_player.stop()
