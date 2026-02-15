class_name CollectibleItem
extends Node2D

## Collectible items: coins, gems, health orbs, keys, lore pages.
## Player walks over to collect. Each type has different value/effect.

enum CollectibleType { COIN, GEM, HEALTH_ORB, KEY, LORE_PAGE }

var collect_type: CollectibleType = CollectibleType.COIN
var value: int = 1
var collected: bool = false
var age: float = 0.0
var bob_offset: float = 0.0
var collect_timer: float = 0.0
var pickup_radius: float = 24.0

func initialize(config: Dictionary):
	var type_str = config.get("type", "coin")
	match type_str:
		"coin":
			collect_type = CollectibleType.COIN
			value = 3
			pickup_radius = 22.0
		"gem":
			collect_type = CollectibleType.GEM
			value = 10
			pickup_radius = 24.0
		"health_orb":
			collect_type = CollectibleType.HEALTH_ORB
			value = 20
			pickup_radius = 20.0
		"key":
			collect_type = CollectibleType.KEY
			value = 1
			pickup_radius = 22.0
		"lore":
			collect_type = CollectibleType.LORE_PAGE
			value = 1
			pickup_radius = 20.0
	position = Vector2(float(config.get("x", 0)), float(config.get("y", 300)))

func update_collectible(delta: float, game = null):
	age += delta
	bob_offset = sin(age * 3.0) * 3.0
	if collected:
		collect_timer -= delta
		if collect_timer <= 0:
			queue_free()
			return
	elif game != null:
		_check_pickup(game)
	queue_redraw()

func _check_pickup(game):
	if collected:
		return
	for p in [game.player_node, game.player2_node]:
		if p == null or p.is_dead:
			continue
		if position.distance_to(p.position) < pickup_radius + p.BODY_RADIUS:
			_on_collect(game, p)
			return

func _on_collect(game, player):
	collected = true
	collect_timer = 0.25
	match collect_type:
		CollectibleType.COIN:
			if game.economy:
				var player_idx = 0 if player == game.player_node else 1
				if player_idx == 0:
					game.economy.p1_gold += value
				else:
					game.economy.p2_gold += value
		CollectibleType.GEM:
			if game.economy:
				var player_idx = 0 if player == game.player_node else 1
				if player_idx == 0:
					game.economy.p1_gold += value
				else:
					game.economy.p2_gold += value
		CollectibleType.HEALTH_ORB:
			player.heal(value)
		CollectibleType.KEY:
			# Store key in game state
			if not game.has_meta("keys_collected"):
				game.set_meta("keys_collected", 0)
			game.set_meta("keys_collected", game.get_meta("keys_collected") + 1)
		CollectibleType.LORE_PAGE:
			pass  # Track in save later

	# VFX
	if game.particles:
		var c: Color
		match collect_type:
			CollectibleType.COIN: c = Color8(255, 220, 50)
			CollectibleType.GEM: c = Color8(100, 200, 255)
			CollectibleType.HEALTH_ORB: c = Color8(80, 255, 100)
			CollectibleType.KEY: c = Color8(255, 200, 80)
			_: c = Color8(200, 180, 160)
		for i in range(4):
			var dir = Vector2(randf_range(-1, 1), -1.0).normalized()
			game.particles.emit_directional(position.x, position.y, dir, c, 1)

	# SFX
	if game.sfx and game.sfx.has_method("play_coin"):
		game.sfx.play_coin()

func _draw():
	if collected:
		# Fade out + float up
		var alpha = maxf(0, collect_timer / 0.25)
		var rise = (0.25 - collect_timer) * 60.0
		draw_set_transform(Vector2(0, -rise), 0, Vector2(1, 1))
		_draw_icon(alpha)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return

	_draw_icon(1.0)

func _draw_icon(alpha: float):
	var y = bob_offset

	match collect_type:
		CollectibleType.COIN:
			# Gold circle
			draw_circle(Vector2(0, y), 8.0, Color(1.0, 0.85, 0.15, alpha))
			draw_circle(Vector2(0, y), 5.5, Color(0.9, 0.75, 0.1, alpha))
			# Shine
			var shine = 0.3 + 0.2 * sin(age * 4.0)
			draw_circle(Vector2(-2, y - 2), 2.0, Color(1, 1, 0.8, shine * alpha))

		CollectibleType.GEM:
			# Diamond shape
			var points = PackedVector2Array([
				Vector2(0, y - 12), Vector2(10, y), Vector2(0, y + 6), Vector2(-10, y)
			])
			draw_colored_polygon(points, Color(0.3, 0.7, 1.0, alpha))
			# Inner glow
			var inner = PackedVector2Array([
				Vector2(0, y - 7), Vector2(5, y), Vector2(0, y + 3), Vector2(-5, y)
			])
			draw_colored_polygon(inner, Color(0.5, 0.85, 1.0, alpha * 0.7))
			# Sparkle
			var sparkle = 0.4 + 0.3 * sin(age * 5.0)
			draw_circle(Vector2(2, y - 4), 1.5, Color(1, 1, 1, sparkle * alpha))

		CollectibleType.HEALTH_ORB:
			# Green orb
			draw_circle(Vector2(0, y), 8.0, Color(0.2, 0.8, 0.3, alpha))
			draw_circle(Vector2(0, y), 5.0, Color(0.3, 0.95, 0.4, alpha * 0.8))
			# Cross
			draw_rect(Rect2(-1.5, y - 5, 3, 10), Color(1, 1, 1, alpha * 0.6))
			draw_rect(Rect2(-5, y - 1.5, 10, 3), Color(1, 1, 1, alpha * 0.6))

		CollectibleType.KEY:
			# Key shape
			draw_circle(Vector2(0, y - 4), 6.0, Color(0.9, 0.7, 0.2, alpha))
			draw_circle(Vector2(0, y - 4), 3.5, Color(0.5, 0.35, 0.1, alpha))
			draw_rect(Rect2(-2, y, 4, 10), Color(0.9, 0.7, 0.2, alpha))
			draw_rect(Rect2(-4, y + 6, 3, 3), Color(0.9, 0.7, 0.2, alpha))

		CollectibleType.LORE_PAGE:
			# Scroll/page
			draw_rect(Rect2(-7, y - 10, 14, 18), Color(0.85, 0.8, 0.65, alpha))
			draw_rect(Rect2(-7, y - 10, 14, 18), Color(0.6, 0.55, 0.4, alpha), false, 1.0)
			# Text lines
			for i in range(3):
				draw_rect(Rect2(-4, y - 7 + i * 5, 8, 2), Color(0.4, 0.35, 0.25, alpha * 0.5))
