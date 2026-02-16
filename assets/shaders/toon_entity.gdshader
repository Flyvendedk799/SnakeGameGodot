shader_type canvas_item;

// Toon shading for entity sprites in Main Game
// Quantizes lighting into 3-4 steps with warm highlights / cool shadows
// Also handles hit flash and dissolve effects

uniform vec4 light_direction : source_color = vec4(0.5, -0.7, 0.5, 1.0);
uniform float light_intensity : hint_range(0.0, 2.0) = 0.6;
uniform vec4 ambient_color : source_color = vec4(0.85, 0.85, 0.9, 1.0);
uniform int toon_steps : hint_range(2, 6) = 3;
uniform float toon_strength : hint_range(0.0, 1.0) = 0.5;

// Hit flash
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Rim lighting
uniform float rim_strength : hint_range(0.0, 1.0) = 0.3;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (tex_color.a < 0.01) {
		discard;
	}

	vec3 color = tex_color.rgb;

	// Simulated normal from UV position (top = lit, bottom = shadow)
	float fake_normal_y = 1.0 - UV.y;  // Top of sprite faces up
	float fake_normal_x = (UV.x - 0.5) * 2.0;  // Left/right facing
	vec3 normal = normalize(vec3(fake_normal_x * 0.3, fake_normal_y, 0.5));

	// Diffuse lighting
	vec3 light_dir = normalize(light_direction.xyz);
	float ndl = dot(normal, -light_dir);
	float diffuse = clamp(ndl, 0.0, 1.0);

	// Toon quantization
	float steps_f = float(toon_steps);
	float quantized = floor(diffuse * steps_f + 0.5) / steps_f;
	float final_light = mix(diffuse, quantized, toon_strength);

	// Apply lighting
	vec3 lit_color = color * (ambient_color.rgb + vec3(final_light) * light_intensity);

	// Warm highlights / cool shadows
	float luma = dot(lit_color, vec3(0.2126, 0.7152, 0.0722));
	if (luma > 0.5) {
		lit_color = mix(lit_color, lit_color * vec3(1.05, 1.0, 0.92), 0.2);  // Warm highlights
	} else {
		lit_color = mix(lit_color, lit_color * vec3(0.9, 0.92, 1.05), 0.15);  // Cool shadows
	}

	// Rim lighting (edge glow from above)
	float rim = 1.0 - abs(UV.x - 0.5) * 2.0;
	rim *= UV.y < 0.3 ? (1.0 - UV.y / 0.3) : 0.0;  // Only top portion
	lit_color += rim_color.rgb * rim * rim_strength;

	// Hit flash
	lit_color = mix(lit_color, flash_color.rgb, flash_amount);

	COLOR = vec4(clamp(lit_color, vec3(0.0), vec3(1.0)), tex_color.a);
}
