class_name LevelDestructible
extends Node2D

## Phase 5.2: Destructible wall/passage
## Dash or ground pound breaks the wall (dash: horizontal > 450 speed; ground pound: any)
## On destruction: WallSegment disappears, emits particle burst, opens passage

var hp: int = 30
var max_hp: int = 30
var width: float = 32.0
var height: float = 64.0
var color: Color = Color8(120, 100, 80)
var is_destroyed: bool = false

# Reveal what's behind: "secret_passage" | "treasure_room" | "alt_path"
var passage_type: String = "secret_passage"
# Gold bonus on destruction
var loot_gold: int = 20
# Key drop chance (for locked doors)
var key_drop_chance: float = 0.3

signal destroyed(wall_node)

func take_damage(amount: int, game, hit_type: String = "medium"):
	"""Receive hit. Dash = force, ground_pound = instant."""
	if is_destroyed:
		return
	if hit_type == "ground_pound":
		hp = 0  # Instant destruction
	else:
		hp -= amount

	# Visual feedback
	if game.particles:
		game.particles.emit_burst(position.x, position.y, color.lightened(0.3), 6)

	if hp <= 0:
		_destroy(game)

func _destroy(game):
	"""Destroy the wall, grant loot, emit FX."""
	if is_destroyed:
		return
	is_destroyed = true

	# Big particle burst
	if game.particles:
		game.particles.emit_death_burst(position.x, position.y, color)

	# FX shake
	if game.has_method("start_shake"):
		game.start_shake(5.0, 0.12)

	# Gold loot
	if loot_gold > 0 and game.get("economy"):
		game.economy.add_gold(loot_gold, 0)
		game.spawn_damage_number(position, "+%d" % loot_gold, Color.GOLD)

	# Key drop
	if randf() < key_drop_chance:
		_drop_key(game)

	emit_signal("destroyed", self)
	queue_free()

func _drop_key(game):
	"""Spawn a key collectible for locked doors."""
	if not game.get("gold_container"):
		return
	var key_item = CollectibleItem.new() if ClassDB.class_exists("CollectibleItem") else null
	if key_item == null:
		# Fallback: just add to player key count directly
		if game.player_node:
			game.player_node.key_count += 1
			game.spawn_damage_number(position, "KEY!", Color(1.0, 0.9, 0.3))
		return
	key_item.item_type = "key"
	key_item.position = position
	game.gold_container.add_child(key_item)

func _draw():
	if is_destroyed:
		return
	# Draw wall with damage indicator (darkens as HP drops)
	var hp_frac = float(hp) / float(max_hp)
	var draw_color = color.darkened(0.4 * (1.0 - hp_frac))
	draw_rect(Rect2(-width / 2.0, -height / 2.0, width, height), draw_color)
	# Crack lines at low HP
	if hp_frac < 0.5:
		var crack_col = Color(0.1, 0.08, 0.05, 0.8)
		draw_line(Vector2(-width * 0.3, -height * 0.2), Vector2(width * 0.1, height * 0.3), crack_col, 2.0)
		draw_line(Vector2(-width * 0.1, -height * 0.4), Vector2(width * 0.2, -height * 0.1), crack_col, 1.5)

func get_collision_rect() -> Rect2:
	return Rect2(position.x - width / 2.0, position.y - height / 2.0, width, height)
