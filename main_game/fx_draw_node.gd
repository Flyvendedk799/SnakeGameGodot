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
# AAA Upgrade: Bloom intensity for glow effects
var bloom_intensity: float = 0.0

# AAA Indie Upgrade: Advanced visual systems
var ambient_particles: Array = []  # Floating dust motes
var light_rays: Array = []  # Dynamic light shafts
var film_grain_offset: float = 0.0
var color_grade_intensity: float = 1.0
var ambient_light_pulse: float = 0.0
const MAX_AMBIENT_PARTICLES = 40

func _ready():
	_init_ambient_particles()
	_init_light_rays()

func _process(delta: float):
	_update_ambient_particles(delta)
	_update_light_rays(delta)
	film_grain_offset += delta * 30.0  # Animate grain
	ambient_light_pulse = (sin(game.time_elapsed * 0.8) + 1.0) * 0.5 if game else 0.0
	queue_redraw()

func _draw():
	if game == null:
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	_draw_ambient_particles(vp_size)  # AAA Indie: Atmospheric depth
	_draw_light_rays(vp_size)  # AAA Indie: Dynamic lighting
	_draw_damage_flash(vp_size)
	_draw_vignette(vp_size)
	_draw_chromatic_edges(vp_size)
	_draw_bloom(vp_size)  # AAA Upgrade: Bloom & glow effects
	_draw_motion_blur(vp_size)  # AAA Upgrade: Player velocity-based motion blur
	_draw_speed_lines(vp_size)
	_draw_scanlines(vp_size)
	_draw_low_hp_pulse(vp_size)
	_draw_level_intro_fade(vp_size)
	_draw_film_grain(vp_size)  # AAA Indie: Texture depth
	_draw_color_grade(vp_size)  # AAA Indie: Cinematic color

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

	# AAA Upgrade: Dynamic edge width based on intensity (0.05 to 0.15)
	var edge_w = vp_size.x * lerpf(0.05, 0.15, intensity)

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

	# AAA Upgrade: Radial chromatic aberration from impact center
	if intensity > 0.3:
		var center = vp_size * 0.5
		var offset = 8.0 * intensity
		# Red shifted outward
		draw_circle(center + Vector2(offset, 0), 30, Color(1, 0, 0, 0.2 * intensity))
		# Cyan shifted inward
		draw_circle(center - Vector2(offset, 0), 30, Color(0, 1, 1, 0.2 * intensity))

		# Additional ring aberration for strong impacts
		if intensity > 0.6:
			var ring_offset = 12.0 * intensity
			draw_arc(center, 50, 0, TAU, 24, Color(1, 0.2, 0.2, 0.15 * intensity), 2.0 + offset * 0.3)
			draw_arc(center, 50 + ring_offset, 0, TAU, 24, Color(0.2, 1, 1, 0.15 * intensity), 2.0 + offset * 0.3)

func _draw_bloom(vp_size: Vector2):
	"""AAA Upgrade: Bloom & glow post-processing - soft glow around bright elements."""
	if bloom_intensity < 0.05:
		return

	# Draw glow around player during dash or special moves
	if game.player_node == null:
		return

	var player_screen_pos = game.player_node.position - game.game_camera.position + vp_size * 0.5

	# Draw when dashing or when bloom is triggered
	if game.player_node.is_dashing or bloom_intensity > 0.1:
		# Multiple expanding circles for bloom effect
		for radius in [60, 80, 100]:
			var alpha = bloom_intensity * 0.08
			draw_circle(player_screen_pos, radius, Color(1, 1, 1, alpha))

		# Extra bright core
		draw_circle(player_screen_pos, 30, Color(1, 1, 1, bloom_intensity * 0.12))

func _draw_motion_blur(vp_size: Vector2):
	"""AAA Upgrade: Velocity-based motion blur - radial streaks when moving fast."""
	if game.player_node == null:
		return

	var vel = game.player_node.velocity.length()
	if vel < 400:
		return  # Only draw when fast

	# Intensity scales from 0.0 at 400 to 1.0 at 800 velocity
	var intensity = clampf((vel - 400.0) / 400.0, 0.0, 1.0)

	# Convert player world position to screen position
	var player_screen_pos = game.player_node.position - game.game_camera.position + vp_size * 0.5

	# Draw radial blur streaks emanating from player
	var line_count = int(8 * intensity)
	var vel_angle = game.player_node.velocity.angle()

	for i in range(line_count):
		# Streaks point opposite to movement direction with some spread
		var angle = vel_angle + PI + randf_range(-0.3, 0.3)
		var length = 40.0 * intensity
		var start = player_screen_pos
		var end = start + Vector2(cos(angle), sin(angle)) * length
		var alpha = 0.15 * intensity * randf_range(0.6, 1.0)
		draw_line(start, end, Color(1, 1, 1, alpha), 2.0)

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

# ============================================================================
# AAA INDIE VISUAL SYSTEMS
# ============================================================================

func _init_ambient_particles():
	"""Initialize floating dust motes for atmospheric depth."""
	ambient_particles.clear()
	for i in range(MAX_AMBIENT_PARTICLES):
		ambient_particles.append({
			"pos": Vector2(randf_range(0, 1280), randf_range(0, 720)),
			"velocity": Vector2(randf_range(-8, 8), randf_range(-12, -4)),
			"size": randf_range(1.0, 3.0),
			"alpha": randf_range(0.1, 0.3),
			"phase": randf() * TAU
		})

func _update_ambient_particles(delta: float):
	"""Animate ambient particles with slow drift."""
	var vp_size = get_viewport_rect().size
	for p in ambient_particles:
		# Drift movement
		p.pos += p.velocity * delta

		# Sine wave horizontal drift
		p.pos.x += sin(game.time_elapsed * 0.5 + p.phase) * 15.0 * delta

		# Wrap around screen
		if p.pos.x < -10:
			p.pos.x = vp_size.x + 10
		elif p.pos.x > vp_size.x + 10:
			p.pos.x = -10

		if p.pos.y < -10:
			p.pos.y = vp_size.y + 10
		elif p.pos.y > vp_size.y + 10:
			p.pos.y = -10

		# Pulse alpha
		p.alpha = lerpf(0.1, 0.3, (sin(game.time_elapsed * 0.4 + p.phase) + 1.0) * 0.5)

func _draw_ambient_particles(vp_size: Vector2):
	"""Draw floating dust motes for atmospheric depth."""
	for p in ambient_particles:
		var col = Color(0.9, 0.9, 0.95, p.alpha)
		draw_circle(p.pos, p.size, col)

func _init_light_rays():
	"""Initialize dynamic light ray system."""
	light_rays.clear()
	# Create 5 light shafts from above
	for i in range(5):
		light_rays.append({
			"x": randf_range(100, 1180),
			"width": randf_range(60, 120),
			"intensity": randf_range(0.08, 0.15),
			"speed": randf_range(0.3, 0.8),
			"offset": randf() * TAU
		})

func _update_light_rays(delta: float):
	"""Animate light rays with slow drift."""
	for ray in light_rays:
		ray.x += ray.speed * delta * 10.0
		ray.intensity = lerpf(0.08, 0.15, (sin(game.time_elapsed * ray.speed + ray.offset) + 1.0) * 0.5)

		# Wrap around
		if ray.x > 1380:
			ray.x = -100
			ray.width = randf_range(60, 120)

func _draw_light_rays(vp_size: Vector2):
	"""Draw dynamic god rays from top of screen."""
	if game.player_node == null:
		return

	# Only draw if player is in darker areas or at low HP for dramatic effect
	var hp_ratio = float(game.player_node.current_hp) / float(game.player_node.max_hp)
	var base_intensity = 1.0
	if hp_ratio < 0.4:
		base_intensity = 0.5  # Dim rays at low HP for darker mood

	for ray in light_rays:
		var col = Color(1.0, 0.98, 0.9, ray.intensity * base_intensity)

		# Draw tapered light shaft from top
		var top_left = Vector2(ray.x - ray.width * 0.3, 0)
		var top_right = Vector2(ray.x + ray.width * 0.3, 0)
		var bot_left = Vector2(ray.x - ray.width * 0.5, vp_size.y * 0.6)
		var bot_right = Vector2(ray.x + ray.width * 0.5, vp_size.y * 0.6)

		# Draw as gradient-like by layering multiple rects
		for layer in range(5):
			var t = float(layer) / 5.0
			var alpha_mult = 1.0 - t
			var layer_col = Color(col.r, col.g, col.b, col.a * alpha_mult * 0.3)

			var l1 = top_left.lerp(bot_left, t)
			var l2 = top_right.lerp(bot_right, t)
			var l3 = top_left.lerp(bot_left, t + 0.2)
			var l4 = top_right.lerp(bot_right, t + 0.2)

			draw_polygon([l1, l2, l4, l3], [layer_col, layer_col, layer_col, layer_col])

func _draw_film_grain(vp_size: Vector2):
	"""Draw subtle film grain texture overlay."""
	# Draw randomized noise points
	var grain_density = 0.003  # 0.3% of pixels
	var point_count = int(vp_size.x * vp_size.y * grain_density)

	for i in range(point_count):
		var x = randf_range(0, vp_size.x)
		var y = randf_range(0, vp_size.y)
		var brightness = randf_range(0.4, 1.0)
		var alpha = 0.08 * brightness

		# Slightly colored grain for warmth
		var col = Color(brightness, brightness * 0.98, brightness * 0.95, alpha)
		draw_rect(Rect2(x, y, 1, 1), col)

func _draw_color_grade(vp_size: Vector2):
	"""Apply cinematic color grading overlay."""
	if color_grade_intensity < 0.01:
		return

	# Warm tint overlay (slight orange/amber for cinematic feel)
	var warm_tint = Color(1.0, 0.95, 0.85, 0.04 * color_grade_intensity)
	draw_rect(Rect2(Vector2.ZERO, vp_size), warm_tint)

	# Subtle blue shadows in corners
	var shadow_blue = Color(0.7, 0.8, 1.0, 0.02 * color_grade_intensity)
	var corner_size = vp_size.x * 0.15
	draw_rect(Rect2(0, 0, corner_size, corner_size), shadow_blue)
	draw_rect(Rect2(vp_size.x - corner_size, 0, corner_size, corner_size), shadow_blue)
	draw_rect(Rect2(0, vp_size.y - corner_size, corner_size, corner_size), shadow_blue)
	draw_rect(Rect2(vp_size.x - corner_size, vp_size.y - corner_size, corner_size, corner_size), shadow_blue)

	# Ambient light pulse (breathes with time)
	var pulse_alpha = 0.015 * ambient_light_pulse * color_grade_intensity
	var pulse_col = Color(1.0, 0.98, 0.9, pulse_alpha)
	draw_rect(Rect2(Vector2.ZERO, vp_size), pulse_col)
