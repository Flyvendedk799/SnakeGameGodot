class_name UnitData
extends RefCounted

static func get_stats(unit_type: String) -> Dictionary:
	match unit_type:
		"chill_dude":
			return {"hp": 80, "damage": 8, "speed": 55.0, "cost_gold": 30, "cost_crystals": 0,
				"is_ranged": false, "attack_cd": 1.0, "detect_range": 150.0,
				"color": Color8(100, 160, 220), "label": "Cool Guy", "short": "CG", "size": 21.0,
				"building_req": "smoke_shack", "sprite": "coolguy",
				"weapon": {"sprite": "machette", "height": 52.0, "grip": Vector2(0.2, 0.85), "rotation": -0.5}}
		"pot_shot":
			return {"hp": 40, "damage": 12, "speed": 45.0, "cost_gold": 40, "cost_crystals": 0,
				"is_ranged": true, "attack_cd": 1.5, "detect_range": 180.0, "ranged_range": 160.0,
				"color": Color8(100, 200, 120), "label": "Pot Shot", "short": "PS", "size": 18.0,
				"building_req": "smoke_shack", "sprite": "pod",
				"weapon": {"sprite": "rangedak", "height": 44.0, "grip": Vector2(0.25, 0.5), "rotation": 0.0}}
		"zen_master":
			return {"hp": 120, "damage": 15, "speed": 80.0, "cost_gold": 80, "cost_crystals": 0,
				"is_ranged": false, "attack_cd": 0.8, "detect_range": 160.0,
				"color": Color8(180, 180, 255), "label": "Zen Master", "short": "ZM", "size": 21.0,
				"building_req": "bong_academy", "sprite": "zen",
				"weapon": {"sprite": "machette", "height": 55.0, "grip": Vector2(0.2, 0.85), "rotation": -0.5}}
		"space_cadet":
			return {"hp": 50, "damage": 25, "speed": 40.0, "cost_gold": 60, "cost_crystals": 20,
				"is_ranged": true, "attack_cd": 2.0, "detect_range": 200.0, "ranged_range": 180.0,
				"color": Color8(200, 120, 255), "label": "Space Cadet", "short": "SC", "size": 20.0,
				"building_req": "psychic_lounge",
				"weapon": {"sprite": "rangedak", "height": 46.0, "grip": Vector2(0.25, 0.5), "rotation": 0.0}}
		"bouncer_bro":
			return {"hp": 200, "damage": 20, "speed": 50.0, "cost_gold": 100, "cost_crystals": 40,
				"is_ranged": false, "attack_cd": 1.2, "detect_range": 140.0,
				"color": Color8(60, 100, 180), "label": "Bouncer Bro", "short": "BB", "size": 24.0,
				"building_req": "the_dojo",
				"weapon": {"sprite": "machette", "height": 60.0, "grip": Vector2(0.2, 0.85), "rotation": -0.5}}
		"gate_guard":
			return {"hp": 100, "damage": 12, "speed": 60.0, "cost_gold": 70, "cost_crystals": 0,
				"is_ranged": false, "attack_cd": 0.9, "detect_range": 200.0,
				"color": Color8(180, 120, 80), "label": "Gate Guard", "short": "GG", "size": 20.0,
				"building_req": "smoke_shack", "sprite": "coolguy",
				"placement": "outside",
				"weapon": {"sprite": "machette", "height": 52.0, "grip": Vector2(0.2, 0.85), "rotation": -0.5}}
		"coin_runner":
			return {"hp": 150, "damage": 0, "speed": 70.0, "cost_gold": 45, "cost_crystals": 0,
				"is_ranged": false, "attack_cd": 1.0, "detect_range": 250.0,
				"color": Color8(255, 200, 80), "label": "Coin Runner", "short": "CR", "size": 18.0,
				"building_req": "smoke_shack", "sprite": "",
				"collects_gold": true, "collect_radius": 40.0}
		_:
			return {"hp": 50, "damage": 5, "speed": 50.0, "cost_gold": 30, "cost_crystals": 0,
				"is_ranged": false, "attack_cd": 1.0, "detect_range": 150.0,
				"color": Color8(100, 160, 220), "label": "Ally", "short": "A", "size": 18.0,
				"building_req": ""}

static func get_all_types() -> Array[String]:
	return ["chill_dude", "pot_shot", "zen_master", "space_cadet", "bouncer_bro", "gate_guard", "coin_runner"]

static func is_placement_outside(unit_type: String) -> bool:
	var stats = get_stats(unit_type)
	return stats.get("placement", "") == "outside"
