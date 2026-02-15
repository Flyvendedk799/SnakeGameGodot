@tool
class_name LevelPlatform
extends Node2D
## Draggable floating platform. Position = center (drag point matches sprite).
## Size in Inspector controls both sprite display and hitbox. Scale gizmo multiplies both.
## Surface Fraction: how far down (0-1) the walkable top is in the texture. Tune if player floats.

var _size: Vector2 = Vector2(120, 24)
@export_range(0.0, 0.5) var surface_fraction: float = 0.28  # Walkable surface offset in texture

@export var size: Vector2:
	get: return _size
	set(v):
		if _size != v:
			_size = v
			_update_sprite()

const PLATFORM_TEXTURE_PATH = "res://assets/platform1.png"
var _sprite: Sprite2D = null

func _ready():
	# Load texture and create Sprite2D child (GPU-optimized, batched)
	var tex = load(PLATFORM_TEXTURE_PATH) as Texture2D
	if tex:
		_sprite = Sprite2D.new()
		_sprite.name = "PlatformSprite"
		_sprite.texture = tex
		_sprite.centered = true
		_sprite.position = Vector2.ZERO
		add_child(_sprite)
		_update_sprite()

func _update_sprite():
	if not _sprite or not _sprite.texture:
		return
	var ts = _sprite.texture.get_size()
	if ts.x <= 0 or ts.y <= 0:
		return
	# Scale sprite so it displays at _size in local coords (node scale handles the rest)
	_sprite.scale = _size / ts
