@tool
class_name LevelGoal
extends Node2D
## Goal zone. Position = center. Resize in Inspector.

@export var size: Vector2 = Vector2(50, 220)

func _draw():
	var rect = Rect2(-size * 0.5, size)
	draw_rect(rect, Color(0.9, 0.75, 0.2))
	draw_rect(rect, Color(1.0, 0.9, 0.4), false, 3.0)
