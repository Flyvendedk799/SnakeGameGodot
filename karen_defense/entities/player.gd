@tool
class_name PlayerEntity
extends Node2D

# Multiplayer config
var game = null  # Reference to main game node
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
var key_count: int = 0

# Temporary buffs (checkpoint shop consumables)
var temp_damage_mult: float = 1.0
var temp_damage_timer: float = 0.0
var temp_speed_mult: float = 1.0
var temp_speed_timer: float = 0.0
var has_extra_life: bool = false

# Skins / Cosmetics
var selected_skin: String = "default"
const SKIN_TINTS = {
	"default": Color(1, 1, 1),
	"golden": Color(1.0, 0.85, 0.3),
	"shadow": Color(0.3, 0.2, 0.4),
	"frost": Color(0.6, 0.85, 1.0),
	"fire": Color(1.0, 0.5, 0.2),
	"neon": Color(0.3, 1.0, 0.5),
	"royal": Color(0.6, 0.3, 0.9),
	"chrome": Color(0.85, 0.85, 0.9),
}

# Melee attack phases (anticipation / strike / recovery)
var melee_attack_phase: String = "none"
var melee_phase_timer: float = 0.0
const ANTICIPATION_DURATION: float = 0.06
const RECOVERY_DURATION: float = 0.08

# Side-view physics (Main Game beat-em-up mode)
var in_sideview_mode: bool = false
var velocity: Vector2 = Vector2.ZERO
var is_on_ground: bool = false
var was_on_ground: bool = false
var drop_through_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
# AAA Upgrade: Additional input buffers
var dash_buffer_timer: float = 0.0
var grapple_buffer_timer: float = 0.0
const GRAVITY = 900.0
const JUMP_FORCE = -380.0
const DROP_THROUGH_DURATION = 0.2
const COYOTE_TIME: float = 0.18  # Phase 6.3: Extended for more forgiving grapple-to-jump
const JUMP_BUFFER_TIME: float = 0.22  # Phase 6.3: Extended buffer window
const AIR_CONTROL_MULT: float = 0.96  # AAA Upgrade: Increased for snappier mid-air control

# Double jump
var air_jump_count: int = 0
var max_air_jumps: int = 1
var has_double_jump: bool = true

# Air dash
var has_air_dash: bool = true
var air_dash_used: bool = false

# Wall jump / wall slide
var has_wall_jump: bool = true
var is_wall_sliding: bool = false
var wall_slide_dir: int = 0
const WALL_SLIDE_SPEED: float = 45.0  # AAA Upgrade: Slower for more control
const WALL_JUMP_FORCE_X: float = 280.0  # AAA Upgrade: More horizontal boost
const WALL_JUMP_FORCE_Y: float = -350.0
var wall_jump_lockout: float = 0.0
# AAA Upgrade: Wall jump chain and cling system
var wall_jump_chain_timer: float = 0.0
var wall_cling_timer: float = 0.0
const WALL_CLING_MAX: float = 0.5

# AAA Upgrade: Momentum system
var horizontal_momentum: float = 0.0
var slide_timer: float = 0.0
const SLIDE_DURATION = 0.2
const SPRINT_JUMP_BOOST = 1.15

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

# Parry / Counter system
var parry_window_timer: float = 0.0
var parry_counter_active: bool = false
var parry_counter_timer: float = 0.0
var parry_target: Node2D = null
const PARRY_WINDOW: float = 0.1
const PARRY_COUNTER_DURATION: float = 0.25
const PARRY_COUNTER_DAMAGE_MULT: float = 3.0
const PARRY_INVINCIBILITY: float = 0.4

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
# Phase 4.4: Node-based afterimage trail system
var dash_afterimage = null
# AAA Upgrade: Momentum-based dash
var current_dash_speed: float = DASH_SPEED
var enemies_dashed_through: int = 0

# AAA Upgrade: Ground pound mechanic
var is_ground_pounding: bool = false
const GROUND_POUND_VELOCITY: float = 800.0
const GROUND_POUND_AOE: float = 120.0
const GROUND_POUND_DAMAGE_MULT: float = 2.5

# Combo state
var combo_index: int = 0  # 0, 1, 2 for the 3-hit combo
var combo_window: float = 0.0  # Time left to input next combo hit
const COMBO_WINDOW_TIME = 0.6  # Slightly more forgiving combo window
const COMBO_COUNT = 3
# Per-combo-hit configs: {duration, damage_mult, arc_mult, lunge, squash, hitstop}
# CARTOON: Exaggerated anticipation, strike, and recovery for weight
const COMBO_CONFIGS = [
	{"duration": 0.14, "damage_mult": 1.0, "arc_mult": 1.0, "lunge": 28.0, "squash": 1.45, "hitstop": 0.008},
	{"duration": 0.18, "damage_mult": 1.35, "arc_mult": 0.85, "lunge": 34.0, "squash": 1.55, "hitstop": 0.022},
	{"duration": 0.26, "damage_mult": 1.7, "arc_mult": 1.6, "lunge": 20.0, "squash": 0.42, "hitstop": 0.065},
]

# Input buffering for responsive combat
var attack_buffered: bool = false  # Buffer the next attack press during current attack animation
var attack_buffer_timer: float = 0.0
const ATTACK_BUFFER_WINDOW = 0.22  # AAA Upgrade: 220ms input buffer for more responsive combat

# AAA Upgrade: Attack canceling system
var last_hit_landed_time: float = 0.0
const CANCEL_WINDOW: float = 0.12

# AAA Upgrade: Combo visual trails
var combo_visual_trails: Array = []  # {type, pos, timer, color, angle}

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
var grapple_swing_mode: bool = false  # True = pendulum swing, false = pull
var grapple_rope_length: float = 0.0   # For swing: distance to anchor when attached
var grapple_swing_angle: float = 0.0  # Pendulum angle (0 = straight down)
var grapple_swing_velocity: float = 0.0  # Angular velocity (rad/s)
var grapple_is_chain_link: bool = false  # Chain links use swing, anchors can pull
const GRAPPLE_RANGE = 350.0
const GRAPPLE_SPEED = 800.0
const GRAPPLE_COOLDOWN_TIME = 1.5
const GRAPPLE_LINE_SPEED = 10.0  # How fast the line extends (0->1 in 0.1s)
const GRAPPLE_CONE = 1.2  # Radians, ~70 deg half-cone for target detection
const GRAPPLE_CHAIN_CONE = 3.0  # Wider cone for chain links (recovery from pits)

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

# AAA Visual Overhaul: Shader-capable rendering (Main Game only)
var character_visual: CharacterVisual = null
var _use_shader_visual: bool = false
# AAA Animation System
var sprite_animator: SpriteAnimator = null
var animation_frames_loaded: bool = false

# Sprite
var sprite_texture: Texture2D = null
var hammer_texture: Texture2D = null
var grapple_texture: Texture2D = null
const SPRITE_HEIGHT = 150.0
## Pixels of empty space below the character's feet in the texture. Tune in Inspector if feet float.
@export_range(0.0, 800.0, 10.0) var sprite_feet_padding: float = 500.0  # Empty pixels below feet in sprite texture

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
var impact_rings: Array = []  # {offset, radius, color, width, timer, max_timer}
var melee_slash_trails: Array = []  # {offset, color, scale, timer}
var landing_dust_timer: float = 0.0
var wall_slide_sparks: Array = []

# AAA Animation upgrade - enhanced animation states
var landing_recovery_timer: float = 0.0
var landing_target_squash: float = 1.0
var jump_state: String = "none"  # "anticipation", "launch", "apex", "fall"
var jump_phase_timer: float = 0.0
var jump_queued: bool = false  # Queue jump during anticipation
# Note: melee_attack_phase and melee_phase_timer already declared at lines 57-58

# AAA Upgrade: Procedural animation system
var cape_trail_points: Array[Vector2] = []  # Spring physics trail
var weapon_offset: Vector2 = Vector2.ZERO  # Weapon follows action with lag
var weapon_rotation: float = 0.0  # Weapon rotation for attacks
var limb_foot_l: Vector2 = Vector2.ZERO  # Left foot IK position
var limb_foot_r: Vector2 = Vector2.ZERO  # Right foot IK position
var anticipation_timer: float = 0.0  # Wind-up before major actions

func _ready():
	if player_index == 1:
		sprite_texture = load("res://assets/player2.png")
	else:
		sprite_texture = load("res://assets/WilliamPlayer.png")
	hammer_texture = load("res://assets/hammer.png")
	grapple_texture = load("res://assets/grapple.png")
	# Phase 4.4: Create dash afterimage trail node
	if ClassDB.class_exists("DashAfterimage"):
		dash_afterimage = DashAfterimage.new()
		dash_afterimage.name = "DashAfterimage"
		add_child(dash_afterimage)
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
	# Temporary buffs
	if effects.has("temp_damage"):
		temp_damage_mult = float(effects.temp_damage)
		temp_damage_timer = float(effects.get("temp_duration", 30.0))
	if effects.has("temp_speed"):
		temp_speed_mult = float(effects.temp_speed)
		temp_speed_timer = float(effects.get("temp_duration", 30.0))
	if effects.has("extra_life"):
		has_extra_life = true
	if effects.has("grant_key"):
		key_count += 1
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
	grapple_swing_mode = false
	grapple_is_chain_link = false
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
	in_sideview_mode = _is_main_game_sideview(game)
	# AAA Visual Overhaul: Initialize shader visual on first update (game now available)
	if in_sideview_mode and not _use_shader_visual and sprite_texture and character_visual == null:
		_setup_player_shader_visual(game)
	if _use_shader_visual and character_visual:
		character_visual.update_visual(delta)
		# 2.5D: Depth atmosphere fog — player tinted by screen depth
		if in_sideview_mode and ClassDB.class_exists("DepthPlanes"):
			var depth = DepthPlanes.get_depth_factor(position.y)
			var fog = (1.0 - depth) * 0.25
			character_visual.modulate = Color(
				1.0 - fog * 0.12,
				1.0 - fog * 0.05,
				1.0 + fog * 0.10,
				character_visual.modulate.a
			)
	if has_dino_mount:
		dino_anim_time += delta
	_handle_grapple(delta, game)
	_handle_dash(delta, game)
	_handle_block(delta, game)
	if in_sideview_mode:
		_handle_movement_sideview(delta, game)
	else:
		_handle_movement(delta, game)
	_handle_facing()
	_handle_combat(delta, game)
	_handle_grenade(delta, game)
	_handle_repair(delta, game)
	_handle_potion(game)
	_update_timers(delta)
	_update_squash(delta)
	_update_combo_visuals(delta)  # AAA Upgrade: Update combo trail effects
	_update_trail(delta)
	_update_dash_trail(delta)
	_update_cape_trail(delta)  # AAA Upgrade: Procedural cape/hair trail
	_update_limb_ik(delta, game)  # AAA Upgrade: Foot IK for ground contact
	_update_weapon_lag(delta)  # AAA Upgrade: Weapon follows with spring lag
	idle_time += delta
	# HP regen
	if regen_rate > 0 and current_hp < max_hp:
		regen_accum += regen_rate * delta
		if regen_accum >= 1.0:
			var heal_amt = int(regen_accum)
			current_hp = mini(current_hp + heal_amt, max_hp)
			regen_accum -= heal_amt
	# Temp buff timers
	if temp_damage_timer > 0:
		temp_damage_timer -= delta
		if temp_damage_timer <= 0:
			temp_damage_mult = 1.0
			temp_damage_timer = 0.0
	if temp_speed_timer > 0:
		temp_speed_timer -= delta
		if temp_speed_timer <= 0:
			temp_speed_mult = 1.0
			temp_speed_timer = 0.0
	queue_redraw()

func _handle_grapple(delta, game):
	grapple_cooldown = maxf(0, grapple_cooldown - delta)
	# AAA Upgrade: Grapple input buffering
	if grapple_buffer_timer > 0:
		grapple_buffer_timer = maxf(0, grapple_buffer_timer - delta)

	if is_grappling:
		# Release grapple on re-press or jump (during swing)
		if grapple_swing_mode and grapple_pull_started:
			if Input.is_action_just_pressed(action_prefix + "grapple") or Input.is_action_just_pressed(action_prefix + "move_up"):
				# Phase 6.3: Release boost — catapult 1.5x in swing direction for satisfying launch
				var to_anchor = grapple_target - position
				var rope_dir = to_anchor.normalized()
				var tangent = Vector2(-rope_dir.y, rope_dir.x)
				var tangent_vel = tangent * grapple_swing_velocity * grapple_rope_length * 1.5
				velocity = tangent_vel
				is_grappling = false
				grapple_swing_mode = false
				grapple_pull_started = false
				grapple_line_progress = 0.0
				grapple_cooldown = GRAPPLE_COOLDOWN_TIME * 0.5  # Shorter cooldown on release
				invincibility_timer = maxf(invincibility_timer, 0.08)
				# AAA Upgrade: Double coyote time on grapple release for more forgiving platforming
				coyote_timer = COYOTE_TIME * 2.0  # 0.28s grace period
				# AAA Upgrade: Grapple release feedback
				if game.sfx:
					game.sfx.play_grapple_land()
				if game.particles:
					game.particles.emit_burst(position.x, position.y, Color8(200, 220, 255), 8)
				return

		# Phase 1: Line extending to target
		if not grapple_pull_started:
			grapple_line_progress = minf(grapple_line_progress + delta * GRAPPLE_LINE_SPEED, 1.0)
			if grapple_line_progress >= 1.0:
				grapple_pull_started = true
				# Reset air abilities when attaching (for multi-level pits: release, fall, grapple again)
				air_jump_count = 0
				air_dash_used = false
				if grapple_swing_mode:
					grapple_rope_length = position.distance_to(grapple_target)
					# Pendulum angle: 0 = straight down from anchor
					grapple_swing_angle = atan2(position.x - grapple_target.x, position.y - grapple_target.y)
					grapple_swing_velocity = velocity.x / maxf(grapple_rope_length, 1.0)
		else:
			if grapple_swing_mode:
				# Phase 2 (swing): Pendulum physics (safeguard against invalid values)
				var rope_len = maxf(grapple_rope_length, 20.0)
				if is_nan(grapple_swing_angle) or is_inf(grapple_swing_angle):
					grapple_swing_angle = 0.0
				if is_nan(grapple_swing_velocity) or is_inf(grapple_swing_velocity):
					grapple_swing_velocity = 0.0
				var g = GRAVITY if _is_main_game_sideview(game) else 600.0
				var angular_accel = -g / rope_len * sin(grapple_swing_angle)
				grapple_swing_velocity += angular_accel * delta
				grapple_swing_velocity *= 0.998  # Slight damping
				grapple_swing_velocity = clampf(grapple_swing_velocity, -8.0, 8.0)
				grapple_swing_angle += grapple_swing_velocity * delta
				position = grapple_target + Vector2(sin(grapple_swing_angle), cos(grapple_swing_angle)) * rope_len
				velocity = Vector2(-cos(grapple_swing_angle), sin(grapple_swing_angle)) * grapple_swing_velocity * grapple_rope_length
				invincibility_timer = maxf(invincibility_timer, delta + 0.05)
				var world_w = game.map.SCREEN_W if game else 1280.0
				var world_h = game.map.SCREEN_H if game else 720.0
				position.x = clampf(position.x, 15, world_w - 15)
				position.y = clampf(position.y, 15, world_h - 15)
				# Arrive if very close to anchor (auto-release)
				if position.distance_to(grapple_target) < 25.0:
					is_grappling = false
					grapple_swing_mode = false
					grapple_pull_started = false
					grapple_line_progress = 0.0
					grapple_cooldown = GRAPPLE_COOLDOWN_TIME
					velocity = Vector2(sin(grapple_swing_angle), cos(grapple_swing_angle)) * grapple_swing_velocity * grapple_rope_length
					# AAA Upgrade: Double coyote time on auto-release
					coyote_timer = COYOTE_TIME * 2.0
					squash_factor = 0.65
					invincibility_timer = maxf(invincibility_timer, 0.1)
					game.particles.emit_burst(position.x, position.y, Color8(100, 200, 255), 6)
					if game.sfx:
						game.sfx.play_grapple_land()
		return

	# AAA Upgrade: Check buffered input when cooldown expires
	var want_grapple = Input.is_action_just_pressed(action_prefix + "grapple")
	if want_grapple and grapple_cooldown > 0:
		grapple_buffer_timer = 0.20  # Buffer the input

	if (want_grapple or grapple_buffer_timer > 0) and grapple_cooldown <= 0 and not is_dead and not is_dashing:
		grapple_buffer_timer = 0  # Consume buffer
		var result = _find_grapple_target(game)
		var target_pos = result.position if result is Dictionary else result
		var _use_swing = true  # All grapples use swing mechanic
		if target_pos != Vector2.ZERO:
			is_grappling = true
			grapple_target = target_pos
			grapple_line_progress = 0.0
			grapple_pull_started = false
			grapple_swing_mode = true
			grapple_is_chain_link = result.get("is_chain_link", false) if result is Dictionary else false
			is_repairing = false
			is_blocking = false
			squash_factor = 1.4
			# AAA Upgrade: Grapple launch feedback
			if game.sfx:
				game.sfx.play_grapple_launch()
			if game.particles:
				var dir_to_target = (grapple_target - position).normalized()
				game.particles.emit_directional(position.x, position.y, dir_to_target, Color8(200, 220, 255), 8)
			if game.has_method("start_shake"):
				game.start_shake(1.0, 0.06)

func _find_grapple_target(game) -> Dictionary:
	"""Scan for nearest valid grapple target. Only chain links are grapplable (pit recovery)."""
	var best_target = Vector2.ZERO
	var best_dist = GRAPPLE_RANGE + 1
	var best_is_chain = false

	var candidates: Array = []  # [{pos: Vector2, is_chain: bool}]

	# Only chain links are grapplable (placed in pits for recovery)
	if "chain_links" in game.map and game.map.chain_links.size() > 0:
		for cl in game.map.chain_links:
			var pos = cl if cl is Vector2 else Vector2(cl.get("x", 0), cl.get("y", 0))
			candidates.append({"pos": pos, "is_chain": true})

	for c in candidates:
		var target_pos: Vector2 = c.pos
		var is_chain: bool = c.is_chain
		var dist = position.distance_to(target_pos)
		if dist < 40.0 or dist > GRAPPLE_RANGE:
			continue
		var angle_to = (target_pos - position).angle()
		var angle_diff = abs(fmod(angle_to - facing_angle + PI, TAU) - PI)
		var cone = GRAPPLE_CHAIN_CONE / 2.0 if is_chain else GRAPPLE_CONE / 2.0
		# Chain links: wider cone so you can grapple up when falling
		if angle_diff < cone and dist < best_dist:
			best_dist = dist
			best_target = target_pos
			best_is_chain = is_chain

	return {"position": best_target, "is_chain_link": best_is_chain}

func _handle_block(delta, _game):
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
			parry_window_timer = PARRY_WINDOW
			is_repairing = false
		block_hold_time += delta
		block_stamina -= delta
		if block_stamina <= 0:
			# Stamina depleted - force end block with cooldown
			is_blocking = false
			block_cooldown = BLOCK_COOLDOWN_TIME
			block_hold_time = 0.0
			parry_window_timer = 0.0
	else:
		if is_blocking:
			is_blocking = false
			block_hold_time = 0.0
			parry_window_timer = 0.0

func _handle_movement(delta, game):
	# During grapple/dash, movement is handled elsewhere
	if is_grappling:
		return
	if is_dashing:
		# Calculate new position AND update velocity for animation system
		var dash_velocity = dash_direction * DASH_SPEED
		velocity = dash_velocity  # CRITICAL: Update velocity so SpriteAnimator can detect dash speed
		var new_pos = position + dash_velocity * delta

		# Prevent dashing into pits
		if game and game.map and game.map.has_method("is_position_over_pit"):
			if not game.map.is_position_over_pit(new_pos):
				position = new_pos
			else:
				# Hit a pit - stop dash
				is_dashing = false
				dash_timer = 0
				velocity = Vector2.ZERO
		else:
			position = new_pos

		# Apply collision resolution (prevent phasing through walls/floors)
		if game and game.map:
			position = game.map.resolve_collision(position, BODY_RADIUS)

		# Add dash trail ghost
		if dash_trail.size() == 0 or position.distance_to(dash_trail[-1].pos) > 8.0:
			dash_trail.append({"pos": position, "alpha": 0.7, "angle": facing_angle})  # Phase 4.4: 0.7→0
		var bound_w = game.map.SCREEN_W if game else 1280.0
		var bound_h = game.map.SCREEN_H if game else 720.0
		position.x = clampf(position.x, 15, bound_w - 15)
		position.y = clampf(position.y, 15, bound_h - 15)
		# Dash can phase through enemies but not terrain
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
	var effective_speed = move_speed * temp_speed_mult
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

func _update_player_shader_visual():
	"""AAA Visual Overhaul: Update CharacterVisual transforms from player state."""
	if not character_visual or not sprite_texture:
		return

	var tex_size = sprite_texture.get_size()
	var base_scale = SPRITE_HEIGHT / tex_size.y
	var scale_x = base_scale
	var scale_y = base_scale

	# Flip based on movement/action direction
	var flip: bool
	if is_dashing:
		# Use dash direction for dash animation
		flip = dash_direction.x < 0
	elif is_attacking_melee or is_blocking:
		# Use facing angle for combat actions
		flip = facing_angle < -PI / 2.0 or facing_angle > PI / 2.0
	else:
		# Use movement direction for walking animation
		var move_dir_x = last_move_dir.x if abs(last_move_dir.x) > 0.1 else (1.0 if velocity.x > 0 else -1.0)
		flip = move_dir_x < 0  # Flip when moving left

	# NOTE: flip_sign is NOT used with CharacterVisual - it handles flipping via flip_h
	# Using flip_sign would create a double-negative (flip_h=true + negative scale = no flip)
	var flip_sign = 1.0  # Always positive scale for CharacterVisual

	# Squash/stretch
	var sq = clampf(squash_factor, 0.4, 2.0)
	scale_y *= sq
	scale_x *= (2.0 - sq)

	# AAA Animation: Add animation squash/stretch
	if sprite_animator and animation_frames_loaded:
		var anim_squash = sprite_animator.get_squash_multiplier()
		scale_x *= anim_squash.x
		scale_y *= anim_squash.y

	# Depth scaling in sideview
	if in_sideview_mode:
		var depth_scale = DepthPlanes.get_scale_for_y(position.y)
		scale_x *= depth_scale
		scale_y *= depth_scale

	# Dashing: smooth, elegant stretch with ease
	if is_dashing:
		var dash_t = 1.0 - (dash_timer / DASH_DURATION)  # 0->1 progress
		# Ease out quad for smooth motion blur effect
		var ease = 1.0 - pow(1.0 - dash_t, 2.0)
		var stretch = 1.0 + ease * 0.4  # Peak 1.4x stretch
		var squish = 1.0 - ease * 0.25   # Peak 0.75x compression
		scale_x *= stretch
		scale_y *= squish

	# Position at sprite offset
	var sprite_y = BODY_RADIUS - (tex_size.y / 2.0 - sprite_feet_padding) * scale_y

	# AAA Animation: Update animation state and apply
	if sprite_animator and animation_frames_loaded:
		var anim_state = "idle"
		var current_combo = 0
		if is_attacking_melee:
			anim_state = "attack"
			# Get which combo is currently active (previous combo since index increments on hit)
			current_combo = ((combo_index - 1) + COMBO_COUNT) % COMBO_COUNT if combo_window > 0 else 0
		elif is_dashing:
			anim_state = "run"
		elif is_moving:
			anim_state = "walk"

		sprite_animator.update_animation(get_physics_process_delta_time(), anim_state, velocity, is_on_ground, current_combo)

		# Apply animation offsets (bob, tilt)
		var anim_offset = sprite_animator.get_animation_offset()
		character_visual.position = Vector2(anim_offset.x, sprite_y + anim_offset.y)

		# Apply animation rotation
		var anim_rotation = sprite_animator.get_rotation_offset()
		character_visual.update_transform(flip, Vector2(scale_x * flip_sign, scale_y), anim_rotation)
	else:
		# Fallback: no animation
		character_visual.update_transform(flip, Vector2(scale_x * flip_sign, scale_y))
		character_visual.position = Vector2(0, sprite_y)

func _setup_player_shader_visual(game):
	"""AAA Visual Overhaul: Create CharacterVisual for shader rendering."""
	_use_shader_visual = true
	character_visual = CharacterVisual.new()
	character_visual.name = "Visual"
	add_child(character_visual)
	var theme = "grass"
	if game.map and game.map.get("level_config"):
		theme = game.map.level_config.get("theme", "grass")
	character_visual.setup(sprite_texture, {
		"outline_width": 2.0,
		"outline_color": CartoonPalette.get_outline_color(theme),
		"tint": SKIN_TINTS.get(selected_skin, Color.WHITE),
	})
	character_visual.set_theme_lighting(theme)

	# AAA Animation System: Set up sprite animator
	sprite_animator = SpriteAnimator.new()
	sprite_animator.setup(character_visual)

	# Load animation frames (AI-generated or placeholders)
	var frames = SpriteFrameLoader.load_character_frames("player")
	sprite_animator.set_sprite_frames(frames)
	animation_frames_loaded = true

	# Phase 3.1: Wire animation event callbacks
	sprite_animator.on_land_frame = func():
		if character_visual:
			character_visual.squash_land()
		if game and game.get("audio_manager"):
			game.audio_manager.play_at("res://audio/sfx/land.ogg", position, -6.0, 1.0)
	sprite_animator.on_dash_start_frame = func():
		if character_visual:
			character_visual.squash_stretch_scale = Vector2(1.4, 0.65)
	sprite_animator.on_strike_frame = func():
		if character_visual:
			character_visual.squash_strike()

	print("[Player] ✅ CharacterVisual system initialized")
	print("[Player] _use_shader_visual = %s" % _use_shader_visual)
	print("[Player] Animation frames: %s" % SpriteFrameLoader.get_frame_status())
	print("[Player] Sprite dimensions: %dx%d" % [sprite_texture.get_size().x, sprite_texture.get_size().y])
	print("[Player] sprite_feet_padding: %.1f pixels" % sprite_feet_padding)

func _is_main_game_sideview(game) -> bool:
	if game == null or game.map == null:
		return false
	if game.get("is_sideview_game") == true:
		return true
	return game.map.has_method("resolve_sideview_collision")

func _is_on_floor_only(pos: Vector2, game) -> bool:
	# Check if standing on solid floor (not platform)
	var foot_y = pos.y + BODY_RADIUS
	for rect in game.map.floor_rects:
		if absf(foot_y - rect.position.y) <= 6.0:
			if pos.x + BODY_RADIUS >= rect.position.x and pos.x - BODY_RADIUS <= rect.position.x + rect.size.x:
				return true
	return false

func _handle_movement_sideview(delta: float, game):
	# During dash, apply dash movement and skip normal physics
	if is_dashing:
		# AAA Upgrade: Use momentum-based dash speed
		# CRITICAL: Update velocity for animation system
		var dash_velocity = dash_direction * current_dash_speed
		velocity = dash_velocity
		var new_pos = position + dash_velocity * delta

		# Prevent dashing into pits
		if game and game.map and game.map.has_method("is_position_over_pit"):
			if not game.map.is_position_over_pit(new_pos):
				position = new_pos
			else:
				# Hit a pit - stop dash
				is_dashing = false
				dash_timer = 0
				velocity = Vector2.ZERO
				return
		else:
			position = new_pos

		# Apply collision resolution (prevent phasing through walls/floors)
		if game and game.map and game.map.has_method("resolve_sideview_collision"):
			var result = game.map.resolve_sideview_collision(position, velocity, BODY_RADIUS, false)
			position = result.position
			# If collision stopped us, cancel dash
			if result.velocity.length() < velocity.length() * 0.5:
				is_dashing = false
				dash_timer = 0
			velocity = result.velocity

		if dash_trail.size() == 0 or position.distance_to(dash_trail[-1].pos) > 8.0:
			dash_trail.append({"pos": position, "alpha": 0.7, "angle": facing_angle})  # Phase 4.4: 0.7→0
		# Phase 3.1: Try to break destructible walls during dash
		if game and game.map and game.map.has_method("try_dash_break_walls"):
			game.map.try_dash_break_walls(position, velocity, game)
		# Clamp to map bounds during dash
		position.x = clampf(position.x, 30, game.map.level_width - 30)
		position.y = clampf(position.y, 30, game.map.level_height - 30)

		# AAA Upgrade: Track enemies passed through for extended i-frames
		if game.has_method("get") and game.get("enemy_container"):
			var candidates = game.get("spatial_grid").get_enemies_near(position, 40.0) if game.get("spatial_grid") else game.enemy_container.get_children()
			for enemy in candidates:
				if enemy.state != EnemyEntity.EnemyState.DEAD and enemy.state != EnemyEntity.EnemyState.DYING:
					if position.distance_to(enemy.position) < BODY_RADIUS + enemy.entity_size:
						enemies_dashed_through += 1
		return

	drop_through_timer = maxf(0, drop_through_timer - delta)
	var want_drop_through = Input.is_action_pressed(action_prefix + "move_down")
	if want_drop_through and is_on_ground:
		var on_platform = game.map.get_ground_check(position, BODY_RADIUS) and not _is_on_floor_only(position, game)
		if on_platform:
			drop_through_timer = DROP_THROUGH_DURATION

	var input_x = 0.0
	if Input.is_action_pressed(action_prefix + "move_left"): input_x -= 1.0
	if Input.is_action_pressed(action_prefix + "move_right"): input_x += 1.0
	var want_jump = Input.is_action_just_pressed(action_prefix + "move_up")
	is_moving = absf(input_x) > 0.1
	if is_moving:
		last_move_dir = Vector2(input_x, 0).normalized()
		is_repairing = false
		walk_anim += delta * 10.0

	# Coyote time
	if is_on_ground:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0, coyote_timer - delta)
	# Jump buffer
	if want_jump and not is_on_ground:
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(0, jump_buffer_timer - delta)

	is_sprinting = is_moving and Input.is_action_pressed(action_prefix + "sprint") and not is_blocking and not is_attacking_melee
	var effective_speed = move_speed * temp_speed_mult
	if is_sprinting:
		effective_speed *= SPRINT_SPEED_MULT
	if has_dino_mount:
		effective_speed *= 1.40
	if is_blocking:
		effective_speed *= BLOCK_SPEED_PENALTY

	# AAA Upgrade: Slide momentum system
	if slide_timer > 0:
		slide_timer -= delta
		# Reduce friction during slide
		effective_speed *= 1.3

	# Air control with momentum preservation
	var control_mult = AIR_CONTROL_MULT if not is_on_ground else 1.0
	var target_vx = input_x * effective_speed * control_mult

	# AAA Upgrade: Blend momentum with target velocity in air
	if not is_on_ground and absf(horizontal_momentum) > 50.0:
		target_vx = lerpf(horizontal_momentum, target_vx, 0.3)
		horizontal_momentum = lerpf(horizontal_momentum, 0.0, delta * 2.0)  # Decay momentum

	velocity.x = lerpf(velocity.x, target_vx, delta * 18.0)

	# AAA Upgrade: Wall jump chain timer
	if wall_jump_chain_timer > 0:
		wall_jump_chain_timer -= delta

	# Wall jump lockout timer
	if wall_jump_lockout > 0:
		wall_jump_lockout -= delta

	# Wall slide detection
	is_wall_sliding = false
	wall_slide_dir = 0
	if has_wall_jump and not is_on_ground and velocity.y > 0 and game.map.has_method("get_wall_at_position"):
		var wall_check_left = game.map.get_wall_at_position(position, BODY_RADIUS, -1)
		var wall_check_right = game.map.get_wall_at_position(position, BODY_RADIUS, 1)
		if wall_check_left and input_x < -0.1:
			is_wall_sliding = true
			wall_slide_dir = -1
		elif wall_check_right and input_x > 0.1:
			is_wall_sliding = true
			wall_slide_dir = 1

	# AAA Upgrade: Wall cling - holding toward wall pauses descent
	if is_wall_sliding and wall_cling_timer < WALL_CLING_MAX:
		# Pause descent when holding toward wall
		if (wall_slide_dir == -1 and input_x < -0.8) or (wall_slide_dir == 1 and input_x > 0.8):
			wall_cling_timer += delta
			velocity.y = 0  # Pause fall

	# AAA Upgrade: Allow jump cancel on combo finisher (hit 3) within cancel window
	var can_cancel_with_jump = last_hit_landed_time < CANCEL_WINDOW and is_attacking_melee and ((combo_index - 1) % COMBO_COUNT == 2)

	# Jump: ground / coyote / double jump / wall jump
	var can_jump = is_on_ground or coyote_timer > 0 or can_cancel_with_jump
	if want_jump:
		# AAA Upgrade: If canceling attack, reset attack state
		if can_cancel_with_jump:
			is_attacking_melee = false
			melee_attack_timer = 0
			melee_attack_phase = "none"
		if is_wall_sliding:
			velocity.x = -wall_slide_dir * WALL_JUMP_FORCE_X
			velocity.y = WALL_JUMP_FORCE_Y
			is_on_ground = false
			is_wall_sliding = false
			wall_cling_timer = 0  # Reset cling timer on jump

			# AAA Upgrade: Chain wall jumps - reduced lockout if chaining
			if wall_jump_chain_timer > 0:
				wall_jump_lockout = 0.08  # Reduced lockout for chain
			else:
				wall_jump_lockout = 0.15  # Normal lockout
			wall_jump_chain_timer = 0.8  # 0.8s window to chain

			coyote_timer = 0
			air_jump_count = 0
			squash_factor = 1.3
			if game.sfx:
				game.sfx.play_jump()
			game.particles.emit_burst(position.x + wall_slide_dir * BODY_RADIUS, position.y, Color8(200, 200, 210), 6)
		elif can_jump:
			velocity.y = JUMP_FORCE
			is_on_ground = false
			coyote_timer = 0
			air_jump_count = 0
			var config = AnimationConfig.get_config()
			squash_factor = config.jump_launch_squash
			jump_state = "launch"
			# Phase 3.2: Stretch visual on jump
			if _use_shader_visual and character_visual:
				character_visual.squash_jump()

			# AAA Upgrade: Momentum preservation and sprint jump boost
			horizontal_momentum = velocity.x
			if is_sprinting and absf(velocity.x) > 100:
				horizontal_momentum *= SPRINT_JUMP_BOOST
				# Extra particle burst for sprint jump
				if game.particles:
					game.particles.emit_directional(position.x, position.y + BODY_RADIUS, Vector2(-signf(velocity.x), -0.5), Color8(255, 200, 100), 8)

			# AAA Upgrade: Camera zoom pulse on jump
			if game.has_method("trigger_camera_zoom_pulse"):
				game.trigger_camera_zoom_pulse(-0.5)
			# AAA Upgrade: Subtle shake on jump for tactile feel
			if game.has_method("start_shake"):
				game.start_shake(1.5, 0.06)
			if game.sfx:
				game.sfx.play_jump()
			if game.particles:
				game.particles.emit_ring(position.x, position.y + BODY_RADIUS, Color8(180, 220, 255), 10)
		elif has_double_jump and air_jump_count < max_air_jumps:
			velocity.y = JUMP_FORCE * 0.85
			air_jump_count += 1
			squash_factor = 1.2
			# AAA Upgrade: Subtle shake on double jump
			if game.has_method("start_shake"):
				game.start_shake(1.2, 0.05)
			if game.sfx:
				game.sfx.play_jump()
			game.particles.emit_ring(position.x, position.y + BODY_RADIUS, Color8(180, 220, 255), 8)

	# Gravity
	if is_wall_sliding:
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)
		velocity.y += GRAVITY * 0.15 * delta
	else:
		velocity.y += GRAVITY * delta

	# AAA Upgrade: Jump state tracking (apex and fall detection)
	if not is_on_ground:
		var config = AnimationConfig.get_config()
		# Apex detection (float at top of jump)
		if absf(velocity.y) < 50 and jump_state != "apex":
			jump_state = "apex"
			squash_factor = lerpf(squash_factor, config.jump_apex_squash, delta * 8.0)
		# Fall detection
		elif velocity.y > 100 and jump_state != "fall":
			jump_state = "fall"
			squash_factor = lerpf(squash_factor, 1.05, delta * 5.0)

		# AAA Upgrade: Ground pound activation (DOWN + ATTACK while airborne)
		if not is_ground_pounding and Input.is_action_pressed(action_prefix + "move_down") and Input.is_action_just_pressed(action_prefix + "attack"):
			is_ground_pounding = true
			velocity.y = GROUND_POUND_VELOCITY
			velocity.x *= 0.3  # Reduce horizontal drift
			squash_factor = 0.6  # Squash on activation
			jump_state = "ground_pound"
			# Visual feedback
			if game.particles:
				game.particles.emit_ring(position.x, position.y, Color8(255, 100, 50), 12)
			if game.sfx:
				game.sfx.play_dash()  # Reuse dash sound for whoosh effect

		# AAA Upgrade: Ground pound visual trail during fall
		if is_ground_pounding:
			squash_factor = 0.6  # Maintain squash
			# Continuous upward particle trail
			if game.particles and randf() < 0.4:
				game.particles.emit_directional(position.x, position.y, Vector2(0, -1), Color8(255, 120, 50), 3)
	else:
		if jump_state != "none":
			jump_state = "none"
		if is_ground_pounding:
			is_ground_pounding = false  # Reset if grounded normally

	# Jump apex squash
	if not is_on_ground and velocity.y > -50 and velocity.y < 50:
		squash_factor = 1.12

	# Override horizontal during wall jump lockout
	if wall_jump_lockout > 0:
		pass

	# Integrate
	position += velocity * delta

	# Collision
	var ignore_platforms = drop_through_timer > 0
	var result = game.map.resolve_sideview_collision(position, velocity, BODY_RADIUS, ignore_platforms)
	position = result.position
	velocity = result.velocity

	# Fall-to-death: feet at or below level bottom = death (after collision so we catch landing on bottom wall)
	var level_bottom = 720.0
	if game.map is LinearMap:
		level_bottom = game.map.level_height
	if position.y + BODY_RADIUS >= level_bottom:
		take_damage(current_hp + 1, game)  # Instant death
		return

	# Ground check
	was_on_ground = is_on_ground
	is_on_ground = game.map.get_ground_check(position, BODY_RADIUS)

	# Ground snap: flush feet to surface (prevents floating)
	if is_on_ground and velocity.y >= 0 and game.map.has_method("get_ground_surface_y"):
		var surface_y = game.map.get_ground_surface_y(position, BODY_RADIUS)
		if surface_y < INF:
			position.y = surface_y - BODY_RADIUS
			velocity.y = 0.0

	# Reset air abilities on ground touch
	if is_on_ground and not was_on_ground:
		air_jump_count = 0
		air_dash_used = false

	# Jump buffer on landing
	if is_on_ground and not was_on_ground and jump_buffer_timer > 0:
		velocity.y = JUMP_FORCE
		is_on_ground = false
		jump_buffer_timer = 0
		squash_factor = 1.25
		if game.sfx:
			game.sfx.play_jump()

	# AAA Upgrade: Ground pound landing with AOE damage
	if is_ground_pounding and is_on_ground and not was_on_ground:
		is_ground_pounding = false
		squash_factor = 0.4  # Massive squash on impact
		# Phase 3.1: Ground pound breaks destructible walls
		if game and game.map and game.map.has_method("try_dash_break_walls"):
			game.map.try_dash_break_walls(position, velocity, game)

		# Devastating screen shake and chromatic aberration
		if game.has_method("start_shake"):
			game.start_shake(12.0, 0.3, game.ShakeCurve.EASE_OUT_EXPO)
		if game.has_method("start_chromatic"):
			game.start_chromatic(5.0)
		if game.has_method("trigger_camera_zoom_pulse"):
			game.trigger_camera_zoom_pulse(2.0)  # Heavy zoom in
		if game.has_method("trigger_bloom"):
			game.trigger_bloom(1.5)

		# Massive impact ring and particles
		spawn_impact_ring(Vector2.ZERO, 80.0, Color(1.0, 0.3, 0.0, 1.0), 6.0)
		if game.particles:
			game.particles.emit_burst(position.x, position.y + BODY_RADIUS, Color8(255, 120, 50), 30)
			# Radial dust explosion
			for i in range(12):
				var angle = (float(i) / 12.0) * TAU
				var dir = Vector2(cos(angle), sin(angle))
				game.particles.emit_directional(position.x, position.y + BODY_RADIUS, dir, Color8(200, 180, 150), 8)

		if game.sfx:
			game.sfx.play_grenade_explode()

		# AOE damage to all enemies within radius
		if game.has_method("get") and game.get("enemy_container"):
			var aoe_damage = int(melee_damage * GROUND_POUND_DAMAGE_MULT)
			var candidates = game.get("spatial_grid").get_enemies_near(position, GROUND_POUND_AOE) if game.get("spatial_grid") else game.enemy_container.get_children()
			var hit_count = 0
			for enemy in candidates:
				if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
					continue
				if position.distance_to(enemy.position) <= GROUND_POUND_AOE:
					enemy.last_damager = self
					enemy.take_damage(aoe_damage, game)
					var dir_to_enemy = (enemy.position - position).normalized()
					if game.particles:
						game.particles.emit_directional(enemy.position.x, enemy.position.y, dir_to_enemy, Color8(255, 100, 50), 8)
					if game.has_method("spawn_damage_number"):
						game.spawn_damage_number(enemy.position, str(aoe_damage), Color8(255, 120, 50), true)
					hit_count += 1

			# Show AOE hit indicator
			if hit_count > 0 and game.has_method("spawn_damage_number"):
				game.spawn_damage_number(position + Vector2(0, -50), "SLAM! x%d" % hit_count, Color(1.0, 0.5, 0.0), false)

	# AAA Upgrade: Enhanced landing effects with ease curves and recovery
	if is_on_ground and not was_on_ground and velocity.y > 50:
		var config = AnimationConfig.get_config()
		var impact_strength = clampf(velocity.y / 400.0, 0.3, 1.0)

		# Determine squash intensity based on impact
		if impact_strength < 0.5:
			squash_factor = config.landing_squash_light
		elif impact_strength < 0.75:
			squash_factor = config.landing_squash_medium
		else:
			squash_factor = config.landing_squash_heavy

		# Phase 3.2: Trigger CharacterVisual spring squash on land
		if _use_shader_visual and character_visual:
			character_visual.squash_land()

		landing_recovery_timer = config.landing_recovery_time
		landing_target_squash = 1.0

		# AAA Upgrade: Slide momentum on high-speed landing
		if is_sprinting and absf(velocity.x) > 150:
			slide_timer = SLIDE_DURATION
			# Extra slide particles
			if game.particles:
				game.particles.emit_directional(position.x, position.y + BODY_RADIUS, Vector2(-signf(velocity.x), 0.2), Color8(200, 190, 170), 12)

		# Enhanced particle effects
		spawn_impact_ring(Vector2(0, 22), 50.0 * impact_strength, Color(0.9, 0.85, 0.7, 0.7), 3.0)
		if impact_strength > 0.6:
			if game.has_method("trigger_landing_impact"):
				game.trigger_landing_impact()
			if game.has_method("trigger_camera_zoom_pulse"):
				game.trigger_camera_zoom_pulse(2.2)
		elif impact_strength > 0.35:
			if game.has_method("trigger_camera_zoom_pulse"):
				game.trigger_camera_zoom_pulse(1.0)

		if game.sfx:
			game.sfx.play_land()

		if game.particles:
			var dust_count = int(18 * impact_strength) + 6
			var dust_color = Color8(180, 170, 155)
			game.particles.emit_directional(position.x, position.y + BODY_RADIUS, Vector2.UP, dust_color, dust_count)
			# Add dust ring on heavier impacts
			if impact_strength > 0.5:
				game.particles.emit_ring(position.x, position.y + BODY_RADIUS, dust_color.lightened(0.2), int(8 * impact_strength))
			# Phase 2.2: Wide soft dust cloud on hard landings (velocity.y > 300)
			if impact_strength > 0.75:
				game.particles.emit_burst(position.x, position.y + BODY_RADIUS, Color8(200, 185, 160, 200), int(14 * impact_strength))
				game.particles.emit_burst(position.x - 16, position.y + BODY_RADIUS, Color8(190, 175, 150, 160), 6)
				game.particles.emit_burst(position.x + 16, position.y + BODY_RADIUS, Color8(190, 175, 150, 160), 6)

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
	var anim_config = AnimationConfig.get_config()
	melee_timer = melee_cooldown_base * attack_cooldown_multiplier * (0.7 + combo_index * 0.15)
	is_attacking_melee = true
	melee_hit_done = false
	melee_attack_timer = cfg.duration + ANTICIPATION_DURATION + RECOVERY_DURATION
	# AAA Upgrade: Start in anticipation phase with config values
	melee_attack_phase = "anticipation"
	melee_phase_timer = anim_config.attack_anticipation_time
	squash_factor = anim_config.attack_anticipation_squash
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
	proj.damage = int(ranged_damage * _get_current_ranged_damage_mult() * temp_damage_mult)
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
	# AAA Upgrade: Dash input buffering
	if dash_buffer_timer > 0:
		dash_buffer_timer = maxf(0, dash_buffer_timer - delta)

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			# Phase 4.4: Stop afterimage ghost trail
			if dash_afterimage:
				dash_afterimage.stop_trail()
			# AAA Upgrade: Extended i-frames if dashed through 2+ enemies
			var base_iframes = 0.05
			if enemies_dashed_through >= 2:
				base_iframes = 0.15  # 150ms extended i-frames for skill play
				# Visual feedback for successful dash-through
				if game.particles:
					game.particles.emit_burst(position.x, position.y, Color8(150, 200, 255), 15)
			invincibility_timer = maxf(invincibility_timer, base_iframes)
			enemies_dashed_through = 0  # Reset counter
		return

	# AAA Upgrade: Check buffered input when cooldown expires
	var want_dash = Input.is_action_just_pressed(action_prefix + "dash")
	if want_dash and dash_cooldown > 0:
		dash_buffer_timer = 0.20  # Buffer the input

	# AAA Upgrade: Allow dash cancel within attack cancel window (bypasses cooldown if hit just landed)
	var can_cancel_with_dash = want_dash and last_hit_landed_time < CANCEL_WINDOW and is_attacking_melee
	var can_dash_normally = (want_dash or dash_buffer_timer > 0) and dash_cooldown <= 0

	if (can_dash_normally or can_cancel_with_dash) and not is_dead and not is_blocking:
		dash_buffer_timer = 0  # Consume buffer
		# Air dash check: if airborne, must have ability and not already used
		if not is_on_ground and in_sideview_mode and (not has_air_dash or air_dash_used):
			return

		# AAA Upgrade: If canceling attack, reset attack state
		if can_cancel_with_dash:
			is_attacking_melee = false
			melee_attack_timer = 0
			melee_attack_phase = "none"
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

		# AAA Upgrade: Velocity-dependent dash speed
		var player_speed = velocity.length()
		if is_sprinting or player_speed > 200:
			current_dash_speed = 750.0  # Sprint dash - faster and longer
		elif player_speed < 50:
			current_dash_speed = 550.0  # Standing dash - slower, tactical
		else:
			current_dash_speed = DASH_SPEED  # Standard dash

		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown = DASH_COOLDOWN_TIME
		invincibility_timer = DASH_DURATION + 0.05  # Invincible during dash
		squash_factor = 1.5  # Stretch in dash direction
		enemies_dashed_through = 0  # Reset counter at dash start

		# Phase 4.3: Dash glow — bright bloom + post-process boost (no extra Light2Ds)
		if game.has_method("trigger_bloom"):
			var bloom_strength = 1.5 if current_dash_speed >= 750 else 1.0
			game.trigger_bloom(bloom_strength)
		if game.has_method("trigger_bloom_boost"):
			game.trigger_bloom_boost(0.6 if current_dash_speed >= 750 else 0.35)
		# AAA Upgrade: Camera zoom pulse on dash
		if game.has_method("trigger_camera_zoom_pulse"):
			game.trigger_camera_zoom_pulse(-0.8)
		# AAA Upgrade: Screen shake on dash start (stronger for sprint dash)
		if game.has_method("start_shake"):
			var shake_strength = 2.5 if current_dash_speed >= 750 else 2.0
			game.start_shake(shake_strength, 0.08)
		# Mark air dash used if airborne
		if not is_on_ground and in_sideview_mode:
			air_dash_used = true
			# AAA Upgrade: Preserve momentum - blend with dash direction instead of canceling
			var preserved_velocity = velocity * 0.4  # Preserve 40% of air momentum
			velocity = preserved_velocity + dash_direction * current_dash_speed * 0.3
		is_repairing = false
		# Phase 4.3: Dash particles — bright cyan-white for bloom pickup
		if game:
			var particle_count = 10 if current_dash_speed >= 750 else 6
			var dash_glow_color = Color8(220, 240, 255) if current_dash_speed >= 750 else Color8(180, 220, 255)
			game.particles.emit_directional(position.x, position.y, -dash_direction, dash_glow_color, particle_count)
		if game and game.sfx:
			game.sfx.play_dash()
		# Phase 4.4: Start afterimage ghost trail
		if dash_afterimage:
			var trail_tint = Color(0.5, 0.85, 1.0) if current_dash_speed >= 750 else Color(0.35, 0.65, 0.9)
			dash_afterimage.start_trail(self, trail_tint)

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

func _update_cape_trail(delta: float):
	"""AAA Upgrade: Spring physics trail for cape/hair secondary motion."""
	# Add current position to front of trail
	cape_trail_points.insert(0, position)
	if cape_trail_points.size() > 8:
		cape_trail_points.resize(8)

	# Spring physics: Each point follows previous with lag
	for i in range(1, cape_trail_points.size()):
		var target = cape_trail_points[i - 1]
		# Add velocity influence for dynamic motion
		var velocity_offset = velocity * delta * 0.05
		cape_trail_points[i] = cape_trail_points[i].lerp(target - velocity_offset, delta * 12.0)

func _update_limb_ik(delta: float, game):
	"""AAA Upgrade: Foot IK for ground contact - feet stick to ground."""
	if not game or not game.map:
		return

	# Left foot
	var foot_l_world = position + Vector2(-8, BODY_RADIUS)
	if is_on_ground and game.map.has_method("get_ground_surface_y"):
		var ground_y = game.map.get_ground_surface_y(foot_l_world, BODY_RADIUS)
		if ground_y > 0:
			limb_foot_l = limb_foot_l.lerp(Vector2(foot_l_world.x - position.x, ground_y - position.y), delta * 15.0)
	else:
		# In air, feet dangle
		limb_foot_l = limb_foot_l.lerp(Vector2(-8, BODY_RADIUS + 4), delta * 8.0)

	# Right foot
	var foot_r_world = position + Vector2(8, BODY_RADIUS)
	if is_on_ground and game.map.has_method("get_ground_surface_y"):
		var ground_y = game.map.get_ground_surface_y(foot_r_world, BODY_RADIUS)
		if ground_y > 0:
			limb_foot_r = limb_foot_r.lerp(Vector2(foot_r_world.x - position.x, ground_y - position.y), delta * 15.0)
	else:
		limb_foot_r = limb_foot_r.lerp(Vector2(8, BODY_RADIUS + 4), delta * 8.0)

func _update_weapon_lag(delta: float):
	"""AAA Upgrade: Weapon follows attacks with spring lag for impact feel."""
	var target_offset = Vector2.ZERO
	var target_rotation = 0.0

	if is_attacking_melee:
		# Weapon swings during attacks
		var attack_progress = 1.0 - (melee_attack_timer / 0.3)
		match combo_index:
			0:  # Hit 1 - horizontal slash
				target_rotation = lerpf(-0.5, 0.5, attack_progress)
				target_offset = Vector2(cos(facing_angle) * 15.0, sin(facing_angle) * 15.0)
			1:  # Hit 2 - thrust
				target_rotation = 0.0
				target_offset = Vector2(cos(facing_angle) * 20.0 * attack_progress, sin(facing_angle) * 20.0 * attack_progress)
			2:  # Hit 3 - spin
				target_rotation = attack_progress * TAU
				target_offset = Vector2(cos(facing_angle + target_rotation) * 18.0, sin(facing_angle + target_rotation) * 18.0)
	else:
		# Idle weapon position
		target_offset = Vector2(cos(facing_angle) * 8.0, sin(facing_angle) * 8.0)
		target_rotation = facing_angle * 0.3

	# Spring to target
	weapon_offset = weapon_offset.lerp(target_offset, delta * 18.0)
	weapon_rotation = lerpf(weapon_rotation, target_rotation, delta * 15.0)

func _update_timers(delta):
	# AAA Upgrade: Update attack cancel window timer
	if last_hit_landed_time < CANCEL_WINDOW:
		last_hit_landed_time += delta

	if is_attacking_melee:
		melee_attack_timer -= delta
		var config = AnimationConfig.get_config()
		# AAA Upgrade: Enhanced melee attack phases with AnimationConfig
		if melee_attack_phase == "anticipation":
			melee_phase_timer -= delta
			squash_factor = lerpf(squash_factor, config.attack_anticipation_squash, delta * 20.0)
			if melee_phase_timer <= 0:
				melee_attack_phase = "strike"
				melee_phase_timer = melee_attack_timer  # Remaining time is strike
				squash_factor = config.attack_strike_squash
				# Camera punch on strike
				if game and game.has_method("start_shake"):
					game.start_shake(3.0, 0.08)
		elif melee_attack_phase == "strike":
			melee_phase_timer -= delta
			if melee_phase_timer <= 0 or melee_attack_timer <= config.attack_recovery_time:
				melee_attack_phase = "recovery"
				melee_phase_timer = config.attack_recovery_time
		elif melee_attack_phase == "recovery":
			melee_phase_timer -= delta
			var progress = 1.0 - (melee_phase_timer / config.attack_recovery_time)
			squash_factor = lerpf(squash_factor, 1.0, AnimationConfig.apply_ease(progress, config.attack_ease) * delta * 20.0)
		if melee_attack_timer <= 0:
			is_attacking_melee = false
			melee_attack_phase = "none"
			melee_phase_timer = 0.0
	invincibility_timer = maxf(0, invincibility_timer - delta)
	hit_flash_timer = maxf(0, hit_flash_timer - delta)
	# Parry window decay
	if parry_window_timer > 0:
		parry_window_timer -= delta
		if parry_window_timer <= 0:
			parry_window_timer = 0.0
	# Parry counter execution
	if parry_counter_active:
		parry_counter_timer -= delta
		if parry_counter_timer <= 0:
			parry_counter_active = false
			parry_counter_timer = 0.0

func take_damage(amount: int, game, attacker = null):
	if invincibility_timer > 0 or is_dead:
		return
	if dodge_chance > 0 and randf() < dodge_chance:
		game.spawn_damage_number(position, "DODGE", Color8(200, 200, 200))
		invincibility_timer = 0.15
		return
	# Parry check: block within PARRY_WINDOW triggers counter
	if is_blocking and parry_window_timer > 0 and attacker and is_instance_valid(attacker):
		_trigger_parry(game, attacker)
		return
	# Block damage reduction
	if is_blocking:
		var is_perfect = block_hold_time <= BLOCK_PERFECT_WINDOW
		var reduction = BLOCK_PERFECT_REDUCTION if is_perfect else BLOCK_DAMAGE_REDUCTION
		amount = maxi(1, int(amount * (1.0 - reduction)))
		if is_perfect:
			block_flash_timer = 0.3
			game.start_hitstop(0.08)
			game.spawn_damage_number(position, "PERFECT!", Color8(100, 200, 255))
			game.particles.emit_burst(position.x, position.y, Color8(100, 200, 255), 8)
			if game.sfx:
				game.sfx.play_block_perfect()
			invincibility_timer = 0.2
			squash_factor = 0.85
		else:
			# AAA Upgrade: Add hitstop on regular block
			game.start_hitstop(0.03)
			game.spawn_damage_number(position, "BLOCKED", Color8(180, 200, 220))
			game.particles.emit_directional(position.x, position.y, Vector2.from_angle(facing_angle), Color8(180, 200, 220), 4)
			if game.sfx:
				game.sfx.play_block_hit()
			invincibility_timer = 0.1
			squash_factor = 0.9
		current_hp -= amount
		if current_hp <= 0:
			if has_extra_life:
				has_extra_life = false
				current_hp = int(max_hp * 0.5)
				invincibility_timer = 1.5
				squash_factor = 1.6
				game.spawn_damage_number(position, "SECOND WIND!", Color8(100, 255, 200))
				game.particles.emit_burst(position.x, position.y, Color8(100, 255, 200), 12)
				if game.sfx:
					game.sfx.play_wave_complete()
			else:
				current_hp = 0
				is_dead = true
				visible = false
				game.check_all_players_dead()
		return
	current_hp -= amount
	hit_flash_timer = 0.12
	invincibility_timer = 0.35
	squash_factor = 0.6
	spawn_impact_ring(Vector2.ZERO, 45.0, Color(1, 0.3, 0.2, 0.7), 3.0)
	if game.sfx:
		game.sfx.play_player_hurt()
	game.start_shake(6.0, 0.15)
	game.start_chromatic(0.6)
	if game.has_method("start_damage_flash"):
		game.start_damage_flash()
	if current_hp <= 0:
		if has_extra_life:
			has_extra_life = false
			current_hp = int(max_hp * 0.5)
			invincibility_timer = 1.5
			squash_factor = 1.6
			game.spawn_damage_number(position, "SECOND WIND!", Color8(100, 255, 200))
			game.particles.emit_burst(position.x, position.y, Color8(100, 255, 200), 12)
			if game.sfx:
				game.sfx.play_wave_complete()
			return
		current_hp = 0
		is_dead = true
		visible = false
		game.check_all_players_dead()

func _trigger_parry(game, attacker):
	parry_counter_active = true
	parry_counter_timer = PARRY_COUNTER_DURATION
	parry_target = attacker
	invincibility_timer = PARRY_INVINCIBILITY
	parry_window_timer = 0.0
	squash_factor = 0.7
	block_flash_timer = 0.4
	game.start_hitstop(0.12)
	game.start_shake(8.0, 0.2)
	game.start_chromatic(0.8)
	game.spawn_damage_number(position, "PARRY!", Color8(255, 215, 0), true)
	game.particles.emit_burst(position.x, position.y, Color8(255, 215, 0), 15)
	spawn_impact_ring(Vector2.ZERO, 60.0, Color(1.0, 0.85, 0.0, 0.8), 4.0)
	if game.sfx:
		game.sfx.play_block_perfect()

func _execute_parry_counter(game):
	if parry_target and is_instance_valid(parry_target) and parry_target.has_method("take_damage"):
		var counter_dmg = int(melee_damage * PARRY_COUNTER_DAMAGE_MULT)
		parry_target.take_damage(counter_dmg, game)
		game.spawn_damage_number(parry_target.position, str(counter_dmg), Color8(255, 215, 0), true)
		game.particles.emit_burst(parry_target.position.x, parry_target.position.y, Color8(255, 200, 50), 12)
		spawn_melee_slash(Vector2.ZERO, Color(1.0, 0.85, 0.0, 0.9), 2.0)
		game.start_shake(5.0, 0.12)
		if game.sfx:
			game.sfx.play_combo_hit(2)
	parry_counter_active = false
	parry_target = null

func try_execute_enemy(enemy, game) -> bool:
	if enemy.current_hp <= 0 or enemy.state == enemy.EnemyState.DYING or enemy.state == enemy.EnemyState.DEAD:
		return false
	var hp_pct = float(enemy.current_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 1.0
	if hp_pct > 0.15:
		return false
	game.start_hitstop(0.15)
	game.start_shake(10.0, 0.25)
	game.start_chromatic(1.0)
	game.spawn_damage_number(enemy.position, "EXECUTE!", Color8(255, 50, 50), true)
	game.particles.emit_burst(enemy.position.x, enemy.position.y, Color8(255, 50, 50), 20)
	spawn_impact_ring(enemy.position - position, 80.0, Color(1, 0.2, 0.1, 0.9), 5.0)
	if game.sfx:
		game.sfx.play_enemy_death()
	enemy.die(game, true)
	var bonus = 5
	if game.economy:
		game.economy.add_gold(bonus, player_index)
		game.spawn_damage_number(enemy.position + Vector2(0, -20), "+%d BONUS" % bonus, Color.GOLD)
	return true

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

func spawn_combo_visual(hit_index: int, hit_position: Vector2):
	"""Phase 1.2: Spawn GPU ribbon trail via WeaponTrailManager."""
	if game and game.get("weapon_trail_manager") and game.weapon_trail_manager:
		# Compute start/end from position, facing angle and melee range
		var weapon_dir = Vector2.from_angle(facing_angle)
		var perp = Vector2(-weapon_dir.y, weapon_dir.x)
		var arc_half = melee_range * 0.55
		var trail_start = hit_position - perp * arc_half
		var trail_end = hit_position + perp * arc_half
		game.weapon_trail_manager.spawn_weapon_trail(trail_start, trail_end, hit_index)
	else:
		# Fallback: keep legacy combo_visual_trails when WeaponTrailManager unavailable
		var trail_data = {}
		trail_data["pos"] = hit_position
		trail_data["timer"] = 0.0
		trail_data["angle"] = facing_angle
		match hit_index:
			0:
				trail_data["type"] = "arc"
				trail_data["max_time"] = 0.3
				trail_data["color"] = Color.WHITE
			1:
				trail_data["type"] = "line"
				trail_data["max_time"] = 0.4
				trail_data["color"] = Color.YELLOW
			2:
				trail_data["type"] = "vortex"
				trail_data["max_time"] = 0.6
				trail_data["color"] = Color.RED
			_:
				trail_data["type"] = "arc"
				trail_data["max_time"] = 0.3
				trail_data["color"] = Color.WHITE
		combo_visual_trails.append(trail_data)

func _update_combo_visuals(delta: float):
	"""AAA Upgrade: Update combo visual trail timers."""
	var i = combo_visual_trails.size() - 1
	while i >= 0:
		combo_visual_trails[i]["timer"] += delta
		if combo_visual_trails[i]["timer"] >= combo_visual_trails[i]["max_time"]:
			combo_visual_trails.remove_at(i)
		i -= 1

func _update_squash(delta: float):
	# AAA Upgrade: Use AnimationConfig parameters
	var config = AnimationConfig.get_config()
	var force = (1.0 - squash_factor) * config.squash_spring_strength
	squash_velocity += force * delta
	squash_velocity *= exp(-config.squash_damping * delta)
	squash_factor += squash_velocity * delta
	squash_factor = clampf(squash_factor, config.squash_min, config.squash_max)

	# Landing recovery with ease curve
	if landing_recovery_timer > 0:
		landing_recovery_timer -= delta
		var progress = 1.0 - (landing_recovery_timer / config.landing_recovery_time)
		var ease_progress = AnimationConfig.apply_ease(progress, config.landing_ease)
		squash_factor = lerpf(squash_factor, landing_target_squash, ease_progress * delta * 20.0)

	# Phase 7: Velocity-based squash/stretch — blend with physics-driven factor
	if in_sideview_mode and not is_on_ground:
		# Stretch horizontally when sprinting fast (scale_y squeeze = squash_factor < 1)
		var speed_stretch = clamp(absf(velocity.x) / 500.0, 0.0, 0.15)
		# Squash vertically when falling fast (sq < 1 compresses Y, widens X)
		var fall_squash = clamp(velocity.y / 800.0, 0.0, 0.18)
		var velocity_sq = 1.0 + speed_stretch - fall_squash
		# Take max deviation from 1.0 to avoid fighting landing squash
		if absf(velocity_sq - 1.0) > absf(squash_factor - 1.0):
			squash_factor = lerpf(squash_factor, velocity_sq, delta * 10.0)

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
	# AAA Upgrade: Update impact rings with expansion
	i = impact_rings.size() - 1
	while i >= 0:
		impact_rings[i].timer -= delta
		if impact_rings[i].timer <= 0:
			impact_rings.remove_at(i)
		else:
			# Expand radius over time
			var t = 1.0 - (impact_rings[i].timer / impact_rings[i].max_timer)
			impact_rings[i].radius = lerpf(impact_rings[i].radius, impact_rings[i].max_radius, t * 0.5)
		i -= 1
	# Update slash trails
	i = melee_slash_trails.size() - 1
	while i >= 0:
		melee_slash_trails[i].timer -= delta
		if melee_slash_trails[i].timer <= 0:
			melee_slash_trails.remove_at(i)
		i -= 1
	# Landing dust
	if landing_dust_timer > 0:
		landing_dust_timer -= delta

func spawn_impact_ring(offset: Vector2, radius: float, color: Color, width: float):
	# AAA Upgrade: Enhanced impact rings with expansion and distortion
	impact_rings.append({
		"offset": offset,
		"radius": radius,
		"max_radius": radius * 3.0,  # Expand to 3x size
		"color": color,
		"width": width,
		"timer": 0.5,  # Longer lifetime for better visibility
		"max_timer": 0.5,
		"distortion": 8.0  # Visual distortion strength
	})

func spawn_melee_slash(offset: Vector2, color: Color, slash_scale: float = 1.0):
	melee_slash_trails.append({
		"offset": offset, "color": color, "scale": slash_scale, "timer": 0.2
	})

# --- Drawing (Brotato-style enhanced) ---

func _draw_editor_preview():
	"""Simplified preview when scene is open in editor (no game context)."""
	var tex = sprite_texture
	if tex == null:
		tex = load("res://assets/WilliamPlayer.png") as Texture2D
		if tex == null:
			return
	var ts = tex.get_size()
	var base_scale = SPRITE_HEIGHT / ts.y
	var scale_y = base_scale
	var feet_offset_in_tex = (ts.y / 2.0) - sprite_feet_padding
	var feet_in_display = feet_offset_in_tex * scale_y
	var sprite_y = BODY_RADIUS - feet_in_display
	# Shadow
	_draw_shadow_ellipse(Rect2(-45, 26, 90, 24), Color(0, 0, 0, 0.4))
	# Sprite (facing right)
	draw_set_transform(Vector2(0, sprite_y), 0, Vector2(base_scale, scale_y))
	draw_texture(tex, -ts / 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw():
	# Editor preview: show sprite when scene is open standalone (no game context)
	if Engine.is_editor_hint() and game == null:
		_draw_editor_preview()
		return

	# Blink when invincible (but not during dash or grapple - those keep player visible)
	if invincibility_timer > 0 and not is_dashing and not is_grappling and fmod(invincibility_timer, 0.12) < 0.06:
		if _use_shader_visual and character_visual:
			character_visual.visible = false
		return
	elif _use_shader_visual and character_visual:
		character_visual.visible = true

	# AAA Visual Overhaul: Update shader visual transforms
	if _use_shader_visual and character_visual:
		_update_player_shader_visual()
		# Flash on hit
		if hit_flash_timer > 0 and character_visual.flash_timer <= 0:
			character_visual.trigger_flash(0.1)
		# Skip sprite drawing but continue with effects (grapple, aim, trails, etc.)
		# Don't return early - let effects draw below

	var flash = hit_flash_timer > 0

	# AAA: Draw dash wind streaks (subtle motion lines)
	if is_dashing:
		var wind_count = 8
		for i in range(wind_count):
			var offset_dist = randf_range(20.0, 50.0)
			var offset_angle = dash_direction.angle() + randf_range(-0.3, 0.3)
			var offset = Vector2(cos(offset_angle), sin(offset_angle)) * offset_dist
			var wind_alpha = randf_range(0.1, 0.3) * (1.0 - dash_timer / DASH_DURATION)
			var wind_length = randf_range(8.0, 16.0)
			var wind_end = offset + Vector2(cos(offset_angle), sin(offset_angle)) * wind_length
			draw_line(offset, wind_end, Color(0.8, 0.9, 1.0, wind_alpha), 2.0)

	# Phase 4.4: Draw dash afterimages (3-4 fading sprites, alpha 0.7→0)
	# Works for both sprite_texture and CharacterVisual modes
	if dash_trail.size() > 0:
		if sprite_texture and not _use_shader_visual:
			var tex_size = sprite_texture.get_size()
			var ds = SPRITE_HEIGHT / tex_size.y
			for gi in range(dash_trail.size()):
				var ghost = dash_trail[gi]
				var ghost_offset = ghost.pos - position
				var g_flip = ghost.angle < -PI / 2.0 or ghost.angle > PI / 2.0
				var g_fs = -1.0 if g_flip else 1.0
				# Phase 4.4: 0.7→0 alpha gradient across 3-4 ghosts
				var trail_alpha = ghost.alpha * 0.7
				draw_set_transform(
					Vector2(ghost_offset.x, ghost_offset.y - tex_size.y * ds * 0.32),
					0, Vector2(ds * g_fs * 1.1, ds * 0.9)
				)
				draw_texture(sprite_texture, -tex_size / 2.0, Color(0.4, 0.7, 1.0, trail_alpha))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# AAA Upgrade: Draw combo visual trails
	for trail in combo_visual_trails:
		_draw_combo_trail(trail)

	# AAA Upgrade: Draw cape/hair trail (spring physics)
	if cape_trail_points.size() > 1:
		for i in range(1, cape_trail_points.size()):
			var alpha = 1.0 - (float(i) / float(cape_trail_points.size()))
			var trail_offset = cape_trail_points[i] - position
			var trail_color = Color(0.2, 0.15, 0.3, alpha * 0.4)
			var trail_width = 4.0 * alpha
			if i < cape_trail_points.size() - 1:
				var next_offset = cape_trail_points[i + 1] - position
				draw_line(trail_offset, next_offset, trail_color, trail_width)

	# Draw dinosaur mount (behind player)
	if has_dino_mount:
		_draw_dino_mount()

	# Sprint speed lines
	if is_sprinting and is_moving:
		var _sprint_dir = -Vector2.from_angle(facing_angle)
		for si in range(4):
			var line_angle = facing_angle + PI + randf_range(-0.3, 0.3)
			var line_start = Vector2.from_angle(line_angle) * 20.0
			var line_end = line_start + Vector2.from_angle(line_angle) * 18.0
			var line_alpha = 0.2 + 0.15 * sin(walk_anim + si * 1.5)
			draw_line(line_start, line_end, Color(1.0, 1.0, 1.0, line_alpha), 1.5)

	# Enhanced shadow with depth-based scaling and directional offset
	var shadow_pulse = 1.0
	if is_dashing:
		shadow_pulse = 1.3
	elif is_moving:
		shadow_pulse = 1.0 + abs(sin(walk_anim)) * 0.12

	# Apply depth scaling to shadow
	var shadow_depth_scale = 1.0
	var shadow_offset_x = 0.0
	var shadow_offset_y = 26.0
	var _shadow_alpha = 0.4
	if in_sideview_mode and game:
		shadow_depth_scale = DepthPlanes.get_scale_for_y(position.y)
		# Directional shadow: offset more for entities farther from camera
		var y_factor = (position.y - 280.0) / 300.0
		shadow_offset_x = y_factor * 6.0  # Shadow shifts right/left based on depth
		shadow_offset_y = 26.0 + abs(y_factor) * 4.0  # Shadow moves down slightly
		_shadow_alpha = clampf(0.35 + y_factor * 0.1, 0.25, 0.45)  # Fade far shadows

	var shadow_w = 90.0 * shadow_pulse * shadow_depth_scale
	if has_dino_mount:
		shadow_w *= 1.4
	# AAA Upgrade: Use soft shadow with depth-based parameters
	_draw_shadow_soft(shadow_w / 2, position.y, shadow_pulse, shadow_offset_x, shadow_offset_y)

	# Flip based on facing direction
	var flip = facing_angle < -PI / 2.0 or facing_angle > PI / 2.0
	var flip_sign = -1.0 if flip else 1.0
	var sprite_xform = Transform2D.IDENTITY

	# Current combo config (for animation)
	var active_combo = ((combo_index - 1) + COMBO_COUNT) % COMBO_COUNT if combo_window > 0 else 0

	# Draw sprite (skip if using CharacterVisual shader system)
	if sprite_texture and not _use_shader_visual:
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
			var _dash_t = dash_timer / DASH_DURATION
			offset_x = dash_direction.x * 8.0
			offset_y = dash_direction.y * 8.0 - 6.0
			tilt = dash_direction.angle() * 0.15
			scale_x = base_scale * 1.25
			scale_y = base_scale * 0.8
		elif is_grappling:
			# Grapple: stretched toward target, avoid extreme scales that cause invisibility
			var to_target = grapple_target - position
			var dist = to_target.length()
			if dist > 1.0:
				var dir_n = to_target / dist
				offset_x = dir_n.x * 12.0
				offset_y = dir_n.y * 12.0
				tilt = dir_n.angle() * 0.2 * (-1.0 if dir_n.x < 0 else 1.0)
			scale_x = base_scale * 1.1
			scale_y = base_scale * 1.1
		elif is_blocking:
			# Block: hunch down, widen stance
			var block_breath = sin(block_hold_time * 6.0) * 0.02
			offset_y = 4.0  # Crouch down
			scale_x = base_scale * (1.1 + block_breath)
			scale_y = base_scale * (0.9 - block_breath)
			tilt = (facing_angle * 0.06) * flip_sign  # Slight lean into block direction
		elif is_attacking_melee:
			# CARTOON: Exaggerated combo animation - clear anticipation, strike, recovery
			var cfg = COMBO_CONFIGS[active_combo]
			var attack_dur = cfg.duration
			var t = melee_attack_timer / attack_dur  # 1 -> 0
			var punch = sin(t * PI)
			# Anticipation phase: wind-up before strike (first 25% of duration)
			var anticipation = 1.0 - clampf(t * 4.0, 0.0, 1.0)
			var strike = punch

			match active_combo:
				0:
					offset_x = cos(facing_angle) * strike * cfg.lunge
					offset_y = sin(facing_angle) * strike * cfg.lunge
					tilt = (anticipation * -0.2 + strike * 0.35) * flip_sign
					scale_x = base_scale * (1.0 - anticipation * 0.12 + strike * 0.22)
					scale_y = base_scale * (1.0 + anticipation * 0.08 - strike * 0.18)
				1:
					offset_x = cos(facing_angle) * strike * cfg.lunge
					offset_y = sin(facing_angle) * strike * cfg.lunge - strike * 14.0
					tilt = (anticipation * 0.15 + strike * -0.22) * flip_sign
					scale_x = base_scale * (1.0 - anticipation * 0.08 - strike * 0.12)
					scale_y = base_scale * (1.0 + anticipation * 0.06 + strike * 0.28)
				2:
					offset_x = cos(facing_angle) * strike * cfg.lunge
					offset_y = sin(facing_angle) * strike * cfg.lunge
					tilt = (anticipation * 0.3 + t * TAU * 0.75) * flip_sign
					scale_x = base_scale * (1.0 - anticipation * 0.15 + strike * 0.35)
					scale_y = base_scale * (1.0 + anticipation * 0.1 + strike * 0.22)
		elif is_moving:
			# Walk: lean + squash/stretch (no vertical bob - keeps feet on ground)
			var step = sin(walk_anim)
			var step2 = cos(walk_anim)
			offset_y = abs(step) * 1.0  # Slight dip instead of lift - prevents floating
			tilt = step * 0.10 * flip_sign
			scale_x = base_scale * (1.0 + step2 * 0.07)
			scale_y = base_scale * (1.0 - step2 * 0.07)
		else:
			# Idle: amplified breathing
			var breath = sin(idle_time * 2.0)
			scale_y = base_scale * (1.0 + breath * 0.04)
			scale_x = base_scale * (1.0 - breath * 0.025)

		# Apply perspective depth scaling (makes entities smaller when higher on screen)
		if in_sideview_mode and game:
			var depth_scale = DepthPlanes.get_scale_for_y(position.y)
			# Add slight vertical squash to simulate perspective foreshortening
			var y_factor = clampf((position.y - 280.0) / 300.0, -0.3, 0.3)  # 280 is middle ground
			var perspective_squash = 1.0 - abs(y_factor) * 0.08  # Subtle vertical compression
			scale_x *= depth_scale
			scale_y *= depth_scale * perspective_squash

		# Apply spring squash factor (clamp to prevent invisibility from extreme values)
		scale_y *= squash_factor
		scale_x *= (2.0 - squash_factor)
		scale_x = clampf(scale_x, base_scale * 0.25, base_scale * 2.5)
		scale_y = clampf(scale_y, base_scale * 0.25, base_scale * 2.5)

		# Align character's feet (not texture bottom) to BODY_RADIUS - sprite_feet_padding = empty pixels below feet in texture
		var feet_offset_in_tex = (tex_size.y / 2.0) - sprite_feet_padding  # from center to visual feet
		var feet_in_display = feet_offset_in_tex * scale_y
		var sprite_y = BODY_RADIUS - feet_in_display + offset_y

		# Draw afterimage trails (body only, no weapons)
		for trail in trail_history:
			var trail_offset = trail.pos - position
			draw_set_transform(
				Vector2(trail_offset.x + offset_x, trail_offset.y + sprite_y),
				tilt,
				Vector2(scale_x * flip_sign, scale_y)
			)
			draw_texture(sprite_texture, -tex_size / 2.0, Color(0.3, 0.6, 1.0, trail.alpha))

		# CARTOON: Bold outline for strong silhouette (2 layers: dark core + softer edge)
		var outline_scale = 1.12
		# Outer soft edge (warm shadow tone)
		draw_set_transform(
			Vector2(offset_x, sprite_y),
			tilt,
			Vector2(scale_x * flip_sign * outline_scale, scale_y * outline_scale)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(0.08, 0.05, 0.15, 0.6))
		# Inner crisp edge (strong readable silhouette)
		var inner_outline = 1.05
		draw_set_transform(
			Vector2(offset_x, sprite_y),
			tilt,
			Vector2(scale_x * flip_sign * inner_outline, scale_y * inner_outline)
		)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(0.02, 0.01, 0.08, 0.9))

		# CARTOON: Stylized rim lighting (soft bright edge from key light - upper-left)
		# Key light direction: (-1, -1) normalized -> top-left
		var rim_offset = Vector2(-flip_sign * 3.0, -4.0)
		var rim_scale = 1.04
		draw_set_transform(
			Vector2(offset_x + rim_offset.x, sprite_y + rim_offset.y),
			tilt,
			Vector2(scale_x * flip_sign * rim_scale, scale_y * rim_scale)
		)
		# Warm highlight on lit edge (amber-white)
		draw_texture(sprite_texture, -tex_size / 2.0, Color(1.0, 0.95, 0.85, 0.45))

		# Draw main sprite
		sprite_xform = Transform2D(tilt, Vector2(scale_x * flip_sign, scale_y), 0.0, Vector2(offset_x, sprite_y))
		draw_set_transform(Vector2(offset_x, sprite_y), tilt, Vector2(scale_x * flip_sign, scale_y))
		if flash:
			draw_texture(sprite_texture, -tex_size / 2.0, Color(4.0, 4.0, 4.0, 1.0))
		else:
			draw_texture(sprite_texture, -tex_size / 2.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# AAA Upgrade: Draw limb IK (feet)
	if is_on_ground:
		# Left foot
		draw_circle(limb_foot_l, 3.0, Color(0.3, 0.25, 0.2, 0.6))
		draw_line(Vector2(0, BODY_RADIUS - 5), limb_foot_l, Color(0.3, 0.25, 0.2, 0.4), 2.0)
		# Right foot
		draw_circle(limb_foot_r, 3.0, Color(0.3, 0.25, 0.2, 0.6))
		draw_line(Vector2(0, BODY_RADIUS - 5), limb_foot_r, Color(0.3, 0.25, 0.2, 0.4), 2.0)

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

	# Grapple line visual — Phase 6.3: Catmull-Rom spline, 8 segments, gradient alpha
	if is_grappling:
		var line_end_world = grapple_target - position
		var line_end = line_end_world * grapple_line_progress
		var line_len = line_end.length()

		if line_len > 0.1:
			# Phase 6.3: Catmull-Rom spline from player to anchor using 4 control points
			# p0 = behind player, p1 = player (origin), p2 = anchor, p3 = ahead of anchor
			var perp_dir = Vector2(-line_end.normalized().y, line_end.normalized().x)
			var sag = minf(line_len * 0.2, 40.0) * (1.0 - grapple_line_progress * 0.5)  # Gravity sag
			var p0 = -line_end.normalized() * 30.0  # Behind player
			var p1 = Vector2.ZERO                   # Player origin
			var p2 = line_end + perp_dir * sag * 0.3 + Vector2(0, sag)  # Sag point
			var p3 = line_end + line_end.normalized() * 20.0  # Ahead of anchor

			const CATMULL_SEGS = 8
			var pts: Array[Vector2] = []
			for si in range(CATMULL_SEGS + 1):
				var t = float(si) / float(CATMULL_SEGS)
				# Catmull-Rom with alpha=0.5
				var t2 = t * t
				var t3 = t2 * t
				var c0 = -t3 + 2.0 * t2 - t
				var c1 = 3.0 * t3 - 5.0 * t2 + 2.0
				var c2 = -3.0 * t3 + 4.0 * t2 + t
				var c3 = t3 - t2
				pts.append(0.5 * (c0 * p0 + c1 * p1 + c2 * p2 + c3 * p3))

			for si in range(CATMULL_SEGS):
				var frac = float(si) / float(CATMULL_SEGS)
				var seg_alpha = lerpf(0.85, 0.25, frac)  # Gradient: opaque at player, fade at anchor
				var seg_width = lerpf(3.0, 1.0, frac)    # Tapers to anchor
				# Glow pass
				draw_line(pts[si], pts[si + 1], Color(0.4, 0.8, 1.0, seg_alpha * 0.4), seg_width + 2.5)
				# Core pass
				draw_line(pts[si], pts[si + 1], Color(0.7, 0.9, 1.0, seg_alpha), seg_width)

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

	# AAA Upgrade: Draw impact rings with distortion effect
	for ring in impact_rings:
		var t = ring.timer / ring.max_timer
		var alpha = t * ring.color.a
		var current_color = Color(ring.color.r, ring.color.g, ring.color.b, alpha)

		# Main ring
		draw_arc(ring.offset, ring.radius, 0, TAU, 32, current_color, ring.width * t)

		# Distortion effect: Draw offset rings for wave/distortion feel
		if ring.distortion > 0 and t > 0.3:
			var distort_offset = ring.distortion * (1.0 - t)
			var distort_alpha = alpha * 0.4
			draw_arc(ring.offset, ring.radius - distort_offset, 0, TAU, 24,
				Color(current_color.r, current_color.g, current_color.b, distort_alpha), ring.width * t * 0.6)
			draw_arc(ring.offset, ring.radius + distort_offset, 0, TAU, 24,
				Color(current_color.r, current_color.g, current_color.b, distort_alpha), ring.width * t * 0.6)

	# Draw melee slash trails
	for slash in melee_slash_trails:
		var t = slash.timer / 0.2
		var alpha = t * slash.color.a
		var r = 30.0 * slash.scale * (1.0 + (1.0 - t) * 0.3)
		var col = Color(slash.color.r, slash.color.g, slash.color.b, alpha)
		draw_arc(slash.offset, r, -0.5, 0.5, 12, col, 3.0 * slash.scale * t)

	# Wall slide sparks
	if is_wall_sliding:
		var spark_x = wall_slide_dir * BODY_RADIUS
		for si in range(3):
			var sy = randf_range(-10, 10)
			draw_circle(Vector2(spark_x, sy), randf_range(1.0, 2.5), Color(1.0, 0.8, 0.3, randf_range(0.3, 0.7)))

	# Parry counter flash
	if parry_counter_active:
		var counter_t = parry_counter_timer / PARRY_COUNTER_DURATION
		draw_circle(Vector2.ZERO, 35.0 * (1.0 - counter_t), Color(1.0, 0.85, 0.0, counter_t * 0.4))

func _draw_combo_trail(trail: Dictionary):
	"""AAA Upgrade: Draw combo visual trail effect."""
	var t = trail["timer"] / trail["max_time"]
	var alpha = 1.0 - t
	var col = Color(trail["color"].r, trail["color"].g, trail["color"].b, alpha * 0.7)
	var offset = trail["pos"] - position

	match trail["type"]:
		"arc":
			# White arc slash
			var arc_radius = 30.0 * (1.0 - t * 0.5)
			var arc_width = PI * 0.6
			var arc_start = trail["angle"] - arc_width * 0.5
			draw_arc(offset, arc_radius, arc_start, arc_start + arc_width, 12, col, 3.0)
		"line":
			# Yellow thrust trail
			var line_len = 40.0 * (1.0 - t * 0.3)
			var dir = Vector2.from_angle(trail["angle"])
			draw_line(offset, offset + dir * line_len, col, 4.0)
			draw_circle(offset + dir * line_len, 4.0, Color(col.r, col.g, col.b, alpha * 0.5))
		"vortex":
			# Red spinning vortex
			var vortex_radius = 35.0 * (1.0 - t * 0.4)
			var spin_angle = t * TAU * 2.0  # 2 full rotations
			for i in range(3):
				var spoke_angle = trail["angle"] + spin_angle + (i * TAU / 3.0)
				var spoke_start = offset + Vector2.from_angle(spoke_angle) * 10.0
				var spoke_end = offset + Vector2.from_angle(spoke_angle) * vortex_radius
				draw_line(spoke_start, spoke_end, col, 3.0)

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

func _draw_shadow_soft(body_radius: float, depth_y: float, pulse: float = 1.0, offset_x: float = 0.0, offset_y: float = 26.0):
	"""CARTOON: Strong contact shadow - dark core + soft falloff for weight and grounding."""
	var shadow_alpha = DepthPlanes.get_shadow_alpha_for_y(depth_y)
	var shadow_scale = DepthPlanes.get_shadow_scale_for_y(depth_y)
	var shadow_offset = Vector2(offset_x, offset_y)

	# CARTOON: Strong dark contact core (clear shape, no muddiness)
	var core_radius_x = body_radius * shadow_scale * pulse * 0.85
	var core_radius_y = core_radius_x * 0.4
	var contact_alpha = minf(0.85, shadow_alpha * 1.4)
	var core_points = PackedVector2Array()
	for j in range(16):
		var angle = float(j) / 16.0 * TAU
		var px = shadow_offset.x + cos(angle) * core_radius_x
		var py = shadow_offset.y + sin(angle) * core_radius_y
		core_points.append(Vector2(px, py))
	# Slightly cool shadow tint (cartoon rule: cool in shadows)
	draw_polygon(core_points, PackedColorArray([Color(0.05, 0.05, 0.12, contact_alpha)]))

	# Soft outer gradient (2 layers for transition)
	var layers = 2
	for i in range(layers):
		var layer_t = float(i + 1) / float(layers + 1)
		var radius_x = core_radius_x * (1.0 + layer_t * 0.5)
		var radius_y = core_radius_y * (1.0 + layer_t * 0.5)
		var alpha = shadow_alpha * 0.4 * (1.0 - layer_t)
		var color = Color(0.08, 0.06, 0.15, alpha)
		var points = PackedVector2Array()
		for j in range(12):
			var angle = float(j) / 12.0 * TAU
			var px = shadow_offset.x + cos(angle) * radius_x
			var py = shadow_offset.y + sin(angle) * radius_y
			points.append(Vector2(px, py))
		draw_polygon(points, PackedColorArray([color]))

func _draw_shadow_ellipse(rect: Rect2, _color: Color):
	"""Legacy shadow function - redirects to soft shadow for backward compatibility."""
	var center_x = rect.position.x + rect.size.x / 2.0
	var center_y = rect.position.y + rect.size.y / 2.0
	var body_radius = rect.size.x / 2.0
	_draw_shadow_soft(body_radius, position.y, 1.0, center_x, center_y)
