@tool
class_name LevelGrappleAnchor
extends Node2D
## Grapple anchor point. Position = center. Drag to move, Delete to remove.

func _draw():
	# Blue ring
	draw_rect(Rect2(-12, -12, 24, 24), Color(0.3, 0.6, 0.95))
	draw_rect(Rect2(-12, -12, 24, 24), Color(0.5, 0.75, 1.0), false, 2.0)
