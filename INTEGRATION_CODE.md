# Integration Code - Copy & Paste Ready

## Add to player.gd

### 1. Add these variables at the top (around line 260):

```gdscript
# AAA Animation System
var sprite_animator: SpriteAnimator = null
var animation_frames_loaded: bool = false
```

### 2. Modify your `_setup_player_shader_visual()` function:

Find this function (around line 807) and replace it with:

```gdscript
func _setup_player_shader_visual(game):
	if not sprite_texture:
		return

	var theme = game.map.level_config.get("theme", "grass")

	_use_shader_visual = true
	character_visual = CharacterVisual.new()
	character_visual.name = "Visual"
	add_child(character_visual)

	# Set up visual with sprite
	character_visual.setup(sprite_texture, {
		"outline_width": 1.5,
		"outline_color": CartoonPalette.get_outline_color(theme),
		"tint": skin_tint if skin_tint != Color.WHITE else Color.WHITE
	})
	character_visual.set_theme_lighting(theme)

	# NEW: Set up sprite animator
	sprite_animator = SpriteAnimator.new()
	sprite_animator.setup(character_visual)

	# Load animation frames (AI-generated or placeholders)
	var frames = SpriteFrameLoader.load_character_frames("player")
	sprite_animator.set_sprite_frames(frames)
	animation_frames_loaded = true

	print("[Player] Animation system ready - %s" % SpriteFrameLoader.get_frame_status())
```

### 3. Modify your `_update_player_shader_visual()` function:

Find this function (around line 770) and add animation update:

```gdscript
func _update_player_shader_visual():
	if not character_visual or not sprite_texture:
		return

	# Determine flip
	var flip = facing_angle < -PI/2 or facing_angle > PI/2
	var flip_sign = -1.0 if flip else 1.0

	# Base scale with squash factor
	var scale_x = squash_factor
	var scale_y = 1.0 / squash_factor if squash_factor > 0.1 else 1.0

	# NEW: Add animation squash/stretch
	if sprite_animator and animation_frames_loaded:
		var anim_squash = sprite_animator.get_squash_multiplier()
		scale_x *= anim_squash.x
		scale_y *= anim_squash.y

	# Apply depth scaling (from DepthPlanes)
	if game and game.has_method("get_depth_scale_at_y"):
		var depth_scale = game.get_depth_scale_at_y(position.y)
		scale_x *= depth_scale
		scale_y *= depth_scale

	# Apply dash stretch
	if is_dashing:
		scale_x *= 1.25
		scale_y *= 0.8

	# NEW: Update animation state
	if sprite_animator and animation_frames_loaded:
		var anim_state = "idle"
		if is_attacking_melee:
			anim_state = "attack"
		elif is_dashing:
			anim_state = "run"

		sprite_animator.update_animation(get_physics_process_delta_time(), anim_state, velocity, is_on_ground)

		# Apply animation offsets
		var anim_offset = sprite_animator.get_animation_offset()
		character_visual.position = Vector2(anim_offset.x, sprite_y + anim_offset.y)

		# Apply animation rotation
		var anim_rotation = sprite_animator.get_rotation_offset()
		character_visual.update_transform(flip, Vector2(scale_x * flip_sign, scale_y), anim_rotation)
	else:
		# Fallback: no animation
		character_visual.position = Vector2(0, sprite_y)
		character_visual.update_transform(flip, Vector2(scale_x * flip_sign, scale_y), 0.0)
```

### 4. Done!

That's it! The system will now:
- ✅ Load your AI-generated sprites when you add them
- ✅ Use placeholders in the meantime
- ✅ Smoothly animate between the 3 frames
- ✅ Add squash/stretch automatically
- ✅ Apply bob, tilt, and rotation
- ✅ Work with all the existing shader effects

## Testing

1. Run the game now - you'll see placeholder colored rectangles animating
2. When you get your AI sprites, just drop them in `assets/sprites/player/`
3. Restart the game - they'll automatically load and animate!

## Where to Put AI-Generated Sprites

Create this folder structure:
```
C:\Users\tobia\Desktop\SnakeGameGodot\assets\sprites\player\
```

Then save your 3 AI-generated PNGs as:
- `player_idle.png`
- `player_walk_mid.png`
- `player_walk_extended.png`

The system will automatically detect and use them! 🎨
