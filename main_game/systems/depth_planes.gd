class_name DepthPlanes
extends RefCounted

## VerticalTiers: Side-view beat-em-up with Y-based tiers (platforms, ground, underground).
## Entities in same tier can hit each other. Higher tier = higher on screen = smaller (back), lower = bigger (front).
## Alias: DepthPlanes name kept for compatibility; PLANE_* = TIER_*.

const PLANE_COUNT: int = 4
# Tier Y ranges: [min, max] - tier 0=skybridge, 1=platform, 2=ground, 3=underground
const TIER_BANDS: Array = [
	Vector2(80.0, 170.0),   # skybridge
	Vector2(180.0, 260.0),  # platform
	Vector2(280.0, 420.0),  # ground
	Vector2(450.0, 580.0),  # underground
]
const PLANE_CENTERS: Array = [125.0, 220.0, 350.0, 515.0]  # Center of each tier
const PLANE_SCALES: Array = [0.80, 0.90, 1.0, 1.1]  # Back (high) smaller, front (low) bigger

static func get_plane_index(y: float) -> int:
	for i in range(PLANE_COUNT):
		if i < TIER_BANDS.size():
			var band = TIER_BANDS[i]
			if y >= band.x and y <= band.y:
				return i
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
	return PLANE_CENTERS[clampi(plane_index, 0, PLANE_COUNT - 1)]

static func are_in_same_plane(y1: float, y2: float) -> bool:
	return get_plane_index(y1) == get_plane_index(y2)

static func get_scale_for_y(y: float) -> float:
	var idx = get_plane_index(y)
	return PLANE_SCALES[idx]

static func get_plane_bounds(plane_index: int) -> Vector2:
	if plane_index >= 0 and plane_index < TIER_BANDS.size():
		return TIER_BANDS[plane_index]
	var c = get_plane_center(plane_index)
	return Vector2(c - 50.0, c + 50.0)
