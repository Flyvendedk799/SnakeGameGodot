class_name UnitManager
extends Node

var game = null
var max_units: int = 5
var unit_counts: Dictionary = {}  # type -> count of alive units
var outside_allies: Dictionary = {}  # player_index (int) -> AllyEntity ref; one outside ally slot per player

func setup(game_ref):
	game = game_ref

func reset():
	max_units = 5
	unit_counts.clear()
	outside_allies.clear()

func get_alive_count() -> int:
	return game.ally_container.get_child_count()

func get_normal_alive_count() -> int:
	var n = 0
	for ally in game.ally_container.get_children():
		if not ally.get("is_outside_ally"):
			n += 1
	return n

func can_hire(unit_type: String, player_index: int = 0, split: bool = false) -> bool:
	if UnitData.is_placement_outside(unit_type):
		return false  # use can_hire_outside_ally(unit_type, player_index) instead
	var stats = UnitData.get_stats(unit_type)
	if stats.building_req != "" and not game.building_manager.has_building(stats.building_req):
		return false
	if get_normal_alive_count() >= max_units:
		return false
	if split:
		return game.economy.can_afford_split(stats.cost_gold, stats.cost_crystals)
	return game.economy.can_afford(stats.cost_gold, stats.cost_crystals, player_index)

func has_outside_ally(player_index: int) -> bool:
	var existing = outside_allies.get(player_index)
	return existing != null and is_instance_valid(existing)

func can_hire_outside_ally(unit_type: String, player_index: int, split: bool = false) -> bool:
	var stats = UnitData.get_stats(unit_type)
	if stats.get("placement", "") != "outside":
		return false
	if stats.building_req != "" and not game.building_manager.has_building(stats.building_req):
		return false
	if has_outside_ally(player_index):
		return false
	if split:
		return game.economy.can_afford_split(stats.cost_gold, stats.cost_crystals)
	return game.economy.can_afford(stats.cost_gold, stats.cost_crystals, player_index)

func is_unlocked(unit_type: String) -> bool:
	var stats = UnitData.get_stats(unit_type)
	if stats.building_req == "":
		return true
	return game.building_manager.has_building(stats.building_req)

func hire_unit(unit_type: String, player_index: int = 0, split: bool = false) -> bool:
	if not can_hire(unit_type, player_index, split):
		return false
	var stats = UnitData.get_stats(unit_type)
	var spent: bool
	if split:
		spent = game.economy.spend_split(stats.cost_gold, stats.cost_crystals)
	else:
		spent = game.economy.spend(stats.cost_gold, stats.cost_crystals, player_index)
	if not spent:
		return false

	var ally = AllyEntity.new()
	ally.initialize(unit_type, stats)
	ally.owner_player_index = 0
	var rally = game.map.get_player_anchor() if game.map.has_method("get_player_anchor") else game.map.get_fort_center()
	ally.rally_point = rally
	ally.position = rally + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	game.ally_container.add_child(ally)
	if game.sfx:
		game.sfx.play_purchase()
	return true

func hire_outside_ally(unit_type: String, player_index: int, split: bool = false) -> bool:
	if not can_hire_outside_ally(unit_type, player_index, split):
		return false
	var stats = UnitData.get_stats(unit_type)
	var spent: bool
	if split:
		spent = game.economy.spend_split(stats.cost_gold, stats.cost_crystals)
	else:
		spent = game.economy.spend(stats.cost_gold, stats.cost_crystals, player_index)
	if not spent:
		return false
	var ally = AllyEntity.new()
	ally.initialize(unit_type, stats)
	ally.owner_player_index = clampi(player_index, 0, 1)
	ally.is_outside_ally = true
	ally.rally_point = game.map.get_outside_ally_position(ally.owner_player_index)
	ally.position = game.map.get_outside_ally_position(ally.owner_player_index)
	game.ally_container.add_child(ally)
	outside_allies[ally.owner_player_index] = ally
	ally.tree_exiting.connect(_on_outside_ally_exiting.bind(ally))
	if game.sfx:
		game.sfx.play_purchase()
	return true

func _on_outside_ally_exiting(ally_ref: AllyEntity):
	var pi = ally_ref.owner_player_index
	if outside_allies.get(pi) == ally_ref:
		outside_allies.erase(pi)

func regroup_all():
	var center = game.map.get_player_anchor() if game.map.has_method("get_player_anchor") else game.map.get_fort_center()
	for ally in game.ally_container.get_children():
		ally.regroup(center)

func get_nearest_ally(from_pos: Vector2):
	var best = null
	var best_dist = INF
	for ally in game.ally_container.get_children():
		if ally.current_hp <= 0:
			continue
		var d = from_pos.distance_to(ally.position)
		if d < best_dist:
			best_dist = d
			best = ally
	return best
