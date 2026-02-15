@tool
class_name LevelFloorSegment
extends Node2D
## Draggable floor segment. Position = top-left corner. Resize in Inspector.

@export var size: Vector2 = Vector2(800, 64)

func _draw():
	var rect = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.4, 0.35, 0.25))
	draw_rect(rect, Color(0.3, 0.25, 0.2), false, 3.0)
