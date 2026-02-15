class_name SkillData
extends RefCounted

static func get_all_skills() -> Array:
	return [
		# === OFFENSE ===
		{
			"id": "mellow_strength",
			"name": "Mellow Strength",
			"description": "+15% melee damage",
			"category": "offense",
			"scope": "player",
			"color": Color8(220, 80, 80),
			"apply": "melee_damage_mult"
		},
		{
			"id": "eagle_eye",
			"name": "Eagle Eye",
			"description": "+15% ranged damage",
			"category": "offense",
			"scope": "player",
			"color": Color8(80, 180, 220),
			"apply": "ranged_damage_mult"
		},
		{
			"id": "quick_hands",
			"name": "Quick Hands",
			"description": "-15% attack cooldown",
			"category": "offense",
			"color": Color8(255, 160, 60),
			"apply": "cooldown_mult"
		},
		{
			"id": "critical_hit",
			"name": "Critical Hit",
			"description": "+8% crit chance (2x damage)",
			"category": "offense",
			"color": Color8(255, 50, 50),
			"apply": "crit_chance"
		},
		{
			"id": "cleave",
			"name": "Cleave",
			"description": "Melee hits +1 additional target",
			"category": "offense",
			"color": Color8(180, 100, 220),
			"apply": "max_melee_targets"
		},
		{
			"id": "wider_swing",
			"name": "Wider Swing",
			"description": "+20% melee arc width",
			"category": "offense",
			"color": Color8(240, 120, 60),
			"apply": "melee_arc"
		},
		{
			"id": "sniper_range",
			"name": "Long Shot",
			"description": "+25% ranged projectile speed",
			"category": "offense",
			"color": Color8(60, 160, 200),
			"apply": "proj_speed"
		},
		# === DEFENSE ===
		{
			"id": "thick_skin",
			"name": "Thick Skin",
			"description": "+25 max HP",
			"category": "defense",
			"color": Color8(80, 200, 80),
			"apply": "max_hp_bonus"
		},
		{
			"id": "lifesteal",
			"name": "Lifesteal Herb",
			"description": "Heal 3 HP per enemy killed",
			"category": "defense",
			"color": Color8(180, 40, 60),
			"apply": "lifesteal"
		},
		{
			"id": "dodge",
			"name": "Smoke Screen",
			"description": "+8% dodge chance (avoid damage)",
			"category": "defense",
			"color": Color8(180, 180, 180),
			"apply": "dodge_chance"
		},
		{
			"id": "regen",
			"name": "Herbal Regen",
			"description": "Regenerate 1 HP every 3 seconds",
			"category": "defense",
			"color": Color8(60, 220, 120),
			"apply": "regen"
		},
		{
			"id": "barricade_guru",
			"name": "Barricade Guru",
			"description": "+50% repair speed",
			"category": "defense",
			"color": Color8(139, 90, 43),
			"apply": "repair_mult"
		},
		{
			"id": "fortify",
			"name": "Fortify",
			"description": "All barricades +15% max HP",
			"category": "defense",
			"scope": "global",
			"color": Color8(120, 90, 50),
			"apply": "barricade_hp"
		},
		# === MOBILITY ===
		{
			"id": "speed_toke",
			"name": "Speed Toke",
			"description": "+12% move speed",
			"category": "mobility",
			"color": Color8(220, 220, 80),
			"apply": "speed_mult"
		},
		# === SUPPORT ===
		{
			"id": "chill_aura",
			"name": "Chill Aura",
			"description": "Allies deal +10% damage",
			"category": "support",
			"scope": "global",
			"color": Color8(100, 160, 255),
			"apply": "ally_damage_mult"
		},
		{
			"id": "rally_cry",
			"name": "Rally Cry",
			"description": "Allies get +20% max HP",
			"category": "support",
			"scope": "global",
			"color": Color8(80, 200, 160),
			"apply": "ally_hp_mult"
		},
		{
			"id": "inspiring",
			"name": "Inspiring Presence",
			"description": "Allies attack 15% faster",
			"category": "support",
			"scope": "global",
			"color": Color8(140, 200, 255),
			"apply": "ally_speed_mult"
		},
		# === ECONOMY ===
		{
			"id": "deep_pockets",
			"name": "Deep Pockets",
			"description": "+25% gold pickup value",
			"category": "economy",
			"color": Color8(255, 215, 0),
			"apply": "gold_mult"
		},
		{
			"id": "bounty_hunter",
			"name": "Bounty Hunter",
			"description": "Enemies drop +30% more gold",
			"category": "economy",
			"color": Color8(230, 180, 40),
			"apply": "enemy_gold_mult"
		},
		{
			"id": "xp_boost",
			"name": "Fast Learner",
			"description": "+20% XP gained",
			"category": "economy",
			"color": Color8(160, 120, 255),
			"apply": "xp_mult"
		},
		{
			"id": "iron_lungs",
			"name": "Iron Lungs",
			"description": "+15 max HP",
			"category": "defense",
			"color": Color8(100, 180, 140),
			"apply": "max_hp_bonus_small"
		},
		{
			"id": "hustle",
			"name": "Hustle",
			"description": "+8% move speed",
			"category": "mobility",
			"color": Color8(255, 200, 100),
			"apply": "speed_mult_small"
		},
		{
			"id": "lucky_coin",
			"name": "Lucky Coin",
			"description": "+10% XP and gold from pickups",
			"category": "economy",
			"color": Color8(255, 220, 100),
			"apply": "lucky_coin"
		},
		{
			"id": "recruiter",
			"name": "Recruiter",
			"description": "+1 ally capacity",
			"category": "support",
			"scope": "global",
			"color": Color8(80, 160, 220),
			"apply": "ally_cap"
		},
		{
			"id": "second_wind",
			"name": "Second Wind",
			"description": "+20 max HP",
			"category": "defense",
			"color": Color8(70, 200, 120),
			"apply": "max_hp_bonus_medium"
		},
		{
			"id": "blood_pact",
			"name": "Blood Pact",
			"description": "Lifesteal +2 HP per kill",
			"category": "defense",
			"color": Color8(200, 50, 70),
			"apply": "lifesteal_small"
		},
	]

static func get_skill_scope(skill_id: String) -> String:
	for s in get_all_skills():
		if s.id == skill_id:
			return s.get("scope", "player")
	return "player"

static func get_random_skills(count: int, _already_picked: Array) -> Array:
	# Skills are now stackable - always offer from the full pool
	var all = get_all_skills()
	all.shuffle()
	return all.slice(0, mini(count, all.size()))
