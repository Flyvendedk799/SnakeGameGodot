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
