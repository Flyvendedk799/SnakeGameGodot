class_name SfxPlayer
extends Node

var player: AudioStreamPlayer
var sounds: Dictionary = {}

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	# Pre-generate all sounds
	sounds["eat"] = _generate_wav(400.0, 0.1, "square", 800.0, 0.4)
	sounds["death"] = _generate_wav(300.0, 0.6, "saw", 60.0, 0.5)
	sounds["start"] = _generate_wav(500.0, 0.15, "square", 1000.0, 0.4)
	sounds["countdown_tick"] = _generate_wav(600.0, 0.08, "square", 600.0, 0.3)
	sounds["countdown_go"] = _generate_wav(800.0, 0.2, "square", 1200.0, 0.4)
	sounds["pause"] = _generate_wav(350.0, 0.08, "sine", 350.0, 0.25)

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
		# Frequency sweep
		var freq := lerpf(frequency, freq_end, progress)
		var phase := t * freq * TAU
		# Waveform
		var sample := 0.0
		match wave_type:
			"sine":
				sample = sin(phase)
			"square":
				sample = 1.0 if fmod(phase, TAU) < PI else -1.0
			"saw":
				sample = 2.0 * (fmod(phase, TAU) / TAU) - 1.0
		# Envelope: quick attack, linear decay
		var envelope := 1.0 - progress
		sample *= envelope * volume
		# Convert to 16-bit PCM
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
		player.stream = sounds[sound_name]
		player.play()

func play_eat():
	_play("eat")

func play_death():
	_play("death")

func play_start():
	_play("start")

func play_countdown_tick():
	_play("countdown_tick")

func play_countdown_go():
	_play("countdown_go")

func play_pause():
	_play("pause")
