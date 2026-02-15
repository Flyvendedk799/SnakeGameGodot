shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform bool enabled = true;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (!enabled) {
		COLOR = tex;
		return;
	}

	vec2 texel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	float max_alpha = 0.0;

	// Sample adjacent texels in a circle pattern to detect edges
	int steps = 8;
	for (int i = 0; i < steps; i++) {
		float angle = float(i) * (6.28318530718 / float(steps));
		vec2 offset = vec2(cos(angle), sin(angle)) * texel_size * outline_width;
		float sample_alpha = texture(TEXTURE, UV + offset).a;
		max_alpha = max(max_alpha, sample_alpha);
	}
	// Also sample the 4 cardinal + 4 diagonal directions for robustness
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(texel_size.x * outline_width, 0.0)).a);
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(-texel_size.x * outline_width, 0.0)).a);
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, texel_size.y * outline_width)).a);
	max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(0.0, -texel_size.y * outline_width)).a);

	// If the current pixel is transparent but neighbors are not, draw outline
	if (tex.a < 0.1 && max_alpha > 0.1) {
		COLOR = outline_color;
	} else {
		COLOR = tex;
	}
}
