shader_type canvas_item;

// Simple test shader - just passthrough with slight tint
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);

	// Add slight warm tint to verify shader is working
	color.rgb *= vec3(1.05, 1.0, 0.95);

	COLOR = color;
}
