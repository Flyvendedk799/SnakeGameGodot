class_name CheckpointManager
extends Node

var game = null
var current_index: int = -1
var last_position: Vector2 = Vector2.ZERO
var shop_open_from_checkpoint: bool = false
var respawn_enabled: bool = true
var respawn_hp_ratio: float = 0.5
var respawn_gold_penalty_ratio: float = 0.15

func setup(game_ref):
	game = game_ref
	respawn_enabled = true
	var cfg = game.map.level_config
	respawn_hp_ratio = cfg.get("respawn_hp_ratio", 0.5)
	respawn_gold_penalty_ratio = cfg.get("respawn_gold_penalty_ratio", 0.15)
	current_index = -1
	last_position = game.player_node.position

func update(delta: float):
	if game == null or game.map == null:
		return
	var player_pos = game.player_node.position
	if game.player_node.is_dead:
		return
	
	var cp_idx = game.map.get_checkpoint_index_at(player_pos)
	if cp_idx >= 0 and cp_idx > current_index:
		_trigger_checkpoint(cp_idx)

func _trigger_checkpoint(index: int):
	current_index = index
	last_position = game.map.get_checkpoint_position(index)
	# Heal players based on checkpoint's heal_ratio (default 1.0 = full heal)
	var heal_ratio: float = 1.0
	if index >= 0 and index < game.map.checkpoints.size():
		heal_ratio = game.map.checkpoints[index].get("heal_ratio", 1.0)
	if heal_ratio > 0:
		game.player_node.heal(int(game.player_node.max_hp * heal_ratio))
		if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
			game.player2_node.heal(int(game.player2_node.max_hp * heal_ratio))
	if not shop_open_from_checkpoint:
		shop_open_from_checkpoint = true
		game.shop_menu.show_menu(true)
	if game.sfx:
		game.sfx.play_wave_complete()

func on_shop_closed():
	shop_open_from_checkpoint = false

func respawn():
	if not respawn_enabled or game == null:
		return
	
	game.player_node.position = last_position
	game.player_node.is_dead = false
	game.player_node.visible = true
	game.player_node.current_hp = int(game.player_node.max_hp * respawn_hp_ratio)
	game.player_node.invincibility_timer = 1.0
	
	game.economy.p1_gold = int(game.economy.p1_gold * (1.0 - respawn_gold_penalty_ratio))
	
	if game.p2_joined and game.player2_node:
		game.player2_node.position = last_position + Vector2(40, 0)
		game.player2_node.is_dead = false
		game.player2_node.visible = true
		game.player2_node.current_hp = int(game.player2_node.max_hp * respawn_hp_ratio)
		game.player2_node.invincibility_timer = 1.0
		game.economy.p2_gold = int(game.economy.p2_gold * (1.0 - respawn_gold_penalty_ratio))
	
	for ally in game.ally_container.get_children():
		ally.position = last_position + Vector2(randf_range(-40, 40), randf_range(-20, 20))
		ally.rally_point = last_position
		if ally.current_hp <= 0:
			ally.current_hp = ally.max_hp
			ally.state = AllyEntity.AllyState.IDLE
