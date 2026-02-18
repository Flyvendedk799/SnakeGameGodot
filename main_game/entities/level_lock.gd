class_name LevelLock
extends Node2D

## Phase 3.3: Locked gate that blocks passage until the player has collected enough keys.
## Drawn as a portcullis-style gate with animated lock icon.
## Integrates with player.key_count; call try_unlock(game) each frame when player is near.

var required_keys: int = 1
var gate_width: float = 48.0
var gate_height: float = 120.0
var is_unlocked: bool = false

# Visual state
var _unlock_anim: float = 0.0      # 0.0 = locked, 1.0 = fully open
var _shake_timer: float = 0.0      # brief shake when player tries without a key
var _glow_pulse: float = 0.0       # anim_time forwarded from parent

signal unlocked(gate_node)

# Called from LinearMap._process or game loop
func update(delta: float, game):
	_glow_pulse += delta
	if _shake_timer > 0.0:
		_shake_timer -= delta
	if is_unlocked and _unlock_anim < 1.0:
		_unlock_anim += delta * 1.8  # Raise gate over ~0.55 s
		_unlock_anim = minf(_unlock_anim, 1.0)
		queue_redraw()
		return

	# Auto-check proximity - only unlock if player walks into the gate
	if game == null or is_unlocked:
		return
	var player = game.get("player_node")
	if player == null:
		return
	var gate_rect = get_collision_rect()
	if gate_rect.grow(24.0).has_point(player.position):
		try_unlock(game)

func try_unlock(game) -> bool:
	if is_unlocked:
		return true
	var player = game.get("player_node")
	if player == null:
		return false
	var player_keys: int = int(player.get("key_count") if player.get("key_count") != null else 0)
	if player_keys >= required_keys:
		# Consume keys
		player.key_count -= required_keys
		is_unlocked = true
		_unlock_anim = 0.0
		# SFX + particle burst
		if game.has_method("start_shake"):
			game.start_shake(3.0, 0.08)
		if game.get("particles"):
			game.particles.emit_burst(position.x, position.y, Color(1.0, 0.9, 0.3), 12)
		if game.get("audio_manager"):
			game.audio_manager.play_sfx("door_unlock")
		game.spawn_damage_number(position + Vector2(0, -60), "GATE OPEN!", Color.YELLOW)
		emit_signal("unlocked", self)
		queue_redraw()
		return true
	else:
		# Can't open - shake the gate and show info
		_shake_timer = 0.35
		var need = required_keys - player_keys
		game.spawn_damage_number(position + Vector2(0, -50),
			"Need %d key%s" % [need, "s" if need > 1 else ""],
			Color(1.0, 0.5, 0.2))
		queue_redraw()
		return false

func get_collision_rect() -> Rect2:
	if is_unlocked and _unlock_anim >= 1.0:
		return Rect2(0, 0, 0, 0)  # No collision once open
	return Rect2(
		position.x - gate_width * 0.5,
		position.y - gate_height,
		gate_width,
		gate_height * (1.0 - _unlock_anim)
	)

func _draw():
	if is_unlocked and _unlock_anim >= 1.0:
		return

	var w = gate_width
	var h = gate_height
	var open_offset = -h * _unlock_anim  # Negative = gate rises up
	var shake_x = 0.0
	if _shake_timer > 0.0:
		shake_x = sin(_shake_timer * 60.0) * 3.0

	# Gate base (top anchor bar - fixed, does not move)
	var bar_col = Color8(70, 65, 80)
	draw_rect(Rect2(-w * 0.5 + shake_x, -h - 12, w, 12), bar_col)
	draw_rect(Rect2(-w * 0.5 + shake_x, -h - 14, w, 3), bar_col.lightened(0.2))

	# Portcullis bars (vertical)
	var bar_count = maxi(2, int(w / 14))
	var bar_w = 8.0
	var spacing = w / float(bar_count)
	var gate_col = Color8(85, 80, 92)
	var gate_highlight = Color8(115, 110, 125)
	for i in range(bar_count):
		var bx = -w * 0.5 + spacing * float(i) + spacing * 0.5 - bar_w * 0.5 + shake_x
		var by = -h + open_offset
		var bh = h * (1.0 - _unlock_anim)
		draw_rect(Rect2(bx, by, bar_w, bh), gate_col)
		draw_rect(Rect2(bx + 1, by, 3, bh), gate_highlight)
		# Bottom spike
		var spike_pts = PackedVector2Array([
			Vector2(bx, by + bh),
			Vector2(bx + bar_w * 0.5, by + bh + 10),
			Vector2(bx + bar_w, by + bh)
		])
		draw_colored_polygon(spike_pts, gate_col)

	# Horizontal cross-braces
	var brace_count = maxi(1, int(h / 40))
	for i in range(brace_count):
		var brace_y = -h + open_offset + (float(i) + 0.5) * (h / float(brace_count)) * (1.0 - _unlock_anim)
		draw_rect(Rect2(-w * 0.5 + shake_x, brace_y - 3, w, 6), gate_col.darkened(0.1))

	# Lock icon (center of gate)
	if not is_unlocked:
		var lock_y = -h * 0.5 + open_offset
		var pulse = 0.6 + 0.4 * sin(_glow_pulse * 4.0)
		var lock_col = Color(1.0, 0.85, 0.2, pulse)
		# Lock body
		draw_rect(Rect2(-8 + shake_x, lock_y - 6, 16, 12), lock_col)
		# Lock shackle arc (approximated with 3 lines)
		draw_arc(Vector2(shake_x, lock_y - 6), 6.0, 0.0, PI, 8, lock_col, 2.5)
		# Key count badge
		if required_keys > 1:
			var font = ThemeDB.fallback_font
			draw_string(font, Vector2(-4 + shake_x, lock_y + 4), str(required_keys),
				HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color.WHITE)

	# Glow aura around gate (indicates interactable)
	var glow_alpha = (0.05 + 0.04 * sin(_glow_pulse * 3.5)) * (1.0 - _unlock_anim)
	draw_rect(Rect2(-w * 0.5 - 4 + shake_x, -h + open_offset - 4, w + 8, h * (1.0 - _unlock_anim) + 8),
		Color(1.0, 0.85, 0.2, glow_alpha))
