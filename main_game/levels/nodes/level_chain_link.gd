@tool
class_name LevelChainLink
extends Node2D
## Chain link (pit recovery grapple). Position = center.

func _draw():
	# Silver/ grey
	draw_rect(Rect2(-10, -8, 20, 16), Color(0.6, 0.6, 0.65))
	draw_rect(Rect2(-10, -8, 20, 16), Color(0.75, 0.75, 0.8), false, 2.0)
