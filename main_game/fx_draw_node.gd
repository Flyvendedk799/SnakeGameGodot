class_name FXDrawNode
extends Node2D

# AAA Visual Overhaul: Stripped CPU effects - GPU shaders now handle:
#   vignette, chromatic aberration, bloom, film grain, color grading, tonemapping
# Retained CPU effects (require game state):
#   damage flash, low-HP pulse, level intro fade, speed lines, motion blur,
#   scanlines, ambient particles, light rays, foreground framing

var game = null  # Reference to main_game
var scanline_offset: float = 0.0
# Legacy bloom intensity (for backward compat with combat_system triggers)
var bloom_intensity: float = 0.0

# AAA Indie Upgrade: Advanced visual systems
var ambient_particles: Array = []  # Floating dust motes
var light_rays: Array = []  # Dynamic light shafts
var ambient_light_pulse: float = 0.0
const MAX_AMBIENT_PARTICLES = 80  # Phase 2.3: Increased from 40 with depth layers
# Depth layer split: 0=far (small/slow), 1=mid, 2=near (large/fast)
const DEPTH_COUNTS = [30, 30, 20]  # far, mid, near
# Theme-tinted particle colors: game.map.theme → color hints
const THEME_PARTICLE_COLORS = {
	"grass":   [Color(0.85, 0.95, 0.80, 1.0), Color(0.90, 0.92, 0.88, 1.0)],
	"cave":    [Color(0.70, 0.75, 0.90, 1.0), Color(0.60, 0.65, 0.80, 1.0)],
	"lava":    [Color(1.00, 0.70, 0.40, 1.0), Color(1.00, 0.55, 0.25, 1.0)],
	"ice":     [Color(0.75, 0.90, 1.00, 1.0), Color(0.80, 0.95, 1.00, 1.0)],
	"sky":     [Color(0.95, 0.95, 1.00, 1.0), Color(0.85, 0.88, 1.00, 1.0)],
	"summit":  [Color(0.85, 0.90, 0.95, 1.0), Color(0.90, 0.93, 1.00, 1.0)],
	"default": [Color(0.90, 0.90, 0.95, 1.0), Color(0.88, 0.88, 0.92, 1.0)],
}

func _ready():
	_init_ambient_particles()
	_init_light_rays()

func _process(delta: float):
	_update_ambient_particles(delta)
	_update_light_rays(delta)
	ambient_light_pulse = (sin(game.time_elapsed * 0.8) + 1.0) * 0.5 if game else 0.0
	# Route legacy bloom triggers to GPU post-process
	if bloom_intensity > 0.05 and game and game.post_process:
		game.post_process.trigger_bloom_boost(bloom_intensity * 0.5)
		bloom_intensity = lerpf(bloom_intensity, 0.0, delta * 4.0)
	queue_redraw()

func _draw():
	if game == null:
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	_draw_ambient_particles(vp_size)
	_draw_light_rays(vp_size)
	_draw_damage_flash(vp_size)
	_draw_motion_blur(vp_size)
	_draw_speed_lines(vp_size)
	_draw_scanlines(vp_size)
	_draw_low_hp_pulse(vp_size)
	_draw_level_intro_fade(vp_size)
	_draw_foreground_framing(vp_size)

	# Fallback: If no GPU post-process, draw CPU versions
	if not game.post_process:
		_draw_vignette_cpu(vp_size)
		_draw_chromatic_cpu(vp_size)
		_draw_film_grain_cpu(vp_size)
		_draw_color_grade_cpu(vp_size)

func _draw_damage_flash(vp_size: Vector2):
	if game.damage_flash_timer <= 0:
		return
	var alpha = clampf(game.damage_flash_timer / 0.25, 0.0, 1.0)
	var col = game.damage_flash_color
	col.a *= alpha * 0.6
	draw_rect(Rect2(Vector2.ZERO, vp_size), col)

func _draw_motion_blur(vp_size: Vector2):
	"""Velocity-based motion blur streaks when moving fast."""
	if game.player_node == null:
		return
	var vel = game.player_node.velocity.length()
	if vel < 400:
		return
	var intensity = clampf((vel - 400.0) / 400.0, 0.0, 1.0)
	var player_screen_pos = game.player_node.position - game.game_camera.position + vp_size * 0.5
	var line_count = int(8 * intensity)
	var vel_angle = game.player_node.velocity.angle()
	for i in range(line_count):
		var angle = vel_angle + PI + randf_range(-0.3, 0.3)
		var length = 40.0 * intensity
		var start = player_screen_pos
		var end_pt = start + Vector2(cos(angle), sin(angle)) * length
		var alpha = 0.15 * intensity * randf_range(0.6, 1.0)
		draw_line(start, end_pt, Color(1, 1, 1, alpha), 2.0)

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
	var urgency = 1.0 - (hp_ratio / 0.3)
	var pulse_speed = lerpf(2.0, 5.0, urgency)
	var pulse = (sin(game.time_elapsed * pulse_speed * TAU) + 1.0) * 0.5
	var alpha = urgency * pulse * 0.15
	var edge_col = Color(0.8, 0.05, 0.0, alpha)
	var edge_size = vp_size.x * 0.1
	draw_rect(Rect2(0, 0, edge_size, vp_size.y), edge_col)
	draw_rect(Rect2(vp_size.x - edge_size, 0, edge_size, vp_size.y), edge_col)
	draw_rect(Rect2(0, 0, vp_size.x, edge_size * 0.6), edge_col)
	draw_rect(Rect2(0, vp_size.y - edge_size * 0.6, vp_size.x, edge_size * 0.6), edge_col)

func _draw_level_intro_fade(vp_size: Vector2):
	if game.level_intro_timer <= 0:
		return
	var t = clampf(game.level_intro_timer / 2.0, 0.0, 1.0)
	var bar_h = vp_size.y * 0.08 * t
	var bar_col = Color(0, 0, 0, t * 0.9)
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), bar_col)
	draw_rect(Rect2(0, vp_size.y - bar_h, vp_size.x, bar_h), bar_col)
	if game.level_intro_timer > 1.5:
		var fade_t = clampf((game.level_intro_timer - 1.5) / 0.5, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0, 0, 0, fade_t))

func _draw_foreground_framing(vp_size: Vector2):
	"""Dark edge silhouettes for cinematic framing."""
	var frame_w = vp_size.x * 0.11
	var steps = 5
	var band_w = frame_w / float(steps)
	for i in range(steps):
		var t = float(i) / float(steps)
		var alpha = 0.5 * (1.0 - t * 0.6)
		var col = Color(0.03, 0.02, 0.1, alpha)
		var left = band_w * i
		var right = vp_size.x - band_w * (i + 1)
		draw_rect(Rect2(left, 0, band_w, vp_size.y), col)
		draw_rect(Rect2(right, 0, band_w, vp_size.y), col)

# ============================================================================
# AAA INDIE VISUAL SYSTEMS (ambient particles, light rays)
# ============================================================================

func _init_ambient_particles():
	ambient_particles.clear()
	# Phase 2.3: Depth-layered — far (slow/tiny), mid, near (fast/large)
	# [depth, size_min, size_max, speed_mult, alpha_min, alpha_max, drift_min, drift_max]
	var depth_params = [
		[0, 0.5, 1.2, 0.3,  0.05, 0.12, -4.0,  4.0],
		[1, 1.2, 2.2, 0.7,  0.10, 0.22, -8.0,  8.0],
		[2, 2.0, 4.0, 1.4,  0.18, 0.35, -12.0, 12.0],
	]
	for d in range(3):
		var p = depth_params[d]
		var count = DEPTH_COUNTS[d]
		for _i in range(count):
			ambient_particles.append({
				"pos":      Vector2(randf_range(0, 1280), randf_range(0, 720)),
				"velocity": Vector2(randf_range(p[6], p[7]),
				                    randf_range(-14, -3) * p[3]),
				"size":     randf_range(p[1], p[2]),
				"alpha":    randf_range(p[4], p[5]),
				"phase":    randf() * TAU,
				"depth":    p[0],
			})

func _update_ambient_particles(delta: float):
	var vp_size = get_viewport_rect().size
	for p in ambient_particles:
		p.pos += p.velocity * delta
		# Depth-scaled horizontal drift: far layers drift less
		var drift_scale = lerpf(0.5, 1.5, float(p.depth) / 2.0)
		p.pos.x += sin(game.time_elapsed * 0.5 + p.phase) * 15.0 * delta * drift_scale
		if p.pos.x < -10:
			p.pos.x = vp_size.x + 10
		elif p.pos.x > vp_size.x + 10:
			p.pos.x = -10
		if p.pos.y < -10:
			p.pos.y = vp_size.y + 10
		elif p.pos.y > vp_size.y + 10:
			p.pos.y = -10
		# Depth-scaled alpha range: near particles are more opaque
		var a_min = lerpf(0.05, 0.18, float(p.depth) / 2.0)
		var a_max = lerpf(0.12, 0.35, float(p.depth) / 2.0)
		p.alpha = lerpf(a_min, a_max, (sin(game.time_elapsed * 0.4 + p.phase) + 1.0) * 0.5)

func _get_theme_particle_color(depth: int) -> Color:
	var theme = "default"
	if game and game.get("map") and game.map.get("theme"):
		theme = game.map.theme
	var colors = THEME_PARTICLE_COLORS.get(theme, THEME_PARTICLE_COLORS["default"])
	# depth 0→far color [0], depth 2→near color [1], mid blends
	var t = float(depth) / 2.0
	return colors[0].lerp(colors[1], t)

func _draw_ambient_particles(vp_size: Vector2):
	for p in ambient_particles:
		var base_col = _get_theme_particle_color(p.depth)
		var col = Color(base_col.r, base_col.g, base_col.b, p.alpha)
		draw_circle(p.pos, p.size, col)

func _init_light_rays():
	light_rays.clear()
	for i in range(5):
		light_rays.append({
			"x": randf_range(100, 1180),
			"width": randf_range(60, 120),
			"intensity": randf_range(0.08, 0.15),
			"speed": randf_range(0.3, 0.8),
			"offset": randf() * TAU
		})

func _update_light_rays(delta: float):
	for ray in light_rays:
		ray.x += ray.speed * delta * 10.0
		ray.intensity = lerpf(0.08, 0.15, (sin(game.time_elapsed * ray.speed + ray.offset) + 1.0) * 0.5)
		if ray.x > 1380:
			ray.x = -100
			ray.width = randf_range(60, 120)

func _draw_light_rays(vp_size: Vector2):
	if game.player_node == null:
		return
	var hp_ratio = float(game.player_node.current_hp) / float(game.player_node.max_hp)
	var base_intensity = 1.0
	if hp_ratio < 0.4:
		base_intensity = 0.5
	for ray in light_rays:
		var col = Color(1.0, 0.98, 0.9, ray.intensity * base_intensity)
		var top_left = Vector2(ray.x - ray.width * 0.3, 0)
		var top_right = Vector2(ray.x + ray.width * 0.3, 0)
		var bot_left = Vector2(ray.x - ray.width * 0.5, vp_size.y * 0.6)
		var bot_right = Vector2(ray.x + ray.width * 0.5, vp_size.y * 0.6)
		for layer_idx in range(5):
			var t = float(layer_idx) / 5.0
			var alpha_mult = 1.0 - t
			var layer_col = Color(col.r, col.g, col.b, col.a * alpha_mult * 0.3)
			var l1 = top_left.lerp(bot_left, t)
			var l2 = top_right.lerp(bot_right, t)
			var l3 = top_left.lerp(bot_left, t + 0.2)
			var l4 = top_right.lerp(bot_right, t + 0.2)
			draw_polygon([l1, l2, l4, l3], [layer_col, layer_col, layer_col, layer_col])

# ============================================================================
# CPU FALLBACK: Used when GPU post-process pipeline is not active
# ============================================================================

func _draw_vignette_cpu(vp_size: Vector2):
	var intensity = game.vignette_intensity
	if intensity < 0.01:
		return
	var cx = vp_size.x * 0.5
	var cy = vp_size.y * 0.5
	var max_r = vp_size.length() * 0.5
	var ring_count = 12
	for i in range(ring_count):
		var t = float(i) / float(ring_count)
		var inner_r = lerpf(max_r * 0.45, max_r, t)
		var alpha = intensity * t * t * 0.85
		var col = Color(0.0, 0.0, 0.0, alpha)
		var thickness = max_r / float(ring_count)
		var top_h = maxf(cy - inner_r + thickness, 0)
		if top_h > 0:
			draw_rect(Rect2(0, 0, vp_size.x, top_h), col)
		var bot_y = cy + inner_r - thickness
		if bot_y < vp_size.y:
			draw_rect(Rect2(0, bot_y, vp_size.x, vp_size.y - bot_y), col)
		var left_w = maxf(cx - inner_r + thickness, 0)
		if left_w > 0:
			draw_rect(Rect2(0, 0, left_w, vp_size.y), col)
		var right_x = cx + inner_r - thickness
		if right_x < vp_size.x:
			draw_rect(Rect2(right_x, 0, vp_size.x - right_x, vp_size.y), col)

func _draw_chromatic_cpu(vp_size: Vector2):
	if game.chromatic_intensity < 0.01:
		return
	var intensity = game.chromatic_intensity
	var edge_w = vp_size.x * lerpf(0.05, 0.15, intensity)
	draw_rect(Rect2(0, 0, edge_w, vp_size.y), Color(1, 0.1, 0.1, 0.12 * intensity))
	draw_rect(Rect2(vp_size.x - edge_w, 0, edge_w, vp_size.y), Color(0.1, 0.8, 1.0, 0.12 * intensity))
	draw_rect(Rect2(0, 0, vp_size.x, edge_w * 0.6), Color(0.8, 0.2, 1.0, 0.06 * intensity))
	draw_rect(Rect2(0, vp_size.y - edge_w * 0.6, vp_size.x, edge_w * 0.6), Color(1.0, 0.9, 0.1, 0.06 * intensity))

func _draw_film_grain_cpu(vp_size: Vector2):
	var grain_density = 0.003
	var point_count = int(vp_size.x * vp_size.y * grain_density)
	for i in range(point_count):
		var x = randf_range(0, vp_size.x)
		var y = randf_range(0, vp_size.y)
		var brightness = randf_range(0.4, 1.0)
		var alpha = 0.08 * brightness
		draw_rect(Rect2(x, y, 1, 1), Color(brightness, brightness * 0.98, brightness * 0.95, alpha))

func _draw_color_grade_cpu(vp_size: Vector2):
	var warm_tint = Color(1.0, 0.95, 0.85, 0.04)
	draw_rect(Rect2(Vector2.ZERO, vp_size), warm_tint)
	var shadow_blue = Color(0.7, 0.8, 1.0, 0.02)
	var corner_size = vp_size.x * 0.15
	draw_rect(Rect2(0, 0, corner_size, corner_size), shadow_blue)
	draw_rect(Rect2(vp_size.x - corner_size, 0, corner_size, corner_size), shadow_blue)
	draw_rect(Rect2(0, vp_size.y - corner_size, corner_size, corner_size), shadow_blue)
	draw_rect(Rect2(vp_size.x - corner_size, vp_size.y - corner_size, corner_size, corner_size), shadow_blue)
