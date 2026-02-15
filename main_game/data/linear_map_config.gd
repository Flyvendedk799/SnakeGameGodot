class_name LinearMapConfig
extends RefCounted

static func get_level(level_id: int) -> Dictionary:
	match level_id:
		1:
			return _level_1()
		2:
			return _level_2()
		3:
			return _level_3()
		4:
			return _level_4()
		5:
			return _level_5()
		6:
			return _level_6()
		7:
			return _level_7()
		8:
			return _level_8()
		9:
			return _level_9()
		10:
			return _level_10()
		11:
			return _level_11()
		12:
			return _level_12()
		13:
			return _level_13()
		14:
			return _level_14()
		15:
			return _level_15()
		_:
			return _level_1()

static func _level_1() -> Dictionary:
	return {
		"id": 1,
		"name": "First Steps",
		"width": 2400,
		"height": 720,
		"theme": "grass",
		"bg_texture_path": "",
		"checkpoints": [
			{"x": 800, "y": 350, "rect": Rect2(750, 300, 100, 120), "layer": "surface"},
			{"x": 1600, "y": 350, "rect": Rect2(1550, 300, 100, 120), "layer": "surface"},
			{"x": 2300, "y": 350, "rect": Rect2(2250, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(2350, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}
		],
		"segments": [
			{
				"x_min": 0, "x_max": 750,
				"spawn_zones": [
					{"x_min": 200, "x_max": 400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer"], "density": 0.5, "max_concurrent": 3, "trigger_x": 150}
				]
			},
			{
				"x_min": 900, "x_max": 1540,
				"spawn_zones": [
					{"x_min": 1000, "x_max": 1200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer"], "density": 0.6, "max_concurrent": 4, "trigger_x": 950}
				]
			},
			{
				"x_min": 1700, "x_max": 2350,
				"spawn_zones": [
					{"x_min": 1800, "x_max": 2100, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1750}
				]
			}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_2() -> Dictionary:
	return {
		"id": 2,
		"name": "The Ascent",
		"width": 3200,
		"height": 720,
		"theme": "grass",
		"bg_texture_path": "",
		"checkpoints": [
			{"x": 700, "y": 350, "rect": Rect2(650, 300, 100, 120), "layer": "surface"},
			{"x": 1400, "y": 220, "rect": Rect2(1350, 180, 100, 100), "layer": "platform"},
			{"x": 2100, "y": 350, "rect": Rect2(2050, 300, 100, 120), "layer": "surface"},
			{"x": 2900, "y": 350, "rect": Rect2(2850, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(3150, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 300, "y_max": 420, "type": "ground"},
			{"id": "platform", "y_min": 180, "y_max": 260, "type": "platform"}
		],
		"segments": [
			{"x_min": 0, "x_max": 650, "spawn_zones": [{"x_min": 200, "x_max": 500, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 800, "x_max": 1340, "spawn_zones": [{"x_min": 900, "x_max": 1200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 850}, {"x_min": 1000, "x_max": 1300, "y_min": 180, "y_max": 260, "layer": "platform", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 3, "trigger_x": 950}]},
			{"x_min": 1450, "x_max": 2040, "spawn_zones": [{"x_min": 1550, "x_max": 1900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1500}]},
			{"x_min": 2150, "x_max": 3150, "spawn_zones": [{"x_min": 2300, "x_max": 2900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.75, "max_concurrent": 6, "trigger_x": 2200}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_3() -> Dictionary:
	return {
		"id": 3,
		"name": "Below",
		"width": 4000,
		"height": 720,
		"theme": "cave",
		"bg_texture_path": "",
		"checkpoints": [
			{"x": 800, "y": 350, "rect": Rect2(750, 300, 100, 120), "layer": "surface"},
			{"x": 1600, "y": 350, "rect": Rect2(1550, 300, 100, 120), "layer": "surface"},
			{"x": 2300, "y": 520, "rect": Rect2(2250, 480, 100, 100), "layer": "underground"},
			{"x": 3000, "y": 350, "rect": Rect2(2950, 300, 100, 120), "layer": "surface"},
			{"x": 3700, "y": 350, "rect": Rect2(3650, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(3950, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"},
			{"id": "underground", "y_min": 450, "y_max": 580, "type": "cave"}
		],
		"segments": [
			{"x_min": 0, "x_max": 750, "spawn_zones": [{"x_min": 200, "x_max": 600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 150}]},
			{"x_min": 900, "x_max": 1540, "spawn_zones": [{"x_min": 1000, "x_max": 1400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 950}]},
			{"x_min": 1700, "x_max": 2240, "spawn_zones": [{"x_min": 1750, "x_max": 2100, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["complainer", "manager", "bomber"], "density": 0.85, "max_concurrent": 6, "trigger_x": 1700}]},
			{"x_min": 2400, "x_max": 2940, "spawn_zones": [{"x_min": 2500, "x_max": 2800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 2450}]},
			{"x_min": 3050, "x_max": 3950, "spawn_zones": [{"x_min": 3200, "x_max": 3700, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.75, "max_concurrent": 6, "trigger_x": 3100}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_4() -> Dictionary:
	return {
		"id": 4,
		"name": "High Wire",
		"width": 4800,
		"height": 720,
		"theme": "sky",
		"bg_texture_path": "",
		"checkpoints": [
			{"x": 800, "y": 350, "rect": Rect2(750, 300, 100, 120), "layer": "surface"},
			{"x": 1600, "y": 350, "rect": Rect2(1550, 300, 100, 120), "layer": "surface"},
			{"x": 2400, "y": 220, "rect": Rect2(2350, 180, 100, 100), "layer": "platform"},
			{"x": 3000, "y": 125, "rect": Rect2(2950, 80, 100, 90), "layer": "skybridge"},
			{"x": 3600, "y": 350, "rect": Rect2(3550, 300, 100, 120), "layer": "surface"},
			{"x": 4400, "y": 350, "rect": Rect2(4350, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4750, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 300, "y_max": 420, "type": "ground"},
			{"id": "platform", "y_min": 180, "y_max": 260, "type": "platform"},
			{"id": "skybridge", "y_min": 80, "y_max": 170, "type": "skybridge"}
		],
		"segments": [
			{"x_min": 0, "x_max": 750, "spawn_zones": [{"x_min": 200, "x_max": 600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 150}]},
			{"x_min": 900, "x_max": 1540, "spawn_zones": [{"x_min": 1000, "x_max": 1400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 950}]},
			{"x_min": 1700, "x_max": 2340, "spawn_zones": [{"x_min": 1850, "x_max": 2200, "y_min": 180, "y_max": 260, "layer": "platform", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1750}]},
			{"x_min": 2450, "x_max": 2940, "spawn_zones": [{"x_min": 2550, "x_max": 2850, "y_min": 80, "y_max": 170, "layer": "skybridge", "pool": ["manager", "hoa"], "density": 0.8, "max_concurrent": 5, "trigger_x": 2500}]},
			{"x_min": 3050, "x_max": 3540, "spawn_zones": [{"x_min": 3150, "x_max": 3400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 3100}]},
			{"x_min": 3650, "x_max": 4750, "spawn_zones": [{"x_min": 3800, "x_max": 4550, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3700}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_5() -> Dictionary:
	return {
		"id": 5,
		"name": "The Summit",
		"width": 8500,
		"height": 720,
		"theme": "summit",
		"bg_texture_path": "",
		"checkpoints": [
			{"x": 700, "y": 350, "rect": Rect2(650, 300, 100, 120), "layer": "surface"},
			{"x": 1400, "y": 350, "rect": Rect2(1350, 300, 100, 120), "layer": "surface"},
			{"x": 2100, "y": 350, "rect": Rect2(2050, 300, 100, 120), "layer": "surface"},
			{"x": 2800, "y": 520, "rect": Rect2(2750, 480, 100, 100), "layer": "underground"},
			{"x": 3500, "y": 220, "rect": Rect2(3450, 180, 100, 100), "layer": "platform"},
			{"x": 4200, "y": 350, "rect": Rect2(4150, 300, 100, 120), "layer": "surface"},
			{"x": 4900, "y": 350, "rect": Rect2(4850, 300, 100, 120), "layer": "surface"},
			{"x": 5600, "y": 125, "rect": Rect2(5550, 80, 100, 90), "layer": "skybridge"},
			{"x": 6300, "y": 350, "rect": Rect2(6250, 300, 100, 120), "layer": "surface"},
			{"x": 7000, "y": 350, "rect": Rect2(6950, 300, 100, 120), "layer": "surface"},
			{"x": 7700, "y": 350, "rect": Rect2(7650, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(8450, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"},
			{"id": "platform", "y_min": 180, "y_max": 260, "type": "platform"},
			{"id": "underground", "y_min": 450, "y_max": 580, "type": "cave"},
			{"id": "skybridge", "y_min": 80, "y_max": 170, "type": "skybridge"}
		],
		"segments": [
			{"x_min": 0, "x_max": 650, "spawn_zones": [{"x_min": 200, "x_max": 500, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 800, "x_max": 1340, "spawn_zones": [{"x_min": 900, "x_max": 1200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.65, "max_concurrent": 5, "trigger_x": 850}]},
			{"x_min": 1450, "x_max": 2040, "spawn_zones": [{"x_min": 1550, "x_max": 1900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1500}]},
			{"x_min": 2150, "x_max": 2740, "spawn_zones": [{"x_min": 2250, "x_max": 2600, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2200}]},
			{"x_min": 2850, "x_max": 3440, "spawn_zones": [{"x_min": 2950, "x_max": 3300, "y_min": 180, "y_max": 260, "layer": "platform", "pool": ["complainer", "manager", "witch"], "density": 0.75, "max_concurrent": 5, "trigger_x": 2900}]},
			{"x_min": 3550, "x_max": 4140, "spawn_zones": [{"x_min": 3650, "x_max": 4000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3600}]},
			{"x_min": 4250, "x_max": 4840, "spawn_zones": [{"x_min": 4350, "x_max": 4700, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 6, "trigger_x": 4300}]},
			{"x_min": 4950, "x_max": 5540, "spawn_zones": [{"x_min": 5050, "x_max": 5400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 6, "trigger_x": 5000}]},
			{"x_min": 5650, "x_max": 6240, "spawn_zones": [{"x_min": 5750, "x_max": 6100, "y_min": 80, "y_max": 170, "layer": "skybridge", "pool": ["manager", "hoa", "witch"], "density": 0.9, "max_concurrent": 5, "trigger_x": 5700}]},
			{"x_min": 6350, "x_max": 6940, "spawn_zones": [{"x_min": 6450, "x_max": 6800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "mega"], "density": 0.9, "max_concurrent": 7, "trigger_x": 6400}]},
			{"x_min": 7050, "x_max": 8450, "spawn_zones": [{"x_min": 7200, "x_max": 8300, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "mega"], "density": 1.0, "max_concurrent": 8, "trigger_x": 7100}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 6: Ambush Alley --- Enemies spawn BEHIND you as you advance
static func _level_6() -> Dictionary:
	return {
		"id": 6,
		"name": "Ambush Alley",
		"width": 3600,
		"height": 720,
		"theme": "cave",
		"checkpoints": [
			{"x": 800, "y": 350, "rect": Rect2(750, 300, 100, 120), "layer": "surface"},
			{"x": 1800, "y": 350, "rect": Rect2(1750, 300, 100, 120), "layer": "surface"},
			{"x": 2800, "y": 350, "rect": Rect2(2750, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(3550, 250, 50, 220),
		"layers": [{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}],
		"segments": [
			{"x_min": 0, "x_max": 750, "spawn_zones": [{"x_min": 200, "x_max": 600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.5, "max_concurrent": 4, "trigger_x": 150}]},
			{"x_min": 900, "x_max": 1740, "spawn_zones": [
				{"x_min": 1100, "x_max": 1600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1000, "ambush": true}
			]},
			{"x_min": 1850, "x_max": 2740, "spawn_zones": [
				{"x_min": 2000, "x_max": 2600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 1900, "ambush": true}
			]},
			{"x_min": 2850, "x_max": 3550, "spawn_zones": [
				{"x_min": 3000, "x_max": 3400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 7, "trigger_x": 2900, "ambush": true}
			]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 7: Gold Rush --- Zone with 1.5x gold multiplier
static func _level_7() -> Dictionary:
	return {
		"id": 7,
		"name": "Gold Rush",
		"width": 4000,
		"height": 720,
		"theme": "grass",
		"checkpoints": [
			{"x": 1000, "y": 350, "rect": Rect2(950, 300, 100, 120), "layer": "surface"},
			{"x": 2500, "y": 350, "rect": Rect2(2450, 300, 100, 120), "layer": "surface"},
			{"x": 3600, "y": 350, "rect": Rect2(3550, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(3950, 250, 50, 220),
		"layers": [{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}],
		"segments": [
			{"x_min": 0, "x_max": 940, "spawn_zones": [{"x_min": 200, "x_max": 800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 5, "trigger_x": 150}]},
			{"x_min": 1050, "x_max": 2440, "spawn_zones": [{"x_min": 1150, "x_max": 2300, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.75, "max_concurrent": 6, "trigger_x": 1100, "gold_multiplier": 1.5}]},
			{"x_min": 2550, "x_max": 3540, "spawn_zones": [{"x_min": 2700, "x_max": 3400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa", "bomber"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2600}]},
			{"x_min": 3650, "x_max": 3950, "spawn_zones": [{"x_min": 3700, "x_max": 3900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.5, "max_concurrent": 3, "trigger_x": 3660}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 8: Safe Havens --- Checkpoints fully heal you (heal_ratio: 1.0)
static func _level_8() -> Dictionary:
	return {
		"id": 8,
		"name": "Safe Havens",
		"width": 4400,
		"height": 720,
		"theme": "sky",
		"checkpoints": [
			{"x": 800, "y": 350, "rect": Rect2(750, 300, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			{"x": 1600, "y": 220, "rect": Rect2(1550, 180, 100, 100), "layer": "platform", "heal_ratio": 1.0},
			{"x": 2400, "y": 350, "rect": Rect2(2350, 300, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			{"x": 3200, "y": 350, "rect": Rect2(3150, 300, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			{"x": 4000, "y": 350, "rect": Rect2(3950, 300, 100, 120), "layer": "surface", "heal_ratio": 1.0}
		],
		"goal_rect": Rect2(4350, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"},
			{"id": "platform", "y_min": 180, "y_max": 260, "type": "platform"}
		],
		"segments": [
			{"x_min": 0, "x_max": 750, "spawn_zones": [{"x_min": 200, "x_max": 600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.65, "max_concurrent": 5, "trigger_x": 150}]},
			{"x_min": 900, "x_max": 1540, "spawn_zones": [{"x_min": 1000, "x_max": 1400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 950}, {"x_min": 1100, "x_max": 1400, "y_min": 180, "y_max": 260, "layer": "platform", "pool": ["complainer", "witch"], "density": 0.6, "max_concurrent": 3, "trigger_x": 1050}]},
			{"x_min": 1700, "x_max": 2340, "spawn_zones": [{"x_min": 1850, "x_max": 2200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 1750}]},
			{"x_min": 2450, "x_max": 3140, "spawn_zones": [{"x_min": 2600, "x_max": 3000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2500}]},
			{"x_min": 3250, "x_max": 4350, "spawn_zones": [{"x_min": 3400, "x_max": 4200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch"], "density": 0.85, "max_concurrent": 7, "trigger_x": 3300}]}
		],
		"respawn_hp_ratio": 0.6,
		"respawn_gold_penalty_ratio": 0.12,
		"max_waves": 1
	}

# --- Level 9: The Long March --- Endurance: long segments, few checkpoints
static func _level_9() -> Dictionary:
	return {
		"id": 9,
		"name": "The Long March",
		"width": 6000,
		"height": 720,
		"theme": "cave",
		"checkpoints": [
			{"x": 2000, "y": 350, "rect": Rect2(1950, 300, 100, 120), "layer": "surface"},
			{"x": 4000, "y": 350, "rect": Rect2(3950, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(5950, 250, 50, 220),
		"layers": [{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}],
		"segments": [
			{"x_min": 0, "x_max": 1940, "spawn_zones": [
				{"x_min": 300, "x_max": 900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.5, "max_concurrent": 4, "trigger_x": 200},
				{"x_min": 1000, "x_max": 1600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.6, "max_concurrent": 5, "trigger_x": 1050},
				{"x_min": 1650, "x_max": 1900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa"], "density": 0.65, "max_concurrent": 5, "trigger_x": 1700}
			]},
			{"x_min": 2050, "x_max": 3940, "spawn_zones": [
				{"x_min": 2200, "x_max": 2800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.65, "max_concurrent": 5, "trigger_x": 2150},
				{"x_min": 2900, "x_max": 3600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.7, "max_concurrent": 6, "trigger_x": 2950},
				{"x_min": 3650, "x_max": 3900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa", "witch"], "density": 0.75, "max_concurrent": 6, "trigger_x": 3700}
			]},
			{"x_min": 4050, "x_max": 5950, "spawn_zones": [
				{"x_min": 4200, "x_max": 5000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 4250},
				{"x_min": 5100, "x_max": 5800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa", "mega"], "density": 0.85, "max_concurrent": 7, "trigger_x": 5150}
			]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.2,
		"max_waves": 1
	}

# --- Level 10: Elite Invasion --- Only manager, HOA, mega, witch (no weak complainers)
static func _level_10() -> Dictionary:
	return {
		"id": 10,
		"name": "Elite Invasion",
		"width": 4200,
		"height": 720,
		"theme": "summit",
		"checkpoints": [
			{"x": 900, "y": 350, "rect": Rect2(850, 300, 100, 120), "layer": "surface"},
			{"x": 2100, "y": 350, "rect": Rect2(2050, 300, 100, 120), "layer": "surface"},
			{"x": 3300, "y": 350, "rect": Rect2(3250, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4150, 250, 50, 220),
		"layers": [{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}],
		"segments": [
			{"x_min": 0, "x_max": 840, "spawn_zones": [{"x_min": 250, "x_max": 750, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager"], "density": 0.55, "max_concurrent": 4, "trigger_x": 200}]},
			{"x_min": 950, "x_max": 2040, "spawn_zones": [{"x_min": 1050, "x_max": 1900, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1000}]},
			{"x_min": 2150, "x_max": 3240, "spawn_zones": [{"x_min": 2300, "x_max": 3100, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa", "witch"], "density": 0.75, "max_concurrent": 6, "trigger_x": 2200}]},
			{"x_min": 3350, "x_max": 4150, "spawn_zones": [{"x_min": 3500, "x_max": 4000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa", "mega", "witch"], "density": 0.85, "max_concurrent": 6, "trigger_x": 3400}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 11: Underground Gauntlet --- All underground, bombers heavy
static func _level_11() -> Dictionary:
	return {
		"id": 11,
		"name": "Underground Gauntlet",
		"width": 3800,
		"height": 720,
		"theme": "cave",
		"checkpoints": [
			{"x": 950, "y": 520, "rect": Rect2(900, 480, 100, 100), "layer": "underground"},
			{"x": 1900, "y": 520, "rect": Rect2(1850, 480, 100, 100), "layer": "underground"},
			{"x": 2850, "y": 520, "rect": Rect2(2800, 480, 100, 100), "layer": "underground"}
		],
		"goal_rect": Rect2(3750, 450, 50, 150),
		"layers": [
			{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"},
			{"id": "underground", "y_min": 450, "y_max": 580, "type": "cave"}
		],
		"segments": [
			{"x_min": 0, "x_max": 400, "spawn_zones": [{"x_min": 150, "x_max": 350, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "bomber"], "density": 0.55, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 450, "x_max": 890, "spawn_zones": [{"x_min": 500, "x_max": 800, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["complainer", "manager", "bomber"], "density": 0.85, "max_concurrent": 6, "trigger_x": 480}]},
			{"x_min": 950, "x_max": 1840, "spawn_zones": [{"x_min": 1000, "x_max": 1700, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["manager", "bomber", "bomber", "hoa"], "density": 0.9, "max_concurrent": 7, "trigger_x": 1000}]},
			{"x_min": 1900, "x_max": 2790, "spawn_zones": [{"x_min": 2000, "x_max": 2650, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["bomber", "bomber", "manager", "hoa"], "density": 0.95, "max_concurrent": 7, "trigger_x": 1950}]},
			{"x_min": 2900, "x_max": 3750, "spawn_zones": [{"x_min": 3000, "x_max": 3600, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["bomber", "hoa", "mega"], "density": 1.0, "max_concurrent": 6, "trigger_x": 2950}]}
		],
		"respawn_hp_ratio": 0.45,
		"respawn_gold_penalty_ratio": 0.18,
		"max_waves": 1
	}

# --- Level 12: Sky Scramble --- Mostly skybridge + platforms
static func _level_12() -> Dictionary:
	return {
		"id": 12,
		"name": "Sky Scramble",
		"width": 4600,
		"height": 720,
		"theme": "sky",
		"checkpoints": [
			{"x": 800, "y": 350, "rect": Rect2(750, 300, 100, 120), "layer": "surface"},
			{"x": 1600, "y": 125, "rect": Rect2(1550, 80, 100, 90), "layer": "skybridge"},
			{"x": 2600, "y": 220, "rect": Rect2(2550, 180, 100, 100), "layer": "platform"},
			{"x": 3600, "y": 350, "rect": Rect2(3550, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4550, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 300, "y_max": 420, "type": "ground"},
			{"id": "platform", "y_min": 180, "y_max": 260, "type": "platform"},
			{"id": "skybridge", "y_min": 80, "y_max": 170, "type": "skybridge"}
		],
		"segments": [
			{"x_min": 0, "x_max": 750, "spawn_zones": [{"x_min": 200, "x_max": 600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.55, "max_concurrent": 4, "trigger_x": 150}]},
			{"x_min": 900, "x_max": 1540, "spawn_zones": [{"x_min": 1000, "x_max": 1400, "y_min": 180, "y_max": 260, "layer": "platform", "pool": ["complainer", "manager", "witch"], "density": 0.7, "max_concurrent": 5, "trigger_x": 950}]},
			{"x_min": 1700, "x_max": 2540, "spawn_zones": [{"x_min": 1850, "x_max": 2400, "y_min": 80, "y_max": 170, "layer": "skybridge", "pool": ["manager", "hoa", "witch"], "density": 0.85, "max_concurrent": 6, "trigger_x": 1750}]},
			{"x_min": 2650, "x_max": 3540, "spawn_zones": [{"x_min": 2750, "x_max": 3400, "y_min": 180, "y_max": 260, "layer": "platform", "pool": ["manager", "witch", "hoa"], "density": 0.8, "max_concurrent": 5, "trigger_x": 2700}]},
			{"x_min": 3650, "x_max": 4550, "spawn_zones": [{"x_min": 3800, "x_max": 4400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3700}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 13: Mixed Madness --- All enemy types, high density
static func _level_13() -> Dictionary:
	return {
		"id": 13,
		"name": "Mixed Madness",
		"width": 5000,
		"height": 720,
		"theme": "grass",
		"checkpoints": [
			{"x": 1200, "y": 350, "rect": Rect2(1150, 300, 100, 120), "layer": "surface"},
			{"x": 2500, "y": 350, "rect": Rect2(2450, 300, 100, 120), "layer": "surface"},
			{"x": 3800, "y": 350, "rect": Rect2(3750, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4950, 250, 50, 220),
		"layers": [{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}],
		"segments": [
			{"x_min": 0, "x_max": 1140, "spawn_zones": [{"x_min": 300, "x_max": 1000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 250}]},
			{"x_min": 1250, "x_max": 2440, "spawn_zones": [{"x_min": 1350, "x_max": 2300, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 1300}]},
			{"x_min": 2550, "x_max": 3740, "spawn_zones": [{"x_min": 2700, "x_max": 3600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch", "mega"], "density": 0.95, "max_concurrent": 8, "trigger_x": 2600}]},
			{"x_min": 3850, "x_max": 4950, "spawn_zones": [{"x_min": 4000, "x_max": 4800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch", "mega"], "density": 1.0, "max_concurrent": 8, "trigger_x": 3900}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 14: The Chase --- Heavy ambush, enemies spawn from behind
static func _level_14() -> Dictionary:
	return {
		"id": 14,
		"name": "The Chase",
		"width": 4800,
		"height": 720,
		"theme": "cave",
		"checkpoints": [
			{"x": 1200, "y": 350, "rect": Rect2(1150, 300, 100, 120), "layer": "surface"},
			{"x": 2400, "y": 350, "rect": Rect2(2350, 300, 100, 120), "layer": "surface"},
			{"x": 3600, "y": 350, "rect": Rect2(3550, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4750, 250, 50, 220),
		"layers": [{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"}],
		"segments": [
			{"x_min": 0, "x_max": 1140, "spawn_zones": [{"x_min": 300, "x_max": 1000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 5, "trigger_x": 200}]},
			{"x_min": 1250, "x_max": 2340, "spawn_zones": [
				{"x_min": 1400, "x_max": 2200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 1300, "ambush": true},
				{"x_min": 1800, "x_max": 2200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["bomber"], "density": 0.5, "max_concurrent": 3, "trigger_x": 1750, "ambush": true}
			]},
			{"x_min": 2450, "x_max": 3540, "spawn_zones": [
				{"x_min": 2600, "x_max": 3400, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "hoa", "witch"], "density": 0.85, "max_concurrent": 7, "trigger_x": 2550, "ambush": true}
			]},
			{"x_min": 3650, "x_max": 4750, "spawn_zones": [
				{"x_min": 3800, "x_max": 4600, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa", "mega"], "density": 0.9, "max_concurrent": 7, "trigger_x": 3700, "ambush": true}
			]}
		],
		"respawn_hp_ratio": 0.45,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 15: The Final Gauntlet --- Marathon finale, all mechanics combined
static func _level_15() -> Dictionary:
	return {
		"id": 15,
		"name": "The Final Gauntlet",
		"width": 7200,
		"height": 720,
		"theme": "summit",
		"checkpoints": [
			{"x": 1200, "y": 350, "rect": Rect2(1150, 300, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			{"x": 2400, "y": 520, "rect": Rect2(2350, 480, 100, 100), "layer": "underground"},
			{"x": 3600, "y": 125, "rect": Rect2(3550, 80, 100, 90), "layer": "skybridge"},
			{"x": 4800, "y": 350, "rect": Rect2(4750, 300, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			{"x": 6000, "y": 350, "rect": Rect2(5950, 300, 100, 120), "layer": "surface"},
			{"x": 6800, "y": 350, "rect": Rect2(6750, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(7150, 250, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 280, "y_max": 420, "type": "ground"},
			{"id": "platform", "y_min": 180, "y_max": 260, "type": "platform"},
			{"id": "underground", "y_min": 450, "y_max": 580, "type": "cave"},
			{"id": "skybridge", "y_min": 80, "y_max": 170, "type": "skybridge"}
		],
		"segments": [
			{"x_min": 0, "x_max": 1140, "spawn_zones": [{"x_min": 300, "x_max": 1000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 200}]},
			{"x_min": 1250, "x_max": 2340, "spawn_zones": [{"x_min": 1400, "x_max": 2200, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 1350, "ambush": true}]},
			{"x_min": 2450, "x_max": 3540, "spawn_zones": [{"x_min": 2600, "x_max": 3400, "y_min": 450, "y_max": 580, "layer": "underground", "pool": ["manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 2500}]},
			{"x_min": 3650, "x_max": 4740, "spawn_zones": [{"x_min": 3800, "x_max": 4600, "y_min": 80, "y_max": 170, "layer": "skybridge", "pool": ["manager", "hoa", "witch"], "density": 0.85, "max_concurrent": 6, "trigger_x": 3700}]},
			{"x_min": 4850, "x_max": 5940, "spawn_zones": [{"x_min": 5000, "x_max": 5800, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 4900, "gold_multiplier": 1.5}]},
			{"x_min": 6050, "x_max": 7150, "spawn_zones": [{"x_min": 6200, "x_max": 7000, "y_min": 300, "y_max": 420, "layer": "surface", "pool": ["manager", "bomber", "hoa", "mega", "witch"], "density": 1.0, "max_concurrent": 8, "trigger_x": 6100, "ambush": true}]}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}
