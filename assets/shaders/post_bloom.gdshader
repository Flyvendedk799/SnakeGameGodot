shader_type canvas_item;

// AAA Bloom shader: HDR threshold extract + gaussian blur + additive composite
// Reference: Ori, Hollow Knight glow

uniform float bloom_threshold : hint_range(0.4, 1.0) = 0.7;
uniform float bloom_intensity : hint_range(0.0, 3.0) = 0.8;
uniform float bloom_radius : hint_range(0.0, 8.0) = 3.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	vec2 pixel_size = SCREEN_PIXEL_SIZE;
	vec4 base_color = texture(screen_texture, SCREEN_UV);

	// Extract bright pixels above threshold
	float brightness = dot(base_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	float soft_threshold = smoothstep(bloom_threshold - 0.1, bloom_threshold + 0.1, brightness);

	// 9-tap gaussian blur for bloom (horizontal + vertical combined)
	vec4 bloom = vec4(0.0);
	float weights[5] = {0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216};

	for (int i = 0; i < 5; i++) {
		float offset = float(i) * bloom_radius;
		vec2 offset_h = vec2(offset * pixel_size.x, 0.0);
		vec2 offset_v = vec2(0.0, offset * pixel_size.y);

		vec4 h1 = texture(screen_texture, SCREEN_UV + offset_h);
		vec4 h2 = texture(screen_texture, SCREEN_UV - offset_h);
		vec4 v1 = texture(screen_texture, SCREEN_UV + offset_v);
		vec4 v2 = texture(screen_texture, SCREEN_UV - offset_v);

		float w = weights[i];
		// Only bloom bright pixels
		float b1 = smoothstep(bloom_threshold - 0.1, bloom_threshold + 0.1, dot(h1.rgb, vec3(0.2126, 0.7152, 0.0722)));
		float b2 = smoothstep(bloom_threshold - 0.1, bloom_threshold + 0.1, dot(h2.rgb, vec3(0.2126, 0.7152, 0.0722)));
		float b3 = smoothstep(bloom_threshold - 0.1, bloom_threshold + 0.1, dot(v1.rgb, vec3(0.2126, 0.7152, 0.0722)));
		float b4 = smoothstep(bloom_threshold - 0.1, bloom_threshold + 0.1, dot(v2.rgb, vec3(0.2126, 0.7152, 0.0722)));

		bloom += (h1 * b1 + h2 * b2 + v1 * b3 + v2 * b4) * w * 0.25;
	}

	// Additive composite
	vec3 result = base_color.rgb + bloom.rgb * bloom_intensity;
	COLOR = vec4(result, base_color.a);
}
