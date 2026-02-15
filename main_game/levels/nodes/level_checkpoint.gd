@tool
class_name LevelCheckpoint
extends Node2D
## Checkpoint marker. Position = center. Drag to move, Delete to remove.

func _draw():
	# Green diamond/marker
	draw_rect(Rect2(-24, -36, 48, 72), Color(0.2, 0.7, 0.35))
	draw_rect(Rect2(-24, -36, 48, 72), Color(0.3, 0.85, 0.5), false, 2.0)
