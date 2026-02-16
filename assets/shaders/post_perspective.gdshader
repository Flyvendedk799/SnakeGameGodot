shader_type canvas_item;

// AAA Visual Overhaul: Perspective quad display
// Trapezoid warp - top edge narrower than bottom
// Simulates looking at a stage (Hollow Knight / Shantae feel)

uniform float perspective_amount : hint_range(0.0, 0.15) = 0.03;  // How much top narrows
uniform float vertical_shift : hint_range(-0.1, 0.1) = 0.005;  // Slight upward shift
uniform bool enabled = true;

void fragment() {
	if (!enabled) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 uv = UV;

		// Trapezoid: top edge pinches inward, bottom stays full width
		// As Y goes from 0 (top) to 1 (bottom), horizontal range shrinks at top
		float y_factor = 1.0 - uv.y;  // 1 at top, 0 at bottom
		float pinch = perspective_amount * y_factor;

		// Remap X to account for pinch
		uv.x = mix(pinch, 1.0 - pinch, uv.x);

		// Slight vertical shift for stage-viewing angle
		uv.y -= vertical_shift * y_factor;

		// Clamp to avoid sampling outside texture
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		} else {
			COLOR = texture(TEXTURE, uv);
		}
	}
}
