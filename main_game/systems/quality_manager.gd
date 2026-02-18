class_name QualityManager
extends Node

## Phase 1.3: Runtime quality tier switching
## Ultra: 1.0 scale, full bloom radius
## High: 0.95 scale
## Medium: 0.9 scale, reduced bloom samples
## Temporal smoothing: blend 10% of previous frame for motion blur reduction at 60fps

enum QualityTier { ULTRA, HIGH, MEDIUM }

var current_tier: QualityTier = QualityTier.ULTRA
var game = null

# Per-tier bloom radius overrides applied to post_process
const TIER_PARAMS = {
	QualityTier.ULTRA:  {"scale": 1.00, "bloom_radius": 4.5,  "bloom_samples": 3, "grain_strength_mult": 1.0},
	QualityTier.HIGH:   {"scale": 0.95, "bloom_radius": 3.5,  "bloom_samples": 2, "grain_strength_mult": 0.8},
	QualityTier.MEDIUM: {"scale": 0.90, "bloom_radius": 2.5,  "bloom_samples": 1, "grain_strength_mult": 0.6},
}

# Temporal smoothing state (Phase 1.3)
var _prev_frame_buffer: Array = []  # placeholder — actual temporal blend in shader
const TEMPORAL_BLEND: float = 0.10  # 10% previous frame blend

func setup(game_ref):
	game = game_ref
	_apply_tier(current_tier)

func set_tier(tier: QualityTier):
	if tier == current_tier:
		return
	current_tier = tier
	_apply_tier(tier)

func set_tier_by_name(name: String):
	match name.to_lower():
		"ultra":  set_tier(QualityTier.ULTRA)
		"high":   set_tier(QualityTier.HIGH)
		"medium": set_tier(QualityTier.MEDIUM)

func get_tier_name() -> String:
	match current_tier:
		QualityTier.ULTRA:  return "Ultra"
		QualityTier.HIGH:   return "High"
		QualityTier.MEDIUM: return "Medium"
	return "Ultra"

func _apply_tier(tier: QualityTier):
	var params = TIER_PARAMS.get(tier, TIER_PARAMS[QualityTier.ULTRA])

	# Apply internal render scale (Godot 4: viewport scaling)
	var vp = get_viewport()
	if vp:
		vp.scaling_3d_scale = params.scale  # Godot uses this for 2D stretch too in some modes
		# For 2D: can also adjust Canvas item scale for perf
		# set_physics_process / set_process at lower priority on MEDIUM tier
		if tier == QualityTier.MEDIUM:
			Engine.max_fps = 60  # Already capped
		else:
			Engine.max_fps = 0   # Uncapped for Ultra/High

	# Apply bloom radius to post-process
	if game and game.get("post_process") and game.post_process:
		var pp = game.post_process
		if pp.get("cel_mat") and pp.cel_mat:
			pp.cel_mat.set_shader_parameter("bloom_radius", params.bloom_radius)
			pp.cel_mat.set_shader_parameter("grain_strength",
				pp.cel_mat.get_shader_parameter("grain_strength") * params.grain_strength_mult)

	print("[QualityManager] Tier set to: %s (scale=%.2f, bloom_radius=%.1f)" % [
		get_tier_name(), params.scale, params.bloom_radius])

func _process(delta: float):
	# Auto-downgrade if FPS drops severely
	var fps = Engine.get_frames_per_second()
	if fps < 40 and current_tier != QualityTier.MEDIUM:
		set_tier(QualityTier.MEDIUM)
		print("[QualityManager] Auto-downgraded to Medium (FPS=%d)" % fps)
	elif fps > 55 and current_tier == QualityTier.MEDIUM:
		set_tier(QualityTier.HIGH)
		print("[QualityManager] Auto-upgraded to High (FPS=%d)" % fps)
