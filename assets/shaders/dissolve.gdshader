shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 dissolve_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float noise_scale : hint_range(1.0, 50.0) = 10.0;

// Simple procedural noise (hash-based value noise)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Smooth interpolation
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * value_noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Generate noise pattern at the UV coordinate
	float noise = fbm(UV * noise_scale);

	// Dissolve threshold based on dissolve_amount
	float threshold = dissolve_amount;

	// Edge glow width (in noise-space)
	float edge_width = 0.06;

	if (noise < threshold - edge_width) {
		// Fully dissolved region
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else if (noise < threshold) {
		// Edge glow region - bright dissolve color fading to transparent
		float edge_t = (threshold - noise) / edge_width;
		vec4 glow = dissolve_color;
		// Intensify edge glow
		glow.rgb *= 1.5 + edge_t * 2.0;
		glow.a = tex.a * (1.0 - edge_t * 0.5);
		COLOR = glow;
	} else {
		// Original texture
		COLOR = tex;
	}

	// When fully dissolved, ensure complete transparency
	if (dissolve_amount >= 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
