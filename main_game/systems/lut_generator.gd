class_name LUTGenerator
extends RefCounted

## Phase 1.1: Procedural LUT (Look-Up Table) texture generator
## Creates 256x16 strip LUTs per theme when PNG files are absent.
## A 256x16 LUT encodes 16x16x16 color correction in a single strip:
##   X axis = 16 blue slabs, each 16 pixels wide (R 0-15 per slab)
##   Y axis = G 0-15
## This matches the standard Godot/post_lut.gdshader layout.

# Fog preset → fog params dict
const FOG_PRESETS: Dictionary = {
	"none":   {"density": 0.0,  "start_y": 0.5, "end_y": 0.95, "top_haze": 0.0, "color": Color(0,0,0,0)},
	"light":  {"density": 0.10, "start_y": 0.4, "end_y": 0.95, "top_haze": 0.0, "color": Color(0.06,0.10,0.16,0.7)},
	"medium": {"density": 0.22, "start_y": 0.3, "end_y": 0.95, "top_haze": 0.0, "color": Color(0.05,0.08,0.14,0.85)},
	"dense":  {"density": 0.45, "start_y": 0.2, "end_y": 0.98, "top_haze": 0.0, "color": Color(0.04,0.05,0.10,0.95)},
	"sky":    {"density": 0.08, "start_y": 0.5, "end_y": 0.95, "top_haze": 0.25,"color": Color(0.55,0.72,0.95,0.6)},
	"lava":   {"density": 0.28, "start_y": 0.25,"end_y": 0.95, "top_haze": 0.0, "color": Color(0.30,0.06,0.02,0.9)},
	"snow":   {"density": 0.15, "start_y": 0.35,"end_y": 0.95, "top_haze": 0.12,"color": Color(0.72,0.82,0.95,0.7)},
}

# Per-theme LUT color adjustments:
# Each entry is: {shadows: Color, mids: Color, highlights: Color, saturation: float, contrast: float}
const THEME_LUTS: Dictionary = {
	"grass": {
		"shadows":    Color(0.02, 0.03, 0.00),   # Warm shadow tint (deep green)
		"mids":       Color(0.00, 0.02, -0.01),  # Slight green push
		"highlights": Color(0.04, 0.03, -0.02),  # Warm highlights
		"saturation": 1.18,
		"contrast":   1.08,
	},
	"cave": {
		"shadows":    Color(0.02, 0.01, 0.04),   # Deep purple-blue shadows
		"mids":       Color(-0.02, -0.01, 0.02), # Blue desaturation
		"highlights": Color(0.01, 0.02, 0.05),   # Cool blue highlights
		"saturation": 0.82,
		"contrast":   1.18,
	},
	"lava": {
		"shadows":    Color(0.03, -0.01, -0.02), # Red-brown deep shadows
		"mids":       Color(0.05, -0.02, -0.03), # Orange push
		"highlights": Color(0.08, 0.04, -0.04),  # Bright orange-yellow
		"saturation": 1.35,
		"contrast":   1.12,
	},
	"sky": {
		"shadows":    Color(0.00, 0.01, 0.03),   # Soft blue shadows
		"mids":       Color(0.00, 0.01, 0.02),   # Light blue
		"highlights": Color(0.02, 0.03, 0.05),   # Bright sky
		"saturation": 1.22,
		"contrast":   1.05,
	},
	"summit": {
		"shadows":    Color(0.01, 0.01, 0.03),   # Cool white-blue
		"mids":       Color(0.00, 0.00, 0.02),   # Slight blue push
		"highlights": Color(0.02, 0.02, 0.04),   # Icy highlights
		"saturation": 0.88,
		"contrast":   1.10,
	},
	"ice": {
		"shadows":    Color(0.00, 0.01, 0.04),   # Ice blue shadows
		"mids":       Color(-0.01, 0.00, 0.03),  # Blue-white
		"highlights": Color(0.01, 0.02, 0.06),   # Bright icy
		"saturation": 0.85,
		"contrast":   1.08,
	},
}

# Colorblind variant LUT adjustments
const COLORBLIND_ADJUSTMENTS: Dictionary = {
	"deuteranopia": {  # Red-green deficiency (green weak)
		"shadows":    Color(0.04, -0.02, 0.03),
		"mids":       Color(0.06, -0.03, 0.04),
		"highlights": Color(0.08, -0.04, 0.05),
		"saturation": 1.1,
		"contrast":   1.05,
	},
	"protanopia": {  # Red-green deficiency (red weak)
		"shadows":    Color(-0.02, 0.02, 0.05),
		"mids":       Color(-0.03, 0.03, 0.06),
		"highlights": Color(-0.04, 0.04, 0.08),
		"saturation": 1.12,
		"contrast":   1.05,
	},
}

static func generate_lut(theme: String, colorblind_mode: String = "") -> ImageTexture:
	"""Generate a 256x16 LUT texture for the given theme."""
	var lut_data = THEME_LUTS.get(theme, THEME_LUTS["grass"])

	# Optionally blend in colorblind adjustment
	if not colorblind_mode.is_empty() and COLORBLIND_ADJUSTMENTS.has(colorblind_mode):
		var cb = COLORBLIND_ADJUSTMENTS[colorblind_mode]
		lut_data = {
			"shadows":    lut_data.shadows + cb.shadows * 0.5,
			"mids":       lut_data.mids + cb.mids * 0.5,
			"highlights": lut_data.highlights + cb.highlights * 0.5,
			"saturation": lut_data.saturation * 0.5 + cb.saturation * 0.5,
			"contrast":   lut_data.contrast * 0.5 + cb.contrast * 0.5,
		}

	var img = Image.create(256, 16, false, Image.FORMAT_RGBA8)

	for b in range(16):
		for g in range(16):
			for r in range(16):
				# Normalize to 0-1
				var rv = float(r) / 15.0
				var gv = float(g) / 15.0
				var bv = float(b) / 15.0

				# Apply theme LUT color transform
				var col = _apply_lut_transform(rv, gv, bv, lut_data)

				# Pixel position in 256x16 strip: slab b at x = b*16+r, y = g
				var px = b * 16 + r
				var py = g
				img.set_pixel(px, py, Color(clampf(col.r, 0.0, 1.0), clampf(col.g, 0.0, 1.0), clampf(col.b, 0.0, 1.0), 1.0))

	return ImageTexture.create_from_image(img)

static func _apply_lut_transform(r: float, g: float, b: float, data: Dictionary) -> Color:
	"""Apply shadows/mids/highlights split-toning + saturation + contrast."""
	# Luminance to determine shadows/mids/highlights split
	var luma = r * 0.2126 + g * 0.7152 + b * 0.0722

	# Tri-zone weighting
	var shadow_w    = clampf(1.0 - luma / 0.4, 0.0, 1.0)
	var highlight_w = clampf((luma - 0.6) / 0.4, 0.0, 1.0)
	var mid_w       = clampf(1.0 - shadow_w - highlight_w, 0.0, 1.0)

	var shadows: Color    = data.get("shadows", Color(0, 0, 0))
	var mids: Color       = data.get("mids", Color(0, 0, 0))
	var highlights: Color = data.get("highlights", Color(0, 0, 0))

	var shift_r = shadows.r * shadow_w + mids.r * mid_w + highlights.r * highlight_w
	var shift_g = shadows.g * shadow_w + mids.g * mid_w + highlights.g * highlight_w
	var shift_b = shadows.b * shadow_w + mids.b * mid_w + highlights.b * highlight_w

	# Apply shift
	var nr = clampf(r + shift_r, 0.0, 1.0)
	var ng = clampf(g + shift_g, 0.0, 1.0)
	var nb = clampf(b + shift_b, 0.0, 1.0)

	# Contrast (pivot around 0.5)
	var contrast: float = data.get("contrast", 1.0)
	nr = clampf((nr - 0.5) * contrast + 0.5, 0.0, 1.0)
	ng = clampf((ng - 0.5) * contrast + 0.5, 0.0, 1.0)
	nb = clampf((nb - 0.5) * contrast + 0.5, 0.0, 1.0)

	# Saturation
	var sat: float = data.get("saturation", 1.0)
	var new_luma = nr * 0.2126 + ng * 0.7152 + nb * 0.0722
	nr = clampf(lerpf(new_luma, nr, sat), 0.0, 1.0)
	ng = clampf(lerpf(new_luma, ng, sat), 0.0, 1.0)
	nb = clampf(lerpf(new_luma, nb, sat), 0.0, 1.0)

	return Color(nr, ng, nb, 1.0)

static func get_fog_preset(preset_name: String) -> Dictionary:
	"""Return fog parameters for a given preset name."""
	return FOG_PRESETS.get(preset_name, FOG_PRESETS["none"])
