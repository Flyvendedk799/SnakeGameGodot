class_name FXManager
extends Node

## AAA Visual Upgrade: Centralized FX coordination
## Unifies particles, camera effects, sound, and hitstop for consistent feel
## Phase 4.1: Per-hit-type hitstop curves, haptic rumble, per-axis shake
## Phase 4.3: Crit screen flash, multi-point impact support
## Phase 6: Combat Visual Event Bus — emit_melee_hit, emit_melee_crit, etc.
## Phase 7.3: Haptic feedback via Input.start_joy_vibration

var game = null  # Reference to main_game

# ---------------------------------------------------------------------------
# Phase 4.1: Hit-type definitions (duration_s, engine_timescale, shake, haptic_weak, haptic_strong)
# ---------------------------------------------------------------------------
const HIT_TYPES = {
	"light":    {"hitstop": 0.02, "scale": 0.5,  "shake": 2.5,  "hap_w": 0.2, "hap_s": 0.4, "hap_dur": 0.03},
	"medium":   {"hitstop": 0.04, "scale": 1.0,  "shake": 4.0,  "hap_w": 0.3, "hap_s": 0.5, "hap_dur": 0.05},
	"heavy":    {"hitstop": 0.08, "scale": 1.5,  "shake": 6.5,  "hap_w": 0.4, "hap_s": 0.7, "hap_dur": 0.08},
	"finisher": {"hitstop": 0.12, "scale": 2.0,  "shake": 9.0,  "hap_w": 0.6, "hap_s": 0.8, "hap_dur": 0.12},
	"crit":     {"hitstop": 0.06, "scale": 1.3,  "shake": 7.0,  "hap_w": 0.4, "hap_s": 0.7, "hap_dur": 0.06},
}

# Multi-point impact centers (Phase 4.3: up to 2 simultaneous impacts)
var _impact_queue: Array = []
const MAX_IMPACT_QUEUE: int = 2

func setup(game_ref):
	"""Initialize with reference to main game."""
	game = game_ref

# ---------------------------------------------------------------------------
# Phase 4.1: Hit-type-driven FX dispatch
# ---------------------------------------------------------------------------

func emit_hit_type(hit_type: String, world_pos: Vector2, direction: Vector2 = Vector2.RIGHT):
	"""Unified hit FX by type: light / medium / heavy / finisher / crit."""
	var ht = HIT_TYPES.get(hit_type, HIT_TYPES["medium"])

	# Hitstop
	if game.has_method("start_hitstop"):
		game.start_hitstop(ht.hitstop, ht.scale)

	# Shake — horizontal for melee hits
	if game.has_method("start_shake"):
		game.start_shake(ht.shake, 0.08 + ht.hitstop, game.ShakeCurve.EASE_OUT_QUAD)

	# Haptic rumble (Phase 7.3)
	_rumble(ht.hap_w, ht.hap_s, ht.hap_dur)

	# Directional warp (Phase 4.3: multi-point)
	_queue_impact(world_pos, hit_type)

	# Bloom boost on heavy/finisher
	if hit_type in ["heavy", "finisher", "crit"]:
		if game.has_method("trigger_bloom_boost"):
			game.trigger_bloom_boost(0.3 if hit_type != "finisher" else 0.55)

	# Crit flash: fullscreen 1-frame at 0.15 alpha (Phase 4.3)
	if hit_type in ["crit", "finisher"]:
		_trigger_crit_flash(world_pos, hit_type)

# ---------------------------------------------------------------------------
# Phase 4.3: Multi-point impact queue
# ---------------------------------------------------------------------------

func _queue_impact(world_pos: Vector2, hit_type: String):
	"""Queue directional warp impact (max 2 simultaneous centers)."""
	if _impact_queue.size() >= MAX_IMPACT_QUEUE:
		_impact_queue.pop_front()
	var strength = 0.25
	match hit_type:
		"heavy":    strength = 0.40
		"finisher": strength = 0.55
		"crit":     strength = 0.45
		"light":    strength = 0.18
	_impact_queue.append({"pos": world_pos, "strength": strength})
	if game.has_method("trigger_impact_distortion"):
		game.trigger_impact_distortion(world_pos, strength)

func _trigger_crit_flash(pos: Vector2, hit_type: String):
	"""Phase 4.3: Fullscreen crit flash at 0.15 alpha."""
	var alpha = 0.12 if hit_type == "crit" else 0.18
	var col = Color(1.0, 1.0, 0.9, alpha)
	if game.has_method("spawn_impact_flash"):
		game.spawn_impact_flash(pos, 0.08, col)
	# Chromatic spike on crit
	if game.has_method("start_chromatic"):
		game.start_chromatic(4.0)

# ---------------------------------------------------------------------------
# Phase 7.3: Haptic rumble helper
# ---------------------------------------------------------------------------

func _rumble(weak: float, strong: float, duration: float, device: int = 0):
	"""Trigger controller haptic feedback if gamepad present."""
	if Input.get_connected_joypads().is_empty():
		return
	Input.start_joy_vibration(device, weak, strong, duration)

# ---------------------------------------------------------------------------
# Phase 6: Combat Visual Event Bus
# ---------------------------------------------------------------------------

func emit_melee_hit(payload: Dictionary):
	"""MELEE_HIT: particles + impact flash + damage number + hitstop + shake + weapon trail."""
	var pos: Vector2 = payload.get("position", Vector2.ZERO)
	var combo: int = payload.get("combo_index", 0)
	var intensity: float = payload.get("intensity", 1.0)
	var hit_colors = [Color.WHITE, Color8(100, 200, 255), Color8(255, 120, 50)]
	var hit_dir: Vector2 = payload.get("direction", Vector2.RIGHT)

	# Phase 4.1: route to typed dispatch
	var hit_type = "light" if combo == 0 else ("medium" if combo == 1 else "heavy")
	emit_hit_type(hit_type, pos, hit_dir)

	# Phase 4.2: GPU burst for heavy hits, CPU for light/medium
	if combo >= 2 and game.get("gpu_particle_emitter"):
		game.gpu_particle_emitter.emit_death_burst(pos, hit_colors[2], 20)
	elif game.particles:
		game.particles.emit_directional(pos.x, pos.y, hit_dir, hit_colors[mini(combo, 2)], 5 + combo * 2)

	if combo >= 1:
		var flash_color = Color.WHITE if combo == 1 else Color8(255, 120, 50)
		if game.has_method("spawn_impact_flash"):
			game.spawn_impact_flash(pos, 0.15, flash_color)

	if game.sfx:
		game.sfx.play_hit()

func emit_melee_crit(payload: Dictionary):
	"""MELEE_CRIT: strong flash + yellow burst + chromatic + crit ring."""
	var pos: Vector2 = payload.get("position", Vector2.ZERO)

	emit_hit_type("crit", pos)

	# Phase 4.2: GPU burst for crits
	if game.get("gpu_particle_emitter"):
		game.gpu_particle_emitter.emit_death_burst(pos, Color.YELLOW, 30)
	elif game.particles:
		game.particles.emit_burst(pos.x, pos.y, Color.YELLOW, 8)

	if game.has_method("spawn_impact_flash"):
		game.spawn_impact_flash(pos, 0.2, Color(1.0, 1.0, 0.6))

	if game.sfx and game.sfx.has_method("play_crit_hit"):
		game.sfx.play_crit_hit()
	elif game.sfx:
		game.sfx.play_hit()

func emit_combo_finisher(payload: Dictionary):
	"""COMBO_FINISHER: camera zoom pulse + large impact ring + strong distortion."""
	var pos: Vector2 = payload.get("position", Vector2.ZERO)

	emit_hit_type("finisher", pos)

	if game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(2.8)

	# Phase 4.2: GPU explosion for finishers (much larger visual)
	if game.get("gpu_particle_emitter"):
		game.gpu_particle_emitter.emit_explosion(pos, Color8(255, 120, 50), 80.0)
	elif game.particles:
		game.particles.emit_ring(pos.x, pos.y, Color8(255, 120, 50), 12)

	# Extra rumble for finisher
	_rumble(0.6, 0.8, 0.15)

func emit_enemy_death(payload: Dictionary):
	"""ENEMY_DEATH: death burst + big shake + chromatic."""
	var pos: Vector2 = payload.get("position", Vector2.ZERO)
	var col: Color = payload.get("color", Color8(255, 100, 100))

	# Phase 4.2: GPU burst (visually superior to CPU fallback)
	if game.get("gpu_particle_emitter"):
		game.gpu_particle_emitter.emit_death_burst(pos, col, 60)
	elif game.particles:
		game.particles.emit_death_burst(pos.x, pos.y, col)

	if game.has_method("start_shake"):
		# Phase 4.1: vertical axis emphasis on death
		game.start_shake(6.0, 0.15, game.ShakeCurve.EASE_OUT_EXPO)

	if game.has_method("start_chromatic"):
		game.start_chromatic(3.5)

	# Phase 7.3: haptic on enemy death
	_rumble(0.3, 0.6, 0.06)

	if game.sfx and game.sfx.has_method("play_enemy_death"):
		game.sfx.play_enemy_death()

func emit_projectile_hit(payload: Dictionary):
	"""PROJECTILE_HIT: directional particles + light shake."""
	var pos: Vector2 = payload.get("position", Vector2.ZERO)
	var hit_dir: Vector2 = payload.get("direction", Vector2.RIGHT)

	emit_hit_type("light", pos, hit_dir)

	if game.particles:
		game.particles.emit_directional(pos.x, pos.y, hit_dir, Color.WHITE, 5)

func emit_block_parry(payload: Dictionary):
	"""BLOCK_PARRY: spark burst + brief freeze + camera pull."""
	var pos: Vector2 = payload.get("position", Vector2.ZERO)

	if game.particles:
		game.particles.emit_ring(pos.x, pos.y, Color8(200, 220, 255), 10)
		game.particles.emit_burst(pos.x, pos.y, Color(0.8, 0.9, 1.0), 6)

	if game.has_method("start_hitstop"):
		game.start_hitstop(0.06, 1.5)

	if game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(-1.0)

	# Phase 7.3: parry haptic (short sharp tap)
	_rumble(0.1, 0.6, 0.04)

# ---------------------------------------------------------------------------
# Legacy emit_event API (unchanged — backwards compatible)
# ---------------------------------------------------------------------------

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
	"""Landing impact effects. Phase 4.1: vertical axis emphasis, phase 7.3 haptic."""
	var dust_count = int(12 * intensity) + 6
	var dust_color = Color8(180, 170, 155)
	if game.particles:
		game.particles.emit_directional(pos.x, pos.y, Vector2.UP, dust_color, dust_count)
		if intensity > 0.6:
			game.particles.emit_ring(pos.x, pos.y, dust_color.lightened(0.2), 8)

	# Phase 4.1: vertical axis 1.2x emphasis for landings
	var shake_intensity = lerpf(2.0, 8.0, intensity)
	if game.has_method("start_shake"):
		game.start_shake(shake_intensity * 1.2, 0.1, game.ShakeCurve.EASE_OUT_QUAD)
	if intensity > 0.7 and game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(1.0)

	# Phase 7.3: haptic land bump
	_rumble(0.15 * intensity, 0.3 * intensity, 0.02)

	if game.sfx:
		game.sfx.play_land()

func _fx_jump(pos: Vector2, _intensity: float, _data: Dictionary):
	"""Jump launch effects."""
	if game.particles:
		game.particles.emit_ring(pos.x, pos.y, Color8(180, 220, 255), 8)
	if game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(-0.5)
	# Phase 7.3: haptic jump pop
	_rumble(0.0, 0.1, 0.02)
	if game.sfx:
		game.sfx.play_jump()

func _fx_attack_hit(pos: Vector2, intensity: float, data: Dictionary):
	"""Attack impact effects. Phase 4.1: route through hit-type system."""
	var is_crit = data.get("is_crit", false)
	var hit_color = Color8(255, 180, 100) if is_crit else Color8(255, 220, 200)
	var hit_type = "crit" if is_crit else ("heavy" if intensity > 1.2 else ("medium" if intensity > 0.7 else "light"))

	emit_hit_type(hit_type, pos)

	if game.particles:
		game.particles.emit_burst(pos.x, pos.y, hit_color, int(8 * intensity) + 4)

	if game.sfx:
		if is_crit:
			if game.sfx.has_method("play_crit_hit"):
				game.sfx.play_crit_hit()
			else:
				game.sfx.play_hit()
		else:
			game.sfx.play_hit()

func _fx_dash(pos: Vector2, _intensity: float, data: Dictionary):
	"""Dash activation effects. Phase 7.3: haptic dash."""
	var dash_dir = data.get("direction", Vector2.RIGHT)
	if game.particles:
		game.particles.emit_directional(pos.x, pos.y, -dash_dir, Color8(200, 220, 255, 180), 6)
	if game.has_method("start_shake"):
		game.start_shake(2.0, 0.06)
	# Phase 7.3: haptic dash
	_rumble(0.1, 0.25, 0.04)

func _fx_death(pos: Vector2, _intensity: float, data: Dictionary):
	"""Death/destruction effects."""
	var death_color = data.get("color", Color8(255, 100, 100))
	if game.particles:
		game.particles.emit_death_burst(pos.x, pos.y, death_color)
	if game.has_method("start_shake"):
		game.start_shake(6.0, 0.15)
	if game.has_method("start_chromatic"):
		game.start_chromatic(4.0)
	_rumble(0.3, 0.6, 0.06)
	if game.sfx and game.sfx.has_method("play_enemy_death"):
		game.sfx.play_enemy_death()

func _fx_grapple_attach(pos: Vector2, _intensity: float, _data: Dictionary):
	"""Grapple hook attachment effects."""
	if game.particles:
		game.particles.emit_ring(pos.x, pos.y, Color8(100, 200, 255), 10)
	if game.has_method("start_shake"):
		game.start_shake(2.0, 0.05)
	# Phase 7.3: haptic grapple attach
	_rumble(0.05, 0.2, 0.03)
	if game.sfx and game.sfx.has_method("play_grapple_attach"):
		game.sfx.play_grapple_attach()
