class_name Economy
extends Node

# Per-player gold
var p1_gold: int = 50
var p2_gold: int = 50
# Shared crystals
var crystals: int = 0
var gold_mine_multiplier: float = 1.0
var crystal_per_wave: int = 0
var max_waves: int = 50
var world_tier: int = 3

# Legacy accessor — total gold (for display/tracking)
var gold: int:
	get: return p1_gold + p2_gold

func reset():
	p1_gold = 50
	p2_gold = 50
	crystals = 0
	gold_mine_multiplier = 1.0
	crystal_per_wave = 0

func configure_for_map(map_config: Dictionary):
	max_waves = map_config.get("max_waves", 50)
	world_tier = map_config.get("world_tier", 3)

func get_player_gold(player_index: int) -> int:
	return p2_gold if player_index == 1 else p1_gold

func add_gold(amount: int, player_index: int = 0):
	if player_index == 1:
		p2_gold += amount
	else:
		p1_gold += amount

func add_crystals(amount: int):
	crystals += amount

func _effective_cost_gold(cost_gold: int) -> int:
	return int(cost_gold * get_cost_multiplier())

func _effective_cost_crystals(cost_crystals: int) -> int:
	return int(cost_crystals * get_cost_multiplier())

func can_afford(cost_gold: int, cost_crystals: int = 0, player_index: int = 0) -> bool:
	var pg = get_player_gold(player_index)
	return pg >= _effective_cost_gold(cost_gold) and crystals >= _effective_cost_crystals(cost_crystals)

func spend(cost_gold: int, cost_crystals: int = 0, player_index: int = 0) -> bool:
	var eg = _effective_cost_gold(cost_gold)
	var ec = _effective_cost_crystals(cost_crystals)
	var pg = get_player_gold(player_index)
	if pg < eg or crystals < ec:
		return false
	if player_index == 1:
		p2_gold -= eg
	else:
		p1_gold -= eg
	crystals -= ec
	return true

# --- 50/50 split for shared purchases (Buildings, Units) when P2 is in ---
func can_afford_split(cost_gold: int, cost_crystals: int = 0) -> bool:
	var eg = _effective_cost_gold(cost_gold)
	var ec = _effective_cost_crystals(cost_crystals)
	var p1_share = eg - eg / 2  # P1 pays remainder for odd amounts
	var p2_share = eg / 2
	return p1_gold >= p1_share and p2_gold >= p2_share and crystals >= ec

func spend_split(cost_gold: int, cost_crystals: int = 0) -> bool:
	var eg = _effective_cost_gold(cost_gold)
	var ec = _effective_cost_crystals(cost_crystals)
	var p1_share = eg - eg / 2
	var p2_share = eg / 2
	if p1_gold < p1_share or p2_gold < p2_share or crystals < ec:
		return false
	p1_gold -= p1_share
	p2_gold -= p2_share
	crystals -= ec
	return true

func apply_end_of_wave_bonus(wave_number: int):
	# Scale bonus by max_waves so progression feels good across 15/30/50-wave maps
	var base_val = 10.0
	var linear = 2.0 + max_waves * 0.08
	var quad = 0.08
	var bonus = int((base_val + wave_number * linear + wave_number * wave_number * quad) * gold_mine_multiplier)
	# Split evenly between P1 and P2
	var half = bonus / 2
	p1_gold += bonus - half  # P1 gets remainder
	p2_gold += half
	if crystal_per_wave > 0:
		crystals += crystal_per_wave

func get_cost_multiplier() -> float:
	# Map1 cheaper (0.85), Map3 full price (1.15)
	return 0.7 + 0.15 * world_tier

func get_display_cost_gold(cost_gold: int) -> int:
	return _effective_cost_gold(cost_gold)

func get_display_cost_crystals(cost_crystals: int) -> int:
	return _effective_cost_crystals(cost_crystals)
