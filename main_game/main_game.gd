extends Node2D

const SCREEN_W = 1280
const SCREEN_H = 720

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
var particles: ParticleSystem
var game_camera: Camera2D = null
var camera_base_zoom: float = 1.0
var camera_rotation_angle: float = 0.15  # ~8.6 degrees - subtle tilt for depth (was 0.35, too much)

var player2_node: PlayerEntity = null
var p2_joined: bool = false
var p2_join_flash_timer: float = 0.0
var ally_target_counts: Dictionary = {}
var damage_numbers: Array = []
var time_elapsed: float = 0.0

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var hitstop_timer: float = 0.0
var radar_reveal_timer: float = 0.0  # HUD minimap compatibility (Karen Defense radar)
var combo_meter: float = 0.0  # HUD combo display compatibility (Karen Defense)
var combo_level: int = 0
var combo_stats: Dictionary = {"mark_strike": 0, "supply_chain": 0, "emp_followup": 0}
var _redraw_accum: float = 0.0

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

	player_node = PlayerEntity.new()
	player_node.name = "Player"
	entity_layer.add_child(player_node)

	game_camera = Camera2D.new()
	game_camera.name = "GameCamera"
	game_camera.position = Vector2(SCREEN_W / 2.0, SCREEN_H / 2.0)
	game_camera.zoom = Vector2(camera_base_zoom, camera_base_zoom)
	game_camera.enabled = true
	game_layer.add_child(game_camera)

	# Apply subtle perspective skew for depth effect (Y-shear creates isometric-like feel)
	# Using transform instead of rotation to avoid physics issues
	var skew_amount = 0.08  # Subtle skew for perspective
	game_layer.transform = Transform2D(
		Vector2(1.0, skew_amount),  # X basis with slight Y skew
		Vector2(0.0, 1.0),           # Y basis unchanged
		Vector2.ZERO                 # Origin
	)

	spawn_director = SpawnDirector.new()
	spawn_director.name = "SpawnDirector"
	add_child(spawn_director)

	checkpoint_manager = CheckpointManager.new()
	checkpoint_manager.name = "CheckpointManager"
	add_child(checkpoint_manager)

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
	map.setup(self, current_level_id)
	if parallax_backdrop:
		var theme = map.level_config.get("theme", "grass")
		parallax_backdrop.setup(self, theme, map.level_width, map.level_height)
	economy.configure_for_map(map.level_config)
	game_camera.position = map.get_player_anchor()
	spawn_director.setup(self)
	checkpoint_manager.setup(self)
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
	if chromatic_intensity > 0.05:
		chromatic_intensity = lerpf(chromatic_intensity, 0.0, delta * 8.0)
	if level_intro_timer > 0:
		level_intro_timer -= delta
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
	if state == GameState.LEVEL_ACTIVE:
		_update_linear_camera(delta)
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
		var lookahead_x = 80.0 if lookahead_anchor.last_move_dir.x > 0.1 else -40.0
		target = Vector2(mid.x + lookahead_x, mid.y)
		# Zoom out when players are spread so both fit on screen
		var min_spread = 180.0
		var zoom_out = clampf((spread_x + spread_y) / 400.0, 0.0, 0.35)
		zoom_target = Vector2(camera_base_zoom + zoom_out, camera_base_zoom + zoom_out)
	else:
		var anchor = p1
		var lookahead_x = 150.0 if anchor.last_move_dir.x > 0.1 else -80.0
		target = Vector2(anchor.position.x + lookahead_x, anchor.position.y)

	# Allow vertical camera follow for platformer levels (was locking Y when dy < 90)
	var dy = target.y - game_camera.position.y
	if absf(dy) < 25:
		target.y = game_camera.position.y

	var half_w = (get_viewport_rect().size.x / 2.0) / maxf(zoom_target.x, 0.1)
	var half_h = (get_viewport_rect().size.y / 2.0) / maxf(zoom_target.y, 0.1)
	target.x = clampf(target.x, half_w, map.level_width - half_w)
	target.y = clampf(target.y, half_h, map.level_height - half_h)

	game_camera.position = game_camera.position.lerp(target, delta * 6.0)
	game_camera.zoom = game_camera.zoom.lerp(zoom_target, delta * 4.0)

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

func start_hitstop(duration: float):
	hitstop_timer = duration

func spawn_damage_number(pos: Vector2, text: String, color: Color):
	if damage_numbers.size() >= 40:
		damage_numbers.pop_front()
	damage_numbers.append({
		"position": pos + Vector2(randf_range(-12, 12), -10),
		"text": text,
		"color": color,
		"timer": 0.9,
		"velocity_y": -80.0,
		"scale": 2.2,
		"rotation": randf_range(-0.15, 0.15),
		"drift_phase": randf_range(0, TAU),
		"drift_speed": randf_range(2.0, 4.0),
	})

func start_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

func trigger_landing_impact():
	"""Called by player on hard landings - screen shake for juice."""
	start_shake(5.0, 0.1)

func start_chromatic(intensity: float):
	chromatic_intensity = maxf(chromatic_intensity, intensity)

func _update_shake(delta):
	if shake_timer > 0:
		shake_timer -= delta
		var progress = shake_timer / shake_duration
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
		dn.position.y += dn.velocity_y * delta
		if dn.timer <= 0:
			damage_numbers.remove_at(i)
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
	player2_node = PlayerEntity.new()
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
			var pos = dn.position + shake_offset + Vector2(drift_x, 0)
			var life_frac = clampf(dn.timer / 0.9, 0.0, 1.0)
			var sc = lerpf(1.0, dn.get("scale", 2.0), clampf(life_frac * 2.0, 0.0, 1.0))
			var rot = dn.get("rotation", 0.0)
			draw_set_transform(pos, rot, Vector2(sc, sc))
			draw_string(font, Vector2(1, 1), dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0, 0, 0, alpha * 0.6))
			draw_string(font, Vector2.ZERO, dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
