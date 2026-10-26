shader_type canvas_item;
uniform float shimmer : hint_range(0.0, 0.2) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 ink = texture(TEXTURE, UV) * COLOR;
	// Original artwork and hue; only an occasional, very small luminance lift.
	ink.rgb = min(ink.rgb * (1.0 + shimmer), vec3(1.0));
	if (dissolve > 0.0) {
		vec2 cell = floor(UV * 60.0);
		float threshold = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		ink.a *= 1.0 - smoothstep(threshold - 0.04, threshold + 0.04, dissolve);
	}
	COLOR = ink;
}
