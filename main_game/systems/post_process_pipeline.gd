class_name PostProcessPipeline
extends Node

## Phase 1.1: Multi-pass GPU post-process pipeline coordinator
## 3-pass chain using SubViewport + CanvasLayer architecture:
##   Pass 1 — Bloom Extract: render scene, extract brights (Luma > threshold),
##             dual-kawase blur at half-res + quarter-res, additive blend.
##   Pass 2 — Tonemap + Color: ACES/Reinhard, per-theme LUT (256x16 strip).
##   Pass 3 — Final compositing: Edge detection, chromatic, vignette, film grain,
##             scanlines — one efficient pass.
##
## NOTE: The current single-pass post_cinematic.gdshader already handles all of
## these in one shader (which is GPU-optimal for 2D). This pipeline class manages
## the orchestration layer and per-theme LUT loading, ready for when SubViewport
## multi-pass is needed for more complex effects.

var game = null

# Pass nodes
var bloom_viewport: SubViewport = null
var tonemap_viewport: SubViewport = null
var final_canvas: CanvasLayer = null

# LUT state
var current_lut: Texture2D = null
var lut_map: Dictionary = {}   # theme_name → Texture2D (256x16 strips)

# Passes enabled
var bloom_pass_enabled: bool = true
var lut_pass_enabled: bool = true

# Pipeline state forwarded from PostProcessLayer
var _post_process_layer: PostProcessLayer = null

func setup(game_ref):
	game = game_ref
	_find_post_process_layer()
	_preload_luts()

func _find_post_process_layer():
	"""Locate the existing PostProcessLayer for parameter routing."""
	if game.get("post_process") and game.post_process is PostProcessLayer:
		_post_process_layer = game.post_process

# ---------------------------------------------------------------------------
# LUT Management (Phase 1.1: per-theme LUT 256x16 strip)
# ---------------------------------------------------------------------------

func _preload_luts():
	"""Load per-theme LUT PNGs from assets/luts/, or generate procedurally."""
	var themes = ["grass", "cave", "sky", "summit", "lava", "ice"]
	for theme in themes:
		var path = "res://assets/luts/%s_lut.png" % theme
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				lut_map[theme] = tex
		else:
			# Phase 1.1: Generate procedural LUT when PNG not available
			var gen_tex = LUTGenerator.generate_lut(theme)
			if gen_tex:
				lut_map[theme] = gen_tex

func generate_colorblind_luts(colorblind_mode: String):
	"""Regenerate LUTs with colorblind correction overlay."""
	var themes = ["grass", "cave", "sky", "summit", "lava", "ice"]
	for theme in themes:
		var gen_tex = LUTGenerator.generate_lut(theme, colorblind_mode)
		if gen_tex:
			lut_map[theme] = gen_tex
	# Re-apply current theme
	if game and game.map:
		set_theme_lut(game.map.level_config.get("theme", "grass"))

func set_theme_lut(theme: String):
	"""Switch active LUT to the given theme."""
	if lut_map.has(theme):
		current_lut = lut_map[theme]
		_apply_lut_to_shader(current_lut)
	else:
		current_lut = null
		_apply_lut_to_shader(null)

func _apply_lut_to_shader(lut: Texture2D):
	"""Forward LUT texture to post_cinematic shader lut pass."""
	if _post_process_layer == null:
		return
	# Use the PostProcessLayer's public API (Phase 1.1)
	if _post_process_layer.has_method("apply_lut_texture"):
		_post_process_layer.apply_lut_texture(lut as ImageTexture, 0.72)

# ---------------------------------------------------------------------------
# Bloom pass configuration (Phase 1.1)
# ---------------------------------------------------------------------------

func set_bloom_pass(enabled: bool, threshold: float = 0.35, radius: float = 4.5):
	"""Configure the bloom extraction pass parameters."""
	bloom_pass_enabled = enabled
	if _post_process_layer and _post_process_layer.cel_mat:
		_post_process_layer.cel_mat.set_shader_parameter("bloom_threshold", threshold)
		_post_process_layer.cel_mat.set_shader_parameter("bloom_radius", radius)

# ---------------------------------------------------------------------------
# Phase 1.3: Temporal smoothing hint (shader-side in future)
# ---------------------------------------------------------------------------

func set_temporal_blend(amount: float):
	"""Set temporal anti-aliasing blend factor (for future SubViewport ping-pong)."""
	# Currently a no-op placeholder — temporal blend would be implemented
	# via ping-pong SubViewport textures when two render targets are available.
	pass

# ---------------------------------------------------------------------------
# Pipeline update
# ---------------------------------------------------------------------------

func update(delta: float):
	"""Called each frame. Dynamically adjusts shader params based on game state."""
	if _post_process_layer == null or _post_process_layer.cel_mat == null:
		return
	if game == null:
		return

	var mat: ShaderMaterial = _post_process_layer.cel_mat

	# --- Combat intensity: lower bloom threshold during action for punchier hits ---
	var near_enemy_count = 0
	if game.get("enemy_container"):
		for e in game.enemy_container.get_children():
			if game.get("player_node") and game.player_node:
				if game.player_node.position.distance_to(e.position) < 350.0:
					near_enemy_count += 1
	var combat_t = clampf(float(near_enemy_count) / 5.0, 0.0, 1.0)

	var base_threshold: float = mat.get_shader_parameter("bloom_threshold") if mat.get_shader_parameter("bloom_threshold") else 0.38
	var combat_threshold = lerpf(base_threshold, 0.22, combat_t * 0.6)
	mat.set_shader_parameter("bloom_threshold", lerpf(
		mat.get_shader_parameter("bloom_threshold"), combat_threshold, delta * 3.0))

	# --- Time-of-day: modulate warm/cool tint via parallax backdrop ---
	if game.get("map") and game.map.get("parallax_backdrop"):
		var tod = game.map.parallax_backdrop.get("time_of_day") if game.map.parallax_backdrop.get("time_of_day") != null else 0.5
		# Warm at dawn/dusk (tod ≈ 0.25 and 0.75), cool at noon (tod = 0.5)
		var warmth = sin(tod * TAU) * 0.5 + 0.5   # peaks at tod=0.25 (dawn)
		var warm_boost = Color(warmth * 0.08, warmth * 0.04, 0.0)
		var cool_boost = Color(0.0, 0.0, (1.0 - warmth) * 0.06)
		mat.set_shader_parameter("warm_tint", warm_boost)
		mat.set_shader_parameter("cool_tint", cool_boost)

	# --- Low HP: desaturate slightly for dread feel ---
	if game.get("player_node") and game.player_node and not game.player_node.is_dead:
		var hp_ratio = float(game.player_node.current_hp) / float(maxf(game.player_node.max_hp, 1))
		if hp_ratio < 0.3:
			var dread = lerpf(1.0, 0.65, (0.3 - hp_ratio) / 0.3)
			mat.set_shader_parameter("saturation",
				lerpf(mat.get_shader_parameter("saturation"), dread, delta * 2.0))
