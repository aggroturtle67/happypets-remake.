shader_type canvas_item;
render_mode unshaded;

// A restrained paper grain: the opaque rose colour still comes from ColorRect.
void fragment() {
	vec4 base = COLOR;
	float grain = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	float light = (0.5 - UV.y) * 0.012;
	COLOR = vec4(clamp(base.rgb + vec3(grain * 0.025 + light), vec3(0.0), vec3(1.0)), base.a);
}
