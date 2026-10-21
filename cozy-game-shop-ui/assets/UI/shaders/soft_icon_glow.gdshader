shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.95);
uniform vec2 icon_size = vec2(200.0, 200.0);
uniform vec2 drawing_size = vec2(232.0, 232.0);
uniform float sample_step : hint_range(0.5, 4.0) = 2.0;
uniform float glow_strength : hint_range(0.0, 3.0) = 2.0;

void fragment() {
	// Preserve space for the blur outside the original PNG's bounds.
	vec2 icon_uv = (UV - vec2(0.5)) * drawing_size / icon_size + vec2(0.5);
	float alpha_sum = 0.0;
	float weight_sum = 0.0;
	for (int y = -4; y <= 4; y++) {
		for (int x = -4; x <= 4; x++) {
			vec2 offset = vec2(float(x), float(y));
			float weight = exp(-dot(offset, offset) / 8.0);
			vec2 sample_uv = icon_uv + offset * sample_step / icon_size;
			float source_alpha = 0.0;
			if (sample_uv.x >= 0.0 && sample_uv.y >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y <= 1.0) {
				source_alpha = texture(TEXTURE, sample_uv).a;
			}
			alpha_sum += source_alpha * weight;
			weight_sum += weight;
		}
	}
	float glow_alpha = clamp(alpha_sum / weight_sum * glow_strength, 0.0, 1.0);
	COLOR = vec4(glow_color.rgb, glow_alpha * glow_color.a);
}
