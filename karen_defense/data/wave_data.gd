class_name WaveData
extends RefCounted

static func get_wave(wave_number: int) -> Dictionary:
	# Returns {"enemies": [{"type": ..., "count": ...}, ...], "spawn_delay": float}
	# Wave design philosophy:
	# - Every wave should feel distinct (not just "more of the same")
	# - Variety peaks keep players engaged: rush waves, mixed waves, mini-boss waves
	# - Difficulty ramps smoothly but has spikes to keep tension
	match wave_number:
		# === WORLD 1: Desert Oasis (Waves 1-15) ===
		# Introduction arc — teach enemy types one at a time
		1: return _w([_e("complainer", 8)], 1.2)
		2: return _w([_e("complainer", 14)], 1.0)
		3: return _w([_e("complainer", 12), _e("manager", 4)], 0.9)     # Introduce managers
		4: return _w([_e("complainer", 16), _e("manager", 8)], 0.8)
		5: return _w([_e("manager", 14), _e("complainer", 10)], 0.7)    # Manager-heavy rush
		6: return _w([_e("complainer", 18), _e("manager", 8), _e("bomber", 4)], 0.7)   # Introduce bombers
		7: return _w([_e("complainer", 14), _e("manager", 10), _e("bomber", 6)], 0.65)
		8: return _w([_e("complainer", 20), _e("manager", 12), _e("bomber", 8)], 0.6)  # Expansion wave
		9: return _w([_e("bomber", 14), _e("manager", 8)], 0.5)         # Bomber swarm!
		10: return _w([_e("complainer", 16), _e("manager", 10), _e("hoa", 4)], 0.6)    # Introduce HOA
		11: return _w([_e("complainer", 20), _e("manager", 12), _e("hoa", 6), _e("bomber", 4)], 0.55)
		12: return _w([_e("hoa", 10), _e("manager", 14), _e("bomber", 8)], 0.5)
		13: return _w([_e("complainer", 24), _e("manager", 14), _e("hoa", 8), _e("bomber", 6)], 0.45)
		14: return _w([_e("manager", 18), _e("hoa", 12), _e("bomber", 10)], 0.4)       # Pre-boss intensity
		15: return _w([_e("mega", 2), _e("manager", 16), _e("hoa", 10), _e("bomber", 8)], 0.4) # W1 finale: mini-bosses

		# === WORLD 2: Frozen Fortress (Waves 16-30) ===
		# Escalation arc — all types in play, new combinations
		16: return _w([_e("complainer", 22), _e("manager", 16), _e("hoa", 10)], 0.45)
		17: return _w([_e("manager", 18), _e("hoa", 12), _e("bomber", 10), _e("mega", 2)], 0.4)
		18: return _w([_e("complainer", 26), _e("manager", 16), _e("hoa", 14), _e("bomber", 8)], 0.38)
		19: return _w([_e("mega", 4), _e("hoa", 14), _e("bomber", 12)], 0.4)           # Mega rush
		20: return _w([_e("manager", 18), _e("hoa", 16), _e("mega", 6), _e("bomber", 10)], 0.35) # Expansion
		21: return _w([_e("complainer", 24), _e("manager", 18), _e("hoa", 14), _e("mega", 4)], 0.35)
		22: return _w([_e("manager", 20), _e("hoa", 16), _e("mega", 6), _e("bomber", 10)], 0.32)
		23: return _w([_e("hoa", 18), _e("mega", 8), _e("bomber", 12), _e("manager", 16)], 0.3)
		24: return _w([_e("bomber", 16), _e("mega", 6), _e("hoa", 16)], 0.28)          # Bomber chaos
		25: return _w([_e("manager", 16), _e("hoa", 14), _e("mega", 6), _e("witch", 4)], 0.35) # Introduce witches!
		26: return _w([_e("witch", 8), _e("mega", 8), _e("hoa", 16), _e("manager", 16)], 0.3)
		27: return _w([_e("hoa", 20), _e("mega", 10), _e("witch", 8), _e("bomber", 10)], 0.28)
		28: return _w([_e("witch", 12), _e("mega", 10), _e("hoa", 18), _e("manager", 20)], 0.25)
		29: return _w([_e("mega", 12), _e("witch", 10), _e("bomber", 14), _e("hoa", 18)], 0.22)
		30: return _w([_e("mega", 8), _e("witch", 8), _e("hoa", 14), _e("president", 2)], 0.3) # W2 finale: presidents!

		# === WORLD 3: Jungle Base (Waves 31-50) ===
		# Mastery arc — brutal combos, presidents, final boss
		31: return _w([_e("hoa", 20), _e("mega", 10), _e("witch", 12), _e("bomber", 12)], 0.25)
		32: return _w([_e("manager", 22), _e("hoa", 20), _e("mega", 12), _e("witch", 10)], 0.25)
		33: return _w([_e("witch", 16), _e("mega", 12), _e("bomber", 14), _e("hoa", 18)], 0.22)
		34: return _w([_e("hoa", 22), _e("mega", 14), _e("witch", 14), _e("manager", 18)], 0.2)
		35: return _w([_e("mega", 16), _e("witch", 14), _e("bomber", 16), _e("hoa", 20)], 0.2)
		36: return _w([_e("witch", 18), _e("mega", 14), _e("hoa", 22), _e("bomber", 14)], 0.2)
		37: return _w([_e("mega", 18), _e("witch", 18), _e("hoa", 20), _e("bomber", 14)], 0.18)
		38: return _w([_e("bomber", 20), _e("witch", 16), _e("mega", 16), _e("hoa", 22)], 0.18) # Bomber hell
		39: return _w([_e("mega", 20), _e("witch", 20), _e("hoa", 24), _e("bomber", 14)], 0.18)
		40: return _w([_e("president", 3), _e("mega", 14), _e("witch", 14), _e("hoa", 16)], 0.25) # Presidents arrive
		41: return _w([_e("mega", 16), _e("witch", 16), _e("president", 3), _e("bomber", 14)], 0.2)
		42: return _w([_e("hoa", 22), _e("mega", 16), _e("witch", 16), _e("president", 4)], 0.2)
		43: return _w([_e("mega", 20), _e("witch", 20), _e("president", 4), _e("bomber", 16)], 0.18)
		44: return _w([_e("president", 6), _e("mega", 18), _e("witch", 18), _e("hoa", 20)], 0.18)
		45: return _w([_e("mega", 22), _e("witch", 22), _e("president", 6), _e("bomber", 16)], 0.16)
		46: return _w([_e("president", 8), _e("mega", 20), _e("witch", 20), _e("hoa", 24)], 0.16)
		47: return _w([_e("mega", 24), _e("witch", 24), _e("president", 8), _e("bomber", 18)], 0.15)
		48: return _w([_e("president", 10), _e("mega", 24), _e("witch", 22), _e("hoa", 26)], 0.15) # Pre-boss gauntlet
		49: return _w([_e("mega", 26), _e("witch", 26), _e("president", 10), _e("bomber", 20)], 0.14) # Final gauntlet
		50: return _w([_e("boss", 1), _e("president", 6), _e("mega", 12), _e("witch", 12)], 0.3) # FINAL BOSS

		_: # Beyond 50, scale infinitely with all enemy types
			var n = wave_number - 50
			return _w([
				_e("mega", 16 + n * 2),
				_e("witch", 16 + n * 2),
				_e("president", 4 + n),
				_e("bomber", 10 + n),
			], maxf(0.1, 0.15 - n * 0.002))

static func _w(enemies: Array, spawn_delay: float) -> Dictionary:
	return {"enemies": enemies, "spawn_delay": spawn_delay}

static func _e(type: String, count: int) -> Dictionary:
	return {"type": type, "count": count}
