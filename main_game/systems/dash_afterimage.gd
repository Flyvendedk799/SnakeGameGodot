class_name DashAfterimage
extends Node2D

## Phase 4.4: Dash afterimage / ghost trail system.
## Records player visual snapshots during a dash and fades them out.
## Usage:
##   var afterimage = DashAfterimage.new()
##   add_child(afterimage)
##   afterimage.start_trail(player_node)   # call when dash begins
##   afterimage.stop_trail()               # call when dash ends (auto-stops on timeout)
##   # update() and draw() called automatically by Godot since it is a Node2D

# ---- Configuration ----
const MAX_GHOSTS: int     = 8      # How many ghost frames to keep
const SNAPSHOT_INTERVAL   = 0.025  # Seconds between snapshots
const GHOST_LIFETIME      = 0.35   # Seconds each ghost is visible
const BASE_ALPHA          = 0.55   # Starting alpha
const TRAIL_DURATION      = 0.65   # Auto-stop trail after this long without stop_trail()

# ---- Internal state ----
var _active: bool = false
var _source: Node2D = null         # Player node
var _snapshot_timer: float = 0.0
var _trail_watchdog: float = 0.0

# Ghost frame: {pos, scale, flip_h, color, age, lifetime}
var _ghosts: Array = []

# Theme-tint options: set by caller or auto from game
var trail_color: Color = Color(0.4, 0.7, 1.0, 1.0)  # Default: dash blue

func start_trail(source: Node2D, tint: Color = Color(0.4, 0.7, 1.0, 1.0)):
	_source = source
	trail_color = tint
	_active = true
	_snapshot_timer = 0.0
	_trail_watchdog = 0.0
	_take_snapshot()

func stop_trail():
	_active = false
	_source = null

func _process(delta: float):
	# Age and prune ghosts
	for g in _ghosts:
		g.age += delta
	_ghosts = _ghosts.filter(func(g): return g.age < g.lifetime)

	if not _active:
		if _ghosts.is_empty():
			return  # Nothing to draw - idle
		queue_redraw()
		return

	# Watchdog: auto-stop if source disappeared or trail ran too long
	_trail_watchdog += delta
	if not is_instance_valid(_source) or _trail_watchdog > TRAIL_DURATION:
		stop_trail()
		queue_redraw()
		return

	# Periodic snapshot
	_snapshot_timer -= delta
	if _snapshot_timer <= 0.0:
		_snapshot_timer = SNAPSHOT_INTERVAL
		_take_snapshot()

	queue_redraw()

func _take_snapshot():
	if not is_instance_valid(_source):
		return

	# Limit ghost count
	if _ghosts.size() >= MAX_GHOSTS:
		_ghosts.remove_at(0)

	# Capture player visual properties
	var visual_size = Vector2(32, 48)  # Fallback size
	var flip_h = false
	var sprite_frames: SpriteFrames = null
	var frame_idx: int = 0
	var anim_name: String = "idle"

	# Try to read AnimatedSprite2D from CharacterVisual or direct child
	var character_visual = _source.get("character_visual")
	var sprite: AnimatedSprite2D = null
	if character_visual and character_visual.get("sprite"):
		sprite = character_visual.sprite
	else:
		for child in _source.get_children():
			if child is AnimatedSprite2D:
				sprite = child
				break

	if sprite:
		flip_h      = sprite.flip_h
		sprite_frames = sprite.sprite_frames
		frame_idx    = sprite.frame
		anim_name    = sprite.animation
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
			var tex = sprite.sprite_frames.get_frame_texture(anim_name, frame_idx)
			if tex:
				visual_size = tex.get_size() * sprite.scale

	_ghosts.append({
		"pos":    _source.global_position,
		"scale":  _source.scale if sprite == null else sprite.scale,
		"flip_h": flip_h,
		"sprite_frames": sprite_frames,
		"frame_idx":     frame_idx,
		"anim_name":     anim_name,
		"visual_size":   visual_size,
		"color":  trail_color,
		"age":    0.0,
		"lifetime": GHOST_LIFETIME,
	})

func _draw():
	if _ghosts.is_empty():
		return

	for i in range(_ghosts.size()):
		var g = _ghosts[i]
		var t = clampf(g.age / g.lifetime, 0.0, 1.0)
		var alpha = BASE_ALPHA * (1.0 - t * t)  # Quadratic fade-out
		if alpha < 0.01:
			continue

		var tint = Color(g.color.r, g.color.g, g.color.b, alpha)
		# Local draw pos (relative to this Node2D origin which is at Vector2(0,0))
		var local_pos = to_local(g.pos)
		var w = g.visual_size.x
		var h = g.visual_size.y

		# Try to draw the captured sprite frame
		if g.sprite_frames and g.sprite_frames.has_animation(g.anim_name):
			var tex = g.sprite_frames.get_frame_texture(g.anim_name, g.frame_idx)
			if tex:
				var draw_w = g.scale.x * tex.get_width()
				var draw_h = g.scale.y * tex.get_height()
				var flip_offset = -draw_w if g.flip_h else 0.0
				var dest = Rect2(
					local_pos.x - draw_w * 0.5 + flip_offset,
					local_pos.y - draw_h,
					draw_w if not g.flip_h else -draw_w,
					draw_h
				)
				draw_texture_rect(tex, dest, false, tint)
				continue

		# Fallback: simple silhouette rectangle
		draw_rect(Rect2(local_pos.x - w * 0.5, local_pos.y - h, w, h), tint)
