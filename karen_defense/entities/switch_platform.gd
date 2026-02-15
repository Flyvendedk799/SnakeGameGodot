class_name SwitchPlatformEntity
extends Node2D

var is_visible_platform: bool = true  # Current state
var linked_switch_id: String = ""
var platform_rect: Rect2 = Rect2(0, 0, 80, 12)
var anim_time: float = 0.0
var transition_timer: float = 0.0
const TRANSITION_DURATION: float = 0.3

func initialize(switch_id: String, rect: Rect2, starts_visible: bool = true):
	linked_switch_id = switch_id
	platform_rect = rect
	is_visible_platform = starts_visible
	position = rect.position

func toggle():
	is_visible_platform = not is_visible_platform
	transition_timer = TRANSITION_DURATION

func is_solid() -> bool:
	return is_visible_platform

func update_platform(delta: float):
	anim_time += delta
	if transition_timer > 0:
		transition_timer -= delta
	queue_redraw()

func _draw():
	var w = platform_rect.size.x
	var h = platform_rect.size.y
	var alpha = 1.0
	if transition_timer > 0:
		var t = transition_timer / TRANSITION_DURATION
		alpha = t if not is_visible_platform else 1.0 - t + (1.0 - t)
		alpha = clampf(alpha, 0.1, 1.0)
	
	if is_visible_platform:
		# Solid platform
		draw_rect(Rect2(0, 0, w, h), Color(0.4, 0.6, 0.9, alpha))
		draw_rect(Rect2(0, 0, w, 2), Color(0.6, 0.8, 1.0, alpha))  # Top highlight
		# Energy lines
		var pulse = sin(anim_time * 3.0) * 0.2 + 0.5
		draw_rect(Rect2(2, h/2 - 1, w - 4, 2), Color(0.5, 0.8, 1.0, pulse * alpha))
	else:
		# Ghost/inactive platform (visible but not solid)
		draw_rect(Rect2(0, 0, w, h), Color(0.3, 0.4, 0.6, 0.15))
		# Dashed outline
		var dash_count = int(w / 10)
		for i in range(dash_count):
			if i % 2 == 0:
				draw_rect(Rect2(i * 10, 0, 5, 1), Color(0.5, 0.6, 0.8, 0.3))
