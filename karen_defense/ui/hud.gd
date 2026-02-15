class_name HudDisplay
extends Node2D

var game = null
var tex_portrait: Texture2D = null
var tex_portrait_p2: Texture2D = null

# Animation state for UI polish
var anim_time: float = 0.0
var hp_display_p1: float = 1.0  # Smoothly animated HP ratio for P1
var hp_trail_p1: float = 1.0   # Trailing "damage chunk" for P1
var hp_display_p2: float = 1.0
var hp_trail_p2: float = 1.0
var prev_gold_p1: int = 0
var prev_gold_p2: int = 0
var gold_punch_p1: float = 0.0  # Scale punch timer for gold change
var gold_punch_p2: float = 0.0
var prev_crystals: int = 0
var crystal_punch: float = 0.0
var hint_reveal: float = 0.0  # 0..1 for hint bar slide-up

func _ready():
	tex_portrait = load("res://assets/WilliamHead.png")
	tex_portrait_p2 = load("res://assets/player2.png")

func setup(game_ref):
	game = game_ref

func _process(delta):
	if visible and game:
		anim_time += delta
		# Smooth HP bar animation
		var p = game.player_node
		var target_hp = float(p.current_hp) / float(maxf(p.max_hp, 1))
		hp_display_p1 = lerpf(hp_display_p1, target_hp, delta * 12.0)
		# Trail follows more slowly
		if hp_trail_p1 > hp_display_p1:
			hp_trail_p1 = lerpf(hp_trail_p1, hp_display_p1, delta * 3.0)
		else:
			hp_trail_p1 = hp_display_p1
		# P2 HP
		if game.p2_joined and game.player2_node:
			var p2 = game.player2_node
			var target_hp2 = float(p2.current_hp) / float(maxf(p2.max_hp, 1))
			hp_display_p2 = lerpf(hp_display_p2, target_hp2, delta * 12.0)
			if hp_trail_p2 > hp_display_p2:
				hp_trail_p2 = lerpf(hp_trail_p2, hp_display_p2, delta * 3.0)
			else:
				hp_trail_p2 = hp_display_p2
		# Gold change detection
		if game.economy.p1_gold != prev_gold_p1:
			gold_punch_p1 = 0.3
			prev_gold_p1 = game.economy.p1_gold
		if game.economy.p2_gold != prev_gold_p2:
			gold_punch_p2 = 0.3
			prev_gold_p2 = game.economy.p2_gold
		if game.economy.crystals != prev_crystals:
			crystal_punch = 0.3
			prev_crystals = game.economy.crystals
		gold_punch_p1 = maxf(0, gold_punch_p1 - delta)
		gold_punch_p2 = maxf(0, gold_punch_p2 - delta)
		crystal_punch = maxf(0, crystal_punch - delta)
		# Hint reveal
		if game.state == game.GameState.WAVE_ACTIVE and game.current_wave >= 1 and game.current_wave <= 3:
			hint_reveal = minf(hint_reveal + delta * 2.0, 1.0)
		else:
			hint_reveal = maxf(hint_reveal - delta * 3.0, 0.0)
		queue_redraw()

func _draw():
	if game == null or not visible:
		return
	var font = ThemeDB.fallback_font
	var viewport_size = get_viewport_rect().size
	var scale_x = viewport_size.x / 1280.0
	var scale_y = viewport_size.y / 720.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(scale_x, scale_y))

	# === TOP LEFT: HP panel ===
	_draw_hp_panel(font)

	# === TOP CENTER: Wave info ===
	_draw_wave_info(font)

	# === TOP RIGHT: Resources ===
	_draw_resources(font)

	# === P2 HP panel (top right, below resources) ===
	if game.p2_joined:
		_draw_p2_hp_panel(font)

	# === BOTTOM RIGHT: Allies count ===
	_draw_ally_info(font)

	# === Boss HP bar ===
	_draw_boss_hp(font)

	# === "Press to Join" / "Player 2 Joined!" prompt ===
	_draw_join_prompt(font)

	# === Helpful hints for first 3 waves ===
	_draw_hints(font)

	# === Weapon Wheel ===
	_draw_weapon_wheels()

	# === Minimap ===
	_draw_minimap()

	# === Contextual barrier repair hint ===
	_draw_barrier_hint(font)

	# === Door interaction hint ===
	_draw_door_hint(font)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# --- Rounded panel helper ---
func _draw_rounded_panel(rect: Rect2, bg_color: Color, border_color: Color, radius: float = 6.0):
	"""Draw a panel with simulated rounded corners and subtle gradient."""
	var r = rect
	# Main fill
	draw_rect(Rect2(r.position.x + radius, r.position.y, r.size.x - radius * 2, r.size.y), bg_color)
	draw_rect(Rect2(r.position.x, r.position.y + radius, r.size.x, r.size.y - radius * 2), bg_color)
	# Corner circles
	for corner in [
		Vector2(r.position.x + radius, r.position.y + radius),
		Vector2(r.position.x + r.size.x - radius, r.position.y + radius),
		Vector2(r.position.x + radius, r.position.y + r.size.y - radius),
		Vector2(r.position.x + r.size.x - radius, r.position.y + r.size.y - radius),
	]:
		draw_circle(corner, radius, bg_color)
	# Top gradient highlight
	var grad_h = minf(r.size.y * 0.3, 12.0)
	draw_rect(Rect2(r.position.x + radius, r.position.y, r.size.x - radius * 2, grad_h), Color(1, 1, 1, 0.04))
	# Border (approximated with larger rect outline)
	draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, r.size.y - 2), border_color, false, 1.5)

func _draw_hp_panel(font: Font):
	var px = 12.0
	var py = 10.0
	var portrait_size = 56.0
	var panel_w = 290.0

	# Rounded panel background
	_draw_rounded_panel(Rect2(px - 4, py - 4, panel_w, 78), Color8(0, 0, 0, 150), Color8(80, 70, 100, 120))

	# Portrait with subtle glow
	if tex_portrait:
		var tex_size = tex_portrait.get_size()
		var s = portrait_size / tex_size.y
		var portrait_x = px + 2
		var portrait_y = py + 2
		# Portrait border with subtle pulse
		var border_pulse = 0.8 + 0.2 * sin(anim_time * 2.0)
		draw_rect(Rect2(portrait_x - 2, portrait_y - 2, portrait_size + 4, portrait_size + 4), Color8(80, 70, int(100 * border_pulse)))
		draw_set_transform(Vector2(portrait_x, portrait_y), 0, Vector2(s, s))
		draw_texture(tex_portrait, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var p = game.player_node

	# Offset bars to the right of portrait
	var bar_x = px + portrait_size + 12
	var bar_w = panel_w - portrait_size - 24

	# HP label + bar with damage trail
	draw_string(font, Vector2(bar_x, py + 12), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(200, 200, 200))
	var hp_bar_x = bar_x + 24
	var hp_bar_w = bar_w - 24
	var bar_h = 16.0
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w, bar_h), Color8(60, 20, 20))
	# Damage trail (red chunk that fades behind actual HP)
	if hp_trail_p1 > hp_display_p1 + 0.01:
		draw_rect(Rect2(hp_bar_x, py, hp_bar_w * hp_trail_p1, bar_h), Color8(200, 60, 60, 180))
	# Actual HP bar
	var hp_color: Color
	if hp_display_p1 > 0.5:
		hp_color = Color8(50, 200, 60)
	elif hp_display_p1 > 0.25:
		hp_color = Color8(220, 180, 50)
	else:
		hp_color = Color8(220, 50, 50)
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w * hp_display_p1, bar_h), hp_color)
	# Top highlight on HP bar
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w * hp_display_p1, bar_h * 0.35), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w, bar_h), Color8(150, 140, 160, 120), false, 1.0)
	draw_string(font, Vector2(hp_bar_x + 4, py + 13), "%d / %d" % [p.current_hp, p.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# XP bar with shimmer effect
	var xp_y = py + 22
	draw_string(font, Vector2(bar_x, xp_y + 12), "XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(140, 180, 255))
	var xp_bar_w = hp_bar_w
	var progress = game.progression.xp_progress(0)
	draw_rect(Rect2(hp_bar_x, xp_y, xp_bar_w, 8), Color8(20, 20, 60))
	draw_rect(Rect2(hp_bar_x, xp_y, xp_bar_w * progress, 8), Color8(80, 140, 255))
	# Shimmer: moving bright spot across the XP bar
	if progress > 0.05:
		var shimmer_x = fmod(anim_time * 0.4, 1.0)
		var shimmer_pos = hp_bar_x + xp_bar_w * progress * shimmer_x
		var shimmer_w = 20.0
		if shimmer_pos + shimmer_w > hp_bar_x and shimmer_pos < hp_bar_x + xp_bar_w * progress:
			var clip_start = maxf(shimmer_pos, hp_bar_x)
			var clip_end = minf(shimmer_pos + shimmer_w, hp_bar_x + xp_bar_w * progress)
			draw_rect(Rect2(clip_start, xp_y, clip_end - clip_start, 8), Color(1, 1, 1, 0.2))

	# Level + Weapon mode (P1)
	draw_string(font, Vector2(bar_x, xp_y + 28), "Lv.%d" % game.progression.get_level(0), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color8(255, 230, 100))
	var mode = p.weapon_mode
	var mode_text = "SWORD"
	var mode_col = Color8(220, 160, 80)
	match mode:
		"ranged":
			mode_text = "GUN"
			mode_col = Color8(80, 180, 240)
		"throwable":
			mode_text = "GRENADE"
			mode_col = Color8(240, 140, 60)
	draw_string(font, Vector2(bar_x + 60, xp_y + 28), "[%s]" % mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, mode_col)
	# Grenade aiming indicator in HUD
	if p.weapon_mode == "throwable" and p.grenade_aiming:
		draw_string(font, Vector2(bar_x + 60, xp_y + 40), "AIMING...", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.7, 0.3, 0.6 + 0.3 * sin(anim_time * 6.0)))

	# Potions indicator
	if p.potion_count > 0:
		var pot_x = hp_bar_x + hp_bar_w + 6
		var pot_y = py + 2
		_draw_rounded_panel(Rect2(pot_x - 2, pot_y - 2, 30, 18), Color8(0, 80, 0, 180), Color8(80, 200, 80, 150), 4.0)
		draw_string(font, Vector2(pot_x, pot_y + 12), "%dHP" % p.potion_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(100, 255, 100))
		draw_string(font, Vector2(bar_x + 140, xp_y + 28), "[R/Y] Potion", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(100, 220, 100, 180))

func _draw_wave_info(font: Font):
	var cx = 640.0
	# Rounded panel
	_draw_rounded_panel(Rect2(cx - 100, 6, 200, 40), Color8(0, 0, 0, 150), Color8(80, 70, 100, 120))

	var max_waves = game.map.map_config.get("max_waves", 50)
	# Slight bounce when wave changes
	var wave_scale = 1.0
	if game.wave_announce_timer > 2.0:
		var bounce_t = (game.wave_announce_timer - 2.0) / 0.5
		wave_scale = 1.0 + 0.15 * sin(bounce_t * PI) * clampf(bounce_t, 0, 1)
	draw_set_transform(Vector2(cx, 26), 0, Vector2(wave_scale, wave_scale))
	draw_string(font, Vector2(-100, 4), "Wave %d / %d" % [game.current_wave, max_waves], HORIZONTAL_ALIGNMENT_CENTER, 200, 20, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var alive = game.enemy_container.get_child_count()
	if alive > 0 and game.state == game.GameState.WAVE_ACTIVE:
		# Pulsing enemy count when many enemies
		var count_alpha = 1.0
		if alive > 10:
			count_alpha = 0.8 + 0.2 * sin(anim_time * 4.0)
		draw_string(font, Vector2(cx - 60, 52), "Karens alive: %d" % alive, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1.0, 0.59, 0.67, count_alpha))

func _draw_resources(font: Font):
	var rx = 1060.0
	var ry = 6.0
	var panel_w = 320.0 if game.p2_joined else 220.0
	_draw_rounded_panel(Rect2(rx - 8, ry, panel_w, 50), Color8(0, 0, 0, 150), Color8(80, 70, 100, 120))

	# Gold with scale punch
	var gold_scale = 1.0 + gold_punch_p1 * 0.5
	draw_circle(Vector2(rx + 8, ry + 16), 8 * gold_scale, Color.GOLD)
	draw_string(font, Vector2(rx - 8, ry + 12), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(120, 90, 20))

	var gold_text_scale = 1.0 + gold_punch_p1 * 0.3
	draw_set_transform(Vector2(rx + 22, ry + 22), 0, Vector2(gold_text_scale, gold_text_scale))
	if game.p2_joined:
		var p2_scale = 1.0 + gold_punch_p2 * 0.3
		draw_string(font, Vector2(0, 0), "P1:%d  P2:%d" % [game.economy.p1_gold, game.economy.p2_gold], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GOLD)
	else:
		draw_string(font, Vector2(0, 0), "%d" % game.economy.p1_gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GOLD)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Crystals with punch
	var cry_x = rx + (panel_w - 100.0)
	var cry_scale = 1.0 + crystal_punch * 0.3
	var cry_pts = PackedVector2Array([
		Vector2(cry_x, ry + 8 + (1.0 - cry_scale) * 8),
		Vector2(cry_x + 7 * cry_scale, ry + 16),
		Vector2(cry_x, ry + 24 - (1.0 - cry_scale) * 8),
		Vector2(cry_x - 7 * cry_scale, ry + 16)
	])
	draw_colored_polygon(cry_pts, Color8(160, 100, 255))
	draw_string(font, Vector2(cry_x + 14, ry + 22), "%d" % game.economy.crystals, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(200, 150, 255))

func _draw_equipment_slots(font: Font):
	var ex = 12.0
	var ey = 656.0
	var slot_w = 48.0
	var slot_h = 48.0
	var names = ["Weapon", "Armor", "Shield", "Potion"]

	for i in range(4):
		var sx = ex + i * (slot_w + 6)
		_draw_rounded_panel(Rect2(sx, ey, slot_w, slot_h), Color8(30, 25, 40, 200), Color8(90, 75, 110), 4.0)
		draw_string(font, Vector2(sx + 3, ey + 14), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(140, 120, 170))

func _draw_ally_info(font: Font):
	var ax = 1100.0
	var ay = 660.0
	var count = game.unit_manager.get_normal_alive_count()
	var max_u = game.unit_manager.max_units
	_draw_rounded_panel(Rect2(ax - 4, ay - 4, 170, 48), Color8(0, 0, 0, 140), Color8(80, 70, 100, 80))
	draw_string(font, Vector2(ax, ay + 14), "Allies: %d / %d" % [count, max_u], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(120, 180, 255))
	draw_string(font, Vector2(ax, ay + 34), "Square: Regroup  Triangle: Repair", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(140, 140, 160))

func _draw_boss_hp(font: Font):
	for enemy in game.enemy_container.get_children():
		if enemy.is_boss:
			var bar_w = 500.0
			var bar_h = 16.0
			var bx = (1280 - bar_w) / 2.0
			var by = 58.0
			var hp_ratio = float(enemy.current_hp) / float(enemy.max_hp)
			_draw_rounded_panel(Rect2(bx - 4, by - 16, bar_w + 8, bar_h + 22), Color8(0, 0, 0, 190), Color8(180, 60, 60, 120))
			draw_string(font, Vector2(bx, by - 2), "FINAL BOSS KAREN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(255, 80, 80))
			draw_rect(Rect2(bx, by, bar_w, bar_h), Color8(60, 10, 20))
			draw_rect(Rect2(bx, by, bar_w * hp_ratio, bar_h), Color8(220, 30, 60))
			# Top highlight on boss HP
			draw_rect(Rect2(bx, by, bar_w * hp_ratio, bar_h * 0.35), Color(1, 1, 1, 0.1))
			# Pulsing glow when below 30%
			if hp_ratio < 0.3:
				var pulse = 0.3 + 0.3 * sin(anim_time * 6.0)
				draw_rect(Rect2(bx - 2, by - 2, bar_w + 4, bar_h + 4), Color(1.0, 0.2, 0.2, pulse), false, 2.0)
			draw_rect(Rect2(bx, by, bar_w, bar_h), Color8(255, 80, 80, 120), false, 1.0)
			var hp_text = "%d / %d" % [enemy.current_hp, enemy.max_hp]
			draw_string(font, Vector2(bx + 4, by + 13), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			break

func _draw_p2_hp_panel(font: Font):
	var px = 980.0
	var py = 62.0
	var portrait_size = 48.0
	var panel_w = 290.0

	_draw_rounded_panel(Rect2(px - 4, py - 4, panel_w, 68), Color8(0, 0, 0, 150), Color8(100, 70, 80, 120))

	# Portrait
	if tex_portrait_p2:
		var tex_size = tex_portrait_p2.get_size()
		var s = portrait_size / tex_size.y
		var portrait_x = px + 2
		var portrait_y = py + 2
		draw_rect(Rect2(portrait_x - 2, portrait_y - 2, portrait_size + 4, portrait_size + 4), Color8(100, 70, 80))
		draw_set_transform(Vector2(portrait_x, portrait_y), 0, Vector2(s, s))
		draw_texture(tex_portrait_p2, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var p2 = game.player2_node
	if p2 == null:
		return

	var bar_x = px + portrait_size + 12
	var bar_w = panel_w - portrait_size - 24

	# P2 label
	draw_string(font, Vector2(bar_x, py + 10), "P2", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(255, 150, 170))

	# HP bar with damage trail
	var hp_bar_x = bar_x + 24
	var hp_bar_w = bar_w - 24
	var bar_h = 14.0
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w, bar_h), Color8(60, 20, 20))
	# Damage trail
	if hp_trail_p2 > hp_display_p2 + 0.01:
		draw_rect(Rect2(hp_bar_x, py, hp_bar_w * hp_trail_p2, bar_h), Color8(200, 60, 60, 180))
	var hp_color: Color
	if hp_display_p2 > 0.5:
		hp_color = Color8(50, 200, 60)
	elif hp_display_p2 > 0.25:
		hp_color = Color8(220, 180, 50)
	else:
		hp_color = Color8(220, 50, 50)
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w * hp_display_p2, bar_h), hp_color)
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w * hp_display_p2, bar_h * 0.35), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(hp_bar_x, py, hp_bar_w, bar_h), Color8(150, 140, 160, 120), false, 1.0)
	draw_string(font, Vector2(hp_bar_x + 4, py + 12), "%d / %d" % [p2.current_hp, p2.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# P2 XP bar with shimmer
	var xp_y_p2 = py + 22
	var progress_p2 = game.progression.xp_progress(1)
	draw_rect(Rect2(hp_bar_x, xp_y_p2, hp_bar_w, 6), Color8(20, 20, 60))
	draw_rect(Rect2(hp_bar_x, xp_y_p2, hp_bar_w * progress_p2, 6), Color8(80, 140, 255))
	if progress_p2 > 0.05:
		var shimmer_x = fmod(anim_time * 0.4, 1.0)
		var shimmer_pos = hp_bar_x + hp_bar_w * progress_p2 * shimmer_x
		var shimmer_w = 16.0
		if shimmer_pos + shimmer_w > hp_bar_x and shimmer_pos < hp_bar_x + hp_bar_w * progress_p2:
			var clip_start = maxf(shimmer_pos, hp_bar_x)
			var clip_end = minf(shimmer_pos + shimmer_w, hp_bar_x + hp_bar_w * progress_p2)
			draw_rect(Rect2(clip_start, xp_y_p2, clip_end - clip_start, 6), Color(1, 1, 1, 0.2))
	draw_string(font, Vector2(bar_x, py + 28), "Lv.%d" % game.progression.get_level(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(255, 230, 100))

	# Weapon mode
	var mode = p2.weapon_mode
	var mode_text = "SWORD"
	var mode_col = Color8(220, 160, 80)
	match mode:
		"ranged":
			mode_text = "GUN"
			mode_col = Color8(80, 180, 240)
		"throwable":
			mode_text = "GRENADE"
			mode_col = Color8(240, 140, 60)
	draw_string(font, Vector2(bar_x + 50, py + 28), "[%s]" % mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, mode_col)

	if p2.is_dead:
		var dead_pulse = 0.6 + 0.4 * sin(anim_time * 5.0)
		draw_string(font, Vector2(bar_x + 60, py + 36), "DEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.31, 0.31, dead_pulse))

	# P2 Potions
	if p2.potion_count > 0:
		var pot_x = hp_bar_x + hp_bar_w + 6
		_draw_rounded_panel(Rect2(pot_x - 2, py - 2, 30, 16), Color8(0, 80, 0, 180), Color8(80, 200, 80, 150), 3.0)
		draw_string(font, Vector2(pot_x, py + 10), "%dHP" % p2.potion_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(100, 255, 100))

func _draw_join_prompt(font: Font):
	if game.p2_join_flash_timer > 0:
		var alpha = clampf(game.p2_join_flash_timer / 0.5, 0.0, 1.0)
		var scale = 1.0 + (1.0 - alpha) * 0.2  # Scale down as it fades
		draw_set_transform(Vector2(640, 675), 0, Vector2(scale, scale))
		draw_rect(Rect2(-200, -15, 400, 30), Color(0, 0.3, 0, 0.5 * alpha))
		draw_string(font, Vector2(-200, 7), "Player 2 Joined!", HORIZONTAL_ALIGNMENT_CENTER, 400, 18, Color(0.4, 1.0, 0.4, alpha))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	elif not game.p2_joined and game.state != game.GameState.TITLE and game.state != game.GameState.GAME_OVER:
		var join_alpha = 0.4 + 0.2 * sin(anim_time * 2.0)
		_draw_rounded_panel(Rect2(390, 690, 500, 24), Color(0, 0, 0, join_alpha), Color(0.5, 0.5, 0.6, join_alpha * 0.3), 4.0)
		draw_string(font, Vector2(390, 708), "Player 2: Press Cross on controller to join!", HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color(0.7, 0.7, 0.78, join_alpha + 0.3))

func _draw_hints(font: Font):
	if hint_reveal <= 0.01:
		return
	if game.current_wave < 1 or game.current_wave > 3:
		return
	if game.state != game.GameState.WAVE_ACTIVE:
		return

	var hint_text = ""
	match game.current_wave:
		1: hint_text = "Move: L Stick/WASD | Sprint: R1/Ctrl | Attack: R2/Space | Dash: X/Shift | Weapon Wheel: L1/Q (hold) | Quick Swap: L1/Q (tap)"
		2: hint_text = "Repair/Door: Triangle/F | Regroup: Square/G | Grapple: L3/C | Block: L2/V | Shop: Touchpad/Tab"
		3: hint_text = "Pause: Options/Esc | See Controls in Pause Menu! | Buy Heavy Revolver at shop!"

	# Slide-up animation
	var bar_w = 780.0
	var bar_x = (1280 - bar_w) / 2.0
	var bar_y_target = 640.0
	var bar_y = bar_y_target + (1.0 - hint_reveal) * 40.0  # Slides up from below
	var bar_alpha = hint_reveal

	_draw_rounded_panel(Rect2(bar_x, bar_y, bar_w, 28), Color(0, 0, 0, 0.55 * bar_alpha), Color(0.39, 0.7, 1.0, 0.15 * bar_alpha), 5.0)
	draw_string(font, Vector2(bar_x, bar_y + 19), hint_text, HORIZONTAL_ALIGNMENT_CENTER, int(bar_w), 11, Color(0.7, 0.86, 1.0, bar_alpha))

func _world_to_screen(world_pos: Vector2) -> Vector2:
	"""Convert world position to screen position accounting for camera zoom and position."""
	if game.game_camera == null:
		return world_pos
	var cam = game.game_camera
	var screen_center = Vector2(640.0, 360.0)
	return (world_pos - cam.position) * cam.zoom + screen_center

func _draw_weapon_wheels():
	if game == null:
		return
	var players = [game.player_node]
	if game.p2_joined and game.player2_node:
		players.append(game.player2_node)
	for p in players:
		if p.is_dead:
			continue
		var screen_pos = _world_to_screen(p.position)
		p.weapon_wheel.draw_wheel(self, screen_pos, p.has_grenades and p.grenade_count > 0)

func _draw_minimap():
	"""Draw a minimap in the bottom-left corner showing fort, player, and enemies."""
	if game == null or game.state == game.GameState.TITLE or game.state == game.GameState.WORLD_SELECT:
		return
	var map = game.map

	# Minimap dimensions and position (bottom-left)
	var mm_size = 160.0
	var mm_x = 12.0
	var mm_y = 720.0 - mm_size - 60.0
	var mm_padding = 4.0

	# Background panel
	draw_rect(Rect2(mm_x - mm_padding, mm_y - mm_padding, mm_size + mm_padding * 2, mm_size + mm_padding * 2), Color8(0, 0, 0, 180))
	draw_rect(Rect2(mm_x - mm_padding, mm_y - mm_padding, mm_size + mm_padding * 2, mm_size + mm_padding * 2), Color8(80, 70, 100, 120), false, 1.5)

	# Scale world coords to minimap
	var world_w = map.SCREEN_W
	var world_h = map.SCREEN_H
	var scale_x = mm_size / maxf(world_w, 1.0)
	var scale_y = mm_size / maxf(world_h, 1.0)
	# Use uniform scale to prevent distortion
	var mm_scale = minf(scale_x, scale_y)
	var offset_x = mm_x + (mm_size - world_w * mm_scale) / 2.0
	var offset_y = mm_y + (mm_size - world_h * mm_scale) / 2.0

	# Draw fort outline
	var fort_rect = Rect2(
		offset_x + map.FORT_LEFT * mm_scale,
		offset_y + map.FORT_TOP * mm_scale,
		(map.FORT_RIGHT - map.FORT_LEFT) * mm_scale,
		(map.FORT_BOTTOM - map.FORT_TOP) * mm_scale
	)
	draw_rect(fort_rect, Color8(85, 70, 50, 100))
	draw_rect(fort_rect, Color8(140, 115, 85, 180), false, 1.0)

	# Draw keep outline
	var keep_rect = Rect2(
		offset_x + map.keep_left * mm_scale,
		offset_y + map.keep_top * mm_scale,
		(map.keep_right - map.keep_left) * mm_scale,
		(map.keep_bottom - map.keep_top) * mm_scale
	)
	draw_rect(keep_rect, Color8(65, 55, 40, 100))
	draw_rect(keep_rect, Color8(130, 105, 80, 180), false, 1.0)

	# Draw maze ring
	var ring_rect = Rect2(
		offset_x + map.ring_left * mm_scale,
		offset_y + map.ring_top * mm_scale,
		(map.ring_right - map.ring_left) * mm_scale,
		(map.ring_bottom - map.ring_top) * mm_scale
	)
	draw_rect(ring_rect, Color8(110, 85, 60, 60), false, 1.0)

	# Draw entrance markers
	for ep in map.entrance_positions:
		var ex = offset_x + ep.x * mm_scale
		var ey = offset_y + ep.y * mm_scale
		draw_circle(Vector2(ex, ey), 2.5, Color8(200, 180, 150, 180))

	# Draw barricade status
	for b in map.barricades:
		var bx = offset_x + b.position.x * mm_scale
		var by = offset_y + b.position.y * mm_scale
		var b_col = Color8(80, 200, 80) if b.is_intact() else Color8(200, 80, 80, 120)
		draw_rect(Rect2(bx - 2, by - 1, 4, 2), b_col)

	# Draw enemies (red dots)
	for enemy in game.enemy_container.get_children():
		if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
			continue
		var ex = offset_x + enemy.position.x * mm_scale
		var ey = offset_y + enemy.position.y * mm_scale
		var dot_size = 1.5
		var dot_col = Color8(255, 60, 60, 200)
		if enemy.is_boss:
			dot_size = 3.5
			dot_col = Color8(255, 40, 40)
			# Pulsing boss marker
			dot_size += sin(anim_time * 4.0) * 1.0
		elif enemy.is_bomber:
			dot_col = Color8(255, 160, 50, 200)
		draw_circle(Vector2(ex, ey), dot_size, dot_col)

	# Draw allies (blue dots)
	for ally in game.ally_container.get_children():
		if ally.current_hp <= 0:
			continue
		var ax = offset_x + ally.position.x * mm_scale
		var ay = offset_y + ally.position.y * mm_scale
		draw_circle(Vector2(ax, ay), 1.5, Color8(80, 160, 255, 200))

	# Draw player (bright green, larger)
	if not game.player_node.is_dead:
		var px = offset_x + game.player_node.position.x * mm_scale
		var py = offset_y + game.player_node.position.y * mm_scale
		# Player direction indicator
		var facing = Vector2.from_angle(game.player_node.facing_angle)
		draw_line(Vector2(px, py), Vector2(px + facing.x * 5, py + facing.y * 5), Color8(150, 255, 150, 180), 1.0)
		draw_circle(Vector2(px, py), 3.0, Color8(80, 255, 80))
		draw_circle(Vector2(px, py), 3.0, Color8(200, 255, 200, 150), false, 1.0)

	# Draw P2 (cyan)
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		var px = offset_x + game.player2_node.position.x * mm_scale
		var py = offset_y + game.player2_node.position.y * mm_scale
		draw_circle(Vector2(px, py), 3.0, Color8(80, 200, 255))
		draw_circle(Vector2(px, py), 3.0, Color8(150, 230, 255, 150), false, 1.0)

	# Camera viewport rectangle
	if game.game_camera:
		var cam = game.game_camera
		var zoom = cam.zoom.x
		var vw = (1280.0 / zoom) * mm_scale
		var vh = (720.0 / zoom) * mm_scale
		var vx = offset_x + (cam.position.x - 640.0 / zoom) * mm_scale
		var vy = offset_y + (cam.position.y - 360.0 / zoom) * mm_scale
		draw_rect(Rect2(vx, vy, vw, vh), Color8(255, 255, 255, 40), false, 1.0)

	# Label
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(mm_x, mm_y - 6), "MINIMAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(160, 150, 180, 200))

func _draw_barrier_hint(font: Font):
	if game.current_wave < 1 or game.current_wave > 3:
		return
	if game.state != game.GameState.WAVE_ACTIVE:
		return
	var players_to_check = [game.player_node]
	if game.p2_joined and game.player2_node:
		players_to_check.append(game.player2_node)
	for p in players_to_check:
		if p.is_dead:
			continue
		var barricade = game.map.get_nearest_barricade_in_range(p.position, 80.0)
		if barricade and barricade.current_hp < barricade.max_hp:
			var hint_pos = _world_to_screen(p.position) + Vector2(-60, -50)
			_draw_rounded_panel(Rect2(hint_pos.x - 5, hint_pos.y - 14, 160, 20), Color(0, 0, 0, 0.6), Color(0.39, 0.86, 1.0, 0.2), 4.0)
			draw_string(font, Vector2(hint_pos.x, hint_pos.y), "Press F / RB to Repair!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(100, 220, 255))

func _draw_door_hint(font: Font):
	if game.state != game.GameState.WAVE_ACTIVE and game.state != game.GameState.BETWEEN_WAVES:
		return
	var players_to_check = [game.player_node]
	if game.p2_joined and game.player2_node:
		players_to_check.append(game.player2_node)
	for p in players_to_check:
		if p.is_dead:
			continue
		var door = game.map.get_nearest_door_in_range(p.position, 80.0)
		if door:
			var action_text = "Press F to %s Door" % ("Close" if door.is_open else "Open")
			var hint_pos = _world_to_screen(p.position) + Vector2(-70, -65)
			_draw_rounded_panel(Rect2(hint_pos.x - 5, hint_pos.y - 14, 190, 22), Color(0, 0, 0, 0.65), Color(1.0, 0.78, 0.39, 0.2), 4.0)
			var hint_col = Color8(255, 200, 100) if not door.is_open else Color8(100, 220, 100)
			draw_string(font, Vector2(hint_pos.x, hint_pos.y), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, hint_col)
			if door.reinforced and door.reinforcement_hp > 0:
				_draw_rounded_panel(Rect2(hint_pos.x - 5, hint_pos.y + 4, 190, 16), Color(0, 0, 0, 0.5), Color(0.31, 0.63, 1.0, 0.15), 3.0)
				draw_string(font, Vector2(hint_pos.x, hint_pos.y + 16), "Reinforced: %d/%d" % [door.reinforcement_hp, door.max_reinforcement_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(80, 160, 255))
