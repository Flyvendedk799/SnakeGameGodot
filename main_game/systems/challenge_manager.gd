class_name ChallengeManager
extends Node

const MODIFIERS = {
	"double_gold": {"name": "Golden Age", "desc": "2x gold drops", "gold_mult": 2.0, "enemy_hp_mult": 1.0, "enemy_dmg_mult": 1.0, "player_dmg_mult": 1.0},
	"glass_cannon": {"name": "Glass Cannon", "desc": "2x damage dealt, 2x damage taken", "gold_mult": 1.5, "enemy_hp_mult": 1.0, "enemy_dmg_mult": 2.0, "player_dmg_mult": 2.0},
	"speed_enemies": {"name": "Rush Hour", "desc": "Enemies move 50% faster", "gold_mult": 1.3, "enemy_hp_mult": 1.0, "enemy_dmg_mult": 1.0, "player_dmg_mult": 1.0, "enemy_speed_mult": 1.5},
	"no_block": {"name": "No Defense", "desc": "Cannot block", "gold_mult": 1.5, "enemy_hp_mult": 1.0, "enemy_dmg_mult": 1.0, "player_dmg_mult": 1.0, "disable_block": true},
	"tank_enemies": {"name": "Tank Mode", "desc": "Enemies have 3x HP", "gold_mult": 2.0, "enemy_hp_mult": 3.0, "enemy_dmg_mult": 1.0, "player_dmg_mult": 1.0},
	"berserker": {"name": "Berserker", "desc": "No healing, but 1.5x damage", "gold_mult": 1.3, "enemy_hp_mult": 1.0, "enemy_dmg_mult": 1.0, "player_dmg_mult": 1.5, "disable_heal": true},
	"one_shot": {"name": "One Shot", "desc": "Everything dies in one hit (including you!)", "gold_mult": 1.0, "enemy_hp_mult": 0.01, "enemy_dmg_mult": 100.0, "player_dmg_mult": 100.0},
	"swarm": {"name": "Swarm", "desc": "2x enemy count, 0.5x enemy HP", "gold_mult": 1.5, "enemy_hp_mult": 0.5, "enemy_dmg_mult": 1.0, "player_dmg_mult": 1.0, "spawn_mult": 2.0},
}

var active_modifiers: Array = []  # Array of modifier keys
var game = null
var daily_seed: int = 0

func setup(game_ref):
	game = game_ref
	daily_seed = _get_daily_seed()

static func _get_daily_seed() -> int:
	var date = Time.get_date_dict_from_system()
	return date.year * 10000 + date.month * 100 + date.day

func get_daily_modifiers() -> Array:
	"""Get today's daily challenge modifiers (2 random modifiers from seed)."""
	return get_daily_modifiers_from_seed(daily_seed)

static func get_daily_modifiers_from_seed(seed: int) -> Array:
	"""Get deterministic daily challenge modifiers from a seed."""
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var keys = MODIFIERS.keys()
	var picked = []
	if keys.size() == 0:
		return picked
	if keys.size() == 1:
		picked.append(keys[0])
		return picked
	var idx1 = rng.randi_range(0, keys.size() - 1)
	picked.append(keys[idx1])
	var idx2 = idx1
	while idx2 == idx1:
		idx2 = rng.randi_range(0, keys.size() - 1)
	picked.append(keys[idx2])
	return picked

static func get_today_daily_modifiers() -> Array:
	return get_daily_modifiers_from_seed(_get_daily_seed())

func activate_modifier(mod_key: String):
	if mod_key in MODIFIERS and mod_key not in active_modifiers:
		active_modifiers.append(mod_key)

func deactivate_all():
	active_modifiers.clear()

func get_gold_mult() -> float:
	var mult = 1.0
	for key in active_modifiers:
		mult *= MODIFIERS[key].get("gold_mult", 1.0)
	return mult

func get_enemy_hp_mult() -> float:
	var mult = 1.0
	for key in active_modifiers:
		mult *= MODIFIERS[key].get("enemy_hp_mult", 1.0)
	return mult

func get_enemy_dmg_mult() -> float:
	var mult = 1.0
	for key in active_modifiers:
		mult *= MODIFIERS[key].get("enemy_dmg_mult", 1.0)
	return mult

func get_player_dmg_mult() -> float:
	var mult = 1.0
	for key in active_modifiers:
		mult *= MODIFIERS[key].get("player_dmg_mult", 1.0)
	return mult

func get_spawn_mult() -> float:
	var mult = 1.0
	for key in active_modifiers:
		mult *= MODIFIERS[key].get("spawn_mult", 1.0)
	return mult

func get_enemy_speed_mult() -> float:
	var mult = 1.0
	for key in active_modifiers:
		mult *= MODIFIERS[key].get("enemy_speed_mult", 1.0)
	return mult

func is_block_disabled() -> bool:
	for key in active_modifiers:
		if MODIFIERS[key].get("disable_block", false):
			return true
	return false

func is_heal_disabled() -> bool:
	for key in active_modifiers:
		if MODIFIERS[key].get("disable_heal", false):
			return true
	return false

func get_active_descriptions() -> Array:
	var descs = []
	for key in active_modifiers:
		descs.append(MODIFIERS[key])
	return descs

func get_total_reward_mult() -> float:
	return get_gold_mult()
