shader_type canvas_item;

// AAA Tonemapping: ACES filmic tone mapping for cinematic range
// Prevents blown highlights, compresses HDR to display range

uniform float exposure : hint_range(0.5, 3.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.08;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// ACES filmic tone mapping curve
vec3 aces_tonemap(vec3 x) {
	float a = 2.51;
	float b = 0.03;
	float c = 2.43;
	float d = 0.59;
	float e = 0.14;
	return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void fragment() {
	vec4 base = texture(screen_texture, SCREEN_UV);
	vec3 color = base.rgb;

	// Exposure
	color *= exposure;

	// Contrast adjustment (pivot at mid-gray)
	color = mix(vec3(0.18), color, contrast);

	// ACES tone mapping
	color = aces_tonemap(color);

	// Saturation
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(luma), color, saturation);

	COLOR = vec4(color, base.a);
}
