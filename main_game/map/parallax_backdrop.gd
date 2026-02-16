class_name ParallaxBackdrop
extends Node2D

## Enhanced layered parallax background with animated elements.
## Clouds, stars, ambient particles, and theme-specific details.

var game = null
var theme_name: String = "grass"
var level_width: float = 2400
var level_height: float = 720
var time: float = 0.0

# Theme color palettes: [sky_top, sky_mid, sky_bottom, far_hills, mid_hills, near_hills]
const THEMES = {
	"grass": [Color8(135, 205, 235), Color8(100, 180, 220), Color8(70, 160, 200), Color8(55, 120, 70), Color8(75, 140, 85), Color8(95, 160, 95)],
	"cave": [Color8(18, 15, 28), Color8(28, 24, 40), Color8(38, 34, 52), Color8(42, 38, 50), Color8(48, 44, 55), Color8(55, 50, 62)],
	"sky": [Color8(180, 220, 255), Color8(140, 190, 240), Color8(100, 160, 220), Color8(200, 180, 220), Color8(180, 160, 200), Color8(160, 140, 180)],
	"summit": [Color8(200, 230, 255), Color8(170, 200, 235), Color8(140, 170, 210), Color8(120, 140, 160), Color8(140, 150, 165), Color8(160, 165, 175)],
	"lava": [Color8(60, 20, 15), Color8(80, 30, 18), Color8(110, 40, 20), Color8(50, 25, 15), Color8(65, 30, 18), Color8(80, 35, 20)],
	"ice": [Color8(200, 230, 250), Color8(170, 210, 240), Color8(140, 190, 230), Color8(160, 180, 200), Color8(140, 170, 195), Color8(120, 160, 190)]
}

# Pre-generated cloud positions (deterministic per setup)
var cloud_data: Array = []
var star_data: Array = []
var _parallax_frame: int = 0

func setup(game_ref, theme: String, width: float, height: float):
	game = game_ref
	theme_name = theme if theme in THEMES else "grass"
	level_width = width
	level_height = height
	_generate_clouds()
	_generate_stars()
	queue_redraw()

func _generate_clouds():
	cloud_data.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) + int(level_width)
	var count = 16 + int(level_width / 250)
	for i in range(count):
		cloud_data.append({
			"x": rng.randf_range(-200, level_width + 200),
			"y": rng.randf_range(-150, level_height * 0.3),
			"w": rng.randf_range(80, 200),
			"h": rng.randf_range(20, 50),
			"speed": rng.randf_range(3.0, 12.0),
			"parallax": rng.randf_range(0.1, 0.35),
			"alpha": rng.randf_range(0.08, 0.25),
		})

func _generate_stars():
	star_data.clear()
	if theme_name != "cave" and theme_name != "lava":
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(theme_name) * 7
	for i in range(40):
		star_data.append({
			"x": rng.randf_range(-300, level_width + 300),
			"y": rng.randf_range(-200, level_height * 0.5),
			"size": rng.randf_range(1.0, 3.0),
			"twinkle_speed": rng.randf_range(1.5, 5.0),
			"twinkle_offset": rng.randf_range(0, TAU),
		})

func _process(delta):
	if game and visible:
		time += delta
		_parallax_frame += 1
		# Throttle redraw to every 2nd frame to reduce cost during jumps/scrolling
		if _parallax_frame % 2 == 0:
			queue_redraw()

func _draw():
	if game == null or game.game_camera == null:
		return
	var cam_pos = game.game_camera.position
	var pal = THEMES.get(theme_name, THEMES["grass"])

	# AAA Upgrade: Y-depth based parallax adjustment
	var player_y = game.player_node.position.y if game.player_node else cam_pos.y
	var depth_factor = DepthPlanes.get_parallax_factor_for_y(player_y)

	# Sky gradient (vertical bands)
	var offset0 = -cam_pos * (0.9 * depth_factor)
	var sky_left = offset0.x - 400
	var sky_w = level_width + 1600
	var strip_h = 20.0
	for i in range(int(level_height / strip_h) + 35):
		var y = -300.0 + i * strip_h
		var t = clampf((y + 300) / (level_height + 500), 0.0, 1.0)
		var band_col = pal[0].lerp(pal[2], t)
		draw_rect(Rect2(sky_left, y, sky_w, strip_h + 1), band_col)

	# Stars (cave/lava themes) / Sun/Moon (outdoor themes)
	if star_data.size() > 0:
		for star in star_data:
			var sx = star.x + offset0.x * 0.15
			var sy = star.y + offset0.y * 0.1
			var twinkle = 0.4 + 0.6 * (sin(time * star.twinkle_speed + star.twinkle_offset) * 0.5 + 0.5)
			var col = Color(1, 1, 0.9, twinkle * 0.6)
			draw_circle(Vector2(sx, sy), star.size * twinkle, col)
	elif theme_name != "cave" and theme_name != "lava":
		# Sun/moon
		var sun_x = offset0.x + level_width * 0.7
		var sun_y = -50.0 + offset0.y * 0.05
		var sun_col = Color(1, 0.95, 0.8, 0.3)
		for ri in range(4):
			draw_circle(Vector2(sun_x, sun_y), 35 + ri * 15, Color(sun_col.r, sun_col.g, sun_col.b, sun_col.a * (1.0 - ri * 0.2)))
		draw_circle(Vector2(sun_x, sun_y), 25, Color(1, 0.98, 0.9, 0.5))

	# Clouds with soft parallax drift
	for cloud in cloud_data:
		var cx = cloud.x + offset0.x * cloud.parallax + time * cloud.speed
		var cy = cloud.y + offset0.y * cloud.parallax * 0.3
		# Wrap clouds
		var total_w = level_width + 600
		cx = fmod(cx + 400, total_w) - 400
		var w = cloud.w
		var h = cloud.h
		var alpha = cloud.alpha
		if theme_name == "cave":
			alpha *= 0.3  # Very faint in caves
		elif theme_name == "lava":
			alpha *= 0.5  # Smoke-like
		# Multi-blob cloud shape
		var cloud_col = Color(1, 1, 1, alpha) if theme_name != "lava" else Color(0.3, 0.2, 0.15, alpha)
		if theme_name == "cave":
			cloud_col = Color(0.2, 0.15, 0.25, alpha)
		draw_rect(Rect2(cx, cy, w, h), cloud_col)
		draw_rect(Rect2(cx + w * 0.15, cy - h * 0.4, w * 0.5, h * 0.6), cloud_col)
		draw_rect(Rect2(cx + w * 0.4, cy - h * 0.2, w * 0.4, h * 0.4), cloud_col)

	# Distant mountains/silhouettes (parallax ~0.3 with depth adjustment)
	var offset1 = -cam_pos * (0.3 * depth_factor)
	var hill_h = level_height * 0.65
	for i in range(int(level_width / 90) + 6):
		var bx = offset1.x + i * 90.0 + fmod(cam_pos.x * 0.03, 90)
		var by = level_height - hill_h * (0.35 + 0.25 * sin(i * 0.6))
		var hill_col = pal[3].darkened(0.2)
		draw_rect(Rect2(bx, by, 140, hill_h + 60), hill_col)
		# Snow caps on summit theme
		if theme_name == "summit" or theme_name == "ice":
			var cap_h = 12.0 + sin(i * 1.3) * 6
			draw_rect(Rect2(bx + 10, by, 120, cap_h), Color(0.95, 0.97, 1.0, 0.5))

	# DISTANT LANDMARKS - fortress, ship, far islands (Shantae-style map depth)
	var offset_landmark = -cam_pos * 0.25
	_draw_distant_landmarks(offset_landmark, pal, hill_h)

	# Atmospheric depth fog layer 1 (after distant mountains - 40% fog intensity)
	_draw_depth_fog(offset0, 0.40)

	# Mid-ground hills (parallax ~0.5)
	var offset2 = -cam_pos * (0.5 * depth_factor)
	for i in range(int(level_width / 65) + 8):
		var bx = offset2.x + i * 65.0 + fmod(cam_pos.x * 0.06, 65)
		var by = level_height - hill_h * (0.32 + 0.28 * sin(i * 0.5 + 1))
		draw_rect(Rect2(bx, by, 95, hill_h + 35), pal[4])
		# Tree silhouettes on grass theme
		if theme_name == "grass" and i % 3 == 0:
			var tree_h = 30.0 + sin(i * 2.1) * 10
			draw_rect(Rect2(bx + 35, by - tree_h, 8, tree_h), pal[4].darkened(0.15))
			draw_rect(Rect2(bx + 20, by - tree_h + 5, 38, 15), pal[4].darkened(0.1))
			draw_rect(Rect2(bx + 25, by - tree_h - 5, 28, 12), pal[4].darkened(0.05))

	# MIDGROUND WATER BODY - calm water layer (grass, sky themes) - Shantae-style depth
	if theme_name == "grass" or theme_name == "sky":
		_draw_midground_water(offset2, pal)

	# Atmospheric depth fog layer 2 (after mid-ground hills - 20% fog intensity)
	_draw_depth_fog(offset0, 0.20)

	# Near hills (parallax ~0.7) - more density
	var offset3 = -cam_pos * (0.7 * depth_factor)
	for i in range(int(level_width / 35) + 14):
		var bx = offset3.x + i * 35.0 + fmod(cam_pos.x * 0.1, 35)
		var by = level_height - hill_h * (0.28 + 0.32 * sin(i * 0.4 + 2))
		draw_rect(Rect2(bx, by, 55, hill_h + 25), pal[5])
	# Sky theme: floating island silhouettes
	if theme_name == "sky":
		var offset_isl = -cam_pos * 0.5
		for i in range(int(level_width / 400) + 4):
			var ix = offset_isl.x + i * 380.0 + fmod(cam_pos.x * 0.04, 380)
			var iy = level_height - 150.0 - 80.0 * sin(i * 1.2)
			draw_rect(Rect2(ix, iy, 120, 120), pal[4].darkened(0.3))
			draw_rect(Rect2(ix + 20, iy - 30, 80, 80), pal[5].darkened(0.2))

	# Ceiling details (cave: stalactites; summit: icicles)
	if theme_name == "cave":
		var offset_ceil = -cam_pos * 0.85
		for i in range(int(level_width / 60) + 8):
			var cx = offset_ceil.x + i * 60.0 + fmod(cam_pos.x * 0.08, 60)
			var drop = 20.0 + fmod(i * 4.7, 35.0)
			draw_rect(Rect2(cx, -80, 6, drop), Color8(55, 50, 65))
			draw_rect(Rect2(cx + 1, -78, 4, drop * 0.3), Color8(70, 65, 78))
	elif theme_name == "summit" or theme_name == "ice":
		var offset_ceil = -cam_pos * 0.85
		for i in range(int(level_width / 80) + 6):
			var cx = offset_ceil.x + i * 80.0 + fmod(cam_pos.x * 0.06, 80)
			var drop = 12.0 + fmod(i * 3.1, 18.0)
			draw_rect(Rect2(cx, -60, 4, drop), Color(0.9, 0.95, 1.0, 0.5))
			draw_rect(Rect2(cx + 1, -58, 2, drop * 0.4), Color(1, 1, 1, 0.6))

	# Atmospheric depth fog layer 3 (after near hills - 5% fog intensity)
	_draw_depth_fog(offset0, 0.05)

	# Foreground foliage/props (parallax ~0.9) - DENSER
	var offset4 = -cam_pos * (0.9 * depth_factor)
	var fg_count = int(level_width / 55) + 12
	for i in range(fg_count):
		var fx = offset4.x + i * 55.0 + fmod(cam_pos.x * 0.15, 55)
		var fy = level_height - 40.0 - 25.0 * sin(i * 0.8)
		match theme_name:
			"grass":
				# Animated grass clusters
				var wind = sin(time * 2.0 + i * 0.7) * 4.0
				draw_line(Vector2(fx, fy), Vector2(fx + wind, fy - 20), pal[5].darkened(0.05), 2.0)
				draw_line(Vector2(fx + 8, fy), Vector2(fx + 8 + wind * 0.8, fy - 16), pal[5].darkened(0.1), 2.0)
				draw_line(Vector2(fx + 16, fy), Vector2(fx + 16 + wind * 1.1, fy - 22), pal[5], 2.0)
				# Flower dot
				if i % 3 == 0:
					draw_circle(Vector2(fx + 8 + wind, fy - 18), 3, Color(1, 0.8, 0.3, 0.6))
			"cave":
				# Stalagmites
				var stg_h = 25.0 + fmod(i * 7.3, 20.0)
				draw_rect(Rect2(fx, fy - stg_h, 8, stg_h), pal[5].lightened(0.05))
				draw_rect(Rect2(fx + 2, fy - stg_h, 4, 3), pal[5].lightened(0.15))
			"lava":
				# Ember/rock formations
				draw_rect(Rect2(fx, fy - 15, 12, 15), pal[5].darkened(0.1))
				var ember_alpha = 0.3 + 0.2 * sin(time * 3.0 + i)
				draw_circle(Vector2(fx + 6, fy - 18), 3, Color(1, 0.4, 0.1, ember_alpha))
			"summit", "ice":
				# Snow particles / ice crystals
				var crystal_bob = sin(time * 1.5 + i * 1.1) * 3.0
				draw_circle(Vector2(fx, fy - 10 + crystal_bob), 4, Color(0.85, 0.9, 1.0, 0.3))

	# Atmospheric fog/haze near horizon (enhanced)
	for i in range(int(level_height / 16) + 1):
		var fy = level_height * 0.45 + i * 16.0
		var fog_t = clampf((fy - level_height * 0.45) / (level_height * 0.55), 0.0, 1.0)
		var fog_c: Color
		match theme_name:
			"cave":
				fog_c = Color(0.1, 0.08, 0.15, fog_t * 0.1)
			"lava":
				fog_c = Color(0.3, 0.1, 0.05, fog_t * 0.1)
			_:
				fog_c = Color(1.0, 1.0, 1.0, fog_t * 0.06)
		draw_rect(Rect2(offset0.x - 500, fy, level_width + 2000, 18), fog_c)

	# Weather effects
	_draw_weather(cam_pos)

func _draw_weather(cam_pos: Vector2):
	match theme_name:
		"cave":
			# Falling dust motes
			for i in range(15):
				var mx = cam_pos.x - 600 + fmod(time * (8.0 + i * 2.0) + i * 137.0, 1400.0)
				var my = cam_pos.y - 400 + fmod(time * (15.0 + i * 1.5) + i * 97.0, 900.0)
				var mote_alpha = 0.15 + 0.1 * sin(time * 2.0 + i)
				draw_circle(Vector2(mx, my), 1.5, Color(0.6, 0.5, 0.4, mote_alpha))
		"lava":
			# Rising embers
			for i in range(20):
				var ex = cam_pos.x - 600 + fmod(i * 127.0 + sin(time + i) * 30, 1400.0)
				var base_y = cam_pos.y + 400
				var ey = base_y - fmod(time * (20.0 + i * 3.0) + i * 83.0, 800.0)
				var ember_alpha = clampf((base_y - ey) / 600.0, 0, 0.5)
				var ember_col = Color(1, 0.5 + randf() * 0.3, 0.1, ember_alpha)
				draw_circle(Vector2(ex + sin(time * 2.0 + i) * 8, ey), 2.0, ember_col)
		"ice":
			# Snowflakes
			for i in range(25):
				var sx = cam_pos.x - 600 + fmod(i * 103.0 + time * (5.0 + i * 0.5) + sin(time * 0.5 + i) * 20, 1400.0)
				var sy = cam_pos.y - 400 + fmod(time * (12.0 + i * 1.0) + i * 61.0, 900.0)
				var snow_drift = sin(time * 1.5 + i * 0.8) * 8.0
				var snow_alpha = 0.2 + 0.15 * sin(time + i * 0.5)
				draw_circle(Vector2(sx + snow_drift, sy), 2.0 + sin(i * 0.3) * 1.0, Color(1, 1, 1, snow_alpha))
		"grass":
			# Floating leaf particles
			for i in range(8):
				var lx = cam_pos.x - 600 + fmod(i * 197.0 + time * (6.0 + i * 1.5), 1400.0)
				var ly = cam_pos.y - 300 + fmod(time * (8.0 + i * 0.8) + i * 71.0, 700.0)
				var leaf_drift = sin(time * 2.0 + i * 1.2) * 12.0
				var leaf_alpha = 0.15 + 0.1 * sin(time * 1.5 + i)
				draw_rect(Rect2(lx + leaf_drift, ly, 4, 2), Color(0.4, 0.6, 0.2, leaf_alpha))

func _draw_distant_landmarks(offset: Vector2, pal: Array, hill_h: float):
	"""Draw distant landmarks: fortress, ship, islands (Shantae-style map design)."""
	match theme_name:
		"grass":
			# Distant fortress/castle on the right (sandy ancient style)
			var fort_x = offset.x + level_width * 0.85
			var fort_y = level_height - hill_h * 0.7
			var fort_w = 180
			var fort_h = hill_h * 0.9
			draw_rect(Rect2(fort_x, fort_y, fort_w, fort_h), pal[3].darkened(0.3))
			draw_rect(Rect2(fort_x + 15, fort_y - 20, 50, 25), pal[3].darkened(0.2))  # Tower
			draw_rect(Rect2(fort_x + 115, fort_y - 30, 40, 35), pal[3].darkened(0.15))  # Dome
			draw_rect(Rect2(fort_x + 60, fort_y + fort_h * 0.3, 60, 40), Color8(80, 70, 90, 150))  # Arch
			# Pirate ship anchored near mid-left
			var ship_x = offset.x + level_width * 0.15
			var ship_y = level_height - 80
			draw_rect(Rect2(ship_x, ship_y, 120, 45), Color8(60, 45, 35))
			draw_rect(Rect2(ship_x + 50, ship_y - 55, 25, 60), Color8(80, 50, 90))  # Purple sail
			draw_rect(Rect2(ship_x + 55, ship_y - 50, 15, 50), Color8(100, 70, 110))
			# Small palm islands in midground
			for i in range(4):
				var ix = offset.x + level_width * (0.2 + i * 0.22) + sin(i * 1.7) * 80
				var iy = level_height - 35.0 - 25.0 * sin(i * 0.9)
				draw_rect(Rect2(ix, iy, 70, 45), pal[5].darkened(0.1))
				draw_rect(Rect2(ix + 20, iy - 30 - sin(i) * 8, 8, 35), pal[4].darkened(0.2))
				draw_rect(Rect2(ix + 15, iy - 35, 25, 12), pal[4].darkened(0.15))
		"sky":
			# Floating island structures
			var isl_x = offset.x + level_width * 0.7
			var isl_y = level_height - 140
			draw_rect(Rect2(isl_x, isl_y, 100, 80), pal[4].darkened(0.25))
			draw_rect(Rect2(isl_x + 30, isl_y - 20, 40, 25), pal[5].darkened(0.2))
		"summit", "ice":
			# Distant peak/fortress
			var peak_x = offset.x + level_width * 0.8
			var peak_y = level_height - hill_h * 0.6
			draw_rect(Rect2(peak_x, peak_y, 140, hill_h * 0.65), pal[3].darkened(0.25))
			draw_rect(Rect2(peak_x + 20, peak_y, 100, 20), Color(0.95, 0.97, 1.0, 0.6))

func _draw_midground_water(offset: Vector2, pal: Array):
	"""Draw calm water body (grass) or cloud sea (sky) in midground."""
	var mid_y = level_height * 0.5
	var mid_h = level_height * 0.55
	var mid_left = offset.x - 300
	var mid_w = level_width + 800
	if theme_name == "grass":
		# Calm blue water with slight gradient
		var water_top = Color8(70, 140, 200, 140)
		var water_bot = Color8(50, 110, 170, 160)
		for i in range(int(mid_h / 12) + 1):
			var t = float(i) / maxf(mid_h / 12, 1)
			var band_col = water_top.lerp(water_bot, t)
			draw_rect(Rect2(mid_left, mid_y + i * 12, mid_w, 14), band_col)
		# Subtle wave highlights
		for i in range(int(mid_w / 120) + 2):
			var wx = mid_left + i * 120.0 + fmod(time * 15, 120)
			var wy = mid_y + 8.0 + sin(time * 2.0 + i * 0.5) * 4
			draw_rect(Rect2(wx, wy, 60, 3), Color(1, 1, 1, 0.08))
	elif theme_name == "sky":
		# Cloud sea / soft gradient void
		for i in range(int(mid_h / 16) + 1):
			var t = float(i) / maxf(mid_h / 16, 1)
			var band_col = Color(pal[4].r, pal[4].g, pal[4].b, 0.15 * (1.0 - t * 0.5))
			draw_rect(Rect2(mid_left, mid_y + i * 16, mid_w, 18), band_col)

func _draw_depth_fog(offset: Vector2, intensity: float):
	"""Draw atmospheric depth fog with theme-appropriate color."""
	# Get fog color based on theme
	var fog_color: Color
	match theme_name:
		"cave":
			fog_color = Color(0.08, 0.06, 0.12, 1.0)  # Dark purple haze
		"lava":
			fog_color = Color(0.25, 0.08, 0.04, 1.0)  # Dark red smoke
		"sky":
			fog_color = Color(0.85, 0.90, 1.0, 1.0)  # Bright blue-white
		"summit", "ice":
			fog_color = Color(0.92, 0.95, 1.0, 1.0)  # Cool white mist
		_:  # grass and default
			fog_color = Color(0.88, 0.92, 0.96, 1.0)  # Soft blue-white

	# Draw fog as gradient bands across the screen
	var band_count = 8
	for i in range(band_count):
		var t = float(i) / float(band_count)
		var y = level_height * (0.3 + t * 0.5)
		var alpha = intensity * (1.0 - t * 0.7)  # Stronger at horizon, fades toward bottom
		var band_col = Color(fog_color.r, fog_color.g, fog_color.b, alpha * 0.15)
		draw_rect(Rect2(offset.x - 500, y, level_width + 2000, level_height * 0.08), band_col)
