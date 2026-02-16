shader_type canvas_item;

// Screen distortion on heavy hit - radial warp from impact point
// Driven by impact_strength uniform (0 = no effect, 1 = maximum warp)

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float impact_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 impact_center = vec2(0.5, 0.5);  // Normalized screen position
uniform float distort_radius : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec2 uv = SCREEN_UV;

	if (impact_strength > 0.001) {
		vec2 dir = uv - impact_center;
		float dist = length(dir);
		float falloff = 1.0 - smoothstep(0.0, distort_radius, dist);

		// Radial warp: push pixels outward from impact center
		float warp = falloff * impact_strength * 0.04;

		// Wave ripple for extra punch
		float ripple = sin(dist * 40.0 - impact_strength * 10.0) * 0.5 + 0.5;
		warp *= (0.7 + ripple * 0.3);

		uv += normalize(dir + vec2(0.0001)) * warp;
		uv = clamp(uv, vec2(0.0), vec2(1.0));
	}

	COLOR = texture(screen_texture, uv);
}
