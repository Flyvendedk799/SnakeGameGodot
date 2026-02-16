shader_type canvas_item;

// Working post-process shader for Godot 4
// Cel-shading, bloom, vignette, grain - single pass

uniform int cel_steps : hint_range(3, 8) = 5;
uniform float cel_strength : hint_range(0.0, 1.0) = 0.5;
uniform float bloom_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;
uniform float saturation : hint_range(0.5, 2.0) = 1.1;
uniform float contrast : hint_range(0.5, 2.0) = 1.05;
uniform float grain_amount : hint_range(0.0, 0.1) = 0.02;
uniform float chromatic_amount : hint_range(0.0, 0.03) = 0.0;
uniform float distort_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 distort_center = vec2(0.5, 0.5);

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Impact distortion
	if (distort_strength > 0.01) {
		vec2 dir = uv - distort_center;
		float dist = length(dir);
		uv += normalize(dir) * distort_strength * (1.0 - dist) * 0.02;
	}

	// Chromatic aberration
	vec3 color;
	if (chromatic_amount > 0.0001) {
		vec2 dir = uv - vec2(0.5);
		float r = texture(screen_texture, uv + dir * chromatic_amount).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - dir * chromatic_amount).b;
		color = vec3(r, g, b);
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// Bloom (simple box blur on bright areas)
	if (bloom_intensity > 0.01) {
		vec3 bloom = vec3(0.0);
		float bloom_samples = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				vec2 offset = vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE * 2.0;
				vec3 sample_col = texture(screen_texture, uv + offset).rgb;
				float brightness = dot(sample_col, vec3(0.299, 0.587, 0.114));
				if (brightness > 0.7) {
					bloom += sample_col;
					bloom_samples += 1.0;
				}
			}
		}
		if (bloom_samples > 0.0) {
			color += (bloom / bloom_samples) * bloom_intensity;
		}
	}

	// Contrast
	color = mix(vec3(0.5), color, contrast);

	// Saturation
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, saturation);

	// Cel-shading posterization
	if (cel_strength > 0.01) {
		float luma = dot(color, vec3(0.299, 0.587, 0.114));
		vec3 quantized = floor(color * float(cel_steps)) / float(cel_steps);

		// Warm tint on highlights
		if (luma > 0.6) {
			quantized *= vec3(1.05, 1.0, 0.95);
		}
		// Cool tint on shadows
		else if (luma < 0.4) {
			quantized *= vec3(0.95, 0.97, 1.05);
		}

		color = mix(color, quantized, cel_strength);
	}

	// Vignette
	if (vignette_strength > 0.01) {
		vec2 center_dist = uv - vec2(0.5);
		float vignette = 1.0 - dot(center_dist, center_dist) * vignette_strength * 2.5;
		color *= smoothstep(0.0, 1.0, vignette);
	}

	// Film grain
	if (grain_amount > 0.001) {
		float noise = rand(uv + TIME * 0.1) * 2.0 - 1.0;
		color += vec3(noise) * grain_amount;
	}

	COLOR = vec4(color, 1.0);
}
