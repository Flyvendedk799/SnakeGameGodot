extends Node2D

const SCREEN_W = 1280
const SCREEN_H = 720

enum GameState { WORLD_SELECT, TITLE, WAVE_ACTIVE, BETWEEN_WAVES, PAUSED, LEVEL_UP, GAME_OVER }
var state: GameState = GameState.WORLD_SELECT
var previous_state: GameState = GameState.TITLE
var _last_companion_state: String = ""
var _last_companion_state_seq: int = 0

# Child references
var map: FortMap
var player_node: PlayerEntity
var ally_container: Node2D
var enemy_container: Node2D
var projectile_container: Node2D
var gold_container: Node2D
var barricade_container: Node2D
var door_container: Node2D
var game_layer: Node2D

var wave_director: WaveDirector
var combat_system: CombatSystem
var economy: Economy
var progression: Progression
var building_manager: BuildingManager
var unit_manager: UnitManager

var hud: HudDisplay
var shop_menu: ShopMenu
var level_up_menu: LevelUpMenu
var pause_menu: PauseMenu
var game_over_screen: GameOverScreen
var world_select: WorldSelect

var sfx: KarenSfxPlayer
var particles: ParticleSystem

# Player 2 co-op
var player2_node: PlayerEntity = null
var p2_joined: bool = false
var p2_join_flash_timer: float = 0.0

# Mid-wave shop
var shop_from_wave: bool = false

# Wave complete delay before shop
var wave_complete_timer: float = 0.0
var wave_complete_pending: bool = false

# Wave start grace period
var wave_grace_timer: float = 0.0

# Camera for map scaling
var game_camera: Camera2D = null
var camera_base_zoom: float = 1.5

# Game tracking
var current_wave: int = 0
var enemies_killed_total: int = 0
var total_gold_earned: int = 0
var time_elapsed: float = 0.0

# Screen shake
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# Hitstop
var hitstop_timer: float = 0.0

# Chromatic aberration
var chromatic_intensity: float = 0.0
var chromatic_material: ShaderMaterial = null
var chromatic_overlay: ColorRect = null

# Camera juice
var camera_zoom_punch: float = 0.0

# Y-sorted entity layer
var entity_layer: Node2D = null

# Damage numbers
var damage_numbers: Array = []

# Wave announcement
var wave_announce_text: String = ""
var wave_announce_timer: float = 0.0
var wave_announce_sub: String = ""

# Title screen animation
var title_time: float = 0.0
var title_hover: int = -1

# World/map selection (1=Desert 15w, 2=Snow 30w, 3=Jungle 50w)
var current_map_id: int = 1

# Companion mode (only created when enabled via checkbox on world select)
var companion_session: CompanionSessionManager = null
var helicopter_entity: Node2D  # One-shot bomb heli (fallback when companion heli busy)
var companion_helicopter: CompanionHelicopterEntity = null  # Persistent joystick-controlled heli
var companion_chopper_input: Vector2 = Vector2.ZERO

# Per-frame cache for ally target selection (avoids O(n*m) iteration)
var ally_target_counts: Dictionary = {}

# Radar reveal timer
var radar_reveal_timer: float = 0.0

# Companion minimap broadcast throttle
var _companion_minimap_timer: float = 0.0
const COMPANION_MINIMAP_INTERVAL: float = 0.05  # 20Hz for real-time minimap/chopper

# Companion action HUD notification (array of {text, timer})
var companion_action_feed: Array = []
const MAX_COMPANION_ACTIONS: int = 3

func _ready():
	particles = ParticleSystem.new()
	_build_scene_tree()
	_setup_systems()
	world_select.show_select()
	_update_visibility()

func _build_scene_tree():
	# === GAME LAYER (hidden during title) ===
	game_layer = Node2D.new()
	game_layer.name = "GameLayer"
	add_child(game_layer)

	# Map draws first (background)
	map = FortMap.new()
	map.name = "Map"
	game_layer.add_child(map)

	# Barricades on top of map
	barricade_container = Node2D.new()
	barricade_container.name = "Barricades"
	game_layer.add_child(barricade_container)

	# Doors (inner keep entrances)
	door_container = Node2D.new()
	door_container.name = "Doors"
	game_layer.add_child(door_container)

	# Y-sorted entity layer for depth ordering
	entity_layer = Node2D.new()
	entity_layer.name = "Entities"
	entity_layer.y_sort_enabled = true
	game_layer.add_child(entity_layer)

	# Entity containers (y_sort propagates into parent sort)
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

	# Projectiles on top of entities (not y-sorted)
	projectile_container = Node2D.new()
	projectile_container.name = "Projectiles"
	game_layer.add_child(projectile_container)

	# Player in y-sorted layer
	player_node = PlayerEntity.new()
	player_node.name = "Player"
	entity_layer.add_child(player_node)

	# Camera for map scaling (zoomed in for big map exploration)
	game_camera = Camera2D.new()
	game_camera.name = "GameCamera"
	game_camera.position = Vector2(SCREEN_W / 2.0, SCREEN_H / 2.0)
	game_camera.zoom = Vector2(camera_base_zoom, camera_base_zoom)
	game_camera.enabled = true
	game_layer.add_child(game_camera)

	# Systems (invisible nodes)
	wave_director = WaveDirector.new()
	wave_director.name = "WaveDirector"
	add_child(wave_director)

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

	# SFX
	sfx = KarenSfxPlayer.new()
	sfx.name = "SFX"
	add_child(sfx)

	# UI layer (always on top)
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

	world_select = WorldSelect.new()
	world_select.name = "WorldSelect"
	ui_layer.add_child(world_select)

	# Post-process chromatic aberration layer
	var post_layer = CanvasLayer.new()
	post_layer.name = "PostProcess"
	post_layer.layer = 20
	add_child(post_layer)
	chromatic_overlay = ColorRect.new()
	chromatic_overlay.size = Vector2(SCREEN_W, SCREEN_H)
	chromatic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chromatic_overlay.visible = false
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float aberration_amount : hint_range(0.0, 20.0) = 0.0;\nuniform sampler2D screen_texture : hint_screen_texture, filter_linear;\nvoid fragment() {\n\tvec2 uv = SCREEN_UV;\n\tvec2 dir = uv - vec2(0.5);\n\tfloat dist = length(dir);\n\tvec2 offset = dir * aberration_amount * 0.004 * dist;\n\tfloat r = texture(screen_texture, uv + offset).r;\n\tfloat g = texture(screen_texture, uv).g;\n\tfloat b = texture(screen_texture, uv - offset).b;\n\tCOLOR = vec4(r, g, b, 1.0);\n}\n"
	chromatic_material = ShaderMaterial.new()
	chromatic_material.shader = shader
	chromatic_overlay.material = chromatic_material
	post_layer.add_child(chromatic_overlay)

func _setup_systems():
	map.setup(self, current_map_id)
	economy.configure_for_map(map.map_config)
	# Apply camera zoom from map config
	camera_base_zoom = map.map_config.get("camera_base_zoom", 1.5)
	game_camera.position = map.get_fort_center()
	game_camera.zoom = Vector2(camera_base_zoom, camera_base_zoom)
	wave_director.setup(self)
	combat_system.setup(self)
	progression.setup(self)
	building_manager.setup(self)
	unit_manager.setup(self)
	hud.setup(self)
	shop_menu.setup(self)
	level_up_menu.setup(self)
	pause_menu.setup(self)
	game_over_screen.setup(self)
	world_select.setup(self)
	player_node.position = map.get_fort_center()

func _update_visibility():
	var in_game = state != GameState.TITLE and state != GameState.WORLD_SELECT
	game_layer.visible = in_game
	# Disable camera during non-game states so title/world-select draw in screen space
	if game_camera:
		game_camera.enabled = in_game
	hud.visible = in_game and state != GameState.GAME_OVER
	world_select.visible = state == GameState.WORLD_SELECT

func start_hitstop(duration: float):
	hitstop_timer = duration

func _process(delta):
	if hitstop_timer > 0:
		# Use real-time delta (unscaled) so hitstop duration is accurate
		var real_delta = delta / maxf(Engine.time_scale, 0.01)
		hitstop_timer -= real_delta
		if hitstop_timer <= 0:
			Engine.time_scale = 1.0
		else:
			Engine.time_scale = 0.15  # Slow-mo (not full freeze) for feel without lag
			_update_shake(delta)
			queue_redraw()
			return

	match state:
		GameState.WORLD_SELECT:
			pass
		GameState.TITLE:
			_process_title(delta)
		GameState.WAVE_ACTIVE:
			_process_wave(delta)
		GameState.BETWEEN_WAVES:
			_process_between_waves(delta)
		GameState.PAUSED:
			pass
		GameState.LEVEL_UP:
			pass
		GameState.GAME_OVER:
			pass

	_update_shake(delta)
	if state == GameState.WAVE_ACTIVE or state == GameState.BETWEEN_WAVES:
		_update_camera_follow(delta)
	if wave_announce_timer > 0:
		wave_announce_timer -= delta
	if radar_reveal_timer > 0:
		radar_reveal_timer -= delta
	# Update companion action feed timers
	var i = companion_action_feed.size() - 1
	while i >= 0:
		companion_action_feed[i].timer -= delta
		if companion_action_feed[i].timer <= 0:
			companion_action_feed.remove_at(i)
		i -= 1
	# Update chromatic aberration
	if chromatic_intensity > 0.05:
		chromatic_intensity = lerpf(chromatic_intensity, 0.0, delta * 8.0)
		if chromatic_material:
			chromatic_material.set_shader_parameter("aberration_amount", chromatic_intensity)
		if chromatic_overlay:
			chromatic_overlay.visible = true
	elif chromatic_overlay and chromatic_overlay.visible:
		chromatic_overlay.visible = false

	# Update map animation time
	if state == GameState.WAVE_ACTIVE or state == GameState.BETWEEN_WAVES:
		map.anim_time += delta
		# Send minimap to companion (real-time, throttled)
		if companion_session and companion_session.is_session_connected():
			_companion_minimap_timer -= delta
			if _companion_minimap_timer <= 0:
				_companion_minimap_timer = COMPANION_MINIMAP_INTERVAL
				var m = map
				var w = maxf(m.SCREEN_W, 1.0)
				var h = maxf(m.SCREEN_H, 1.0)
				var enemies_arr: Array = []
				for e in enemy_container.get_children():
					if e.state in [EnemyEntity.EnemyState.DEAD, EnemyEntity.EnemyState.DYING]: continue
					# Include boss flag as third element
					enemies_arr.append([e.position.x / w, e.position.y / h, e.is_boss])
				var allies_arr: Array = []
				for a in ally_container.get_children():
					if a.current_hp <= 0: continue
					allies_arr.append([a.position.x / w, a.position.y / h])
				var players_arr: Array = []
				if not player_node.is_dead:
					players_arr.append([player_node.position.x / w, player_node.position.y / h])
				if p2_joined and player2_node and not player2_node.is_dead:
					players_arr.append([player2_node.position.x / w, player2_node.position.y / h])
				var chopper_pos = null
				if companion_helicopter and is_instance_valid(companion_helicopter):
					chopper_pos = [companion_helicopter.position.x / w, companion_helicopter.position.y / h]
				companion_session.send_minimap_with_state(enemies_arr, allies_arr, players_arr, chopper_pos)

	_update_visibility()
	_update_companion_game_state()
	if state != GameState.WORLD_SELECT:
		queue_redraw()

func _update_companion_game_state():
	"""Send game state to companion when it changes."""
	if not companion_session or not companion_session.is_session_connected():
		return
	var state_name := ""
	match state:
		GameState.WAVE_ACTIVE:
			state_name = "wave_active"
		GameState.BETWEEN_WAVES:
			state_name = "between_waves"
		GameState.PAUSED:
			state_name = "paused"
		GameState.LEVEL_UP:
			state_name = "level_up"
		GameState.GAME_OVER:
			state_name = "game_over"
		_:
			state_name = "other"
	if state_name != _last_companion_state:
		_last_companion_state = state_name
		_last_companion_state_seq += 1
	# Authoritative stream: keep sending latest state snapshot with monotonic sequence.
	companion_session.send_game_state(state_name, _last_companion_state_seq, current_wave)

func _process_title(delta):
	title_time += delta
	var mouse = get_global_mouse_position()
	title_hover = -1
	var btn_rect = Rect2(440, 380, 400, 70)
	if btn_rect.has_point(mouse):
		title_hover = 0

func _process_wave(delta):
	time_elapsed += delta

	# Round transition: count down while game keeps running (no freeze), then open shop
	if wave_complete_pending:
		wave_complete_timer -= delta
		if wave_complete_timer <= 0:
			wave_complete_pending = false
			state = GameState.BETWEEN_WAVES
			shop_menu.show_menu()
			return  # State changed; stop processing this frame as WAVE_ACTIVE
		# Do not return - keep running player/ally/particles so there is no freeze

	# Wave start grace period: let players repair, enemies frozen
	if wave_grace_timer > 0:
		wave_grace_timer -= delta
		if not player_node.is_dead:
			player_node.update_player(delta, self)
		if p2_joined and not player2_node.is_dead:
			player2_node.update_player(delta, self)
		particles.update(delta)
		_update_damage_numbers(delta)
		if p2_join_flash_timer > 0:
			p2_join_flash_timer -= delta
		total_gold_earned = economy.p1_gold + economy.p2_gold
		return

	if not player_node.is_dead:
		player_node.update_player(delta, self)
	if p2_joined and not player2_node.is_dead:
		player2_node.update_player(delta, self)
	_apply_player_tether(delta)
	wave_director.update(delta)

	for enemy in enemy_container.get_children():
		enemy.update_enemy(delta, self)
	# Cache ally target counts once per frame (avoids O(allies*enemies) in _find_best_enemy)
	ally_target_counts.clear()
	for ally in ally_container.get_children():
		var t = ally.get("target_enemy")
		if t != null and is_instance_valid(t):
			ally_target_counts[t] = ally_target_counts.get(t, 0) + 1
	for ally in ally_container.get_children():
		ally.update_ally(delta, self)
	for proj in projectile_container.get_children():
		if proj is GrenadeEntity:
			if proj.update_grenade(delta, self):
				# Grenade exploded or finished, notify owner and remove
				if proj.owner_player and is_instance_valid(proj.owner_player):
					proj.owner_player.on_grenade_removed()
				proj.queue_free()
		elif proj is ExplosionEffect:
			if proj.update_effect(delta):
				proj.queue_free()
		elif proj is SupplyDropEntity:
			var landed_pos = proj.update_supply(delta)
			if landed_pos is Vector2:
				_on_companion_supply_landed(landed_pos)
		elif proj is HelicopterBombEntity:
			pass
		elif proj is CompanionHelicopterEntity:
			pass
		elif proj is EmpEffectEntity:
			if proj.update_effect(delta):
				proj.queue_free()
		else:
			proj.update_projectile(delta)
	for gold in gold_container.get_children():
		gold.update_drop(delta)

	if helicopter_entity and is_instance_valid(helicopter_entity):
		if helicopter_entity.update_helicopter(delta):
			helicopter_entity = null

	if companion_helicopter and is_instance_valid(companion_helicopter):
		companion_helicopter.set_joystick_input(companion_chopper_input.x, companion_chopper_input.y)
		companion_helicopter.update_helicopter(delta)

	combat_system.resolve_frame(delta)
	particles.update(delta)
	_update_damage_numbers(delta)

	if p2_join_flash_timer > 0:
		p2_join_flash_timer -= delta

	if wave_director.is_wave_complete() and not wave_complete_pending:
		_wave_complete()

	if progression.pending_level_ups.size() > 0 and state == GameState.WAVE_ACTIVE:
		var level_up_player = progression.consume_level_up()
		previous_state = GameState.WAVE_ACTIVE
		state = GameState.LEVEL_UP
		level_up_menu.show_menu(level_up_player if level_up_player >= 0 else 0)

	if Input.is_action_just_pressed("regroup"):
		unit_manager.regroup_all()

	total_gold_earned = economy.p1_gold + economy.p2_gold

func _process_between_waves(delta):
	particles.update(delta)
	time_elapsed += delta

func _wave_complete():
	if sfx:
		sfx.play_wave_complete()
	economy.apply_end_of_wave_bonus(current_wave)
	for b in map.barricades:
		b.partial_repair(0.25)
	# Revive dead players
	_revive_dead_players()
	var max_waves = map.map_config.get("max_waves", 50)
	if current_wave >= max_waves:
		_show_victory()
		return
	# Visible round transition: show clear message, then open shop (no freeze)
	wave_complete_pending = true
	wave_complete_timer = 2.5
	_remove_companion_helicopter()
	wave_announce_text = "WAVE %d COMPLETE!" % current_wave
	wave_announce_sub = "Shop opening in %.0fs..." % wave_complete_timer
	wave_announce_timer = 2.5

func _revive_dead_players():
	if player_node.is_dead:
		player_node.is_dead = false
		player_node.visible = true
		player_node.current_hp = player_node.max_hp
		player_node.invincibility_timer = 1.0
		player_node.position = map.get_fort_center()
	if p2_joined and player2_node and player2_node.is_dead:
		player2_node.is_dead = false
		player2_node.visible = true
		player2_node.current_hp = player2_node.max_hp
		player2_node.invincibility_timer = 1.0
		player2_node.position = map.get_fort_center() + Vector2(40, 0)

func _show_victory():
	state = GameState.GAME_OVER
	wave_announce_text = "WORLD %d COMPLETE!" % current_map_id
	var next_id = current_map_id + 1
	if next_id <= 3:
		wave_announce_sub = "World %d unlocked!" % next_id
	else:
		wave_announce_sub = "You beat them all, dude!"
	wave_announce_timer = 999.0
	game_over_screen.show_menu(true)

func start_wave():
	if shop_from_wave:
		# Resuming from mid-wave shop, don't increment wave
		state = GameState.WAVE_ACTIVE
		shop_from_wave = false
		return
	current_wave += 1
	state = GameState.WAVE_ACTIVE
	# Map expansion per map config
	var expand_waves: Array = map.map_config.get("expand_waves", [10, 30])
	var expand_scales: Array = map.map_config.get("expand_scales", [1.5, 2.0])
	for i in range(expand_waves.size()):
		if current_wave == expand_waves[i] and i < expand_scales.size():
			map.expand(expand_scales[i])
			break
	# Apply damage scaling: +3% per wave (compounding from base)
	_apply_wave_damage_scaling()
	# 8-second grace period for repairs
	wave_grace_timer = 8.0
	wave_director.start_wave(current_wave)
	wave_announce_text = "WAVE %d" % current_wave
	var subs = ["Let's gooo!", "Stay chill...", "Here they come!", "Incoming Karens!", "Brace yourself, dude!"]
	wave_announce_sub = subs[current_wave % subs.size()]
	wave_announce_timer = 2.5
	camera_zoom_punch = 0.06
	if sfx:
		sfx.play_wave_start()
	var max_waves = map.map_config.get("max_waves", 50)
	if current_wave == max_waves and sfx:
		sfx.play_boss_roar()
	if companion_session and companion_session.is_session_connected():
		companion_session.notify_new_wave()
		# Spawn persistent joystick-controlled helicopter for companion
		_ensure_companion_helicopter()


func _ensure_companion_helicopter():
	if companion_helicopter and is_instance_valid(companion_helicopter):
		return
	companion_helicopter = CompanionHelicopterEntity.new()
	companion_helicopter.setup(self)
	projectile_container.add_child(companion_helicopter)

func _remove_companion_helicopter():
	if companion_helicopter and is_instance_valid(companion_helicopter):
		companion_helicopter.queue_free()
		companion_helicopter = null
	companion_chopper_input = Vector2.ZERO

func _on_companion_chopper_input(ax: float, ay: float):
	companion_chopper_input.x = clampf(ax, -1.0, 1.0)
	companion_chopper_input.y = clampf(ay, -1.0, 1.0)

func _on_companion_bomb_drop(x: float, y: float):
	if state != GameState.WAVE_ACTIVE or wave_complete_pending: return
	var map = self.map
	var wx = map.FORT_LEFT + x * (map.FORT_RIGHT - map.FORT_LEFT)
	var wy = map.FORT_TOP + y * (map.FORT_BOTTOM - map.FORT_TOP)
	var target_pos = Vector2(wx, wy)
	# Use companion helicopter if available and idle; otherwise one-shot heli
	if companion_helicopter and is_instance_valid(companion_helicopter):
		if companion_helicopter.request_bomb_drop(target_pos):
			_add_companion_action("Companion: Bomb inbound!")
			return
	_add_companion_action("Companion: Bomb inbound!")
	var heli = HelicopterBombEntity.new()
	heli.setup(self, target_pos)
	projectile_container.add_child(heli)
	if helicopter_entity and is_instance_valid(helicopter_entity):
		helicopter_entity.queue_free()
	helicopter_entity = heli

func _on_companion_supply_drop(x: float, y: float):
	if state != GameState.WAVE_ACTIVE or wave_complete_pending: return
	_add_companion_action("Companion: Supply drop incoming!")
	var map = self.map
	var wx = map.FORT_LEFT + x * (map.FORT_RIGHT - map.FORT_LEFT)
	var wy = map.FORT_TOP + y * (map.FORT_BOTTOM - map.FORT_TOP)
	var supply = SupplyDropEntity.new()
	supply.setup(self, Vector2(wx, wy))
	projectile_container.add_child(supply)

func _on_companion_bomb_landed(pos: Vector2, kills: int):
	var text = "Companion bomb: %d kills!" % kills if kills > 0 else "Companion bomb landed!"
	_add_companion_action(text)
	if companion_session:
		var m = map
		var nx = (pos.x - m.FORT_LEFT) / maxf(m.FORT_RIGHT - m.FORT_LEFT, 1.0)
		var ny = (pos.y - m.FORT_TOP) / maxf(m.FORT_BOTTOM - m.FORT_TOP, 1.0)
		companion_session.send_bomb_impact(nx, ny, kills)

func _on_companion_supply_landed(pos: Vector2):
	_add_companion_action("Companion supply: Repairs + gold!")
	if companion_session:
		var m = map
		var nx = (pos.x - m.FORT_LEFT) / maxf(m.FORT_RIGHT - m.FORT_LEFT, 1.0)
		var ny = (pos.y - m.FORT_TOP) / maxf(m.FORT_BOTTOM - m.FORT_TOP, 1.0)
		companion_session.send_supply_impact(nx, ny)


func _apply_player_tether(delta: float):
	if not p2_joined or player2_node == null or player_node.is_dead or player2_node.is_dead:
		return
	var max_dist = 760.0
	var return_dist = 700.0
	var vec = player2_node.position - player_node.position
	var dist = vec.length()
	if dist <= max_dist:
		return
	var dir = vec / maxf(dist, 0.001)
	var overflow = dist - max_dist
	var correction = minf(overflow * (8.0 * delta), overflow)
	player_node.position += dir * correction * 0.5
	player2_node.position -= dir * correction * 0.5
	player_node.position = map.resolve_collision(player_node.position, player_node.BODY_RADIUS)
	player2_node.position = map.resolve_collision(player2_node.position, player2_node.BODY_RADIUS)
	if overflow > (max_dist - return_dist) and int(Time.get_ticks_msec() / 220) % 2 == 0:
		spawn_damage_number((player_node.position + player2_node.position) * 0.5, "TOO FAR APART", Color8(255, 170, 90))
func _update_camera_follow(delta: float):
	var target: Vector2
	var points: Array[Vector2] = []
	var min_x := 0.0
	var max_x := 0.0
	var min_y := 0.0
	var max_y := 0.0
	var heli_to_follow = companion_helicopter if (companion_helicopter and is_instance_valid(companion_helicopter)) else helicopter_entity
	var use_helicopter = companion_session and companion_session.is_session_connected() and heli_to_follow and is_instance_valid(heli_to_follow) and Input.is_action_pressed("look_at_helicopter")
	if use_helicopter:
		target = heli_to_follow.position
	else:
		if not player_node.is_dead:
			points.append(player_node.position)
		if p2_joined and player2_node and not player2_node.is_dead:
			points.append(player2_node.position)
		if points.is_empty():
			points.append(map.get_fort_center())

		min_x = points[0].x
		max_x = points[0].x
		min_y = points[0].y
		max_y = points[0].y
		for p in points:
			min_x = minf(min_x, p.x)
			max_x = maxf(max_x, p.x)
			min_y = minf(min_y, p.y)
			max_y = maxf(max_y, p.y)

		target = Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
		if points.size() == 1:
			if not player_node.is_dead and player_node.is_moving:
				target += player_node.last_move_dir * 60.0
			elif p2_joined and player2_node and player2_node.is_moving:
				target += player2_node.last_move_dir * 60.0

	camera_zoom_punch = lerpf(camera_zoom_punch, 0.0, delta * 5.0)
	var enemy_count = enemy_container.get_child_count()
	var dynamic_zoom_offset = clampf(float(enemy_count) / 50.0, 0.0, 0.15)
	var target_zoom = camera_base_zoom - dynamic_zoom_offset - camera_zoom_punch

	if points.size() > 1:
		var viewport_size = get_viewport_rect().size
		var pad_x = 260.0
		var pad_y = 220.0
		var needed_w = (max_x - min_x) + pad_x
		var needed_h = (max_y - min_y) + pad_y
		var zoom_for_w = viewport_size.x / maxf(needed_w, 1.0)
		var zoom_for_h = viewport_size.y / maxf(needed_h, 1.0)
		var zoom_for_dist = minf(zoom_for_w, zoom_for_h)
		target_zoom = minf(target_zoom, zoom_for_dist)

	target_zoom = clampf(target_zoom, 0.33, camera_base_zoom)
	game_camera.zoom = game_camera.zoom.lerp(Vector2(target_zoom, target_zoom), delta * 4.2)

	var current_zoom = game_camera.zoom.x
	var viewport = get_viewport_rect().size
	var half_w = (viewport.x / 2.0) / maxf(current_zoom, 0.1)
	var half_h = (viewport.y / 2.0) / maxf(current_zoom, 0.1)
	target.x = clampf(target.x, half_w, map.SCREEN_W - half_w)
	target.y = clampf(target.y, half_h, map.SCREEN_H - half_h)
	game_camera.position = game_camera.position.lerp(target, delta * 6.0)

func _apply_wave_damage_scaling():
	# +3% melee and ranged damage per wave (applied on top of current stats)
	var mult = 1.03
	player_node.melee_damage = maxi(player_node.melee_damage, int(player_node.melee_damage * mult))
	player_node.ranged_damage = maxi(player_node.ranged_damage, int(player_node.ranged_damage * mult))
	if p2_joined and player2_node:
		player2_node.melee_damage = maxi(player2_node.melee_damage, int(player2_node.melee_damage * mult))
		player2_node.ranged_damage = maxi(player2_node.ranged_damage, int(player2_node.ranged_damage * mult))

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
		"drift_phase": randf_range(0, TAU),  # Horizontal sine drift
		"drift_speed": randf_range(2.0, 4.0),
	})

func start_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

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

func check_all_players_dead():
	var p1_dead = player_node.is_dead
	var p2_dead = not p2_joined or player2_node.is_dead
	if p1_dead and p2_dead:
		trigger_game_over()

func trigger_game_over():
	state = GameState.GAME_OVER
	Engine.time_scale = 1.0
	hitstop_timer = 0.0
	game_over_screen.show_menu()

func resume_from_shop():
	state = GameState.WAVE_ACTIVE
	shop_from_wave = false

func _spawn_player2():
	player2_node = PlayerEntity.new()
	player2_node.action_prefix = "p2_"
	player2_node.player_index = 1
	player2_node.name = "Player2"
	player2_node.position = map.get_fort_center() + Vector2(40, 0)
	entity_layer.add_child(player2_node)
	p2_joined = true
	p2_join_flash_timer = 2.0

func resume_from_level_up():
	state = previous_state

func unpause():
	state = previous_state
	Engine.time_scale = 1.0
	hitstop_timer = 0.0
	if sfx:
		sfx.play_pause()

func enable_companion_session() -> void:
	"""Create and attach companion session when user enables companion mode."""
	if companion_session != null:
		return
	companion_session = CompanionSessionManager.new()
	companion_session.name = "CompanionSession"
	add_child(companion_session)
	companion_session.bomb_drop_requested_at_normalized.connect(_on_companion_bomb_drop)
	companion_session.supply_drop_requested_at_normalized.connect(_on_companion_supply_drop)
	companion_session.emp_drop_requested_at_normalized.connect(_on_companion_emp_drop)
	companion_session.radar_ping_requested.connect(_on_companion_radar_ping)
	companion_session.chopper_input_received.connect(_on_companion_chopper_input)
	world_select._on_companion_session_ready()

func disable_companion_session() -> void:
	"""Remove companion session when user disables companion mode."""
	if companion_session == null:
		return
	companion_session.disconnect_session()
	companion_session.queue_free()
	companion_session = null
	helicopter_entity = null
	_remove_companion_helicopter()
	world_select._on_companion_session_removed()

func restart_game(restore_map_id: int = -1):
	# restore_map_id: -1 = keep current_map_id, else use specified (e.g. after victory)
	if restore_map_id > 0:
		current_map_id = restore_map_id
	# Always reload map config so expansion resets and economy matches
	map.load_map_config(current_map_id)

	for child in enemy_container.get_children():
		child.queue_free()
	for child in ally_container.get_children():
		child.queue_free()
	for child in projectile_container.get_children():
		child.queue_free()
	for child in gold_container.get_children():
		child.queue_free()

	economy.reset()
	economy.configure_for_map(map.map_config)
	progression.reset()
	building_manager.reset()
	unit_manager.reset()
	wave_director.stop()
	player_node.reset()
	particles.clear()

	# Reset companion helicopter reference (projectile_container cleared below)
	helicopter_entity = null

	# Reset P2
	if p2_joined and player2_node:
		player2_node.queue_free()
		player2_node = null
	p2_joined = false
	p2_join_flash_timer = 0.0
	shop_from_wave = false
	wave_complete_pending = false
	wave_complete_timer = 0.0
	wave_grace_timer = 0.0

	# Reset map to initial scale from config
	var initial_scale = map.map_config.get("initial_scale", 1.0)
	map.expand(initial_scale)
	camera_base_zoom = map.map_config.get("camera_base_zoom", 1.5)
	game_camera.position = map.get_fort_center()
	game_camera.zoom = Vector2(camera_base_zoom, camera_base_zoom)

	for b in map.barricades:
		b.reset()
	for d in map.doors:
		d.reset()

	current_wave = 0
	enemies_killed_total = 0
	total_gold_earned = 0
	time_elapsed = 0.0
	wave_announce_text = ""
	wave_announce_timer = 0.0
	hitstop_timer = 0.0
	Engine.time_scale = 1.0
	damage_numbers.clear()
	camera_zoom_punch = 0.0
	chromatic_intensity = 0.0
	if chromatic_overlay:
		chromatic_overlay.visible = false

	player_node.position = map.get_fort_center()
	state = GameState.BETWEEN_WAVES
	shop_menu.show_menu()
	_update_visibility()

func _input(event):
	if state == GameState.WORLD_SELECT:
		if world_select.handle_input(event):
			return
		# Back to launcher (Circle/Esc/B)
		if event.is_action_pressed("ui_back") or event.is_action_pressed("ui_cancel"):
			get_tree().change_scene_to_file("res://launcher.tscn")
			return
	if state == GameState.GAME_OVER:
		if game_over_screen.handle_input(event):
			return
	if state == GameState.PAUSED:
		if pause_menu.handle_input(event):
			return
	if state == GameState.LEVEL_UP:
		if level_up_menu.handle_input(event):
			return
	if state == GameState.BETWEEN_WAVES:
		if shop_menu.handle_input(event):
			return

	if state == GameState.TITLE:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if title_hover == 0:
				restart_game()
			return
		if event.is_action_pressed("confirm"):
			restart_game()
			return
		# Back to world select
		if event.is_action_pressed("ui_back"):
			state = GameState.WORLD_SELECT
			world_select.show_select()
			_update_visibility()
			return

	# P2 drop-in join
	if not p2_joined and state != GameState.TITLE and state != GameState.GAME_OVER:
		if event.is_action_pressed("p2_join"):
			_spawn_player2()
			return

	# Mid-wave shop
	if state == GameState.WAVE_ACTIVE:
		if event.is_action_pressed("open_shop"):
			previous_state = GameState.WAVE_ACTIVE
			state = GameState.BETWEEN_WAVES
			shop_from_wave = true
			shop_menu.show_menu(true)
			return

	if event.is_action_pressed("pause"):
		if state == GameState.WAVE_ACTIVE:
			previous_state = state
			state = GameState.PAUSED
			pause_menu.show_menu()
			if sfx:
				sfx.play_pause()
		elif state == GameState.PAUSED:
			pause_menu.hide_menu()
			unpause()

func _update_damage_numbers(delta: float):
	var i = damage_numbers.size() - 1
	while i >= 0:
		var dn = damage_numbers[i]
		dn.timer -= delta
		dn.position.y += dn.velocity_y * delta
		if dn.timer <= 0:
			damage_numbers.remove_at(i)
		i -= 1

func _draw():
	match state:
		GameState.TITLE:
			_draw_title()
		_:
			_draw_game_overlay()

func _draw_title():
	var font = ThemeDB.fallback_font
	# Dark background
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color8(18, 12, 28))

	# Animated background dots (stoner vibe)
	for i in range(40):
		var bx = fmod(i * 73.0 + title_time * 8.0 * (0.5 + fmod(i * 0.3, 1.0)), SCREEN_W)
		var by = fmod(i * 47.0 + title_time * 3.0 * (0.3 + fmod(i * 0.7, 1.0)), SCREEN_H)
		var ba = 0.08 + 0.06 * sin(title_time * 2.0 + i)
		draw_circle(Vector2(bx, by), 2 + fmod(i, 3), Color(0.5, 0.3, 0.8, ba))

	# Title glow
	var glow_alpha = 0.15 + 0.05 * sin(title_time * 1.5)
	draw_rect(Rect2(200, 90, 880, 100), Color(0.8, 0.3, 0.6, glow_alpha))

	# Main title
	draw_string(font, Vector2(0, 160), "KAREN DEFENSE", HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 64, Color8(255, 140, 180))

	# Subtitle
	draw_string(font, Vector2(0, 210), "A Chill Tower Defense Experience", HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 22, Color8(180, 160, 220))

	# Divider line
	draw_line(Vector2(400, 240), Vector2(880, 240), Color8(100, 80, 140, 120), 1.0)

	# Flavor text
	draw_string(font, Vector2(0, 280), "The Karens are coming to complain about EVERYTHING.", HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 16, Color8(160, 150, 180))
	draw_string(font, Vector2(0, 310), "Defend your fort. Stay chill. Don't let them talk to your manager.", HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 16, Color8(160, 150, 180))

	# Start button
	var btn_rect = Rect2(440, 380, 400, 70)
	var btn_color: Color
	if title_hover == 0:
		btn_color = Color8(70, 130, 70)
	else:
		btn_color = Color8(45, 90, 45)
	draw_rect(btn_rect, btn_color)
	draw_rect(btn_rect, Color8(120, 200, 120), false, 3.0)
	# Pulsing glow on button
	var pulse = 0.5 + 0.5 * sin(title_time * 3.0)
	if title_hover == 0:
		draw_rect(Rect2(btn_rect.position - Vector2(2, 2), btn_rect.size + Vector2(4, 4)), Color(0.4, 1.0, 0.4, 0.15 * pulse), false, 2.0)
	draw_string(font, Vector2(440, 422), "START GAME", HORIZONTAL_ALIGNMENT_CENTER, 400, 32, Color.WHITE)
	draw_string(font, Vector2(440, 446), "Cross / Space / Click to Start  |  Circle: Back", HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color8(180, 220, 180))

	# Controls box
	draw_rect(Rect2(300, 490, 680, 140), Color8(30, 25, 40, 180))
	draw_rect(Rect2(300, 490, 680, 140), Color8(80, 60, 110, 100), false, 1.0)
	draw_string(font, Vector2(300, 520), "CONTROLS", HORIZONTAL_ALIGNMENT_CENTER, 680, 16, Color8(200, 180, 240))
	var controls = [
		"Keyboard: WASD Move | Ctrl Sprint | Space Attack | Q Weapon (hold=wheel, tap=swap) | Shift Dash",
		"PlayStation: L Stick Move | R1 Sprint | R2 Attack | L1 Weapon Wheel/Swap | Cross Dash",
		"F/Triangle: Repair/Door | G/Square: Regroup | Esc/Options: Pause (see Controls tab!)",
	]
	for i in range(controls.size()):
		draw_string(font, Vector2(300, 548 + i * 22), controls[i], HORIZONTAL_ALIGNMENT_CENTER, 680, 12, Color8(150, 140, 170))

	# Footer
	var max_w = map.map_config.get("max_waves", 50)
	draw_string(font, Vector2(0, 670), "Survive %d waves of Karens to win!" % max_w, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 18, Color8(220, 190, 100))

func _draw_game_overlay():
	# Particles drawn on top of game layer (world space)
	particles.draw(self)

	# Enhanced damage numbers (world space - camera handles positioning)
	if damage_numbers.size() > 0:
		var font = ThemeDB.fallback_font
		for dn in damage_numbers:
			var alpha = clampf(dn.timer / 0.3, 0.0, 1.0)
			var col = dn.color
			col.a = alpha
			# Horizontal sine drift for dynamic pop
			var drift_x = sin(time_elapsed * dn.get("drift_speed", 3.0) + dn.get("drift_phase", 0.0)) * 8.0
			var pos = dn.position + shake_offset + Vector2(drift_x, 0)
			# Scale punch: starts big, eases to 1.0
			var life_frac = clampf(dn.timer / 0.9, 0.0, 1.0)
			var sc_punch = dn.get("scale", 2.0)
			var sc = lerpf(1.0, sc_punch, clampf(life_frac * 2.0, 0.0, 1.0))
			# Slight ease-out curve
			sc = 1.0 + (sc - 1.0) * (1.0 - (1.0 - life_frac) * (1.0 - life_frac))
			var rot = dn.get("rotation", 0.0)
			draw_set_transform(pos, rot, Vector2(sc, sc))
			# Shadow
			draw_string(font, Vector2(1, 1), dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0, 0, 0, alpha * 0.6))
			# Main text
			draw_string(font, Vector2.ZERO, dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
			# Bright outline for emphasis on large numbers
			if sc > 1.3:
				draw_string(font, Vector2(-0.5, -0.5), dn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(col.r, col.g, col.b, alpha * 0.3))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# === Screen-space UI overlays (need camera-to-screen transform) ===
	_begin_screen_draw()

	# Speed lines when player moving
	if state == GameState.WAVE_ACTIVE and not player_node.is_dead and player_node.is_moving:
		var speed_alpha = clampf((player_node.move_speed - 140.0) / 250.0, 0.0, 0.1)
		if speed_alpha > 0.01:
			var center = Vector2(SCREEN_W / 2.0, SCREEN_H / 2.0)
			for i in range(8):
				var angle = (float(i) / 8.0) * TAU + fmod(time_elapsed * 1.5, TAU / 8.0)
				var inner_r = 300.0
				var outer_r = maxf(SCREEN_W, SCREEN_H) * 0.55
				var p1 = center + Vector2.from_angle(angle) * inner_r
				var p2 = center + Vector2.from_angle(angle) * outer_r
				draw_line(p1, p2, Color(1, 1, 1, speed_alpha), 1.5)

	# Wave announcement
	if wave_announce_timer > 0 and state == GameState.WAVE_ACTIVE:
		var font = ThemeDB.fallback_font
		var alpha = clampf(wave_announce_timer, 0.0, 1.0)
		draw_rect(Rect2(0, 320, SCREEN_W, 90), Color(0, 0, 0, 0.4 * alpha))
		var title_col = Color(0.3, 1.0, 0.4, alpha) if wave_complete_pending else Color(1, 0.85, 0.2, alpha)
		draw_string(font, Vector2(0, 368), wave_announce_text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 40, title_col)
		draw_string(font, Vector2(0, 398), wave_announce_sub, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_W, 16, Color(0.8, 0.75, 0.5, alpha * 0.8))

	# Grace period countdown
	if wave_grace_timer > 0 and state == GameState.WAVE_ACTIVE and not wave_complete_pending:
		var font = ThemeDB.fallback_font
		var secs = int(ceil(wave_grace_timer))
		draw_rect(Rect2(540, 56, 200, 30), Color(0, 0, 0, 0.5))
		draw_string(font, Vector2(540, 78), "Prep Time: %ds" % secs, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Color8(100, 220, 255))

	_end_screen_draw()

func _begin_screen_draw():
	"""Set up drawing transform so coordinates map to screen space (0-1280, 0-720)."""
	if game_camera:
		var cam_pos = game_camera.position
		var zoom = game_camera.zoom.x
		draw_set_transform(
			cam_pos - Vector2(640.0, 360.0) / zoom,
			0,
			Vector2(1.0 / zoom, 1.0 / zoom)
		)

func _end_screen_draw():
	"""Reset drawing transform back to world space."""
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _add_companion_action(text: String):
	"""Add action to companion feed (newest on top)."""
	if companion_action_feed.size() >= MAX_COMPANION_ACTIONS:
		companion_action_feed.pop_back()
	companion_action_feed.push_front({ "text": text, "timer": 3.0 })

func _on_companion_emp_drop(x: float, y: float):
	if state != GameState.WAVE_ACTIVE or wave_complete_pending: return
	_add_companion_action("Companion: EMP deployed!")
	var m = self.map
	var wx = m.FORT_LEFT + x * (m.FORT_RIGHT - m.FORT_LEFT)
	var wy = m.FORT_TOP + y * (m.FORT_BOTTOM - m.FORT_TOP)
	var emp = EmpEffectEntity.new()
	emp.setup(self, Vector2(wx, wy))
	projectile_container.add_child(emp)

func _on_companion_radar_ping():
	if state != GameState.WAVE_ACTIVE or wave_complete_pending: return
	radar_reveal_timer = 5.0
	_add_companion_action("Companion: Radar active!")
	if sfx:
		sfx.play_repair()  # Use existing sound for now
