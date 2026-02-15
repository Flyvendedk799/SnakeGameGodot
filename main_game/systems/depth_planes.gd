class_name DepthPlanes
extends RefCounted

## AAA Visual Upgrade: Smooth Y-based depth scaling for pseudo-3D sidescroller
## Entities higher = smaller (back), lower = bigger (front) with continuous smooth curve
## Maintains backward-compatible tier system for collision detection

# Smooth depth parameters
const DEPTH_Y_MIN: float = 80.0   # Top of playable area (skybridge)
const DEPTH_Y_MAX: float = 580.0  # Bottom of playable area (underground)
const DEPTH_SCALE_RANGE: float = 0.25  # Scale variation (±12.5% from center)
const DEPTH_SHADOW_RANGE: float = 0.3  # Shadow opacity variation

## Smooth Depth Functions (AAA Upgrade)

static func ease_in_out_quad(t: float) -> float:
	"""Quadratic S-curve for natural depth perception."""
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0

static func get_depth_factor(y: float) -> float:
	"""Returns 0.0 (top/back) to 1.0 (bottom/front) based on Y position."""
	var t = clampf((y - DEPTH_Y_MIN) / (DEPTH_Y_MAX - DEPTH_Y_MIN), 0.0, 1.0)
	return ease_in_out_quad(t)  # Smooth S-curve

static func get_scale_for_y(y: float) -> float:
	"""Returns visual scale (0.875 to 1.125) based on Y position with smooth curve."""
	var depth = get_depth_factor(y)
	# Map 0.0 (back) -> 0.875, 0.5 (middle) -> 1.0, 1.0 (front) -> 1.125
	return 1.0 - (1.0 - depth) * DEPTH_SCALE_RANGE + depth * DEPTH_SCALE_RANGE * 0.5

static func get_shadow_alpha_for_y(y: float) -> float:
	"""Returns shadow opacity (0.4 to 0.7) based on depth. Front = darker shadows."""
	var depth = get_depth_factor(y)
	return 0.4 + depth * DEPTH_SHADOW_RANGE

static func get_shadow_scale_for_y(y: float) -> float:
	"""Returns shadow size multiplier (0.8 to 1.2) based on depth. Front = larger shadows."""
	var depth = get_depth_factor(y)
	return 0.8 + depth * 0.4

static func get_parallax_factor_for_y(y: float) -> float:
	"""Returns parallax scroll factor (0.85 to 1.0) based on Y. Front = more parallax."""
	var depth = get_depth_factor(y)
	return 0.85 + depth * 0.15

## Backward-Compatible Tier System (for collision detection)

const PLANE_COUNT: int = 4
# Tier Y ranges: [min, max] - tier 0=skybridge, 1=platform, 2=ground, 3=underground
const TIER_BANDS: Array = [
	Vector2(80.0, 170.0),   # skybridge
	Vector2(180.0, 260.0),  # platform
	Vector2(280.0, 420.0),  # ground
	Vector2(450.0, 580.0),  # underground
]
const PLANE_CENTERS: Array = [125.0, 220.0, 350.0, 515.0]  # Center of each tier

static func get_plane_index(y: float) -> int:
	"""Returns which tier (0-3) a Y position belongs to for collision detection."""
	for i in range(PLANE_COUNT):
		if i < TIER_BANDS.size():
			var band = TIER_BANDS[i]
			if y >= band.x and y <= band.y:
				return i
	# Fallback: find nearest tier center
	var best = 0
	var best_dist = INF
	for i in range(PLANE_COUNT):
		var c = PLANE_CENTERS[i]
		var d = absf(y - c)
		if d < best_dist:
			best_dist = d
			best = i
	return best

static func get_plane_center(plane_index: int) -> float:
	"""Returns center Y coordinate of a tier."""
	return PLANE_CENTERS[clampi(plane_index, 0, PLANE_COUNT - 1)]

static func are_in_same_plane(y1: float, y2: float) -> bool:
	"""Returns true if two Y positions are in the same collision tier."""
	return get_plane_index(y1) == get_plane_index(y2)

static func get_plane_bounds(plane_index: int) -> Vector2:
	"""Returns [min, max] Y bounds of a tier."""
	if plane_index >= 0 and plane_index < TIER_BANDS.size():
		return TIER_BANDS[plane_index]
	var c = get_plane_center(plane_index)
	return Vector2(c - 50.0, c + 50.0)
