shader_type canvas_item;

// ============================================================
// Atmospheric Fog Shader (Phase 2.2)
// Fullscreen additive/overlay depth fog — increases with screen Y
// Simulates atmospheric depth: cave = dense bottom fog,
// sky = light upper haze, lava = heat shimmer haze
// ============================================================

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Fog parameters (set per theme from GDScript)
uniform vec4  fog_color      : source_color = vec4(0.05, 0.08, 0.12, 1.0);
uniform float fog_density    : hint_range(0.0, 1.0) = 0.18;
uniform float fog_start_y    : hint_range(0.0, 1.0) = 0.3;   // Screen-space 0-1
uniform float fog_end_y      : hint_range(0.0, 1.0) = 0.95;  // Screen-space 0-1
uniform float fog_top_haze   : hint_range(0.0, 1.0) = 0.0;   // Horizontal top haze (sky theme)
uniform float time_driven    : hint_range(0.0, 1.0) = 0.0;   // Slight drift animation

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 scene = texture(screen_texture, uv).rgb;

	// Vertical depth fog — grows exponentially toward bottom
	float y_t = clamp((uv.y - fog_start_y) / max(fog_end_y - fog_start_y, 0.001), 0.0, 1.0);
	float depth_fog = y_t * y_t * fog_density;

	// Optional top haze (sky / open-air scenes — thin upper atmosphere)
	float top_haze = 0.0;
	if (fog_top_haze > 0.001) {
		float top_t = clamp(1.0 - uv.y / max(fog_start_y, 0.001), 0.0, 1.0);
		top_haze = top_t * top_t * fog_top_haze * 0.4;
	}

	float total_fog = clamp(depth_fog + top_haze, 0.0, 0.88);

	// Subtle horizontal density variation (drifting wisps)
	if (time_driven > 0.001) {
		float wisp = sin(uv.x * 4.2 + TIME * 0.18) * 0.5 + 0.5;
		float wisp2 = sin(uv.x * 7.1 - TIME * 0.12 + 1.57) * 0.5 + 0.5;
		total_fog *= 1.0 + (wisp * wisp2 - 0.5) * 0.12 * time_driven;
		total_fog = clamp(total_fog, 0.0, 0.88);
	}

	// Blend: overlay fog color over scene
	vec3 fogged = mix(scene, fog_color.rgb, total_fog * fog_color.a);
	COLOR = vec4(fogged, 1.0);
}
