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
		16:
			return _level_with_id(_level_1(), 16, "Frost Approach", "summit")
		17:
			return _level_with_id(_level_2(), 17, "Ice Path", "summit")
		18:
			return _level_with_id(_level_3(), 18, "Blizzard", "summit")
		19:
			return _level_with_id(_level_4(), 19, "Peak Assault", "summit")
		20:
			return _level_with_id(_level_5(), 20, "Summit Guardian", "summit")
		21:
			return _level_with_id(_level_1(), 21, "Final Stretch", "summit")
		22:
			return _level_with_id(_level_2(), 22, "Last Stand", "summit")
		23:
			return _level_with_id(_level_3(), 23, "The Gauntlet", "summit")
		24:
			return _level_with_id(_level_4(), 24, "Endgame", "summit")
		25:
			return _level_with_id(_level_5(), 25, "The Final Boss", "summit")
		_:
			return _level_1()

static func _level_with_id(base: Dictionary, level_id: int, name: String, theme_override: String = "") -> Dictionary:
	var c = base.duplicate(true)
	c["id"] = level_id
	c["name"] = name
	if not theme_override.is_empty():
		c["theme"] = theme_override
	return c

static func _level_1() -> Dictionary:
	# Elite Tutorial: [1] Jump over 90px pit, [2] DASH across 100px gap (mandatory), [3] DOUBLE JUMP to elevated platform + secret ledge
	return {
		"id": 1,
		"name": "First Steps",
		"width": 2600,
		"height": 720,
		"theme": "grass",
		"bg_texture_path": "",
		"floor_segments": [
			{"x_min": 0, "x_max": 368, "y_min": 360, "y_max": 480},
			{"x_min": 468, "x_max": 1410, "y_min": 360, "y_max": 480},  # Adjusted: first pit now 100px (368-468)
			{"x_min": 1520, "x_max": 2000, "y_min": 280, "y_max": 400},  # Elevated platform (requires double-jump)
			{"x_min": 2100, "x_max": 2600, "y_min": 360, "y_max": 480}
		],
		"platforms": [
			# Secret ledge (double-jump height) - early optional challenge
			{"x": 250, "y": 220, "w": 80, "h": 22},
			# First pit bridge (tutorial jump)
			{"x": 380, "y": 336, "w": 70, "h": 22},
			# REMOVED platform at x=1420 to enforce DASH requirement across 110px gap (1410-1520)
			# Third pit bridge
			{"x": 2020, "y": 358, "w": 60, "h": 22}
		],
		"checkpoints": [
			{"x": 300, "y": 400, "rect": Rect2(250, 360, 100, 120), "layer": "surface"},
			{"x": 1620, "y": 320, "rect": Rect2(1570, 280, 100, 120), "layer": "platform"},  # Moved AFTER dash gap - earned checkpoint
			{"x": 1880, "y": 320, "rect": Rect2(1830, 280, 100, 120), "layer": "platform"},
			{"x": 2380, "y": 400, "rect": Rect2(2330, 360, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(2550, 300, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 360, "y_max": 480, "type": "ground"},
			{"id": "platform", "y_min": 220, "y_max": 280, "type": "platform"},  # Extended range for secret ledge
			{"id": "secret", "y_min": 220, "y_max": 242, "type": "platform"}
		],
		"segments": [
			# Segment 1: Gentle intro - only 1-2 enemies before first pit
			{"x_min": 0, "x_max": 368, "spawn_zones": [{"x_min": 150, "x_max": 320, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer"], "density": 0.4, "max_concurrent": 2, "trigger_x": 80}]},
			# Segment 2: First platform
			{"x_min": 380, "x_max": 458, "spawn_zones": [{"x_min": 385, "x_max": 445, "y_min": 330, "y_max": 355, "layer": "platform", "pool": ["complainer"], "density": 0.3, "max_concurrent": 1, "trigger_x": 375}]},
			# Segment 3: Post-first-pit, pre-dash-gap - density increases
			{"x_min": 470, "x_max": 1410, "spawn_zones": [
				{"x_min": 550, "x_max": 1000, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer"], "density": 0.65, "max_concurrent": 4, "trigger_x": 480},
				{"x_min": 1050, "x_max": 1350, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1020}
			]},
			# Segment 4: Elevated platform - post-dash, higher threat
			{"x_min": 1520, "x_max": 2600, "spawn_zones": [
				{"x_min": 1650, "x_max": 1950, "y_min": 285, "y_max": 395, "layer": "platform", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 4, "trigger_x": 1540},
				{"x_min": 2100, "x_max": 2450, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.75, "max_concurrent": 5, "trigger_x": 2080}
			]}
		],
		"decor": [
			{"x": 360, "y": 380, "type": "first_pit_marker"},
			{"x": 250, "y": 200, "type": "secret_hint"},
			{"x": 1380, "y": 380, "type": "dash_required"},
			{"x": 1500, "y": 260, "type": "double_jump_sign"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_2() -> Dictionary:
	# Elite Platformer: DOUBLE JUMP chains, WALL JUMP shaft (tightened), optional GRAPPLE bypass, SPRINT finale, underground reward pocket
	return {
		"id": 2,
		"name": "The Ascent",
		"width": 3600,
		"height": 720,
		"theme": "grass",
		"bg_texture_path": "",
		"floor_segments": [
			{"x_min": 0, "x_max": 550, "y_min": 400, "y_max": 500},
			{"x_min": 680, "x_max": 1100, "y_min": 350, "y_max": 450},
			{"x_min": 840, "x_max": 1060, "y_min": 480, "y_max": 580},  # Underground pocket
			{"x_min": 1180, "x_max": 2000, "y_min": 250, "y_max": 350},  # Post-wall-jump elevated
			{"x_min": 2080, "x_max": 3600, "y_min": 400, "y_max": 500}  # Sprint finale
		],
		"platforms": [
			{"x": 560, "y": 378, "w": 100, "h": 22},
			{"x": 600, "y": 328, "w": 80, "h": 22},
			# Drop-through platform at top of wall-jump shaft for descent variety
			{"x": 1070, "y": 328, "w": 90, "h": 22, "drop_through": true},
			{"x": 1150, "y": 228, "w": 90, "h": 22},
			{"x": 2020, "y": 378, "w": 120, "h": 22}
		],
		"wall_segments": [
			{"x": 838, "y": 350, "w": 20, "h": 250},  # Narrowed shaft: 838-1063 = 225px (was 240px)
			{"x": 1063, "y": 350, "w": 20, "h": 250}
		],
		"grapple_anchors": [
			{"x": 1050, "y": 300}  # Optional bypass for skilled players
		],
		"checkpoints": [
			{"x": 350, "y": 430, "rect": Rect2(300, 400, 100, 100), "layer": "surface"},
			{"x": 940, "y": 520, "rect": Rect2(890, 480, 100, 100), "layer": "underground", "heal_ratio": 0.75},  # Underground reward checkpoint
			{"x": 1620, "y": 280, "rect": Rect2(1570, 250, 100, 100), "layer": "surface"},
			{"x": 2900, "y": 430, "rect": Rect2(2850, 400, 100, 100), "layer": "surface"}
		],
		"goal_rect": Rect2(3550, 340, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 250, "y_max": 580, "type": "ground"},
			{"id": "platform", "y_min": 178, "y_max": 378, "type": "platform"},
			{"id": "underground", "y_min": 480, "y_max": 580, "type": "cave"}
		],
		"segments": [
			{"x_min": 0, "x_max": 550, "spawn_zones": [{"x_min": 180, "x_max": 480, "y_min": 405, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 560, "x_max": 1140, "spawn_zones": [
				{"x_min": 720, "x_max": 1080, "y_min": 355, "y_max": 445, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 570},
				# Underground pocket - low density "reward" feel
				{"x_min": 850, "x_max": 1050, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["complainer"], "density": 0.35, "max_concurrent": 2, "trigger_x": 845},
				{"x_min": 1160, "x_max": 1210, "y_min": 223, "y_max": 255, "layer": "platform", "pool": ["complainer"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1150}
			]},
			# Post-wall-jump: 60px breather (1180-1240), then combat
			{"x_min": 1180, "x_max": 2080, "spawn_zones": [{"x_min": 1260, "x_max": 1980, "y_min": 255, "y_max": 345, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1240}]},
			# Sprint finale: varied density - sprint zone (2200-2600), then combat (2650-3450)
			{"x_min": 2080, "x_max": 3600, "spawn_zones": [
				{"x_min": 2200, "x_max": 2580, "y_min": 405, "y_max": 495, "layer": "surface", "pool": ["complainer"], "density": 0.5, "max_concurrent": 3, "trigger_x": 2100},
				{"x_min": 2650, "x_max": 3450, "y_min": 405, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2620}
			]}
		],
		"decor": [
			{"x": 820, "y": 370, "type": "wall_jump_hint"},
			{"x": 1050, "y": 280, "type": "grapple_anchor_hint"},
			{"x": 940, "y": 500, "type": "safe_zone"},
			{"x": 2400, "y": 420, "type": "sprint_stretch"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_3() -> Dictionary:
	# Elite Cave: DROP-THROUGH layering, BLOCK GAUNTLET, bomber clusters with rhythm, "must block" eureka moments
	return {
		"id": 3,
		"name": "Below",
		"width": 4200,
		"height": 720,
		"theme": "cave",
		"bg_texture_path": "",
		"floor_segments": [
			{"x_min": 0, "x_max": 620, "y_min": 300, "y_max": 420},
			{"x_min": 745, "x_max": 1400, "y_min": 320, "y_max": 440},
			{"x_min": 1520, "x_max": 2180, "y_min": 480, "y_max": 580},  # Deep bomber cave
			{"x_min": 2320, "x_max": 2880, "y_min": 420, "y_max": 540},  # Block gauntlet zone
			{"x_min": 3020, "x_max": 4200, "y_min": 300, "y_max": 420}
		],
		"platforms": [
			# Upper/lower path with drop-through
			{"x": 665, "y": 268, "w": 70, "h": 22, "drop_through": true},
			{"x": 665, "y": 328, "w": 70, "h": 22, "drop_through": true},
			{"x": 755, "y": 418, "w": 180, "h": 22, "drop_through": true},
			# Platform before underground descent
			{"x": 1390, "y": 458, "w": 100, "h": 22, "drop_through": true},
			# Underground exit platforms - upper path (must approach from below)
			{"x": 2190, "y": 348, "w": 100, "h": 22, "drop_through": true},  # Raised for below-approach bomber challenge
			{"x": 2190, "y": 398, "w": 100, "h": 22, "drop_through": true},
			# Block gauntlet platform
			{"x": 2520, "y": 398, "w": 80, "h": 22},
			{"x": 2890, "y": 398, "w": 100, "h": 22, "drop_through": true},
			# Final section upper path
			{"x": 3400, "y": 258, "w": 90, "h": 22, "drop_through": true}
		],
		"checkpoints": [
			{"x": 400, "y": 350, "rect": Rect2(350, 300, 100, 120), "layer": "surface"},
			{"x": 1180, "y": 360, "rect": Rect2(1130, 320, 100, 120), "layer": "surface"},
			{"x": 1900, "y": 520, "rect": Rect2(1850, 480, 100, 100), "layer": "underground"},
			{"x": 2680, "y": 460, "rect": Rect2(2630, 420, 100, 120), "layer": "surface"},
			{"x": 3600, "y": 350, "rect": Rect2(3550, 300, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4150, 240, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 300, "y_max": 580, "type": "ground"},
			{"id": "underground", "y_min": 480, "y_max": 580, "type": "cave"},
			{"id": "platform", "y_min": 258, "y_max": 458, "type": "platform"}
		],
		"segments": [
			{"x_min": 0, "x_max": 650, "spawn_zones": [{"x_min": 200, "x_max": 550, "y_min": 305, "y_max": 415, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 150}]},
			{"x_min": 680, "x_max": 1540, "spawn_zones": [{"x_min": 950, "x_max": 1320, "y_min": 325, "y_max": 435, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 900}]},
			# Underground bomber cluster - high density, must block
			{"x_min": 1550, "x_max": 2300, "spawn_zones": [
				{"x_min": 1650, "x_max": 2120, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["complainer", "bomber"], "density": 0.9, "max_concurrent": 6, "trigger_x": 1580},
				# Upper platform bombers - approach from below challenge
				{"x_min": 2195, "x_max": 2280, "y_min": 343, "y_max": 373, "layer": "platform", "pool": ["bomber"], "density": 0.8, "max_concurrent": 2, "trigger_x": 2180}
			]},
			# Block gauntlet corridor - bombers from behind and above (150px gauntlet: 2480-2630)
			{"x_min": 2350, "x_max": 2880, "spawn_zones": [
				{"x_min": 2480, "x_max": 2630, "y_min": 425, "y_max": 535, "layer": "surface", "pool": ["bomber"], "density": 0.95, "max_concurrent": 5, "trigger_x": 2430},
				{"x_min": 2680, "x_max": 2820, "y_min": 425, "y_max": 535, "layer": "surface", "pool": ["manager"], "density": 0.5, "max_concurrent": 3, "trigger_x": 2660}
			]},
			# Breather zone - low intensity single complainer (3020-3150)
			{"x_min": 3020, "x_max": 3180, "spawn_zones": [{"x_min": 3080, "x_max": 3150, "y_min": 305, "y_max": 415, "layer": "surface", "pool": ["complainer"], "density": 0.3, "max_concurrent": 1, "trigger_x": 3050}]},
			# Final mixed bomber/melee cluster
			{"x_min": 3200, "x_max": 4200, "spawn_zones": [{"x_min": 3280, "x_max": 4000, "y_min": 305, "y_max": 415, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3230}]}
		],
		"decor": [
			{"x": 650, "y": 290, "type": "drop_through_hint"},
			{"x": 1550, "y": 500, "type": "bomber_warning"},
			{"x": 2500, "y": 440, "type": "block_gauntlet"},
			{"x": 3100, "y": 330, "type": "breather_zone"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_4() -> Dictionary:
	# Elite Sky: Narrow SKYBRIDGE ribbon, AIR DASH gates (mandatory), GRAPPLE express shortcuts, stair-step ascent, tense high-wire combat
	return {
		"id": 4,
		"name": "High Wire",
		"width": 5000,
		"height": 720,
		"theme": "sky",
		"bg_texture_path": "",
		"floor_segments": [
			{"x_min": 0, "x_max": 520, "y_min": 420, "y_max": 520},
			{"x_min": 655, "x_max": 1300, "y_min": 380, "y_max": 480},
			{"x_min": 1465, "x_max": 1965, "y_min": 320, "y_max": 420},
			# Skybridge - narrowed into ribbon segments (was one 805px floor)
			{"x_min": 2075, "x_max": 2280, "y_min": 100, "y_max": 200},
			{"x_min": 2360, "x_max": 2580, "y_min": 100, "y_max": 200},
			{"x_min": 2660, "x_max": 2880, "y_min": 100, "y_max": 200},
			{"x_min": 3020, "x_max": 5000, "y_min": 400, "y_max": 500}
		],
		"platforms": [
			# Stair-step ascent to skybridge
			{"x": 535, "y": 398, "w": 100, "h": 22},
			{"x": 1305, "y": 338, "w": 140, "h": 22},
			{"x": 1620, "y": 278, "w": 90, "h": 22},  # Added stair-step
			{"x": 1780, "y": 218, "w": 80, "h": 22},  # Added stair-step
			# AIR DASH gate platform - IMPOSSIBLE without air dash or grapple (110px gap: 1965-2075)
			{"x": 1980, "y": 168, "w": 70, "h": 22},  # Final step before air dash gate
			# Skybridge ribbon platforms (narrow gaps)
			{"x": 2290, "y": 78, "w": 60, "h": 22},
			{"x": 2590, "y": 78, "w": 60, "h": 22},
			# Descent from skybridge
			{"x": 2895, "y": 378, "w": 120, "h": 22}
		],
		"grapple_anchors": [
			{"x": 1820, "y": 160},  # Express shortcut bypassing stair-step ascent (saves 3-4 sec)
			{"x": 2050, "y": 80},   # Bypass air dash gate alternative
			{"x": 2560, "y": 60},
			{"x": 2720, "y": 55},
			{"x": 4380, "y": 320}
		],
		"checkpoints": [
			{"x": 350, "y": 450, "rect": Rect2(300, 420, 100, 100), "layer": "surface"},
			{"x": 1050, "y": 410, "rect": Rect2(1000, 380, 100, 100), "layer": "surface"},
			{"x": 1720, "y": 350, "rect": Rect2(1670, 320, 100, 100), "layer": "surface"},
			{"x": 2680, "y": 150, "rect": Rect2(2630, 100, 100, 100), "layer": "skybridge"},
			{"x": 4200, "y": 430, "rect": Rect2(4150, 400, 100, 100), "layer": "surface"}
		],
		"goal_rect": Rect2(4950, 340, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 100, "y_max": 520, "type": "ground"},
			{"id": "platform", "y_min": 78, "y_max": 398, "type": "platform"},
			{"id": "skybridge", "y_min": 100, "y_max": 200, "type": "skybridge"}
		],
		"segments": [
			{"x_min": 0, "x_max": 550, "spawn_zones": [{"x_min": 150, "x_max": 450, "y_min": 425, "y_max": 515, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 570, "x_max": 1470, "spawn_zones": [
				{"x_min": 800, "x_max": 1250, "y_min": 385, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 760},
				{"x_min": 1330, "x_max": 1420, "y_min": 325, "y_max": 415, "layer": "platform", "pool": ["complainer"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1320}
			]},
			# Vertical climb section - stair-step rhythm
			{"x_min": 1500, "x_max": 2050, "spawn_zones": [
				{"x_min": 1630, "x_max": 1920, "y_min": 325, "y_max": 415, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1520},
				{"x_min": 1790, "x_max": 1860, "y_min": 213, "y_max": 243, "layer": "platform", "pool": ["manager"], "density": 0.6, "max_concurrent": 2, "trigger_x": 1780}
			]},
			# Skybridge - tense, fewer but stronger enemies (quality over quantity)
			{"x_min": 2075, "x_max": 3050, "spawn_zones": [
				{"x_min": 2140, "x_max": 2260, "y_min": 105, "y_max": 195, "layer": "skybridge", "pool": ["manager", "hoa"], "density": 0.65, "max_concurrent": 3, "trigger_x": 2100},
				{"x_min": 2380, "x_max": 2560, "y_min": 105, "y_max": 195, "layer": "skybridge", "pool": ["hoa"], "density": 0.7, "max_concurrent": 3, "trigger_x": 2370},
				{"x_min": 2680, "x_max": 2860, "y_min": 105, "y_max": 195, "layer": "skybridge", "pool": ["manager", "hoa"], "density": 0.7, "max_concurrent": 4, "trigger_x": 2670}
			]},
			{"x_min": 3100, "x_max": 5000, "spawn_zones": [{"x_min": 3250, "x_max": 4800, "y_min": 405, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3150}]}
		],
		"decor": [
			{"x": 1700, "y": 240, "type": "stair_step_marker"},
			{"x": 1980, "y": 150, "type": "air_dash_required"},
			{"x": 1820, "y": 140, "type": "grapple_shortcut"},
			{"x": 2400, "y": 120, "type": "skybridge_warning"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

static func _level_5() -> Dictionary:
	# Elite Summit Marathon: Multi-biome epic with BREATHER segments, micro-platform punctuation, grapple vs platform routes, MEGA-ONLY dramatic beat, escalating finale
	return {
		"id": 5,
		"name": "The Summit",
		"width": 8500,
		"height": 720,
		"theme": "summit",
		"bg_texture_path": "",
		"floor_segments": [
			{"x_min": 0, "x_max": 520, "y_min": 360, "y_max": 460},
			{"x_min": 680, "x_max": 1280, "y_min": 340, "y_max": 440},
			{"x_min": 1380, "x_max": 1980, "y_min": 320, "y_max": 420},
			{"x_min": 2100, "x_max": 2680, "y_min": 480, "y_max": 580},  # Cave biome
			{"x_min": 2780, "x_max": 3520, "y_min": 220, "y_max": 320},  # Post-cave elevated (breather zone start)
			{"x_min": 3558, "x_max": 3722, "y_min": 455, "y_max": 520},  # Wall-jump shaft bottom
			{"x_min": 3760, "x_max": 4200, "y_min": 340, "y_max": 440},
			{"x_min": 4300, "x_max": 4780, "y_min": 340, "y_max": 440},
			{"x_min": 4880, "x_max": 5480, "y_min": 100, "y_max": 200},  # Skybridge biome
			{"x_min": 5580, "x_max": 8500, "y_min": 340, "y_max": 440}   # Final gauntlet (2920px!)
		],
		"platforms": [
			{"x": 540, "y": 338, "w": 120, "h": 22},
			{"x": 1300, "y": 318, "w": 60, "h": 22},
			{"x": 2000, "y": 458, "w": 80, "h": 22},
			{"x": 2700, "y": 198, "w": 60, "h": 22},
			# Grapple route to skybridge (alternative to stair-step)
			{"x": 3200, "y": 178, "w": 70, "h": 22},
			{"x": 3400, "y": 318, "w": 60, "h": 22},
			{"x": 4800, "y": 278, "w": 60, "h": 22},
			{"x": 5500, "y": 78, "w": 60, "h": 22},
			# Final gauntlet micro-platforms for punctuation
			{"x": 6200, "y": 298, "w": 70, "h": 22},
			{"x": 6900, "y": 298, "w": 70, "h": 22},
			# MEGA-ONLY dramatic beat platform
			{"x": 7600, "y": 278, "w": 90, "h": 22}
		],
		"wall_segments": [
			{"x": 3538, "y": 150, "w": 18, "h": 320},
			{"x": 3740, "y": 150, "w": 18, "h": 320}
		],
		"grapple_anchors": [
			{"x": 3580, "y": 140},  # Wall-jump bypass
			{"x": 4620, "y": 280},  # Mid-section shortcut (new)
			{"x": 5150, "y": 50},   # Skybridge approach shortcut
			{"x": 7200, "y": 280}
		],
		"checkpoints": [
			{"x": 350, "y": 400, "rect": Rect2(300, 360, 100, 100), "layer": "surface"},
			{"x": 1000, "y": 380, "rect": Rect2(950, 340, 100, 100), "layer": "surface"},
			{"x": 1750, "y": 360, "rect": Rect2(1700, 320, 100, 100), "layer": "surface"},
			{"x": 2420, "y": 520, "rect": Rect2(2370, 480, 100, 100), "layer": "underground"},
			{"x": 3100, "y": 260, "rect": Rect2(3050, 220, 100, 100), "layer": "platform"},
			{"x": 3880, "y": 380, "rect": Rect2(3830, 340, 100, 100), "layer": "surface"},
			{"x": 4580, "y": 380, "rect": Rect2(4530, 340, 100, 100), "layer": "surface"},
			{"x": 5200, "y": 150, "rect": Rect2(5150, 100, 100, 100), "layer": "skybridge"},
			{"x": 6100, "y": 380, "rect": Rect2(6050, 340, 100, 100), "layer": "surface"},
			{"x": 7200, "y": 380, "rect": Rect2(7150, 340, 100, 100), "layer": "surface"}
		],
		"goal_rect": Rect2(8450, 280, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 100, "y_max": 580, "type": "ground"},
			{"id": "platform", "y_min": 78, "y_max": 338, "type": "platform"},
			{"id": "underground", "y_min": 480, "y_max": 580, "type": "cave"},
			{"id": "skybridge", "y_min": 100, "y_max": 200, "type": "skybridge"}
		],
		"segments": [
			{"x_min": 0, "x_max": 520, "spawn_zones": [{"x_min": 150, "x_max": 450, "y_min": 365, "y_max": 455, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 540, "x_max": 1380, "spawn_zones": [{"x_min": 700, "x_max": 1200, "y_min": 345, "y_max": 435, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.65, "max_concurrent": 5, "trigger_x": 560}]},
			{"x_min": 1380, "x_max": 2100, "spawn_zones": [{"x_min": 1510, "x_max": 1900, "y_min": 325, "y_max": 415, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1420}]},
			{"x_min": 2100, "x_max": 2780, "spawn_zones": [{"x_min": 2230, "x_max": 2600, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2150}]},
			# Post-cave BREATHER segment (2780-2900 = 120px low density)
			{"x_min": 2780, "x_max": 3480, "spawn_zones": [
				{"x_min": 2780, "x_max": 2900, "y_min": 225, "y_max": 315, "layer": "platform", "pool": ["complainer"], "density": 0.35, "max_concurrent": 2, "trigger_x": 2770},
				{"x_min": 2920, "x_max": 3300, "y_min": 225, "y_max": 315, "layer": "platform", "pool": ["complainer", "manager", "witch"], "density": 0.75, "max_concurrent": 5, "trigger_x": 2910}
			]},
			{"x_min": 3480, "x_max": 4300, "spawn_zones": [{"x_min": 3610, "x_max": 4120, "y_min": 345, "y_max": 435, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3530}]},
			{"x_min": 4300, "x_max": 4880, "spawn_zones": [{"x_min": 4430, "x_max": 4700, "y_min": 345, "y_max": 435, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 6, "trigger_x": 4350}]},
			{"x_min": 4880, "x_max": 5580, "spawn_zones": [{"x_min": 5010, "x_max": 5400, "y_min": 105, "y_max": 195, "layer": "skybridge", "pool": ["manager", "hoa", "witch"], "density": 0.9, "max_concurrent": 5, "trigger_x": 4930}]},
			# Final gauntlet with micro-platform punctuation and escalation
			{"x_min": 5580, "x_max": 8450, "spawn_zones": [
				{"x_min": 5710, "x_max": 6800, "y_min": 345, "y_max": 435, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "mega"], "density": 0.9, "max_concurrent": 7, "trigger_x": 5630},
				# Micro-platform zones for rhythm
				{"x_min": 6210, "x_max": 6280, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["manager", "witch"], "density": 0.7, "max_concurrent": 3, "trigger_x": 6200},
				{"x_min": 6910, "x_max": 6980, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["hoa", "witch"], "density": 0.75, "max_concurrent": 3, "trigger_x": 6900},
				# MEGA-ONLY dramatic beat
				{"x_min": 7605, "x_max": 7685, "y_min": 273, "y_max": 303, "layer": "platform", "pool": ["mega"], "density": 1.0, "max_concurrent": 2, "trigger_x": 7590},
				# Final 800px escalation
				{"x_min": 7700, "x_max": 8300, "y_min": 345, "y_max": 435, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "mega", "witch"], "density": 0.95, "max_concurrent": 8, "trigger_x": 7680}
			]}
		],
		"decor": [
			{"x": 2680, "y": 500, "type": "cave_exit"},
			{"x": 2850, "y": 240, "type": "breather_zone"},
			{"x": 3640, "y": 470, "type": "wall_jump_shaft"},
			{"x": 4900, "y": 120, "type": "skybridge_transition"},
			{"x": 5600, "y": 360, "type": "final_gauntlet_start"},
			{"x": 7600, "y": 260, "type": "mega_boss_platform"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 6: Ambush Alley --- Elite Chase: SPRINT+DASH gaps (mandatory), narrow escape platforms, checkpoint IN danger, escalating pursuit
static func _level_6() -> Dictionary:
	return {
		"id": 6,
		"name": "Ambush Alley",
		"width": 3800,
		"height": 720,
		"theme": "cave",
		"floor_segments": [
			{"x_min": 0, "x_max": 690, "y_min": 340, "y_max": 460},
			{"x_min": 840, "x_max": 1740, "y_min": 340, "y_max": 460},  # Gap 1: 150px (690-840) - SPRINT+DASH required
			{"x_min": 1890, "x_max": 2790, "y_min": 340, "y_max": 460},  # Gap 2: 150px (1740-1890)
			{"x_min": 2940, "x_max": 3800, "y_min": 340, "y_max": 460}   # Gap 3: 150px (2790-2940)
		],
		"platforms": [
			# Narrow escape platforms (60-70px) between ambush zones
			{"x": 720, "y": 318, "w": 70, "h": 22},  # First narrow escape (was 90px)
			{"x": 1775, "y": 318, "w": 65, "h": 22}, # Second narrow escape (was 90px)
			{"x": 2820, "y": 318, "w": 70, "h": 22}  # Third narrow escape (was 100px)
		],
		"checkpoints": [
			{"x": 450, "y": 380, "rect": Rect2(400, 340, 100, 120), "layer": "surface"},
			{"x": 1580, "y": 380, "rect": Rect2(1530, 340, 100, 120), "layer": "surface"},  # MOVED into ambush zone - respawn in danger!
			{"x": 2480, "y": 380, "rect": Rect2(2430, 340, 100, 120), "layer": "surface"}   # Also in ambush zone
		],
		"goal_rect": Rect2(3750, 280, 50, 220),
		"layers": [{"id": "surface", "y_min": 318, "y_max": 460, "type": "ground"}, {"id": "platform", "y_min": 298, "y_max": 340, "type": "platform"}],
		"segments": [
			# Segment 1: Low threat intro
			{"x_min": 0, "x_max": 690, "spawn_zones": [{"x_min": 200, "x_max": 620, "y_min": 345, "y_max": 455, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.5, "max_concurrent": 4, "trigger_x": 120}]},
			{"x_min": 720, "x_max": 840, "spawn_zones": [{"x_min": 725, "x_max": 780, "y_min": 312, "y_max": 335, "layer": "platform", "pool": ["complainer"], "density": 0.3, "max_concurrent": 1, "trigger_x": 715}]},
			# Segment 2: High threat - staggered ambush (trigger earlier for anticipation)
			{"x_min": 840, "x_max": 1775, "spawn_zones": [{"x_min": 900, "x_max": 1680, "y_min": 345, "y_max": 455, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.75, "max_concurrent": 5, "trigger_x": 780, "ambush": true}]},
			{"x_min": 1775, "x_max": 1890, "spawn_zones": [{"x_min": 1780, "x_max": 1830, "y_min": 312, "y_max": 335, "layer": "platform", "pool": ["complainer"], "density": 0.3, "max_concurrent": 1, "trigger_x": 1770}]},
			# Segment 3: Harder threat - earlier trigger for "they're everywhere"
			{"x_min": 1890, "x_max": 2820, "spawn_zones": [{"x_min": 1980, "x_max": 2720, "y_min": 345, "y_max": 455, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 6, "trigger_x": 1840, "ambush": true}]},
			{"x_min": 2820, "x_max": 2940, "spawn_zones": [{"x_min": 2825, "x_max": 2880, "y_min": 312, "y_max": 335, "layer": "platform", "pool": ["manager"], "density": 0.4, "max_concurrent": 2, "trigger_x": 2815}]},
			# Segment 4: HARDEST - final stand before goal
			{"x_min": 2940, "x_max": 3800, "spawn_zones": [{"x_min": 3050, "x_max": 3680, "y_min": 345, "y_max": 455, "layer": "surface", "pool": ["manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 2900, "ambush": true}]}
		],
		"decor": [
			{"x": 700, "y": 340, "type": "sprint_dash_required"},
			{"x": 900, "y": 360, "type": "ambush_warning"},
			{"x": 1900, "y": 360, "type": "chase_intensifies"},
			{"x": 3000, "y": 360, "type": "last_stand"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 7: Gold Rush --- Elite Speed-Reward: SPRINT to gold zone, multi-path platforming, high/low risk routes, grapple express lane
static func _level_7() -> Dictionary:
	return {
		"id": 7,
		"name": "Gold Rush",
		"width": 4000,
		"height": 720,
		"theme": "grass",
		"floor_segments": [
			{"x_min": 0, "x_max": 920, "y_min": 350, "y_max": 470},
			{"x_min": 1045, "x_max": 2520, "y_min": 350, "y_max": 470},  # Gold zone extended by 40px
			{"x_min": 2600, "x_max": 4000, "y_min": 350, "y_max": 470}
		],
		"platforms": [
			# Entry dash platform
			{"x": 938, "y": 328, "w": 90, "h": 22},
			# Gold zone route variety - high path vs low path
			{"x": 1280, "y": 308, "w": 80, "h": 22},   # High path option 1
			{"x": 1580, "y": 288, "w": 75, "h": 22},   # High path option 2
			# RISKY narrow platform - standing yields more kills but dangerous
			{"x": 1860, "y": 310, "w": 60, "h": 22},   # Narrow risky platform
			{"x": 2180, "y": 308, "w": 80, "h": 22},   # High path option 3
			{"x": 2450, "y": 328, "w": 70, "h": 22}    # Exit transition platform
		],
		"grapple_anchors": [
			{"x": 960, "y": 280},  # Express grapple to skip to gold zone entry (saves 2-3 sec)
			{"x": 1900, "y": 260}  # Mid-gold-zone grapple for advanced routing
		],
		"checkpoints": [
			{"x": 550, "y": 390, "rect": Rect2(500, 350, 100, 120), "layer": "surface"},
			{"x": 1800, "y": 390, "rect": Rect2(1750, 350, 100, 120), "layer": "surface"},  # In gold zone - checkpoint feels earned
			{"x": 3300, "y": 390, "rect": Rect2(3250, 350, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(3950, 290, 50, 220),
		"layers": [{"id": "surface", "y_min": 288, "y_max": 470, "type": "ground"}, {"id": "platform", "y_min": 268, "y_max": 350, "type": "platform"}],
		"segments": [
			{"x_min": 0, "x_max": 920, "spawn_zones": [{"x_min": 200, "x_max": 840, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.6, "max_concurrent": 5, "trigger_x": 150}]},
			# Anticipation zone - empty sprint stretch (920-1045 = 125px)
			{"x_min": 938, "x_max": 1060, "spawn_zones": [{"x_min": 942, "x_max": 1018, "y_min": 322, "y_max": 345, "layer": "platform", "pool": ["complainer"], "density": 0.25, "max_concurrent": 1, "trigger_x": 930}]},
			# GOLD ZONE - multi-path with high/low routes
			{"x_min": 1045, "x_max": 2520, "spawn_zones": [
				{"x_min": 1150, "x_max": 2420, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.75, "max_concurrent": 6, "trigger_x": 1055, "gold_multiplier": 1.5},
				# High path platform spawns
				{"x_min": 1290, "x_max": 1350, "y_min": 303, "y_max": 333, "layer": "platform", "pool": ["manager"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1280, "gold_multiplier": 1.5},
				{"x_min": 1590, "x_max": 1650, "y_min": 283, "y_max": 313, "layer": "platform", "pool": ["manager"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1580, "gold_multiplier": 1.5},
				# Risky narrow platform - higher density for more gold but more danger
				{"x_min": 1865, "x_max": 1915, "y_min": 305, "y_max": 335, "layer": "platform", "pool": ["manager", "bomber"], "density": 0.85, "max_concurrent": 3, "trigger_x": 1860, "gold_multiplier": 1.5},
				{"x_min": 2190, "x_max": 2260, "y_min": 303, "y_max": 333, "layer": "platform", "pool": ["manager"], "density": 0.5, "max_concurrent": 2, "trigger_x": 2180, "gold_multiplier": 1.5}
			]},
			{"x_min": 2600, "x_max": 4000, "spawn_zones": [{"x_min": 2720, "x_max": 3880, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "hoa", "bomber"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2610}]}
		],
		"decor": [
			{"x": 1000, "y": 350, "type": "sprint_zone"},
			{"x": 1150, "y": 370, "type": "gold_zone_entry"},
			{"x": 1860, "y": 290, "type": "high_risk_high_reward"},
			{"x": 2500, "y": 370, "type": "gold_zone_exit"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 8: Safe Havens --- Elite Oasis: Full heals, visible checkpoint approaches, varied safe haven geometry, optional high-risk bonus platform
static func _level_8() -> Dictionary:
	return {
		"id": 8,
		"name": "Safe Havens",
		"width": 4600,
		"height": 720,
		"theme": "sky",
		"floor_segments": [
			{"x_min": 0, "x_max": 680, "y_min": 380, "y_max": 500},
			{"x_min": 810, "x_max": 1450, "y_min": 360, "y_max": 480},
			{"x_min": 810, "x_max": 1100, "y_min": 220, "y_max": 300},
			{"x_min": 1580, "x_max": 2350, "y_min": 380, "y_max": 500},
			{"x_min": 2480, "x_max": 3280, "y_min": 380, "y_max": 500},
			{"x_min": 3410, "x_max": 4600, "y_min": 380, "y_max": 500}
		],
		"platforms": [
			{"x": 700, "y": 358, "w": 90, "h": 22},
			{"x": 1120, "y": 198, "w": 120, "h": 22},
			# Optional HIGH BONUS platform - requires double-jump + air dash
			{"x": 1500, "y": 160, "w": 80, "h": 22},
			{"x": 1470, "y": 358, "w": 90, "h": 22},
			{"x": 2380, "y": 358, "w": 80, "h": 22},
			{"x": 3310, "y": 358, "w": 80, "h": 22}
		],
		"grapple_anchors": [
			{"x": 1200, "y": 150},
			{"x": 1520, "y": 120},  # Grapple to reach high bonus platform
			{"x": 2900, "y": 300}
		],
		"checkpoints": [
			{"x": 450, "y": 420, "rect": Rect2(400, 380, 100, 120), "layer": "surface", "heal_ratio": 1.0},          # Ground level haven
			{"x": 1150, "y": 250, "rect": Rect2(1100, 220, 100, 100), "layer": "platform", "heal_ratio": 1.0},        # Platform haven (after grapple)
			{"x": 2000, "y": 420, "rect": Rect2(1950, 380, 100, 120), "layer": "surface", "heal_ratio": 1.0},         # Ground level haven
			{"x": 2900, "y": 420, "rect": Rect2(2850, 380, 100, 120), "layer": "surface", "heal_ratio": 1.0},         # Ground level haven (post-bridge)
			{"x": 4100, "y": 420, "rect": Rect2(4050, 380, 100, 120), "layer": "surface", "heal_ratio": 1.0}          # Ground level haven (final)
		],
		"goal_rect": Rect2(4550, 320, 50, 220),
		"layers": [{"id": "surface", "y_min": 160, "y_max": 500, "type": "ground"}, {"id": "platform", "y_min": 140, "y_max": 380, "type": "platform"}],
		"segments": [
			# Segment 1: Combat zone, then 80px approach to checkpoint 1 (400-450)
			{"x_min": 0, "x_max": 700, "spawn_zones": [{"x_min": 200, "x_max": 370, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.65, "max_concurrent": 5, "trigger_x": 150}]},
			{"x_min": 700, "x_max": 900, "spawn_zones": [{"x_min": 705, "x_max": 785, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["complainer"], "density": 0.4, "max_concurrent": 1, "trigger_x": 695}]},
			# Segment 2-3: Combat zone, 50px approach to checkpoint 2 (1100-1150)
			{"x_min": 810, "x_max": 1580, "spawn_zones": [
				{"x_min": 850, "x_max": 1050, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 820},
				# Platform checkpoint visible from below - no spawns blocking view
				# High bonus platform zone - risky
				{"x_min": 1505, "x_max": 1575, "y_min": 155, "y_max": 185, "layer": "platform", "pool": ["witch", "hoa"], "density": 0.8, "max_concurrent": 2, "trigger_x": 1500}
			]},
			{"x_min": 1470, "x_max": 1560, "spawn_zones": [{"x_min": 1475, "x_max": 1550, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["complainer"], "density": 0.3, "max_concurrent": 1, "trigger_x": 1465}]},
			# Segment 4: Combat zone, 50px approach to checkpoint 3 (1950-2000)
			{"x_min": 1580, "x_max": 2480, "spawn_zones": [{"x_min": 1700, "x_max": 1900, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 1590}]},
			{"x_min": 2380, "x_max": 2470, "spawn_zones": [{"x_min": 2385, "x_max": 2450, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["manager"], "density": 0.4, "max_concurrent": 2, "trigger_x": 2375}]},
			# Segment 5: Combat zone, 50px approach to checkpoint 4 (2850-2900)
			{"x_min": 2480, "x_max": 3410, "spawn_zones": [{"x_min": 2600, "x_max": 2800, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2490}]},
			{"x_min": 3310, "x_max": 3400, "spawn_zones": [{"x_min": 3315, "x_max": 3385, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["manager"], "density": 0.4, "max_concurrent": 2, "trigger_x": 3305}]},
			# Segment 6: Combat zone, 50px approach to checkpoint 5 (4050-4100)
			{"x_min": 3410, "x_max": 4600, "spawn_zones": [{"x_min": 3550, "x_max": 4000, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch"], "density": 0.85, "max_concurrent": 7, "trigger_x": 3420}]}
		],
		"decor": [
			{"x": 420, "y": 400, "type": "safe_haven_1"},
			{"x": 1130, "y": 230, "type": "safe_haven_2_platform"},
			{"x": 1500, "y": 140, "type": "high_risk_bonus"},
			{"x": 1980, "y": 400, "type": "safe_haven_3"},
			{"x": 2880, "y": 400, "type": "safe_haven_4"},
			{"x": 4080, "y": 400, "type": "safe_haven_5"}
		],
		"respawn_hp_ratio": 0.6,
		"respawn_gold_penalty_ratio": 0.12,
		"max_waves": 1
	}

# --- Level 9: The Long March --- Elite Endurance: 5 distinct chapters, grapple vs platform routing, cruel middle stretch, calm breather at x=3200
static func _level_9() -> Dictionary:
	return {
		"id": 9,
		"name": "The Long March",
		"width": 6000,
		"height": 720,
		"theme": "cave",
		"floor_segments": [
			# Chapter 1: Cave entrance (0-1200)
			{"x_min": 0, "x_max": 580, "y_min": 380, "y_max": 500},
			{"x_min": 740, "x_max": 1180, "y_min": 360, "y_max": 480},
			# Chapter 2: Narrow shaft (740-1340) - vertical signature
			{"x_min": 740, "x_max": 980, "y_min": 230, "y_max": 310},
			# Chapter 2-3 transition: Open cavern (1340-2400)
			{"x_min": 1340, "x_max": 2220, "y_min": 380, "y_max": 500},
			# Chapter 3: Cruel stretch (2400-3600) - fewer checkpoints
			{"x_min": 2400, "x_max": 3280, "y_min": 380, "y_max": 500},
			{"x_min": 2400, "x_max": 2680, "y_min": 240, "y_max": 320},
			# Chapter 4: Climb out (3460-4520) - ascent signature
			{"x_min": 3460, "x_max": 4340, "y_min": 380, "y_max": 500},
			# Chapter 5: Final sprint (4520-6000)
			{"x_min": 4520, "x_max": 6000, "y_min": 380, "y_max": 500}
		],
		"platforms": [
			{"x": 600, "y": 358, "w": 120, "h": 22},
			{"x": 1010, "y": 218, "w": 80, "h": 22},
			{"x": 1200, "y": 358, "w": 110, "h": 22},
			{"x": 2310, "y": 358, "w": 70, "h": 22},
			{"x": 2720, "y": 228, "w": 100, "h": 22},
			{"x": 3310, "y": 358, "w": 130, "h": 22},
			{"x": 4370, "y": 358, "w": 120, "h": 22}
		],
		"grapple_anchors": [
			{"x": 1100, "y": 170},  # Chapter 1→2 grapple shortcut
			{"x": 2050, "y": 300},  # Chapter 2 mid-cavern shortcut (new)
			{"x": 2550, "y": 190},  # Chapter 3 entry grapple
			{"x": 3380, "y": 280},  # Chapter 3→4 grapple (new, every 800-1000px)
			{"x": 4000, "y": 290},  # Chapter 4 grapple
			{"x": 5200, "y": 300}   # Chapter 5 sprint grapple (new)
		],
		"checkpoints": [
			{"x": 350, "y": 420, "rect": Rect2(300, 380, 100, 120), "layer": "surface"},       # Chapter 1
			{"x": 1050, "y": 260, "rect": Rect2(1000, 230, 100, 100), "layer": "platform"},    # Chapter 2 (narrow shaft)
			{"x": 1800, "y": 420, "rect": Rect2(1750, 380, 100, 120), "layer": "surface"},     # Chapter 2-3 transition
			{"x": 2880, "y": 420, "rect": Rect2(2830, 380, 100, 120), "layer": "surface"},     # Chapter 3 (cruel stretch)
			{"x": 3950, "y": 420, "rect": Rect2(3900, 380, 100, 120), "layer": "surface"},     # Chapter 4 (climb out)
			{"x": 5000, "y": 420, "rect": Rect2(4950, 380, 100, 120), "layer": "surface"}      # Chapter 5 (final sprint)
		],
		"goal_rect": Rect2(5950, 320, 50, 220),
		"layers": [{"id": "surface", "y_min": 218, "y_max": 500, "type": "ground"}, {"id": "platform", "y_min": 196, "y_max": 380, "type": "platform"}],
		"segments": [
			# CHAPTER 1: Cave entrance (0-1200)
			{"x_min": 0, "x_max": 600, "spawn_zones": [{"x_min": 150, "x_max": 520, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.5, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 600, "x_max": 740, "spawn_zones": [{"x_min": 605, "x_max": 715, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["complainer"], "density": 0.35, "max_concurrent": 1, "trigger_x": 595}]},
			# CHAPTER 2: Narrow shaft (740-1340) - vertical geometry
			{"x_min": 740, "x_max": 1340, "spawn_zones": [
				{"x_min": 800, "x_max": 1130, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.6, "max_concurrent": 5, "trigger_x": 750},
				{"x_min": 1030, "x_max": 1085, "y_min": 223, "y_max": 255, "layer": "platform", "pool": ["complainer", "witch"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1020}
			]},
			{"x_min": 1200, "x_max": 1290, "spawn_zones": [{"x_min": 1205, "x_max": 1275, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["manager"], "density": 0.35, "max_concurrent": 1, "trigger_x": 1195}]},
			# CHAPTER 2-3: Open cavern (1340-2400)
			{"x_min": 1340, "x_max": 2400, "spawn_zones": [{"x_min": 1450, "x_max": 2310, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.65, "max_concurrent": 6, "trigger_x": 1350}]},
			{"x_min": 2310, "x_max": 2400, "spawn_zones": [{"x_min": 2315, "x_max": 2375, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["complainer"], "density": 0.35, "max_concurrent": 1, "trigger_x": 2305}]},
			# CHAPTER 3: CRUEL STRETCH (2400-3600) - higher density, fewer checkpoints
			{"x_min": 2400, "x_max": 3460, "spawn_zones": [
				# First half of cruel stretch - high intensity
				{"x_min": 2520, "x_max": 3180, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 2410},
				{"x_min": 2745, "x_max": 2815, "y_min": 233, "y_max": 265, "layer": "platform", "pool": ["witch"], "density": 0.45, "max_concurrent": 1, "trigger_x": 2735},
				# CALM BREATHER ZONE (3200-3500) - 300px respite
				{"x_min": 3200, "x_max": 3500, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer"], "density": 0.35, "max_concurrent": 3, "trigger_x": 3190}
			]},
			{"x_min": 3310, "x_max": 3400, "spawn_zones": [{"x_min": 3315, "x_max": 3385, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["manager"], "density": 0.35, "max_concurrent": 2, "trigger_x": 3305}]},
			# CHAPTER 4: Climb out (3460-4520) - escalation after breather
			{"x_min": 3460, "x_max": 4520, "spawn_zones": [{"x_min": 3580, "x_max": 4250, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch"], "density": 0.75, "max_concurrent": 7, "trigger_x": 3470}]},
			{"x_min": 4370, "x_max": 4460, "spawn_zones": [{"x_min": 4375, "x_max": 4445, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["hoa"], "density": 0.35, "max_concurrent": 1, "trigger_x": 4365}]},
			# CHAPTER 5: Final sprint (4520-6000) - marathon finish
			{"x_min": 4520, "x_max": 6000, "spawn_zones": [{"x_min": 4650, "x_max": 5880, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["manager", "hoa", "mega"], "density": 0.85, "max_concurrent": 7, "trigger_x": 4530}]}
		],
		"decor": [
			{"x": 600, "y": 370, "type": "chapter_1_cave_entrance"},
			{"x": 900, "y": 240, "type": "chapter_2_narrow_shaft"},
			{"x": 1600, "y": 400, "type": "chapter_3_open_cavern"},
			{"x": 3300, "y": 400, "type": "calm_breather"},
			{"x": 3800, "y": 400, "type": "chapter_4_climb_out"},
			{"x": 5200, "y": 400, "type": "chapter_5_final_sprint"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.2,
		"max_waves": 1
	}

# --- Level 10: Elite Invasion --- Elite Combat Showcase: Sniper perch, block corridor, sequential elite introduction, platform combat
static func _level_10() -> Dictionary:
	return {
		"id": 10,
		"name": "Elite Invasion",
		"width": 4400,
		"height": 720,
		"theme": "summit",
		"floor_segments": [
			{"x_min": 0, "x_max": 620, "y_min": 360, "y_max": 480},
			{"x_min": 770, "x_max": 1580, "y_min": 360, "y_max": 480},
			{"x_min": 770, "x_max": 1100, "y_min": 240, "y_max": 320},
			{"x_min": 1700, "x_max": 2700, "y_min": 360, "y_max": 480},
			{"x_min": 2840, "x_max": 3820, "y_min": 360, "y_max": 480},
			{"x_min": 3960, "x_max": 4400, "y_min": 360, "y_max": 480}
		],
		"platforms": [
			{"x": 640, "y": 338, "w": 110, "h": 22},
			{"x": 1120, "y": 218, "w": 100, "h": 22},
			{"x": 1610, "y": 338, "w": 70, "h": 22},
			# SNIPER PERCH - high platform with witch/HOA, must block or climb to clear
			{"x": 1900, "y": 178, "w": 100, "h": 22},
			# Platform-heavy section - fighting "above" main floor
			{"x": 2080, "y": 298, "w": 90, "h": 22},
			{"x": 2300, "y": 258, "w": 85, "h": 22},
			{"x": 2730, "y": 338, "w": 90, "h": 22},
			{"x": 3850, "y": 338, "w": 90, "h": 22}
		],
		"grapple_anchors": [
			{"x": 1200, "y": 180},
			{"x": 1920, "y": 140},  # Grapple to sniper perch
			{"x": 2400, "y": 280}
		],
		"checkpoints": [
			{"x": 350, "y": 400, "rect": Rect2(300, 360, 100, 120), "layer": "surface"},
			{"x": 1200, "y": 270, "rect": Rect2(1150, 240, 100, 100), "layer": "platform"},
			{"x": 2200, "y": 400, "rect": Rect2(2150, 360, 100, 120), "layer": "surface"},
			{"x": 3300, "y": 400, "rect": Rect2(3250, 360, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4350, 320, 50, 220),
		"layers": [{"id": "surface", "y_min": 178, "y_max": 480, "type": "ground"}, {"id": "platform", "y_min": 158, "y_max": 358, "type": "platform"}],
		"segments": [
			# Segment 1: Manager only introduction
			{"x_min": 0, "x_max": 640, "spawn_zones": [{"x_min": 200, "x_max": 560, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager"], "density": 0.55, "max_concurrent": 4, "trigger_x": 150}]},
			{"x_min": 640, "x_max": 770, "spawn_zones": [{"x_min": 645, "x_max": 740, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["manager"], "density": 0.4, "max_concurrent": 2, "trigger_x": 635}]},
			# Segment 2: Add HOA
			{"x_min": 770, "x_max": 1700, "spawn_zones": [
				{"x_min": 830, "x_max": 1520, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "hoa"], "density": 0.65, "max_concurrent": 5, "trigger_x": 780},
				{"x_min": 1145, "x_max": 1215, "y_min": 223, "y_max": 255, "layer": "platform", "pool": ["hoa"], "density": 0.55, "max_concurrent": 2, "trigger_x": 1135}
			]},
			{"x_min": 1610, "x_max": 1700, "spawn_zones": [{"x_min": 1615, "x_max": 1675, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["hoa"], "density": 0.4, "max_concurrent": 1, "trigger_x": 1605}]},
			# Segment 3: Add bomber + SNIPER PERCH + BLOCK CORRIDOR
			{"x_min": 1700, "x_max": 2840, "spawn_zones": [
				# Lower path - harder without blocking
				{"x_min": 1820, "x_max": 2180, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "hoa", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 1710},
				# SNIPER PERCH - witch/HOA from above, must block or climb
				{"x_min": 1905, "x_max": 1990, "y_min": 173, "y_max": 203, "layer": "platform", "pool": ["witch", "hoa"], "density": 0.8, "max_concurrent": 3, "trigger_x": 1900},
				# Platform-heavy section (2080-2380) - fighting above
				{"x_min": 2085, "x_max": 2170, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["hoa", "bomber"], "density": 0.65, "max_concurrent": 2, "trigger_x": 2080},
				{"x_min": 2305, "x_max": 2380, "y_min": 253, "y_max": 283, "layer": "platform", "pool": ["hoa", "bomber"], "density": 0.65, "max_concurrent": 2, "trigger_x": 2300},
				# BLOCK CORRIDOR (2200-2350) - projectiles from both sides
				{"x_min": 2200, "x_max": 2350, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["bomber", "witch"], "density": 0.9, "max_concurrent": 5, "trigger_x": 2190},
				# Post-corridor to segment end
				{"x_min": 2380, "x_max": 2640, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "hoa", "bomber"], "density": 0.75, "max_concurrent": 6, "trigger_x": 2370}
			]},
			{"x_min": 2730, "x_max": 2820, "spawn_zones": [{"x_min": 2735, "x_max": 2815, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["hoa"], "density": 0.4, "max_concurrent": 2, "trigger_x": 2725}]},
			# Segment 4: Add witch
			{"x_min": 2840, "x_max": 3960, "spawn_zones": [{"x_min": 2960, "x_max": 3880, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "hoa", "bomber", "witch"], "density": 0.8, "max_concurrent": 6, "trigger_x": 2850}]},
			{"x_min": 3850, "x_max": 3940, "spawn_zones": [{"x_min": 3855, "x_max": 3935, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["witch"], "density": 0.4, "max_concurrent": 1, "trigger_x": 3845}]},
			# Segment 5: ALL ELITES finale
			{"x_min": 3960, "x_max": 4400, "spawn_zones": [{"x_min": 4080, "x_max": 4300, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "hoa", "mega", "witch", "bomber"], "density": 0.85, "max_concurrent": 6, "trigger_x": 3970}]}
		],
		"decor": [
			{"x": 350, "y": 380, "type": "manager_introduction"},
			{"x": 900, "y": 380, "type": "hoa_enters"},
			{"x": 1900, "y": 160, "type": "sniper_perch"},
			{"x": 2270, "y": 380, "type": "block_corridor"},
			{"x": 3000, "y": 380, "type": "witch_introduction"},
			{"x": 4100, "y": 380, "type": "all_elites"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 11: Underground Gauntlet --- Elite Claustrophobia: Vertical descent shaft, squeeze sections, bomber/melee rhythm, dramatic drop
static func _level_11() -> Dictionary:
	return {
		"id": 11,
		"name": "Underground Gauntlet",
		"width": 4000,
		"height": 720,
		"theme": "cave",
		"floor_segments": [
			{"x_min": 0, "x_max": 480, "y_min": 320, "y_max": 440},
			{"x_min": 610, "x_max": 1080, "y_min": 480, "y_max": 580},
			# SQUEEZE section - narrower for pressure (1400-1800 = 400px)
			{"x_min": 1400, "x_max": 1800, "y_min": 480, "y_max": 580},
			{"x_min": 2100, "x_max": 2880, "y_min": 480, "y_max": 580},
			{"x_min": 3000, "x_max": 4000, "y_min": 480, "y_max": 580}
		],
		"platforms": [
			# Dramatic drop - wider pit (480-610 = 130px) with descent platforms
			{"x": 500, "y": 458, "w": 90, "h": 22, "drop_through": true},
			# VERTICAL DESCENT SHAFT - drop-through platforms forcing descent through bomber fire
			{"x": 520, "y": 418, "w": 70, "h": 22, "drop_through": true},
			{"x": 540, "y": 378, "w": 70, "h": 22, "drop_through": true},
			{"x": 1100, "y": 458, "w": 80, "h": 22, "drop_through": true},
			# Squeeze section entry/exit
			{"x": 1320, "y": 458, "w": 70, "h": 22, "drop_through": true},
			{"x": 1890, "y": 458, "w": 70, "h": 22, "drop_through": true},
			{"x": 2010, "y": 458, "w": 70, "h": 22, "drop_through": true},
			{"x": 2910, "y": 458, "w": 70, "h": 22, "drop_through": true}
		],
		"checkpoints": [
			{"x": 300, "y": 360, "rect": Rect2(250, 320, 100, 120), "layer": "surface"},
			{"x": 840, "y": 520, "rect": Rect2(790, 480, 100, 100), "layer": "underground"},
			{"x": 1620, "y": 520, "rect": Rect2(1570, 480, 100, 100), "layer": "underground"},
			{"x": 2520, "y": 520, "rect": Rect2(2470, 480, 100, 100), "layer": "underground"}
		],
		"goal_rect": Rect2(3950, 430, 50, 150),
		"layers": [
			{"id": "surface", "y_min": 320, "y_max": 440, "type": "ground"},
			{"id": "underground", "y_min": 458, "y_max": 580, "type": "cave"},
			{"id": "platform", "y_min": 378, "y_max": 478, "type": "platform"}
		],
		"segments": [
			# Surface entry - complainer + bomber mix
			{"x_min": 0, "x_max": 480, "spawn_zones": [{"x_min": 120, "x_max": 410, "y_min": 325, "y_max": 435, "layer": "surface", "pool": ["complainer", "bomber"], "density": 0.55, "max_concurrent": 4, "trigger_x": 80}]},
			# VERTICAL DESCENT SHAFT - bomber fire from above and sides
			{"x_min": 500, "x_max": 610, "spawn_zones": [
				{"x_min": 505, "x_max": 585, "y_min": 453, "y_max": 475, "layer": "platform", "pool": ["bomber"], "density": 0.7, "max_concurrent": 2, "trigger_x": 495},
				{"x_min": 525, "x_max": 560, "y_min": 413, "y_max": 443, "layer": "platform", "pool": ["bomber"], "density": 0.7, "max_concurrent": 2, "trigger_x": 520},
				{"x_min": 545, "x_max": 580, "y_min": 373, "y_max": 403, "layer": "platform", "pool": ["bomber"], "density": 0.7, "max_concurrent": 2, "trigger_x": 540}
			]},
			# Cave segment 1: BOMBER CLUSTER - peaks at 60% (680-740), eases before checkpoint (790-840)
			{"x_min": 610, "x_max": 1200, "spawn_zones": [
				{"x_min": 680, "x_max": 740, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["bomber"], "density": 0.9, "max_concurrent": 5, "trigger_x": 620},
				{"x_min": 760, "x_max": 840, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["complainer", "bomber"], "density": 0.6, "max_concurrent": 4, "trigger_x": 750}
			]},
			{"x_min": 1100, "x_max": 1190, "spawn_zones": [{"x_min": 1105, "x_max": 1175, "y_min": 453, "y_max": 475, "layer": "platform", "pool": ["bomber"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1095}]},
			# Pre-squeeze transition
			{"x_min": 1200, "x_max": 1400, "spawn_zones": [{"x_min": 1220, "x_max": 1350, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["manager", "complainer"], "density": 0.65, "max_concurrent": 4, "trigger_x": 1210}]},
			{"x_min": 1320, "x_max": 1410, "spawn_zones": [{"x_min": 1325, "x_max": 1395, "y_min": 453, "y_max": 475, "layer": "platform", "pool": ["complainer"], "density": 0.4, "max_concurrent": 1, "trigger_x": 1315}]},
			# SQUEEZE SECTION (1400-1800 = 400px) - MELEE CLUSTER alternating with bombers - peaks at 60% (1520-1580)
			{"x_min": 1400, "x_max": 2100, "spawn_zones": [
				{"x_min": 1420, "x_max": 1520, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["manager", "complainer"], "density": 0.75, "max_concurrent": 5, "trigger_x": 1410},
				{"x_min": 1530, "x_max": 1630, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["bomber", "hoa"], "density": 0.9, "max_concurrent": 6, "trigger_x": 1520},
				{"x_min": 1650, "x_max": 1820, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 4, "trigger_x": 1640}
			]},
			{"x_min": 1890, "x_max": 1980, "spawn_zones": [{"x_min": 1895, "x_max": 1955, "y_min": 453, "y_max": 475, "layer": "platform", "pool": ["bomber"], "density": 0.5, "max_concurrent": 2, "trigger_x": 1885}]},
			{"x_min": 2010, "x_max": 2100, "spawn_zones": [{"x_min": 2015, "x_max": 2075, "y_min": 453, "y_max": 475, "layer": "platform", "pool": ["bomber"], "density": 0.5, "max_concurrent": 2, "trigger_x": 2005}]},
			# Cave segment 3: BOMBER CLUSTER - peaks at 65% (2280-2420), eases before checkpoint (2470-2520)
			{"x_min": 2100, "x_max": 3000, "spawn_zones": [
				{"x_min": 2180, "x_max": 2320, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["bomber", "hoa"], "density": 0.95, "max_concurrent": 6, "trigger_x": 2110},
				{"x_min": 2340, "x_max": 2480, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 2330}
			]},
			{"x_min": 2910, "x_max": 3000, "spawn_zones": [{"x_min": 2915, "x_max": 2975, "y_min": 453, "y_max": 475, "layer": "platform", "pool": ["hoa"], "density": 0.5, "max_concurrent": 2, "trigger_x": 2905}]},
			# Final segment: MELEE + elite bomber mix
			{"x_min": 3000, "x_max": 4000, "spawn_zones": [{"x_min": 3080, "x_max": 3920, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["bomber", "hoa", "mega"], "density": 1.0, "max_concurrent": 6, "trigger_x": 3010}]}
		],
		"decor": [
			{"x": 520, "y": 390, "type": "vertical_descent"},
			{"x": 700, "y": 500, "type": "bomber_cluster"},
			{"x": 1600, "y": 500, "type": "squeeze_section"},
			{"x": 2300, "y": 500, "type": "bomber_gauntlet"},
			{"x": 3500, "y": 500, "type": "final_chamber"}
		],
		"respawn_hp_ratio": 0.45,
		"respawn_gold_penalty_ratio": 0.18,
		"max_waves": 1
	}

# --- Level 12: Sky Scramble --- Elite High-Wire: Narrow skybridge ribbon, air dash gates, leap of faith grapple, fall-through routing, distinct phases
static func _level_12() -> Dictionary:
	return {
		"id": 12,
		"name": "Sky Scramble",
		"width": 4800,
		"height": 720,
		"theme": "sky",
		"floor_segments": [
			# Phase 1: Grounded (0-680)
			{"x_min": 0, "x_max": 680, "y_min": 380, "y_max": 500},
			# Phase 2: Elevated (830-1420)
			{"x_min": 830, "x_max": 1420, "y_min": 260, "y_max": 380},
			# Phase 3: SKYBRIDGE - narrowed into ribbon segments (1520-2280 = 760px → split into 3 ribbons)
			{"x_min": 1520, "x_max": 1760, "y_min": 100, "y_max": 220},
			{"x_min": 1850, "x_max": 2080, "y_min": 100, "y_max": 220},
			{"x_min": 2170, "x_max": 2380, "y_min": 100, "y_max": 220},
			# Phase 4: Descent (2380-3160)
			{"x_min": 2380, "x_max": 3160, "y_min": 220, "y_max": 340},
			# Phase 5: Grounded finale (3260-4800)
			{"x_min": 3260, "x_max": 4800, "y_min": 360, "y_max": 480}
		],
		"platforms": [
			{"x": 700, "y": 358, "w": 110, "h": 22},
			# AIR DASH GATE - platform requires air dash to reach (100px gap from x1420)
			{"x": 1480, "y": 238, "w": 60, "h": 22},
			# FALL-THROUGH decision platform - drop to lower island or continue skybridge
			{"x": 1780, "y": 180, "w": 70, "h": 22, "drop_through": true},
			# Skybridge micro-platforms (narrow gaps between ribbon segments)
			{"x": 1770, "y": 78, "w": 60, "h": 22},
			{"x": 2090, "y": 78, "w": 60, "h": 22},
			# Descent island platforms
			{"x": 2310, "y": 198, "w": 60, "h": 22, "drop_through": true},
			{"x": 2600, "y": 258, "w": 70, "h": 22},
			# AIR DASH GATE - platform requires air dash (gap from x3160)
			{"x": 3200, "y": 338, "w": 70, "h": 22}
		],
		"grapple_anchors": [
			{"x": 1200, "y": 220},  # Elevated to skybridge transition
			{"x": 1850, "y": 60},   # LEAP OF FAITH - hidden behind skybridge geometry
			{"x": 2500, "y": 100},  # Skybridge to descent shortcut
			{"x": 3800, "y": 280}
		],
		"checkpoints": [
			{"x": 450, "y": 420, "rect": Rect2(400, 380, 100, 120), "layer": "surface"},
			{"x": 1200, "y": 300, "rect": Rect2(1150, 260, 100, 120), "layer": "platform"},
			{"x": 1950, "y": 150, "rect": Rect2(1900, 100, 100, 120), "layer": "skybridge"},
			{"x": 2800, "y": 270, "rect": Rect2(2750, 220, 100, 120), "layer": "platform"},
			{"x": 4100, "y": 400, "rect": Rect2(4050, 360, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4750, 300, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 78, "y_max": 500, "type": "ground"},
			{"id": "platform", "y_min": 58, "y_max": 360, "type": "platform"},
			{"id": "skybridge", "y_min": 100, "y_max": 220, "type": "skybridge"}
		],
		"segments": [
			# PHASE 1: Grounded (0-700)
			{"x_min": 0, "x_max": 700, "spawn_zones": [{"x_min": 150, "x_max": 610, "y_min": 385, "y_max": 495, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.55, "max_concurrent": 4, "trigger_x": 100}]},
			{"x_min": 700, "x_max": 830, "spawn_zones": [{"x_min": 705, "x_max": 800, "y_min": 352, "y_max": 365, "layer": "platform", "pool": ["complainer"], "density": 0.4, "max_concurrent": 1, "trigger_x": 695}]},
			# PHASE 2: Elevated (830-1520)
			{"x_min": 830, "x_max": 1520, "spawn_zones": [
				{"x_min": 890, "x_max": 1350, "y_min": 265, "y_max": 375, "layer": "platform", "pool": ["complainer", "manager", "witch"], "density": 0.7, "max_concurrent": 5, "trigger_x": 840},
				{"x_min": 1485, "x_max": 1535, "y_min": 233, "y_max": 263, "layer": "platform", "pool": ["manager"], "density": 0.45, "max_concurrent": 1, "trigger_x": 1480}
			]},
			# PHASE 3: SKYBRIDGE (1520-2380) - narrowed ribbon segments with gaps
			{"x_min": 1520, "x_max": 2380, "spawn_zones": [
				# Ribbon 1 (1520-1760)
				{"x_min": 1610, "x_max": 1750, "y_min": 105, "y_max": 215, "layer": "skybridge", "pool": ["manager", "hoa"], "density": 0.75, "max_concurrent": 4, "trigger_x": 1530},
				# Fall-through platform zone
				{"x_min": 1785, "x_max": 1845, "y_min": 175, "y_max": 205, "layer": "platform", "pool": ["witch"], "density": 0.65, "max_concurrent": 2, "trigger_x": 1780},
				# Micro-platform zones (air dash required)
				{"x_min": 1775, "x_max": 1825, "y_min": 73, "y_max": 103, "layer": "platform", "pool": ["hoa"], "density": 0.6, "max_concurrent": 2, "trigger_x": 1770},
				# Ribbon 2 (1850-2080)
				{"x_min": 1900, "x_max": 2070, "y_min": 105, "y_max": 215, "layer": "skybridge", "pool": ["hoa", "witch"], "density": 0.8, "max_concurrent": 5, "trigger_x": 1860},
				# Micro-platform 2
				{"x_min": 2095, "x_max": 2145, "y_min": 73, "y_max": 103, "layer": "platform", "pool": ["witch"], "density": 0.6, "max_concurrent": 2, "trigger_x": 2090},
				# Ribbon 3 (2170-2380)
				{"x_min": 2220, "x_max": 2370, "y_min": 105, "y_max": 215, "layer": "skybridge", "pool": ["manager", "hoa", "witch"], "density": 0.85, "max_concurrent": 6, "trigger_x": 2180}
			]},
			{"x_min": 2310, "x_max": 2390, "spawn_zones": [{"x_min": 2315, "x_max": 2365, "y_min": 193, "y_max": 223, "layer": "platform", "pool": ["witch"], "density": 0.4, "max_concurrent": 1, "trigger_x": 2305}]},
			# PHASE 4: Descent (2380-3260)
			{"x_min": 2380, "x_max": 3260, "spawn_zones": [{"x_min": 2470, "x_max": 3090, "y_min": 225, "y_max": 335, "layer": "platform", "pool": ["manager", "witch", "hoa"], "density": 0.8, "max_concurrent": 5, "trigger_x": 2390}]},
			{"x_min": 3200, "x_max": 3270, "spawn_zones": [{"x_min": 3205, "x_max": 3260, "y_min": 332, "y_max": 362, "layer": "platform", "pool": ["hoa"], "density": 0.45, "max_concurrent": 2, "trigger_x": 3195}]},
			# PHASE 5: Grounded finale (3260-4800)
			{"x_min": 3260, "x_max": 4800, "spawn_zones": [{"x_min": 3380, "x_max": 4700, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.8, "max_concurrent": 6, "trigger_x": 3270}]}
		],
		"decor": [
			{"x": 650, "y": 400, "type": "phase_1_grounded"},
			{"x": 1100, "y": 280, "type": "phase_2_elevated"},
			{"x": 1480, "y": 220, "type": "air_dash_gate_1"},
			{"x": 1900, "y": 120, "type": "phase_3_skybridge"},
			{"x": 1850, "y": 40, "type": "leap_of_faith_grapple"},
			{"x": 1780, "y": 160, "type": "fall_through_decision"},
			{"x": 2600, "y": 240, "type": "phase_4_descent"},
			{"x": 3200, "y": 320, "type": "air_dash_gate_2"},
			{"x": 4000, "y": 380, "type": "phase_5_grounded_finale"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 13: Mixed Madness --- Elite Chaos: Multi-level arenas, corridor breaks, sequential enemy introduction, density oscillation, vertical escape grapple
static func _level_13() -> Dictionary:
	return {
		"id": 13,
		"name": "Mixed Madness",
		"width": 5200,
		"height": 720,
		"theme": "grass",
		"floor_segments": [
			# ARENA 1 (0-720) - multi-level combat arena (ground + 2 platforms)
			{"x_min": 0, "x_max": 720, "y_min": 360, "y_max": 480},
			# Corridor 1
			{"x_min": 870, "x_max": 1650, "y_min": 360, "y_max": 480},
			{"x_min": 870, "x_max": 1200, "y_min": 240, "y_max": 320},
			# ARENA 2 (1780-2660) - wide arena with vertical escape grapple
			{"x_min": 1780, "x_max": 2660, "y_min": 360, "y_max": 480},
			{"x_min": 1780, "x_max": 2100, "y_min": 230, "y_max": 310},
			# ARENA 3 (2790-3670) - climax arena
			{"x_min": 2790, "x_max": 3670, "y_min": 360, "y_max": 480},
			# ARENA 4 (3800-5200) - finale arena (all enemy types)
			{"x_min": 3800, "x_max": 5200, "y_min": 360, "y_max": 480}
		],
		"platforms": [
			# MULTI-LEVEL ARENA 1 - ground + 2 platforms for vertical combat
			{"x": 280, "y": 298, "w": 100, "h": 22},
			{"x": 480, "y": 258, "w": 90, "h": 22},
			# Corridor 1 platforms
			{"x": 740, "y": 338, "w": 110, "h": 22},
			{"x": 1220, "y": 218, "w": 90, "h": 22},
			{"x": 1680, "y": 338, "w": 80, "h": 22},
			# ARENA 2 multi-level
			{"x": 1980, "y": 298, "w": 100, "h": 22},
			{"x": 2130, "y": 208, "w": 100, "h": 22},
			# Corridor 3
			{"x": 2700, "y": 338, "w": 70, "h": 22},
			# ARENA 3 multi-level
			{"x": 3100, "y": 298, "w": 95, "h": 22},
			{"x": 3350, "y": 258, "w": 90, "h": 22},
			# Corridor 4
			{"x": 3700, "y": 338, "w": 90, "h": 22},
			# ARENA 4 finale multi-level
			{"x": 4200, "y": 298, "w": 100, "h": 22},
			{"x": 4600, "y": 258, "w": 100, "h": 22}
		],
		"grapple_anchors": [
			{"x": 350, "y": 220},   # Arena 1 vertical escape
			{"x": 1300, "y": 170},
			{"x": 2000, "y": 240},  # Arena 2 vertical escape/re-engage
			{"x": 2350, "y": 160},
			{"x": 3200, "y": 220},  # Arena 3 vertical escape
			{"x": 3500, "y": 280}
		],
		"checkpoints": [
			{"x": 450, "y": 400, "rect": Rect2(400, 360, 100, 120), "layer": "surface"},
			{"x": 1300, "y": 270, "rect": Rect2(1250, 240, 100, 100), "layer": "platform"},
			{"x": 2250, "y": 400, "rect": Rect2(2200, 360, 100, 120), "layer": "surface"},
			{"x": 3250, "y": 400, "rect": Rect2(3200, 360, 100, 120), "layer": "surface"},
			{"x": 4500, "y": 400, "rect": Rect2(4450, 360, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(5150, 300, 50, 220),
		"layers": [{"id": "surface", "y_min": 208, "y_max": 480, "type": "ground"}, {"id": "platform", "y_min": 186, "y_max": 358, "type": "platform"}],
		"segments": [
			# ARENA 1 - Introduce complainer, manager, bomber, hoa | HIGH density
			{"x_min": 0, "x_max": 740, "spawn_zones": [
				{"x_min": 200, "x_max": 650, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 6, "trigger_x": 150},
				# Platform spawns for multi-level combat
				{"x_min": 285, "x_max": 375, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["bomber", "hoa"], "density": 0.7, "max_concurrent": 3, "trigger_x": 280},
				{"x_min": 485, "x_max": 565, "y_min": 253, "y_max": 283, "layer": "platform", "pool": ["manager", "hoa"], "density": 0.7, "max_concurrent": 3, "trigger_x": 480}
			]},
			# CORRIDOR 1 | MEDIUM density
			{"x_min": 740, "x_max": 870, "spawn_zones": [{"x_min": 745, "x_max": 835, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["bomber"], "density": 0.45, "max_concurrent": 2, "trigger_x": 735}]},
			{"x_min": 870, "x_max": 1780, "spawn_zones": [
				{"x_min": 930, "x_max": 1580, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.7, "max_concurrent": 5, "trigger_x": 880},
				{"x_min": 1245, "x_max": 1305, "y_min": 223, "y_max": 255, "layer": "platform", "pool": ["hoa"], "density": 0.55, "max_concurrent": 2, "trigger_x": 1235}
			]},
			{"x_min": 1680, "x_max": 1770, "spawn_zones": [{"x_min": 1685, "x_max": 1755, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["manager"], "density": 0.45, "max_concurrent": 2, "trigger_x": 1675}]},
			# ARENA 2 - Add witch | HIGH density
			{"x_min": 1780, "x_max": 2790, "spawn_zones": [
				{"x_min": 1860, "x_max": 2620, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 1790},
				# Multi-level combat
				{"x_min": 1985, "x_max": 2075, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["witch", "hoa"], "density": 0.75, "max_concurrent": 3, "trigger_x": 1980},
				{"x_min": 2155, "x_max": 2215, "y_min": 213, "y_max": 245, "layer": "platform", "pool": ["witch"], "density": 0.65, "max_concurrent": 2, "trigger_x": 2145}
			]},
			# CORRIDOR 3 | MEDIUM density
			{"x_min": 2700, "x_max": 2790, "spawn_zones": [{"x_min": 2705, "x_max": 2775, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["hoa"], "density": 0.45, "max_concurrent": 2, "trigger_x": 2695}]},
			# ARENA 3 - Add mega | CLIMAX density
			{"x_min": 2790, "x_max": 3800, "spawn_zones": [
				{"x_min": 2880, "x_max": 3690, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch", "mega"], "density": 0.95, "max_concurrent": 8, "trigger_x": 2800},
				# Multi-level climax
				{"x_min": 3105, "x_max": 3185, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["mega", "witch"], "density": 0.8, "max_concurrent": 3, "trigger_x": 3100},
				{"x_min": 3355, "x_max": 3435, "y_min": 253, "y_max": 283, "layer": "platform", "pool": ["witch", "hoa"], "density": 0.75, "max_concurrent": 3, "trigger_x": 3350}
			]},
			# CORRIDOR 4 | MEDIUM density
			{"x_min": 3700, "x_max": 3790, "spawn_zones": [{"x_min": 3705, "x_max": 3785, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["mega"], "density": 0.5, "max_concurrent": 1, "trigger_x": 3695}]},
			# ARENA 4 - ALL TYPES finale | PEAK density
			{"x_min": 3800, "x_max": 5200, "spawn_zones": [
				{"x_min": 3920, "x_max": 5100, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa", "witch", "mega"], "density": 1.0, "max_concurrent": 8, "trigger_x": 3810},
				# Multi-level finale
				{"x_min": 4205, "x_max": 4295, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["mega", "witch", "hoa"], "density": 0.85, "max_concurrent": 4, "trigger_x": 4200},
				{"x_min": 4605, "x_max": 4695, "y_min": 253, "y_max": 283, "layer": "platform", "pool": ["mega", "witch"], "density": 0.85, "max_concurrent": 4, "trigger_x": 4600}
			]}
		],
		"decor": [
			{"x": 350, "y": 380, "type": "arena_1_multi_level"},
			{"x": 1100, "y": 380, "type": "corridor_1"},
			{"x": 2000, "y": 380, "type": "arena_2_witch_introduction"},
			{"x": 2000, "y": 220, "type": "vertical_escape_grapple"},
			{"x": 2700, "y": 360, "type": "corridor_3"},
			{"x": 3250, "y": 380, "type": "arena_3_mega_climax"},
			{"x": 4500, "y": 380, "type": "arena_4_all_types_finale"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 14: The Chase --- Elite Hunt: Catch-up moments, enemies ahead, dash chains, platform+ground ambush, escalating last stand
static func _level_14() -> Dictionary:
	return {
		"id": 14,
		"name": "The Chase",
		"width": 4800,
		"height": 720,
		"theme": "cave",
		"floor_segments": [
			# Segment 1 with CATCH-UP MOMENT (500px sprint stretch)
			{"x_min": 0, "x_max": 1100, "y_min": 350, "y_max": 470},
			# Dash chain segment 2
			{"x_min": 1220, "x_max": 2300, "y_min": 350, "y_max": 470},
			# Dash chain segment 3
			{"x_min": 2420, "x_max": 3520, "y_min": 350, "y_max": 470},
			# LAST STAND segment 4
			{"x_min": 3640, "x_max": 4800, "y_min": 350, "y_max": 470}
		],
		"platforms": [
			# Dash chain platforms - positioned for dash→land→sprint→dash
			{"x": 1118, "y": 328, "w": 85, "h": 22},
			# PLATFORM AMBUSH - enemies above player
			{"x": 1580, "y": 288, "w": 90, "h": 22},
			{"x": 2318, "y": 328, "w": 85, "h": 22},
			# PLATFORM AMBUSH
			{"x": 2780, "y": 288, "w": 95, "h": 22},
			{"x": 3538, "y": 328, "w": 85, "h": 22},
			# PLATFORM AMBUSH in last stand
			{"x": 4100, "y": 288, "w": 100, "h": 22}
		],
		"checkpoints": [
			{"x": 700, "y": 390, "rect": Rect2(650, 350, 100, 120), "layer": "surface"},
			{"x": 1780, "y": 390, "rect": Rect2(1730, 350, 100, 120), "layer": "surface"},
			{"x": 2980, "y": 390, "rect": Rect2(2930, 350, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(4750, 290, 50, 220),
		"layers": [{"id": "surface", "y_min": 288, "y_max": 470, "type": "ground"}, {"id": "platform", "y_min": 266, "y_max": 350, "type": "platform"}],
		"segments": [
			# Segment 1: Warm-up + CATCH-UP MOMENT (500px sprint: 600-1100)
			{"x_min": 0, "x_max": 1100, "spawn_zones": [
				# Initial chase (250-580)
				{"x_min": 250, "x_max": 580, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["complainer", "manager"], "density": 0.65, "max_concurrent": 5, "trigger_x": 200, "ambush": true},
				# CATCH-UP MOMENT (600-1100 = 500px sprint) - low density so player can create distance
				{"x_min": 820, "x_max": 1050, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["complainer"], "density": 0.35, "max_concurrent": 3, "trigger_x": 600}
			]},
			{"x_min": 1118, "x_max": 1240, "spawn_zones": [{"x_min": 1122, "x_max": 1198, "y_min": 322, "y_max": 345, "layer": "platform", "pool": ["complainer"], "density": 0.35, "max_concurrent": 1, "trigger_x": 1110}]},
			# Segment 2: Dash chain + PLATFORM AMBUSH (above and behind)
			{"x_min": 1220, "x_max": 2340, "spawn_zones": [
				# Ground ambush from behind
				{"x_min": 1350, "x_max": 1750, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "bomber"], "density": 0.8, "max_concurrent": 5, "trigger_x": 1230, "ambush": true},
				# PLATFORM AMBUSH - enemies above
				{"x_min": 1585, "x_max": 1665, "y_min": 283, "y_max": 313, "layer": "platform", "pool": ["bomber", "hoa"], "density": 0.75, "max_concurrent": 3, "trigger_x": 1580},
				# Post-dash continuation
				{"x_min": 1820, "x_max": 2220, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.85, "max_concurrent": 6, "trigger_x": 1780, "ambush": true}
			]},
			{"x_min": 2318, "x_max": 2440, "spawn_zones": [{"x_min": 2322, "x_max": 2398, "y_min": 322, "y_max": 345, "layer": "platform", "pool": ["manager"], "density": 0.45, "max_concurrent": 2, "trigger_x": 2310}]},
			# Segment 3: Escalation + ENEMIES AHEAD (they're everywhere)
			{"x_min": 2420, "x_max": 3550, "spawn_zones": [
				# Ground ambush
				{"x_min": 2550, "x_max": 3000, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "hoa", "witch"], "density": 0.85, "max_concurrent": 6, "trigger_x": 2430, "ambush": true},
				# PLATFORM AMBUSH above
				{"x_min": 2785, "x_max": 2870, "y_min": 283, "y_max": 313, "layer": "platform", "pool": ["witch", "hoa"], "density": 0.8, "max_concurrent": 3, "trigger_x": 2780},
				# ENEMIES AHEAD - spawn in front of player (trigger_x at 3020, but enemies at 3050+)
				{"x_min": 3050, "x_max": 3440, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 3020, "ambush": true}
			]},
			{"x_min": 3538, "x_max": 3660, "spawn_zones": [{"x_min": 3542, "x_max": 3618, "y_min": 322, "y_max": 345, "layer": "platform", "pool": ["manager"], "density": 0.45, "max_concurrent": 2, "trigger_x": 3530}]},
			# Segment 4: LAST STAND (3640+) - escalating finale before goal
			{"x_min": 3640, "x_max": 4800, "spawn_zones": [
				# Ground wave 1 - high threat
				{"x_min": 3780, "x_max": 4050, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.9, "max_concurrent": 6, "trigger_x": 3650, "ambush": true},
				# PLATFORM AMBUSH above
				{"x_min": 4105, "x_max": 4195, "y_min": 283, "y_max": 313, "layer": "platform", "pool": ["witch", "mega"], "density": 0.85, "max_concurrent": 3, "trigger_x": 4100},
				# Ground wave 2 - FINAL escalation (includes mega)
				{"x_min": 4120, "x_max": 4680, "y_min": 355, "y_max": 465, "layer": "surface", "pool": ["manager", "bomber", "hoa", "mega"], "density": 0.95, "max_concurrent": 7, "trigger_x": 4080, "ambush": true}
			]}
		],
		"decor": [
			{"x": 850, "y": 370, "type": "catch_up_moment"},
			{"x": 1100, "y": 350, "type": "pit_forces_commitment"},
			{"x": 1580, "y": 270, "type": "platform_ambush"},
			{"x": 3050, "y": 370, "type": "enemies_ahead"},
			{"x": 4000, "y": 370, "type": "last_stand"}
		],
		"respawn_hp_ratio": 0.45,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}

# --- Level 15: The Final Gauntlet --- ELITE CAPSTONE: 10-segment pacing, wall-jump challenge room, victory lap finale, full-heal sanctuaries, grapple shortcuts, rewarding gold zone
static func _level_15() -> Dictionary:
	return {
		"id": 15,
		"name": "The Final Gauntlet",
		"width": 7400,
		"height": 720,
		"theme": "summit",
		"floor_segments": [
			# Segments 1-2: Warm-up surface (0-2110)
			{"x_min": 0, "x_max": 1080, "y_min": 360, "y_max": 480},
			{"x_min": 1230, "x_max": 2110, "y_min": 360, "y_max": 480},
			# Segments 3-4: Cave intensity (2240-3260)
			{"x_min": 2240, "x_max": 3120, "y_min": 480, "y_max": 580},
			# Segments 5-6: WALL-JUMP CHALLENGE ROOM + skybridge climax (3135-4280)
			{"x_min": 3135, "x_max": 3260, "y_min": 340, "y_max": 440},  # Wall-jump shaft bottom
			{"x_min": 3260, "x_max": 4140, "y_min": 120, "y_max": 220},
			# Segments 7-8: Surface gauntlet with GOLD ZONE (4280-6400)
			{"x_min": 4280, "x_max": 5300, "y_min": 360, "y_max": 480},  # GOLD MULTIPLIER ZONE
			{"x_min": 5300, "x_max": 6400, "y_min": 360, "y_max": 480},
			# Segments 9-10: VICTORY LAP (6400-7400)
			{"x_min": 6400, "x_max": 7400, "y_min": 360, "y_max": 480}
		],
		"platforms": [
			{"x": 1100, "y": 338, "w": 110, "h": 22},
			{"x": 2140, "y": 458, "w": 80, "h": 22, "drop_through": true},
			# WALL-JUMP CHALLENGE ROOM platforms
			{"x": 3150, "y": 298, "w": 70, "h": 22},
			{"x": 3180, "y": 198, "w": 60, "h": 22},
			{"x": 4100, "y": 258, "w": 70, "h": 22},
			{"x": 4170, "y": 338, "w": 100, "h": 22},
			{"x": 5190, "y": 338, "w": 90, "h": 22},
			{"x": 6350, "y": 338, "w": 80, "h": 22},
			# Victory lap platform
			{"x": 7000, "y": 298, "w": 90, "h": 22}
		],
		"wall_segments": [
			# WALL-JUMP CHALLENGE ROOM (1000px shaft: 3135-4135)
			{"x": 3135, "y": 120, "w": 18, "h": 330},
			{"x": 4135, "y": 120, "w": 18, "h": 330}
		],
		"grapple_anchors": [
			{"x": 2000, "y": 300},  # Pre-cave shortcut
			{"x": 3500, "y": 80},   # WALL-JUMP BYPASS - skips entire challenge room
			{"x": 4800, "y": 300},  # Gold zone shortcut
			{"x": 6500, "y": 280}   # Surface gauntlet shortcut
		],
		"checkpoints": [
			# Segment 1: Full-heal after warm-up
			{"x": 600, "y": 400, "rect": Rect2(550, 360, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			# Segment 2: Pre-cave
			{"x": 1700, "y": 400, "rect": Rect2(1650, 360, 100, 120), "layer": "surface"},
			# Segment 3-4: Post-cave intensity
			{"x": 2700, "y": 520, "rect": Rect2(2650, 480, 100, 100), "layer": "underground"},
			# Segment 5-6: Post-WALL-JUMP + skybridge climax
			{"x": 3750, "y": 160, "rect": Rect2(3700, 120, 100, 100), "layer": "skybridge"},
			# Segment 7: Full-heal after skybridge gauntlet
			{"x": 4750, "y": 400, "rect": Rect2(4700, 360, 100, 120), "layer": "surface", "heal_ratio": 1.0},
			# Segment 8: Post-gold zone
			{"x": 5900, "y": 400, "rect": Rect2(5850, 360, 100, 120), "layer": "surface"},
			# Segment 9-10: Victory lap checkpoint
			{"x": 6800, "y": 400, "rect": Rect2(6750, 360, 100, 120), "layer": "surface"}
		],
		"goal_rect": Rect2(7350, 300, 50, 220),
		"layers": [
			{"id": "surface", "y_min": 198, "y_max": 580, "type": "ground"},
			{"id": "platform", "y_min": 176, "y_max": 478, "type": "platform"},
			{"id": "underground", "y_min": 458, "y_max": 580, "type": "cave"},
			{"id": "skybridge", "y_min": 120, "y_max": 220, "type": "skybridge"}
		],
		"segments": [
			# SEGMENT 1: Warm-up (0-1100)
			{"x_min": 0, "x_max": 1100, "spawn_zones": [{"x_min": 200, "x_max": 1000, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.65, "max_concurrent": 5, "trigger_x": 150}]},
			{"x_min": 1100, "x_max": 1230, "spawn_zones": [{"x_min": 1105, "x_max": 1195, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["complainer"], "density": 0.4, "max_concurrent": 1, "trigger_x": 1095}]},
			# SEGMENT 2: Warm-up continues (1230-2240)
			{"x_min": 1230, "x_max": 2240, "spawn_zones": [{"x_min": 1320, "x_max": 2040, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "bomber", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 1240, "ambush": true}]},
			{"x_min": 2140, "x_max": 2230, "spawn_zones": [{"x_min": 2145, "x_max": 2215, "y_min": 452, "y_max": 475, "layer": "platform", "pool": ["bomber"], "density": 0.5, "max_concurrent": 2, "trigger_x": 2135}]},
			# SEGMENT 3-4: Cave intensity (2240-3260)
			{"x_min": 2240, "x_max": 3260, "spawn_zones": [{"x_min": 2330, "x_max": 3050, "y_min": 485, "y_max": 575, "layer": "underground", "pool": ["manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 2250}]},
			# SEGMENT 5: WALL-JUMP CHALLENGE ROOM (3135-4135) - distinct vertical fight
			{"x_min": 3135, "x_max": 4280, "spawn_zones": [
				# Lower shaft combat
				{"x_min": 3155, "x_max": 3250, "y_min": 345, "y_max": 435, "layer": "surface", "pool": ["manager", "hoa"], "density": 0.7, "max_concurrent": 4, "trigger_x": 3145},
				# Mid-shaft platform combat
				{"x_min": 3155, "x_max": 3235, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["witch"], "density": 0.65, "max_concurrent": 3, "trigger_x": 3150},
				{"x_min": 3185, "x_max": 3245, "y_min": 193, "y_max": 223, "layer": "platform", "pool": ["hoa"], "density": 0.6, "max_concurrent": 2, "trigger_x": 3180},
				# SEGMENT 6: Skybridge climax
				{"x_min": 3380, "x_max": 4060, "y_min": 125, "y_max": 215, "layer": "skybridge", "pool": ["manager", "hoa", "witch"], "density": 0.85, "max_concurrent": 6, "trigger_x": 3270}
			]},
			{"x_min": 4170, "x_max": 4260, "spawn_zones": [{"x_min": 4175, "x_max": 4255, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["hoa"], "density": 0.45, "max_concurrent": 2, "trigger_x": 4165}]},
			# SEGMENT 7: GOLD MULTIPLIER ZONE (4280-5300) - rewarding, not punishing
			{"x_min": 4280, "x_max": 5300, "spawn_zones": [{"x_min": 4400, "x_max": 5080, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber", "hoa"], "density": 0.75, "max_concurrent": 6, "trigger_x": 4290, "gold_multiplier": 1.5}]},
			{"x_min": 5190, "x_max": 5280, "spawn_zones": [{"x_min": 5195, "x_max": 5275, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["manager"], "density": 0.4, "max_concurrent": 2, "trigger_x": 5185}]},
			# SEGMENT 8: Surface gauntlet (5300-6400)
			{"x_min": 5300, "x_max": 6400, "spawn_zones": [{"x_min": 5420, "x_max": 6280, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "bomber", "hoa", "witch"], "density": 0.9, "max_concurrent": 7, "trigger_x": 5310}]},
			{"x_min": 6350, "x_max": 6440, "spawn_zones": [{"x_min": 6355, "x_max": 6435, "y_min": 332, "y_max": 345, "layer": "platform", "pool": ["mega"], "density": 0.5, "max_concurrent": 1, "trigger_x": 6345}]},
			# SEGMENT 9-10: VICTORY LAP (6400-7400) - "you made it" feel, slightly easier than segment before
			{"x_min": 6400, "x_max": 7400, "spawn_zones": [
				# First 400px maintains some pressure
				{"x_min": 6560, "x_max": 6900, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["manager", "bomber", "hoa", "mega"], "density": 0.85, "max_concurrent": 7, "trigger_x": 6450},
				# Victory platform
				{"x_min": 7005, "x_max": 7085, "y_min": 293, "y_max": 323, "layer": "platform", "pool": ["witch"], "density": 0.6, "max_concurrent": 2, "trigger_x": 7000},
				# Final 400px eases - finish strong, not exhausted
				{"x_min": 6950, "x_max": 7280, "y_min": 365, "y_max": 475, "layer": "surface", "pool": ["complainer", "manager", "bomber"], "density": 0.7, "max_concurrent": 5, "trigger_x": 6920}
			]}
		],
		"decor": [
			{"x": 600, "y": 380, "type": "seg_1_2_warmup"},
			{"x": 2600, "y": 500, "type": "seg_3_4_cave_intensity"},
			{"x": 3600, "y": 150, "type": "seg_5_6_wall_jump_skybridge_climax"},
			{"x": 3500, "y": 60, "type": "grapple_bypass"},
			{"x": 4750, "y": 380, "type": "full_heal_sanctuary"},
			{"x": 4800, "y": 380, "type": "seg_7_8_gold_zone"},
			{"x": 6000, "y": 380, "type": "surface_gauntlet"},
			{"x": 7100, "y": 380, "type": "seg_9_10_victory_lap"}
		],
		"respawn_hp_ratio": 0.5,
		"respawn_gold_penalty_ratio": 0.15,
		"max_waves": 1
	}
