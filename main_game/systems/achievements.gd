class_name Achievements
extends Node

# Achievement definitions
const ACHIEVEMENT_LIST = [
	{"id": "first_blood", "name": "First Blood", "desc": "Kill your first enemy", "condition": "kills", "threshold": 1},
	{"id": "slayer_10", "name": "Slayer", "desc": "Kill 10 enemies", "condition": "kills", "threshold": 10},
	{"id": "slayer_100", "name": "Mass Slayer", "desc": "Kill 100 enemies", "condition": "kills", "threshold": 100},
	{"id": "slayer_1000", "name": "Genocide", "desc": "Kill 1000 enemies", "condition": "kills", "threshold": 1000},
	{"id": "no_damage_level", "name": "Untouchable", "desc": "Complete a level without taking damage", "condition": "no_damage_clear", "threshold": 1},
	{"id": "parry_master", "name": "Parry Master", "desc": "Parry 10 attacks", "condition": "parries", "threshold": 10},
	{"id": "execute_5", "name": "Executioner", "desc": "Execute 5 enemies", "condition": "executions", "threshold": 5},
	{"id": "world_2", "name": "Explorer", "desc": "Reach World 2", "condition": "world_reached", "threshold": 2},
	{"id": "world_3", "name": "Adventurer", "desc": "Reach World 3", "condition": "world_reached", "threshold": 3},
	{"id": "world_5", "name": "Legend", "desc": "Reach World 5", "condition": "world_reached", "threshold": 5},
	{"id": "boss_kill_1", "name": "Boss Slayer", "desc": "Defeat your first boss", "condition": "bosses_killed", "threshold": 1},
	{"id": "gold_1000", "name": "Rich", "desc": "Earn 1000 gold total", "condition": "total_gold", "threshold": 1000},
	{"id": "gold_10000", "name": "Wealthy", "desc": "Earn 10000 gold total", "condition": "total_gold", "threshold": 10000},
	{"id": "speed_clear", "name": "Speed Demon", "desc": "Clear a level in under 60 seconds", "condition": "speed_clear", "threshold": 60},
	{"id": "all_levels", "name": "Completionist", "desc": "Complete all 25 levels", "condition": "levels_completed", "threshold": 25},
	{"id": "elite_kill", "name": "Elite Hunter", "desc": "Kill 5 elite enemies", "condition": "elite_kills", "threshold": 5},
	{"id": "double_jump", "name": "Air Time", "desc": "Use double jump 50 times", "condition": "double_jumps", "threshold": 50},
	{"id": "wall_jump", "name": "Wall Runner", "desc": "Wall jump 20 times", "condition": "wall_jumps", "threshold": 20},
	{"id": "combo_3", "name": "Combo King", "desc": "Land 50 full 3-hit combos", "condition": "full_combos", "threshold": 50},
	{"id": "nightmare", "name": "Nightmare Victor", "desc": "Complete any level on Nightmare", "condition": "nightmare_clear", "threshold": 1},
]

# Tracking counters
var counters: Dictionary = {}
var unlocked: Array = []  # Array of achievement IDs
var pending_popups: Array = []  # Achievements to show popup for
var game = null

func setup(game_ref):
	game = game_ref
	for a in ACHIEVEMENT_LIST:
		counters[a.condition] = counters.get(a.condition, 0)

func increment(condition: String, amount: int = 1):
	counters[condition] = counters.get(condition, 0) + amount
	_check_unlocks()

func set_counter(condition: String, value: int):
	counters[condition] = value
	_check_unlocks()

func _check_unlocks():
	for a in ACHIEVEMENT_LIST:
		if a.id in unlocked:
			continue
		if counters.get(a.condition, 0) >= a.threshold:
			unlocked.append(a.id)
			pending_popups.append(a)
			if game and game.sfx:
				game.sfx.play_level_up()

func get_popup() -> Dictionary:
	if pending_popups.size() > 0:
		return pending_popups.pop_front()
	return {}

func get_progress(achievement_id: String) -> float:
	for a in ACHIEVEMENT_LIST:
		if a.id == achievement_id:
			var current = counters.get(a.condition, 0)
			return clampf(float(current) / float(a.threshold), 0.0, 1.0)
	return 0.0

func save_data() -> Dictionary:
	return {"counters": counters, "unlocked": unlocked}

func load_data(data: Dictionary):
	counters = data.get("counters", {})
	unlocked = data.get("unlocked", [])
