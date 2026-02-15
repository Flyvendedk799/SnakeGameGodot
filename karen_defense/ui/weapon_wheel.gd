class_name WeaponWheel
extends RefCounted

# Categories in the wheel
const CATEGORIES = ["melee", "ranged", "throwable"]
const CATEGORY_LABELS = ["SWORD", "GUN", "GRENADE"]
const CATEGORY_ICONS = ["S", "R", "G"]  # Simple letter icons
const CATEGORY_COLORS = [
	Color8(220, 160, 80),    # melee: warm gold
	Color8(80, 180, 240),    # ranged: cool blue
	Color8(240, 140, 60),    # throwable: orange
]

# State
var is_open: bool = false
var open_timer: float = 0.0  # Animation progress 0..1
var selected_index: int = 0  # Which category is highlighted
var previous_mode: String = "melee"
var confirm_flash: float = 0.0
var wobble_time: float = 0.0

# Quick-tap vs hold detection
var hold_timer: float = 0.0  # How long button has been held
const QUICK_TAP_THRESHOLD = 0.18  # Under this = quick tap, over = hold to open wheel
var was_quick_tap: bool = false
var last_weapon_mode: String = "melee"  # The previous weapon before current one
var ranged_options: Array[String] = ["ak47"]
var selected_ranged_index: int = 0
var ranged_cycle_cooldown: float = 0.0

# Bubble animation
const OPEN_SPEED = 8.0
const CLOSE_SPEED = 10.0
const BUBBLE_RADIUS = 75.0
const SEGMENT_GAP = 0.06  # Gap between segments in radians

func open(current_mode: String, owned_ranged: Array[String] = ["ak47"], equipped_ranged: String = "ak47"):
	if is_open:
		return
	is_open = true
	hold_timer = 0.0
	was_quick_tap = false
	ranged_cycle_cooldown = 0.0
	previous_mode = current_mode
	ranged_options = owned_ranged.duplicate()
	if ranged_options.is_empty():
		ranged_options = ["ak47"]
	selected_ranged_index = maxi(0, ranged_options.find(equipped_ranged))
	# Pre-select current category
	for i in range(CATEGORIES.size()):
		if CATEGORIES[i] == current_mode:
			selected_index = i
			break

func close() -> Dictionary:
	"""Close the wheel and return selected mode + sub-selection."""
	is_open = false
	confirm_flash = 0.4
	return {"mode": CATEGORIES[selected_index], "ranged_weapon": ranged_options[selected_ranged_index]}

func quick_swap(current_mode: String) -> String:
	"""Quick tap: swap to the last used weapon mode."""
	confirm_flash = 0.3
	var swap_to = last_weapon_mode if last_weapon_mode != current_mode else "melee"
	return swap_to

func track_weapon_change(old_mode: String, new_mode: String):
	"""Track weapon switches for quick-swap history."""
	if old_mode != new_mode:
		last_weapon_mode = old_mode

func update(delta: float, aim_x: float, aim_y: float):
	wobble_time += delta
	# Track hold duration when open
	if is_open:
		hold_timer += delta
	ranged_cycle_cooldown = maxf(0.0, ranged_cycle_cooldown - delta)
	# Animate open/close
	if is_open:
		open_timer = minf(open_timer + delta * OPEN_SPEED, 1.0)
	else:
		open_timer = maxf(open_timer - delta * CLOSE_SPEED, 0.0)
	confirm_flash = maxf(0.0, confirm_flash - delta)
	# Right stick selection while open (with better deadzone and sensitivity)
	if is_open and hold_timer > QUICK_TAP_THRESHOLD:
		var stick = Vector2(aim_x, aim_y)
		if stick.length() > 0.3:
			var angle = stick.angle()
			# Map angle to 3 segments:
			# Top (-90 deg) = melee, Right-ish = ranged, Bottom-left = throwable
			# Normalize to 0..TAU
			var norm_angle = fmod(angle + TAU, TAU)
			# Offset so melee is centered at top (-PI/2 = 4.71)
			var offset_angle = fmod(norm_angle + PI / 2.0, TAU)
			var seg = int(offset_angle / (TAU / 3.0))
			seg = clampi(seg, 0, 2)
			selected_index = seg
			if selected_index == 1 and abs(aim_y) > 0.45 and ranged_options.size() > 1 and ranged_cycle_cooldown <= 0:
				if aim_y < 0:
					selected_ranged_index = (selected_ranged_index + 1) % ranged_options.size()
				else:
					selected_ranged_index = (selected_ranged_index - 1 + ranged_options.size()) % ranged_options.size()
				ranged_cycle_cooldown = 0.18
		# Also allow mouse movement for P1 (delta from center)

func is_held_long_enough() -> bool:
	"""Returns true if the button was held long enough to open the full wheel."""
	return hold_timer >= QUICK_TAP_THRESHOLD

func get_visual_progress() -> float:
	"""Elastic ease-out for opening animation."""
	if open_timer <= 0:
		return 0.0
	if open_timer >= 1.0:
		return 1.0
	# Elastic overshoot
	var t = open_timer
	var p = 0.4
	return pow(2.0, -10.0 * t) * sin((t - p / 4.0) * TAU / p) + 1.0

func draw_wheel(canvas: CanvasItem, screen_pos: Vector2, player_has_grenades: bool):
	"""Draw the thought-bubble weapon wheel at screen_pos. Called from HUD."""
	if open_timer <= 0.01 and confirm_flash <= 0:
		return

	var progress = get_visual_progress()
	var scale = progress

	# --- THOUGHT BUBBLE TRAIL (small circles from player head to main bubble) ---
	var bubble_center = screen_pos + Vector2(0, -100) * scale
	if scale > 0.1:
		# Three trailing dots going from player to bubble
		var trail_dots = [
			{"pos": screen_pos + Vector2(3, -28) * scale, "r": 5.0 * scale},
			{"pos": screen_pos + Vector2(6, -50) * scale, "r": 9.0 * scale},
			{"pos": screen_pos + Vector2(3, -74) * scale, "r": 13.0 * scale},
		]
		for dot in trail_dots:
			# White fill with thick cartoony outline
			canvas.draw_circle(dot.pos, dot.r + 2.5, Color(0.12, 0.10, 0.18, 0.85 * scale))
			canvas.draw_circle(dot.pos, dot.r, Color(0.98, 0.97, 0.94, 0.92 * scale))

	# --- MAIN BUBBLE ---
	var main_r = BUBBLE_RADIUS * scale
	if main_r < 5.0:
		return

	# Wobble for cartoony feel
	var wobble = sin(wobble_time * 3.0) * 2.0 * scale
	bubble_center.x += wobble

	# Bubble shadow
	canvas.draw_circle(bubble_center + Vector2(3, 5) * scale, main_r + 5, Color(0.0, 0.0, 0.0, 0.3 * scale))
	# Bubble outline (thick cartoony)
	canvas.draw_circle(bubble_center, main_r + 5, Color(0.12, 0.10, 0.18, 0.9 * scale))
	# Bubble fill
	canvas.draw_circle(bubble_center, main_r, Color(0.97, 0.96, 0.93, 0.96 * scale))
	# Inner highlight
	canvas.draw_circle(bubble_center + Vector2(-main_r * 0.2, -main_r * 0.25), main_r * 0.35, Color(1.0, 1.0, 1.0, 0.35 * scale))

	# --- SEGMENTS (3 pie slices) ---
	var segment_angle = TAU / 3.0
	var start_offset = -PI / 2.0 - segment_angle / 2.0  # Center melee at top

	for i in range(3):
		var is_selected = (i == selected_index)
		var seg_start = start_offset + i * segment_angle + SEGMENT_GAP
		var seg_end = start_offset + (i + 1) * segment_angle - SEGMENT_GAP
		var seg_center_angle = (seg_start + seg_end) / 2.0
		var icon_dist = main_r * 0.50
		var icon_pos = bubble_center + Vector2.from_angle(seg_center_angle) * icon_dist

		# Selection highlight (filled wedge)
		if is_selected and is_open:
			var pulse = 0.85 + 0.15 * sin(wobble_time * 8.0)
			var cat_col = CATEGORY_COLORS[i]
			# Draw filled wedge highlight
			var wedge_pts = PackedVector2Array()
			wedge_pts.append(bubble_center)
			var wedge_segs = 8
			for ws in range(wedge_segs + 1):
				var wa = seg_start + (seg_end - seg_start) * float(ws) / float(wedge_segs)
				wedge_pts.append(bubble_center + Vector2.from_angle(wa) * (main_r * 0.92))
			canvas.draw_colored_polygon(wedge_pts, Color(cat_col.r, cat_col.g, cat_col.b, 0.25 * scale * pulse))

		# Draw segment divider lines
		var line_start = bubble_center + Vector2.from_angle(seg_start) * (main_r * 0.15)
		var line_end = bubble_center + Vector2.from_angle(seg_start) * (main_r * 0.88)
		canvas.draw_line(line_start, line_end, Color(0.45, 0.40, 0.50, 0.35 * scale), 1.5)

		# Category icon circle
		var icon_r = main_r * 0.22
		if is_selected:
			icon_r *= 1.2 + sin(wobble_time * 6.0) * 0.05

		var cat_col = CATEGORY_COLORS[i]
		var icon_alpha = 1.0 if is_selected else 0.5
		# Greyed out throwable if no grenades
		if i == 2 and not player_has_grenades:
			cat_col = Color8(100, 100, 100)
			icon_alpha = 0.25

		# Icon background with outline
		canvas.draw_circle(icon_pos, icon_r + 2.5, Color(0.12, 0.10, 0.18, icon_alpha * scale * 0.8))
		canvas.draw_circle(icon_pos, icon_r, Color(cat_col.r, cat_col.g, cat_col.b, icon_alpha * scale))
		# Inner bright core
		if is_selected:
			canvas.draw_circle(icon_pos, icon_r * 0.5, Color(1.0, 1.0, 1.0, 0.2 * scale))

		# Icon letter
		var font = ThemeDB.fallback_font
		var letter = CATEGORY_ICONS[i]
		var font_size = int(13 * scale) if not is_selected else int(16 * scale)
		var text_offset = Vector2(-font_size * 0.3, font_size * 0.35)
		var text_col = Color(1, 1, 1, icon_alpha * scale)
		if is_selected:
			text_col = Color.WHITE
		canvas.draw_string(font, icon_pos + text_offset, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)

		# Label below icon
		var label_pos = icon_pos + Vector2(-20 * scale, icon_r + 14 * scale)
		var label_size = int(9 * scale) if not is_selected else int(11 * scale)
		var label_col = Color(0.15, 0.12, 0.2, icon_alpha * scale) if is_selected else Color(0.4, 0.35, 0.45, 0.45 * scale)
		canvas.draw_string(font, label_pos, CATEGORY_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, label_col)

	if selected_index == 1 and not ranged_options.is_empty():
		var font = ThemeDB.fallback_font
		var selected_name = ranged_options[selected_ranged_index].replace("_", " ").to_upper()
		canvas.draw_string(font, bubble_center + Vector2(-main_r * 0.7, main_r * 0.62), selected_name, HORIZONTAL_ALIGNMENT_LEFT, main_r * 1.4, int(10 * scale), Color8(50, 70, 95, int(220 * scale)))
		if ranged_options.size() > 1:
			canvas.draw_string(font, bubble_center + Vector2(-main_r * 0.5, main_r * 0.8), "UP/DOWN: CYCLE", HORIZONTAL_ALIGNMENT_LEFT, main_r, int(8 * scale), Color8(80, 90, 110, int(180 * scale)))

	# --- CENTER DOT ---
	canvas.draw_circle(bubble_center, 4.0 * scale, Color(0.3, 0.25, 0.35, 0.4 * scale))

	# --- CONFIRM FLASH (on close) ---
	if confirm_flash > 0:
		var flash_alpha = confirm_flash / 0.4
		var flash_col = CATEGORY_COLORS[selected_index] if selected_index < 3 else Color.WHITE
		canvas.draw_circle(screen_pos + Vector2(0, -100), main_r * 1.1 * flash_alpha, Color(flash_col.r, flash_col.g, flash_col.b, flash_alpha * 0.25))
