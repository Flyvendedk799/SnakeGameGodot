extends Node2D

# Constants
var SCREEN_WIDTH = 750
var SCREEN_HEIGHT = 525
const GRID_SIZE = 20
const TICK_RATE = 8.0

# Colors
var BG_COLOR = Color8(135, 206, 235)
var GRID_COLOR = Color8(100, 180, 220)
var BODY_COLOR = Color8(34, 177, 76)
var BODY_DARK = Color8(10, 60, 30)
var FOOD_COLOR = Color8(255, 100, 100)
var FOOD_DARK = Color8(200, 50, 50)
var FOOD_GLOW_COLOR = Color8(255, 180, 80)
var FOOD_SHINE = Color8(255, 220, 150)
var HUD_GOLD = Color8(255, 200, 0)
var HUD_CYAN = Color8(0, 255, 255)

# State machine
enum GameState { TITLE, COUNTDOWN, PLAYING, PAUSED, DYING, GAME_OVER }
var state: GameState = GameState.TITLE

# Game state
var snake = []
var direction = Vector2i.RIGHT
var next_direction = Vector2i.RIGHT
var food_pos = Vector2i.ZERO
var score = 0
var speed = 1.0

# Timing
var tick_accumulator = 0.0
var last_snake_positions = []
var interpolation_factor = 0.0

# Particles and sprites
var particle_system: ParticleSystem
var head_sprite: Texture2D
var map_sprite: Texture2D
var coin_sprite: Texture2D
var gameover_sprite: Texture2D
var glow_intensity = 8.0
var time_elapsed = 0.0

# Screen shake
var shake_intensity = 0.0
var shake_timer = 0.0
var shake_offset = Vector2.ZERO

# Floating score popups
var popups = []

# Countdown state
var countdown_timer = 0.0
var countdown_number = 3
var last_countdown_number = -1

# Death sequence state
var death_timer = 0.0
var death_flash_alpha = 0.0

# Title state
var title_pulse = 0.0

# High score
var high_score = 0

# SFX
var sfx: SfxPlayer

const HIGHSCORE_PATH = "user://highscore.save"

func _ready():
	SCREEN_WIDTH = int(get_viewport_rect().size.x)
	SCREEN_HEIGHT = int(get_viewport_rect().size.y)
	head_sprite = load("res://assets/WilliamHead.png")
	map_sprite = load("res://assets/Map1.png")
	coin_sprite = load("res://assets/CoinModel.png")
	gameover_sprite = load("res://assets/Gameover.png")
	particle_system = ParticleSystem.new()
	sfx = SfxPlayer.new()
	add_child(sfx)
	_load_high_score()
	reset_game()

func reset_game():
	var grid_w = SCREEN_WIDTH / GRID_SIZE
	var grid_h = SCREEN_HEIGHT / GRID_SIZE

	snake = [
		Vector2i(grid_w / 3 - 3, grid_h / 2),
		Vector2i(grid_w / 3 - 2, grid_h / 2),
		Vector2i(grid_w / 3 - 1, grid_h / 2),
		Vector2i(grid_w / 3, grid_h / 2),
	]

	direction = Vector2i.RIGHT
	next_direction = Vector2i.RIGHT
	food_pos = spawn_food()
	score = 0
	speed = 1.0
	tick_accumulator = 0.0
	last_snake_positions = []
	interpolation_factor = 0.0
	time_elapsed = 0.0
	glow_intensity = 8.0
	shake_intensity = 0.0
	shake_timer = 0.0
	shake_offset = Vector2.ZERO
	position = Vector2.ZERO
	popups.clear()
	particle_system.clear()
	death_timer = 0.0
	death_flash_alpha = 0.0

func spawn_food():
	var grid_w = SCREEN_WIDTH / GRID_SIZE
	var grid_h = SCREEN_HEIGHT / GRID_SIZE

	for _i in range(100):
		var pos = Vector2i(
			randi() % (grid_w - 4) + 2,
			randi() % (grid_h - 4) + 2
		)
		if pos not in snake:
			return pos

	return Vector2i(grid_w / 2, grid_h / 2)

func start_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_timer = duration

# --- High score persistence ---

func _load_high_score():
	if FileAccess.file_exists(HIGHSCORE_PATH):
		var f = FileAccess.open(HIGHSCORE_PATH, FileAccess.READ)
		if f:
			high_score = f.get_32()
			f.close()

func _save_high_score():
	var f = FileAccess.open(HIGHSCORE_PATH, FileAccess.WRITE)
	if f:
		f.store_32(high_score)
		f.close()

# --- Input ---

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		match state:
			GameState.TITLE:
				get_tree().quit()
			GameState.PLAYING:
				state = GameState.PAUSED
				sfx.play_pause()
			GameState.PAUSED:
				state = GameState.PLAYING
				sfx.play_pause()
			GameState.GAME_OVER:
				get_tree().quit()

	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if state == GameState.PLAYING:
			state = GameState.PAUSED
			sfx.play_pause()
		elif state == GameState.PAUSED:
			state = GameState.PLAYING
			sfx.play_pause()

# --- Process dispatcher ---

func _process(delta: float):
	# Always update shake
	if shake_timer > 0:
		shake_timer -= delta
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		position = shake_offset
	elif position != Vector2.ZERO:
		position = Vector2.ZERO
		shake_offset = Vector2.ZERO

	# Always update popups
	var active_popups = []
	for popup in popups:
		popup.timer -= delta
		popup.pos.y -= 60.0 * delta
		if popup.timer > 0:
			active_popups.append(popup)
	popups = active_popups

	# Always tick time for animations
	time_elapsed += delta
	glow_intensity = 8.0 + sin(time_elapsed * TAU * 0.12) * 3.0

	match state:
		GameState.TITLE:
			_process_title(delta)
		GameState.COUNTDOWN:
			_process_countdown(delta)
		GameState.PLAYING:
			_process_playing(delta)
		GameState.PAUSED:
			pass
		GameState.DYING:
			_process_dying(delta)
		GameState.GAME_OVER:
			_process_game_over(delta)

	queue_redraw()

func _process_title(delta: float):
	title_pulse += delta

func _process_countdown(delta: float):
	# Allow direction pre-selection during countdown
	if Input.is_action_just_pressed("ui_up") and direction.y == 0:
		next_direction = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down") and direction.y == 0:
		next_direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left") and direction.x == 0:
		next_direction = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right") and direction.x == 0:
		next_direction = Vector2i.RIGHT

	countdown_timer -= delta

	# Determine current number: 3, 2, 1, GO(0)
	var new_number: int
	if countdown_timer > 2.4:
		new_number = 3
	elif countdown_timer > 1.6:
		new_number = 2
	elif countdown_timer > 0.8:
		new_number = 1
	elif countdown_timer > 0.0:
		new_number = 0  # GO!
	else:
		state = GameState.PLAYING
		return

	# Play SFX on number change
	if new_number != last_countdown_number:
		last_countdown_number = new_number
		if new_number > 0:
			sfx.play_countdown_tick()
		else:
			sfx.play_countdown_go()

	countdown_number = new_number

func _process_playing(delta: float):
	# Input
	if Input.is_action_just_pressed("ui_up") and direction.y == 0:
		next_direction = Vector2i.UP
	elif Input.is_action_just_pressed("ui_down") and direction.y == 0:
		next_direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("ui_left") and direction.x == 0:
		next_direction = Vector2i.LEFT
	elif Input.is_action_just_pressed("ui_right") and direction.x == 0:
		next_direction = Vector2i.RIGHT

	particle_system.update(delta)

	# Smooth movement
	tick_accumulator += delta * TICK_RATE * speed
	interpolation_factor = fmod(tick_accumulator, 1.0)

	# Move snake
	if tick_accumulator >= 1.0:
		last_snake_positions = snake.duplicate()
		direction = next_direction

		var head = snake[-1]
		var new_head = head + direction

		var grid_w = SCREEN_WIDTH / GRID_SIZE
		var grid_h = SCREEN_HEIGHT / GRID_SIZE

		new_head.x = posmod(new_head.x, grid_w)
		new_head.y = posmod(new_head.y, grid_h)

		# Self collision → enter DYING state
		if new_head in snake.slice(0, -1):
			_enter_dying()
			return

		snake.append(new_head)

		# Food collision
		if new_head == food_pos:
			score += 1
			var px = float(food_pos.x * GRID_SIZE + GRID_SIZE / 2)
			var py = float(food_pos.y * GRID_SIZE + GRID_SIZE / 2)
			particle_system.emit_burst(px, py, FOOD_GLOW_COLOR, 15)
			start_shake(3.0, 0.1)
			sfx.play_eat()

			popups.append({
				"pos": Vector2(px, py - 10.0),
				"timer": 0.8,
				"text": "+1"
			})

			food_pos = spawn_food()
			speed = min(speed + 0.05, 2.5)
			if last_snake_positions.size() > 0:
				last_snake_positions.push_front(last_snake_positions[0])
		else:
			snake.pop_front()

		tick_accumulator -= 1.0

func _enter_dying():
	state = GameState.DYING
	death_timer = 1.2
	death_flash_alpha = 1.0

	var head = snake[-1]
	var px = float(head.x * GRID_SIZE + GRID_SIZE / 2)
	var py = float(head.y * GRID_SIZE + GRID_SIZE / 2)

	# Double particle burst: red + gold
	particle_system.emit_burst(px, py, FOOD_COLOR, 20)
	particle_system.emit_burst(px, py, HUD_GOLD, 20)
	start_shake(10.0, 0.5)
	sfx.play_death()

func _process_dying(delta: float):
	particle_system.update(delta)
	death_timer -= delta

	# Flash fades over 0.33s
	death_flash_alpha = maxf(0.0, death_flash_alpha - delta / 0.33)

	if death_timer <= 0.0:
		# Check high score
		if score > high_score:
			high_score = score
			_save_high_score()
		state = GameState.GAME_OVER

func _process_game_over(_delta: float):
	if Input.is_action_just_pressed("ui_accept"):
		sfx.play_start()
		reset_game()
		_start_countdown()

func _start_countdown():
	state = GameState.COUNTDOWN
	countdown_timer = 3.2  # 0.8*3 + 0.8 for GO
	countdown_number = 3
	last_countdown_number = -1

# --- Draw ---

func _draw():
	_draw_background()
	_draw_food()
	_draw_snake()
	particle_system.draw(self)
	_draw_popups()
	_draw_hud()

	match state:
		GameState.TITLE:
			_draw_title()
		GameState.COUNTDOWN:
			_draw_countdown()
		GameState.PAUSED:
			_draw_paused()
		GameState.DYING:
			_draw_dying()
		GameState.GAME_OVER:
			_draw_game_over()

func _draw_background():
	if map_sprite != null:
		draw_texture_rect(map_sprite, Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), false)
	else:
		draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), BG_COLOR)

func _draw_food():
	var fcx = float(food_pos.x * GRID_SIZE + GRID_SIZE / 2)
	var fcy = float(food_pos.y * GRID_SIZE + GRID_SIZE / 2)
	var food_bob = sin(time_elapsed * 3.0) * 3.0
	var food_center = Vector2(fcx, fcy + food_bob)

	# Glow effect
	var glow_rad = int(glow_intensity * 2.0)
	for gi in range(glow_rad, 0, -3):
		var alpha = (1.0 - float(gi) / float(glow_rad)) * 0.4
		var glow_col = Color(FOOD_GLOW_COLOR.r, FOOD_GLOW_COLOR.g, FOOD_GLOW_COLOR.b, alpha)
		draw_circle(food_center, float(gi), glow_col)

	# Coin sprite
	if coin_sprite != null:
		var coin_size = float(GRID_SIZE * 3)
		var coin_dest = Rect2(
			food_center.x - coin_size / 2.0,
			food_center.y - coin_size / 2.0,
			coin_size, coin_size
		)
		draw_texture_rect(coin_sprite, coin_dest, false)
	else:
		draw_circle(food_center, 9.0, FOOD_COLOR)
		draw_circle(food_center, 9.0, FOOD_DARK, false, 2.0)
		draw_circle(food_center - Vector2(3, 3), 2.0, FOOD_SHINE)

func _draw_snake():
	for i in range(snake.size()):
		var is_head = (i == snake.size() - 1)
		var pos: Vector2

		if last_snake_positions.size() > i:
			var old_x = float(last_snake_positions[i].x)
			var old_y = float(last_snake_positions[i].y)
			var new_x = float(snake[i].x)
			var new_y = float(snake[i].y)

			var grid_w = float(SCREEN_WIDTH / GRID_SIZE)
			var grid_h = float(SCREEN_HEIGHT / GRID_SIZE)

			if abs(new_x - old_x) > grid_w / 2.0:
				if new_x > old_x:
					old_x += grid_w
				else:
					old_x -= grid_w
			if abs(new_y - old_y) > grid_h / 2.0:
				if new_y > old_y:
					old_y += grid_h
				else:
					old_y -= grid_h

			var ix = lerpf(old_x, new_x, interpolation_factor) * GRID_SIZE
			var iy = lerpf(old_y, new_y, interpolation_factor) * GRID_SIZE
			pos = Vector2(ix, iy)
		else:
			pos = Vector2(float(snake[i].x * GRID_SIZE), float(snake[i].y * GRID_SIZE))

		if is_head:
			var center = pos + Vector2(GRID_SIZE / 2.0, GRID_SIZE / 2.0)
			if head_sprite != null:
				var spr_size = float(GRID_SIZE * 5)
				var dest = Rect2(center.x - spr_size / 2.0, center.y - spr_size / 2.0, spr_size, spr_size)
				draw_texture_rect(head_sprite, dest, false)
			else:
				draw_circle(center, 8.0, HUD_CYAN)
		else:
			var rect = Rect2(pos, Vector2(GRID_SIZE, GRID_SIZE))
			draw_rect(rect, BODY_COLOR)
			draw_rect(rect, BODY_DARK, false, 3.0)

func _draw_popups():
	var font = ThemeDB.fallback_font
	for popup in popups:
		var alpha = clampf(popup.timer / 0.8, 0.0, 1.0)
		var popup_color = Color(HUD_GOLD.r, HUD_GOLD.g, HUD_GOLD.b, alpha)
		draw_string(font, popup.pos, popup.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, popup_color)

func _draw_hud():
	var font = ThemeDB.fallback_font
	if state == GameState.PLAYING or state == GameState.PAUSED or state == GameState.DYING:
		draw_string(font, Vector2(20, 30), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, HUD_GOLD)
		draw_string(font, Vector2(20, 60), "Speed: %.1f" % speed, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, HUD_CYAN)
		if high_score > 0:
			draw_string(font, Vector2(SCREEN_WIDTH - 150, 30), "Best: %d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, HUD_GOLD)

# --- State overlays ---

func _draw_title():
	var font = ThemeDB.fallback_font
	# Dark overlay
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0, 0, 0, 0.65))

	var cx = SCREEN_WIDTH / 2.0
	var cy = SCREEN_HEIGHT / 2.0

	# Title
	draw_string(font, Vector2(cx - 170, cy - 60), "SNAKE GAME", HORIZONTAL_ALIGNMENT_LEFT, -1, 64, HUD_GOLD)

	# Pulsing start prompt
	var pulse_alpha = 0.5 + 0.5 * sin(title_pulse * 3.0)
	var start_color = Color(HUD_CYAN.r, HUD_CYAN.g, HUD_CYAN.b, pulse_alpha)
	draw_string(font, Vector2(cx - 140, cy + 20), "Press SPACE to Start", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, start_color)

	# High score
	if high_score > 0:
		draw_string(font, Vector2(cx - 80, cy + 70), "Best: %d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, HUD_GOLD)

	# Quit hint
	draw_string(font, Vector2(cx - 60, SCREEN_HEIGHT - 30), "ESC to quit", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))

	# Listen for SPACE
	if Input.is_action_just_pressed("ui_accept"):
		sfx.play_start()
		reset_game()
		_start_countdown()

func _draw_countdown():
	var font = ThemeDB.fallback_font
	# Semi-transparent overlay
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0, 0, 0, 0.3))

	var cx = SCREEN_WIDTH / 2.0
	var cy = SCREEN_HEIGHT / 2.0

	var text: String
	var color: Color
	if countdown_number > 0:
		text = str(countdown_number)
		color = HUD_CYAN
	else:
		text = "GO!"
		color = HUD_GOLD

	# Scale/fade animation within each number's time slot
	var slot_progress: float
	if countdown_number == 3:
		slot_progress = 1.0 - (countdown_timer - 2.4) / 0.8
	elif countdown_number == 2:
		slot_progress = 1.0 - (countdown_timer - 1.6) / 0.8
	elif countdown_number == 1:
		slot_progress = 1.0 - (countdown_timer - 0.8) / 0.8
	else:
		slot_progress = 1.0 - countdown_timer / 0.8

	slot_progress = clampf(slot_progress, 0.0, 1.0)
	var alpha = 1.0 - slot_progress * 0.6
	var font_size = int(lerpf(80.0, 60.0, slot_progress))

	var draw_color = Color(color.r, color.g, color.b, alpha)
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(cx - text_width / 2.0, cy + font_size / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, draw_color)

func _draw_paused():
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0, 0, 0, 0.6))

	var cx = SCREEN_WIDTH / 2.0
	var cy = SCREEN_HEIGHT / 2.0

	draw_string(font, Vector2(cx - 100, cy - 20), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, HUD_GOLD)
	draw_string(font, Vector2(cx - 120, cy + 30), "P or ESC to resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, HUD_CYAN)

func _draw_dying():
	var font = ThemeDB.fallback_font
	# White flash
	if death_flash_alpha > 0.0:
		draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(1, 1, 1, death_flash_alpha * 0.8))

	# Gradual darkening
	var dark_progress = 1.0 - (death_timer / 1.2)
	dark_progress = clampf(dark_progress, 0.0, 1.0)
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0, 0, 0, dark_progress * 0.5))

	# Still show HUD (drawn by _draw_hud already)

func _draw_game_over():
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0, 0, 0, 0.7))

	var cx = SCREEN_WIDTH / 2.0
	var cy = SCREEN_HEIGHT / 2.0

	# Game Over sprite
	if gameover_sprite != null:
		var spr_w = gameover_sprite.get_width()
		var spr_h = gameover_sprite.get_height()
		var scale_factor = 250.0 / spr_w
		var draw_w = spr_w * scale_factor
		var draw_h = spr_h * scale_factor
		draw_texture_rect(gameover_sprite, Rect2(cx - draw_w / 2.0, cy - 120 - draw_h / 2.0, draw_w, draw_h), false)
	else:
		draw_string(font, Vector2(cx - 150, cy - 80), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 60, HUD_GOLD)

	draw_string(font, Vector2(cx - 80, cy - 20), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, HUD_CYAN)

	# High score display
	if score >= high_score and score > 0:
		var pulse = 0.7 + 0.3 * sin(time_elapsed * 5.0)
		var hs_color = Color(HUD_GOLD.r, HUD_GOLD.g, HUD_GOLD.b, pulse)
		draw_string(font, Vector2(cx - 130, cy + 30), "NEW HIGH SCORE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, hs_color)
	elif high_score > 0:
		draw_string(font, Vector2(cx - 70, cy + 30), "Best: %d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, HUD_GOLD)

	draw_string(font, Vector2(cx - 160, SCREEN_HEIGHT - 60), "SPACE to restart / ESC to quit", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, HUD_CYAN)
