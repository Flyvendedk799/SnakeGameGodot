class_name SupplyDropEntity
extends Node2D

var game = null
var drop_pos: Vector2
var phase: String = "fly"
var timer: float = 0.0
var fly_duration: float = 1.2
var drop_duration: float = 0.5
var start_pos: Vector2
var crate_ground_pos: Vector2
const REPAIR_RADIUS: float = 120.0
const REPAIR_FRACTION: float = 0.15
const GOLD_AMOUNT: int = 25

func setup(game_ref, world_pos: Vector2):
	game = game_ref
	drop_pos = world_pos
	var map = game.map
	start_pos = Vector2(map.FORT_LEFT - 80, map.get_fort_center().y)
	position = start_pos

func update_supply(delta: float) -> bool:
	timer += delta
	if phase == "fly":
		var t = clampf(timer / fly_duration, 0, 1)
		position = start_pos.lerp(Vector2(drop_pos.x, start_pos.y), t)
		if t >= 1:
			phase = "drop"
			timer = 0
			crate_ground_pos = drop_pos
			position = Vector2(drop_pos.x, start_pos.y)
	elif phase == "drop":
		if timer >= drop_duration:
			_deliver()
			return true
	queue_redraw()
	return false

func _deliver():
	for b in game.map.barricades:
		if not is_instance_valid(b): continue
		var dist = crate_ground_pos.distance_to(b.global_position)
		if dist <= REPAIR_RADIUS:
			b.partial_repair(REPAIR_FRACTION)
	var gold = GoldDrop.new()
	gold.amount = GOLD_AMOUNT
	gold.player_index_hint = 0
	gold.position = crate_ground_pos
	game.gold_container.add_child(gold)
	game.particles.emit_burst(crate_ground_pos.x, crate_ground_pos.y, Color8(100, 200, 100), 12, 0.4)
	game.start_shake(2.0, 0.15)
	if game.sfx:
		game.sfx.play_repair()
	queue_free()

func _draw():
	if phase == "fly":
		draw_circle(Vector2.ZERO, 14, Color8(60, 100, 60))
		draw_rect(Rect2(-8, -8, 16, 10), Color8(80, 140, 80))
	elif phase == "drop":
		var fall_y = -40 * (1 - timer / drop_duration)
		draw_rect(Rect2(-10, fall_y - 6, 20, 12), Color8(90, 120, 90))
		draw_circle(Vector2(0, fall_y + 2), 4, Color8(200, 180, 80))
