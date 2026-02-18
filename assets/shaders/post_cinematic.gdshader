shader_type canvas_item;

// ============================================================
// AAA Cinematic Post-Process Shader
// Bloom · Tonemap · Cel · Lens Distortion · Edge Detection
// Chromatic Aberration · Vignette · Film Grain · Speed Lines
// ============================================================

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// ---- BLOOM ----
uniform float bloom_threshold    : hint_range(0.0, 2.0) = 0.42;
uniform float bloom_intensity    : hint_range(0.0, 4.0) = 1.5;
uniform float bloom_radius       : hint_range(1.0, 10.0) = 4.5;
uniform float bloom_scatter      : hint_range(0.0, 1.0) = 0.7;

// ---- TONEMAPPING ----
uniform float exposure           : hint_range(0.1, 4.0) = 1.1;
uniform float contrast           : hint_range(0.5, 2.5) = 1.22;
uniform float saturation         : hint_range(0.0, 2.5) = 1.25;
uniform float brightness         : hint_range(0.5, 2.0) = 1.04;

// ---- COLOR GRADE (lift/gamma/gain per channel) ----
uniform vec3 color_lift          = vec3(0.01, 0.005, 0.0);
uniform vec3 color_gamma         = vec3(1.0, 1.02, 0.98);
uniform vec3 color_gain          = vec3(1.05, 1.0, 0.95);

// ---- CEL / POSTERIZE ----
uniform int   color_steps        : hint_range(2, 12) = 6;
uniform float posterize_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4  warm_tint          : source_color = vec4(1.0, 0.94, 0.82, 1.0);
uniform vec4  cool_tint          : source_color = vec4(0.72, 0.80, 1.0, 1.0);
uniform float cel_blend          : hint_range(0.0, 1.0) = 0.45;

// ---- EDGE DETECTION (Sobel overlay for hand-drawn look) ----
uniform float edge_strength      : hint_range(0.0, 1.0) = 0.55;
uniform vec4  edge_color         : source_color = vec4(0.0, 0.0, 0.05, 1.0);
uniform float edge_threshold     : hint_range(0.0, 1.0) = 0.12;

// ---- LENS DISTORTION ----
uniform float lens_distortion    : hint_range(-0.5, 0.5) = 0.045;
uniform float lens_zoom          : hint_range(0.5, 2.0) = 1.02;

// ---- PERSPECTIVE WARP ----
uniform float perspective_amount : hint_range(0.0, 0.15) = 0.022;
uniform bool  perspective_enabled = true;

// ---- CHROMATIC ABERRATION ----
uniform float chromatic_base     : hint_range(0.0, 0.015) = 0.0022;
uniform float chromatic_strength : hint_range(0.0, 0.03) = 0.0;

// ---- VIGNETTE ----
uniform float vignette_strength  : hint_range(0.0, 2.0) = 0.58;
uniform float vignette_softness  : hint_range(0.1, 4.0) = 1.6;
uniform vec4  vignette_color     : source_color = vec4(0.0, 0.0, 0.02, 1.0);

// ---- FILM GRAIN ----
uniform float grain_strength     : hint_range(0.0, 0.15) = 0.038;
uniform float grain_size         : hint_range(0.5, 4.0) = 1.5;

// ---- SPEED LINES ----
uniform float speed_line_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float speed_line_speed     : hint_range(0.0, 10.0) = 5.0;

// ---- IMPACT DISTORTION ----
uniform float impact_strength    : hint_range(0.0, 1.0) = 0.0;
uniform vec2  impact_center      = vec2(0.5, 0.5);
// Phase 4.3: Directional warp — push UVs along hit direction
uniform vec2  impact_direction   = vec2(0.0, 0.0);  // normalized hit dir (screen space)

// ---- HDR EXPOSURE CURVE (Phase 1.2) ----
// Shoulder highlight rolloff: applies above 'exposure_shoulder' to prevent burn-out
uniform float exposure_shoulder  : hint_range(0.0, 1.0) = 0.7;
uniform float exposure_curve     : hint_range(0.0, 2.0) = 0.0;  // 0=off, >0=rolls off highlights

// ---- SCANLINE OVERLAY ----
uniform float scanline_strength  : hint_range(0.0, 0.3) = 0.06;

// ---- LUT COLOR GRADE (Phase 1.1) ----
// Optional 256x16 strip LUT for per-theme color grading
uniform sampler2D lut_texture : filter_linear;
uniform bool  lut_enabled    = false;
uniform float lut_strength   : hint_range(0.0, 1.0) = 0.72;


// ---- UTILITY FUNCTIONS ----

float hash(vec2 p) {
	return fract(sin(dot(p * grain_size, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 aces_tonemap(vec3 x) {
	const float a = 2.51;
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	return clamp((x * (a * x + b)) / (x * (c * x + d) + e), vec3(0.0), vec3(1.0));
}

vec2 lens_distort(vec2 uv, float k, float z) {
	vec2 t = uv - 0.5;
	float r2 = dot(t, t);
	t *= (1.0 + k * r2) * z;
	return t + 0.5;
}

// Dual-threshold box bloom — samples in a cross pattern at multiple scales
vec3 dual_bloom(sampler2D tex, vec2 uv, float radius, float threshold, float scatter) {
	vec3 bloom = vec3(0.0);
	float total = 0.0;

	// 3 scale levels for more natural scatter
	for (int scale = 1; scale <= 3; scale++) {
		float sc = float(scale);
		float step_size = SCREEN_PIXEL_SIZE.x * radius * sc;
		vec2 offsets[8];
		offsets[0] = vec2( step_size,  0.0);
		offsets[1] = vec2(-step_size,  0.0);
		offsets[2] = vec2( 0.0,  step_size);
		offsets[3] = vec2( 0.0, -step_size);
		offsets[4] = vec2( step_size,  step_size) * 0.707;
		offsets[5] = vec2(-step_size,  step_size) * 0.707;
		offsets[6] = vec2( step_size, -step_size) * 0.707;
		offsets[7] = vec2(-step_size, -step_size) * 0.707;

		float weight = 1.0 / sc;
		for (int i = 0; i < 8; i++) {
			vec3 s = texture(tex, uv + offsets[i]).rgb;
			float bright = dot(s, vec3(0.2126, 0.7152, 0.0722));
			if (bright > threshold) {
				float bw = (bright - threshold) / (1.0 - threshold + 0.001);
				bloom += s * weight * mix(1.0, bw, scatter);
				total += weight;
			}
		}
	}
	if (total > 0.0) bloom /= total;
	return bloom;
}

// Sobel edge detection — returns edge magnitude 0-1
float sobel_edge(sampler2D tex, vec2 uv) {
	vec2 px = SCREEN_PIXEL_SIZE * 1.2;
	float tl = dot(texture(tex, uv + vec2(-px.x,  px.y)).rgb, vec3(0.333));
	float tm = dot(texture(tex, uv + vec2( 0.0,   px.y)).rgb, vec3(0.333));
	float tr = dot(texture(tex, uv + vec2( px.x,  px.y)).rgb, vec3(0.333));
	float ml = dot(texture(tex, uv + vec2(-px.x,  0.0 )).rgb, vec3(0.333));
	float mr = dot(texture(tex, uv + vec2( px.x,  0.0 )).rgb, vec3(0.333));
	float bl = dot(texture(tex, uv + vec2(-px.x, -px.y)).rgb, vec3(0.333));
	float bm = dot(texture(tex, uv + vec2( 0.0,  -px.y)).rgb, vec3(0.333));
	float br = dot(texture(tex, uv + vec2( px.x, -px.y)).rgb, vec3(0.333));
	float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
	float gy = -tl - 2.0*tm - tr + bl + 2.0*bm + br;
	return length(vec2(gx, gy));
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// ---- Lens distortion ----
	if (abs(lens_distortion) > 0.001) {
		uv = lens_distort(uv, lens_distortion, lens_zoom);
		// Clamp to [0,1] — edges go black
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
			return;
		}
	}

	// ---- Perspective warp ----
	if (perspective_enabled && perspective_amount > 0.001) {
		float pinch = perspective_amount * (1.0 - uv.y);
		uv.x = mix(pinch, 1.0 - pinch, uv.x);
	}

	// ---- Impact distortion (Phase 4.3: directional warp) ----
	if (impact_strength > 0.01) {
		vec2 delta = uv - impact_center;
		float dist = length(delta);
		float ripple = sin(dist * 28.0 - TIME * 6.0) * 0.5 + 0.5;
		float radial_falloff = impact_strength * (1.0 - smoothstep(0.0, 0.6, dist)) * 0.04;
		// Radial ripple
		uv += normalize(delta + vec2(0.0001)) * ripple * radial_falloff;
		// Phase 4.3: directional push along impact_direction
		if (length(impact_direction) > 0.01) {
			float dir_falloff = 1.0 - smoothstep(0.0, 0.45, dist);
			uv += impact_direction * impact_strength * dir_falloff * 0.025;
		}
	}

	// ---- Chromatic aberration (base + dynamic) ----
	float ca = chromatic_base + chromatic_strength;
	vec3 color;
	if (ca > 0.0001) {
		vec2 dir = (uv - 0.5) * ca;
		color.r = texture(screen_texture, uv - dir * 1.2).r;
		color.g = texture(screen_texture, uv).g;
		color.b = texture(screen_texture, uv + dir * 1.2).b;
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// ---- Dual-threshold bloom ----
	if (bloom_intensity > 0.01) {
		vec3 bloom = dual_bloom(screen_texture, uv, bloom_radius, bloom_threshold, bloom_scatter);
		color += bloom * bloom_intensity * 0.4;
	}

	// ---- ACES tonemapping + Phase 1.2 HDR shoulder rolloff ----
	color *= exposure * brightness;
	// Phase 1.2: Soft shoulder for highlights — prevents burn-out at high exposures
	if (exposure_curve > 0.001) {
		float luma_pre = dot(color, vec3(0.2126, 0.7152, 0.0722));
		float shoulder = max(0.0, luma_pre - exposure_shoulder);
		float rolloff = shoulder / (shoulder + exposure_curve);
		color = mix(color, color * (1.0 - shoulder + rolloff), step(exposure_shoulder, luma_pre));
	}
	color = aces_tonemap(color);

	// ---- Lift / Gamma / Gain color grade ----
	color = color + color_lift;
	color = pow(max(color, vec3(0.0)), 1.0 / color_gamma);
	color *= color_gain;
	color = clamp(color, vec3(0.0), vec3(1.0));

	// ---- Contrast + Saturation ----
	color = mix(vec3(0.5), color, contrast);
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(luma), color, saturation);

	// ---- Cel-shading posterization with warm/cool tinting ----
	if (posterize_strength > 0.01) {
		float steps_f = float(color_steps);
		vec3 poster = floor(color * steps_f + 0.5) / steps_f;
		float warm_f = smoothstep(0.45, 0.85, luma);
		float cool_f = smoothstep(0.5, 0.1, luma);
		poster = mix(poster, poster * warm_tint.rgb, warm_f * 0.22);
		poster = mix(poster, poster * cool_tint.rgb, cool_f * 0.22);
		color = mix(color, poster, posterize_strength * cel_blend);
	}

	// ---- Sobel edge detection overlay ----
	if (edge_strength > 0.01) {
		float edge = sobel_edge(screen_texture, uv);
		edge = smoothstep(edge_threshold, edge_threshold + 0.25, edge);
		color = mix(color, edge_color.rgb, edge * edge_strength);
	}

	// ---- Scanline subtle overlay ----
	if (scanline_strength > 0.001) {
		float scan = sin(uv.y * VIEWPORT_SIZE.y * 3.14159) * 0.5 + 0.5;
		scan = pow(scan, 2.0);
		color *= 1.0 - scanline_strength * (1.0 - scan);
	}

	// ---- Speed lines (radial streaks from screen center) ----
	if (speed_line_intensity > 0.01) {
		vec2 center = vec2(0.5, 0.5);
		vec2 dir_sl = normalize(uv - center + vec2(0.0001));
		float angle = atan(dir_sl.y, dir_sl.x);
		float dist_sl = length(uv - center);
		float line_val = sin(angle * 12.0 + TIME * speed_line_speed) * 0.5 + 0.5;
		line_val = pow(line_val, 4.0);
		float radial_fade = smoothstep(0.1, 0.5, dist_sl);
		float edge_mask = 1.0 - smoothstep(0.4, 0.5, dist_sl);
		color = mix(color, color * (1.0 + line_val * 0.3), speed_line_intensity * radial_fade * edge_mask);
	}

	// ---- Cinematic vignette ----
	{
		vec2 vig_uv = (uv - 0.5) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float vig_dist = length(vig_uv);
		float vignette = 1.0 - smoothstep(0.45, 0.45 + vignette_softness * 0.4, vig_dist * vignette_strength);
		color = mix(vignette_color.rgb, color, vignette);
	}

	// ---- LUT color grade (Phase 1.1) ----
	if (lut_enabled) {
		// Standard 16x16x16 LUT encoded in a 256x16 strip
		float blue  = color.b * 15.0;
		float b0    = floor(blue);
		float b_frac = blue - b0;
		// Texel coordinates: slab b0 starts at x = b0/16.0 in [0,1]
		// Within each slab: r maps to sub-x, g maps to y
		float r_sub = color.r * (15.0 / 16.0);  // 15 steps in 1/16th width
		float g_sub = color.g * (15.0 / 16.0);
		vec2 uv1 = vec2(b0 / 16.0 + r_sub / 16.0, g_sub);
		vec2 uv2 = vec2((b0 + 1.0) / 16.0 + r_sub / 16.0, g_sub);
		vec3 lut_col = mix(texture(lut_texture, uv1).rgb, texture(lut_texture, uv2).rgb, b_frac);
		color = mix(color, lut_col, lut_strength);
	}

	// ---- Film grain ----
	if (grain_strength > 0.001) {
		float noise = hash(uv + fract(TIME * 0.317)) * 2.0 - 1.0;
		// Larger grain on dark areas (more cinematic)
		float dark_mask = 1.0 - luma;
		color += vec3(noise) * grain_strength * (1.0 + dark_mask * 0.5);
	}

	COLOR = vec4(color, 1.0);
}
