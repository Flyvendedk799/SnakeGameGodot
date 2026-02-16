class_name CheckpointManager
extends Node

var game = null
var current_index: int = -1
var last_position: Vector2 = Vector2.ZERO
var shop_open_from_checkpoint: bool = false
var respawn_enabled: bool = true
var respawn_hp_ratio: float = 0.5
var respawn_gold_penalty_ratio: float = 0.15

var recent_respawn_timer: float = 0.0
var checkpoint_visit_count: int = 0

func setup(game_ref):
	game = game_ref
	respawn_enabled = true
	var cfg = game.map.level_config
	respawn_hp_ratio = cfg.get("respawn_hp_ratio", 0.5)
	respawn_gold_penalty_ratio = cfg.get("respawn_gold_penalty_ratio", 0.15)
	current_index = -1
	last_position = game.player_node.position
	recent_respawn_timer = 0.0
	checkpoint_visit_count = 0

func update(delta: float):
	if game == null or game.map == null:
		return
	recent_respawn_timer = maxf(0.0, recent_respawn_timer - delta)
	var player_pos = game.player_node.position
	if game.player_node.is_dead:
		return

	var cp_idx = game.map.get_checkpoint_index_at(player_pos)
	if cp_idx >= 0 and cp_idx > current_index:
		_trigger_checkpoint(cp_idx)

func get_recent_respawn_pressure() -> float:
	return clampf(recent_respawn_timer / 20.0, 0.0, 1.0)

func _trigger_checkpoint(index: int):
	current_index = index
	last_position = game.map.get_checkpoint_position(index)
	checkpoint_visit_count += 1

	# Difficulty + modifier integrated checkpoint policy: alternate heal/shop tradeoffs.
	var base_heal_ratio: float = 1.0
	if index >= 0 and index < game.map.checkpoints.size():
		base_heal_ratio = game.map.checkpoints[index].get("heal_ratio", 1.0)
	var allow_heal = game.should_allow_checkpoint_heal() if game.has_method("should_allow_checkpoint_heal") else true
	var full_heal_mode = (checkpoint_visit_count % 2) == 1
	if not allow_heal:
		base_heal_ratio = 0.0
	elif full_heal_mode:
		base_heal_ratio *= 1.0
		game.economy.shop_discount_mult = 1.15  # Full heal costs shopping power.
	else:
		base_heal_ratio *= 0.55
		game.economy.shop_discount_mult = 0.82  # Riskier heal grants better prices.

	if base_heal_ratio > 0:
		game.player_node.heal(int(game.player_node.max_hp * base_heal_ratio))
		if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
			game.player2_node.heal(int(game.player2_node.max_hp * base_heal_ratio))

	if game.spawn_director:
		game.spawn_director.start_recovery_window(8.5 if full_heal_mode else 11.0)

	# AAA Visual Overhaul: Checkpoint camera pull-back (subtle zoom-out for breathing room)
	if game.has_method("trigger_camera_zoom_pulse"):
		game.trigger_camera_zoom_pulse(3.0)  # Gentle zoom-out pulse
	if game.post_process:
		game.post_process.trigger_bloom_boost(0.2)  # Subtle glow on checkpoint reach

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

	recent_respawn_timer = 20.0
	if game.spawn_director:
		game.spawn_director.start_recovery_window(10.0)

	game.player_node.position = last_position
	game.player_node.is_dead = false
	game.player_node.visible = true
	game.player_node.current_hp = int(game.player_node.max_hp * respawn_hp_ratio)
	game.player_node.invincibility_timer = 1.0

	# Difficulty-sensitive respawn tax. Nightmare hits economy harder.
	var penalty_scale = 1.0
	if DifficultyManager.current_difficulty == DifficultyManager.DifficultyMode.HARD:
		penalty_scale = 1.2
	elif DifficultyManager.current_difficulty == DifficultyManager.DifficultyMode.NIGHTMARE:
		penalty_scale = 1.5
	var effective_penalty = clampf(respawn_gold_penalty_ratio * penalty_scale, 0.0, 0.9)
	game.economy.p1_gold = int(game.economy.p1_gold * (1.0 - effective_penalty))

	if game.p2_joined and game.player2_node:
		game.player2_node.position = last_position + Vector2(40, 0)
		game.player2_node.is_dead = false
		game.player2_node.visible = true
		game.player2_node.current_hp = int(game.player2_node.max_hp * respawn_hp_ratio)
		game.player2_node.invincibility_timer = 1.0
		game.economy.p2_gold = int(game.economy.p2_gold * (1.0 - effective_penalty))

	for ally in game.ally_container.get_children():
		ally.position = last_position + Vector2(randf_range(-40, 40), randf_range(-20, 20))
		ally.rally_point = last_position
		if ally.current_hp <= 0:
			ally.current_hp = ally.max_hp
			ally.state = AllyEntity.AllyState.IDLE
