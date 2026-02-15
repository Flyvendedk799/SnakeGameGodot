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
	if level_id == 1:
		return true
	var completed = progress.get("levels_completed", [])
	return (level_id - 1) in completed

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
