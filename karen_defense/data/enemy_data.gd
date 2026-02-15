class_name EnemyData
extends RefCounted

static func get_stats(enemy_type: String) -> Dictionary:
	match enemy_type:
		"complainer":
			return {"hp": 30, "damage": 5, "speed": 90.0, "gold": 8, "xp": 15,
				"color": Color8(255, 130, 170), "is_ranged": false, "attack_cd": 1.0,
				"label": "Complainer Karen", "short": "CK", "size": 24.0,
				"sprite": "enemya"}
		"manager":
			return {"hp": 45, "damage": 10, "speed": 115.0, "gold": 12, "xp": 25,
				"color": Color8(255, 80, 80), "is_ranged": false, "attack_cd": 0.7,
				"label": "Manager Karen", "short": "MK", "size": 26.0,
				"sprite": "enemyb"}
		"bomber":
			return {"hp": 25, "damage": 40, "speed": 105.0, "gold": 15, "xp": 20,
				"color": Color8(255, 160, 50), "is_ranged": false, "attack_cd": 0.0,
				"label": "Coupon Bomber", "short": "CB", "size": 22.0,
				"is_bomber": true, "sprite": "enemyc"}
		"hoa":
			return {"hp": 100, "damage": 8, "speed": 70.0, "gold": 18, "xp": 35,
				"color": Color8(200, 80, 130), "is_ranged": false, "attack_cd": 1.2,
				"label": "HOA Karen", "short": "HK", "size": 28.0,
				"sprite": "enemyd"}
		"mega":
			return {"hp": 250, "damage": 18, "speed": 55.0, "gold": 35, "xp": 70,
				"color": Color8(220, 50, 120), "is_ranged": false, "attack_cd": 1.5,
				"label": "Mega Karen", "short": "MG", "size": 36.0,
				"sprite": "enemye"}
		"witch":
			return {"hp": 60, "damage": 15, "speed": 75.0, "gold": 22, "xp": 40,
				"color": Color8(180, 80, 220), "is_ranged": true, "attack_cd": 1.8,
				"ranged_range": 250.0,
				"label": "PTA Witch", "short": "PW", "size": 26.0,
				"sprite": "enemyc"}
		"president":
			return {"hp": 400, "damage": 22, "speed": 60.0, "gold": 55, "xp": 100,
				"color": Color8(160, 30, 60), "is_ranged": false, "attack_cd": 1.3,
				"label": "HOA President", "short": "HP", "size": 34.0,
				"sprite": "enemyd"}
		"boss":
			return {"hp": 2000, "damage": 30, "speed": 50.0, "gold": 300, "xp": 500,
				"color": Color8(200, 20, 60), "is_ranged": false, "attack_cd": 1.0,
				"label": "FINAL BOSS KAREN", "short": "FK", "size": 48.0,
				"is_boss": true, "sprite": "enemye"}
		_:
			return {"hp": 30, "damage": 5, "speed": 85.0, "gold": 8, "xp": 15,
				"color": Color8(255, 130, 170), "is_ranged": false, "attack_cd": 1.0,
				"label": "Karen", "short": "K", "size": 22.0,
				"sprite": "enemya"}
