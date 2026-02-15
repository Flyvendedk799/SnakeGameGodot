class_name FXManager
extends Node

## AAA Visual Upgrade: Centralized FX coordination
## Unifies particles, camera effects, sound, and hitstop for consistent feel

var game = null  # Reference to main_game

func setup(game_ref):
	"""Initialize with reference to main game."""
	game = game_ref

func emit_event(event_name: String, position: Vector2, intensity: float = 1.0, data: Dictionary = {}):
	"""Unified FX trigger for consistent visual feedback.

	Args:
		event_name: "land", "jump", "attack_hit", "dash", "death", "grapple_attach"
		position: World position for effect
		intensity: 0.0 (light) to 2.0 (heavy)
		data: Event-specific parameters
	"""
	match event_name:
		"land":
			_fx_land(position, intensity, data)
		"jump":
			_fx_jump(position, intensity, data)
		"attack_hit":
			_fx_attack_hit(position, intensity, data)
		"dash":
			_fx_dash(position, intensity, data)
		"death":
			_fx_death(position, intensity, data)
		"grapple_attach":
			_fx_grapple_attach(position, intensity, data)

func _fx_land(pos: Vector2, intensity: float, _data: Dictionary):
	"""Landing impact effects."""
	# Particles
	var dust_count = int(12 * intensity) + 6
	var dust_color = Color8(180, 170, 155)
	if game.particles:
		game.particles.emit_directional(pos.x, pos.y, Vector2.UP, dust_color, dust_count)
		if intensity > 0.6:
			game.particles.emit_ring(pos.x, pos.y, dust_color.lightened(0.2), 8)

	# Camera effects
	var shake_intensity = lerpf(2.0, 8.0, intensity)
	if game.has_method("start_shake"):
		game.start_shake(shake_intensity, 0.1, game.ShakeCurve.EASE_OUT_QUAD)
	if intensity > 0.7 and game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(1.0)

	# Sound
	if game.sfx:
		game.sfx.play_land()

func _fx_jump(pos: Vector2, intensity: float, _data: Dictionary):
	"""Jump launch effects."""
	if game.particles:
		game.particles.emit_ring(pos.x, pos.y, Color8(180, 220, 255), 8)
	if game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(-0.5)
	if game.sfx:
		game.sfx.play_jump()

func _fx_attack_hit(pos: Vector2, intensity: float, data: Dictionary):
	"""Attack impact effects."""
	var is_crit = data.get("is_crit", false)
	var hit_color = Color8(255, 180, 100) if is_crit else Color8(255, 220, 200)

	# Particles
	if game.particles:
		game.particles.emit_burst(pos.x, pos.y, hit_color, int(8 * intensity) + 4)

	# Hitstop
	var hitstop_duration = lerpf(0.04, 0.12, intensity)
	if game.has_method("start_hitstop"):
		game.start_hitstop(hitstop_duration, intensity)

	# Screen shake
	if game.has_method("start_shake"):
		game.start_shake(lerpf(2.0, 6.0, intensity), 0.08)

	# Chromatic aberration on crit
	if is_crit and game.has_method("start_chromatic"):
		game.start_chromatic(2.0)

	# Sound
	if game.sfx:
		if is_crit:
			if game.sfx.has_method("play_crit_hit"):
				game.sfx.play_crit_hit()
			else:
				game.sfx.play_hit()
		else:
			game.sfx.play_hit()

func _fx_dash(pos: Vector2, _intensity: float, data: Dictionary):
	"""Dash activation effects."""
	var dash_dir = data.get("direction", Vector2.RIGHT)
	if game.particles:
		game.particles.emit_directional(pos.x, pos.y, -dash_dir, Color8(200, 220, 255, 180), 6)
	if game.has_method("start_shake"):
		game.start_shake(2.0, 0.06)

func _fx_death(pos: Vector2, _intensity: float, data: Dictionary):
	"""Death/destruction effects."""
	var death_color = data.get("color", Color8(255, 100, 100))
	if game.particles:
		game.particles.emit_death_burst(pos.x, pos.y, death_color)
	if game.has_method("start_shake"):
		game.start_shake(6.0, 0.15)
	if game.has_method("start_chromatic"):
		game.start_chromatic(4.0)
	if game.sfx and game.sfx.has_method("play_enemy_death"):
		game.sfx.play_enemy_death()

func _fx_grapple_attach(pos: Vector2, _intensity: float, _data: Dictionary):
	"""Grapple hook attachment effects."""
	if game.particles:
		game.particles.emit_ring(pos.x, pos.y, Color8(100, 200, 255), 10)
	if game.has_method("start_shake"):
		game.start_shake(2.0, 0.05)
	if game.sfx and game.sfx.has_method("play_grapple_attach"):
		game.sfx.play_grapple_attach()
