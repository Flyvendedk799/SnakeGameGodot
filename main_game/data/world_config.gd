class_name WorldConfig
extends RefCounted

## World and campaign structure: 5 worlds, 25 levels total.
## Each world has 4 regular levels + 1 boss level.

const WORLDS = [
	{
		"id": 1, "name": "Grasslands", "theme": "grass",
		"levels": [1, 2, 3, 4], "boss_level": 5,
		"description": "Where it all begins. Open fields, gentle slopes, and the first wave of Karens.",
		"color": Color8(95, 180, 85)
	},
	{
		"id": 2, "name": "Caves", "theme": "cave",
		"levels": [6, 7, 8, 9], "boss_level": 10,
		"description": "Deep beneath the surface. Lava pits, tight corridors, and ambush-prone tunnels.",
		"color": Color8(120, 90, 140)
	},
	{
		"id": 3, "name": "Sky Realm", "theme": "sky",
		"levels": [11, 12, 13, 14], "boss_level": 15,
		"description": "Floating platforms and treacherous winds. One wrong step and you fall.",
		"color": Color8(140, 190, 220)
	},
	{
		"id": 4, "name": "Summit", "theme": "summit",
		"levels": [16, 17, 18, 19], "boss_level": 20,
		"description": "The frozen peak. Ice, narrow paths, and relentless elite enemies.",
		"color": Color8(170, 175, 190)
	},
	{
		"id": 5, "name": "Final Gauntlet", "theme": "summit",
		"levels": [21, 22, 23, 24], "boss_level": 25,
		"description": "Everything you've learned, put to the ultimate test. No mercy.",
		"color": Color8(200, 60, 60)
	}
]

static func get_world_for_level(level_id: int) -> Dictionary:
	for w in WORLDS:
		if level_id in w.levels or level_id == w.boss_level:
			return w
	return WORLDS[0]

static func get_world_index_for_level(level_id: int) -> int:
	for i in range(WORLDS.size()):
		var w = WORLDS[i]
		if level_id in w.levels or level_id == w.boss_level:
			return i
	return 0

static func is_boss_level(level_id: int) -> bool:
	for w in WORLDS:
		if level_id == w.boss_level:
			return true
	return false

static func get_total_levels() -> int:
	return 25

static func get_level_name_in_world(level_id: int) -> String:
	var w = get_world_for_level(level_id)
	if level_id == w.boss_level:
		return "BOSS"
	var idx = w.levels.find(level_id)
	if idx >= 0:
		return "%d-%d" % [w.id, idx + 1]
	return str(level_id)
