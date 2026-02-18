class_name OcclusionManager
extends Node

## Phase 3: Depth Occlusion Manager
## Tests entities against platform rects each frame; when occluded,
## modulates CharacterVisual to a dark silhouette tint (0.4, 0.4, 0.5).

var game = null

# Silhouette modulate when occluded (dark blue-grey tint)
const OCCLUDED_MODULATE: Color = Color(0.4, 0.4, 0.5, 1.0)
const NORMAL_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

# How many pixels below the platform bottom counts as occluded
const OCCLUSION_BAND: float = 64.0

func setup(game_ref):
	game = game_ref

func update(_delta: float):
	if game == null or game.map == null:
		return
	var platforms = game.map.platform_rects

	# Check player
	if game.player_node and not game.player_node.is_dead:
		_check_entity(game.player_node, platforms)

	# Check player 2
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		_check_entity(game.player2_node, platforms)

	# Check enemies
	for enemy in game.enemy_container.get_children():
		_check_entity(enemy, platforms)

	# Check allies
	for ally in game.ally_container.get_children():
		_check_entity(ally, platforms)

func _check_entity(entity: Node2D, platforms: Array):
	"""Apply or remove occlusion modulate based on platform overlap."""
	var pos = entity.position
	var occluded = _is_occluded(pos, platforms)

	# Try CharacterVisual first; fall back to entity modulate
	var cv = entity.get("character_visual")
	if cv and cv is CharacterVisual:
		cv.set_modulate_color(OCCLUDED_MODULATE if occluded else NORMAL_MODULATE)
	else:
		entity.modulate = OCCLUDED_MODULATE if occluded else NORMAL_MODULATE

func _is_occluded(pos: Vector2, platforms: Array) -> bool:
	"""Return true when entity center is within the occlusion band under a platform."""
	for plat in platforms:
		# Platform X bounds check (with small margin)
		if pos.x < plat.position.x - 4.0 or pos.x > plat.position.x + plat.size.x + 4.0:
			continue
		# Entity must be below platform top (i.e. underneath the platform)
		var plat_bottom = plat.position.y + plat.size.y
		if pos.y > plat.position.y and pos.y < plat_bottom + OCCLUSION_BAND:
			return true
	return false

func get_occlusion(entity: Node2D) -> bool:
	"""Public query: returns whether entity is currently occluded."""
	if game == null or game.map == null:
		return false
	return _is_occluded(entity.position, game.map.platform_rects)
