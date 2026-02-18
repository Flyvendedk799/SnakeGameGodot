class_name DebugOverlay
extends CanvasLayer

## Phase 8.4: Debug HUD — F3 to toggle
## Shows: FPS, entity count, spawn pressure, camera target, process time
## Cheats: debug_invincible (F4), debug_one_hit_kill (F5), debug_slow_mo (F6)
## ALL guarded with OS.is_debug_build() check

var game = null
var visible_hud: bool = false

var debug_invincible: bool = false
var debug_one_hit_kill: bool = false
var debug_slow_mo: bool = false

var _label: Label = null
var _update_timer: float = 0.0
const UPDATE_RATE: float = 0.1  # Update display 10x/sec

func setup(game_ref):
	if not OS.is_debug_build():
		return  # Completely disabled in release builds

	game = game_ref
	layer = 100  # Above everything

	_label = Label.new()
	_label.name = "DebugLabel"
	_label.visible = false
	_label.position = Vector2(8, 8)
	_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.5))
	_label.add_theme_font_size_override("font_size", 14)
	# Monospace look for debug
	add_child(_label)

func _input(event: InputEvent):
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F3:
				visible_hud = not visible_hud
				if _label:
					_label.visible = visible_hud
			KEY_F4:
				debug_invincible = not debug_invincible
				print("[Debug] Invincible: %s" % debug_invincible)
			KEY_F5:
				debug_one_hit_kill = not debug_one_hit_kill
				print("[Debug] One-hit-kill: %s" % debug_one_hit_kill)
			KEY_F6:
				debug_slow_mo = not debug_slow_mo
				Engine.time_scale = 0.25 if debug_slow_mo else 1.0
				print("[Debug] Slow-mo: %s" % debug_slow_mo)

func _process(delta: float):
	if not OS.is_debug_build() or not visible_hud or _label == null or game == null:
		return

	_update_timer += delta
	if _update_timer < UPDATE_RATE:
		return
	_update_timer = 0.0

	var fps = Engine.get_frames_per_second()
	var pt_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var pt_phys = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0

	var enemy_count = game.enemy_container.get_child_count() if game.get("enemy_container") else 0
	var ally_count = game.ally_container.get_child_count() if game.get("ally_container") else 0
	var proj_count = game.projectile_container.get_child_count() if game.get("projectile_container") else 0

	var spawn_pressure = 0.0
	if game.get("spawn_director") and game.spawn_director:
		spawn_pressure = game.spawn_director._compute_pressure() if game.spawn_director.has_method("_compute_pressure") else 0.0

	var cam_pos = game.game_camera.position if game.get("game_camera") else Vector2.ZERO
	var player_pos = game.player_node.position if game.get("player_node") else Vector2.ZERO
	var player_vel = game.player_node.velocity if (game.get("player_node") and game.player_node.get("velocity")) else Vector2.ZERO

	var cheat_str = ""
	if debug_invincible:   cheat_str += " [INVINCIBLE]"
	if debug_one_hit_kill: cheat_str += " [ONE-HIT-KILL]"
	if debug_slow_mo:      cheat_str += " [SLOW-MO]"

	var text = """=== DEBUG OVERLAY === F3 toggle%s
FPS: %d  |  Process: %.1f ms  |  Physics: %.1f ms
Entities: enemies=%d  allies=%d  projectiles=%d
Spawn Pressure: %.2f
Camera: (%.0f, %.0f)  Player: (%.1f, %.1f)  Vel: (%.1f, %.1f)
F4=Invincible  F5=One-hit-kill  F6=Slow-mo""" % [
		cheat_str,
		fps, pt_ms, pt_phys,
		enemy_count, ally_count, proj_count,
		spawn_pressure,
		cam_pos.x, cam_pos.y,
		player_pos.x, player_pos.y,
		player_vel.x, player_vel.y,
	]

	_label.text = text

func apply_debug_to_player(player):
	"""Apply active debug cheats to player node. Call from player.update_player()."""
	if not OS.is_debug_build():
		return
	if debug_invincible:
		player.invincibility_timer = maxf(player.invincibility_timer, 0.5)
