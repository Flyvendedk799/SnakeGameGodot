class_name ShopMenu
extends Node2D

var game = null
var active: bool = false
var current_tab: int = 0  # 0=Buildings, 1=Units, 2=Equipment
var hover_index: int = -1
var kb_index: int = 0
var kb_on_start: bool = false  # true when keyboard focus is on "Start Wave" button
var scroll_offset: int = 0
var mid_wave: bool = false
var shop_purchasing_player_index: int = 0  # 0=P1, 1=P2 (for Equipment tab; only when p2_joined)
var input_cooldown: float = 0.0  # Brief cooldown to prevent stick-drift tab switch on open
var last_mouse_pos: Vector2 = Vector2.ZERO  # Track mouse to avoid overriding controller nav
var using_controller: bool = false  # True when last input was from controller

# Animation
var open_anim: float = 0.0  # 0..1 opening animation
var tab_switch_anim: float = 0.0  # Brief flash on tab switch
var card_hover_pulse: float = 0.0  # Pulsing highlight on hovered card
var purchase_flash: float = 0.0  # Flash on successful purchase
var purchase_flash_pos: Vector2 = Vector2.ZERO

const TABS = ["Buildings", "Units", "Equipment"]
const TAB_ICONS = ["B", "U", "E"]
const TAB_COLORS = [
	Color8(100, 180, 120),   # Buildings: green
	Color8(100, 160, 240),   # Units: blue
	Color8(220, 160, 80),    # Equipment: gold
]
const MENU_X = 120.0
const MENU_Y = 50.0
const MENU_W = 1040.0
const MENU_H = 620.0

func setup(game_ref):
	game = game_ref

func show_menu(is_mid_wave: bool = false):
	active = true
	mid_wave = is_mid_wave
	current_tab = 0
	shop_purchasing_player_index = 0
	hover_index = -1
	kb_index = 0
	kb_on_start = false
	scroll_offset = 0
	open_anim = 0.0
	input_cooldown = 0.25
	last_mouse_pos = get_global_mouse_position()
	using_controller = false

func hide_menu():
	active = false
	queue_redraw()

func _process(delta):
	if not active:
		return
	if input_cooldown > 0:
		input_cooldown -= delta
	open_anim = minf(open_anim + delta * 5.0, 1.0)
	tab_switch_anim = maxf(0, tab_switch_anim - delta * 4.0)
	card_hover_pulse += delta
	purchase_flash = maxf(0, purchase_flash - delta * 3.0)
	_update_hover()
	queue_redraw()

func _update_hover():
	var mouse = get_global_mouse_position()
	if mouse.distance_to(last_mouse_pos) < 2.0:
		return
	last_mouse_pos = mouse
	using_controller = false
	var items = _get_current_items()
	for i in range(items.size()):
		var rect = _get_item_rect(i)
		if rect.has_point(mouse):
			kb_index = i
			kb_on_start = false
			break
	var start_rect = _get_start_button_rect()
	if start_rect.has_point(mouse):
		kb_on_start = true
	hover_index = kb_index if not kb_on_start else -1

func handle_input(event):
	if not active:
		return false
	# Mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse = event.position
		for i in range(TABS.size()):
			var tab_rect = _get_tab_rect(i)
			if tab_rect.has_point(mouse):
				_switch_tab(i)
				return true
		if game.p2_joined and current_tab == 2:
			var sel_w = 180.0
			var sel_x = MENU_X + MENU_W - sel_w - 30
			var p1_rect = Rect2(sel_x, MENU_Y + 10, 80, 28)
			var p2_rect = Rect2(sel_x + 90, MENU_Y + 10, 80, 28)
			if p1_rect.has_point(mouse):
				shop_purchasing_player_index = 0
				return true
			if p2_rect.has_point(mouse):
				shop_purchasing_player_index = 1
				return true
		if hover_index >= 0:
			_buy_item(hover_index)
			return true
		var start_rect = _get_start_button_rect()
		if start_rect.has_point(mouse):
			_activate_start_button()
			return true
	# ui_back: close shop (Circle / ESC during mid-wave)
	if event.is_action_pressed("ui_back") and mid_wave:
		hide_menu()
		game.resume_from_shop()
		return true
	# Skip stick-based nav during cooldown
	var is_stick_event = event is InputEventJoypadMotion
	if is_stick_event and input_cooldown > 0:
		return true
	var items = _get_current_items()
	# Player switch: 1/L1 = P1, 2/R1 = P2
	if game.p2_joined and current_tab == 2:
		if event.is_action_pressed("shop_select_p1"):
			shop_purchasing_player_index = 0
			return true
		if event.is_action_pressed("shop_select_p2"):
			shop_purchasing_player_index = 1
			return true
	# Tab switching
	if event.is_action_pressed("ui_nav_left"):
		_switch_tab(maxi(0, current_tab - 1))
		using_controller = true
		return true
	if event.is_action_pressed("ui_nav_right"):
		_switch_tab(mini(2, current_tab + 1))
		using_controller = true
		return true
	# Item navigation
	if event.is_action_pressed("ui_nav_up"):
		using_controller = true
		if kb_on_start:
			kb_on_start = false
			kb_index = maxi(0, items.size() - 1)
		elif kb_index > 0:
			kb_index -= 1
		hover_index = kb_index if not kb_on_start else -1
		return true
	if event.is_action_pressed("ui_nav_down"):
		using_controller = true
		if not kb_on_start:
			if kb_index < items.size() - 1:
				kb_index += 1
			else:
				kb_on_start = true
		hover_index = kb_index if not kb_on_start else -1
		return true
	# Number keys
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: _switch_tab(0); return true
		if event.keycode == KEY_2: _switch_tab(1); return true
		if event.keycode == KEY_3: _switch_tab(2); return true
	# Confirm
	if event.is_action_pressed("confirm"):
		if kb_on_start:
			_activate_start_button()
			return true
		elif kb_index >= 0:
			_buy_item(kb_index)
			return true
	return false

func _switch_tab(index: int):
	if current_tab != index:
		current_tab = index
		tab_switch_anim = 1.0
		kb_index = 0
		kb_on_start = false

func _activate_start_button():
	hide_menu()
	if mid_wave:
		game.resume_from_shop()
	else:
		game.start_wave()

func _buy_item(index: int):
	var pi = shop_purchasing_player_index if current_tab == 2 else 0
	var do_split = game.p2_joined and current_tab != 2
	var success = false
	match current_tab:
		0:
			var buildings = BuildingData.get_all_buildings()
			if index < buildings.size():
				var b = buildings[index]
				if game.building_manager.can_buy(b, pi, do_split):
					game.building_manager.buy_building(b, pi, do_split)
					success = true
				elif game.sfx:
					game.sfx.play_error()
		1:
			var types = UnitData.get_all_types()
			if index < types.size():
				var ut = types[index]
				if UnitData.is_placement_outside(ut):
					if game.unit_manager.can_hire_outside_ally(ut, pi, do_split):
						game.unit_manager.hire_outside_ally(ut, pi, do_split)
						success = true
					elif game.sfx:
						game.sfx.play_error()
				elif game.unit_manager.can_hire(ut, pi, do_split):
					game.unit_manager.hire_unit(ut, pi, do_split)
					success = true
				elif game.sfx:
					game.sfx.play_error()
		2:
			var equips = EquipmentData.get_all_equipment()
			if index < equips.size():
				var e = equips[index]
				var buying_player = _get_purchasing_player()
				var is_magnet_active = e.get("effects", {}).has("magnet") and buying_player.has_magnet
				if is_magnet_active:
					if game.sfx:
						game.sfx.play_error()
					return
				if buying_player.buy_equipment(e.id, game):
					success = true
				elif game.sfx:
					game.sfx.play_error()
	if success:
		var rect = _get_item_rect(index)
		purchase_flash = 1.0
		purchase_flash_pos = rect.position + rect.size / 2.0

func _get_current_items() -> Array:
	match current_tab:
		0: return BuildingData.get_all_buildings()
		1:
			var items: Array = []
			for t in UnitData.get_all_types():
				items.append(UnitData.get_stats(t))
			return items
		2: return EquipmentData.get_all_equipment()
	return []

func _get_item_rect(index: int) -> Rect2:
	var col = index % 3
	var row = index / 3
	var card_w = 310.0
	var card_h = 95.0
	var gap = 14.0
	var x = MENU_X + 24 + col * (card_w + gap)
	var y = MENU_Y + 100 + row * (card_h + gap) - scroll_offset
	return Rect2(x, y, card_w, card_h)

func _get_tab_rect(index: int) -> Rect2:
	var tab_w = 140.0
	var x = MENU_X + 24 + index * (tab_w + 10)
	return Rect2(x, MENU_Y + 50, tab_w, 36)

func _get_start_button_rect() -> Rect2:
	return Rect2(MENU_X + MENU_W - 240, MENU_Y + MENU_H - 60, 220, 46)

func _get_purchasing_player():
	if shop_purchasing_player_index == 1 and game.p2_joined and game.player2_node:
		return game.player2_node
	return game.player_node

# --- Drawing helpers ---

func _draw_pill(rect: Rect2, color: Color):
	"""Draw a pill/rounded rectangle shape."""
	var r = minf(rect.size.y / 2.0, 8.0)
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2), color)
	for corner in [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
		Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
		Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
	]:
		draw_circle(corner, r, color)

func _draw_card(rect: Rect2, bg_color: Color, border_color: Color, is_selected: bool, accent_color: Color = Color.WHITE):
	"""Draw a cartoony item card with shadow and highlight."""
	# Shadow
	_draw_pill(Rect2(rect.position.x + 3, rect.position.y + 3, rect.size.x, rect.size.y), Color(0, 0, 0, 0.3))
	# Main card
	_draw_pill(rect, bg_color)
	# Top highlight strip
	_draw_pill(Rect2(rect.position.x, rect.position.y, rect.size.x, 4), accent_color)
	# Border
	var bw = 2.5 if is_selected else 1.5
	draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2), border_color, false, bw)
	# Selection glow
	if is_selected:
		var pulse = 0.4 + 0.2 * sin(card_hover_pulse * 5.0)
		draw_rect(Rect2(rect.position.x - 2, rect.position.y - 2, rect.size.x + 4, rect.size.y + 4), Color(accent_color.r, accent_color.g, accent_color.b, pulse * 0.2), false, 2.0)

func _draw():
	if not active:
		return
	var font = ThemeDB.fallback_font
	var anim = _ease_out_back(open_anim)

	# Dark overlay (animated)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.65 * open_anim))

	# Menu panel with shadow (animated scale)
	var panel_scale = anim
	var px = MENU_X + MENU_W / 2.0 * (1.0 - panel_scale)
	var py = MENU_Y + MENU_H / 2.0 * (1.0 - panel_scale)
	var pw = MENU_W * panel_scale
	var ph = MENU_H * panel_scale
	if pw < 100:
		return

	# Panel shadow
	_draw_pill(Rect2(px + 6, py + 6, pw, ph), Color(0, 0, 0, 0.4))
	# Main panel
	_draw_pill(Rect2(px, py, pw, ph), Color8(28, 24, 40, 245))
	# Panel border
	draw_rect(Rect2(px + 2, py + 2, pw - 4, ph - 4), Color8(90, 75, 120, 180), false, 2.0)
	# Decorative inner glow at top
	draw_rect(Rect2(px + 8, py + 2, pw - 16, 3), Color(1, 1, 1, 0.06))

	if open_anim < 0.5:
		return

	# Title with personality
	var title_text = "THE CHILL ZONE"
	var subtitle = "Mid-Wave Shop" if mid_wave else "Between Waves"
	draw_string(font, Vector2(MENU_X + 28, MENU_Y + 36), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color8(230, 210, 255))
	draw_string(font, Vector2(MENU_X + 240, MENU_Y + 36), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color8(160, 150, 185))
	# Decorative line under title
	draw_line(Vector2(MENU_X + 24, MENU_Y + 44), Vector2(MENU_X + MENU_W - 24, MENU_Y + 44), Color8(70, 60, 100, 120), 1.0)

	# Player selector
	if game.p2_joined and current_tab == 2:
		_draw_player_selector(font, MENU_Y + 14)

	# Tabs with icons and color strips
	for i in range(TABS.size()):
		var tab_rect = _get_tab_rect(i)
		var is_active = i == current_tab
		var tab_bg = Color8(55, 48, 72) if is_active else Color8(36, 32, 48)
		var tab_col = TAB_COLORS[i]
		_draw_pill(tab_rect, tab_bg)
		# Active tab accent strip
		if is_active:
			_draw_pill(Rect2(tab_rect.position.x, tab_rect.position.y, tab_rect.size.x, 3), tab_col)
		# Tab border
		var tb = tab_col if is_active else Color8(70, 60, 95)
		draw_rect(Rect2(tab_rect.position.x + 1, tab_rect.position.y + 1, tab_rect.size.x - 2, tab_rect.size.y - 2), tb, false, 2.0 if is_active else 1.0)
		# Tab icon letter in circle
		var icon_x = tab_rect.position.x + 18
		var icon_y = tab_rect.position.y + tab_rect.size.y / 2.0
		draw_circle(Vector2(icon_x, icon_y), 10, tab_col if is_active else Color8(60, 55, 75))
		draw_string(font, Vector2(icon_x - 4, icon_y + 4), TAB_ICONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE if is_active else Color8(140, 130, 160))
		# Tab label
		var label_col = Color.WHITE if is_active else Color8(140, 130, 160)
		draw_string(font, Vector2(tab_rect.position.x + 36, tab_rect.position.y + 24), TABS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, label_col)
		# Navigation hint (D-pad arrows)
		if is_active and using_controller:
			if i > 0:
				draw_string(font, Vector2(tab_rect.position.x - 14, tab_rect.position.y + 24), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(150, 140, 180))
			if i < 2:
				draw_string(font, Vector2(tab_rect.position.x + tab_rect.size.x + 4, tab_rect.position.y + 24), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(150, 140, 180))

	# Tab switch flash
	if tab_switch_anim > 0:
		var flash_col = TAB_COLORS[current_tab]
		draw_rect(Rect2(MENU_X, MENU_Y + 88, MENU_W, 2), Color(flash_col.r, flash_col.g, flash_col.b, tab_switch_anim * 0.5))

	# Content
	match current_tab:
		0: _draw_buildings(font)
		1: _draw_units(font)
		2: _draw_equipment(font)

	# Resources bar
	var res_y = MENU_Y + MENU_H - 54
	_draw_pill(Rect2(MENU_X + 20, res_y - 10, MENU_W - 280, 32), Color8(20, 18, 30, 200))
	var gold_text: String
	if game.p2_joined:
		gold_text = "P1 Gold: %d  |  P2 Gold: %d" % [game.economy.p1_gold, game.economy.p2_gold]
	else:
		gold_text = "Gold: %d" % game.economy.p1_gold
	# Gold coin icon
	draw_circle(Vector2(MENU_X + 36, res_y + 5), 7, Color.GOLD)
	draw_string(font, Vector2(MENU_X + 30, res_y + 2), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(100, 80, 20))
	draw_string(font, Vector2(MENU_X + 50, res_y + 12), gold_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GOLD)
	# Crystal icon
	var cry_x = MENU_X + 380
	var cry_pts = PackedVector2Array([Vector2(cry_x, res_y - 2), Vector2(cry_x + 6, res_y + 5), Vector2(cry_x, res_y + 12), Vector2(cry_x - 6, res_y + 5)])
	draw_colored_polygon(cry_pts, Color8(160, 100, 255))
	draw_string(font, Vector2(cry_x + 12, res_y + 12), "Crystals: %d" % game.economy.crystals, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(200, 150, 255))
	# Unit count
	draw_string(font, Vector2(cry_x + 180, res_y + 12), "Units: %d/%d" % [game.unit_manager.get_normal_alive_count(), game.unit_manager.max_units], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(140, 200, 255))

	# Start wave button (big, inviting)
	var start_rect = _get_start_button_rect()
	var start_hover = start_rect.has_point(get_global_mouse_position()) or kb_on_start
	var start_bg = Color8(55, 140, 55) if start_hover else Color8(35, 95, 35)
	var start_border = Color8(130, 255, 130) if start_hover else Color8(90, 190, 90)
	_draw_pill(Rect2(start_rect.position.x + 3, start_rect.position.y + 3, start_rect.size.x, start_rect.size.y), Color(0, 0, 0, 0.3))
	_draw_pill(start_rect, start_bg)
	draw_rect(Rect2(start_rect.position.x + 1, start_rect.position.y + 1, start_rect.size.x - 2, start_rect.size.y - 2), start_border, false, 3.0 if start_hover else 2.0)
	if start_hover:
		var pulse = 0.3 + 0.2 * sin(card_hover_pulse * 4.0)
		draw_rect(Rect2(start_rect.position.x - 2, start_rect.position.y - 2, start_rect.size.x + 4, start_rect.size.y + 4), Color(0.4, 1.0, 0.4, pulse * 0.15), false, 2.0)
	var start_label = "RESUME WAVE" if mid_wave else "START NEXT WAVE"
	draw_string(font, Vector2(start_rect.position.x + 20, start_rect.position.y + 30), start_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

	# Purchase flash
	if purchase_flash > 0:
		var flash_r = 60.0 * (1.0 - purchase_flash)
		draw_circle(purchase_flash_pos, flash_r, Color(1, 1, 1, purchase_flash * 0.25))

	# Navigation hint bar
	_draw_pill(Rect2(MENU_X + 20, MENU_Y + MENU_H - 20, MENU_W - 40, 18), Color(0, 0, 0, 0.3))
	var nav_hint: String
	if game.p2_joined:
		nav_hint = "D-Pad: Navigate  |  Cross: Buy  |  L/R: Tabs  |  L1: P1  R1: P2"
	else:
		nav_hint = "D-Pad: Navigate  |  Cross/Space: Buy  |  L/R or 1/2/3: Switch Tabs"
	if mid_wave:
		nav_hint += "  |  Circle: Resume"
	draw_string(font, Vector2(MENU_X + 30, MENU_Y + MENU_H - 7), nav_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(130, 125, 155))

func _draw_buildings(font: Font):
	var buildings = BuildingData.get_all_buildings()
	var accent = TAB_COLORS[0]
	for i in range(buildings.size()):
		var b = buildings[i]
		var rect = _get_item_rect(i)
		if rect.position.y < MENU_Y + 88 or rect.position.y + rect.size.y > MENU_Y + MENU_H - 68:
			continue

		var is_repeatable = b.id == "reinforce_doors"
		var owned = game.building_manager.has_building(b.id) and not is_repeatable
		var locked = game.building_manager.is_locked(b)
		var can_buy = game.building_manager.can_buy(b, 0, game.p2_joined)
		var is_selected = (hover_index == i or (kb_index == i and not kb_on_start))

		var bg_color: Color
		if owned:
			bg_color = Color8(35, 60, 40, 230)
		elif is_selected and can_buy:
			bg_color = Color8(50, 45, 68, 230)
		elif locked:
			bg_color = Color8(28, 24, 35, 230)
		else:
			bg_color = Color8(38, 34, 50, 230)
		var border = accent if is_selected else Color8(65, 58, 85)
		_draw_card(rect, bg_color, border, is_selected, accent)

		var tx = rect.position.x + 12
		var ty = rect.position.y + 22
		draw_string(font, Vector2(tx, ty), b.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		draw_string(font, Vector2(tx, ty + 18), b.description, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 20), 10, Color8(175, 175, 200))

		if owned:
			_draw_pill(Rect2(tx, ty + 42, 58, 16), Color8(30, 80, 30))
			draw_string(font, Vector2(tx + 6, ty + 54), "OWNED", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(100, 220, 100))
		elif is_repeatable and can_buy:
			var full_gold = game.economy.get_display_cost_gold(b.cost_gold)
			draw_string(font, Vector2(tx, ty + 48), "%dg" % full_gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GOLD)
		elif locked:
			draw_string(font, Vector2(tx, ty + 48), "LOCKED (need %s)" % b.prereq, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(180, 80, 80))
		else:
			var full_gold = game.economy.get_display_cost_gold(b.cost_gold)
			var cost_text: String
			if game.p2_joined:
				cost_text = "%dg (each %d)" % [full_gold, full_gold / 2]
			else:
				cost_text = "%dg" % full_gold
			if b.cost_crystals > 0:
				cost_text += " + %dc" % game.economy.get_display_cost_crystals(b.cost_crystals)
			var cost_color = Color.GOLD if can_buy else Color8(180, 80, 80)
			draw_string(font, Vector2(tx, ty + 48), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cost_color)

func _draw_units(font: Font):
	var types = UnitData.get_all_types()
	var accent = TAB_COLORS[1]
	for i in range(types.size()):
		var stats = UnitData.get_stats(types[i])
		var rect = _get_item_rect(i)
		if rect.position.y < MENU_Y + 88 or rect.position.y + rect.size.y > MENU_Y + MENU_H - 68:
			continue

		var unlocked = game.unit_manager.is_unlocked(types[i])
		var can_hire: bool
		if UnitData.is_placement_outside(types[i]):
			can_hire = game.unit_manager.can_hire_outside_ally(types[i], 0, game.p2_joined)
		else:
			can_hire = game.unit_manager.can_hire(types[i], 0, game.p2_joined)
		var is_selected = (hover_index == i or (kb_index == i and not kb_on_start))

		var bg_color: Color
		if not unlocked:
			bg_color = Color8(28, 24, 35, 230)
		elif is_selected and can_hire:
			bg_color = Color8(50, 45, 68, 230)
		else:
			bg_color = Color8(38, 34, 50, 230)
		var border = accent if is_selected else Color8(65, 58, 85)
		_draw_card(rect, bg_color, border, is_selected, accent)

		var tx = rect.position.x + 12
		var ty = rect.position.y + 22
		draw_string(font, Vector2(tx, ty), stats.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE if unlocked else Color8(100, 100, 100))
		var desc = "HP:%d  DMG:%d  SPD:%.0f  %s" % [stats.hp, stats.damage, stats.speed, "Ranged" if stats.is_ranged else "Melee"]
		draw_string(font, Vector2(tx, ty + 18), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(175, 175, 200))

		if not unlocked:
			draw_string(font, Vector2(tx, ty + 48), "LOCKED (need %s)" % stats.building_req, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(180, 80, 80))
		else:
			var full_gold = game.economy.get_display_cost_gold(stats.cost_gold)
			var cost_text: String
			if game.p2_joined:
				cost_text = "%dg (each %d)" % [full_gold, full_gold / 2]
			else:
				cost_text = "%dg" % full_gold
			if stats.cost_crystals > 0:
				cost_text += " + %dc" % game.economy.get_display_cost_crystals(stats.cost_crystals)
			var cost_color = Color.GOLD if can_hire else Color8(180, 80, 80)
			draw_string(font, Vector2(tx, ty + 48), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cost_color)
			if UnitData.is_placement_outside(types[i]):
				if game.unit_manager.has_outside_ally(0):
					_draw_pill(Rect2(tx + 140, ty + 40, 54, 16), Color8(30, 70, 30))
					draw_string(font, Vector2(tx + 146, ty + 52), "Owned", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(100, 220, 100))
			else:
				var at_cap = game.unit_manager.get_normal_alive_count() >= game.unit_manager.max_units
				if at_cap:
					_draw_pill(Rect2(tx + 140, ty + 40, 42, 16), Color8(70, 40, 15))
					draw_string(font, Vector2(tx + 146, ty + 52), "FULL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(255, 150, 50))

func _draw_player_selector(font: Font, y: float):
	var sel_w = 180.0
	var sel_x = MENU_X + MENU_W - sel_w - 30
	_draw_pill(Rect2(sel_x - 4, y - 4, sel_w + 8, 34), Color8(25, 22, 38))
	draw_rect(Rect2(sel_x - 3, y - 3, sel_w + 6, 32), Color8(80, 65, 110), false, 1.0)
	var p1_col = Color8(50, 120, 50) if shop_purchasing_player_index == 0 else Color8(38, 34, 48)
	var p2_col = Color8(120, 50, 50) if shop_purchasing_player_index == 1 else Color8(38, 34, 48)
	_draw_pill(Rect2(sel_x, y, 80, 26), p1_col)
	_draw_pill(Rect2(sel_x + 90, y, 80, 26), p2_col)
	draw_string(font, Vector2(sel_x + 6, y + 18), "P1 $%d" % game.economy.p1_gold, HORIZONTAL_ALIGNMENT_LEFT, 72, 11, Color.WHITE if shop_purchasing_player_index == 0 else Color8(140, 140, 160))
	draw_string(font, Vector2(sel_x + 96, y + 18), "P2 $%d" % game.economy.p2_gold, HORIZONTAL_ALIGNMENT_LEFT, 72, 11, Color.WHITE if shop_purchasing_player_index == 1 else Color8(140, 140, 160))
	draw_string(font, Vector2(sel_x - 120, y + 18), "Paying: L1 | R1", HORIZONTAL_ALIGNMENT_RIGHT, 110, 10, Color8(130, 125, 155))

func _draw_equipment(font: Font):
	var buying_player = _get_purchasing_player()
	var equips = EquipmentData.get_all_equipment()
	var accent = TAB_COLORS[2]
	for i in range(equips.size()):
		var e = equips[i]
		var rect = _get_item_rect(i)
		if rect.position.y < MENU_Y + 88 or rect.position.y + rect.size.y > MENU_Y + MENU_H - 68:
			continue

		var is_consumable = e.get("type", "equipment") == "consumable"
		var owned = buying_player.has_equipment(e.id)
		var is_magnet_active = e.get("effects", {}).has("magnet") and buying_player.has_magnet
		var has_prereq = e.prereq_building == "" or game.building_manager.has_building(e.prereq_building)
		var effectively_owned = (owned or is_magnet_active) and not is_consumable
		var can_buy = has_prereq and not effectively_owned and game.economy.can_afford(e.cost_gold, e.cost_crystals, shop_purchasing_player_index)
		var is_selected = (hover_index == i or (kb_index == i and not kb_on_start))

		var bg_color: Color
		if effectively_owned:
			bg_color = Color8(35, 60, 40, 230)
		elif is_selected and can_buy:
			bg_color = Color8(50, 45, 68, 230)
		elif not has_prereq:
			bg_color = Color8(28, 24, 35, 230)
		else:
			bg_color = Color8(38, 34, 50, 230)
		var border = accent if is_selected else Color8(65, 58, 85)
		_draw_card(rect, bg_color, border, is_selected, accent)

		var tx = rect.position.x + 12
		var ty = rect.position.y + 22
		draw_string(font, Vector2(tx, ty), e.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE if has_prereq else Color8(100, 100, 100))
		draw_string(font, Vector2(tx, ty + 18), e.description, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 20), 10, Color8(175, 175, 200))

		if effectively_owned:
			var status_text = "ACTIVE" if is_magnet_active else "EQUIPPED"
			_draw_pill(Rect2(tx, ty + 42, 68, 16), Color8(30, 80, 30))
			draw_string(font, Vector2(tx + 6, ty + 54), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(100, 220, 100))
		elif is_consumable and e.get("effects", {}).has("heal_full"):
			if game.p2_joined:
				var count_text = "P1: %d  P2: %d" % [game.player_node.potion_count, game.player2_node.potion_count]
				draw_string(font, Vector2(tx, ty + 48), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(100, 220, 100))
			else:
				draw_string(font, Vector2(tx, ty + 48), "Held: %d" % game.player_node.potion_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(100, 220, 100))
			var cost_text = "  %dg" % game.economy.get_display_cost_gold(e.cost_gold)
			var cost_color = Color.GOLD if game.economy.can_afford(e.cost_gold, e.cost_crystals, shop_purchasing_player_index) else Color8(180, 80, 80)
			draw_string(font, Vector2(tx + 120, ty + 48), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cost_color)
		elif not has_prereq:
			draw_string(font, Vector2(tx, ty + 48), "LOCKED (need %s)" % e.prereq_building, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(180, 80, 80))
		else:
			var cost_text = "%dg" % game.economy.get_display_cost_gold(e.cost_gold)
			if e.cost_crystals > 0:
				cost_text += " + %dc" % game.economy.get_display_cost_crystals(e.cost_crystals)
			var cost_color = Color.GOLD if can_buy else Color8(180, 80, 80)
			draw_string(font, Vector2(tx, ty + 48), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cost_color)

func _ease_out_back(t: float) -> float:
	"""Ease out with overshoot for bouncy open animation."""
	if t >= 1.0:
		return 1.0
	var c1 = 1.70158
	var c3 = c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3) + c1 * pow(t - 1.0, 2)
