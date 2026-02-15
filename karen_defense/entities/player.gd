class_name PlayerEntity
extends Node2D

# Multiplayer config
var action_prefix: String = ""  # "" for P1, "p2_" for P2
var player_index: int = 0       # 0=P1, 1=P2
var is_dead: bool = false

# Base stats
var max_hp: int = 100
var current_hp: int = 100
var move_speed: float = 160.0
var melee_damage: int = 15
var ranged_damage: int = 10
var melee_cooldown_base: float = 0.30  # Slightly faster base melee
var ranged_cooldown_base: float = 0.65  # Slightly faster base ranged
var melee_range: float = 75.0
var melee_arc: float = 1.2
var repair_speed: float = 25.0
var crit_chance: float = 0.0
var gold_multiplier: float = 1.0
var attack_cooldown_multiplier: float = 1.0
var max_melee_targets: int = 3
var ally_damage_multiplier: float = 1.0
var has_magnet: bool = false
var magnet_radius: float = 200.0
var dodge_chance: float = 0.0
var lifesteal: int = 0
var regen_rate: float = 0.0  # HP per second
var regen_accum: float = 0.0
var enemy_gold_mult: float = 1.0
var xp_mult: float = 1.0
var proj_speed_mult: float = 1.0
var has_grenades: bool = false
var grenade_count: int = 0

# Potions
var potion_count: int = 0

# State
var facing_angle: float = 0.0
var melee_timer: float = 0.0
var ranged_timer: float = 0.0
var is_attacking_melee: bool = false
var melee_attack_timer: float = 0.0
var melee_hit_done: bool = false
var weapon_mode: String = "melee"
var is_repairing: bool = false
var repair_anim_time: float = 0.0  # Continuous timer for hammer swing animation
var repair_spark_timer: float = 0.0  # Timer for spark particle emission
var invincibility_timer: float = 0.0
var hit_flash_timer: float = 0.0
var walk_anim: float = 0.0
var is_moving: bool = false
var idle_time: float = 0.0
var repair_timer: float = 0.0

# Grenade state
var grenade_cooldown: float = 0.0
const GRENADE_COOLDOWN_TIME = 1.2
const GRENADE_DAMAGE = 40
const GRENADE_RANGE = 250.0
const GRENADE_MIN_RANGE = 60.0
const MAX_ACTIVE_GRENADES = 3
var active_grenade_count: int = 0
var grenade_aiming: bool = false  # True when aiming grenade (hold attack)
var grenade_aim_distance: float = 150.0  # Current aim distance (adjustable)
var grenade_aim_pulse: float = 0.0  # Visual pulse timer

# Block state
var is_blocking: bool = false
var block_hold_time: float = 0.0  # How long block has been held
var block_stamina: float = 2.0  # Remaining block stamina (max 2s)
var block_cooldown: float = 0.0  # Cooldown after stamina depleted
const BLOCK_MAX_STAMINA = 2.0
const BLOCK_COOLDOWN_TIME = 1.0
const BLOCK_DAMAGE_REDUCTION = 0.6  # 60% reduction normally
const BLOCK_PERFECT_WINDOW = 0.15  # First 0.15s = perfect block
const BLOCK_PERFECT_REDUCTION = 0.9  # 90% reduction on perfect block
const BLOCK_SPEED_PENALTY = 0.6  # 60% of normal speed while blocking
var block_flash_timer: float = 0.0  # Visual flash on perfect block

# Sprint state
var is_sprinting: bool = false
const SPRINT_SPEED_MULT = 1.55  # 55% faster when holding sprint

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_cooldown: float = 0.0
const DASH_SPEED = 650.0
const DASH_DURATION = 0.16
const DASH_COOLDOWN_TIME = 0.35
var dash_trail: Array = []  # For afterimage effect

# Combo state
var combo_index: int = 0  # 0, 1, 2 for the 3-hit combo
var combo_window: float = 0.0  # Time left to input next combo hit
const COMBO_WINDOW_TIME = 0.6  # Slightly more forgiving combo window
const COMBO_COUNT = 3
# Per-combo-hit configs: {duration, damage_mult, arc_mult, lunge, squash}
const COMBO_CONFIGS = [
	{"duration": 0.13, "damage_mult": 1.0, "arc_mult": 1.0, "lunge": 20.0, "squash": 1.3},   # Hit 1: Quick slash (faster)
	{"duration": 0.16, "damage_mult": 1.35, "arc_mult": 0.85, "lunge": 26.0, "squash": 1.4},   # Hit 2: Thrust (more forward)
	{"duration": 0.22, "damage_mult": 1.7, "arc_mult": 1.6, "lunge": 14.0, "squash": 0.55},   # Hit 3: Heavy spin (more impact)
]

# Input buffering for responsive combat
var attack_buffered: bool = false  # Buffer the next attack press during current attack animation
var attack_buffer_timer: float = 0.0
const ATTACK_BUFFER_WINDOW = 0.15  # 150ms input buffer

# Weapon wheel
var weapon_wheel: WeaponWheel = WeaponWheel.new()
var weapon_wheel_open: bool = false
var weapon_wheel_press_time: float = 0.0  # Track how long swap button is held
var weapon_wheel_button_held: bool = false

# Grapple state
var is_grappling: bool = false
var grapple_target: Vector2 = Vector2.ZERO
var grapple_cooldown: float = 0.0
var grapple_line_progress: float = 0.0  # 0..1 for line shoot-out animation
var grapple_pull_started: bool = false
const GRAPPLE_RANGE = 350.0
const GRAPPLE_SPEED = 800.0
const GRAPPLE_COOLDOWN_TIME = 1.5
const GRAPPLE_LINE_SPEED = 10.0  # How fast the line extends (0->1 in 0.1s)
const GRAPPLE_CONE = 1.2  # Radians, ~70 deg half-cone for target detection

# Ranged charge (Heavy Revolver)
var ranged_charging: bool = false
var ranged_charge_timer: float = 0.0
var ranged_charge_time: float = 0.0  # 0 = instant fire (default AK), 0.8 = heavy revolver
var ranged_charge_ready: bool = false  # True when fully charged
var ranged_weapon_order: Array[String] = ["ak47"]
var equipped_ranged_weapon: String = "ak47"

# Mount state
var has_dino_mount: bool = false
var dino_anim_time: float = 0.0

# Facing control
var last_move_dir: Vector2 = Vector2.RIGHT
var last_mouse_pos: Vector2 = Vector2.ZERO
var using_mouse_aim: bool = false

const BODY_RADIUS = 26.0

# Sprite
var sprite_texture: Texture2D = null
var hammer_texture: Texture2D = null
var grapple_texture: Texture2D = null
const SPRITE_HEIGHT = 150.0

# Anchor points on player sprite (offset from texture center, in texture pixels)
# X+ = character's right (facing right), Y+ = down
const SPRITE_ANCHORS = {
	"right_hand": Vector2(21, 9),
	"left_hand": Vector2(-21, 9),
	"head_top": Vector2(0, -42),
	"back": Vector2(-12, 0),
}

# Weapon configs: id -> {texture, slot, height, grip (fraction 0-1), rotation_offset}
var weapon_configs: Dictionary = {}

# Equipment
var owned_equipment: Array[String] = []

# Visual juice (Brotato-style)
var squash_factor: float = 1.0
var squash_velocity: float = 0.0
var trail_history: Array = []
var trail_timer: float = 0.0

func _ready():
	if player_index == 1:
		sprite_texture = load("res://assets/player2.png")
	else:
		sprite_texture = load("res://assets/WilliamPlayer.png")
	hammer_texture = load("res://assets/hammer.png")
	grapple_texture = load("res://assets/grapple.png")
	weapon_configs["ak47"] = {
		"texture": load("res://assets/rangedak.png"),
		"slot": "right_hand",
		"height": 52.0,
		"grip": Vector2(0.25, 0.5),
		"rotation_offset": 0.0,
		"damage_mult": 1.0,
		"charge_time": 0.0,
	}

func has_equipment(equip_id: String) -> bool:
	return equip_id in owned_equipment

func buy_equipment(equip_id: String, game) -> bool:
	var data = EquipmentData.get_equipment(equip_id)
	if data.is_empty():
		return false
	var is_consumable = data.get("type", "equipment") == "consumable"
	# Grenade belt is a stackable consumable refill.
	if equip_id == "grenade_belt":
		is_consumable = true
	# Non-consumables can only be bought once
	if not is_consumable and has_equipment(equip_id):
		return false
	if data.prereq_building != "" and not game.building_manager.has_building(data.prereq_building):
		return false
	if not game.economy.can_afford(data.cost_gold, data.cost_crystals, player_index):
		return false
	if not game.economy.spend(data.cost_gold, data.cost_crystals, player_index):
		return false
	# Apply effects
	var effects = data.get("effects", {})
	if effects.has("heal_full"):
		potion_count += 1
	if effects.has("magnet"):
		has_magnet = true
	if effects.has("grenade"):
		has_grenades = true
		grenade_count += int(effects.get("grenade_count", 0))
	if effects.has("dino_mount"):
		has_dino_mount = true
	if effects.has("melee_damage_mult"):
		melee_damage = int(melee_damage * effects.melee_damage_mult)
	if effects.has("ranged_damage_mult") and not data.has("weapon_mode"):
		ranged_damage = int(ranged_damage * effects.ranged_damage_mult)
	if effects.has("max_hp"):
		var bonus = int(effects.max_hp)
		max_hp += bonus
		current_hp += bonus
	if effects.has("crit_chance"):
		crit_chance += float(effects.crit_chance)
	if effects.has("gold_mult"):
		gold_multiplier *= float(effects.gold_mult)
	if effects.has("move_speed_mult"):
		move_speed *= float(effects.move_speed_mult)
	# Register weapon config for weapon-type equipment
	if not is_consumable:
		owned_equipment.append(equip_id)
		if data.has("weapon_slot"):
			weapon_configs[equip_id] = {
				"texture": load("res://assets/%s.png" % data.sprite),
				"slot": data.weapon_slot,
				"height": data.weapon_height,
				"grip": data.weapon_grip,
				"rotation_offset": data.weapon_rotation,
				"damage_mult": float(effects.get("ranged_damage_mult", 1.0)),
				"charge_time": float(data.get("charge_time", 0.0)),
			}
		if data.get("weapon_mode", "") == "ranged" and not ranged_weapon_order.has(equip_id):
			ranged_weapon_order.append(equip_id)
			equipped_ranged_weapon = equip_id
			_equip_ranged_weapon(equip_id)
	if game.sfx:
		game.sfx.play_purchase()
	return true

func reset():
	is_dead = false
	visible = true
	max_hp = 100
	current_hp = 100
	move_speed = 160.0
	melee_damage = 15
	ranged_damage = 10
	attack_cooldown_multiplier = 1.0
	crit_chance = 0.0
	gold_multiplier = 1.0
	max_melee_targets = 3
	melee_arc = 1.2
	repair_speed = 25.0
	ally_damage_multiplier = 1.0
	melee_timer = 0.0
	ranged_timer = 0.0
	is_attacking_melee = false
	melee_hit_done = false
	weapon_mode = "melee"
	is_repairing = false
	invincibility_timer = 0.0
	hit_flash_timer = 0.0
	repair_timer = 0.0
	has_magnet = false
	has_grenades = false
	grenade_count = 0
	dodge_chance = 0.0
	lifesteal = 0
	regen_rate = 0.0
	regen_accum = 0.0
	enemy_gold_mult = 1.0
	xp_mult = 1.0
	proj_speed_mult = 1.0
	potion_count = 0
	squash_factor = 1.0
	squash_velocity = 0.0
	trail_history.clear()
	trail_timer = 0.0
	owned_equipment.clear()
	grenade_cooldown = 0.0
	active_grenade_count = 0
	grenade_aiming = false
	grenade_aim_distance = 150.0
	grenade_aim_pulse = 0.0
	is_blocking = false
	block_hold_time = 0.0
	block_stamina = BLOCK_MAX_STAMINA
	block_cooldown = 0.0
	block_flash_timer = 0.0
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown = 0.0
	dash_trail.clear()
	combo_index = 0
	combo_window = 0.0
	attack_buffered = false
	attack_buffer_timer = 0.0
	weapon_wheel_open = false
	weapon_wheel = WeaponWheel.new()
	weapon_wheel_press_time = 0.0
	weapon_wheel_button_held = false
	ranged_charging = false
	ranged_charge_timer = 0.0
	ranged_charge_time = 0.0
	ranged_charge_ready = false
	ranged_weapon_order = ["ak47"]
	equipped_ranged_weapon = "ak47"
	_equip_ranged_weapon(equipped_ranged_weapon)
	is_grappling = false
	grapple_target = Vector2.ZERO
	grapple_cooldown = 0.0
	grapple_line_progress = 0.0
	grapple_pull_started = false
	is_sprinting = false
	has_dino_mount = false
	dino_anim_time = 0.0
	# Remove non-default weapon configs (keep ak47)
	var keep_keys = ["ak47"]
	for key in weapon_configs.keys():
		if key not in keep_keys:
			weapon_configs.erase(key)

func use_potion(game):
	if potion_count > 0 and current_hp < max_hp:
		potion_count -= 1
		current_hp = max_hp
		if game.sfx:
			game.sfx.play_repair()
		game.spawn_damage_number(position, "HEALED!", Color8(100, 255, 100))

func update_player(delta: float, game):
	if has_dino_mount:
		dino_anim_time += delta
	_handle_grapple(delta, game)
	_handle_dash(delta, game)
	_handle_block(delta, game)
	_handle_movement(delta, game)
	_handle_facing()
	_handle_combat(delta, game)
	_handle_grenade(delta, game)
	_handle_repair(delta, game)
	_handle_potion(game)
	_update_timers(delta)
	_update_squash(delta)
	_update_trail(delta)
	_update_dash_trail(delta)
	idle_time += delta
	# HP regen
	if regen_rate > 0 and current_hp < max_hp:
		regen_accum += regen_rate * delta
		if regen_accum >= 1.0:
			var heal_amt = int(regen_accum)
			current_hp = mini(current_hp + heal_amt, max_hp)
			regen_accum -= heal_amt
	queue_redraw()

func _handle_grapple(delta, game):
	grapple_cooldown = maxf(0, grapple_cooldown - delta)

	if is_grappling:
		# Phase 1: Line extending to target
		if not grapple_pull_started:
			grapple_line_progress = minf(grapple_line_progress + delta * GRAPPLE_LINE_SPEED, 1.0)
			if grapple_line_progress >= 1.0:
				grapple_pull_started = true
		else:
			# Phase 2: Pull player toward target
			var dir_to_target = (grapple_target - position).normalized()
			var dist_to_target = position.distance_to(grapple_target)
			if dist_to_target < 30.0:
				# Arrived at target
				is_grappling = false
				grapple_pull_started = false
				grapple_line_progress = 0.0
				grapple_cooldown = GRAPPLE_COOLDOWN_TIME
				squash_factor = 0.65  # Landing squash
				invincibility_timer = maxf(invincibility_timer, 0.1)
				game.particles.emit_burst(position.x, position.y, Color8(100, 200, 255), 6)
				if game.sfx:
					game.sfx.play_grapple_land()
			else:
				position += dir_to_target * GRAPPLE_SPEED * delta
				invincibility_timer = maxf(invincibility_timer, delta + 0.05)
				# Clamp to world bounds
				var world_w = game.map.SCREEN_W if game else 1280.0
				var world_h = game.map.SCREEN_H if game else 720.0
				position.x = clampf(position.x, 15, world_w - 15)
				position.y = clampf(position.y, 15, world_h - 15)
		return  # Skip other movement while grappling

	if Input.is_action_just_pressed(action_prefix + "grapple") and grapple_cooldown <= 0 and not is_dead and not is_dashing:
		# Find valid grapple target
		var target = _find_grapple_target(game)
		if target != Vector2.ZERO:
			is_grappling = true
			grapple_target = target
			grapple_line_progress = 0.0
			grapple_pull_started = false
			is_repairing = false
			is_blocking = false
			squash_factor = 1.4  # Stretch toward target
			if game.sfx:
				game.sfx.play_grapple_launch()

func _find_grapple_target(game) -> Vector2:
	"""Scan for nearest valid grapple target in a cone in front of the player."""
	var best_target = Vector2.ZERO
	var best_dist = GRAPPLE_RANGE + 1

	var aim_dir = Vector2.from_angle(facing_angle)
	var candidates: Array = []

	# Barricades
	for b in game.map.barricades:
		candidates.append(b.position)

	# Doors
	for d in game.map.doors:
		candidates.append(d.position)

	# Allies
	for ally in game.ally_container.get_children():
		if ally.current_hp > 0:
			candidates.append(ally.position)

	# Wall corners as anchor points (keep corners and fort corners)
	var map = game.map
	var corner_anchors = [
		Vector2(map.keep_left, map.keep_top),
		Vector2(map.keep_right, map.keep_top),
		Vector2(map.keep_left, map.keep_bottom),
		Vector2(map.keep_right, map.keep_bottom),
		Vector2(map.FORT_LEFT, map.FORT_TOP),
		Vector2(map.FORT_RIGHT, map.FORT_TOP),
		Vector2(map.FORT_LEFT, map.FORT_BOTTOM),
		Vector2(map.FORT_RIGHT, map.FORT_BOTTOM),
	]
	for anchor in corner_anchors:
		candidates.append(anchor)

	# Entrance positions
	for ep in map.entrance_positions:
		candidates.append(ep)
	for kep in map.keep_entrance_positions:
		candidates.append(kep)

	for target_pos in candidates:
		var dist = position.distance_to(target_pos)
		if dist < 40.0 or dist > GRAPPLE_RANGE:
			continue
		var angle_to = (target_pos - position).angle()
		var angle_diff = abs(fmod(angle_to - facing_angle + PI, TAU) - PI)
		if angle_diff < GRAPPLE_CONE / 2.0 and dist < best_dist:
			best_dist = dist
			best_target = target_pos

	return best_target

func _handle_block(delta, game):
	block_cooldown = maxf(0, block_cooldown - delta)
	block_flash_timer = maxf(0, block_flash_timer - delta)
	# Regenerate block stamina when not blocking
	if not is_blocking:
		block_stamina = minf(block_stamina + delta * 0.8, BLOCK_MAX_STAMINA)

	var wants_block = Input.is_action_pressed(action_prefix + "block")
	# Also allow right mouse button for P1
	if action_prefix == "":
		wants_block = wants_block or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if wants_block and not is_dashing and not is_attacking_melee and block_cooldown <= 0 and block_stamina > 0:
		if not is_blocking:
			# Just started blocking
			is_blocking = true
			block_hold_time = 0.0
			is_repairing = false
		block_hold_time += delta
		block_stamina -= delta
		if block_stamina <= 0:
			# Stamina depleted - force end block with cooldown
			is_blocking = false
			block_cooldown = BLOCK_COOLDOWN_TIME
			block_hold_time = 0.0
	else:
		if is_blocking:
			is_blocking = false
			block_hold_time = 0.0

func _handle_movement(delta, game):
	# During grapple/dash, movement is handled elsewhere
	if is_grappling:
		return
	if is_dashing:
		position += dash_direction * DASH_SPEED * delta
		# Add dash trail ghost
		if dash_trail.size() == 0 or position.distance_to(dash_trail[-1].pos) > 8.0:
			dash_trail.append({"pos": position, "alpha": 0.5, "angle": facing_angle})
		var world_w = game.map.SCREEN_W if game else 1280.0
		var world_h = game.map.SCREEN_H if game else 720.0
		position.x = clampf(position.x, 15, world_w - 15)
		position.y = clampf(position.y, 15, world_h - 15)
		# Dash phases THROUGH walls — no collision during dash
		return

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed(action_prefix + "move_up"): input_dir.y -= 1
	if Input.is_action_pressed(action_prefix + "move_down"): input_dir.y += 1
	if Input.is_action_pressed(action_prefix + "move_left"): input_dir.x -= 1
	if Input.is_action_pressed(action_prefix + "move_right"): input_dir.x += 1
	is_moving = input_dir.length() > 0
	if is_moving:
		input_dir = input_dir.normalized()
		last_move_dir = input_dir
		is_repairing = false
		walk_anim += delta * 10.0
	# Sprint: hold to run faster
	is_sprinting = is_moving and Input.is_action_pressed(action_prefix + "sprint") and not is_blocking and not is_attacking_melee
	var effective_speed = move_speed
	if is_sprinting:
		effective_speed *= SPRINT_SPEED_MULT
	if has_dino_mount:
		effective_speed *= 1.40  # Dino mount +40% speed
	if is_blocking:
		effective_speed *= BLOCK_SPEED_PENALTY
	position += input_dir * effective_speed * delta
	var world_w = game.map.SCREEN_W if game else 1280.0
	var world_h = game.map.SCREEN_H if game else 720.0
	position.x = clampf(position.x, 15, world_w - 15)
	position.y = clampf(position.y, 15, world_h - 15)
	# Collide with walls and intact barricades
	position = game.map.resolve_collision(position, BODY_RADIUS)

func _handle_facing():
	# Right stick aiming (controller)
	var aim_dir = Vector2(
		Input.get_action_strength(action_prefix + "aim_right") - Input.get_action_strength(action_prefix + "aim_left"),
		Input.get_action_strength(action_prefix + "aim_down") - Input.get_action_strength(action_prefix + "aim_up")
	)
	if aim_dir.length() > 0.25:
		facing_angle = aim_dir.angle()
		using_mouse_aim = false
		return

	# P2 is controller-only, skip mouse aim
	if action_prefix != "":
		facing_angle = last_move_dir.angle()
		return

	var mouse_pos = get_global_mouse_position()
	# Detect if the PHYSICAL mouse moved (use screen-space to avoid camera drift)
	var screen_mouse = get_viewport().get_mouse_position() if get_viewport() else Vector2.ZERO
	if screen_mouse.distance_to(last_mouse_pos) > 2.0:
		using_mouse_aim = true
		last_mouse_pos = screen_mouse
	elif is_moving:
		using_mouse_aim = false

	if using_mouse_aim:
		facing_angle = (mouse_pos - position).angle()
	else:
		facing_angle = last_move_dir.angle()

func _handle_combat(delta, game):
	melee_timer = maxf(0, melee_timer - delta)
	ranged_timer = maxf(0, ranged_timer - delta)
	# Combo window countdown
	if combo_window > 0:
		combo_window -= delta
		if combo_window <= 0:
			combo_index = 0  # Reset combo if window expires

	# Weapon wheel: QUICK TAP = swap to last weapon, HOLD = open wheel
	var swap_pressed = Input.is_action_just_pressed(action_prefix + "swap_weapon")
	var swap_held = Input.is_action_pressed(action_prefix + "swap_weapon")
	var swap_released = weapon_wheel_button_held and not swap_held

	if swap_pressed:
		weapon_wheel_button_held = true
		weapon_wheel_press_time = 0.0
	if weapon_wheel_button_held:
		weapon_wheel_press_time += delta

	# Open the wheel after holding past threshold
	if weapon_wheel_button_held and not weapon_wheel_open and weapon_wheel_press_time >= weapon_wheel.QUICK_TAP_THRESHOLD:
		weapon_wheel.open(weapon_mode, ranged_weapon_order, equipped_ranged_weapon)
		weapon_wheel_open = true
		combo_index = 0
		combo_window = 0
		if game.sfx:
			game.sfx.play_weapon_wheel_open()

	if weapon_wheel_open:
		var aim_x = Input.get_action_strength(action_prefix + "aim_right") - Input.get_action_strength(action_prefix + "aim_left")
		var aim_y = Input.get_action_strength(action_prefix + "aim_down") - Input.get_action_strength(action_prefix + "aim_up")
		weapon_wheel.update(delta, aim_x, aim_y)
		if swap_released:
			# Released after hold - confirm wheel selection
			var old_mode = weapon_mode
			var selection = weapon_wheel.close()
			var new_mode = String(selection.get("mode", weapon_mode))
			if new_mode == "throwable":
				if has_grenades and grenade_count > 0:
					weapon_wheel.track_weapon_change(old_mode, "throwable")
					weapon_mode = "throwable"
			else:
				weapon_wheel.track_weapon_change(old_mode, new_mode)
				weapon_mode = new_mode
				if weapon_mode == "ranged":
					_equip_ranged_weapon(String(selection.get("ranged_weapon", equipped_ranged_weapon)))
			weapon_wheel_open = false
			weapon_wheel_button_held = false
			if game.sfx:
				game.sfx.play_weapon_wheel_select()
	elif swap_released:
		# Quick tap - swap to last weapon
		var old_mode = weapon_mode
		var new_mode = weapon_wheel.quick_swap(weapon_mode)
		if new_mode == "throwable" and (not has_grenades or grenade_count <= 0):
			new_mode = "melee"  # Fallback if no grenades
		weapon_wheel.track_weapon_change(old_mode, new_mode)
		weapon_mode = new_mode
		if weapon_mode == "ranged":
			_equip_ranged_weapon(equipped_ranged_weapon)
		weapon_wheel_button_held = false
		if game.sfx:
			game.sfx.play_weapon_wheel_select()
	else:
		weapon_wheel.update(delta, 0, 0)

	if swap_released:
		weapon_wheel_button_held = false

	# Attack input (properly handle both keyboard/controller and mouse)
	var is_held = Input.is_action_pressed(action_prefix + "attack")
	var is_just = Input.is_action_just_pressed(action_prefix + "attack")
	if action_prefix == "":
		var mouse_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		is_held = is_held or mouse_held
		# For "just pressed", only use action_just_pressed (input map handles mouse mapping)
		is_just = is_just or Input.is_action_just_pressed("attack")

	# Handle Heavy Revolver charge release OUTSIDE cooldown gate so releasing during
	# cooldown properly resets charge state and doesn't get stuck
	if ranged_charge_time > 0 and ranged_charging and not is_held:
		if ranged_charge_ready and ranged_timer <= 0:
			_do_ranged_attack(game)
		ranged_charging = false
		ranged_charge_timer = 0.0
		ranged_charge_ready = false

	# Input buffering: store attack press during current animation
	if is_just and is_attacking_melee:
		attack_buffered = true
		attack_buffer_timer = ATTACK_BUFFER_WINDOW
	if attack_buffer_timer > 0:
		attack_buffer_timer -= delta
		if attack_buffer_timer <= 0:
			attack_buffered = false

	if not is_repairing and not is_dashing and not is_blocking and not weapon_wheel_open:
		if weapon_mode == "melee":
			# Melee combo: just_pressed starts combo, buffered input, or held auto-continues
			var can_melee = melee_timer <= 0 and not is_attacking_melee
			var wants_attack = is_just or attack_buffered or (is_held and combo_window > 0)
			if can_melee and wants_attack:
				attack_buffered = false
				attack_buffer_timer = 0.0
				_do_melee_attack(game)
		elif weapon_mode == "ranged" and ranged_timer <= 0:
			if ranged_charge_time > 0:
				# Heavy Revolver: hold to charge, release to fire
				if is_held:
					if not ranged_charging:
						ranged_charging = true
						ranged_charge_timer = 0.0
						ranged_charge_ready = false
					ranged_charge_timer += delta
					if ranged_charge_timer >= ranged_charge_time and not ranged_charge_ready:
						ranged_charge_ready = true
						if game.sfx:
							game.sfx.play_charge_ready()
				# Release handled above (outside cooldown gate)
			else:
				# Standard ranged: hold to auto-fire
				if is_held or is_just:
					_do_ranged_attack(game)
		elif weapon_mode == "throwable" and has_grenades and grenade_count >= 0:
			if grenade_count <= 0:
				if grenade_aiming:
					grenade_aiming = false
					grenade_aim_pulse = 0.0
				if is_just and game:
					game.spawn_damage_number(position + Vector2(0, -28), "NO GRENADES", Color8(255, 120, 90))
					if game.sfx:
						game.sfx.play_error()
				return
			if grenade_cooldown <= 0 and active_grenade_count < MAX_ACTIVE_GRENADES:
				if is_held:
					if not grenade_aiming:
						grenade_aiming = true
						grenade_aim_distance = 150.0
					# Adjust distance with movement stick (up/down)
					var aim_adjust = Input.get_action_strength(action_prefix + "move_up") - Input.get_action_strength(action_prefix + "move_down")
					grenade_aim_distance = clampf(grenade_aim_distance + aim_adjust * delta * 200.0, GRENADE_MIN_RANGE, GRENADE_RANGE)
					grenade_aim_pulse += delta
				elif grenade_aiming:
					# Released attack button — throw!
					_throw_grenade(game)
					grenade_aiming = false
					grenade_aim_pulse = 0.0
			elif not is_held and grenade_aiming:
				# Cooldown active but released — cancel aim
				grenade_aiming = false
				grenade_aim_pulse = 0.0

func _do_melee_attack(game):
	var cfg = COMBO_CONFIGS[combo_index]
	melee_timer = melee_cooldown_base * attack_cooldown_multiplier * (0.7 + combo_index * 0.15)
	is_attacking_melee = true
	melee_hit_done = false
	melee_attack_timer = cfg.duration
	squash_factor = cfg.squash
	if game.sfx:
		game.sfx.play_combo_hit(combo_index)
	# Advance combo
	combo_window = COMBO_WINDOW_TIME
	combo_index = (combo_index + 1) % COMBO_COUNT

func _do_ranged_attack(game):
	ranged_timer = ranged_cooldown_base * attack_cooldown_multiplier
	var proj = ProjectileEntity.new()
	proj.position = position
	proj.direction = Vector2.from_angle(facing_angle)
	proj.damage = int(ranged_damage * _get_current_ranged_damage_mult())
	proj.source = "player"
	proj.owner_player = self
	proj.proj_speed = 450.0 * proj_speed_mult
	# Heavy revolver: bigger, slower projectile
	if ranged_charge_time > 0:
		proj.proj_speed = 550.0 * proj_speed_mult
		proj.SIZE = 14.0
		squash_factor = 0.6  # Heavy recoil
		# Muzzle flash particles
		var muzzle_dir = Vector2.from_angle(facing_angle)
		game.particles.emit_directional(position.x + muzzle_dir.x * 30, position.y + muzzle_dir.y * 30, muzzle_dir, Color8(255, 200, 80), 8)
		game.start_shake(4.0, 0.12)
		if game.sfx:
			game.sfx.play_charge_fire()
	else:
		squash_factor = 0.8  # Brief recoil squash
		if game.sfx:
			game.sfx.play_shoot()
	game.projectile_container.add_child(proj)

func _handle_repair(_delta, game):
	repair_timer = maxf(0, repair_timer - _delta)
	if is_repairing:
		repair_anim_time += _delta
		repair_spark_timer += _delta
		# Spawn sparks at swing apex (every ~0.3s = half a swing cycle)
		if repair_spark_timer >= 0.3:
			repair_spark_timer -= 0.3
			var barricade = game.map.get_nearest_barricade_in_range(position, 80.0)
			if barricade:
				game.particles.emit_burst(barricade.position.x, barricade.position.y, Color8(255, 200, 80), 4)
				if game.sfx:
					game.sfx.play_hammer_hit()
	else:
		repair_anim_time = 0.0
		repair_spark_timer = 0.0
	if Input.is_action_just_pressed(action_prefix + "repair") and repair_timer <= 0:
		# Priority 1: Toggle nearby door (open/close)
		var door = game.map.get_nearest_door_in_range(position, 70.0)
		if door:
			door.toggle_door()
			repair_timer = 0.3  # Brief cooldown to prevent spam
			is_repairing = false
			if game.sfx:
				game.sfx.play_repair()
			return
		# Priority 2: Repair nearby barricade
		var barricade = game.map.get_nearest_barricade_in_range(position, 60.0)
		if barricade and barricade.current_hp < barricade.max_hp:
			barricade.partial_repair(0.2)
			repair_timer = 1.0
			is_repairing = true
			if game.sfx:
				game.sfx.play_repair()
		else:
			is_repairing = false
	elif repair_timer <= 0:
		is_repairing = false

func _handle_potion(game):
	if Input.is_action_just_pressed(action_prefix + "use_potion"):
		use_potion(game)

func _handle_dash(delta, game):
	dash_cooldown = maxf(0, dash_cooldown - delta)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			invincibility_timer = maxf(invincibility_timer, 0.05)  # Brief post-dash i-frame
		return

	if Input.is_action_just_pressed(action_prefix + "dash") and dash_cooldown <= 0 and not is_dead and not is_blocking:
		# Dash in movement direction, or facing direction if standing still
		var input_dir = Vector2.ZERO
		if Input.is_action_pressed(action_prefix + "move_up"): input_dir.y -= 1
		if Input.is_action_pressed(action_prefix + "move_down"): input_dir.y += 1
		if Input.is_action_pressed(action_prefix + "move_left"): input_dir.x -= 1
		if Input.is_action_pressed(action_prefix + "move_right"): input_dir.x += 1
		if input_dir.length() > 0:
			dash_direction = input_dir.normalized()
		else:
			dash_direction = Vector2.from_angle(facing_angle)
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown = DASH_COOLDOWN_TIME
		invincibility_timer = DASH_DURATION + 0.05  # Invincible during dash
		squash_factor = 1.5  # Stretch in dash direction
		is_repairing = false
		# Dash particles
		if game:
			game.particles.emit_directional(position.x, position.y, -dash_direction, Color8(150, 200, 255), 6)
		if game and game.sfx:
			game.sfx.play_dash()

func _handle_grenade(delta, _game):
	grenade_cooldown = maxf(0, grenade_cooldown - delta)
	# Grenades are now thrown via weapon wheel -> throwable mode -> attack button
	# This method just ticks the cooldown

func _throw_grenade(game):
	if grenade_count <= 0:
		if game and game.sfx:
			game.sfx.play_error()
		return
	grenade_cooldown = GRENADE_COOLDOWN_TIME
	var gren = GrenadeEntity.new()
	var throw_dist = grenade_aim_distance if grenade_aiming else 150.0
	gren.setup(position, Vector2.from_angle(facing_angle), throw_dist, GRENADE_DAMAGE, self)
	game.projectile_container.add_child(gren)
	active_grenade_count += 1
	grenade_count -= 1
	squash_factor = 0.75  # Throw recoil
	# Wind-up lunge
	var throw_dir = Vector2.from_angle(facing_angle)
	game.particles.emit_directional(position.x + throw_dir.x * 15, position.y + throw_dir.y * 15, throw_dir, Color8(240, 160, 60), 6)
	if game.sfx:
		game.sfx.play_grenade_throw()

func on_grenade_removed():
	active_grenade_count = maxi(0, active_grenade_count - 1)

func _get_current_ranged_damage_mult() -> float:
	if weapon_configs.has(equipped_ranged_weapon):
		return float(weapon_configs[equipped_ranged_weapon].get("damage_mult", 1.0))
	return 1.0

func _equip_ranged_weapon(weapon_id: String):
	if not weapon_configs.has(weapon_id):
		weapon_id = "ak47"
	equipped_ranged_weapon = weapon_id
	ranged_charge_time = float(weapon_configs[weapon_id].get("charge_time", 0.0))
	ranged_charging = false
	ranged_charge_timer = 0.0
	ranged_charge_ready = false

func _update_dash_trail(delta: float):
	var i = dash_trail.size() - 1
	while i >= 0:
		dash_trail[i].alpha -= delta * 3.5
		if dash_trail[i].alpha <= 0:
			dash_trail.remove_at(i)
		i -= 1

func _update_timers(delta):
	if is_attacking_melee:
		melee_attack_timer -= delta
		if melee_attack_timer <= 0:
			is_attacking_melee = false
	invincibility_timer = maxf(0, invincibility_timer - delta)
	hit_flash_timer = maxf(0, hit_flash_timer - delta)

func take_damage(amount: int, game):
	if invincibility_timer > 0 or is_dead:
		return
	if dodge_chance > 0 and randf() < dodge_chance:
		game.spawn_damage_number(position, "DODGE", Color8(200, 200, 200))
		invincibility_timer = 0.15
		return
	# Block damage reduction
	if is_blocking:
		var is_perfect = block_hold_time <= BLOCK_PERFECT_WINDOW
		var reduction = BLOCK_PERFECT_REDUCTION if is_perfect else BLOCK_DAMAGE_REDUCTION
		amount = maxi(1, int(amount * (1.0 - reduction)))
		if is_perfect:
			# Perfect block: hitstop, flash, special feedback
			block_flash_timer = 0.3
			game.start_hitstop(0.08)
			game.spawn_damage_number(position, "PERFECT!", Color8(100, 200, 255))
			game.particles.emit_burst(position.x, position.y, Color8(100, 200, 255), 8)
			if game.sfx:
				game.sfx.play_block_perfect()
			invincibility_timer = 0.2
			squash_factor = 0.85
		else:
			game.spawn_damage_number(position, "BLOCKED", Color8(180, 200, 220))
			game.particles.emit_directional(position.x, position.y, Vector2.from_angle(facing_angle), Color8(180, 200, 220), 4)
			if game.sfx:
				game.sfx.play_block_hit()
			invincibility_timer = 0.1
			squash_factor = 0.9
		current_hp -= amount
		if current_hp <= 0:
			current_hp = 0
			is_dead = true
			visible = false
			game.check_all_players_dead()
		return
	current_hp -= amount
	hit_flash_timer = 0.12
	invincibility_timer = 0.35
	squash_factor = 0.6  # Trigger squash spring on hit
	if game.sfx:
		game.sfx.play_player_hurt()
	game.start_shake(6.0, 0.15)
	game.start_chromatic(3.0)
	if current_hp <= 0:
		current_hp = 0
		is_dead = true
		visible = false
		game.check_all_players_dead()

func heal(amount: int):
	current_hp = mini(current_hp + amount, max_hp)

func apply_skill(skill_id: String, game = null):
	match skill_id:
		"mellow_strength": melee_damage = int(melee_damage * 1.15)
		"eagle_eye": ranged_damage = int(ranged_damage * 1.15)
		"thick_skin":
			max_hp += 25
			current_hp += 25
		"speed_toke": move_speed *= 1.12
		"quick_hands": attack_cooldown_multiplier *= 0.85
		"chill_aura": ally_damage_multiplier *= 1.10
		"deep_pockets": gold_multiplier *= 1.25
		"barricade_guru": repair_speed *= 1.5
		"critical_hit": crit_chance += 0.08
		"cleave": max_melee_targets += 1
		"wider_swing": melee_arc *= 1.20
		"sniper_range": proj_speed_mult *= 1.25
		"lifesteal": lifesteal += 3
		"dodge": dodge_chance = minf(dodge_chance + 0.08, 0.5)
		"regen": regen_rate += 0.33  # +1 HP per 3 seconds
		"bounty_hunter": enemy_gold_mult *= 1.30
		"xp_boost": xp_mult *= 1.20
		"fortify":
			if game:
				for b in game.map.barricades:
					b.max_hp = int(b.max_hp * 1.15)
					b.current_hp = mini(b.current_hp + int(b.max_hp * 0.15), b.max_hp)
		"rally_cry":
			if game:
				for ally in game.ally_container.get_children():
					ally.max_hp = int(ally.max_hp * 1.20)
					ally.current_hp = mini(ally.current_hp + int(ally.max_hp * 0.20), ally.max_hp)
		"inspiring":
			if game:
				for ally in game.ally_container.get_children():
					ally.attack_cooldown *= 0.85
		"iron_lungs":
			max_hp += 15
			current_hp += 15
		"hustle": move_speed *= 1.08
		"lucky_coin":
			xp_mult *= 1.10
			gold_multiplier *= 1.10
		"recruiter":
			if game and game.unit_manager:
				game.unit_manager.max_units += 1
		"second_wind":
			max_hp += 20
			current_hp += 20
		"blood_pact": lifesteal += 2

# --- Visual juice helpers ---

func _update_squash(delta: float):
	var force = (1.0 - squash_factor) * 180.0
	squash_velocity += force * delta
	squash_velocity *= exp(-12.0 * delta)
	squash_factor += squash_velocity * delta
	squash_factor = clampf(squash_factor, 0.3, 1.8)  # Prevent extreme visual glitches

func _update_trail(delta: float):
	trail_timer += delta
	var is_active = is_moving and not is_dead
	if is_active and trail_timer >= 0.035:
		trail_timer = 0.0
		trail_history.push_front({"pos": position, "alpha": 0.25})
		if trail_history.size() > 3:
			trail_history.pop_back()
	var i = trail_history.size() - 1
	while i >= 0:
		trail_history[i].alpha -= delta * 4.0
		if trail_history[i].alpha <= 0.0:
			trail_history.remove_at(i)
		i -= 1

# --- Drawing (Brotato-style enhanced) ---

func _draw():
	# Blink when invincible (but not during dash)
	if invincibility_timer > 0 and not is_dashing and fmod(invincibility_timer, 0.12) < 0.06:
		return

	var flash = hit_flash_timer > 0

	# Draw dash afterimages first (behind everything)
	if dash_trail.size() > 0 and sprite_texture:
		var tex_size = sprite_texture.get_size()
		var ds = SPRITE_HEIGHT / tex_size.y
		for ghost in dash_trail:
			var ghost_offset = ghost.pos - position
			var g_flip = ghost.angle < -PI / 2.0 or ghost.angle > PI / 2.0
			var g_fs = -1.0 if g_flip else 1.0
			draw_set_transform(
				Vector2(ghost_offset.x, ghost_offset.y - tex_size.y * ds * 0.32),
				0, Vector2(ds * g_fs * 1.1, ds * 0.9)
			)
			draw_texture(sprite_texture, -tex_size / 2.0, Color(0.4, 0.7, 1.0, ghost.alpha))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Draw dinosaur mount (behind player)
	if has_dino_mount:
		_draw_dino_mount()

	# Sprint speed lines
	if is_sprinting and is_moving:
		var sprint_dir = -Vector2.from_angle(facing_angle)
		for si in range(4):
			var line_angle = facing_angle + PI + randf_range(-0.3, 0.3)
			var line_start = Vector2.from_angle(line_angle) * 20.0
			var line_end = line_start + Vector2.from_angle(line_angle) * 18.0
			var line_alpha = 0.2 + 0.15 * sin(walk_anim + si * 1.5)
			draw_line(line_start, line_end, Color(1.0, 1.0, 1.0, line_alpha), 1.5)

	# Enhanced shadow (bigger, more offset, pulsing with movement)
	var shadow_pulse = 1.0
	if is_dashing:
		shadow_pulse = 1.3
	elif is_moving:
		shadow_pulse = 1.0 + abs(sin(walk_anim)) * 0.12
	var shadow_w = 90.0 * shadow_pulse
	var shadow_h = 24.0 * shadow_pulse
	if has_dino_mount:
		shadow_w *= 1.4
		shadow_h *= 1.3
	_draw_shadow_ellipse(Rect2(-shadow_w / 2, 26, shadow_w, shadow_h), Color(0, 0, 0, 0.4))

	# Flip based on facing direction
	var flip = facing_angle < -PI / 2.0 or facing_angle > PI / 2.0
	var flip_sign = -1.0 if flip else 1.0
	var sprite_xform = Transform2D.IDENTITY

	# Current combo config (for animation)
	var active_combo = ((combo_index - 1) + COMBO_COUNT) % COMBO_COUNT if combo_window > 0 else 0

	# Draw sprite
	if sprite_texture:
		var tex_size = sprite_texture.get_size()
		var base_scale = SPRITE_HEIGHT / tex_size.y

		# --- Animations ---
		var offset_x = 0.0
		var offset_y = 0.0
		var tilt = 0.0
		var scale_x = base_scale
		var scale_y = base_scale

		if is_dashing:
			# Dash: extreme horizontal stretch, lean into direction
			var dash_t = dash_timer / DASH_DURATION
			offset_x = dash_direction.x * 8.0
			offset_y = dash_direction.y * 8.0 - 6.0
			tilt = dash_direction.angle() * 0.15
			scale_x = base_scale * 1.25
			scale_y = base_scale * 0.8
		elif is_blocking:
			# Block: hunch down, widen stance
			var block_breath = sin(block_hold_time * 6.0) * 0.02
			offset_y = 4.0  # Crouch down
			scale_x = base_scale * (1.1 + block_breath)
			scale_y = base_scale * (0.9 - block_breath)
			tilt = (facing_angle * 0.06) * flip_sign  # Slight lean into block direction
		elif is_attacking_melee:
			# Combo-dependent animation
			var cfg = COMBO_CONFIGS[active_combo]
			var attack_dur = cfg.duration
			var t = melee_attack_timer / attack_dur  # 1 -> 0
			var punch = sin(t * PI)

			match active_combo:
				0:  # Quick horizontal slash
					offset_x = cos(facing_angle) * punch * cfg.lunge
					offset_y = sin(facing_angle) * punch * cfg.lunge
					tilt = punch * 0.25 * flip_sign
					scale_x = base_scale * (1.0 + punch * 0.18)
					scale_y = base_scale * (1.0 - punch * 0.14)
				1:  # Upward thrust
					offset_x = cos(facing_angle) * punch * cfg.lunge
					offset_y = sin(facing_angle) * punch * cfg.lunge - punch * 10.0
					tilt = punch * -0.15 * flip_sign
					scale_x = base_scale * (1.0 - punch * 0.1)
					scale_y = base_scale * (1.0 + punch * 0.2)
				2:  # Heavy spin
					offset_x = cos(facing_angle) * punch * cfg.lunge
					offset_y = sin(facing_angle) * punch * cfg.lunge
					tilt = t * TAU * flip_sign * 0.6  # Spin!
					scale_x = base_scale * (1.0 + punch * 0.25)
					scale_y = base_scale * (1.0 + punch * 0.15)
		elif is_moving:
			# Walk: amplified rhythmic bob + lean + squash/stretch cycle
			var step = sin(walk_anim)
			var step2 = cos(walk_anim)
			offset_y = abs(step) * -8.0
			tilt = step * 0.10 * flip_sign
			scale_x = base_scale * (1.0 + step2 * 0.07)
			scale_y = base_scale * (1.0 - step2 * 0.07)
		else:
			# Idle: amplified breathing
			var breath = sin(idle_time * 2.0)
			scale_y = base_scale * (1.0 + breath * 0.04)
			scale_x = base_scale * (1.0 - breath * 0.025)

		# Apply spring squash factor
		scale_y *= squash_factor
		scale_x *= (2.0 - squash_factor)

		var draw_size_y = tex_size.y * base_scale
		var sprite_y = -draw_size_y * 0.32 + offset_y

		# Draw afterimage trails (body only, no weapons)
		for trail in trail_history:
			var trail_offset = trail.pos - position
			draw_set_transform(
				Vector2(trail_offset.x + offset_x, trail_offset.y + sprite_y),
				tilt,
				Vector2(scale_x * flip_sign, scale_y)
			)
			draw_texture(sprite_texture, -tex_size / 2.0, Color(0.3, 0.6, 1.0, trail.alpha))

		# Draw sprite outline (slightly larger, dark)
		var outline_bump = 1.05
		draw_set_transform(
			Vector2(offset_x, sprite_y),
			tilt,
			Vector2(scale_x * flip_sign * outline_bump, scale_y * outline_bump)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(0, 0, 0, 0.5))

		# Draw main sprite
		sprite_xform = Transform2D(tilt, Vector2(scale_x * flip_sign, scale_y), 0.0, Vector2(offset_x, sprite_y))
		draw_set_transform(Vector2(offset_x, sprite_y), tilt, Vector2(scale_x * flip_sign, scale_y))
		if flash:
			draw_texture(sprite_texture, -tex_size / 2.0, Color(4.0, 4.0, 4.0, 1.0))
		else:
			draw_texture(sprite_texture, -tex_size / 2.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Draw held weapon at anchor point
	if weapon_mode == "ranged":
		_draw_held_weapon(equipped_ranged_weapon, sprite_xform, flip)
	elif weapon_mode == "throwable":
		if not grenade_aiming:
			# Show gun holstered + grenade ready indicator (small grenade icon near hand)
			_draw_held_weapon(equipped_ranged_weapon, sprite_xform, flip)
			# Floating grenade-ready indicator
			if has_grenades and grenade_count > 0 and grenade_cooldown <= 0 and active_grenade_count < MAX_ACTIVE_GRENADES:
				var nade_bob = sin(idle_time * 3.0) * 3.0
				var nade_x = flip_sign * 22.0
				var nade_y = -35.0 + nade_bob
				draw_circle(Vector2(nade_x, nade_y), 5.5, Color8(55, 65, 50))
				draw_circle(Vector2(nade_x, nade_y), 4.0, Color8(80, 90, 70))
				draw_circle(Vector2(nade_x - 1, nade_y - 1), 1.5, Color8(120, 130, 110))
				# Fuse
				var spark_vis = fmod(idle_time * 10.0, 1.0) > 0.4
				if spark_vis:
					draw_circle(Vector2(nade_x, nade_y - 6), 2.0, Color8(255, 220, 50))
		# When aiming, grenade visual is drawn in _draw_grenade_aim_trajectory
	elif weapon_mode == "melee":
		var drew_melee = false
		for equip_id in owned_equipment:
			if weapon_configs.has(equip_id) and equip_id != "heavy_revolver":
				_draw_held_weapon(equip_id, sprite_xform, flip)
				drew_melee = true
		if not drew_melee:
			pass  # Default fists

	# Ranged aim line (subtle dotted line when in ranged mode)
	if weapon_mode == "ranged" and not is_attacking_melee and not is_blocking and not is_dashing:
		var aim_dir = Vector2.from_angle(facing_angle)
		var line_len = 180.0
		var dot_count = 8
		for di in range(dot_count):
			var frac = float(di) / float(dot_count)
			var dot_pos = aim_dir * (40.0 + frac * line_len)
			var dot_alpha = 0.2 * (1.0 - frac)
			draw_circle(dot_pos, 1.5, Color(1.0, 0.9, 0.5, dot_alpha))

	# Grenade aiming trajectory (when holding attack in throwable mode)
	if weapon_mode == "throwable" and not is_dashing and not is_blocking:
		if grenade_aiming:
			_draw_grenade_aim_trajectory()
		elif not grenade_aiming and has_grenades and grenade_count > 0:
			# Show subtle throw direction hint when in throwable mode
			var aim_dir = Vector2.from_angle(facing_angle)
			for di in range(4):
				var frac = float(di) / 4.0
				var dot_pos = aim_dir * (30.0 + frac * 60.0)
				var dot_alpha = 0.12 * (1.0 - frac)
				draw_circle(dot_pos, 2.0, Color(1.0, 0.65, 0.2, dot_alpha))

	# Ranged charge visual (Heavy Revolver charge ring)
	if ranged_charging and ranged_charge_time > 0:
		var charge_frac = clampf(ranged_charge_timer / ranged_charge_time, 0.0, 1.0)
		var ring_radius = 36.0
		var ring_col = Color(1.0, 0.85, 0.3, 0.6) if not ranged_charge_ready else Color(1.0, 0.4, 0.2, 0.8)
		# Draw charge arc
		var charge_arc = TAU * charge_frac
		draw_arc(Vector2.ZERO, ring_radius, -PI / 2.0, -PI / 2.0 + charge_arc, 20, ring_col, 3.0)
		# Inner glow when charging
		var glow_alpha = charge_frac * 0.2
		draw_circle(Vector2.ZERO, ring_radius * 0.6, Color(1.0, 0.8, 0.3, glow_alpha))
		# Ready flash
		if ranged_charge_ready:
			var pulse = 0.5 + 0.5 * sin(idle_time * 12.0)
			draw_circle(Vector2.ZERO, ring_radius + 4.0, Color(1.0, 0.5, 0.2, pulse * 0.3))
			draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 20, Color(1.0, 0.4, 0.1, pulse * 0.6), 2.0)

	# Persistent melee range indicator (subtle arc when in melee mode, not attacking)
	if weapon_mode == "melee" and not is_attacking_melee and not is_blocking and not is_dashing and not is_repairing:
		var range_arc = melee_arc
		var range_dist = melee_range
		var half_arc = range_arc / 2.0
		var range_start = facing_angle - half_arc
		var range_segments = 16
		# Pulsing alpha
		var range_alpha = 0.08 + 0.05 * sin(idle_time * 2.5)
		# Combo preview color
		var next_combo = combo_index if combo_window > 0 else 0
		var preview_colors = [Color(1.0, 0.85, 0.4), Color(0.4, 0.85, 1.0), Color(1.0, 0.3, 0.15)]
		var range_col = preview_colors[next_combo]
		# Dashed arc segments
		var prev_pt = Vector2.from_angle(range_start) * range_dist
		for si in range(1, range_segments + 1):
			var seg_angle = range_start + (range_arc * float(si) / float(range_segments))
			var seg_pt = Vector2.from_angle(seg_angle) * range_dist
			# Draw every other segment for dashed effect
			if si % 2 == 0:
				draw_line(prev_pt, seg_pt, Color(range_col.r, range_col.g, range_col.b, range_alpha), 1.5)
			prev_pt = seg_pt
		# Inner thin arc for "filled range" feeling
		var inner_alpha = range_alpha * 0.4
		for si in range(range_segments):
			var a1 = range_start + (range_arc * float(si) / float(range_segments))
			var a2 = range_start + (range_arc * float(si + 1) / float(range_segments))
			var inner1 = Vector2.from_angle(a1) * (range_dist * 0.7)
			var outer1 = Vector2.from_angle(a1) * range_dist
			var inner2 = Vector2.from_angle(a2) * (range_dist * 0.7)
			var outer2 = Vector2.from_angle(a2) * range_dist
			draw_colored_polygon(PackedVector2Array([inner1, outer1, outer2, inner2]), Color(range_col.r, range_col.g, range_col.b, inner_alpha))

	# Melee arc visual (combo-colored)
	if is_attacking_melee:
		_draw_melee_arc(active_combo)

	# Grapple line visual
	if is_grappling:
		var line_end_world = grapple_target - position
		var line_end = line_end_world * grapple_line_progress
		var line_len = line_end.length()
		# Main grapple line with rope-physics sine wave
		var line_segments = int(maxf(8, line_len / 12.0))
		var perp = Vector2(-line_end.normalized().y, line_end.normalized().x)
		var prev_seg = Vector2.ZERO
		var wave_amp = 6.0 * (1.0 - grapple_line_progress) if not grapple_pull_started else 2.0
		for seg_i in range(1, line_segments + 1):
			var frac = float(seg_i) / float(line_segments)
			var base_pt = line_end * frac
			var wave = sin(frac * PI * 3.0 + idle_time * 20.0) * wave_amp * (1.0 - frac)
			var seg_pt = base_pt + perp * wave
			var seg_alpha = 0.8 - frac * 0.3
			# Glow line
			draw_line(prev_seg, seg_pt, Color(0.4, 0.8, 1.0, seg_alpha * 0.4), 5.0)
			# Core line
			draw_line(prev_seg, seg_pt, Color(0.7, 0.9, 1.0, seg_alpha), 2.5)
			prev_seg = seg_pt
		# Grapple hook at end
		if grapple_line_progress > 0.5:
			draw_circle(line_end, 5.0, Color(0.5, 0.8, 1.0, 0.8))
			draw_circle(line_end, 5.0, Color(0.3, 0.6, 0.9, 0.6), false, 2.0)

	# Grapple device on player (left hand)
	if grapple_texture:
		var grap_tex_size = grapple_texture.get_size()
		var grap_scale = 36.0 / maxf(grap_tex_size.y, 1.0)
		var grap_anchor = Vector2(-18, -5)  # Left hand approximate
		var grap_rot = 0.0
		if is_grappling:
			grap_rot = (grapple_target - position).angle()
			var grap_col = Color(0.8, 0.95, 1.0, 1.0)  # Activated glow
			draw_set_transform(grap_anchor, grap_rot, Vector2(grap_scale, grap_scale))
			draw_texture(grapple_texture, -grap_tex_size / 2.0, grap_col)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		else:
			# Stale/inactive appearance
			draw_set_transform(grap_anchor, -0.3, Vector2(grap_scale, grap_scale))
			draw_texture(grapple_texture, -grap_tex_size / 2.0, Color(0.7, 0.7, 0.7, 0.6))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Grapple cooldown indicator
	if grapple_cooldown > 0 and not is_grappling:
		var grap_cd_frac = grapple_cooldown / GRAPPLE_COOLDOWN_TIME
		draw_arc(Vector2(-18, 8), 12.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - grap_cd_frac), 10, Color8(100, 200, 255, 60), 2.0)

	# Dash cooldown indicator
	if dash_cooldown > 0 and not is_dashing:
		var cd_frac = dash_cooldown / DASH_COOLDOWN_TIME
		draw_arc(Vector2.ZERO, 32.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - cd_frac), 16, Color8(100, 180, 255, 80), 2.0)

	# Combo indicator dots
	if weapon_mode == "melee" and not is_dashing:
		var dot_y = 42.0
		for i in range(COMBO_COUNT):
			var dot_x = -8.0 + i * 10.0
			var prev_combo = (combo_index - 1) % COMBO_COUNT if combo_window > 0 else -1
			var dot_col: Color
			if i <= prev_combo and combo_window > 0:
				dot_col = [Color8(255, 220, 100), Color8(255, 160, 50), Color8(255, 80, 30)][i]
			else:
				dot_col = Color8(80, 80, 80, 120)
			draw_circle(Vector2(dot_x, dot_y), 3.0, dot_col)

	# Block visual
	if is_blocking:
		# Shield arc in facing direction
		var shield_radius = 38.0
		var shield_arc = 1.8
		var shield_start = facing_angle - shield_arc / 2.0
		var segments = 10
		var is_perfect = block_hold_time <= BLOCK_PERFECT_WINDOW
		var shield_alpha = 0.6 if is_perfect else 0.35
		var shield_col = Color(0.4, 0.8, 1.0, shield_alpha) if is_perfect else Color(0.6, 0.7, 0.8, shield_alpha)
		# Filled shield segments
		for i in range(segments):
			var a1 = shield_start + (shield_arc * float(i) / float(segments))
			var a2 = shield_start + (shield_arc * float(i + 1) / float(segments))
			var inner1 = Vector2.from_angle(a1) * 20.0
			var inner2 = Vector2.from_angle(a2) * 20.0
			var outer1 = Vector2.from_angle(a1) * shield_radius
			var outer2 = Vector2.from_angle(a2) * shield_radius
			var seg_alpha = shield_alpha * (1.0 - float(i) / float(segments) * 0.4)
			draw_colored_polygon(PackedVector2Array([inner1, outer1, outer2, inner2]), Color(shield_col.r, shield_col.g, shield_col.b, seg_alpha))
		# Shield edge glow
		var prev_pt = Vector2.from_angle(shield_start) * shield_radius
		for i in range(1, segments + 1):
			var angle = shield_start + (shield_arc * float(i) / float(segments))
			var point = Vector2.from_angle(angle) * shield_radius
			var line_col = Color(0.5, 0.9, 1.0, 0.8) if is_perfect else Color(0.7, 0.8, 0.9, 0.5)
			draw_line(prev_pt, point, line_col, 3.0 if is_perfect else 2.0)
			prev_pt = point
		# Perfect block flash
		if block_flash_timer > 0:
			var flash_alpha = block_flash_timer / 0.3
			draw_circle(Vector2.ZERO, 50.0, Color(0.5, 0.9, 1.0, flash_alpha * 0.3))
		# Block stamina arc (below player)
		var stamina_frac = block_stamina / BLOCK_MAX_STAMINA
		var stam_col = Color8(100, 200, 255, 100) if stamina_frac > 0.3 else Color8(255, 150, 80, 120)
		draw_arc(Vector2(0, 38), 18.0, PI * 0.15, PI * 0.15 + PI * 0.7 * stamina_frac, 10, stam_col, 2.5)

	# Block cooldown indicator
	if block_cooldown > 0 and not is_blocking:
		var cd_frac = block_cooldown / BLOCK_COOLDOWN_TIME
		draw_arc(Vector2(0, 38), 18.0, PI * 0.15, PI * 0.15 + PI * 0.7 * (1.0 - cd_frac), 10, Color8(255, 100, 80, 80), 2.0)

	# Repair indicator with hammer animation
	if is_repairing:
		draw_arc(Vector2.ZERO, 42.0, 0, TAU, 20, Color8(100, 220, 255, 80), 2.0)
		# Draw hammer at right hand, swinging
		if hammer_texture:
			var ham_tex_size = hammer_texture.get_size()
			var ham_scale = 50.0 / ham_tex_size.y
			# Swing arc: oscillate rotation
			var swing_angle = sin(repair_anim_time * 10.0) * 0.5
			var ham_pos = Vector2(18, -10)  # Right hand offset
			# Slight body bob synced to hammer
			var bob_offset = abs(sin(repair_anim_time * 10.0)) * -3.0
			draw_set_transform(Vector2(ham_pos.x, ham_pos.y + bob_offset), swing_angle - 0.3, Vector2(ham_scale, ham_scale))
			draw_texture(hammer_texture, -ham_tex_size / 2.0)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var rfont = ThemeDB.fallback_font
		draw_string(rfont, Vector2(-36, -55), "REPAIRING", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color8(100, 220, 255))

	# Weapon mode indicator (polished pill-shaped badge)
	var font = ThemeDB.fallback_font
	var mode_text = "SWORD"
	var mode_col = Color8(220, 180, 100)
	var mode_bg = Color8(60, 50, 30, 160)
	match weapon_mode:
		"ranged":
			mode_text = "GUN"
			mode_col = Color8(100, 200, 255)
			mode_bg = Color8(20, 40, 60, 160)
		"throwable":
			mode_text = "GRENADE"
			mode_col = Color8(240, 160, 60)
			mode_bg = Color8(60, 35, 15, 160)
	# Badge background
	var badge_w = 58.0
	var badge_h = 16.0
	var badge_x = -badge_w / 2.0
	var badge_y = 44.0
	draw_rect(Rect2(badge_x, badge_y, badge_w, badge_h), mode_bg)
	draw_rect(Rect2(badge_x, badge_y, badge_w, badge_h), Color(mode_col.r, mode_col.g, mode_col.b, 0.4), false, 1.0)
	draw_string(font, Vector2(badge_x + 3, badge_y + 12), mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, mode_col)

	# Grenade count when in throwable mode
	if weapon_mode == "throwable" and has_grenades and grenade_count >= 0:
		var nade_count = grenade_count
		var nade_text = "%d" % nade_count
		var nade_x = badge_x + badge_w + 4
		var nade_col = Color8(255, 200, 80) if nade_count > 0 else Color8(160, 80, 80)
		draw_circle(Vector2(nade_x + 6, badge_y + 8), 8.0, Color(0, 0, 0, 0.5))
		draw_string(font, Vector2(nade_x + 2, badge_y + 12), nade_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, nade_col)
		# Cooldown arc
		if grenade_cooldown > 0:
			var cd_frac = grenade_cooldown / GRENADE_COOLDOWN_TIME
			draw_arc(Vector2(nade_x + 6, badge_y + 8), 9.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - cd_frac), 10, Color8(240, 140, 60, 120), 2.0)

	# Sprint indicator (speed lines icon)
	if is_sprinting:
		var sprint_alpha = 0.6 + 0.3 * sin(walk_anim * 2.0)
		draw_string(font, Vector2(-22, -58), "SPRINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.4, sprint_alpha))

	# Block indicator
	if block_stamina < BLOCK_MAX_STAMINA or block_cooldown > 0:
		var block_col = Color8(100, 200, 255, 150) if block_cooldown <= 0 else Color8(120, 100, 80, 100)
		draw_string(font, Vector2(-22, 64), "BLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, block_col)

func _draw_grenade_aim_trajectory():
	"""Draw a parabolic arc preview showing where the grenade will land."""
	var aim_dir = Vector2.from_angle(facing_angle)
	var dist = grenade_aim_distance
	var arc_height = 80.0
	var segments = 16
	var pulse = sin(grenade_aim_pulse * 5.0) * 0.15 + 0.85

	# Draw trajectory arc (dotted parabolic path)
	var prev_pt = Vector2.ZERO
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var ground_pos = aim_dir * dist * t
		var height = arc_height * 4.0 * t * (1.0 - t)
		var arc_pt = Vector2(ground_pos.x, ground_pos.y - height)
		if i > 0:
			# Alternating dash pattern
			if i % 2 == 0:
				var seg_alpha = 0.5 * (1.0 - t * 0.5) * pulse
				draw_line(prev_pt, arc_pt, Color(1.0, 0.7, 0.25, seg_alpha), 2.0)
			# Dots at each segment for visual clarity
			draw_circle(arc_pt, 1.5, Color(1.0, 0.65, 0.2, 0.3 * pulse))
		prev_pt = arc_pt

	# Landing zone circle (pulsing)
	var landing_pos = aim_dir * dist
	var blast_r = 80.0
	var ring_alpha = 0.2 + 0.1 * sin(grenade_aim_pulse * 6.0)
	# Outer danger zone
	draw_arc(landing_pos, blast_r, 0, TAU, 24, Color(1.0, 0.35, 0.15, ring_alpha), 1.5)
	# Inner solid circle
	draw_circle(landing_pos, 6.0 * pulse, Color(1.0, 0.5, 0.2, 0.4 * pulse))
	# Crosshair
	var cross_size = 8.0 * pulse
	draw_line(landing_pos + Vector2(-cross_size, 0), landing_pos + Vector2(cross_size, 0), Color(1.0, 0.7, 0.3, 0.5), 1.5)
	draw_line(landing_pos + Vector2(0, -cross_size), landing_pos + Vector2(0, cross_size), Color(1.0, 0.7, 0.3, 0.5), 1.5)

	# Distance indicator text
	var dist_text = "%dm" % int(dist / 10.0)
	var tfont = ThemeDB.fallback_font
	draw_string(tfont, landing_pos + Vector2(-10, -14), dist_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.8, 0.4, 0.7 * pulse))

	# Grenade held visual (grenade in hand)
	var hand_pos = aim_dir * 22.0 + Vector2(0, -8)
	draw_circle(hand_pos, 6.0, Color8(70, 80, 65))
	draw_circle(hand_pos, 4.5, Color8(90, 100, 80))
	draw_circle(hand_pos + Vector2(-1.5, -1.5), 1.5, Color8(130, 140, 120))
	# Fuse spark
	var spark_on = fmod(grenade_aim_pulse * 15.0, 1.0) > 0.35
	if spark_on:
		draw_circle(hand_pos + Vector2(0, -7), 2.5, Color8(255, 220, 50))
		draw_circle(hand_pos + Vector2(0, -7), 1.0, Color.WHITE)

func _draw_held_weapon(weapon_id: String, sprite_xform: Transform2D, is_flipped: bool):
	if not weapon_configs.has(weapon_id): return
	var cfg = weapon_configs[weapon_id]
	var tex: Texture2D = cfg.texture
	if not tex: return
	var slot: String = cfg.slot
	if not SPRITE_ANCHORS.has(slot): return
	# Compute world position of anchor point on the sprite
	var anchor_pos = sprite_xform * SPRITE_ANCHORS[slot]
	var tex_size = tex.get_size()
	var wep_scale = cfg.height / tex_size.y
	var rot = facing_angle + cfg.get("rotation_offset", 0.0)
	var flip_y = -1.0 if is_flipped else 1.0
	# Grip point: where the hand holds the weapon (fraction of texture size)
	var grip = Vector2(tex_size.x * cfg.grip.x, tex_size.y * cfg.grip.y)
	draw_set_transform(anchor_pos, rot, Vector2(wep_scale, wep_scale * flip_y))
	draw_texture(tex, -grip)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_melee_arc(current_combo: int = 0):
	var cfg = COMBO_CONFIGS[current_combo]
	var arc = melee_arc * cfg.arc_mult
	var segments = 12
	var half_arc = arc / 2.0

	# Combo 2 (spin): rotate the arc based on attack timer
	var angle_offset = 0.0
	if current_combo == 2 and is_attacking_melee:
		var spin_t = 1.0 - (melee_attack_timer / cfg.duration)
		angle_offset = spin_t * TAU * 0.8

	var start_angle = facing_angle - half_arc + angle_offset

	# Combo-specific colors
	var arc_colors = [
		Color(1.0, 0.85, 0.4),    # Hit 1: golden
		Color(0.4, 0.85, 1.0),    # Hit 2: blue thrust
		Color(1.0, 0.3, 0.15),    # Hit 3: red spin
	]
	var col = arc_colors[current_combo]

	for i in range(segments):
		var a1 = start_angle + (arc * float(i) / float(segments))
		var a2 = start_angle + (arc * float(i + 1) / float(segments))
		var p1 = Vector2.from_angle(a1) * melee_range
		var p2 = Vector2.from_angle(a2) * melee_range
		var inner1 = Vector2.from_angle(a1) * 16
		var inner2 = Vector2.from_angle(a2) * 16
		var alpha = 0.4 - 0.25 * (float(i) / float(segments))
		draw_colored_polygon(PackedVector2Array([inner1, p1, p2, inner2]), Color(col.r, col.g, col.b, alpha))
	var prev_pt = Vector2.from_angle(start_angle) * melee_range
	for i in range(1, segments + 1):
		var angle = start_angle + (arc * float(i) / float(segments))
		var point = Vector2.from_angle(angle) * melee_range
		draw_line(prev_pt, point, Color(col.r, col.g, col.b, 0.7), 2.5 + current_combo * 0.5)
		prev_pt = point

func _draw_dino_mount():
	"""Draw a cartoony animated dinosaur mount around the player."""
	var flip = facing_angle < -PI / 2.0 or facing_angle > PI / 2.0
	var fs = -1.0 if flip else 1.0
	var t = dino_anim_time

	# Bobbing motion
	var bob = sin(t * 6.0) * 4.0 if is_moving else sin(t * 2.0) * 1.5
	var lean = sin(t * 6.0) * 0.08 if is_moving else 0.0
	var run_stretch_x = 1.0 + abs(sin(t * 6.0)) * 0.06 if is_moving else 1.0
	var run_stretch_y = 1.0 - abs(sin(t * 6.0)) * 0.06 if is_moving else 1.0

	# Colors - bright green cartoony dino
	var body_col = Color8(80, 200, 80)
	var belly_col = Color8(160, 230, 120)
	var spot_col = Color8(50, 150, 50)
	var eye_col = Color.WHITE
	var pupil_col = Color.BLACK

	# Body (large oval behind player)
	var body_cx = fs * -5.0
	var body_cy = 8.0 + bob
	var body_w = 48.0 * run_stretch_x
	var body_h = 30.0 * run_stretch_y
	_draw_oval(Vector2(body_cx, body_cy), body_w, body_h, lean, body_col)
	# Belly lighter stripe
	_draw_oval(Vector2(body_cx, body_cy + 4), body_w * 0.65, body_h * 0.5, lean, belly_col)

	# Back spots
	for si in range(3):
		var sx = body_cx + fs * (-14.0 + si * 12.0)
		var sy = body_cy - 8.0 + sin(t * 2.0 + si) * 1.5
		draw_circle(Vector2(sx, sy), 3.5, spot_col)

	# Tail (wavy behind)
	var tail_base_x = body_cx + fs * -28.0
	var tail_wave = sin(t * 5.0) * 8.0
	var tail_pts = PackedVector2Array()
	for ti in range(6):
		var frac = float(ti) / 5.0
		var tx = tail_base_x + fs * (-frac * 35.0)
		var ty = body_cy + tail_wave * frac + frac * frac * 8.0
		var tw = 8.0 * (1.0 - frac * 0.7)
		tail_pts.append(Vector2(tx, ty - tw))
	for ti in range(5, -1, -1):
		var frac = float(ti) / 5.0
		var tx = tail_base_x + fs * (-frac * 35.0)
		var ty = body_cy + tail_wave * frac + frac * frac * 8.0
		var tw = 8.0 * (1.0 - frac * 0.7)
		tail_pts.append(Vector2(tx, ty + tw))
	if tail_pts.size() >= 3:
		draw_colored_polygon(tail_pts, body_col)
	# Tail tip spot
	var tip_x = tail_base_x + fs * -30.0
	var tip_y = body_cy + tail_wave + 5.0
	draw_circle(Vector2(tip_x, tip_y), 3.0, spot_col)

	# Head
	var head_x = body_cx + fs * 32.0
	var head_y = body_cy - 10.0 + bob * 0.5
	var head_bob = sin(t * 4.0) * 2.0 if is_moving else 0.0
	head_y += head_bob
	_draw_oval(Vector2(head_x, head_y), 22.0, 18.0, lean * 0.5, body_col)
	# Snout
	var snout_x = head_x + fs * 14.0
	var snout_y = head_y + 2.0
	_draw_oval(Vector2(snout_x, snout_y), 14.0, 10.0, 0.0, body_col)
	# Nostril
	draw_circle(Vector2(snout_x + fs * 6.0, snout_y - 1.0), 2.0, spot_col)
	# Mouth line
	var mouth_start = Vector2(snout_x + fs * 4.0, snout_y + 4.0)
	var mouth_end = Vector2(snout_x - fs * 4.0, snout_y + 5.0)
	draw_line(mouth_start, mouth_end, spot_col, 1.5)
	# Eye
	var eye_x = head_x + fs * 8.0
	var eye_y = head_y - 4.0
	draw_circle(Vector2(eye_x, eye_y), 5.0, eye_col)
	draw_circle(Vector2(eye_x + fs * 1.5, eye_y), 2.5, pupil_col)
	# Eye highlight
	draw_circle(Vector2(eye_x + fs * 3.0, eye_y - 2.0), 1.5, Color(1, 1, 1, 0.8))

	# Small head spikes/crest
	for ci in range(3):
		var spike_x = head_x + fs * (-4.0 + ci * 5.0)
		var spike_y = head_y - 10.0 - ci * 1.5
		var spike_base_y = head_y - 5.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(spike_x - 2.5, spike_base_y),
			Vector2(spike_x, spike_y + sin(t * 3.0 + ci) * 1.0),
			Vector2(spike_x + 2.5, spike_base_y),
		]), Color8(255, 140, 60))

	# Legs (animated running)
	var leg_offsets = [-16.0, -6.0, 6.0, 16.0]
	for li in range(4):
		var lx = body_cx + fs * leg_offsets[li]
		var ly = body_cy + 14.0
		var leg_phase = t * 8.0 + li * PI * 0.5
		var leg_swing = sin(leg_phase) * 8.0 if is_moving else 0.0
		var foot_y = ly + 12.0
		# Upper leg
		draw_line(Vector2(lx, ly), Vector2(lx + leg_swing * 0.4, foot_y - abs(leg_swing) * 0.3), body_col, 4.0)
		# Foot
		var foot_x = lx + leg_swing * 0.5
		draw_circle(Vector2(foot_x, foot_y - abs(leg_swing) * 0.3), 3.5, body_col)
		# Toe nails
		draw_circle(Vector2(foot_x + fs * 2.5, foot_y - abs(leg_swing) * 0.3 + 1.0), 1.5, Color8(220, 200, 150))

func _draw_oval(center: Vector2, w: float, h: float, rot: float, col: Color):
	var pts = PackedVector2Array()
	for i in range(16):
		var angle = TAU * i / 16.0
		var pt = Vector2(cos(angle) * w / 2.0, sin(angle) * h / 2.0)
		pt = pt.rotated(rot)
		pts.append(center + pt)
	draw_colored_polygon(pts, col)

func _draw_shadow_ellipse(rect: Rect2, color: Color):
	var center = rect.position + rect.size / 2
	var points = PackedVector2Array()
	for i in range(16):
		var angle = TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * rect.size.x / 2, sin(angle) * rect.size.y / 2))
	draw_colored_polygon(points, color)
