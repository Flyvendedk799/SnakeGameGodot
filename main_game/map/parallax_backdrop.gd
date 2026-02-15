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
	var count = 8 + int(level_width / 400)
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
		queue_redraw()

func _draw():
	if game == null or game.game_camera == null:
		return
	var cam_pos = game.game_camera.position
	var pal = THEMES.get(theme_name, THEMES["grass"])

	# Sky gradient (vertical bands)
	var offset0 = -cam_pos * 0.9
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

	# Distant mountains/silhouettes (parallax ~0.3)
	var offset1 = -cam_pos * 0.3
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

	# Mid-ground hills (parallax ~0.5)
	var offset2 = -cam_pos * 0.5
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

	# Near hills (parallax ~0.7)
	var offset3 = -cam_pos * 0.7
	for i in range(int(level_width / 45) + 10):
		var bx = offset3.x + i * 45.0 + fmod(cam_pos.x * 0.1, 45)
		var by = level_height - hill_h * (0.28 + 0.32 * sin(i * 0.4 + 2))
		draw_rect(Rect2(bx, by, 65, hill_h + 25), pal[5])

	# Foreground foliage/props (parallax ~0.9)
	var offset4 = -cam_pos * 0.9
	for i in range(int(level_width / 100) + 5):
		var fx = offset4.x + i * 100.0 + fmod(cam_pos.x * 0.15, 100)
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
