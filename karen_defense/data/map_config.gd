class_name MapConfig
extends RefCounted

# Base fort dimensions (used for obstacle positioning)
const BASE_FORT_W: float = 700.0
const BASE_FORT_H: float = 480.0

# Obstacle format: {"x": normalized 0-1, "y": normalized 0-1, "w": pixel width, "h": pixel height}
# These scale with the fort when map expands

# Terrain types for AA-quality environmental design
enum TerrainType {
	WATER,        # Rivers, lakes - impassable or very slow
	CLIFF,        # Rocky cliffs, ice walls - blocks movement and vision
	ROUGH,        # Sand dunes, snow drifts, mud - slows movement
	ELEVATION_HIGH,  # Hills, platforms - tactical high ground
	ELEVATION_LOW,   # Valleys, ditches - tactical low ground
	CHASM,        # Canyons, crevasses - impassable gaps
	BRIDGE        # Crossings over water/chasms - choke points
}
static func get_map_config(map_id: int) -> Dictionary:
	match map_id:
		1:
			return {
				"id": 1,
				"name": "Desert Oasis",
				"max_waves": 15,
				"theme": "desert",
				"world_tier": 1,
				"bg_texture_path": "res://assets/Map1.png",
				"bg_tint": Color(1.05, 0.95, 0.85),
				"obstacles": _desert_obstacles(),
				"terrain": _desert_terrain(),
				"expand_waves": [8],
				"expand_scales": [7.5],
				"initial_scale": 6.0,
				"camera_base_zoom": 1.5,
			}
		2:
			return {
				"id": 2,
				"name": "Frozen Fortress",
				"max_waves": 30,
				"theme": "snow",
				"world_tier": 2,
				"bg_texture_path": "res://assets/map2.png",
				"bg_tint": Color(0.92, 0.95, 1.05),
				"obstacles": _snow_obstacles(),
				"terrain": _snow_terrain(),
				"expand_waves": [10, 20],
				"expand_scales": [7.5, 9.0],
				"initial_scale": 6.0,
				"camera_base_zoom": 1.5,
			}
		3:
			return {
				"id": 3,
				"name": "Jungle Base",
				"max_waves": 50,
				"theme": "jungle",
				"world_tier": 3,
				"bg_texture_path": "res://assets/Map1.png",
				"bg_tint": Color(0.75, 1.0, 0.85),
				"obstacles": _jungle_obstacles(),
				"terrain": _jungle_terrain(),
				"expand_waves": [10, 30],
				"expand_scales": [7.5, 9.0],
				"initial_scale": 6.0,
				"camera_base_zoom": 1.5,
			}
		_:
			return get_map_config(1)

static func _desert_obstacles() -> Array:
	# DESERT OASIS: "Ancient Trade Post Ruins"
	# Premium level design: Compound L/T-shapes, organic rock clusters, tactical lanes, asymmetric flow
	# Focus: Clear approach routes, flanking opportunities, high-low cover variety, natural choke points
	return [
		# === NW: MARKET SQUARE - Sophisticated T/L-shaped stalls with tactical aisles ===
		# Corner anchor (L-shape using 3 pieces)
		{"x": 0.04, "y": 0.04, "w": 36, "h": 18},  # Horizontal base
		{"x": 0.04, "y": 0.08, "w": 18, "h": 34},  # Vertical stem
		{"x": 0.08, "y": 0.08, "w": 14, "h": 14},  # Corner fill

		# T-shaped merchant counter (creates natural cover)
		{"x": 0.13, "y": 0.05, "w": 28, "h": 12},  # Top bar
		{"x": 0.20, "y": 0.07, "w": 14, "h": 26},  # Vertical stem
		{"x": 0.19, "y": 0.12, "w": 16, "h": 10},  # Reinforcement

		# L-shaped textile stall (angled for flow)
		{"x": 0.06, "y": 0.16, "w": 24, "h": 10},  # Long side
		{"x": 0.06, "y": 0.20, "w": 10, "h": 18},  # Short side
		{"x": 0.09, "y": 0.23, "w": 8, "h": 8},    # Corner brace

		# Clustered vendor carts (organic positioning)
		{"x": 0.15, "y": 0.18, "w": 11, "h": 9},
		{"x": 0.18, "y": 0.21, "w": 9, "h": 11},
		{"x": 0.22, "y": 0.17, "w": 10, "h": 8},
		{"x": 0.23, "y": 0.23, "w": 8, "h": 10},

		# Small debris creating micro-cover
		{"x": 0.11, "y": 0.13, "w": 6, "h": 6},
		{"x": 0.25, "y": 0.09, "w": 7, "h": 5},
		{"x": 0.09, "y": 0.26, "w": 5, "h": 7},

		# === NE: CARAVAN STOP - Angled wagon wreckage with asymmetric cargo scatter ===
		# Diagonal wagon body (5-piece angular formation)
		{"x": 0.95, "y": 0.04, "w": 32, "h": 16},  # Main body (angled)
		{"x": 0.92, "y": 0.07, "w": 18, "h": 24},  # Side panel
		{"x": 0.97, "y": 0.09, "w": 24, "h": 14},  # Roof section
		{"x": 0.88, "y": 0.05, "w": 14, "h": 12},  # Wheel debris
		{"x": 0.94, "y": 0.13, "w": 12, "h": 10},  # Axle remains

		# Spilled supply crates (staggered T-formation)
		{"x": 0.87, "y": 0.12, "w": 16, "h": 10},
		{"x": 0.89, "y": 0.16, "w": 10, "h": 14},
		{"x": 0.85, "y": 0.19, "w": 12, "h": 8},

		# Cargo lane (creates flanking route)
		{"x": 0.79, "y": 0.06, "w": 14, "h": 9},
		{"x": 0.81, "y": 0.11, "w": 11, "h": 14},
		{"x": 0.77, "y": 0.15, "w": 9, "h": 11},

		# Scattered goods (irregular cluster)
		{"x": 0.91, "y": 0.21, "w": 10, "h": 8},
		{"x": 0.85, "y": 0.09, "w": 8, "h": 7},
		{"x": 0.93, "y": 0.18, "w": 7, "h": 9},
		{"x": 0.88, "y": 0.24, "w": 6, "h": 6},

		# === SW: OASIS POOL - Circular arc formation with organic palm clusters ===
		# Pool rim (8-piece circular arc, creates natural cover curve)
		{"x": 0.04, "y": 0.92, "w": 18, "h": 12},  # Bottom-left
		{"x": 0.04, "y": 0.88, "w": 14, "h": 16},  # Left side
		{"x": 0.06, "y": 0.84, "w": 12, "h": 14},  # Upper-left curve
		{"x": 0.09, "y": 0.82, "w": 14, "h": 10},  # Top curve
		{"x": 0.13, "y": 0.82, "w": 16, "h": 8},   # Top-right curve
		{"x": 0.17, "y": 0.84, "w": 14, "h": 10},  # Right upper curve
		{"x": 0.19, "y": 0.88, "w": 12, "h": 14},  # Right side
		{"x": 0.18, "y": 0.92, "w": 10, "h": 12},  # Bottom-right

		# Palm stump cluster (organic radial pattern)
		{"x": 0.11, "y": 0.90, "w": 12, "h": 14},  # Center stump
		{"x": 0.08, "y": 0.87, "w": 9, "h": 10},   # Satellite 1
		{"x": 0.14, "y": 0.88, "w": 10, "h": 9},   # Satellite 2
		{"x": 0.10, "y": 0.94, "w": 8, "h": 8},    # Satellite 3

		# Scattered stones (tactical positioning)
		{"x": 0.15, "y": 0.93, "w": 7, "h": 6},
		{"x": 0.07, "y": 0.80, "w": 6, "h": 7},
		{"x": 0.20, "y": 0.86, "w": 6, "h": 6},

		# === SE: WATCHTOWER RUINS - Concentric broken circle with diagonal rubble ===
		# Outer ring (6-piece broken circle)
		{"x": 0.90, "y": 0.88, "w": 18, "h": 10},  # Bottom segment
		{"x": 0.88, "y": 0.84, "w": 12, "h": 16},  # Left segment
		{"x": 0.91, "y": 0.82, "w": 14, "h": 10},  # Top-left
		{"x": 0.96, "y": 0.83, "w": 16, "h": 12},  # Top-right
		{"x": 0.98, "y": 0.88, "w": 10, "h": 14},  # Right segment
		# Gap for entry at bottom-right

		# Inner ring (4-piece smaller circle)
		{"x": 0.92, "y": 0.86, "w": 12, "h": 8},
		{"x": 0.94, "y": 0.84, "w": 8, "h": 10},
		{"x": 0.96, "y": 0.86, "w": 10, "h": 8},
		{"x": 0.94, "y": 0.89, "w": 8, "h": 9},

		# Diagonal rubble scatter (creates asymmetric lanes)
		{"x": 0.84, "y": 0.92, "w": 14, "h": 9},
		{"x": 0.80, "y": 0.88, "w": 11, "h": 12},
		{"x": 0.86, "y": 0.82, "w": 10, "h": 8},
		{"x": 0.92, "y": 0.78, "w": 12, "h": 10},
		{"x": 0.98, "y": 0.77, "w": 8, "h": 8},

		# Small stone fragments
		{"x": 0.88, "y": 0.91, "w": 6, "h": 5},
		{"x": 0.83, "y": 0.85, "w": 5, "h": 6},

		# === OUTER CORRIDORS - Asymmetric cover with flanking lanes ===
		# North corridor (staggered cover, not inline)
		{"x": 0.30, "y": 0.06, "w": 16, "h": 8},
		{"x": 0.33, "y": 0.08, "w": 10, "h": 10},
		{"x": 0.44, "y": 0.05, "w": 14, "h": 9},
		{"x": 0.47, "y": 0.09, "w": 8, "h": 8},
		{"x": 0.57, "y": 0.06, "w": 12, "h": 10},
		{"x": 0.61, "y": 0.08, "w": 9, "h": 7},
		{"x": 0.72, "y": 0.07, "w": 11, "h": 8},

		# South corridor (offset pattern for tactical variety)
		{"x": 0.28, "y": 0.94, "w": 14, "h": 9},
		{"x": 0.31, "y": 0.92, "w": 9, "h": 10},
		{"x": 0.42, "y": 0.95, "w": 16, "h": 8},
		{"x": 0.46, "y": 0.91, "w": 10, "h": 9},
		{"x": 0.59, "y": 0.93, "w": 12, "h": 10},
		{"x": 0.63, "y": 0.95, "w": 8, "h": 8},
		{"x": 0.74, "y": 0.92, "w": 13, "h": 9},

		# West corridor (varied sizes for cover diversity)
		{"x": 0.06, "y": 0.30, "w": 8, "h": 16},
		{"x": 0.08, "y": 0.33, "w": 10, "h": 10},
		{"x": 0.05, "y": 0.44, "w": 9, "h": 14},
		{"x": 0.09, "y": 0.47, "w": 8, "h": 8},
		{"x": 0.06, "y": 0.57, "w": 10, "h": 12},
		{"x": 0.08, "y": 0.61, "w": 7, "h": 9},
		{"x": 0.07, "y": 0.72, "w": 8, "h": 11},

		# East corridor (asymmetric to west)
		{"x": 0.94, "y": 0.28, "w": 9, "h": 14},
		{"x": 0.92, "y": 0.31, "w": 10, "h": 9},
		{"x": 0.95, "y": 0.42, "w": 8, "h": 16},
		{"x": 0.91, "y": 0.46, "w": 9, "h": 10},
		{"x": 0.93, "y": 0.59, "w": 10, "h": 12},
		{"x": 0.95, "y": 0.63, "w": 8, "h": 8},
		{"x": 0.92, "y": 0.74, "w": 9, "h": 13},

		# === RING INTERIOR - Asymmetric tactical strongpoints (no mirroring) ===
		# NW strongpoint (L-formation)
		{"x": 0.14, "y": 0.14, "w": 20, "h": 12},
		{"x": 0.14, "y": 0.18, "w": 12, "h": 18},
		{"x": 0.18, "y": 0.22, "w": 14, "h": 10},
		{"x": 0.20, "y": 0.27, "w": 10, "h": 12},
		{"x": 0.16, "y": 0.31, "w": 8, "h": 8},

		# NE strongpoint (T-formation, different from NW)
		{"x": 0.84, "y": 0.15, "w": 18, "h": 10},
		{"x": 0.80, "y": 0.19, "w": 12, "h": 16},
		{"x": 0.86, "y": 0.23, "w": 10, "h": 14},
		{"x": 0.82, "y": 0.29, "w": 14, "h": 9},
		{"x": 0.78, "y": 0.33, "w": 9, "h": 10},

		# SW strongpoint (zigzag pattern)
		{"x": 0.16, "y": 0.84, "w": 16, "h": 11},
		{"x": 0.19, "y": 0.80, "w": 11, "h": 14},
		{"x": 0.14, "y": 0.78, "w": 13, "h": 10},
		{"x": 0.21, "y": 0.75, "w": 10, "h": 12},
		{"x": 0.17, "y": 0.71, "w": 8, "h": 9},

		# SE strongpoint (diagonal cluster, unique)
		{"x": 0.82, "y": 0.86, "w": 18, "h": 12},
		{"x": 0.86, "y": 0.82, "w": 14, "h": 16},
		{"x": 0.80, "y": 0.80, "w": 12, "h": 11},
		{"x": 0.84, "y": 0.76, "w": 10, "h": 13},
		{"x": 0.78, "y": 0.74, "w": 9, "h": 8},

		# === THE WELL (center) - Premium octagonal landmark with tactical cover ===
		# Well rim (8-piece octagon for premium look)
		{"x": 0.48, "y": 0.48, "w": 14, "h": 6},   # Top-left
		{"x": 0.52, "y": 0.48, "w": 14, "h": 6},   # Top-right
		{"x": 0.46, "y": 0.50, "w": 6, "h": 14},   # Left-top
		{"x": 0.54, "y": 0.50, "w": 6, "h": 14},   # Right-top
		{"x": 0.48, "y": 0.52, "w": 14, "h": 6},   # Bottom-left
		{"x": 0.52, "y": 0.52, "w": 14, "h": 6},   # Bottom-right
		{"x": 0.46, "y": 0.54, "w": 6, "h": 14},   # Left-bottom
		{"x": 0.54, "y": 0.54, "w": 6, "h": 14},   # Right-bottom

		# Cardinal benches (angled for cover)
		{"x": 0.49, "y": 0.38, "w": 12, "h": 8},
		{"x": 0.49, "y": 0.62, "w": 12, "h": 8},
		{"x": 0.38, "y": 0.49, "w": 8, "h": 12},
		{"x": 0.62, "y": 0.49, "w": 8, "h": 12},

		# Diagonal water troughs (offset for asymmetry)
		{"x": 0.41, "y": 0.42, "w": 10, "h": 9},
		{"x": 0.59, "y": 0.43, "w": 9, "h": 10},
		{"x": 0.42, "y": 0.59, "w": 10, "h": 8},
		{"x": 0.58, "y": 0.58, "w": 8, "h": 10},

		# Small accent stones
		{"x": 0.45, "y": 0.45, "w": 5, "h": 5},
		{"x": 0.55, "y": 0.45, "w": 5, "h": 5},
		{"x": 0.45, "y": 0.55, "w": 5, "h": 5},
		{"x": 0.55, "y": 0.55, "w": 5, "h": 5},

		# === INNER APPROACHES - Asymmetric gate defenses ===
		# North approach (offset L-shape)
		{"x": 0.47, "y": 0.26, "w": 14, "h": 9},
		{"x": 0.50, "y": 0.29, "w": 10, "h": 12},
		{"x": 0.53, "y": 0.32, "w": 8, "h": 8},

		# East approach (diagonal formation)
		{"x": 0.74, "y": 0.47, "w": 9, "h": 14},
		{"x": 0.71, "y": 0.50, "w": 12, "h": 10},
		{"x": 0.68, "y": 0.53, "w": 8, "h": 8},

		# South approach (T-shape)
		{"x": 0.48, "y": 0.74, "w": 12, "h": 8},
		{"x": 0.51, "y": 0.71, "w": 10, "h": 11},
		{"x": 0.49, "y": 0.68, "w": 8, "h": 9},

		# West approach (zigzag)
		{"x": 0.26, "y": 0.48, "w": 8, "h": 12},
		{"x": 0.29, "y": 0.51, "w": 11, "h": 10},
		{"x": 0.32, "y": 0.49, "w": 9, "h": 8},

		# === MID-RING TACTICAL COVER - Sophisticated asymmetric placement ===
		# North mid-ring (varied sizes, not symmetrical)
		{"x": 0.30, "y": 0.16, "w": 12, "h": 9},
		{"x": 0.34, "y": 0.18, "w": 8, "h": 10},
		{"x": 0.66, "y": 0.17, "w": 14, "h": 8},
		{"x": 0.70, "y": 0.19, "w": 9, "h": 9},

		# South mid-ring (different pattern from north)
		{"x": 0.32, "y": 0.84, "w": 10, "h": 10},
		{"x": 0.36, "y": 0.82, "w": 9, "h": 8},
		{"x": 0.68, "y": 0.83, "w": 12, "h": 9},
		{"x": 0.72, "y": 0.81, "w": 8, "h": 11},

		# West mid-ring (vertical orientation)
		{"x": 0.16, "y": 0.32, "w": 9, "h": 12},
		{"x": 0.18, "y": 0.36, "w": 10, "h": 8},
		{"x": 0.17, "y": 0.68, "w": 8, "h": 14},
		{"x": 0.19, "y": 0.72, "w": 9, "h": 9},

		# East mid-ring (unique to east)
		{"x": 0.84, "y": 0.30, "w": 10, "h": 10},
		{"x": 0.82, "y": 0.34, "w": 8, "h": 9},
		{"x": 0.83, "y": 0.66, "w": 9, "h": 12},
		{"x": 0.81, "y": 0.70, "w": 11, "h": 8},
	]

static func _snow_obstacles() -> Array:
	# FROZEN FORTRESS: "Fallen Citadel of the Ice King"
	# Premium design: Jagged ice shards, crystalline star patterns, asymmetric pillar forests, tactical depth
	# Focus: Angular formations, crystal clusters, frozen pillar mazes, multi-height cover variety
	return [
		# === NW: FROZEN THRONE - Jagged ice throne with crystalline pillars ===
		# Throne base (angular 7-piece formation)
		{"x": 0.04, "y": 0.04, "w": 20, "h": 14},  # Seat base
		{"x": 0.03, "y": 0.08, "w": 14, "h": 18},  # Left armrest
		{"x": 0.10, "y": 0.08, "w": 14, "h": 18},  # Right armrest
		{"x": 0.05, "y": 0.03, "w": 10, "h": 10},  # Left back spire
		{"x": 0.11, "y": 0.03, "w": 10, "h": 10},  # Right back spire
		{"x": 0.08, "y": 0.02, "w": 8, "h": 6},    # Center spire top
		{"x": 0.07, "y": 0.13, "w": 12, "h": 8},   # Footrest

		# Ice pillar cluster (jagged formation, not grid)
		{"x": 0.15, "y": 0.05, "w": 8, "h": 16},
		{"x": 0.18, "y": 0.08, "w": 10, "h": 14},
		{"x": 0.21, "y": 0.05, "w": 7, "h": 18},
		{"x": 0.24, "y": 0.09, "w": 9, "h": 12},

		# Left pillar row (staggered heights)
		{"x": 0.05, "y": 0.18, "w": 9, "h": 14},
		{"x": 0.08, "y": 0.21, "w": 7, "h": 16},
		{"x": 0.10, "y": 0.24, "w": 8, "h": 12},

		# Crystal star pattern (6-point)
		{"x": 0.16, "y": 0.22, "w": 10, "h": 6},   # Right ray
		{"x": 0.12, "y": 0.22, "w": 10, "h": 6},   # Left ray
		{"x": 0.14, "y": 0.20, "w": 6, "h": 8},    # Top ray
		{"x": 0.14, "y": 0.24, "w": 6, "h": 8},    # Bottom ray
		{"x": 0.14, "y": 0.22, "w": 6, "h": 6},    # Center
		# Diagonal rays
		{"x": 0.12, "y": 0.20, "w": 5, "h": 5},
		{"x": 0.17, "y": 0.20, "w": 5, "h": 5},

		# === NE: BARRACKS - Jagged bunk rows with frozen equipment maze ===
		# Bunk row 1 (segmented ice blocks)
		{"x": 0.90, "y": 0.04, "w": 9, "h": 14},
		{"x": 0.90, "y": 0.10, "w": 9, "h": 12},
		{"x": 0.90, "y": 0.16, "w": 9, "h": 14},

		# Bunk row 2 (offset)
		{"x": 0.94, "y": 0.05, "w": 8, "h": 13},
		{"x": 0.94, "y": 0.11, "w": 8, "h": 14},
		{"x": 0.94, "y": 0.18, "w": 8, "h": 11},

		# Bunk row 3 (varied heights)
		{"x": 0.98, "y": 0.04, "w": 7, "h": 16},
		{"x": 0.98, "y": 0.12, "w": 7, "h": 12},
		{"x": 0.98, "y": 0.17, "w": 7, "h": 13},

		# Equipment racks (L-shapes creating aisles)
		{"x": 0.85, "y": 0.08, "w": 14, "h": 8},
		{"x": 0.87, "y": 0.12, "w": 10, "h": 14},
		{"x": 0.82, "y": 0.14, "w": 12, "h": 9},
		{"x": 0.84, "y": 0.18, "w": 9, "h": 12},

		# Footlocker clusters (organic placement)
		{"x": 0.79, "y": 0.06, "w": 9, "h": 10},
		{"x": 0.76, "y": 0.10, "w": 10, "h": 8},
		{"x": 0.78, "y": 0.15, "w": 8, "h": 9},
		{"x": 0.81, "y": 0.20, "w": 7, "h": 8},

		# === SW: ARMORY VAULT - Weapon rack maze with shield clusters ===
		# Vault door framework (angular 6-piece)
		{"x": 0.04, "y": 0.93, "w": 16, "h": 10},  # Base
		{"x": 0.03, "y": 0.88, "w": 12, "h": 16},  # Left post
		{"x": 0.10, "y": 0.88, "w": 12, "h": 16},  # Right post
		{"x": 0.06, "y": 0.85, "w": 8, "h": 10},   # Left top
		{"x": 0.12, "y": 0.85, "w": 8, "h": 10},   # Right top
		{"x": 0.08, "y": 0.83, "w": 6, "h": 6},    # Center keystone

		# Weapon racks (staggered vertical)
		{"x": 0.15, "y": 0.90, "w": 8, "h": 16},
		{"x": 0.18, "y": 0.88, "w": 9, "h": 18},
		{"x": 0.21, "y": 0.91, "w": 7, "h": 14},
		{"x": 0.24, "y": 0.89, "w": 8, "h": 17},

		# Shield wall (stepped formation)
		{"x": 0.06, "y": 0.78, "w": 12, "h": 9},
		{"x": 0.10, "y": 0.76, "w": 14, "h": 10},
		{"x": 0.14, "y": 0.74, "w": 10, "h": 12},
		{"x": 0.18, "y": 0.77, "w": 12, "h": 9},

		# Scattered armor (irregular placement)
		{"x": 0.08, "y": 0.82, "w": 8, "h": 7},
		{"x": 0.13, "y": 0.81, "w": 7, "h": 8},
		{"x": 0.20, "y": 0.83, "w": 6, "h": 6},

		# === SE: STATUE GARDEN - Frozen warrior formation with ice pedestals ===
		# Command statue pedestal (multi-tier)
		{"x": 0.94, "y": 0.94, "w": 18, "h": 14},  # Base tier
		{"x": 0.95, "y": 0.95, "w": 14, "h": 12},  # Mid tier
		{"x": 0.96, "y": 0.96, "w": 10, "h": 10},  # Top tier
		{"x": 0.92, "y": 0.92, "w": 12, "h": 10},  # Front step

		# Officer statue row (varied heights)
		{"x": 0.88, "y": 0.95, "w": 12, "h": 16},
		{"x": 0.84, "y": 0.93, "w": 11, "h": 14},
		{"x": 0.95, "y": 0.88, "w": 14, "h": 12},
		{"x": 0.93, "y": 0.84, "w": 12, "h": 11},

		# Soldier formation (staggered grid, not aligned)
		{"x": 0.82, "y": 0.90, "w": 10, "h": 12},
		{"x": 0.86, "y": 0.88, "w": 9, "h": 13},
		{"x": 0.79, "y": 0.94, "w": 11, "h": 11},
		{"x": 0.90, "y": 0.82, "w": 12, "h": 10},
		{"x": 0.88, "y": 0.78, "w": 11, "h": 11},
		{"x": 0.94, "y": 0.79, "w": 10, "h": 12},

		# Back rank soldiers (smaller, further)
		{"x": 0.78, "y": 0.86, "w": 8, "h": 10},
		{"x": 0.82, "y": 0.82, "w": 9, "h": 9},
		{"x": 0.86, "y": 0.78, "w": 8, "h": 10},
		{"x": 0.78, "y": 0.90, "w": 7, "h": 8},
		{"x": 0.90, "y": 0.78, "w": 8, "h": 7},

		# Ice monument (background)
		{"x": 0.76, "y": 0.92, "w": 9, "h": 11},
		{"x": 0.92, "y": 0.76, "w": 11, "h": 9},

		# === OUTER CORRIDORS - Jagged ice battlements (varied sizes, asymmetric) ===
		# North wall (irregular crenellations)
		{"x": 0.24, "y": 0.05, "w": 14, "h": 10},
		{"x": 0.30, "y": 0.06, "w": 12, "h": 9},
		{"x": 0.36, "y": 0.05, "w": 15, "h": 11},
		{"x": 0.43, "y": 0.07, "w": 11, "h": 8},
		{"x": 0.50, "y": 0.05, "w": 13, "h": 10},
		{"x": 0.57, "y": 0.06, "w": 14, "h": 9},
		{"x": 0.64, "y": 0.05, "w": 12, "h": 11},
		{"x": 0.71, "y": 0.07, "w": 13, "h": 8},
		{"x": 0.77, "y": 0.06, "w": 11, "h": 10},

		# South wall (different pattern from north)
		{"x": 0.26, "y": 0.95, "w": 13, "h": 10},
		{"x": 0.32, "y": 0.94, "w": 14, "h": 9},
		{"x": 0.39, "y": 0.95, "w": 12, "h": 11},
		{"x": 0.46, "y": 0.93, "w": 15, "h": 8},
		{"x": 0.53, "y": 0.95, "w": 11, "h": 10},
		{"x": 0.60, "y": 0.94, "w": 13, "h": 9},
		{"x": 0.67, "y": 0.95, "w": 14, "h": 11},
		{"x": 0.74, "y": 0.93, "w": 12, "h": 8},
		{"x": 0.80, "y": 0.94, "w": 11, "h": 10},

		# West wall (vertical irregular)
		{"x": 0.05, "y": 0.24, "w": 10, "h": 14},
		{"x": 0.06, "y": 0.30, "w": 9, "h": 12},
		{"x": 0.05, "y": 0.36, "w": 11, "h": 15},
		{"x": 0.07, "y": 0.43, "w": 8, "h": 11},
		{"x": 0.05, "y": 0.50, "w": 10, "h": 13},
		{"x": 0.06, "y": 0.57, "w": 9, "h": 14},
		{"x": 0.05, "y": 0.64, "w": 11, "h": 12},
		{"x": 0.07, "y": 0.71, "w": 8, "h": 13},
		{"x": 0.06, "y": 0.77, "w": 10, "h": 11},

		# East wall (asymmetric to west)
		{"x": 0.95, "y": 0.26, "w": 10, "h": 13},
		{"x": 0.94, "y": 0.32, "w": 9, "h": 14},
		{"x": 0.95, "y": 0.39, "w": 11, "h": 12},
		{"x": 0.93, "y": 0.46, "w": 8, "h": 15},
		{"x": 0.95, "y": 0.53, "w": 10, "h": 11},
		{"x": 0.94, "y": 0.60, "w": 9, "h": 13},
		{"x": 0.95, "y": 0.67, "w": 11, "h": 14},
		{"x": 0.93, "y": 0.74, "w": 8, "h": 12},
		{"x": 0.94, "y": 0.80, "w": 10, "h": 11},

		# === RING INTERIOR - Sophisticated ice tower formations (asymmetric layers) ===
		# NW tower (L-shaped base with spires)
		{"x": 0.14, "y": 0.14, "w": 18, "h": 12},  # Base horizontal
		{"x": 0.14, "y": 0.18, "w": 12, "h": 16},  # Base vertical
		{"x": 0.17, "y": 0.17, "w": 14, "h": 14},  # Mid tier
		{"x": 0.19, "y": 0.20, "w": 10, "h": 11},  # Upper tier
		{"x": 0.21, "y": 0.23, "w": 8, "h": 9},    # Spire
		{"x": 0.16, "y": 0.25, "w": 7, "h": 8},    # Side spire
		{"x": 0.24, "y": 0.17, "w": 8, "h": 7},    # Side spire

		# NE tower (T-shaped, different from NW)
		{"x": 0.84, "y": 0.15, "w": 16, "h": 10},  # Top bar
		{"x": 0.87, "y": 0.19, "w": 11, "h": 14},  # Vertical stem
		{"x": 0.85, "y": 0.22, "w": 13, "h": 12},  # Mid tier
		{"x": 0.87, "y": 0.26, "w": 9, "h": 10},   # Upper tier
		{"x": 0.88, "y": 0.29, "w": 7, "h": 8},    # Spire
		{"x": 0.82, "y": 0.20, "w": 8, "h": 7},    # Side pillar
		{"x": 0.90, "y": 0.24, "w": 7, "h": 9},    # Side pillar

		# SW tower (zigzag formation)
		{"x": 0.15, "y": 0.85, "w": 14, "h": 13},
		{"x": 0.18, "y": 0.82, "w": 12, "h": 15},
		{"x": 0.14, "y": 0.79, "w": 11, "h": 12},
		{"x": 0.20, "y": 0.77, "w": 10, "h": 11},
		{"x": 0.17, "y": 0.74, "w": 8, "h": 9},
		{"x": 0.22, "y": 0.80, "w": 7, "h": 8},
		{"x": 0.13, "y": 0.76, "w": 8, "h": 7},

		# SE tower (radial spires, most complex)
		{"x": 0.86, "y": 0.86, "w": 15, "h": 15},  # Center
		{"x": 0.84, "y": 0.84, "w": 12, "h": 12},  # Inner ring
		{"x": 0.89, "y": 0.84, "w": 10, "h": 11},  # NE spire
		{"x": 0.84, "y": 0.89, "w": 11, "h": 10},  # SW spire
		{"x": 0.82, "y": 0.82, "w": 9, "h": 9},    # Outer NW
		{"x": 0.90, "y": 0.90, "w": 9, "h": 9},    # Outer SE
		{"x": 0.88, "y": 0.79, "w": 7, "h": 8},    # Top accent
		{"x": 0.79, "y": 0.88, "w": 8, "h": 7},    # Bottom accent

		# === THE GREAT HALL (center) - Crystal pillar forest (organic, varied sizes) ===
		# Central cluster (multi-piece landmark)
		{"x": 0.49, "y": 0.49, "w": 14, "h": 16},  # Main pillar
		{"x": 0.51, "y": 0.51, "w": 12, "h": 14},  # Secondary
		{"x": 0.48, "y": 0.52, "w": 10, "h": 12},  # Tertiary
		{"x": 0.52, "y": 0.48, "w": 11, "h": 13},  # Quaternary
		{"x": 0.50, "y": 0.50, "w": 8, "h": 8},    # Center accent

		# Cardinal pillar clusters (each unique)
		# North cluster
		{"x": 0.49, "y": 0.38, "w": 12, "h": 14},
		{"x": 0.51, "y": 0.36, "w": 10, "h": 12},
		{"x": 0.50, "y": 0.40, "w": 9, "h": 10},
		# South cluster
		{"x": 0.50, "y": 0.64, "w": 13, "h": 12},
		{"x": 0.48, "y": 0.62, "w": 11, "h": 14},
		{"x": 0.52, "y": 0.66, "w": 10, "h": 9},
		# West cluster
		{"x": 0.38, "y": 0.50, "w": 14, "h": 11},
		{"x": 0.36, "y": 0.49, "w": 12, "h": 13},
		{"x": 0.40, "y": 0.51, "w": 10, "h": 10},
		# East cluster
		{"x": 0.62, "y": 0.49, "w": 12, "h": 13},
		{"x": 0.64, "y": 0.51, "w": 14, "h": 11},
		{"x": 0.60, "y": 0.50, "w": 9, "h": 12},

		# Diagonal pillar pairs (staggered)
		{"x": 0.41, "y": 0.41, "w": 10, "h": 11},
		{"x": 0.39, "y": 0.39, "w": 9, "h": 10},
		{"x": 0.59, "y": 0.41, "w": 11, "h": 10},
		{"x": 0.61, "y": 0.39, "w": 10, "h": 9},
		{"x": 0.41, "y": 0.59, "w": 10, "h": 10},
		{"x": 0.39, "y": 0.61, "w": 9, "h": 11},
		{"x": 0.59, "y": 0.59, "w": 11, "h": 9},
		{"x": 0.61, "y": 0.61, "w": 10, "h": 10},

		# Outer accent pillars (small, scattered)
		{"x": 0.33, "y": 0.33, "w": 7, "h": 8},
		{"x": 0.67, "y": 0.33, "w": 8, "h": 7},
		{"x": 0.33, "y": 0.67, "w": 7, "h": 8},
		{"x": 0.67, "y": 0.67, "w": 8, "h": 7},

		# === INNER APPROACHES - Ice gate formations (compound shapes) ===
		# North gate (T-formation)
		{"x": 0.48, "y": 0.27, "w": 14, "h": 10},
		{"x": 0.50, "y": 0.30, "w": 10, "h": 12},
		{"x": 0.52, "y": 0.33, "w": 8, "h": 9},

		# East gate (L-formation)
		{"x": 0.73, "y": 0.49, "w": 10, "h": 14},
		{"x": 0.70, "y": 0.51, "w": 12, "h": 10},
		{"x": 0.67, "y": 0.53, "w": 9, "h": 8},

		# South gate (zigzag)
		{"x": 0.49, "y": 0.73, "w": 12, "h": 9},
		{"x": 0.51, "y": 0.70, "w": 10, "h": 11},
		{"x": 0.50, "y": 0.67, "w": 8, "h": 10},

		# West gate (diagonal cluster)
		{"x": 0.27, "y": 0.50, "w": 9, "h": 12},
		{"x": 0.30, "y": 0.52, "w": 11, "h": 10},
		{"x": 0.33, "y": 0.50, "w": 10, "h": 8},

		# === MID-RING ICE MAZE - Jagged crystal shards (varied angles) ===
		# North mid-ring
		{"x": 0.30, "y": 0.16, "w": 12, "h": 10},
		{"x": 0.34, "y": 0.18, "w": 10, "h": 9},
		{"x": 0.66, "y": 0.17, "w": 11, "h": 10},
		{"x": 0.70, "y": 0.19, "w": 9, "h": 8},

		# South mid-ring
		{"x": 0.32, "y": 0.84, "w": 11, "h": 9},
		{"x": 0.36, "y": 0.82, "w": 10, "h": 10},
		{"x": 0.68, "y": 0.83, "w": 12, "h": 9},
		{"x": 0.72, "y": 0.81, "w": 9, "h": 11},

		# West mid-ring
		{"x": 0.16, "y": 0.30, "w": 10, "h": 12},
		{"x": 0.18, "y": 0.34, "w": 9, "h": 10},
		{"x": 0.17, "y": 0.66, "w": 10, "h": 11},
		{"x": 0.19, "y": 0.70, "w": 8, "h": 9},

		# East mid-ring
		{"x": 0.84, "y": 0.32, "w": 9, "h": 11},
		{"x": 0.82, "y": 0.36, "w": 10, "h": 10},
		{"x": 0.83, "y": 0.68, "w": 9, "h": 12},
		{"x": 0.81, "y": 0.72, "w": 11, "h": 9},
	]

static func _jungle_obstacles() -> Array:
	# JUNGLE BASE: "Lost Temple of the Serpent God"
	# Premium design: Organic stone formations, asymmetric ruins, multi-tier platforms, serpent motifs
	# Focus: Ancient architecture, overgrown nature, layered complexity, irregular sacred geometry
	return [
		# === NW: TEMPLE GATEWAY - Monumental entrance with serpent guardian statues ===
		# Gateway arch (multi-piece asymmetric)
		{"x": 0.04, "y": 0.04, "w": 22, "h": 18},  # Left pillar base
		{"x": 0.03, "y": 0.08, "w": 16, "h": 20},  # Left pillar mid
		{"x": 0.04, "y": 0.03, "w": 14, "h": 12},  # Left pillar top
		{"x": 0.12, "y": 0.04, "w": 18, "h": 22},  # Right pillar base
		{"x": 0.14, "y": 0.03, "w": 20, "h": 16},  # Right pillar mid
		{"x": 0.13, "y": 0.06, "w": 12, "h": 14},  # Right pillar top
		{"x": 0.07, "y": 0.02, "w": 16, "h": 8},   # Lintel stone

		# Left guardian serpent (curved formation)
		{"x": 0.06, "y": 0.14, "w": 14, "h": 16},  # Body segment 1
		{"x": 0.08, "y": 0.18, "w": 12, "h": 14},  # Body segment 2
		{"x": 0.10, "y": 0.22, "w": 10, "h": 12},  # Body segment 3
		{"x": 0.11, "y": 0.26, "w": 9, "h": 10},   # Tail

		# Right guardian serpent (mirror but asymmetric)
		{"x": 0.16, "y": 0.06, "w": 16, "h": 14},
		{"x": 0.19, "y": 0.09, "w": 14, "h": 12},
		{"x": 0.22, "y": 0.12, "w": 12, "h": 10},
		{"x": 0.24, "y": 0.15, "w": 10, "h": 9},

		# Ceremonial braziers (stone pedestals)
		{"x": 0.10, "y": 0.11, "w": 9, "h": 10},
		{"x": 0.17, "y": 0.18, "w": 10, "h": 9},

		# Fallen gateway stones (irregular scatter)
		{"x": 0.20, "y": 0.07, "w": 11, "h": 9},
		{"x": 0.07, "y": 0.20, "w": 9, "h": 11},
		{"x": 0.15, "y": 0.25, "w": 8, "h": 8},
		{"x": 0.25, "y": 0.15, "w": 7, "h": 9},
		{"x": 0.12, "y": 0.30, "w": 6, "h": 7},

		# === NE: SACRED GROVE - Ancient tree stump with organic root system ===
		# Great tree stump (irregular organic shape)
		{"x": 0.94, "y": 0.04, "w": 18, "h": 20},  # Main trunk
		{"x": 0.96, "y": 0.06, "w": 16, "h": 16},  # Core
		{"x": 0.92, "y": 0.03, "w": 14, "h": 16},  # Side growth
		{"x": 0.95, "y": 0.08, "w": 12, "h": 14},  # Upper section

		# Root system (radiating tendrils)
		{"x": 0.89, "y": 0.05, "w": 14, "h": 10},  # Root 1
		{"x": 0.86, "y": 0.08, "w": 12, "h": 12},  # Root 2
		{"x": 0.93, "y": 0.12, "w": 13, "h": 11},  # Root 3
		{"x": 0.97, "y": 0.14, "w": 11, "h": 14},  # Root 4
		{"x": 0.91, "y": 0.16, "w": 10, "h": 12},  # Root 5

		# Stone circle (asymmetric placement)
		{"x": 0.85, "y": 0.14, "w": 10, "h": 11},  # Stone 1
		{"x": 0.88, "y": 0.18, "w": 9, "h": 10},   # Stone 2
		{"x": 0.82, "y": 0.17, "w": 11, "h": 9},   # Stone 3
		{"x": 0.90, "y": 0.10, "w": 8, "h": 10},   # Stone 4

		# Satellite stumps (scattered)
		{"x": 0.78, "y": 0.06, "w": 11, "h": 10},
		{"x": 0.80, "y": 0.12, "w": 10, "h": 9},
		{"x": 0.84, "y": 0.22, "w": 9, "h": 11},
		{"x": 0.90, "y": 0.24, "w": 8, "h": 9},
		{"x": 0.86, "y": 0.08, "w": 8, "h": 8},
		{"x": 0.92, "y": 0.20, "w": 7, "h": 8},

		# === SW: RITUAL CHAMBER - Tiered altar with ceremonial channels ===
		# Altar platform (stepped pyramid)
		{"x": 0.04, "y": 0.94, "w": 20, "h": 18},  # Base tier
		{"x": 0.05, "y": 0.95, "w": 16, "h": 16},  # Mid tier
		{"x": 0.06, "y": 0.96, "w": 12, "h": 12},  # Top tier
		{"x": 0.03, "y": 0.92, "w": 14, "h": 12},  # Front steps

		# Offering tables (L-shaped formations)
		{"x": 0.12, "y": 0.94, "w": 14, "h": 10},
		{"x": 0.14, "y": 0.90, "w": 10, "h": 12},
		{"x": 0.17, "y": 0.92, "w": 12, "h": 11},

		# Ceremonial pillars (asymmetric pair)
		{"x": 0.10, "y": 0.86, "w": 10, "h": 12},
		{"x": 0.15, "y": 0.84, "w": 11, "h": 10},
		{"x": 0.18, "y": 0.87, "w": 9, "h": 11},

		# Blood channels (diagonal carved grooves)
		{"x": 0.20, "y": 0.89, "w": 11, "h": 14},
		{"x": 0.22, "y": 0.85, "w": 9, "h": 12},
		{"x": 0.12, "y": 0.79, "w": 10, "h": 11},

		# Incense burner pedestals (scattered)
		{"x": 0.24, "y": 0.93, "w": 8, "h": 9},
		{"x": 0.08, "y": 0.78, "w": 9, "h": 8},
		{"x": 0.16, "y": 0.81, "w": 7, "h": 8},
		{"x": 0.22, "y": 0.82, "w": 8, "h": 7},

		# Sacrificial channels (side elements)
		{"x": 0.06, "y": 0.88, "w": 12, "h": 9},
		{"x": 0.03, "y": 0.84, "w": 10, "h": 11},
		{"x": 0.25, "y": 0.88, "w": 9, "h": 10},

		# === SE: OBSERVATORY - Tiered platform with collapsed dome ruins ===
		# Dome foundation (irregular collapse)
		{"x": 0.94, "y": 0.94, "w": 18, "h": 20},  # Main section
		{"x": 0.96, "y": 0.96, "w": 16, "h": 16},  # Center
		{"x": 0.92, "y": 0.92, "w": 14, "h": 16},  # Side fragment
		{"x": 0.95, "y": 0.90, "w": 12, "h": 14},  # Upper piece

		# Platform tiers (stepped formation)
		{"x": 0.89, "y": 0.95, "w": 14, "h": 12},  # Lower tier
		{"x": 0.86, "y": 0.92, "w": 12, "h": 14},  # Mid tier
		{"x": 0.93, "y": 0.89, "w": 13, "h": 11},  # Upper tier
		{"x": 0.90, "y": 0.86, "w": 11, "h": 12},  # Top tier

		# Star chart tablets (angled placement)
		{"x": 0.85, "y": 0.88, "w": 10, "h": 11},
		{"x": 0.88, "y": 0.84, "w": 11, "h": 10},
		{"x": 0.82, "y": 0.85, "w": 9, "h": 10},

		# Telescope mount (broken base)
		{"x": 0.80, "y": 0.90, "w": 11, "h": 13},
		{"x": 0.83, "y": 0.93, "w": 9, "h": 10},
		{"x": 0.91, "y": 0.80, "w": 12, "h": 11},
		{"x": 0.88, "y": 0.78, "w": 10, "h": 9},

		# Observation marker stones (circular pattern)
		{"x": 0.78, "y": 0.94, "w": 9, "h": 10},
		{"x": 0.94, "y": 0.78, "w": 10, "h": 9},
		{"x": 0.82, "y": 0.78, "w": 8, "h": 9},
		{"x": 0.76, "y": 0.86, "w": 9, "h": 8},
		{"x": 0.90, "y": 0.76, "w": 8, "h": 8},
		{"x": 0.86, "y": 0.82, "w": 7, "h": 8},

		# === OUTER SANCTUM - Organic overgrown vegetation (asymmetric dense jungle) ===
		# North sanctum (irregular cluster sizes, varied placement)
		{"x": 0.20, "y": 0.05, "w": 14, "h": 12},
		{"x": 0.24, "y": 0.07, "w": 12, "h": 11},
		{"x": 0.30, "y": 0.05, "w": 13, "h": 10},
		{"x": 0.36, "y": 0.06, "w": 11, "h": 12},
		{"x": 0.42, "y": 0.05, "w": 14, "h": 11},
		{"x": 0.48, "y": 0.07, "w": 12, "h": 10},
		{"x": 0.54, "y": 0.06, "w": 13, "h": 12},
		{"x": 0.60, "y": 0.05, "w": 11, "h": 11},
		{"x": 0.66, "y": 0.07, "w": 14, "h": 10},
		{"x": 0.72, "y": 0.06, "w": 12, "h": 12},
		{"x": 0.78, "y": 0.05, "w": 13, "h": 11},

		# South sanctum (different pattern)
		{"x": 0.22, "y": 0.95, "w": 13, "h": 12},
		{"x": 0.28, "y": 0.93, "w": 14, "h": 11},
		{"x": 0.34, "y": 0.95, "w": 12, "h": 13},
		{"x": 0.40, "y": 0.94, "w": 11, "h": 10},
		{"x": 0.46, "y": 0.95, "w": 14, "h": 12},
		{"x": 0.52, "y": 0.93, "w": 12, "h": 11},
		{"x": 0.58, "y": 0.95, "w": 13, "h": 13},
		{"x": 0.64, "y": 0.94, "w": 11, "h": 10},
		{"x": 0.70, "y": 0.95, "w": 14, "h": 12},
		{"x": 0.76, "y": 0.93, "w": 12, "h": 11},
		{"x": 0.82, "y": 0.95, "w": 11, "h": 13},

		# West sanctum (vertical, all unique sizes)
		{"x": 0.05, "y": 0.20, "w": 12, "h": 14},
		{"x": 0.07, "y": 0.24, "w": 11, "h": 12},
		{"x": 0.05, "y": 0.30, "w": 10, "h": 13},
		{"x": 0.06, "y": 0.36, "w": 12, "h": 11},
		{"x": 0.05, "y": 0.42, "w": 11, "h": 14},
		{"x": 0.07, "y": 0.48, "w": 10, "h": 12},
		{"x": 0.06, "y": 0.54, "w": 12, "h": 13},
		{"x": 0.05, "y": 0.60, "w": 11, "h": 11},
		{"x": 0.07, "y": 0.66, "w": 10, "h": 14},
		{"x": 0.06, "y": 0.72, "w": 12, "h": 12},
		{"x": 0.05, "y": 0.78, "w": 11, "h": 13},

		# East sanctum (completely asymmetric to west)
		{"x": 0.95, "y": 0.22, "w": 12, "h": 13},
		{"x": 0.93, "y": 0.28, "w": 11, "h": 14},
		{"x": 0.95, "y": 0.34, "w": 13, "h": 12},
		{"x": 0.94, "y": 0.40, "w": 10, "h": 11},
		{"x": 0.95, "y": 0.46, "w": 12, "h": 14},
		{"x": 0.93, "y": 0.52, "w": 11, "h": 12},
		{"x": 0.95, "y": 0.58, "w": 13, "h": 13},
		{"x": 0.94, "y": 0.64, "w": 10, "h": 11},
		{"x": 0.95, "y": 0.70, "w": 12, "h": 14},
		{"x": 0.93, "y": 0.76, "w": 11, "h": 12},
		{"x": 0.95, "y": 0.82, "w": 13, "h": 11},

		# === INNER TEMPLE GARDENS - Multi-layer ruins (creates "rooms") ===
		# Northwest garden chamber (L-shaped ruins creating tactical space)
		{"x": 0.10, "y": 0.10, "w": 18, "h": 16},  # Outer wall 1
		{"x": 0.14, "y": 0.09, "w": 16, "h": 14},  # Outer wall 2
		{"x": 0.09, "y": 0.14, "w": 14, "h": 18},  # Outer wall 3
		{"x": 0.12, "y": 0.18, "w": 12, "h": 14},  # Mid-layer corner
		{"x": 0.16, "y": 0.13, "w": 14, "h": 12},  # Mid-layer extension
		{"x": 0.11, "y": 0.22, "w": 10, "h": 11},  # Inner fragment 1
		{"x": 0.15, "y": 0.17, "w": 11, "h": 10},  # Inner fragment 2
		{"x": 0.19, "y": 0.21, "w": 9, "h": 9},    # Center pillar
		{"x": 0.20, "y": 0.11, "w": 8, "h": 10},   # Scattered stone 1
		{"x": 0.10, "y": 0.24, "w": 7, "h": 8},    # Scattered stone 2

		# Northeast garden chamber (T-shaped ruins with irregular wings)
		{"x": 0.90, "y": 0.10, "w": 16, "h": 18},  # Main column
		{"x": 0.86, "y": 0.09, "w": 14, "h": 16},  # Left wing base
		{"x": 0.94, "y": 0.09, "w": 14, "h": 16},  # Right wing base
		{"x": 0.88, "y": 0.13, "w": 12, "h": 14},  # Left wing mid
		{"x": 0.92, "y": 0.13, "w": 12, "h": 14},  # Right wing mid
		{"x": 0.90, "y": 0.17, "w": 11, "h": 12},  # Central core
		{"x": 0.85, "y": 0.17, "w": 10, "h": 10},  # Left fragment
		{"x": 0.95, "y": 0.17, "w": 10, "h": 10},  # Right fragment
		{"x": 0.90, "y": 0.21, "w": 9, "h": 9},    # Inner shrine
		{"x": 0.83, "y": 0.11, "w": 8, "h": 7},    # Outer debris

		# Southwest garden chamber (Stepped pyramid ruins)
		{"x": 0.10, "y": 0.90, "w": 18, "h": 17},  # Base tier
		{"x": 0.11, "y": 0.88, "w": 16, "h": 15},  # Second tier offset
		{"x": 0.13, "y": 0.86, "w": 14, "h": 13},  # Third tier
		{"x": 0.15, "y": 0.84, "w": 12, "h": 11},  # Fourth tier
		{"x": 0.17, "y": 0.82, "w": 10, "h": 9},   # Top platform
		{"x": 0.09, "y": 0.84, "w": 11, "h": 14},  # Side chamber left
		{"x": 0.19, "y": 0.88, "w": 13, "h": 11},  # Side chamber right
		{"x": 0.14, "y": 0.80, "w": 9, "h": 10},   # Upper alcove
		{"x": 0.08, "y": 0.92, "w": 8, "h": 9},    # Fallen block 1
		{"x": 0.21, "y": 0.91, "w": 7, "h": 8},    # Fallen block 2

		# Southeast garden chamber (Radial petal formation)
		{"x": 0.90, "y": 0.90, "w": 16, "h": 16},  # Central hub
		{"x": 0.88, "y": 0.86, "w": 14, "h": 12},  # Petal NW
		{"x": 0.94, "y": 0.86, "w": 12, "h": 14},  # Petal NE
		{"x": 0.88, "y": 0.94, "w": 12, "h": 14},  # Petal SW
		{"x": 0.94, "y": 0.94, "w": 14, "h": 12},  # Petal SE
		{"x": 0.86, "y": 0.90, "w": 11, "h": 10},  # Extension W
		{"x": 0.94, "y": 0.90, "w": 10, "h": 11},  # Extension E
		{"x": 0.90, "y": 0.84, "w": 10, "h": 9},   # Extension N
		{"x": 0.90, "y": 0.96, "w": 9, "h": 10},   # Extension S
		{"x": 0.92, "y": 0.88, "w": 8, "h": 8},    # Inner accent

		# === THE TEMPLE HEART (center) - Sacred shrine with radiating paths ===
		# Central serpent shrine (organic multi-piece formation)
		{"x": 0.50, "y": 0.50, "w": 18, "h": 16},  # Core head
		{"x": 0.48, "y": 0.48, "w": 16, "h": 14},  # Body segment 1
		{"x": 0.52, "y": 0.52, "w": 14, "h": 16},  # Body segment 2
		{"x": 0.46, "y": 0.46, "w": 14, "h": 12},  # Coil NW
		{"x": 0.54, "y": 0.46, "w": 12, "h": 14},  # Coil NE
		{"x": 0.46, "y": 0.54, "w": 12, "h": 14},  # Coil SW
		{"x": 0.54, "y": 0.54, "w": 14, "h": 12},  # Coil SE
		{"x": 0.50, "y": 0.44, "w": 11, "h": 10},  # Head crest
		{"x": 0.50, "y": 0.56, "w": 10, "h": 11},  # Tail end

		# Cardinal shrine pedestals (asymmetric placement)
		{"x": 0.50, "y": 0.38, "w": 13, "h": 12},  # North pedestal
		{"x": 0.48, "y": 0.36, "w": 11, "h": 10},  # North accent
		{"x": 0.50, "y": 0.62, "w": 12, "h": 13},  # South pedestal
		{"x": 0.52, "y": 0.64, "w": 10, "h": 11},  # South accent
		{"x": 0.38, "y": 0.50, "w": 12, "h": 13},  # West pedestal
		{"x": 0.36, "y": 0.48, "w": 10, "h": 11},  # West accent
		{"x": 0.62, "y": 0.50, "w": 13, "h": 12},  # East pedestal
		{"x": 0.64, "y": 0.52, "w": 11, "h": 10},  # East accent

		# Diagonal offering stones (irregular sizes)
		{"x": 0.42, "y": 0.42, "w": 11, "h": 10},
		{"x": 0.58, "y": 0.42, "w": 10, "h": 11},
		{"x": 0.42, "y": 0.58, "w": 10, "h": 10},
		{"x": 0.58, "y": 0.58, "w": 11, "h": 11},

		# === PROCESSIONAL PATHWAYS - Asymmetric approach routes ===
		# North approach (irregular stepped platforms)
		{"x": 0.50, "y": 0.30, "w": 14, "h": 12},  # Center platform
		{"x": 0.48, "y": 0.26, "w": 12, "h": 11},  # Step left
		{"x": 0.52, "y": 0.26, "w": 11, "h": 12},  # Step right
		{"x": 0.50, "y": 0.34, "w": 10, "h": 9},   # Lower tier
		# South approach (different pattern)
		{"x": 0.50, "y": 0.70, "w": 13, "h": 14},  # Center platform
		{"x": 0.46, "y": 0.74, "w": 11, "h": 12},  # Step left
		{"x": 0.54, "y": 0.74, "w": 12, "h": 11},  # Step right
		{"x": 0.50, "y": 0.66, "w": 9, "h": 10},   # Upper tier
		# West approach (asymmetric to east)
		{"x": 0.30, "y": 0.50, "w": 12, "h": 14},  # Center platform
		{"x": 0.26, "y": 0.48, "w": 11, "h": 12},  # Step upper
		{"x": 0.26, "y": 0.52, "w": 12, "h": 11},  # Step lower
		{"x": 0.34, "y": 0.50, "w": 9, "h": 10},   # Inner tier
		# East approach (unique configuration)
		{"x": 0.70, "y": 0.50, "w": 14, "h": 13},  # Center platform
		{"x": 0.74, "y": 0.46, "w": 12, "h": 11},  # Step upper
		{"x": 0.74, "y": 0.54, "w": 11, "h": 12},  # Step lower
		{"x": 0.66, "y": 0.50, "w": 10, "h": 9},   # Inner tier

		# === KEEPER CHAMBERS - Final gauntlet to inner keep ===
		# NW Guardian statue complex (multi-piece formation)
		{"x": 0.26, "y": 0.24, "w": 16, "h": 14},  # Statue base
		{"x": 0.24, "y": 0.22, "w": 14, "h": 12},  # Pedestal
		{"x": 0.28, "y": 0.26, "w": 12, "h": 11},  # Statue body
		{"x": 0.30, "y": 0.28, "w": 10, "h": 9},   # Altar stone
		{"x": 0.22, "y": 0.26, "w": 9, "h": 10},   # Offering plate
		# SE Guardian statue complex (asymmetric mirror)
		{"x": 0.74, "y": 0.76, "w": 14, "h": 16},  # Statue base
		{"x": 0.76, "y": 0.78, "w": 12, "h": 14},  # Pedestal
		{"x": 0.72, "y": 0.74, "w": 11, "h": 12},  # Statue body
		{"x": 0.70, "y": 0.72, "w": 9, "h": 10},   # Altar stone
		{"x": 0.78, "y": 0.74, "w": 10, "h": 9},   # Offering plate
		# SW Guardian statue complex (different pattern)
		{"x": 0.24, "y": 0.74, "w": 14, "h": 16},  # Statue base
		{"x": 0.22, "y": 0.76, "w": 12, "h": 14},  # Pedestal
		{"x": 0.26, "y": 0.72, "w": 11, "h": 12},  # Statue body
		{"x": 0.28, "y": 0.70, "w": 9, "h": 10},   # Altar stone
		{"x": 0.20, "y": 0.74, "w": 10, "h": 9},   # Offering plate
		# NE Guardian statue complex (unique configuration)
		{"x": 0.76, "y": 0.26, "w": 16, "h": 14},  # Statue base
		{"x": 0.78, "y": 0.24, "w": 14, "h": 12},  # Pedestal
		{"x": 0.74, "y": 0.28, "w": 12, "h": 11},  # Statue body
		{"x": 0.72, "y": 0.30, "w": 10, "h": 9},   # Altar stone
		{"x": 0.80, "y": 0.26, "w": 9, "h": 10},   # Offering plate

		# === MID-RING VEGETATION - Living temple (organic cover) ===
		# NW cluster (irregular organic formation)
		{"x": 0.30, "y": 0.14, "w": 13, "h": 12},
		{"x": 0.28, "y": 0.16, "w": 11, "h": 10},
		{"x": 0.32, "y": 0.12, "w": 10, "h": 11},
		# NE cluster (asymmetric)
		{"x": 0.70, "y": 0.14, "w": 12, "h": 13},
		{"x": 0.72, "y": 0.16, "w": 10, "h": 11},
		{"x": 0.68, "y": 0.12, "w": 11, "h": 10},
		# SW cluster (different sizes)
		{"x": 0.30, "y": 0.86, "w": 14, "h": 11},
		{"x": 0.28, "y": 0.84, "w": 10, "h": 12},
		{"x": 0.32, "y": 0.88, "w": 11, "h": 9},
		# SE cluster (unique pattern)
		{"x": 0.70, "y": 0.86, "w": 11, "h": 14},
		{"x": 0.72, "y": 0.84, "w": 12, "h": 10},
		{"x": 0.68, "y": 0.88, "w": 9, "h": 11},
		# W cluster (tall organic)
		{"x": 0.14, "y": 0.30, "w": 11, "h": 13},
		{"x": 0.12, "y": 0.32, "w": 10, "h": 11},
		{"x": 0.16, "y": 0.28, "w": 9, "h": 12},
		# W-S cluster
		{"x": 0.14, "y": 0.70, "w": 12, "h": 14},
		{"x": 0.12, "y": 0.68, "w": 11, "h": 10},
		{"x": 0.16, "y": 0.72, "w": 10, "h": 11},
		# E-N cluster
		{"x": 0.86, "y": 0.30, "w": 13, "h": 12},
		{"x": 0.88, "y": 0.32, "w": 11, "h": 10},
		{"x": 0.84, "y": 0.28, "w": 10, "h": 11},
		# E-S cluster
		{"x": 0.86, "y": 0.70, "w": 12, "h": 13},
		{"x": 0.88, "y": 0.68, "w": 10, "h": 11},
		{"x": 0.84, "y": 0.72, "w": 11, "h": 10},
	]

static func obstacles_to_rects(obstacles: Array, fort_left: float, fort_top: float, fort_w: float, fort_h: float) -> Array:
	var rects: Array[Rect2] = []
	for obs in obstacles:
		var w = obs.get("w", 48) * (fort_w / BASE_FORT_W)
		var h = obs.get("h", 48) * (fort_h / BASE_FORT_H)
		var x = fort_left + obs.get("x", 0.5) * fort_w - w / 2.0
		var y = fort_top + obs.get("y", 0.5) * fort_h - h / 2.0
		rects.append(Rect2(x, y, w, h))
	return rects

static func terrain_to_rects(terrain: Array, fort_left: float, fort_top: float, fort_w: float, fort_h: float) -> Array:
	"""Convert normalized terrain definitions to world-space rects with type metadata."""
	var terrain_rects: Array = []
	for t in terrain:
		var w = t.get("w", 48) * (fort_w / BASE_FORT_W)
		var h = t.get("h", 48) * (fort_h / BASE_FORT_H)
		var x = fort_left + t.get("x", 0.5) * fort_w - w / 2.0
		var y = fort_top + t.get("y", 0.5) * fort_h - h / 2.0
		terrain_rects.append({
			"rect": Rect2(x, y, w, h),
			"type": t.get("type", TerrainType.ROUGH),
			"blocks_movement": t.get("blocks_movement", false),
			"blocks_vision": t.get("blocks_vision", false),
			"movement_penalty": t.get("movement_penalty", 0.0)
		})
	return terrain_rects

static func _desert_terrain() -> Array:
	# DESERT OASIS TERRAIN: Canyon walls, dry riverbeds, sand dunes creating natural boundaries
	return [
		# === CANYON WALLS (west side) - Natural barriers creating asymmetric map shape ===
		{"x": 0.02, "y": 0.12, "w": 80, "h": 240, "type": TerrainType.CLIFF, "blocks_movement": true, "blocks_vision": true},
		{"x": 0.03, "y": 0.45, "w": 60, "h": 180, "type": TerrainType.CLIFF, "blocks_movement": true, "blocks_vision": true},

		# === DRY RIVERBED (diagonal northeast to southwest) - Rough terrain slowing movement ===
		{"x": 0.65, "y": 0.12, "w": 90, "h": 45, "type": TerrainType.ROUGH, "movement_penalty": 0.3},
		{"x": 0.58, "y": 0.22, "w": 85, "h": 50, "type": TerrainType.ROUGH, "movement_penalty": 0.3},
		{"x": 0.50, "y": 0.35, "w": 95, "h": 55, "type": TerrainType.ROUGH, "movement_penalty": 0.3},
		{"x": 0.42, "y": 0.50, "w": 90, "h": 60, "type": TerrainType.ROUGH, "movement_penalty": 0.3},
		{"x": 0.32, "y": 0.66, "w": 100, "h": 65, "type": TerrainType.ROUGH, "movement_penalty": 0.3},
		{"x": 0.22, "y": 0.82, "w": 85, "h": 50, "type": TerrainType.ROUGH, "movement_penalty": 0.3},

		# === SAND DUNES (east side) - Elevated tactical positions ===
		{"x": 0.88, "y": 0.18, "w": 110, "h": 95, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.92, "y": 0.35, "w": 95, "h": 85, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.90, "y": 0.55, "w": 105, "h": 90, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.88, "y": 0.75, "w": 100, "h": 88, "type": TerrainType.ELEVATION_HIGH},

		# === ROCKY OUTCROPS (scattered) - Small blocking terrain for cover variety ===
		{"x": 0.35, "y": 0.15, "w": 45, "h": 38, "type": TerrainType.CLIFF, "blocks_movement": true},
		{"x": 0.62, "y": 0.48, "w": 52, "h": 42, "type": TerrainType.CLIFF, "blocks_movement": true},
		{"x": 0.48, "y": 0.78, "w": 48, "h": 40, "type": TerrainType.CLIFF, "blocks_movement": true},

		# === CHASM (northwest corner) - Impassable gap creating unique routing ===
		{"x": 0.08, "y": 0.08, "w": 75, "h": 65, "type": TerrainType.CHASM, "blocks_movement": true, "blocks_vision": false},
	]

static func _snow_terrain() -> Array:
	# FROZEN FORTRESS TERRAIN: Ice cliffs, frozen lakes, snowdrifts creating defensive layers
	return [
		# === ICE CLIFFS (outer perimeter) - Jagged fortress boundaries ===
		{"x": 0.01, "y": 0.15, "w": 50, "h": 280, "type": TerrainType.CLIFF, "blocks_movement": true, "blocks_vision": true},
		{"x": 0.99, "y": 0.18, "w": 50, "h": 260, "type": TerrainType.CLIFF, "blocks_movement": true, "blocks_vision": true},
		{"x": 0.18, "y": 0.01, "w": 260, "h": 50, "type": TerrainType.CLIFF, "blocks_movement": true, "blocks_vision": true},
		{"x": 0.20, "y": 0.99, "w": 250, "h": 50, "type": TerrainType.CLIFF, "blocks_movement": true, "blocks_vision": true},

		# === FROZEN LAKE (north) - Slippery terrain with movement penalty ===
		{"x": 0.35, "y": 0.10, "w": 145, "h": 75, "type": TerrainType.ROUGH, "movement_penalty": 0.4},
		{"x": 0.50, "y": 0.12, "w": 135, "h": 68, "type": TerrainType.ROUGH, "movement_penalty": 0.4},
		{"x": 0.62, "y": 0.10, "w": 125, "h": 72, "type": TerrainType.ROUGH, "movement_penalty": 0.4},

		# === FROZEN LAKE (south) - Mirror formation ===
		{"x": 0.32, "y": 0.90, "w": 140, "h": 70, "type": TerrainType.ROUGH, "movement_penalty": 0.4},
		{"x": 0.48, "y": 0.88, "w": 130, "h": 75, "type": TerrainType.ROUGH, "movement_penalty": 0.4},
		{"x": 0.65, "y": 0.90, "w": 135, "h": 68, "type": TerrainType.ROUGH, "movement_penalty": 0.4},

		# === SNOWDRIFT CORRIDORS (inner maze enhancement) - Slow zones ===
		{"x": 0.12, "y": 0.35, "w": 85, "h": 110, "type": TerrainType.ROUGH, "movement_penalty": 0.25},
		{"x": 0.88, "y": 0.38, "w": 80, "h": 105, "type": TerrainType.ROUGH, "movement_penalty": 0.25},
		{"x": 0.38, "y": 0.12, "w": 105, "h": 75, "type": TerrainType.ROUGH, "movement_penalty": 0.25},
		{"x": 0.40, "y": 0.88, "w": 100, "h": 72, "type": TerrainType.ROUGH, "movement_penalty": 0.25},

		# === ICE CREVASSES (tactical gaps) - Narrow impassable chasms ===
		{"x": 0.25, "y": 0.28, "w": 65, "h": 35, "type": TerrainType.CHASM, "blocks_movement": true},
		{"x": 0.75, "y": 0.65, "w": 70, "h": 38, "type": TerrainType.CHASM, "blocks_movement": true},
		{"x": 0.58, "y": 0.40, "w": 55, "h": 30, "type": TerrainType.CHASM, "blocks_movement": true},

		# === RAMPARTS (elevated positions) - High ground advantage ===
		{"x": 0.15, "y": 0.15, "w": 85, "h": 75, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.85, "y": 0.18, "w": 80, "h": 70, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.17, "y": 0.85, "w": 82, "h": 73, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.83, "y": 0.82, "w": 78, "h": 72, "type": TerrainType.ELEVATION_HIGH},
	]

static func _jungle_terrain() -> Array:
	# JUNGLE TEMPLE TERRAIN: Rivers, muddy ground, elevated platforms, ravines - maximum environmental variety
	return [
		# === SACRED RIVER (flowing west to east, S-curve) - Impassable water ===
		{"x": 0.08, "y": 0.25, "w": 95, "h": 55, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.15, "y": 0.35, "w": 100, "h": 60, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.25, "y": 0.42, "w": 110, "h": 65, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.38, "y": 0.48, "w": 115, "h": 68, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.52, "y": 0.52, "w": 120, "h": 70, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.65, "y": 0.55, "w": 115, "h": 65, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.78, "y": 0.58, "w": 105, "h": 62, "type": TerrainType.WATER, "blocks_movement": true},
		{"x": 0.88, "y": 0.62, "w": 95, "h": 58, "type": TerrainType.WATER, "blocks_movement": true},

		# === STONE BRIDGES (crossing river) - Critical choke points ===
		{"x": 0.22, "y": 0.38, "w": 45, "h": 22, "type": TerrainType.BRIDGE},
		{"x": 0.48, "y": 0.50, "w": 48, "h": 24, "type": TerrainType.BRIDGE},
		{"x": 0.75, "y": 0.57, "w": 42, "h": 20, "type": TerrainType.BRIDGE},

		# === MUDDY SWAMP (north sector) - Heavy movement penalty ===
		{"x": 0.25, "y": 0.12, "w": 125, "h": 85, "type": TerrainType.ROUGH, "movement_penalty": 0.5},
		{"x": 0.40, "y": 0.15, "w": 115, "h": 78, "type": TerrainType.ROUGH, "movement_penalty": 0.5},
		{"x": 0.55, "y": 0.10, "w": 120, "h": 82, "type": TerrainType.ROUGH, "movement_penalty": 0.5},

		# === MUDDY SWAMP (south sector) ===
		{"x": 0.30, "y": 0.88, "w": 118, "h": 80, "type": TerrainType.ROUGH, "movement_penalty": 0.5},
		{"x": 0.48, "y": 0.85, "w": 125, "h": 88, "type": TerrainType.ROUGH, "movement_penalty": 0.5},
		{"x": 0.62, "y": 0.90, "w": 115, "h": 75, "type": TerrainType.ROUGH, "movement_penalty": 0.5},

		# === TEMPLE PLATFORMS (elevated ruins) - High ground tactical positions ===
		{"x": 0.10, "y": 0.10, "w": 95, "h": 85, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.90, "y": 0.12, "w": 90, "h": 88, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.12, "y": 0.88, "w": 92, "h": 82, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.88, "y": 0.85, "w": 88, "h": 90, "type": TerrainType.ELEVATION_HIGH},
		{"x": 0.50, "y": 0.50, "w": 105, "h": 100, "type": TerrainType.ELEVATION_HIGH},  # Central temple heart

		# === JUNGLE RAVINES (impassable gaps) - Forces routing around ===
		{"x": 0.18, "y": 0.65, "w": 75, "h": 40, "type": TerrainType.CHASM, "blocks_movement": true},
		{"x": 0.82, "y": 0.28, "w": 70, "h": 42, "type": TerrainType.CHASM, "blocks_movement": true},
		{"x": 0.65, "y": 0.78, "w": 68, "h": 38, "type": TerrainType.CHASM, "blocks_movement": true},

		# === DENSE JUNGLE UNDERGROWTH (scattered) - Minor obstacles ===
		{"x": 0.72, "y": 0.15, "w": 55, "h": 48, "type": TerrainType.ROUGH, "movement_penalty": 0.2},
		{"x": 0.28, "y": 0.70, "w": 58, "h": 50, "type": TerrainType.ROUGH, "movement_penalty": 0.2},
		{"x": 0.15, "y": 0.50, "w": 52, "h": 45, "type": TerrainType.ROUGH, "movement_penalty": 0.2},
		{"x": 0.85, "y": 0.45, "w": 50, "h": 48, "type": TerrainType.ROUGH, "movement_penalty": 0.2},
	]
