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
var parallax_backdrop: ParallaxBackdropV2 = null
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
var weapon_trail_manager: WeaponTrailManager = null  # Phase 1.2: GPU ribbon trails
var occlusion_manager: OcclusionManager = null  # Phase 3: Depth occlusion silhouettes
var hit_flash_light: PointLight2D = null  # Phase 4.2: Single shared hit-impact light
var hit_flash_light_energy: float = 0.0   # Current energy (decays each frame)
var post_process: PostProcessLayer = null  # Phase 1.3: Full multi-pass GPU shader pipeline
var post_process_pipeline: PostProcessPipeline = null  # Phase 1.1: Multi-pass orchestration
var quality_manager: QualityManager = null             # Phase 1.3: Quality tier switching
var music_controller: MusicController = null           # Phase 7.1: Dynamic music stems
var audio_manager: AudioManager = null                 # Phase 7.2: Spatial SFX
var debug_overlay: DebugOverlay = null                 # Phase 8.4: Debug HUD (debug builds only)
var streaming_loader: StreamingLoader = null           # Phase 8.2: Asset streaming
var weather_system: WeatherSystem = null               # Phase 2.3: Weather & ambient particles
var gpu_particle_emitter: GPUParticleEmitter = null    # Phase 4.2: GPU burst/death particles
var atmospheric_fog_layer: CanvasLayer = null          # Phase 2.2: Depth atmospheric fog
var atmospheric_fog_mat: ShaderMaterial = null

# Phase 5.2: Biome transition tracking
var _last_biome_x_check: float = -1.0
var _current_segment_theme: String = ""

# Phase 8.1: Delta smoothing for frame pacing
var _smoothed_delta: float = 0.016
const DELTA_SMOOTH_FACTOR: float = 0.2

# Accessibility settings (Phase 8.3)
var accessibility_reduce_motion: bool = false  # Reduces shake, no speed lines, no hitStop shake
var accessibility_colorblind_mode: String = ""  # "deuteranopia" | "protanopia" | "" (normal)

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
const CAMERA_TILT_MAX: float = 0.22  # CARTOON: Noticeable tilt during sprint (~12.5 degrees)
const CAMERA_LOOKAHEAD_MAX: float = 220.0
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

# AAA Visual Overhaul: Establishing shot camera
var establishing_shot_active: bool = false
var establishing_shot_timer: float = 0.0
var establishing_shot_from: Vector2 = Vector2.ZERO
var establishing_shot_to: Vector2 = Vector2.ZERO
const ESTABLISHING_SHOT_DURATION: float = 1.2
# Phase 6.2: Intro cinematic zoom (1.05 → 1.0 over 0.85s) + level name card
var _intro_zoom: float = 1.0        # Extra factor applied on top of base zoom during intro
var _intro_zoom_timer: float = 0.0
const _INTRO_ZOOM_DURATION: float = 0.85
const _INTRO_ZOOM_START: float = 1.05
var _level_name_card_timer: float = 0.0
const _LEVEL_NAME_CARD_DURATION: float = 3.5
var _level_name_canvas: CanvasLayer = null
# Camera overshoot spring
var camera_overshoot: Vector2 = Vector2.ZERO
var camera_overshoot_velocity: Vector2 = Vector2.ZERO
# Camera breathing (subtle idle oscillation for cinematic life)
var _camera_breath_phase: float = 0.0
const CAMERA_BREATH_SPEED: float = 0.28  # ~0.28 Hz — very slow, barely perceptible
const CAMERA_BREATH_AMP: float = 1.8     # pixels at full idle

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

	parallax_backdrop = ParallaxBackdropV2.new()
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

	# Phase 1.2: Weapon trail manager for GPU ribbon combo trails
	weapon_trail_manager = WeaponTrailManager.new()
	weapon_trail_manager.name = "WeaponTrailManager"
	weapon_trail_manager.setup(self)
	add_child(weapon_trail_manager)

	# Phase 3: Occlusion manager for depth silhouettes
	occlusion_manager = OcclusionManager.new()
	occlusion_manager.name = "OcclusionManager"
	occlusion_manager.setup(self)
	add_child(occlusion_manager)

	# Phase 4.2: Single shared hit-flash light (moved per hit, energy decays)
	hit_flash_light = PointLight2D.new()
	hit_flash_light.name = "HitFlashLight"
	hit_flash_light.color = Color(1.0, 0.9, 0.8)
	hit_flash_light.energy = 0.0
	hit_flash_light.texture_scale = 1.2
	hit_flash_light.range_layer_min = -1024
	hit_flash_light.range_layer_max = 1024
	var _lft = _make_radial_light_texture(96)
	if _lft:
		hit_flash_light.texture = _lft
	entity_layer.add_child(hit_flash_light)

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

	# Phase 1.3: Full multi-pass GPU post-processing pipeline (cel, bloom, distort, tonemap)
	post_process = PostProcessLayer.new()
	post_process.name = "PostProcess"
	add_child(post_process)
	post_process.setup(self)

	# Phase 1.1: Multi-pass pipeline orchestration
	post_process_pipeline = PostProcessPipeline.new()
	post_process_pipeline.name = "PostProcessPipeline"
	add_child(post_process_pipeline)
	post_process_pipeline.setup(self)

	# Phase 1.3: Quality tier manager
	quality_manager = QualityManager.new()
	quality_manager.name = "QualityManager"
	add_child(quality_manager)
	quality_manager.setup(self)

	# Phase 7.1: Dynamic music controller
	music_controller = MusicController.new()
	music_controller.name = "MusicController"
	add_child(music_controller)
	music_controller.setup(self)

	# Phase 7.2: Spatial audio manager
	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	audio_manager.setup(self)

	# Phase 8.4: Debug overlay (debug builds only)
	debug_overlay = DebugOverlay.new()
	debug_overlay.name = "DebugOverlay"
	add_child(debug_overlay)
	debug_overlay.setup(self)

	# Phase 8.2: Streaming loader
	streaming_loader = StreamingLoader.new()
	streaming_loader.name = "StreamingLoader"
	add_child(streaming_loader)

	# Phase 4.2: GPU burst/death particle emitter
	gpu_particle_emitter = GPUParticleEmitter.new()
	gpu_particle_emitter.name = "GPUParticleEmitter"
	add_child(gpu_particle_emitter)
	gpu_particle_emitter.setup(self)

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
	var _theme = map.level_config.get("theme", "grass")
	if parallax_backdrop:
		parallax_backdrop.setup(self, _theme, map.level_width, map.level_height)
	# AAA Visual Overhaul: Set post-process theme
	if post_process:
		post_process.set_theme(_theme)
	# Phase 1.1: Set LUT theme in pipeline
	if post_process_pipeline:
		post_process_pipeline.set_theme_lut(_theme)
	# Phase 7.1: Start dynamic music for theme
	if music_controller:
		music_controller.set_theme(_theme)
	# Phase 7.2: Set up ambient sources for theme
	if audio_manager:
		audio_manager.setup_ambient_sources(_theme, map.level_width)
	# Phase 2.3: Set up weather system (with per-level intensity from config)
	var _weather_intensity = float(map.level_config.get("weather_intensity", 1.0))
	weather_system = WeatherSystem.new()
	weather_system.name = "WeatherSystem"
	game_layer.add_child(weather_system)
	weather_system.setup(self, _theme, _weather_intensity)

	# Phase 2.2: Atmospheric fog layer
	_setup_atmospheric_fog(_theme, map.level_config.get("fog_preset", ""))

	# Phase 3.4: Apply per-level time_of_day to parallax + weather
	var _tod = float(map.level_config.get("time_of_day", 0.5))
	if parallax_backdrop:
		parallax_backdrop.set_time_of_day(_tod)
	if weather_system:
		weather_system.set_time_of_day(_tod)

	# Phase 5.2: Initialize biome tracking
	_current_segment_theme = _theme
	# Phase 8.2: Start streaming loader
	if streaming_loader:
		streaming_loader.setup(self)
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

	# AAA Visual Overhaul: Establishing shot - brief pan from spawn area to player
	_start_establishing_shot()


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
	# Phase 8.1: Delta smoothing — prevents camera jumpiness from frame spikes
	_smoothed_delta = lerpf(_smoothed_delta, delta, DELTA_SMOOTH_FACTOR)
	var smooth_delta = _smoothed_delta
	# Flag if process time is too high (> 14ms)
	var pt_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	if pt_ms > 14.0 and OS.is_debug_build():
		pass  # Could log but avoid console spam

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
	# Phase 6.2: Tick level name card fade
	_update_level_name_card(delta)

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
	# Phase 4.2: Decay shared hit-flash light
	if hit_flash_light and hit_flash_light_energy > 0.01:
		hit_flash_light_energy = lerpf(hit_flash_light_energy, 0.0, delta * 7.0)
		hit_flash_light.energy = hit_flash_light_energy
	elif hit_flash_light and hit_flash_light.energy > 0.0:
		hit_flash_light.energy = 0.0
	# AAA Upgrade: Decay bloom intensity
	if fx_draw_node and fx_draw_node.bloom_intensity > 0.05:
		fx_draw_node.bloom_intensity = lerpf(fx_draw_node.bloom_intensity, 0.0, delta * 4.0)
	if level_intro_timer > 0:
		level_intro_timer -= delta
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
	# AAA Visual Overhaul: Update establishing shot
	if establishing_shot_active:
		establishing_shot_timer -= delta
		if establishing_shot_timer <= 0:
			establishing_shot_active = false
		else:
			var t = 1.0 - (establishing_shot_timer / ESTABLISHING_SHOT_DURATION)
			var ease_t = ease_out_expo(t)
			game_camera.position = establishing_shot_from.lerp(establishing_shot_to, ease_t)
	if state == GameState.LEVEL_ACTIVE:
		run_summary_timer = maxf(0.0, run_summary_timer - delta)
		if not establishing_shot_active:
			_update_linear_camera(delta)
		_debug_camera_timer += delta
		if _debug_camera_timer >= 5.0:
			_debug_camera_timer = 0.0
			_log_camera_snapshot(delta)
	map.anim_time += delta
	# Phase 2.1: Update player position for grass bend
	if map and player_node:
		map._player_pos = player_node.position
	# Phase 2.3 / Phase 5: Update animated terrain effects
	if map and map.has_method("update_effects"):
		map.update_effects(delta)
	if map:
		map.queue_redraw()
	if fx_draw_node:
		fx_draw_node.queue_redraw()
	_update_visibility()
	_redraw_accum += delta
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()

	# Phase 1.1: Update post-process pipeline (LUT, bloom params, exposure)
	if post_process_pipeline:
		post_process_pipeline.update(delta)

func _process_level_active(delta):
	time_elapsed += delta
	if p2_join_flash_timer > 0:
		p2_join_flash_timer -= delta

	if shop_menu.active:
		state = GameState.CHECKPOINT_SHOP
		return

	if not player_node.is_dead:
		player_node.update_player(delta, self)
	# Speed lines: connect GPU post-process speed lines to dash and sprint
	if post_process and not player_node.is_dead:
		if player_node.is_dashing:
			post_process.trigger_speed_lines(0.85)
		elif player_node.get("is_sprinting") and player_node.is_sprinting and absf(player_node.velocity.x) > 240.0:
			post_process.trigger_speed_lines(0.32)
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
	if weapon_trail_manager:
		weapon_trail_manager.update(delta)
	if occlusion_manager:
		occlusion_manager.update(delta)
	_update_damage_numbers(delta)
	_update_impact_flashes(delta)

	checkpoint_manager.update(delta)
	spawn_director.update(delta)
	total_gold_earned = economy.p1_gold + economy.p2_gold

	# Phase 2.3: Propagate time_of_day from parallax to weather (sun-driven light shafts)
	if weather_system and parallax_backdrop:
		var tod = parallax_backdrop.get("time_of_day") if parallax_backdrop.get("time_of_day") != null else 0.5
		weather_system.set_time_of_day(tod)

	# Phase 5.2: Biome transition check
	if player_node and not player_node.is_dead:
		var px = player_node.position.x
		# Only check every 40px of travel to avoid per-frame cost
		if absf(px - _last_biome_x_check) >= 40.0:
			_last_biome_x_check = px
			_check_biome_transitions(px)

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
		if anchor.is_dashing:
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
		# Delta-corrected exponential smoothing — frame-rate independent
		var smooth_x = 1.0 - exp(-delta * 6.0)
		var smooth_y = 1.0 - exp(-delta * 4.5)
		_camera_target_smooth.x = lerpf(_camera_target_smooth.x, target.x, smooth_x)
		_camera_target_smooth.y = lerpf(_camera_target_smooth.y, target.y, smooth_y)

	var effective_target = _camera_target_smooth

	# AAA Visual Overhaul: Aggressive action-based dynamic zoom
	var action_zoom = 1.0
	if p1 and not p1.is_dead:
		# Zoom out when sprinting for speed emphasis
		if p1.is_sprinting and absf(p1.velocity.x) > 200:
			action_zoom += 0.08
		# Zoom out during ground pound fall
		elif p1.get("is_ground_pounding") and p1.is_ground_pounding:
			action_zoom += 0.12
		# Zoom out slightly when airborne for spatial awareness
		elif not p1.is_on_ground and absf(p1.velocity.y) > 200:
			action_zoom += 0.04

	# Phase 6.4: Boss frame — pull back 1.2x and center between player and boss
	var boss_node = _get_active_boss()
	if boss_node and p1 and not p1.is_dead:
		var boss_to_player_mid = (p1.position + boss_node.position) * 0.5
		target = target.lerp(boss_to_player_mid, 0.4)
		action_zoom += 0.2  # Pull back for boss fight

	# Phase 6.4: Danger framing — 4+ nearby enemies → slight zoom out
	var nearby_enemy_count = _count_nearby_enemies(p1.position if p1 else Vector2.ZERO, 250.0)
	if nearby_enemy_count >= 4:
		var danger_zoom = clampf((nearby_enemy_count - 3) * 0.015, 0.0, 0.05)
		action_zoom += danger_zoom

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

	# AAA Visual Overhaul: Camera overshoot spring (continues past target, springs back)
	var cam_velocity = Vector2(new_x - game_camera.position.x, new_y - game_camera.position.y)
	var overshoot_spring = -camera_overshoot * 30.0
	camera_overshoot_velocity += overshoot_spring * delta
	camera_overshoot_velocity *= exp(-12.0 * delta)
	camera_overshoot_velocity += cam_velocity * 0.15  # Feed camera movement into overshoot
	camera_overshoot += camera_overshoot_velocity * delta
	if camera_overshoot.length() < 0.5:
		camera_overshoot = Vector2.ZERO

	# Camera breathing: gentle idle oscillation fades out as player moves
	_camera_breath_phase = fmod(_camera_breath_phase + delta * CAMERA_BREATH_SPEED * TAU, TAU)
	var p1_speed = p1.velocity.length() if p1 and not p1.is_dead else 0.0
	var breath_scale = 1.0 - clampf(p1_speed / 180.0, 0.0, 1.0)
	var breath_x = sin(_camera_breath_phase) * CAMERA_BREATH_AMP * 0.4 * breath_scale
	var breath_y = sin(_camera_breath_phase * 0.71 + 1.27) * CAMERA_BREATH_AMP * breath_scale
	game_camera.position = Vector2(new_x + breath_x, new_y + breath_y) + camera_overshoot

	# Store for debug snapshot
	_debug_cam_target = target
	_debug_cam_smooth = _camera_target_smooth
	_debug_cam_effective = effective_target

	# Phase 6.2: Decay intro zoom smoothly (1.05 → 1.0)
	if _intro_zoom_timer > 0.0:
		_intro_zoom_timer -= delta
		var t = clampf(1.0 - _intro_zoom_timer / _INTRO_ZOOM_DURATION, 0.0, 1.0)
		_intro_zoom = lerpf(_INTRO_ZOOM_START, 1.0, t * t)  # Ease-in decay
	else:
		_intro_zoom = 1.0
	# Fold intro zoom into the zoom target
	zoom_target *= Vector2(_intro_zoom, _intro_zoom)

	# Zoom with spring ease (use safe_delta to avoid jerk during frame drops)
	var zoom_ease = ease_out_spring(safe_delta * 5.0)
	game_camera.zoom = game_camera.zoom.lerp(zoom_target, zoom_ease)

	# CARTOON: Exaggerated camera tilt - kicks in at lower speed, stronger during dash
	var target_tilt = 0.0
	if p1 and not p1.is_dead:
		var vel_x = p1.velocity.x
		if absf(vel_x) > 100:
			target_tilt = -sign(vel_x) * clampf((absf(vel_x) - 100) / 450.0, 0.0, 1.0) * CAMERA_TILT_MAX
		if p1.is_dashing:
			target_tilt *= 2.2
	# Spring physics for smooth tilt
	var tilt_force = (target_tilt - camera_tilt) * 25.0
	camera_tilt_velocity += tilt_force * delta
	camera_tilt_velocity *= exp(-15.0 * delta)  # Dampening
	camera_tilt += camera_tilt_velocity * delta
	game_camera.rotation = camera_tilt

func _get_active_boss():
	"""Phase 6.4: Find active boss entity for camera framing."""
	for enemy in enemy_container.get_children():
		if enemy.get("is_boss") and enemy.is_boss and enemy.state != EnemyEntity.EnemyState.DEAD and enemy.state != EnemyEntity.EnemyState.DYING:
			return enemy
	return null

func _count_nearby_enemies(from_pos: Vector2, radius: float) -> int:
	"""Phase 6.4: Count live enemies within radius for danger framing."""
	var count = 0
	for enemy in enemy_container.get_children():
		if enemy.state == EnemyEntity.EnemyState.DEAD or enemy.state == EnemyEntity.EnemyState.DYING:
			continue
		if from_pos.distance_to(enemy.position) <= radius:
			count += 1
	return count

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

	# AAA Visual Overhaul: Heavy hits trigger screen distortion + bloom
	if intensity > 1.0 and post_process:
		post_process.trigger_impact_distortion(Vector2(0.5, 0.5), (intensity - 1.0) * 0.4)
		post_process.trigger_bloom_boost((intensity - 1.0) * 0.3)

func trigger_bloom(intensity: float = 1.0):
	"""AAA Upgrade: Trigger bloom glow effect."""
	if fx_draw_node:
		fx_draw_node.bloom_intensity = intensity

func trigger_camera_zoom_pulse(strength: float):
	"""CARTOON: Exaggerated camera pulse - clearly noticeable."""
	camera_zoom_pulse += strength * 0.025
	camera_zoom_pulse = clampf(camera_zoom_pulse, -0.08, 0.08)

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
	# Phase 4.2: Activate shared hit-flash light at impact position
	trigger_hit_light(pos, 1.0)

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
	# AAA Visual Overhaul: Route to GPU shader when available
	if post_process:
		post_process.trigger_chromatic(intensity * 0.003)

func trigger_impact_distortion(world_pos: Vector2, strength: float = 0.5):
	"""AAA Visual Overhaul: Screen warp from impact point. Uses GPU shader."""
	if post_process and game_camera:
		var vp_size = get_viewport_rect().size
		var screen_pos = (world_pos - game_camera.position + vp_size * 0.5) / vp_size
		screen_pos = screen_pos.clamp(Vector2.ZERO, Vector2.ONE)
		post_process.trigger_impact_distortion(screen_pos, strength)

func trigger_bloom_boost(intensity: float = 0.5):
	"""AAA Visual Overhaul: GPU bloom boost for emphasis."""
	if post_process:
		post_process.trigger_bloom_boost(intensity)

## Phase 2.2: Set up atmospheric fog CanvasLayer
func _setup_atmospheric_fog(theme: String, fog_preset: String):
	"""Create fullscreen depth fog pass below post-process."""
	var shader_path = "res://assets/shaders/atmospheric_fog.gdshader"
	if not ResourceLoader.exists(shader_path):
		return
	var shader = load(shader_path) as Shader
	if shader == null:
		return

	# Determine fog params from preset or theme default
	var fog_params: Dictionary
	if not fog_preset.is_empty() and LUTGenerator.FOG_PRESETS.has(fog_preset):
		fog_params = LUTGenerator.FOG_PRESETS[fog_preset]
	else:
		# Theme defaults
		match theme:
			"cave":   fog_params = LUTGenerator.FOG_PRESETS["dense"]
			"lava":   fog_params = LUTGenerator.FOG_PRESETS["lava"]
			"sky":    fog_params = LUTGenerator.FOG_PRESETS["sky"]
			"ice":    fog_params = LUTGenerator.FOG_PRESETS["snow"]
			"summit": fog_params = LUTGenerator.FOG_PRESETS["light"]
			_:        fog_params = LUTGenerator.FOG_PRESETS["light"]

	if fog_params.get("density", 0.0) < 0.01:
		return  # Skip near-zero fog

	atmospheric_fog_mat = ShaderMaterial.new()
	atmospheric_fog_mat.shader = shader
	atmospheric_fog_mat.set_shader_parameter("fog_color",    fog_params.get("color", Color(0.05,0.08,0.14,0.85)))
	atmospheric_fog_mat.set_shader_parameter("fog_density",  fog_params.get("density", 0.15))
	atmospheric_fog_mat.set_shader_parameter("fog_start_y",  fog_params.get("start_y", 0.35))
	atmospheric_fog_mat.set_shader_parameter("fog_end_y",    fog_params.get("end_y", 0.95))
	atmospheric_fog_mat.set_shader_parameter("fog_top_haze", fog_params.get("top_haze", 0.0))
	atmospheric_fog_mat.set_shader_parameter("time_driven",  1.0 if theme == "cave" or theme == "lava" else 0.3)

	var fog_rect = ColorRect.new()
	fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog_rect.material = atmospheric_fog_mat
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.color = Color.TRANSPARENT

	atmospheric_fog_layer = CanvasLayer.new()
	atmospheric_fog_layer.name = "AtmosphericFog"
	atmospheric_fog_layer.layer = 9   # Above weather (8), below FX (15)
	atmospheric_fog_layer.add_child(fog_rect)
	add_child(atmospheric_fog_layer)

## Phase 5.2: Check segment_theme_overrides for biome transitions
func _check_biome_transitions(player_x: float):
	"""Switch parallax and post-process theme when player crosses x_min threshold."""
	if map == null:
		return
	var overrides: Array = map.level_config.get("segment_theme_overrides", [])
	if overrides.is_empty():
		return

	# Find the most recent override that applies (largest x_min <= player_x)
	var new_theme = map.level_config.get("theme", "grass")
	for override in overrides:
		var x_min = float(override.get("x_min", 0))
		if player_x >= x_min:
			new_theme = str(override.get("theme", new_theme))

	if new_theme != _current_segment_theme:
		_current_segment_theme = new_theme
		if parallax_backdrop and parallax_backdrop.has_method("crossfade_to_theme"):
			parallax_backdrop.crossfade_to_theme(new_theme, 1.5)
		if post_process:
			post_process.set_theme(new_theme)
		if post_process_pipeline:
			post_process_pipeline.set_theme_lut(new_theme)

func _start_establishing_shot():
	"""AAA Visual Overhaul: Brief camera pan from offset to player on level load."""
	if not player_node or not game_camera:
		return
	establishing_shot_active = true
	establishing_shot_timer = ESTABLISHING_SHOT_DURATION
	establishing_shot_to = player_node.position
	# Start camera offset to the right (show ahead of player)
	establishing_shot_from = player_node.position + Vector2(300, -80)
	game_camera.position = establishing_shot_from

	# Phase 6.2: Intro cinematic zoom 1.05 → 1.0
	_intro_zoom = _INTRO_ZOOM_START
	_intro_zoom_timer = _INTRO_ZOOM_DURATION
	# Scale camera zoom immediately for a subtle zoom-in at level start
	game_camera.zoom = Vector2(camera_base_zoom * _intro_zoom, camera_base_zoom * _intro_zoom)

	# Phase 6.2: Level name card — create fullscreen overlay canvas on demand
	_level_name_card_timer = _LEVEL_NAME_CARD_DURATION
	_show_level_name_card()

func _show_level_name_card():
	"""Phase 6.2: Create/update the level name card overlay on a dedicated CanvasLayer."""
	# Build canvas lazily
	if _level_name_canvas == null:
		_level_name_canvas = CanvasLayer.new()
		_level_name_canvas.name = "LevelNameCard"
		_level_name_canvas.layer = 15  # Above HUD (10) and post-process (8-9)
		add_child(_level_name_canvas)
	# Clear previous children
	for c in _level_name_canvas.get_children():
		c.queue_free()

	var level_name: String = map.level_config.get("name", "")
	if level_name.is_empty():
		return

	var level_num: int = map.level_config.get("id", current_level_id)
	var theme: String = map.level_config.get("theme", "grass")

	# Theme-based accent color for the name card
	var THEME_ACCENT = {
		"grass":   Color8(120, 200, 80),
		"cave":    Color8(140, 120, 200),
		"sky":     Color8(100, 180, 240),
		"summit":  Color8(200, 210, 225),
		"lava":    Color8(220, 90, 40),
		"ice":     Color8(160, 210, 240),
	}
	var accent = THEME_ACCENT.get(theme, Color8(200, 200, 200))

	# Name card container — FX node that draws the card
	var card = LevelNameCard.new(level_name, level_num, accent, _LEVEL_NAME_CARD_DURATION)
	card.name = "CardDrawNode"
	_level_name_canvas.add_child(card)

func _update_level_name_card(delta: float):
	"""Phase 6.2: Tick the name card alpha fade."""
	if _level_name_card_timer <= 0.0:
		# Hide canvas once done
		if _level_name_canvas:
			_level_name_canvas.visible = false
		return
	_level_name_card_timer -= delta
	if _level_name_canvas:
		_level_name_canvas.visible = true
		# Forward timer to the card draw node
		var card = _level_name_canvas.get_node_or_null("CardDrawNode")
		if card and card.has_method("set_time"):
			card.set_time(_level_name_card_timer)
			card.queue_redraw()

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
		# Cinematic shake rotation: adds physical weight to impacts
		game_camera.rotation += randf_range(-ci, ci) * 0.0025
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

# ---------------------------------------------------------------------------
# Phase 8.3: Accessibility API
# ---------------------------------------------------------------------------

func set_reduce_motion(enabled: bool):
	"""Phase 8.3: Toggle reduced motion — 30% shake, 50% hitstop, no speed lines."""
	accessibility_reduce_motion = enabled
	if post_process:
		if enabled:
			post_process.trigger_speed_lines(0.0)

func set_colorblind_mode(mode: String):
	"""Phase 7.1: Switch colorblind LUT. mode: '' | 'deuteranopia' | 'protanopia'"""
	accessibility_colorblind_mode = mode
	if post_process_pipeline and post_process_pipeline.has_method("generate_colorblind_luts"):
		if mode.is_empty():
			# Regenerate normal LUTs
			post_process_pipeline._preload_luts()
			post_process_pipeline.set_theme_lut(map.level_config.get("theme", "grass"))
		else:
			post_process_pipeline.generate_colorblind_luts(mode)

# Override start_shake to respect reduce_motion (Phase 8.3)
func start_shake_accessible(intensity: float, duration: float, curve: ShakeCurve = ShakeCurve.EASE_OUT_QUAD):
	"""Phase 8.3: start_shake respecting accessibility reduce_motion setting."""
	var actual_intensity = intensity * 0.3 if accessibility_reduce_motion else intensity
	start_shake(actual_intensity, duration, curve)

# Override start_hitstop to respect reduce_motion
func start_hitstop_accessible(duration: float, intensity: float = 1.0):
	"""Phase 8.3: start_hitstop respecting accessibility reduce_motion."""
	var actual_duration = duration * 0.5 if accessibility_reduce_motion else duration
	start_hitstop(actual_duration, intensity)

func restart_game(_restore_map_id: int = -1):
	restart_level()

func _make_radial_light_texture(size: int) -> ImageTexture:
	"""Phase 4.2: Generate radial gradient texture for PointLight2D."""
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center) / (size / 2.0)
			var alpha = clamp(1.0 - dist * dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func trigger_hit_light(world_pos: Vector2, intensity: float = 1.0):
	"""Phase 4.2: Activate the shared hit-flash light at impact position."""
	if hit_flash_light:
		hit_flash_light.position = world_pos
		hit_flash_light_energy = clamp(intensity * 1.2, 0.4, 2.0)
		hit_flash_light.energy = hit_flash_light_energy

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
