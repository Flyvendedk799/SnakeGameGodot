shader_type canvas_item;

// 3D LUT Color Grading shader
// Supports per-theme color look-up tables for professional color control
// Can also do procedural color grading when no LUT texture is provided

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D lut_texture : filter_linear;
uniform float lut_strength : hint_range(0.0, 1.0) = 0.8;
uniform bool use_lut = false;

// Procedural grading (when no LUT)
uniform float lift_r : hint_range(-0.5, 0.5) = 0.0;
uniform float lift_g : hint_range(-0.5, 0.5) = 0.0;
uniform float lift_b : hint_range(-0.5, 0.5) = 0.02;
uniform float gamma_r : hint_range(0.5, 2.0) = 1.0;
uniform float gamma_g : hint_range(0.5, 2.0) = 0.98;
uniform float gamma_b : hint_range(0.5, 2.0) = 1.02;
uniform float gain_r : hint_range(0.5, 2.0) = 1.02;
uniform float gain_g : hint_range(0.5, 2.0) = 1.0;
uniform float gain_b : hint_range(0.5, 2.0) = 0.98;

// Vignette (combined here for efficiency)
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_radius : hint_range(0.2, 1.0) = 0.75;

// Chromatic aberration
uniform float chromatic_strength : hint_range(0.0, 0.02) = 0.0;

// Film grain
uniform float grain_strength : hint_range(0.0, 0.15) = 0.03;

// Hash function for grain
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(443.8975, 397.2973, 491.1871));
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Chromatic aberration (radial from center)
	vec3 color;
	if (chromatic_strength > 0.0001) {
		vec2 dir = uv - vec2(0.5);
		float dist = length(dir);
		vec2 offset = dir * chromatic_strength * dist;
		color.r = texture(screen_texture, uv + offset).r;
		color.g = texture(screen_texture, uv).g;
		color.b = texture(screen_texture, uv - offset).b;
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// LUT color grading
	if (use_lut) {
		// Standard 16x16x16 LUT strip (256x16 texture)
		float blue = color.b * 15.0;
		float blue_floor = floor(blue);
		float blue_frac = blue - blue_floor;

		vec2 quad_size = vec2(1.0 / 16.0, 1.0);
		vec2 uv1 = vec2(blue_floor / 16.0 + color.r / 16.0 * (15.0 / 16.0), color.g * (15.0 / 16.0));
		vec2 uv2 = vec2((blue_floor + 1.0) / 16.0 + color.r / 16.0 * (15.0 / 16.0), color.g * (15.0 / 16.0));

		vec3 lut_color = mix(texture(lut_texture, uv1).rgb, texture(lut_texture, uv2).rgb, blue_frac);
		color = mix(color, lut_color, lut_strength);
	} else {
		// Procedural lift/gamma/gain color grading
		vec3 lift = vec3(lift_r, lift_g, lift_b);
		vec3 gamma_val = vec3(gamma_r, gamma_g, gamma_b);
		vec3 gain = vec3(gain_r, gain_g, gain_b);

		// Apply lift (shadows)
		color = color + lift * (1.0 - color);
		// Apply gain (highlights)
		color = color * gain;
		// Apply gamma (midtones)
		color = pow(max(color, vec3(0.0001)), 1.0 / gamma_val);

		color = mix(texture(screen_texture, uv).rgb, color, lut_strength);
	}

	// Vignette
	if (vignette_strength > 0.001) {
		vec2 vig_uv = uv * 2.0 - 1.0;
		float vig_dist = length(vig_uv);
		float vig = smoothstep(vignette_radius, vignette_radius + 0.4, vig_dist);
		color *= 1.0 - vig * vignette_strength;
	}

	// Film grain
	if (grain_strength > 0.001) {
		float grain = hash(uv * 1000.0 + fract(TIME * 43.168)) * 2.0 - 1.0;
		color += vec3(grain) * grain_strength;
	}

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
