class_name FXDrawNode
extends Node2D

# Draws full-screen post-processing effects:
# - Vignette (HP-reactive)
# - Damage flash (red screen pulse)
# - Chromatic aberration (simulated color-split edges)
# - Speed lines (radial motion blur effect)
# - CRT scanlines (subtle retro feel)
# - Low-HP heartbeat pulse

var game = null  # Reference to main_game
var scanline_offset: float = 0.0

func _draw():
	if game == null:
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	_draw_damage_flash(vp_size)
	_draw_vignette(vp_size)
	_draw_chromatic_edges(vp_size)
	_draw_speed_lines(vp_size)
	_draw_scanlines(vp_size)
	_draw_low_hp_pulse(vp_size)
	_draw_level_intro_fade(vp_size)

func _draw_damage_flash(vp_size: Vector2):
	if game.damage_flash_timer <= 0:
		return
	var alpha = clampf(game.damage_flash_timer / 0.25, 0.0, 1.0)
	var col = game.damage_flash_color
	col.a *= alpha * 0.6
	draw_rect(Rect2(Vector2.ZERO, vp_size), col)

func _draw_vignette(vp_size: Vector2):
	var intensity = game.vignette_intensity
	if intensity < 0.01:
		return
	var cx = vp_size.x * 0.5
	var cy = vp_size.y * 0.5
	var max_r = vp_size.length() * 0.5
	# Draw concentric darkened rings from edge inward
	var ring_count = 12
	for i in range(ring_count):
		var t = float(i) / float(ring_count)
		var inner_r = lerpf(max_r * 0.45, max_r, t)
		var alpha = intensity * t * t * 0.85
		var col = Color(0.0, 0.0, 0.0, alpha)
		# Approximate ring with 4 rects at edges
		var thickness = max_r / float(ring_count)
		# Top
		var top_h = maxf(cy - inner_r + thickness, 0)
		if top_h > 0:
			draw_rect(Rect2(0, 0, vp_size.x, top_h), col)
		# Bottom
		var bot_y = cy + inner_r - thickness
		if bot_y < vp_size.y:
			draw_rect(Rect2(0, bot_y, vp_size.x, vp_size.y - bot_y), col)
		# Left
		var left_w = maxf(cx - inner_r + thickness, 0)
		if left_w > 0:
			draw_rect(Rect2(0, 0, left_w, vp_size.y), col)
		# Right
		var right_x = cx + inner_r - thickness
		if right_x < vp_size.x:
			draw_rect(Rect2(right_x, 0, vp_size.x - right_x, vp_size.y), col)

func _draw_chromatic_edges(vp_size: Vector2):
	if game.chromatic_intensity < 0.01:
		return
	var intensity = game.chromatic_intensity
	var edge_w = vp_size.x * 0.08 * intensity
	# Red tint on left edge
	var red = Color(1, 0.1, 0.1, 0.12 * intensity)
	draw_rect(Rect2(0, 0, edge_w, vp_size.y), red)
	# Cyan tint on right edge
	var cyan = Color(0.1, 0.8, 1.0, 0.12 * intensity)
	draw_rect(Rect2(vp_size.x - edge_w, 0, edge_w, vp_size.y), cyan)
	# Slight color shift top/bottom
	var top_col = Color(0.8, 0.2, 1.0, 0.06 * intensity)
	draw_rect(Rect2(0, 0, vp_size.x, edge_w * 0.6), top_col)
	var bot_col = Color(1.0, 0.9, 0.1, 0.06 * intensity)
	draw_rect(Rect2(0, vp_size.y - edge_w * 0.6, vp_size.x, edge_w * 0.6), bot_col)

func _draw_speed_lines(vp_size: Vector2):
	if game.speed_line_intensity < 0.05:
		return
	var intensity = game.speed_line_intensity
	var cx = vp_size.x * 0.5
	var cy = vp_size.y * 0.5
	var max_r = vp_size.length() * 0.55
	var line_count = int(18 * intensity)
	var time = game.time_elapsed
	for i in range(line_count):
		var angle = (float(i) / float(line_count)) * TAU + sin(time * 2.0 + i) * 0.1
		var r_start = max_r * lerpf(0.6, 0.8, fmod(time * 3.0 + i * 0.37, 1.0))
		var r_end = max_r * 1.1
		var p1 = Vector2(cx + cos(angle) * r_start, cy + sin(angle) * r_start)
		var p2 = Vector2(cx + cos(angle) * r_end, cy + sin(angle) * r_end)
		var alpha = intensity * 0.15 * randf_range(0.5, 1.0)
		draw_line(p1, p2, Color(1, 1, 1, alpha), 1.5)

func _draw_scanlines(vp_size: Vector2):
	# Subtle CRT scanlines for retro feel
	scanline_offset = fmod(scanline_offset + 0.5, 4.0)
	var alpha = 0.03
	var y = int(scanline_offset)
	while y < int(vp_size.y):
		draw_line(Vector2(0, y), Vector2(vp_size.x, y), Color(0, 0, 0, alpha), 1.0)
		y += 4

func _draw_low_hp_pulse(vp_size: Vector2):
	if game.player_node == null or game.player_node.is_dead:
		return
	var hp_ratio = float(game.player_node.current_hp) / float(game.player_node.max_hp)
	if hp_ratio > 0.3:
		return
	# Heartbeat pulse: grows more intense as HP drops
	var urgency = 1.0 - (hp_ratio / 0.3)
	var pulse_speed = lerpf(2.0, 5.0, urgency)
	var pulse = (sin(game.time_elapsed * pulse_speed * TAU) + 1.0) * 0.5
	var alpha = urgency * pulse * 0.15
	var edge_col = Color(0.8, 0.05, 0.0, alpha)
	# Red edge glow
	var edge_size = vp_size.x * 0.1
	draw_rect(Rect2(0, 0, edge_size, vp_size.y), edge_col)
	draw_rect(Rect2(vp_size.x - edge_size, 0, edge_size, vp_size.y), edge_col)
	draw_rect(Rect2(0, 0, vp_size.x, edge_size * 0.6), edge_col)
	draw_rect(Rect2(0, vp_size.y - edge_size * 0.6, vp_size.x, edge_size * 0.6), edge_col)

func _draw_level_intro_fade(vp_size: Vector2):
	if game.level_intro_timer <= 0:
		return
	# Black bars cinematic letterbox + fade-in
	var t = clampf(game.level_intro_timer / 2.0, 0.0, 1.0)
	var bar_h = vp_size.y * 0.08 * t
	var bar_col = Color(0, 0, 0, t * 0.9)
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), bar_col)
	draw_rect(Rect2(0, vp_size.y - bar_h, vp_size.x, bar_h), bar_col)
	# Screen fade from black
	if game.level_intro_timer > 1.5:
		var fade_t = clampf((game.level_intro_timer - 1.5) / 0.5, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0, 0, 0, fade_t))
