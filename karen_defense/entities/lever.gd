class_name LeverEntity
extends Node2D

var is_activated: bool = false
var lever_id: String = ""  # Links to what it controls
var interaction_radius: float = 40.0
var anim_time: float = 0.0
var flash_timer: float = 0.0

func initialize(id: String):
	lever_id = id

func interact(game):
	if is_activated:
		return
	is_activated = true
	flash_timer = 0.5
	if game.sfx:
		game.sfx.play_lever()
	game.particles.emit_burst(position.x, position.y, Color8(255, 220, 80), 10)
	# Notify game of lever activation
	if game.has_method("on_lever_activated"):
		game.on_lever_activated(lever_id)

func update_lever(delta: float):
	anim_time += delta
	flash_timer = maxf(0, flash_timer - delta)
	queue_redraw()

func _draw():
	# Base pedestal
	draw_rect(Rect2(-8, 5, 16, 10), Color8(100, 100, 110))
	draw_rect(Rect2(-6, 7, 12, 6), Color8(80, 80, 90))
	
	# Lever arm
	var angle = -0.8 if not is_activated else 0.8
	var arm_end = Vector2(sin(angle) * 18, -cos(angle) * 18)
	var arm_color = Color8(180, 180, 190) if not is_activated else Color8(100, 255, 100)
	draw_line(Vector2(0, 5), arm_end, arm_color, 3.0)
	
	# Knob
	var knob_color = Color8(200, 60, 60) if not is_activated else Color8(60, 200, 60)
	draw_circle(arm_end, 5.0, knob_color)
	
	# Glow when activated
	if is_activated:
		var pulse = sin(anim_time * 3.0) * 0.15 + 0.3
		draw_circle(arm_end, 10.0, Color(0.2, 1.0, 0.2, pulse))
	
	# Flash
	if flash_timer > 0:
		draw_circle(Vector2.ZERO, 25.0, Color(1, 1, 0.8, flash_timer))
	
	# Interaction prompt (if not activated)
	if not is_activated:
		var bob = sin(anim_time * 2.5) * 3.0
		draw_string(ThemeDB.fallback_font, Vector2(-8, -20 + bob), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color8(255, 255, 200, 180))
