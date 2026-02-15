class_name BreakableProp
extends Node2D

## Breakable prop entity: crate, barrel, breakable wall.
## Hit by melee or projectile to break. Drops gold, health, or nothing.

enum PropType { CRATE, BARREL, BREAKABLE_WALL }
enum PropState { INTACT, BREAKING, DESTROYED }

var prop_type: PropType = PropType.CRATE
var prop_state: PropState = PropState.INTACT
var current_hp: int = 30
var max_hp: int = 30
var drops: String = "gold"  # "gold", "health", "nothing"
var entity_size: float = 18.0
var hit_flash_timer: float = 0.0
var break_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# Visual
var anim_time: float = 0.0

func initialize(config: Dictionary):
	var type_str = config.get("type", "crate")
	match type_str:
		"crate":
			prop_type = PropType.CRATE
			max_hp = 25
			entity_size = 18.0
		"barrel":
			prop_type = PropType.BARREL
			max_hp = 35
			entity_size = 16.0
		"breakable_wall":
			prop_type = PropType.BREAKABLE_WALL
			max_hp = 80
			entity_size = 40.0
	current_hp = max_hp
	drops = config.get("drops", "gold")
	position = Vector2(float(config.get("x", 0)), float(config.get("y", 350)))

func take_damage(amount: int, game = null) -> bool:
	"""Returns true if prop was just destroyed."""
	if prop_state != PropState.INTACT:
		return false
	current_hp -= amount
	hit_flash_timer = 0.12
	shake_offset = Vector2(randf_range(-3, 3), randf_range(-2, 2))
	if current_hp <= 0:
		prop_state = PropState.BREAKING
		break_timer = 0.3
		_on_break(game)
		return true
	return false

func _on_break(game):
	if game == null:
		return
	# Spawn drops
	match drops:
		"gold":
			var gold = GoldDrop.new()
			gold.amount = randi_range(5, 15)
			gold.position = position + Vector2(0, -10)
			if game.gold_container:
				game.gold_container.add_child(gold)
		"health":
			# Spawn health orb as a collectible-style node
			var orb = CollectibleItem.new()
			orb.initialize({"x": position.x, "y": position.y - 10, "type": "health_orb"})
			if game.has_node("GameLayer/Entities"):
				game.get_node("GameLayer/Entities").add_child(orb)
	# Particles
	if game.particles:
		var c = Color8(160, 120, 70) if prop_type == PropType.CRATE else Color8(120, 80, 50)
		for i in range(6):
			var dir = Vector2(randf_range(-1, 1), randf_range(-1.5, -0.2)).normalized()
			game.particles.emit_directional(position.x, position.y, dir, c, 2)
	if game.sfx and game.sfx.has_method("play_break"):
		game.sfx.play_break()

func update_prop(delta: float):
	anim_time += delta
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		shake_offset = shake_offset.lerp(Vector2.ZERO, delta * 20.0)
	if prop_state == PropState.BREAKING:
		break_timer -= delta
		if break_timer <= 0:
			prop_state = PropState.DESTROYED
			queue_free()
	queue_redraw()

func _draw():
	if prop_state == PropState.DESTROYED:
		return
	var flash = hit_flash_timer > 0
	var breaking = prop_state == PropState.BREAKING
	var alpha = 1.0
	if breaking:
		alpha = maxf(0.0, break_timer / 0.3)

	var offset = shake_offset if hit_flash_timer > 0 else Vector2.ZERO

	match prop_type:
		PropType.CRATE:
			_draw_crate(offset, flash, alpha)
		PropType.BARREL:
			_draw_barrel(offset, flash, alpha)
		PropType.BREAKABLE_WALL:
			_draw_wall(offset, flash, alpha)

func _draw_crate(offset: Vector2, flash: bool, alpha: float):
	var size = 32.0
	var half = size / 2.0
	# Shadow
	_draw_ellipse_shape(Vector2(offset.x + 2, 14), Vector2(half, 6), Color(0, 0, 0, 0.2 * alpha))
	# Body
	var body_c = Color8(180, 140, 80, int(255 * alpha))
	if flash:
		body_c = Color8(255, 220, 180, int(255 * alpha))
	draw_rect(Rect2(offset.x - half, offset.y - size + 4, size, size), body_c)
	# Cross beams
	var dark_c = Color8(140, 100, 55, int(255 * alpha))
	draw_line(Vector2(offset.x - half, offset.y - size + 4), Vector2(offset.x + half, offset.y + 4), dark_c, 2.0)
	draw_line(Vector2(offset.x + half, offset.y - size + 4), Vector2(offset.x - half, offset.y + 4), dark_c, 2.0)
	# Edge
	draw_rect(Rect2(offset.x - half, offset.y - size + 4, size, size), dark_c, false, 2.0)
	# HP indicator
	if current_hp < max_hp and prop_state == PropState.INTACT:
		var ratio = float(current_hp) / float(max_hp)
		draw_rect(Rect2(offset.x - half, offset.y - size - 2, size * ratio, 3), Color8(80, 200, 80, int(200 * alpha)))

func _draw_barrel(offset: Vector2, flash: bool, alpha: float):
	var w = 26.0
	var h = 36.0
	# Shadow
	_draw_ellipse_shape(Vector2(offset.x + 2, 14), Vector2(w / 2.0, 5), Color(0, 0, 0, 0.2 * alpha))
	# Body
	var body_c = Color8(140, 90, 50, int(255 * alpha))
	if flash:
		body_c = Color8(220, 170, 120, int(255 * alpha))
	draw_rect(Rect2(offset.x - w / 2.0, offset.y - h + 4, w, h), body_c)
	# Metal bands
	var band_c = Color8(100, 100, 110, int(255 * alpha))
	draw_rect(Rect2(offset.x - w / 2.0 - 1, offset.y - h + 8, w + 2, 4), band_c)
	draw_rect(Rect2(offset.x - w / 2.0 - 1, offset.y - 6, w + 2, 4), band_c)
	# HP indicator
	if current_hp < max_hp and prop_state == PropState.INTACT:
		var ratio = float(current_hp) / float(max_hp)
		draw_rect(Rect2(offset.x - w / 2.0, offset.y - h - 2, w * ratio, 3), Color8(80, 200, 80, int(200 * alpha)))

func _draw_wall(offset: Vector2, flash: bool, alpha: float):
	var w = 70.0
	var h = 90.0
	var body_c = Color8(90, 80, 75, int(255 * alpha))
	if flash:
		body_c = Color8(150, 140, 130, int(255 * alpha))
	draw_rect(Rect2(offset.x - w / 2.0, offset.y - h, w, h), body_c)
	# Cracks
	var crack_c = Color8(60, 55, 50, int(200 * alpha))
	draw_line(Vector2(offset.x - 10, offset.y - h + 20), Vector2(offset.x + 15, offset.y - h + 50), crack_c, 2.0)
	draw_line(Vector2(offset.x + 5, offset.y - h + 10), Vector2(offset.x - 20, offset.y - 30), crack_c, 1.5)
	# HP indicator
	if current_hp < max_hp and prop_state == PropState.INTACT:
		var ratio = float(current_hp) / float(max_hp)
		draw_rect(Rect2(offset.x - w / 2.0, offset.y - h - 4, w * ratio, 3), Color8(80, 200, 80, int(200 * alpha)))

func _draw_ellipse_shape(center: Vector2, radii: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
