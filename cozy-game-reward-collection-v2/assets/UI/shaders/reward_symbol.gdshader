shader_type canvas_item;
render_mode unshaded;
uniform float shimmer : hint_range(0.0, 0.2) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	// Godot's fragment COLOR already includes the texture. Multiplying it by
	// texture() again squares/darkens the artwork; use the vertex tint instead.
	vec4 ink = texture(TEXTURE, UV) * vertex_tint;
	// Original artwork and hue; only an occasional, very small luminance lift.
	ink.rgb = min(ink.rgb * (1.0 + shimmer), vec3(1.0));
	if (dissolve > 0.0) {
		vec2 cell = floor(UV * 60.0);
		float threshold = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		ink.a *= 1.0 - smoothstep(threshold - 0.04, threshold + 0.04, dissolve);
	}
	COLOR = ink;
}
