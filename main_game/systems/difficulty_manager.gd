class_name DifficultyManager
extends RefCounted

## Manages difficulty modes and per-level challenge tracking.

enum DifficultyMode { NORMAL, HARD, NIGHTMARE }

static var current_difficulty: DifficultyMode = DifficultyMode.NORMAL

static func get_difficulty_name() -> String:
	match current_difficulty:
		DifficultyMode.NORMAL: return "Normal"
		DifficultyMode.HARD: return "Hard"
		DifficultyMode.NIGHTMARE: return "Nightmare"
	return "Normal"

static func get_enemy_hp_mult() -> float:
	match current_difficulty:
		DifficultyMode.NORMAL: return 1.0
		DifficultyMode.HARD: return 1.2
		DifficultyMode.NIGHTMARE: return 1.5
	return 1.0

static func get_enemy_damage_mult() -> float:
	match current_difficulty:
		DifficultyMode.NORMAL: return 1.0
		DifficultyMode.HARD: return 1.2
		DifficultyMode.NIGHTMARE: return 1.5
	return 1.0

static func get_gold_mult() -> float:
	match current_difficulty:
		DifficultyMode.NORMAL: return 1.0
		DifficultyMode.HARD: return 0.8
		DifficultyMode.NIGHTMARE: return 0.6
	return 1.0

static func get_souls_bonus() -> float:
	"""Bonus souls multiplier for harder difficulties."""
	match current_difficulty:
		DifficultyMode.NORMAL: return 1.0
		DifficultyMode.HARD: return 1.5
		DifficultyMode.NIGHTMARE: return 2.0
	return 1.0

static func get_spawn_rate_mult() -> float:
	match current_difficulty:
		DifficultyMode.NORMAL: return 1.0
		DifficultyMode.HARD: return 1.0
		DifficultyMode.NIGHTMARE: return 1.3
	return 1.0

static func heal_at_checkpoints() -> bool:
	"""Nightmare mode: no mid-level checkpoint heal."""
	return current_difficulty != DifficultyMode.NIGHTMARE

# --- Per-Level Challenges ---

const CHALLENGES = {
	"no_damage": {"name": "No Damage", "desc": "Complete without taking damage"},
	"speed_run": {"name": "Speed Run", "desc": "Finish under 3:00"},
	"kill_all": {"name": "Exterminator", "desc": "Kill all enemies"},
	"no_death": {"name": "Deathless", "desc": "Complete without dying"},
}

static func get_challenges_for_level(_level_id: int) -> Array:
	"""Returns available challenges for a given level."""
	return ["no_damage", "speed_run", "kill_all"]

static func check_challenge(challenge_id: String, game) -> bool:
	"""Check if a challenge was completed at end of level."""
	match challenge_id:
		"no_damage":
			return game.player_node.current_hp >= game.player_node.max_hp
		"speed_run":
			return game.time_elapsed < 180.0  # 3 minutes
		"kill_all":
			return game.enemy_container.get_child_count() == 0
		"no_death":
			return true  # Would need death counter tracking
	return false

# --- Achievements ---

const ACHIEVEMENTS = [
	{"id": "world1_complete", "name": "Grasslands Champion", "desc": "Complete World 1"},
	{"id": "world2_complete", "name": "Cave Explorer", "desc": "Complete World 2"},
	{"id": "world3_complete", "name": "Sky Walker", "desc": "Complete World 3"},
	{"id": "world4_complete", "name": "Summit Conqueror", "desc": "Complete World 4"},
	{"id": "world5_complete", "name": "Final Victor", "desc": "Complete World 5"},
	{"id": "kill_100", "name": "Century", "desc": "Kill 100 enemies"},
	{"id": "kill_500", "name": "Warrior", "desc": "Kill 500 enemies"},
	{"id": "kill_1000", "name": "Legend", "desc": "Kill 1000 enemies"},
	{"id": "all_stars", "name": "Perfectionist", "desc": "Get 3 stars on all levels"},
	{"id": "hard_complete", "name": "Hardened", "desc": "Complete game on Hard"},
	{"id": "nightmare_complete", "name": "Nightmare Survivor", "desc": "Complete game on Nightmare"},
	{"id": "secret_5", "name": "Explorer", "desc": "Find 5 secrets"},
	{"id": "secret_10", "name": "Treasure Hunter", "desc": "Find 10 secrets"},
	{"id": "max_upgrades", "name": "Fully Upgraded", "desc": "Max all upgrades"},
]

static func check_achievements(upgrades: Dictionary, progress: Dictionary) -> Array:
	"""Returns newly unlocked achievement IDs."""
	var existing: Array = upgrades.get("achievements", [])
	var newly_unlocked: Array = []
	var completed: Array = progress.get("levels_completed", [])
	var total_killed = int(upgrades.get("total_enemies_killed", 0))

	for ach in ACHIEVEMENTS:
		if ach.id in existing:
			continue
		var unlocked = false
		match ach.id:
			"world1_complete":
				unlocked = _has_level(completed, 5)
			"world2_complete":
				unlocked = _has_level(completed, 10)
			"world3_complete":
				unlocked = _has_level(completed, 15)
			"world4_complete":
				unlocked = _has_level(completed, 20)
			"world5_complete":
				unlocked = _has_level(completed, 25)
			"kill_100":
				unlocked = total_killed >= 100
			"kill_500":
				unlocked = total_killed >= 500
			"kill_1000":
				unlocked = total_killed >= 1000
			"max_upgrades":
				unlocked = int(upgrades.get("hp_level", 0)) >= 3 and int(upgrades.get("speed_level", 0)) >= 3
		if unlocked:
			newly_unlocked.append(ach.id)

	return newly_unlocked

static func _has_level(completed: Array, level_id: int) -> bool:
	for v in completed:
		if int(v) == level_id:
			return true
	return false
