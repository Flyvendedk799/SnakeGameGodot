class_name AnimationConfig
extends Resource

## AAA Visual Upgrade: Centralized animation parameters for consistent feel
## This resource provides all animation timing, ease curves, and squash/stretch values

# Spring physics parameters
@export var squash_spring_strength: float = 180.0
@export var squash_damping: float = 12.0
@export var squash_min: float = 0.3
@export var squash_max: float = 1.8

# Landing squash
@export var landing_squash_light: float = 0.75  # Low impact
@export var landing_squash_medium: float = 0.65  # Medium impact
@export var landing_squash_heavy: float = 0.55  # High impact
@export var landing_recovery_time: float = 0.25

# Jump squash
@export var jump_anticipation_squash: float = 0.85  # Pre-jump crouch
@export var jump_anticipation_time: float = 0.05  # Wind-up duration
@export var jump_launch_squash: float = 1.3  # Launch stretch
@export var jump_apex_squash: float = 1.12  # Float at top

# Attack squash
@export var attack_anticipation_squash: float = 0.90  # Wind-up
@export var attack_anticipation_time: float = 0.05  # Wind-up duration
@export var attack_strike_squash: float = 1.35  # Impact
@export var attack_recovery_time: float = 0.12

# Walk cycle
@export var walk_frequency: float = 8.0  # Hz
@export var walk_bob_amplitude: float = 2.5  # pixels
@export var walk_hip_sway: float = 1.5  # pixels

# Idle breathing
@export var idle_frequency: float = 2.0  # Hz
@export var idle_amplitude: float = 1.2  # pixels

# Entity spawn
@export var spawn_scale_start: float = 0.8
@export var spawn_duration: float = 0.25

# Ease curve settings
enum EaseCurve {
	LINEAR,
	EASE_OUT_QUAD,
	EASE_OUT_CUBIC,
	EASE_OUT_EXPO,
	EASE_OUT_BACK,
	EASE_OUT_ELASTIC,
	EASE_OUT_SPRING
}

@export var landing_ease: EaseCurve = EaseCurve.EASE_OUT_ELASTIC
@export var jump_ease: EaseCurve = EaseCurve.EASE_OUT_BACK
@export var attack_ease: EaseCurve = EaseCurve.EASE_OUT_EXPO

# Singleton instance
static var instance: AnimationConfig = null

static func get_config() -> AnimationConfig:
	"""Get singleton instance, loading default config if needed."""
	if instance == null:
		var config_path = "res://main_game/data/default_animation_config.tres"
		if ResourceLoader.exists(config_path):
			instance = load(config_path)
		else:
			# Fallback to new instance with defaults
			instance = AnimationConfig.new()
	return instance

## Ease Function Implementations

static func apply_ease(t: float, curve: EaseCurve) -> float:
	"""Apply ease curve to normalized time value (0.0 to 1.0)."""
	t = clampf(t, 0.0, 1.0)
	match curve:
		EaseCurve.LINEAR:
			return t
		EaseCurve.EASE_OUT_QUAD:
			return 1.0 - (1.0 - t) * (1.0 - t)
		EaseCurve.EASE_OUT_CUBIC:
			return 1.0 - pow(1.0 - t, 3.0)
		EaseCurve.EASE_OUT_EXPO:
			return 1.0 if t >= 1.0 else 1.0 - pow(2.0, -10.0 * t)
		EaseCurve.EASE_OUT_BACK:
			var c1 = 1.70158
			var c3 = c1 + 1.0
			return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
		EaseCurve.EASE_OUT_ELASTIC:
			if t <= 0.0: return 0.0
			if t >= 1.0: return 1.0
			var c4 = (2.0 * PI) / 3.0
			return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0
		EaseCurve.EASE_OUT_SPRING:
			return 1.0 - (cos(t * PI * 3.5) * exp(-t * 4.0))
		_:
			return t
