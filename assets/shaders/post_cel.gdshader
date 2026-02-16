shader_type canvas_item;

// AAA Cel-shading / posterization shader
// 5-6 color steps with warm highlights and cool shadows
// Reference: Cuphead, Guilty Gear Strive

uniform int color_steps : hint_range(3, 8) = 5;
uniform float posterize_strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 warm_tint : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform vec4 cool_tint : source_color = vec4(0.75, 0.8, 0.95, 1.0);
uniform float edge_threshold : hint_range(0.0, 0.5) = 0.08;
uniform float edge_strength : hint_range(0.0, 2.0) = 0.6;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
	vec2 pixel_size = SCREEN_PIXEL_SIZE;
	vec4 base = texture(screen_texture, SCREEN_UV);
	vec3 color = base.rgb;

	// --- Posterization (color quantization) ---
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float steps_f = float(color_steps);

	// Quantize each channel
	vec3 posterized = floor(color * steps_f + 0.5) / steps_f;

	// Warm/cool tinting based on luminance
	// Highlights get warm tint (amber/yellow), shadows get cool tint (blue/purple)
	float warm_factor = smoothstep(0.4, 0.8, luma);
	float cool_factor = smoothstep(0.5, 0.15, luma);
	vec3 tinted = posterized;
	tinted = mix(tinted, tinted * warm_tint.rgb, warm_factor * 0.3);
	tinted = mix(tinted, tinted * cool_tint.rgb, cool_factor * 0.25);

	// Blend posterized with original based on strength
	color = mix(color, tinted, posterize_strength);

	// --- Edge detection (Sobel-like for cartoon outlines) ---
	float edge = 0.0;
	if (edge_strength > 0.01) {
		// Sample luminances in a cross pattern
		float l_c = luma;
		float l_u = dot(texture(screen_texture, SCREEN_UV + vec2(0.0, -pixel_size.y * 1.5)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float l_d = dot(texture(screen_texture, SCREEN_UV + vec2(0.0, pixel_size.y * 1.5)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float l_l = dot(texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x * 1.5, 0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float l_r = dot(texture(screen_texture, SCREEN_UV + vec2(pixel_size.x * 1.5, 0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));

		// Diagonal samples for better edge detection
		float l_ul = dot(texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x, -pixel_size.y)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float l_ur = dot(texture(screen_texture, SCREEN_UV + vec2(pixel_size.x, -pixel_size.y)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float l_dl = dot(texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x, pixel_size.y)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float l_dr = dot(texture(screen_texture, SCREEN_UV + vec2(pixel_size.x, pixel_size.y)).rgb, vec3(0.2126, 0.7152, 0.0722));

		// Sobel gradient
		float gx = -l_ul - 2.0 * l_l - l_dl + l_ur + 2.0 * l_r + l_dr;
		float gy = -l_ul - 2.0 * l_u - l_ur + l_dl + 2.0 * l_d + l_dr;
		edge = sqrt(gx * gx + gy * gy);
		edge = smoothstep(edge_threshold, edge_threshold + 0.15, edge);

		// Darken edges for cartoon outline effect
		color = mix(color, color * 0.15, edge * edge_strength);
	}

	COLOR = vec4(color, base.a);
}
