class_name SaveManager
extends RefCounted

const SAVE_PATH = "user://karen_defense_unlocks.save"

static func load_unlocks() -> Dictionary:
	var result = {"world2": false, "world3": false}
	if not FileAccess.file_exists(SAVE_PATH):
		return result
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return result
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return result
	var data = json.get_data()
	if data is Dictionary:
		result["world2"] = data.get("world2", false)
		result["world3"] = data.get("world3", false)
	return result

static func save_unlocks(unlocks: Dictionary) -> bool:
	var data = {"world2": unlocks.get("world2", false), "world3": unlocks.get("world3", false)}
	var json_str = JSON.stringify(data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_str)
	file.close()
	return true

static func unlock_world(world_id: int, unlocks: Dictionary) -> bool:
	if world_id == 2:
		unlocks["world2"] = true
	elif world_id == 3:
		unlocks["world3"] = true
	return save_unlocks(unlocks)

# --- Main Game progress ---
const MAIN_GAME_SAVE_PATH = "user://main_game_progress.save"

static func load_main_game_progress() -> Dictionary:
	var result = {"levels_completed": [], "level_stars": {}}
	if not FileAccess.file_exists(MAIN_GAME_SAVE_PATH):
		return result
	var file = FileAccess.open(MAIN_GAME_SAVE_PATH, FileAccess.READ)
	if not file:
		return result
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return result
	var data = json.get_data()
	if data is Dictionary:
		result["levels_completed"] = data.get("levels_completed", [])
		result["level_stars"] = data.get("level_stars", {})
	return result

static func save_main_game_progress(progress: Dictionary) -> bool:
	var data = {
		"levels_completed": progress.get("levels_completed", []),
		"level_stars": progress.get("level_stars", {})
	}
	var json_str = JSON.stringify(data)
	var file = FileAccess.open(MAIN_GAME_SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_str)
	file.close()
	return true

static func is_level_unlocked(level_id: int, progress: Dictionary) -> bool:
	if level_id <= 1:
		return true
	var completed: Array = progress.get("levels_completed", [])
	var prev_id = level_id - 1
	for v in completed:
		if int(v) == prev_id:
			return true
	return false

static func complete_level(level_id: int, progress: Dictionary, stars: int = 1) -> bool:
	var completed: Array = progress.get("levels_completed", [])
	if not (level_id in completed):
		completed.append(level_id)
		completed.sort()
	progress["levels_completed"] = completed
	var stars_dict: Dictionary = progress.get("level_stars", {})
	stars_dict[level_id] = maxi(stars_dict.get(level_id, 0), stars)
	progress["level_stars"] = stars_dict
	return save_main_game_progress(progress)

# --- Main Game upgrades (souls, HP, speed, potions) ---
const UPGRADES_SAVE_PATH = "user://main_game_upgrades.save"

static func load_upgrades() -> Dictionary:
	var result = {"souls": 0, "hp_level": 0, "speed_level": 0, "potions": 1, "achievements": []}
	if not FileAccess.file_exists(UPGRADES_SAVE_PATH):
		return result
	var file = FileAccess.open(UPGRADES_SAVE_PATH, FileAccess.READ)
	if not file:
		return result
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return result
	var data = json.get_data()
	if data is Dictionary:
		for k in result:
			if data.has(k):
				result[k] = data[k]
	return result

static func save_upgrades(upgrades: Dictionary) -> bool:
	var json_str = JSON.stringify(upgrades)
	var file = FileAccess.open(UPGRADES_SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_str)
	file.close()
	return true

static func buy_upgrade(type: String, upgrades: Dictionary) -> bool:
	var key = type + "_level"
	if type == "potions":
		key = "potions"
	var current = int(upgrades.get(key, 0))
	var cost = get_upgrade_cost(type, current)
	var souls = int(upgrades.get("souls", 0))
	if souls < cost:
		return false
	var max_lvl = get_max_upgrade_level(type)
	if current >= max_lvl:
		return false
	upgrades["souls"] = souls - cost
	upgrades[key] = current + 1
	return save_upgrades(upgrades)

static func get_max_upgrade_level(_type: String) -> int:
	return 3

static func get_upgrade_cost(type: String, current: int) -> int:
	var base = 10 if type == "potions" else 25
	return base + current * 15
