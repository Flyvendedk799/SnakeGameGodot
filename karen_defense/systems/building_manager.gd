class_name BuildingManager
extends Node

var game = null
var owned_buildings: Array[String] = []

func setup(game_ref):
	game = game_ref

func reset():
	owned_buildings.clear()

func has_building(building_id: String) -> bool:
	return building_id in owned_buildings

func can_buy(building: Dictionary, player_index: int = 0, split: bool = false) -> bool:
	# Repeatable buildings (like door reinforcement) can always be re-bought
	if building.id != "reinforce_doors" and has_building(building.id):
		return false
	if building.prereq != "" and not has_building(building.prereq):
		return false
	if split:
		return game.economy.can_afford_split(building.cost_gold, building.cost_crystals)
	return game.economy.can_afford(building.cost_gold, building.cost_crystals, player_index)

func is_locked(building: Dictionary) -> bool:
	if building.prereq == "":
		return false
	return not has_building(building.prereq)

func buy_building(building: Dictionary, player_index: int = 0, split: bool = false) -> bool:
	if not can_buy(building, player_index, split):
		return false
	var spent: bool
	if split:
		spent = game.economy.spend_split(building.cost_gold, building.cost_crystals)
	else:
		spent = game.economy.spend(building.cost_gold, building.cost_crystals, player_index)
	if not spent:
		return false
	# Repeatable buildings don't go into owned_buildings (stay purchasable)
	if building.id != "reinforce_doors":
		owned_buildings.append(building.id)
	_apply_effect(building.effect)
	if game.sfx:
		game.sfx.play_purchase()
	return true

func _apply_effect(effect: String):
	match effect:
		"gold_mine":
			game.economy.gold_mine_multiplier = 1.5
		"crystal_mine":
			game.economy.crystal_per_wave = 10
		"spiked_barricades":
			for b in game.map.barricades:
				b.is_spiked = true
				b.spike_damage = 5
		"reinforce_doors":
			for d in game.map.doors:
				d.apply_reinforcement()
		"unlock_equipment", "unlock_potions":
			pass  # Coming soon
		_:
			pass  # Unit unlock effects are checked via has_building()
