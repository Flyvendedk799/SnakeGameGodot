class_name SpriteAnimator
extends Node

## AAA Visual Overhaul: Sprite frame animation system
## Phase 3.1: Explicit AnimationState enum with blend times (0.05s WALK↔SPRINT)
## Animation events: callbacks at strike frame for FX sync (on_land_frame, on_dash_start_frame)
## Designed to work with just 3 frames + interpolation for smooth 60fps animation

## Phase 3.1: Explicit animation state enum
enum AnimationState {
	IDLE,
	WALK,
	SPRINT,
	JUMP_ASCEND,
	JUMP_FALL,
	LAND,
	MELEE_ANTICIPATE,
	MELEE_STRIKE,
	MELEE_RECOVERY,
	DASH,
	GROUND_POUND,
	GRAPPLE,
	BLOCK,
	HURT,
	DEATH,
}

var character_visual: CharacterVisual = null
var animation_player: AnimationPlayer = null
var current_state: String = "idle"
var anim_state: AnimationState = AnimationState.IDLE   # Phase 3.1: typed state
var prev_anim_state: AnimationState = AnimationState.IDLE
var sprite_frames: Dictionary = {}

# Animation state
var walk_cycle_time: float = 0.0
var attack_time: float = 0.0
var current_frame: String = "idle"
var combo_index: int = 0

# Phase 3.1: Blend times
var blend_time: float = 0.0
var blend_duration: float = 0.1
var previous_state: String = "idle"
var transition_t: float = 0.0  # 0→1 transition progress

# Phase 3.1: Animation event callbacks (assigned by entity)
var on_land_frame: Callable          # Called at land frame
var on_dash_start_frame: Callable    # Called at dash start frame
var on_strike_frame: Callable        # Called at melee strike frame

# Walk cycle timing (for 3-frame walk)
const WALK_CYCLE_SPEED: float = 6.0  # Cycles per second
const ATTACK_WINDUP_DURATION: float = 0.25  # Wind-up phase (anticipation) - 15 frames at 60fps
const ATTACK_STRIKE_DURATION: float = 0.30  # Strike phase (impact) - 18 frames at 60fps
const FRAME_TRANSITIONS = {
	"idle": ["idle"],
	"walk": ["idle", "walk_mid", "walk_extended", "walk_mid"],  # 4-phase cycle
	"run": ["idle", "walk_mid", "walk_extended", "walk_mid"],   # Same but faster
	"jump": ["walk_extended"],  # Extended pose for jump
	"fall": ["walk_mid"],       # Mid pose for fall
	"land": ["idle"],           # Compress on landing
	"attack": ["attack_windup", "attack_strike"],  # Wind-up then strike
}

func setup(visual: CharacterVisual):
	"""Initialize with CharacterVisual reference."""
	character_visual = visual

func set_sprite_frames(frames: Dictionary):
	"""Set the sprite frame textures.
	Expected keys: 'idle', 'walk_mid', 'walk_extended', optionally 'attack_windup', 'attack_strike'
	"""
	sprite_frames = frames

func set_anim_state(new_state: AnimationState, blend: float = 0.05):
	"""Phase 3.1: Set typed animation state with blend time."""
	if new_state == anim_state:
		return
	prev_anim_state = anim_state
	anim_state = new_state
	transition_t = 0.0
	blend_duration = blend

	# Fire animation events
	match new_state:
		AnimationState.LAND:
			if on_land_frame.is_valid():
				on_land_frame.call()
		AnimationState.DASH:
			if on_dash_start_frame.is_valid():
				on_dash_start_frame.call()
		AnimationState.MELEE_STRIKE:
			if on_strike_frame.is_valid():
				on_strike_frame.call()
		AnimationState.MELEE_ANTICIPATE:
			# Visual squash for anticipation
			if character_visual:
				character_visual.squash_anticipate()
		_:
			pass

func update_animation(delta: float, state: String, velocity: Vector2, is_grounded: bool, combo_idx: int = 0):
	"""Update animation based on movement state."""
	combo_index = combo_idx

	# Determine animation state from movement
	var target_state = _get_animation_state(state, velocity, is_grounded)

	# Blend to new state
	if target_state != current_state:
		previous_state = current_state
		current_state = target_state
		blend_time = 0.0
		# Phase 3.1: Typed state transitions with blend
		_sync_typed_state(target_state, velocity, is_grounded)
		if current_state == "attack" and previous_state != "attack":
			attack_time = 0.0

	# Update Phase 3.1 transition blend
	if transition_t < 1.0:
		transition_t = minf(transition_t + delta / maxf(blend_duration, 0.001), 1.0)

	# Update blend
	if blend_time < blend_duration:
		blend_time = min(blend_time + delta, blend_duration)

	# Update walk cycle
	if current_state == "walk" or current_state == "run":
		var speed_mult = 1.5 if current_state == "run" else 1.0
		walk_cycle_time += delta * WALK_CYCLE_SPEED * speed_mult
		walk_cycle_time = fmod(walk_cycle_time, 1.0)

	# Update attack animation
	if current_state == "attack":
		attack_time += delta

	# Select and apply frame
	var frame_name = _get_current_frame()
	_apply_frame(frame_name)

func _sync_typed_state(target_str: String, velocity: Vector2, is_grounded: bool):
	"""Phase 3.1: Sync typed AnimationState from string state."""
	match target_str:
		"idle":   set_anim_state(AnimationState.IDLE, 0.08)
		"walk":   set_anim_state(AnimationState.WALK, 0.05)
		"run":    set_anim_state(AnimationState.SPRINT, 0.05)  # WALK↔SPRINT 0.05s blend
		"jump":   set_anim_state(AnimationState.JUMP_ASCEND, 0.04)
		"fall":   set_anim_state(AnimationState.JUMP_FALL, 0.04)
		"land":   set_anim_state(AnimationState.LAND, 0.03)
		"attack": set_anim_state(AnimationState.MELEE_ANTICIPATE, 0.02)
		"dash":   set_anim_state(AnimationState.DASH, 0.02)
		"block":  set_anim_state(AnimationState.BLOCK, 0.05)
		"hurt":   set_anim_state(AnimationState.HURT, 0.02)
		"death":  set_anim_state(AnimationState.DEATH, 0.04)

func _get_animation_state(state: String, velocity: Vector2, is_grounded: bool) -> String:
	"""Determine which animation state to use."""
	# Priority states that override velocity-based detection
	if state == "attack":
		return "attack"

	# Airborne states
	if not is_grounded:
		if velocity.y < -50:
			return "jump"
		elif velocity.y > 50:
			return "fall"

	# Ground movement states based on velocity
	var speed = abs(velocity.x)
	if speed > 200:
		return "run"
	elif speed > 30:
		return "walk"
	else:
		return "idle"

func _get_current_frame() -> String:
	"""Get the current frame name based on animation state and cycle time."""
	var frames = FRAME_TRANSITIONS.get(current_state, ["idle"])

	# Attack state - time-based transitions
	if current_state == "attack":
		# Check if we have attack frames, otherwise use extended for dynamic pose
		if sprite_frames.has("attack_windup") and sprite_frames.has("attack_strike"):
			if attack_time < ATTACK_WINDUP_DURATION:
				return "attack_windup"
			else:
				return "attack_strike"
		else:
			# Fallback: use walk_extended for a dynamic attack pose
			return "walk_extended"

	# Static states
	if current_state == "idle" or current_state == "jump" or current_state == "fall" or current_state == "land":
		return frames[0]

	# Walk/run cycle - interpolate through 4 phases
	var phase = int(walk_cycle_time * float(frames.size()))
	phase = clampi(phase, 0, frames.size() - 1)
	return frames[phase]

func _apply_frame(frame_name: String):
	"""Apply the sprite frame to CharacterVisual."""
	if not character_visual or not character_visual.sprite:
		return

	var texture = sprite_frames.get(frame_name)
	if texture:
		character_visual.set_texture(texture)
		current_frame = frame_name

func get_animation_offset() -> Vector2:
	"""Get procedural offset for animation enhancement (bob, sway, etc.)."""
	var offset = Vector2.ZERO

	# Attack position offset with combo-specific lunge
	if current_state == "attack":
		if attack_time < ATTACK_WINDUP_DURATION:
			# Wind-up: pull back slightly
			var t = attack_time / ATTACK_WINDUP_DURATION
			match combo_index:
				0:  # Jab - minimal pullback
					offset.x = -t * 4.0
				1:  # Cross - medium pullback
					offset.x = -t * 6.0
				2:  # Haymaker - BIG pullback
					offset.x = -t * 10.0
					offset.y = -t * 4.0  # Also rise up slightly
		else:
			# Strike: lunge forward
			var strike_t = (attack_time - ATTACK_WINDUP_DURATION) / ATTACK_STRIKE_DURATION
			var punch = sin(clampf(strike_t, 0.0, 1.0) * PI)
			match combo_index:
				0:  # Jab - quick forward snap
					offset.x = punch * 8.0
				1:  # Cross - strong lunge
					offset.x = punch * 14.0
				2:  # Haymaker - wide swing (less forward, more arc)
					offset.x = punch * 10.0
					offset.y = sin(strike_t * TAU) * 6.0  # Arc motion

	# Walking bob
	elif current_state == "walk" or current_state == "run":
		var bob_amount = 3.0 if current_state == "run" else 2.0
		offset.y = sin(walk_cycle_time * TAU) * bob_amount

	return offset

func get_rotation_offset() -> float:
	"""Get procedural rotation for animation enhancement."""
	var rotation = 0.0

	# Attack rotation with combo-specific variations
	if current_state == "attack":
		if attack_time < ATTACK_WINDUP_DURATION:
			# Wind-up: lean back clearly
			var t = attack_time / ATTACK_WINDUP_DURATION
			match combo_index:
				0:  # Jab - minimal windup rotation
					rotation = -t * 0.12
				1:  # Cross - medium windup
					rotation = -t * 0.20
				2:  # Haymaker - BIG windup rotation (spin back)
					rotation = -t * 0.40
		else:
			# Strike: snap forward with force
			var strike_t = (attack_time - ATTACK_WINDUP_DURATION) / ATTACK_STRIKE_DURATION
			var punch = sin(clampf(strike_t, 0.0, 1.0) * PI)
			match combo_index:
				0:  # Jab - quick snap forward
					rotation = punch * 0.18
				1:  # Cross - strong forward lean
					rotation = punch * 0.28
				2:  # Haymaker - SPIN ATTACK! Full rotation through
					rotation = punch * 0.60  # ~34 degrees - massive spin

	# Slight tilt during walk
	elif current_state == "walk" or current_state == "run":
		var tilt_amount = 0.08 if current_state == "run" else 0.05
		rotation = sin(walk_cycle_time * TAU) * tilt_amount

	return rotation

func get_squash_multiplier() -> Vector2:
	"""Get squash/stretch multiplier for current animation phase."""
	var squash = Vector2.ONE

	# Attack squash/stretch with combo-specific variations
	if current_state == "attack":
		if attack_time < ATTACK_WINDUP_DURATION:
			# Wind-up: compress horizontally, stretch vertically (anticipation)
			var t = attack_time / ATTACK_WINDUP_DURATION
			match combo_index:
				0:  # Jab - quick, tight windup
					squash.x = 1.0 - t * 0.12
					squash.y = 1.0 + t * 0.10
				1:  # Cross - medium windup
					squash.x = 1.0 - t * 0.18
					squash.y = 1.0 + t * 0.15
				2:  # Haymaker - BIG windup, compress more
					squash.x = 1.0 - t * 0.28
					squash.y = 1.0 + t * 0.25
		else:
			# Strike: stretch horizontally, compress vertically (impact)
			var strike_t = (attack_time - ATTACK_WINDUP_DURATION) / ATTACK_STRIKE_DURATION
			var punch = sin(clampf(strike_t, 0.0, 1.0) * PI)
			match combo_index:
				0:  # Jab - quick snap
					squash.x = 1.0 + punch * 0.22
					squash.y = 1.0 - punch * 0.12
				1:  # Cross - strong horizontal stretch
					squash.x = 1.0 + punch * 0.35
					squash.y = 1.0 - punch * 0.18
				2:  # Haymaker - MASSIVE impact, wide stretch
					squash.x = 1.0 + punch * 0.50
					squash.y = 1.0 - punch * 0.28

	# Squash/stretch on walk cycle
	elif current_state == "walk" or current_state == "run":
		# Compress vertically when both feet touch ground (at 0 and 0.5)
		var cycle_phase = fmod(walk_cycle_time * 2.0, 1.0)
		if cycle_phase < 0.2:  # Landing phase
			var t = cycle_phase / 0.2
			squash.y = 1.0 - (1.0 - t) * 0.08  # Compress by 8%
			squash.x = 1.0 + (1.0 - t) * 0.04  # Widen by 4%
		elif cycle_phase > 0.4 and cycle_phase < 0.6:  # Mid-step stretch
			var t = (cycle_phase - 0.4) / 0.2
			squash.y = 1.0 + sin(t * PI) * 0.05  # Stretch by 5%
			squash.x = 1.0 - sin(t * PI) * 0.025  # Narrow by 2.5%

	return squash

## Helper function to create placeholder frames for testing
static func create_placeholder_frames(base_color: Color) -> Dictionary:
	"""Create simple colored rectangle placeholders for the 3 frames."""
	var frames = {}

	# Create 32x32 placeholder images
	for frame_name in ["idle", "walk_mid", "walk_extended"]:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)

		# Different shades for each frame
		var color = base_color
		if frame_name == "walk_mid":
			color = base_color.lightened(0.2)
		elif frame_name == "walk_extended":
			color = base_color.lightened(0.4)

		# Draw simple character shape
		img.fill(Color.TRANSPARENT)
		# Body
		for y in range(8, 28):
			for x in range(8, 24):
				img.set_pixel(x, y, color)
		# Head
		for y in range(4, 12):
			for x in range(10, 22):
				img.set_pixel(x, y, color.lightened(0.1))

		frames[frame_name] = ImageTexture.create_from_image(img)

	return frames
