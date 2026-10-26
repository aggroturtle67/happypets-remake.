extends Control
## F6 / GPU regression probe: plain textures on the left, neutral shaders right.
## Both panels must have identical RGB output. No new artwork is generated.
const SYMBOL = preload("res://assets/UI/shaders/reward_symbol.gdshader")
const DUST = preload("res://assets/UI/shaders/reward_dust.gdshader")

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("d9bcba")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var paths: Array[String] = ["coin_single.png", "xp_single.png", "coin_particle.png", "xp_particle.png"]
	for index in paths.size():
		for side in 2:
			var image := TextureRect.new()
			image.position = Vector2(30 + side * 330 + (index % 2) * 780, 30 + int(index / 2.0) * 360)
			image.size = Vector2(300, 300)
			image.texture = load("res://assets/UI/rewards/" + paths[index])
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if side == 1:
				var material := ShaderMaterial.new()
				material.shader = SYMBOL if index < 2 else DUST
				material.set_shader_parameter("shimmer", 0.0)
				material.set_shader_parameter("twinkle_strength", 0.0)
				image.material = material
			add_child(image)
	# The same batching-friendly shader must retain both dark and bright values.
	for currency in 2:
		for sample in 3:
			var dust := TextureRect.new()
			dust.position = Vector2(30 + sample * 210 + currency * 780, 750)
			dust.size = Vector2(180, 180)
			dust.texture = load("res://assets/UI/rewards/" + ("coin_particle.png" if currency == 0 else "xp_particle.png"))
			dust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var material := ShaderMaterial.new()
			material.shader = DUST
			material.set_shader_parameter("twinkle_strength", 0.0)
			dust.material = material
			var brightness: float = [0.65, 1.0, 2.0][sample]
			dust.self_modulate = Color(brightness, 0, 1, 1)
			add_child(dust)
