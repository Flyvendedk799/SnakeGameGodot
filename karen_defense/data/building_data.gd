class_name BuildingData
extends RefCounted

static func get_all_buildings() -> Array:
	return [
		{
			"id": "smoke_shack",
			"name": "Smoke Shack",
			"description": "Unlocks hiring Chill Dudes (basic melee bros)",
			"cost_gold": 100, "cost_crystals": 0,
			"prereq": "",
			"effect": "unlock_chill_dude"
		},
		{
			"id": "bong_academy",
			"name": "Bong Academy",
			"description": "Unlocks hiring Zen Masters (fast melee fighters)",
			"cost_gold": 250, "cost_crystals": 0,
			"prereq": "smoke_shack",
			"effect": "unlock_zen_master"
		},
		{
			"id": "the_stash",
			"name": "The Stash",
			"description": "Armory - Unlocks equipment purchases",
			"cost_gold": 200, "cost_crystals": 0,
			"prereq": "",
			"effect": "unlock_equipment"
		},
		{
			"id": "grow_op",
			"name": "Grow Op",
			"description": "+50% gold bonus at end of each wave",
			"cost_gold": 150, "cost_crystals": 0,
			"prereq": "",
			"effect": "gold_mine"
		},
		{
			"id": "crystal_cave",
			"name": "Crystal Cave",
			"description": "Generates crystals each wave (+10 per wave)",
			"cost_gold": 300, "cost_crystals": 0,
			"prereq": "grow_op",
			"effect": "crystal_mine"
		},
		{
			"id": "herbal_lab",
			"name": "Herbal Lab",
			"description": "Potions & consumables - Coming soon, man",
			"cost_gold": 200, "cost_crystals": 0,
			"prereq": "the_stash",
			"effect": "unlock_potions"
		},
		{
			"id": "psychic_lounge",
			"name": "Psychic Lounge",
			"description": "Unlocks hiring Space Cadets (ranged magic)",
			"cost_gold": 400, "cost_crystals": 50,
			"prereq": "bong_academy",
			"effect": "unlock_space_cadet"
		},
		{
			"id": "the_dojo",
			"name": "The Dojo",
			"description": "Unlocks hiring Bouncer Bros (heavy tanks)",
			"cost_gold": 500, "cost_crystals": 100,
			"prereq": "psychic_lounge",
			"effect": "unlock_bouncer_bro"
		},
		{
			"id": "chill_upgrades",
			"name": "Chill Upgrades",
			"description": "Spiked barricades deal 5 dmg to attackers",
			"cost_gold": 200, "cost_crystals": 0,
			"prereq": "smoke_shack",
			"effect": "spiked_barricades"
		},
		{
			"id": "reinforce_doors",
			"name": "Reinforce Doors",
			"description": "Reinforce all keep doors — enemies need 5 strikes to force open (repeatable)",
			"cost_gold": 100, "cost_crystals": 0,
			"prereq": "",
			"effect": "reinforce_doors"
		},
	]
