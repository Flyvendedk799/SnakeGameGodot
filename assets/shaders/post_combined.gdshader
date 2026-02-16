shader_type canvas_item;

// AAA Visual Overhaul: Combined post-process shader
// Combines bloom, tonemap, cel-shading, vignette, chromatic aberration, grain
// Single-pass for performance and simplicity

// Bloom
uniform float bloom_threshold : hint_range(0.0, 2.0) = 0.7;
uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float bloom_radius : hint_range(1.0, 8.0) = 3.0;

// Tonemap
uniform float exposure : hint_range(0.1, 4.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.08;

// Cel-shading
uniform int color_steps : hint_range(3, 8) = 5;
uniform float posterize_strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 warm_tint : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform vec4 cool_tint : source_color = vec4(0.75, 0.8, 0.95, 1.0);

// Vignette
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;

// Chromatic aberration
uniform float chromatic_strength : hint_range(0.0, 0.02) = 0.0;

// Film grain
uniform float grain_strength : hint_range(0.0, 0.1) = 0.025;

// Impact distortion
uniform float impact_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 impact_center = vec2(0.5, 0.5);

// Perspective warp
uniform float perspective_amount : hint_range(0.0, 0.15) = 0.025;
uniform bool perspective_enabled = true;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Simple hash for noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// --- Perspective trapezoid warp ---
	if (perspective_enabled && perspective_amount > 0.001) {
		float y_factor = 1.0 - uv.y;
		float pinch = perspective_amount * y_factor;
		uv.x = mix(pinch, 1.0 - pinch, uv.x);
	}

	// --- Impact distortion ---
	if (impact_strength > 0.01) {
		vec2 to_center = uv - impact_center;
		float dist = length(to_center);
		float ripple = sin(dist * 30.0 - TIME * 5.0) * 0.5 + 0.5;
		float warp = impact_strength * ripple * (1.0 - dist) * 0.03;
		uv += normalize(to_center) * warp;
	}

	// --- Chromatic aberration ---
	vec3 color;
	if (chromatic_strength > 0.0001) {
		vec2 dir = uv - vec2(0.5);
		float r = texture(screen_texture, uv - dir * chromatic_strength).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv + dir * chromatic_strength).b;
		color = vec3(r, g, b);
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// --- Bloom (simplified) ---
	if (bloom_intensity > 0.01) {
		vec3 bloom = vec3(0.0);
		float total_weight = 0.0;
		int samples = int(bloom_radius);
		for (int x = -samples; x <= samples; x++) {
			for (int y = -samples; y <= samples; y++) {
				vec2 offset = vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE * bloom_radius;
				vec3 sample_col = texture(screen_texture, uv + offset).rgb;
				float brightness = dot(sample_col, vec3(0.2126, 0.7152, 0.0722));
				if (brightness > bloom_threshold) {
					float weight = 1.0 - length(vec2(float(x), float(y))) / float(samples + 1);
					bloom += sample_col * weight;
					total_weight += weight;
				}
			}
		}
		if (total_weight > 0.0) {
			bloom /= total_weight;
			color += bloom * bloom_intensity * 0.3;
		}
	}

	// --- Tonemapping (ACES approximation) ---
	color *= exposure;
	vec3 a = 2.51;
	vec3 b = vec3(0.03);
	vec3 c = 2.43;
	vec3 d = vec3(0.59);
	vec3 e = vec3(0.14);
	color = clamp((color * (a * color + b)) / (color * (c * color + d) + e), vec3(0.0), vec3(1.0));

	// --- Contrast and saturation ---
	color = mix(vec3(0.5), color, contrast);
	float gray = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(gray), color, saturation);

	// --- Cel-shading posterization ---
	if (posterize_strength > 0.01) {
		float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
		float steps_f = float(color_steps);
		vec3 posterized = floor(color * steps_f + 0.5) / steps_f;

		// Warm/cool tinting
		float warm_factor = smoothstep(0.4, 0.8, luma);
		float cool_factor = smoothstep(0.5, 0.15, luma);
		posterized = mix(posterized, posterized * warm_tint.rgb, warm_factor * 0.15);
		posterized = mix(posterized, posterized * cool_tint.rgb, cool_factor * 0.15);

		color = mix(color, posterized, posterize_strength);
	}

	// --- Vignette ---
	if (vignette_strength > 0.01) {
		vec2 center_dist = uv - vec2(0.5);
		float vignette = 1.0 - dot(center_dist, center_dist) * vignette_strength * 2.0;
		vignette = smoothstep(0.0, 1.0, vignette);
		color *= vignette;
	}

	// --- Film grain ---
	if (grain_strength > 0.001) {
		float noise = hash(uv + TIME * 0.1) * 2.0 - 1.0;
		color += vec3(noise) * grain_strength;
	}

	COLOR = vec4(color, 1.0);
}
