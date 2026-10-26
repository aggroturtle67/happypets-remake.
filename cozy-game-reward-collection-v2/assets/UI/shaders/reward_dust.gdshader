shader_type canvas_item;
render_mode unshaded;
// One shared material: per-particle data travels in the vertex color so the
// small dust sprites can still batch together instead of owning materials.
varying vec4 dust_data;
uniform float twinkle_strength : hint_range(0.0, 0.3) = 0.075;

void vertex() {
	dust_data = COLOR;
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float brightness = dust_data.r * (1.0 + twinkle_strength * sin(TIME * 5.0 + dust_data.g * 6.283185));
	float highlight = clamp(brightness - 1.0, 0.0, 1.0) * 0.55;
	ink.rgb = mix(ink.rgb * min(brightness, 1.0), vec3(1.0), highlight);
	ink.a *= dust_data.a;
	COLOR = ink;
}
