extends Node2D

const SCREEN_W = 1280
const SCREEN_H = 720

# AAA Camera Ease Functions
func ease_out_expo(x: float) -> float:
	return 1.0 if x >= 1.0 else 1.0 - pow(2.0, -10.0 * x)

func ease_out_spring(x: float, amplitude: float = 1.3, frequency: float = 3.0) -> float:
	return 1.0 - (cos(x * PI * frequency) * exp(-x * amplitude))

enum GameState { LEVEL_ACTIVE, CHECKPOINT_SHOP, PAUSED, LEVEL_UP, GAME_OVER, VICTORY, WAVE_ACTIVE = 0, TITLE = 99, WORLD_SELECT = 98, BETWEEN_WAVES = 6 }
var state: GameState = GameState.LEVEL_ACTIVE
var previous_state: GameState = GameState.LEVEL_ACTIVE

var map: LinearMap
var parallax_backdrop: ParallaxBackdrop = null
var player_node: PlayerEntity
var ally_container: Node2D
var enemy_container: Node2D
var projectile_container: Node2D
var gold_container: Node2D
var game_layer: Node2D
var entity_layer: Node2D

var spawn_director: SpawnDirector
var checkpoint_manager: CheckpointManager
var challenge_manager: ChallengeManager
var combat_system: CombatSystem
var economy: Economy
var progression: Progression
var building_manager: BuildingManager
var unit_manager: UnitManager

var hud: HudDisplay
var fx_draw_node: FXDrawNode = null
var shop_menu: ShopMenu
var level_up_menu: LevelUpMenu
var pause_menu: PauseMenu
var game_over_screen: GameOverScreen

var sfx: KarenSfxPlayer
var fx_manager: FXManager  # AAA Upgrade: Unified FX coordinator
var particles: ParticleSystem
var game_camera: Camera2D = null
var camera_base_zoom: float = 1.0
var camera_rotation_angle: float = 0.28  # ~16 degrees - stronger 3D tilt for depth

var player2_node: PlayerEntity = null
var p2_joined: bool = false
var p2_join_flash_timer: float = 0.0
var ally_target_counts: Dictionary = {}
var damage_numbers: Array = []
var impact_flashes: Array = []  # AAA Upgrade: Brief white flashes at hit points
var time_elapsed: float = 0.0

enum ShakeCurve { LINEAR, EASE_OUT_QUAD, EASE_OUT_EXPO }
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var shake_curve: ShakeCurve = ShakeCurve.EASE_OUT_QUAD
var hitstop_timer: float = 0.0

# Camera zoom pulse (AAA upgrade)
var camera_zoom_pulse: float = 0.0  # -0.02 to +0.02 range
var camera_zoom_velocity: float = 0.0
const CAMERA_DEADZONE_X: float = 0.0  # Disabled - was causing stick/catch jitter near pit

# AAA Upgrade: Cinematic camera enhancements
var camera_tilt: float = 0.0  # Dynamic rotation based on movement
var camera_tilt_velocity: float = 0.0
var camera_combat_offset: Vector2 = Vector2.ZERO  # Frame enemies during combat
var camera_vertical_offset: float = 0.0  # Enhanced vertical positioning
const CAMERA_TILT_MAX: float = 0.08  # ~4.5 degrees max tilt
const CAMERA_LOOKAHEAD_MAX: float = 180.0  # More aggressive lookahead
const CAMERA_DEADZONE_Y: float = 0.0
var _camera_target_smooth: Vector2 = Vector2.ZERO
var _camera_smooth_ready: bool = false
var _debug_camera_timer: float = 0.0
var _debug_cam_target: Vector2 = Vector2.ZERO
var _debug_cam_smooth: Vector2 = Vector2.ZERO
var _debug_cam_effective: Vector2 = Vector2.ZERO
var radar_reveal_timer: float = 0.0  # HUD minimap compatibility (Karen Defense radar)
var combo_meter: float = 0.0  # HUD combo display compatibility (Karen Defense)
var combo_level: int = 0
var combo_stats: Dictionary = {"mark_strike": 0, "supply_chain": 0, "emp_followup": 0}
var _redraw_accum: float = 0.0
var run_summary_timer: float = 10.0
var run_summary_line: String = ""

# FX / post-process (player.gd, enemy.gd, boss_manager.gd, FXDrawNode)
var chromatic_intensity: float = 0.0
var damage_flash_timer: float = 0.0
var damage_flash_color: Color = Color(1, 0.2, 0.2, 0.6)
var vignette_intensity: float = 0.0
var speed_line_intensity: float = 0.0
var level_intro_timer: float = 2.0
const REDRAW_INTERVAL: float = 1.0 / 60.0

var current_level_id: int = 1
var current_map_id: int = 1  # Alias for game_over_screen compatibility
var is_sideview_game: bool = true  # Main Game uses front-view platformer movement
var victory_display_timer: float = 0.0
var current_wave: int = 0  # Stub for HUD compatibility
var wave_complete_pending: bool = false  # Stub for HUD (Main Game has no waves)
var wave_announce_timer: float = 0.0
var enemies_killed_total: int = 0  # game_over_screen, enemy.gd
var total_gold_earned: int = 0  # game_over_screen
var companion_session = null  # Stub for HUD (Main Game has no companion)
var companion_action_feed: Array = []
var helicopter_entity = null

func _ready():
	particles = ParticleSystem.new()
	current_level_id = MainGameManager.current_level if MainGameManager.current_level > 0 else 1
	current_map_id = current_level_id
	_build_scene_tree()
	_setup_systems()
	state = GameState.LEVEL_ACTIVE
	_update_visibility()

func _build_scene_tree():
	game_layer = Node2D.new()
	game_layer.name = "GameLayer"
	add_child(game_layer)

	parallax_backdrop = ParallaxBackdrop.new()
	parallax_backdrop.name = "ParallaxBackdrop"
	game_layer.add_child(parallax_backdrop)

	map = LinearMap.new()
	map.name = "Map"
	game_layer.add_child(map)

	entity_layer = Node2D.new()
	entity_layer.name = "Entities"
	entity_layer.y_sort_enabled = true
	game_layer.add_child(entity_layer)

	ally_container = Node2D.new()
	ally_container.name = "Allies"
	ally_container.y_sort_enabled = true
	entity_layer.add_child(ally_container)

	enemy_container = Node2D.new()
	enemy_container.name = "Enemies"
	enemy_container.y_sort_enabled = true
	entity_layer.add_child(enemy_container)

	gold_container = Node2D.new()
	gold_container.name = "GoldDrops"
	gold_container.y_sort_enabled = true
	entity_layer.add_child(gold_container)

	projectile_container = Node2D.new()
	projectile_container.name = "Projectiles"
	game_layer.add_child(projectile_container)

	player_node = preload("res://karen_defense/entities/player.tscn").instantiate()
	player_node.name = "Player"
	entity_layer.add_child(player_node)

	game_camera = Camera2D.new()
	game_camera.name = "GameCamera"
	game_camera.position = Vector2(SCREEN_W / 2.0, SCREEN_H / 2.0)
	game_camera.zoom = Vector2(camera_base_zoom, camera_base_zoom)
	game_camera.enabled = true
	game_layer.add_child(game_camera)

	# Pure 2D side-scrolling POV (Shantae-style) - no perspective skew

	spawn_director = SpawnDirector.new()
	spawn_director.name = "SpawnDirector"
	add_child(spawn_director)

	checkpoint_manager = CheckpointManager.new()
	checkpoint_manager.name = "CheckpointManager"
	add_child(checkpoint_manager)

	challenge_manager = ChallengeManager.new()
	challenge_manager.name = "ChallengeManager"
	add_child(challenge_manager)

	combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	add_child(combat_system)

	economy = Economy.new()
	economy.name = "Economy"
	add_child(economy)

	progression = Progression.new()
	progression.name = "Progression"
	add_child(progression)

	building_manager = BuildingManager.new()
	building_manager.name = "BuildingManager"
	add_child(building_manager)

	unit_manager = UnitManager.new()
	unit_manager.name = "UnitManager"
	add_child(unit_manager)

	sfx = KarenSfxPlayer.new()
	sfx.name = "SFX"
	add_child(sfx)

	# AAA Upgrade: FX Manager for unified visual feedback
	fx_manager = FXManager.new()
	fx_manager.name = "FXManager"
	add_child(fx_manager)
	fx_manager.setup(self)

	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	hud = HudDisplay.new()
	hud.name = "HUD"
	ui_layer.add_child(hud)

	shop_menu = ShopMenu.new()
	shop_menu.name = "ShopMenu"
	ui_layer.add_child(shop_menu)

	level_up_menu = LevelUpMenu.new()
	level_up_menu.name = "LevelUpMenu"
	ui_layer.add_child(level_up_menu)

	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	ui_layer.add_child(pause_menu)

	game_over_screen = GameOverScreen.new()
	game_over_screen.name = "GameOverScreen"
	ui_layer.add_child(game_over_screen)

	var fx_layer = CanvasLayer.new()
	fx_layer.name = "FXLayer"
	fx_layer.layer = 15
	add_child(fx_layer)
	fx_draw_node = FXDrawNode.new()
	fx_draw_node.name = "FXDraw"
	fx_draw_node.game = self
	fx_layer.add_child(fx_draw_node)

	# ParticleSystem is RefCounted, not Node - used via particles.update() and particles.draw()

func _setup_systems():
	var used_custom = false
	# 1. Prefer node-based level (drag-and-drop) if it exists
	var node_path = LinearMapConfig.get_node_level_path(current_level_id)
	if not node_path.is_empty():
		var packed = load(node_path) as PackedScene
		if packed:
			var temp = packed.instantiate()
			if _has_level_nodes(temp):
				var config = NodeLevelLoader.get_level_config_from_nodes(temp)
				config["id"] = current_level_id
				config["name"] = LinearMapConfig.get_level(current_level_id).get("name", "Node Level")
				config["theme"] = LinearMapConfig.get_level(current_level_id).get("theme", "grass")
				map.setup_from_config(self, config)
				used_custom = true
			temp.queue_free()
	# 2. Fall back to TileMap level if no node-based level
	if not used_custom:
		var tilemap_path = LinearMapConfig.get_tilemap_level_path(current_level_id)
		if not tilemap_path.is_empty():
			var packed = load(tilemap_path) as PackedScene
			if packed:
				var temp = packed.instantiate()
				var tilemap = _find_tilemap(temp)
				if tilemap:
					var config = TileMapLevelLoader.get_level_config_from_tilemap(tilemap)
					config["id"] = current_level_id
					config["name"] = LinearMapConfig.get_level(current_level_id).get("name", "TileMap Level")
					config["theme"] = LinearMapConfig.get_level(current_level_id).get("theme", "grass")
					map.setup_from_config(self, config)
					used_custom = true
				temp.queue_free()
	if not used_custom:
		map.setup(self, current_level_id)
	if parallax_backdrop:
		var theme = map.level_config.get("theme", "grass")
		parallax_backdrop.setup(self, theme, map.level_width, map.level_height)
	economy.configure_for_map(map.level_config)
	game_camera.position = map.get_player_anchor()
	spawn_director.setup(self)
	checkpoint_manager.setup(self)
	challenge_manager.setup(self)
	_apply_pending_run_modifiers()
	combat_system.setup(self)
	progression.setup(self)
	building_manager.setup(self)
	unit_manager.setup(self)
	hud.setup(self)
	shop_menu.setup(self)
	level_up_menu.setup(self)
	pause_menu.setup(self)
	game_over_screen.setup(self)

	# Spawn on first walkable floor (supports floor_segments and layers)
	player_node.position = map.get_spawn_position()
	run_summary_line = get_run_summary_line()
	run_summary_timer = 11.0


func _apply_pending_run_modifiers():
	if challenge_manager == null:
		return
	challenge_manager.deactivate_all()
	if MainGameManager.use_daily_modifiers:
		for key in ChallengeManager.get_today_daily_modifiers():
			challenge_manager.activate_modifier(key)
	for key in MainGameManager.pending_modifiers:
		challenge_manager.activate_modifier(str(key))
	MainGameManager.pending_modifiers.clear()
	MainGameManager.use_daily_modifiers = false

func get_enemy_hp_multiplier() -> float:
	var challenge_mult = challenge_manager.get_enemy_hp_mult() if challenge_manager else 1.0
	return DifficultyManager.get_enemy_hp_mult() * challenge_mult

func get_enemy_damage_multiplier() -> float:
	var challenge_mult = challenge_manager.get_enemy_dmg_mult() if challenge_manager else 1.0
	return DifficultyManager.get_enemy_damage_mult() * challenge_mult

func get_gold_multiplier() -> float:
	var challenge_mult = challenge_manager.get_gold_mult() if challenge_manager else 1.0
	return DifficultyManager.get_gold_mult() * challenge_mult

func get_spawn_rate_multiplier() -> float:
	var challenge_mult = challenge_manager.get_spawn_mult() if challenge_manager else 1.0
	return DifficultyManager.get_spawn_rate_mult() * challenge_mult

func should_allow_checkpoint_heal() -> bool:
	if not DifficultyManager.heal_at_checkpoints():
		return false
	if challenge_manager and challenge_manager.is_heal_disabled():
		return false
	return true

func get_run_summary_line() -> String:
	var hp_pct = int((get_enemy_hp_multiplier() - 1.0) * 100.0)
	var dmg_pct = int((get_enemy_damage_multiplier() - 1.0) * 100.0)
	var gold_pct = int((1.0 - get_gold_multiplier()) * 100.0)
	var text = "%s: %+d%% enemy HP, %+d%% enemy damage, %d%% gold" % [DifficultyManager.get_difficulty_name(), hp_pct, dmg_pct, gold_pct]
	if challenge_manager and challenge_manager.active_modifiers.size() > 0:
		text += " | Mod bonus x%.2f" % challenge_manager.get_total_reward_mult()
	return text

func get_active_modifiers_label() -> String:
	if challenge_manager == null or challenge_manager.active_modifiers.is_empty():
		return ""
	var names = []
	for key in challenge_manager.active_modifiers:
		names.append(ChallengeManager.MODIFIERS.get(key, {}).get("name", key))
	return "Modifiers: %s" % ", ".join(names)

func should_show_run_summary() -> bool:
	return run_summary_timer > 0.0

func on_enemy_killed():
	if spawn_director:
		spawn_director.notify_enemy_killed()

func _has_level_nodes(node: Node) -> bool:
	if node is LevelFloorSegment or node is LevelPlatform or node is LevelCheckpoint or node is LevelGoal or node is LevelGrappleAnchor or node is LevelChainLink:
		return true
	for c in node.get_children():
		if _has_level_nodes(c):
			return true
	return false

func _find_tilemap(node: Node) -> TileMap:
	if node is TileMap:
		return node as TileMap
	for c in node.get_children():
		var found = _find_tilemap(c)
		if found:
			return found
	return null

func _update_visibility():
	game_layer.visible = state != GameState.GAME_OVER and state != GameState.VICTORY
	if game_camera:
		game_camera.enabled = game_layer.visible
	hud.visible = state == GameState.LEVEL_ACTIVE or state == GameState.CHECKPOINT_SHOP
	shop_menu.visible = shop_menu.active

func _process(delta):
	if hitstop_timer > 0:
		var real_delta = delta / maxf(Engine.time_scale, 0.01)
		hitstop_timer -= real_delta
		if hitstop_timer <= 0:
			Engine.time_scale = 1.0
		else:
			Engine.time_scale = 0.15
			_update_shake(delta)
			return

	match state:
		GameState.LEVEL_ACTIVE:
			_process_level_active(delta)
		GameState.CHECKPOINT_SHOP:
			_process_checkpoint_shop(delta)
		GameState.PAUSED:
			pass
		GameState.LEVEL_UP:
			pass
		GameState.GAME_OVER:
			pass
		GameState.VICTORY:
			victory_display_timer -= delta
			if victory_display_timer <= 0:
				_return_to_level_select()
			return

	_update_shake(delta)

	# Camera zoom pulse spring physics (AAA upgrade)
	if absf(camera_zoom_pulse) > 0.001:
		var spring_force = -camera_zoom_pulse * 25.0
		camera_zoom_velocity += spring_force * delta
		camera_zoom_velocity *= exp(-8.0 * delta)
		camera_zoom_pulse += camera_zoom_velocity * delta
	else:
		camera_zoom_pulse = 0.0
		camera_zoom_velocity = 0.0

	if chromatic_intensity > 0.05:
		chromatic_intensity = lerpf(chromatic_intensity, 0.0, delta * 8.0)
	# AAA Upgrade: Decay bloom intensity
	if fx_draw_node and fx_draw_node.bloom_intensity > 0.05:
		fx_draw_node.bloom_intensity = lerpf(fx_draw_node.bloom_intensity, 0.0, delta * 4.0)
	if level_intro_timer > 0:
		level_intro_timer -= delta
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
	if state == GameState.LEVEL_ACTIVE:
		run_summary_timer = maxf(0.0, run_summary_timer - delta)
		_update_linear_camera(delta)
		_debug_camera_timer += delta
		if _debug_camera_timer >= 5.0:
			_debug_camera_timer = 0.0
			_log_camera_snapshot(delta)
	map.anim_time += delta
	if map:
		map.queue_redraw()
	if fx_draw_node:
		fx_draw_node.queue_redraw()
	_update_visibility()
	_redraw_accum += delta
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()

func _process_level_active(delta):
	time_elapsed += delta
	if p2_join_flash_timer > 0:
		p2_join_flash_timer -= delta

	if shop_menu.active:
		state = GameState.CHECKPOINT_SHOP
		return

	if not player_node.is_dead:
		player_node.update_player(delta, self)
	if p2_joined and player2_node and not player2_node.is_dead:
		player2_node.update_player(delta, self)

	ally_target_counts.clear()
	var allies = ally_container.get_children()
	for ally in allies:
		var t = ally.get("target_enemy")
		if t != null and is_instance_valid(t):
			ally_target_counts[t] = ally_target_counts.get(t, 0) + 1
	for ally in allies:
		ally.update_ally(delta, self)

	# Reset pathfinding budget each frame (limits A* runs to prevent 1 FPS freeze)
	EnemyEntity._pathfind_budget = 3
	var enemies = enemy_container.get_children()
	for enemy in enemies:
		enemy.update_enemy(delta, self)

	var projs = projectile_container.get_children()
	for proj in projs:
		if proj is GrenadeEntity:
			if proj.update_grenade(delta, self):
				if proj.owner_player and is_instance_valid(proj.owner_player):
					proj.owner_player.on_grenade_removed()
				proj.queue_free()
		elif proj is ExplosionEffect:
			if proj.update_effect(delta):
				proj.queue_free()
		else:
			proj.update_projectile(delta)

	var gold_drops = gold_container.get_children()
	for gold in gold_drops:
		gold.update_drop(delta)

	combat_system.resolve_frame(delta)
	particles.update(delta)
	_update_damage_numbers(delta)
	_update_impact_flashes(delta)

	checkpoint_manager.update(delta)
	spawn_director.update(delta)
	total_gold_earned = economy.p1_gold + economy.p2_gold

	if map.is_in_goal(player_node.position) or (p2_joined and player2_node and map.is_in_goal(player2_node.position)):
		_on_level_complete()
		return

	if Input.is_action_just_pressed("regroup"):
		unit_manager.regroup_all()

	check_all_players_dead()

func _process_checkpoint_shop(delta):
	particles.update(delta)
	time_elapsed += delta
	if not shop_menu.active:
		checkpoint_manager.on_shop_closed()
		state = GameState.LEVEL_ACTIVE

func _update_linear_camera(delta: float):
	var p1 = player_node
	var p2 = player2_node if (p2_joined and player2_node and not player2_node.is_dead) else null
	var target: Vector2
	var zoom_target = Vector2(camera_base_zoom, camera_base_zoom)

	if p2 != null:
		var mid = (p1.position + p2.position) * 0.5
		var spread_x = absf(p1.position.x - p2.position.x)
		var spread_y = absf(p1.position.y - p2.position.y)
		var lookahead_anchor = p2 if p2.position.x > p1.position.x else p1
		var lookahead_x = 80.0 if lookahead_anchor.last_move_dir.x > 0.1 else -50.0
		target = Vector2(mid.x + lookahead_x, mid.y - 20.0)  # Slight upward bias
		# Zoom out when players are spread so both fit on screen
		var zoom_out = clampf((spread_x + spread_y) / 400.0, 0.0, 0.35)
		zoom_target = Vector2(camera_base_zoom + zoom_out, camera_base_zoom + zoom_out)
	else:
		# AAA Upgrade: Cinematic predictive camera system
		var anchor = p1

		# Enhanced velocity-based horizontal lookahead: MORE aggressive (60-180 range)
		var vel_x = anchor.velocity.x if anchor else 0.0
		var speed = absf(vel_x)
		var lookahead_x = sign(vel_x) * clampf(speed / 2.5, 60.0, CAMERA_LOOKAHEAD_MAX)

		# AAA Upgrade: Add facing-based offset even when stationary
		if speed < 50 and anchor:
			var facing_dir = 1.0 if anchor.facing_angle > -PI/2 and anchor.facing_angle < PI/2 else -1.0
			lookahead_x = facing_dir * 70.0  # Look ahead of where player faces

		# AAA Upgrade: Enhanced vertical framing with more dramatic positioning
		var vel_y = anchor.velocity.y if anchor else 0.0
		var lookahead_y = 0.0
		camera_vertical_offset = lerpf(camera_vertical_offset, 0.0, delta * 3.0)

		if vel_y < -250:  # Jumping - show MUCH more above
			lookahead_y = -60.0
			camera_vertical_offset = -20.0
		elif vel_y > 350:  # Falling fast - show more below
			lookahead_y = 50.0
			camera_vertical_offset = 15.0
		elif anchor.is_on_ground:
			lookahead_y = 15.0  # Ground bias - show more above when grounded

		# AAA Upgrade: Combat-aware framing - include nearest enemies
		var combat_frame = Vector2.ZERO
		if anchor.is_attacking_melee or anchor.is_dashing:
			var nearest_enemy = _get_nearest_enemy_in_range(anchor.position, 200.0)
			if nearest_enemy:
				var to_enemy = nearest_enemy.position - anchor.position
				combat_frame = to_enemy * 0.15  # Frame 15% toward enemy
		camera_combat_offset = camera_combat_offset.lerp(combat_frame, delta * 4.0)

		var target_y = anchor.position.y + lookahead_y + camera_vertical_offset
		# Use ground surface Y when grounded - eliminates pit/edge jitter from collision bounce
		if anchor.is_on_ground and map.has_method("get_ground_surface_y"):
			var surface_y = map.get_ground_surface_y(anchor.position, 26.0)
			if surface_y < INF:
				target_y = surface_y - 26.0 + lookahead_y + camera_vertical_offset

		target = Vector2(anchor.position.x + lookahead_x, target_y) + camera_combat_offset

	var half_w = (get_viewport_rect().size.x / 2.0) / maxf(zoom_target.x, 0.1)
	var half_h = (get_viewport_rect().size.y / 2.0) / maxf(zoom_target.y, 0.1)
	target.x = clampf(target.x, half_w, map.level_width - half_w)
	target.y = clampf(target.y, half_h, map.level_height - half_h)

	# AAA Upgrade: Enhanced cinematic smoothing with dual-stage easing
	const SMOOTH_X = 0.35  # Looser for more fluid motion
	const SMOOTH_Y = 0.25  # Less rigid vertical tracking
	if not _camera_smooth_ready:
		_camera_target_smooth = target
		_camera_smooth_ready = true
	else:
		# Smoothstep for more cinematic easing
		var smooth_x = smoothstep(0.0, 1.0, SMOOTH_X)
		var smooth_y = smoothstep(0.0, 1.0, SMOOTH_Y)
		_camera_target_smooth.x = lerpf(_camera_target_smooth.x, target.x, smooth_x)
		_camera_target_smooth.y = lerpf(_camera_target_smooth.y, target.y, smooth_y)

	var effective_target = _camera_target_smooth

	# AAA Upgrade: Action-based dynamic zoom
	var action_zoom = 1.0
	if p1 and not p1.is_dead:
		# Zoom out when sprinting for speed emphasis
		if p1.is_sprinting and absf(p1.velocity.x) > 200:
			action_zoom += 0.08
		# Zoom in slightly during combat for intensity
		elif p1.is_attacking_melee:
			action_zoom -= 0.03
		# Zoom out during ground pound fall
		elif p1.get("is_ground_pounding") and p1.is_ground_pounding:
			action_zoom += 0.12

	# Apply zoom pulse and action zoom to zoom target
	var pulse_zoom = Vector2(1.0 + camera_zoom_pulse, 1.0 + camera_zoom_pulse)
	var dynamic_zoom = Vector2(action_zoom, action_zoom)
	zoom_target *= pulse_zoom * dynamic_zoom

	# Cap delta to prevent camera jumpiness during frame drops (e.g. when jumping right)
	var safe_delta = minf(delta, 0.05)
	# Slower vertical follow: dampen during jumps, extra dampen when grounded (platform/pit edges)
	var y_speed_mult = 1.0
	if p1 and not p1.is_dead:
		if absf(p1.velocity.y) > 150:
			y_speed_mult = 0.6  # Jumps/falls
		elif p1.is_on_ground:
			y_speed_mult = 0.45  # Grounded - very slow Y follow for stable camera near pits
	var follow_speed = 8.0
	var ease_x = ease_out_expo(safe_delta * follow_speed)
	var ease_y = ease_out_expo(safe_delta * follow_speed * y_speed_mult)
	var new_x = lerpf(game_camera.position.x, effective_target.x, ease_x)
	var new_y = lerpf(game_camera.position.y, effective_target.y, ease_y)
	game_camera.position = Vector2(new_x, new_y)

	# Store for debug snapshot
	_debug_cam_target = target
	_debug_cam_smooth = _camera_target_smooth
	_debug_cam_effective = effective_target

	# Zoom with spring ease (use safe_delta to avoid jerk during frame drops)
	var zoom_ease = ease_out_spring(safe_delta * 5.0)
	game_camera.zoom = game_camera.zoom.lerp(zoom_target, zoom_ease)

	# AAA Upgrade: Dynamic camera tilt based on velocity for cinematic feel
	var target_tilt = 0.0
	if p1 and not p1.is_dead:
		# Tilt camera in direction of fast movement (like car racing games)
		var vel_x = p1.velocity.x
		if absf(vel_x) > 150:
			target_tilt = -sign(vel_x) * clampf(absf(vel_x) / 600.0, 0.0, 1.0) * CAMERA_TILT_MAX
		# Extra tilt during dash for emphasis
		if p1.is_dashing:
			target_tilt *= 1.8
	# Spring physics for smooth tilt
	var tilt_force = (target_tilt - camera_tilt) * 25.0
	camera_tilt_velocity += tilt_force * delta
	camera_tilt_velocity *= exp(-15.0 * delta)  # Dampening
	camera_tilt += camera_tilt_velocity * delta
	game_camera.rotation = camera_tilt

func _get_nearest_enemy_in_range(from_pos: Vector2, max_range: float):
	"""AAA Upgrade: Find nearest enemy for combat-aware camera framing."""
	var nearest = null
	var nearest_dist_sq = max_range * max_range
	var candidates = enemy_container.get_children()
	for enemy in candidates:
		if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
			continue
		var dist_sq = from_pos.distance_squared_to(enemy.position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = enemy
	return nearest

func _log_camera_snapshot(delta: float):
	var dl = get_node_or_null("/root/DebugLogger")
	if not dl:
		return
	var p = player_node
	var px = p.position.x if p else 0.0
	var py = p.position.y if p else 0.0
	var vx = p.velocity.x if p else 0.0
	var vy = p.velocity.y if p else 0.0
	var fps = Engine.get_frames_per_second()
	var pt_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var buf = []
	buf.append("--- Main Game Snapshot ---")
	buf.append("FPS: %d  Process: %.1f ms  Delta: %.4f" % [fps, pt_ms, delta])
	buf.append("Camera: (%.0f, %.0f)  Player: (%.1f, %.1f)  Vel: (%.1f, %.1f)" % [game_camera.position.x, game_camera.position.y, px, py, vx, vy])
	buf.append("Target: (%.1f, %.1f)  Smoothed: (%.1f, %.1f)  Effective: (%.1f, %.1f)" % [_debug_cam_target.x, _debug_cam_target.y, _debug_cam_smooth.x, _debug_cam_smooth.y, _debug_cam_effective.x, _debug_cam_effective.y])
	var grounded = p.is_on_ground if p else false
	buf.append("Grounded: %s  Using ground-surface Y for cam: %s" % [grounded, grounded and map.has_method("get_ground_surface_y")])
	buf.append("Entities: allies=%d enemies=%d projs=%d" % [ally_container.get_child_count(), enemy_container.get_child_count(), projectile_container.get_child_count()])
	for line in buf:
		dl.write_log(line)

func _on_level_complete():
	state = GameState.VICTORY
	victory_display_timer = 3.0
	if sfx:
		sfx.play_wave_complete()
	if SaveManager:
		var progress = SaveManager.load_main_game_progress()
		SaveManager.complete_level(current_level_id, progress)
	game_over_screen.show_menu(true)

func check_all_players_dead():
	var p1_dead = player_node.is_dead
	var p2_dead = not p2_joined or (player2_node != null and player2_node.is_dead)
	if p1_dead and p2_dead:
		if checkpoint_manager.respawn_enabled:
			checkpoint_manager.respawn()
		else:
			trigger_game_over()

func trigger_game_over():
	state = GameState.GAME_OVER
	Engine.time_scale = 1.0
	hitstop_timer = 0.0
	game_over_screen.show_menu(false)

func resume_from_shop():
	state = GameState.LEVEL_ACTIVE
	shop_menu.hide_menu()
	checkpoint_manager.on_shop_closed()

func start_hitstop(duration: float, intensity: float = 1.0):
	"""AAA Upgrade: Enhanced hitstop with variable intensity.
	intensity: 0.5 (light) to 2.0 (heavy) - affects timescale."""
	# Skip hitstop if duration is too small (< 10ms)
	if duration < 0.01:
		return
	hitstop_timer = duration
	var timescale = lerpf(0.25, 0.05, clampf(intensity - 0.5, 0.0, 1.5) / 1.5)
	Engine.time_scale = timescale

func trigger_bloom(intensity: float = 1.0):
	"""AAA Upgrade: Trigger bloom glow effect."""
	if fx_draw_node:
		fx_draw_node.bloom_intensity = intensity

func trigger_camera_zoom_pulse(strength: float):
	"""AAA Upgrade: Trigger camera FOV pulse. Negative = zoom out, positive = zoom in."""
	camera_zoom_pulse += strength * 0.01  # Scale to -0.02 to +0.02 range
	camera_zoom_pulse = clampf(camera_zoom_pulse, -0.04, 0.04)

func spawn_damage_number(pos: Vector2, text: String, color: Color, use_bounce: bool = false):
	"""AAA Upgrade: Enhanced with optional spring bounce physics."""
	if damage_numbers.size() >= 40:
		damage_numbers.pop_front()

	var number_data = {
		"position": pos + Vector2(randf_range(-12, 12), -10),
		"text": text,
		"color": color,
		"timer": 0.9,
		"velocity_y": -80.0,
		"scale": 2.2,
		"rotation": randf_range(-0.15, 0.15),
		"drift_phase": randf_range(0, TAU),
		"drift_speed": randf_range(2.0, 4.0),
	}

	# AAA Upgrade: Bounce physics for impactful hits
	if use_bounce:
		number_data["bounce_velocity"] = Vector2(randf_range(-40, 40), -150.0)
		number_data["bounce_gravity"] = 300.0
		number_data["bounce_dampening"] = 0.6
		number_data["bounce_pos_offset"] = Vector2.ZERO

	damage_numbers.append(number_data)

func spawn_impact_flash(pos: Vector2, duration: float = 0.15, color: Color = Color.WHITE):
	"""AAA Upgrade: Spawn a brief flash at impact point for visual punch."""
	if impact_flashes.size() >= 20:
		impact_flashes.pop_front()
	impact_flashes.append({
		"position": pos,
		"timer": duration,
		"max_duration": duration,
		"color": color,
		"radius_start": 10.0,
		"radius_end": 40.0,
	})

func start_shake(intensity: float, duration: float, curve: ShakeCurve = ShakeCurve.EASE_OUT_QUAD):
	"""AAA Upgrade: Enhanced screen shake with decay curves."""
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shake_curve = curve

func trigger_landing_impact():
	"""Called by player on hard landings - screen shake for juice."""
	start_shake(5.0, 0.1)

func start_chromatic(intensity: float):
	chromatic_intensity = maxf(chromatic_intensity, intensity)

func _update_shake(delta):
	if shake_timer > 0:
		shake_timer -= delta
		var t = shake_timer / shake_duration

		# AAA Upgrade: Apply curve to shake decay
		var progress = t
		match shake_curve:
			ShakeCurve.EASE_OUT_QUAD:
				progress = t * t
			ShakeCurve.EASE_OUT_EXPO:
				progress = pow(2.0, -10.0 * (1.0 - t)) if t < 1.0 else 0.0
			_:  # LINEAR
				progress = t

		var ci = shake_intensity * progress
		shake_offset = Vector2(randf_range(-ci, ci), randf_range(-ci, ci))
		game_layer.position = shake_offset
	else:
		shake_offset = Vector2.ZERO
		game_layer.position = Vector2.ZERO

func _update_damage_numbers(delta: float):
	var i = damage_numbers.size() - 1
	while i >= 0:
		var dn = damage_numbers[i]
		dn.timer -= delta

		# AAA Upgrade: Spring bounce physics for impactful hits
		if dn.has("bounce_velocity"):
			dn.bounce_velocity.y += dn.bounce_gravity * delta
			dn.bounce_pos_offset += dn.bounce_velocity * delta
			# Simple ground bounce
			if dn.bounce_pos_offset.y > 0:
				dn.bounce_pos_offset.y = 0
				dn.bounce_velocity.y = -dn.bounce_velocity.y * dn.bounce_dampening
				dn.bounce_velocity.x *= dn.bounce_dampening
		else:
			# Standard vertical rise
			dn.position.y += dn.velocity_y * delta

		if dn.timer <= 0:
			damage_numbers.remove_at(i)
		i -= 1

func _update_impact_flashes(delta: float):
	"""AAA Upgrade: Update brief impact flashes for visual punch."""
	var i = impact_flashes.size() - 1
	while i >= 0:
		var flash = impact_flashes[i]
		flash.timer -= delta
		if flash.timer <= 0:
			impact_flashes.remove_at(i)
		i -= 1

func resume_from_level_up():
	state = previous_state

func unpause():
	state = previous_state
	Engine.time_scale = 1.0
	hitstop_timer = 0.0
	if sfx:
		sfx.play_pause()

func _return_to_level_select():
	get_tree().change_scene_to_file("res://main_game/ui/world_map.tscn")

func _input(event):
	if state == GameState.GAME_OVER or state == GameState.VICTORY:
		if game_over_screen.handle_input(event):
			return
		if event.is_action_pressed("confirm"):
			if state == GameState.VICTORY:
				_return_to_level_select()
			else:
				restart_level()
			return

	if state == GameState.PAUSED:
		if pause_menu.handle_input(event):
			return

	if state == GameState.LEVEL_UP:
		if level_up_menu.handle_input(event):
			return

	if state == GameState.LEVEL_ACTIVE or state == GameState.CHECKPOINT_SHOP:
		if shop_menu.handle_input(event):
			return

	if not p2_joined and state != GameState.GAME_OVER and state != GameState.VICTORY:
		if event.is_action_pressed("p2_join"):
			_spawn_player2()
			return

	if state == GameState.LEVEL_ACTIVE and event.is_action_pressed("pause"):
		previous_state = state
		state = GameState.PAUSED
		pause_menu.show_menu()
		if sfx:
			sfx.play_pause()
	elif state == GameState.PAUSED and event.is_action_pressed("pause"):
		pause_menu.hide_menu()
		unpause()

func _spawn_player2():
	player2_node = preload("res://karen_defense/entities/player.tscn").instantiate()
	player2_node.action_prefix = "p2_"
	player2_node.player_index = 1
	player2_node.name = "Player2"
	player2_node.position = map.get_player_anchor() + Vector2(40, 0)
	entity_layer.add_child(player2_node)
	p2_joined = true
	p2_join_flash_timer = 0.6

func restart_level():
	get_tree().reload_current_scene()

func restart_game(_restore_map_id: int = -1):
	restart_level()

func _draw():
	particles.draw(self)
	if damage_numbers.size() > 0:
		var font = ThemeDB.fallback_font
		for dn in damage_numbers:
			var alpha = clampf(dn.timer / 0.3, 0.0, 1.0)
			var col = dn.color
			col.a = alpha
			var drift_x = sin(time_elapsed * dn.get("drift_speed", 3.0) + dn.get("drift_phase", 0.0)) * 8.0
			# AAA Upgrade: Add bounce offset for spring physics
			var bounce_offset = dn.get("bounce_pos_offset", Vector2.ZERO)
			var pos = dn.position + shake_offset + Vector2(drift_x, 0) + bounce_offset
			var life_frac = clampf(dn.timer / 0.9, 0.0, 1.0)
			var sc = lerpf(1.0, dn.get("scale", 2.0), clampf(life_frac * 2.0, 0.0, 1.0))
			var rot = dn.get("rotation", 0.0)
			draw_set_transform(pos, rot, Vector2(sc, sc))
			draw_string(font, Vector2(1, 1), dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0, 0, 0, alpha * 0.6))
			draw_string(font, Vector2.ZERO, dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# AAA Upgrade: Draw impact flashes for visual punch
	for flash in impact_flashes:
		var t = 1.0 - (flash.timer / flash.max_duration)  # 0 to 1
		var radius = lerpf(flash.radius_start, flash.radius_end, t)
		var alpha = 1.0 - t  # Fade out
		var col = flash.color
		col.a = alpha * 0.4
		var pos = flash.position + shake_offset
		# Draw expanding flash ring
		draw_circle(pos, radius, col)
		# Brighter center
		draw_circle(pos, radius * 0.5, Color(col.r, col.g, col.b, alpha * 0.6))
