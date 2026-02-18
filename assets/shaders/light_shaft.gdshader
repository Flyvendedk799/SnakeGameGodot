shader_type canvas_item;

// ============================================================
// Light Shaft / God Rays Shader (Phase 2.3)
// Radial blur from light_origin sampling scene luminance
// Accumulates brightness along rays from the sun/light source
// ============================================================

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform vec2  ray_origin      = vec2(0.5, 0.0);     // Light source in UV space
uniform float ray_intensity   : hint_range(0.0, 1.0) = 0.12;
uniform vec4  ray_color       : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform int   num_samples     : hint_range(8, 64) = 32;
uniform float decay           : hint_range(0.8, 1.0) = 0.94;
uniform float density         : hint_range(0.0, 1.0) = 0.8;
uniform float weight          : hint_range(0.0, 1.0) = 0.38;

void fragment() {
	if (ray_intensity < 0.001) {
		COLOR = vec4(0.0);
		return;
	}

	vec2 uv = SCREEN_UV;
	vec2 delta_uv = (uv - ray_origin) * (1.0 / float(num_samples)) * density;
	vec2 sample_uv = uv;

	float illumination_decay = 1.0;
	vec3 accum = vec3(0.0);

	for (int i = 0; i < num_samples; i++) {
		sample_uv -= delta_uv;
		sample_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));
		vec3 sample_col = texture(screen_texture, sample_uv).rgb;
		float luma = dot(sample_col, vec3(0.2126, 0.7152, 0.0722));
		accum += sample_col * luma * illumination_decay * weight;
		illumination_decay *= decay;
	}

	// Scale and tint
	accum /= float(num_samples);
	vec3 shaft = accum * ray_color.rgb * ray_intensity;

	// Fade toward edges (radial distance from origin)
	float dist = length(uv - ray_origin);
	float edge_fade = 1.0 - smoothstep(0.2, 0.8, dist);
	shaft *= edge_fade;

	// Additive blend — does not darken the scene
	COLOR = vec4(shaft, ray_intensity * 0.6 * edge_fade);
}
