shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.005;
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_density : hint_range(1.0, 50.0) = 10.0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
	// Create layered sine wave distortion for a realistic heat shimmer
	float time = TIME * speed;

	// Primary wave (horizontal shimmer)
	float wave1 = sin(UV.y * wave_density + time * 2.3) * distortion_strength;
	// Secondary wave (vertical shimmer, offset frequency)
	float wave2 = cos(UV.x * wave_density * 0.7 + time * 1.7) * distortion_strength * 0.5;
	// Tertiary fine detail wave
	float wave3 = sin((UV.x + UV.y) * wave_density * 1.5 + time * 3.1) * distortion_strength * 0.25;

	vec2 distorted_uv = SCREEN_UV;
	distorted_uv.x += wave1 + wave3;
	distorted_uv.y += wave2 + wave3 * 0.5;

	// Clamp to prevent sampling outside screen
	distorted_uv = clamp(distorted_uv, vec2(0.0), vec2(1.0));

	vec4 screen_color = texture(screen_texture, distorted_uv);
	COLOR = screen_color;
}
