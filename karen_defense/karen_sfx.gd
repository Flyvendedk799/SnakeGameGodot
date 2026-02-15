class_name KarenSfxPlayer
extends Node

var player1: AudioStreamPlayer
var player2: AudioStreamPlayer
var sounds: Dictionary = {}
var use_player2: bool = false

func _ready():
	player1 = AudioStreamPlayer.new()
	player2 = AudioStreamPlayer.new()
	add_child(player1)
	add_child(player2)
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

func _play(sound_name: String):
	if sounds.has(sound_name):
		var p = player2 if use_player2 else player1
		use_player2 = !use_player2
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
