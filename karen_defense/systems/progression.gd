class_name Progression
extends Node

var game = null
# Per-player: index 0 = P1, 1 = P2
var xp: Array = [0, 0]
var level: Array = [1, 1]
var skills_picked: Array = [[], []]  # skills_picked[0] = P1, skills_picked[1] = P2
var pending_level_ups: Array = []  # queue of player_index (0 or 1) who leveled up

func setup(game_ref):
	game = game_ref

func reset():
	xp = [0, 0]
	level = [1, 1]
	skills_picked = [[], []]
	pending_level_ups.clear()

func _get_player(player_index: int):
	if player_index == 1 and game.p2_joined and game.player2_node:
		return game.player2_node
	return game.player_node

func add_xp_for_player(player_index: int, amount: int):
	var p = _get_player(player_index)
	var mult = p.xp_mult if p else 1.0
	var idx = clampi(player_index, 0, 1)
	xp[idx] += int(amount * mult)
	while xp[idx] >= xp_for_next_level(idx):
		_level_up(idx)

func add_xp(amount: int):
	add_xp_for_player(0, amount)

func xp_for_next_level(player_index: int = 0) -> int:
	var idx = clampi(player_index, 0, 1)
	return level[idx] * level[idx] * 30 + 20

func xp_progress(player_index: int = 0) -> float:
	var idx = clampi(player_index, 0, 1)
	var needed = xp_for_next_level(idx)
	return float(xp[idx]) / float(needed)

func get_level(player_index: int = 0) -> int:
	return level[clampi(player_index, 0, 1)]

func get_skills_picked(player_index: int = 0) -> Array:
	return skills_picked[clampi(player_index, 0, 1)]

func _level_up(player_index: int):
	var idx = clampi(player_index, 0, 1)
	xp[idx] -= xp_for_next_level(idx)
	level[idx] += 1
	pending_level_ups.append(idx)
	if game.sfx:
		game.sfx.play_level_up()

func consume_level_up() -> int:
	if pending_level_ups.size() > 0:
		return pending_level_ups.pop_front()
	return -1

func pick_skill(skill_id: String, player_index: int = 0):
	var idx = clampi(player_index, 0, 1)
	skills_picked[idx].append(skill_id)
	var p = _get_player(player_index)
	if p:
		p.apply_skill(skill_id, game)
