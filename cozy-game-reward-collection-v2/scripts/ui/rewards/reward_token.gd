extends Control
## A visual receipt. This script never calls GameManager or writes a save.
signal received(currency: StringName, value: int)
enum Phase { FLYING, LANDED, COLLECTING, DONE }
const SYMBOL_SHADER = preload("res://assets/UI/shaders/reward_symbol.gdshader")

var currency: StringName
var value: int
var phase: Phase = Phase.FLYING
var landing_world: Vector2
var current_world: Vector2
var flight_tween: Tween
var _settings
var _rng := RandomNumberGenerator.new()
var _project: Callable
var _target: Callable
var _start_world: Vector2
var _jump_world: Vector2
var _visual: Control
var _icon: TextureRect
var _material: ShaderMaterial
var _draw_size: Vector2
var _shimmer: Tween
var _received_once: bool = false
var _parts_remaining: int = 0

func setup(config: Resource, kind: StringName, points: int, start: Vector2, landing: Vector2,
		jump: Vector2, project_world: Callable, target_position: Callable, seed_value: int) -> void:
	_settings = config
	currency = kind
	value = points
	_start_world = start
	current_world = start
	landing_world = landing
	_jump_world = jump
	_project = project_world
	_target = target_position
	_rng.seed = seed_value

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual = Control.new()
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)
	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.texture = _settings.artwork(currency, value)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var factor: float = _settings.symbol_size * _rng.randf_range(1.0 - _settings.size_variation, 1.0 + _settings.size_variation)
	factor *= _settings.symbol_scale(currency, value)
	_draw_size = _icon.texture.get_size() * factor / maxf(_icon.texture.get_width(), _icon.texture.get_height())
	_icon.size = _draw_size
	_icon.position = -_draw_size * 0.5
	_material = ShaderMaterial.new()
	_material.shader = SYMBOL_SHADER
	_material.set_shader_parameter("shimmer", 0.0)
	_material.set_shader_parameter("dissolve", 0.0)
	_icon.material = _material
	_visual.add_child(_icon)
	position = _project.call(current_world)
	var duration: float = _settings.flight_duration / maxf(_settings.flight_speed, 0.05) * _rng.randf_range(0.85, 1.15)
	flight_tween = create_tween()
	flight_tween.tween_interval(_rng.randf_range(0.0, 0.07))
	flight_tween.tween_method(_fly, 0.0, 1.0, duration)
	flight_tween.tween_method(_bounce, 0.0, 1.0, 0.18)
	flight_tween.tween_callback(_land)

func _fly(t: float) -> void:
	current_world = _start_world.lerp(landing_world, t) - _jump_world * (4.0 * t * (1.0 - t))
	position = _project.call(current_world)

func _bounce(t: float) -> void:
	current_world = landing_world
	_visual.position.y = -sin(PI * t) * _settings.landing_bounce

func _land() -> void:
	phase = Phase.LANDED
	current_world = landing_world
	_visual.position = Vector2.ZERO
	_shimmer = create_tween().set_loops()
	_shimmer.tween_interval(_rng.randf_range(2.4, 5.5))
	_shimmer.tween_method(_set_shimmer, 0.0, float(_settings.shimmer_intensity), 0.3).set_trans(Tween.TRANS_SINE)
	_shimmer.tween_method(_set_shimmer, float(_settings.shimmer_intensity), 0.0, 0.55).set_trans(Tween.TRANS_SINE)

func _set_shimmer(amount: float) -> void:
	_material.set_shader_parameter("shimmer", amount)

func _process(_delta: float) -> void:
	if phase == Phase.FLYING or phase == Phase.LANDED:
		position = _project.call(current_world)
	# Offscreen ground tokens remain in their world position when the camera pans.
	# They reappear on returning, without either credit or collection being repeated.
	visible = phase == Phase.COLLECTING or get_viewport().get_visible_rect().grow(_settings.symbol_size).has_point(get_global_transform_with_canvas().origin)

func try_collect(mouse: Vector2) -> bool:
	if phase != Phase.LANDED:
		return false
	# Camera updates precede this parent's hover pass; use the current projection,
	# not the previous frame's screen position.
	position = _project.call(current_world)
	visible = get_viewport().get_visible_rect().grow(_settings.symbol_size).has_point(get_global_transform_with_canvas().origin)
	if not visible or position.distance_to(mouse) > _settings.magnet_radius:
		return false
	phase = Phase.COLLECTING # Set before any tween, so overlapping hover checks are safe.
	if is_instance_valid(_shimmer):
		_shimmer.kill()
	_set_shimmer(0.0)
	var pull: Vector2 = (mouse - position).limit_length(75.0) * 0.24
	var collect: Tween = create_tween()
	collect.tween_method(func(t: float) -> void:
		_visual.position = pull * t + Vector2(0, -sin(PI * t) * _settings.collection_jump),
		0.0, 1.0, _settings.collection_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	collect.tween_callback(_dissolve)
	return true

func _dissolve() -> void:
	var count: int = maxi(1, _settings.double_particles if value == 2 else _settings.single_particles)
	_parts_remaining = count
	var dissolve: Tween = create_tween()
	dissolve.tween_method(func(t: float) -> void: _material.set_shader_parameter("dissolve", t), 0.0, 1.0, 0.19)
	dissolve.tween_callback(func() -> void: _icon.visible = false)
	var image: Image = _settings.image_for(_icon.texture)
	for index in count:
		var uv := Vector2(0.5, 0.5)
		for attempt in 24:
			uv = Vector2(_rng.randf(), _rng.randf())
			var px := Vector2i(clampi(int(uv.x * image.get_width()), 0, image.get_width() - 1), clampi(int(uv.y * image.get_height()), 0, image.get_height() - 1))
			if image.get_pixelv(px).a > 0.25:
				break
		var particle := Sprite2D.new()
		particle.texture = _settings.particle_artwork(currency)
		particle.material = _settings.dust_material()
		# Many tiny specks, some larger ones; brightness varies independently.
		var size_variation: float = lerpf(_settings.particle_min_scale, _settings.particle_max_scale, pow(_rng.randf(), 1.6))
		var size_factor: float = _settings.particle_size * size_variation / maxf(particle.texture.get_width(), particle.texture.get_height())
		particle.scale = Vector2.ONE * size_factor
		var brightness: float = _rng.randf_range(_settings.particle_min_brightness, _settings.particle_max_brightness)
		# Shared dust shader interprets red as brightness and green as twinkle phase.
		# The original gold/blue texture supplies the actual hue, not this data color.
		particle.self_modulate = Color(brightness, _rng.randf(), 1.0, 1.0)
		add_child(particle)
		var start: Vector2 = position + _visual.position + (uv - Vector2.ONE * 0.5) * _draw_size
		var spread: Vector2 = start + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(6, _settings.particle_scatter)
		var curve: Vector2 = Vector2(_rng.randf_range(-95, 95), -_rng.randf_range(35, 120))
		var duration: float = _settings.particle_duration / maxf(_settings.particle_speed, 0.05) * _rng.randf_range(0.85, 1.2)
		var tween: Tween = create_tween()
		tween.tween_method(_move_particle.bind(particle, start, spread, curve), 0.0, 1.0, duration)
		tween.tween_callback(_part_arrived.bind(particle))

func _move_particle(t: float, particle: Sprite2D, start: Vector2, spread: Vector2, curve: Vector2) -> void:
	var point: Vector2
	if t < 0.22:
		point = start.lerp(spread, sin(t / 0.22 * PI * 0.5))
	else:
		var u: float = pow((t - 0.22) / 0.78, 1.8) # Accelerate towards the UI.
		var target: Vector2 = _target.call()
		var first: Vector2 = spread + curve
		var second: Vector2 = target + curve * 0.35
		point = pow(1.0 - u, 3) * spread + 3.0 * pow(1.0 - u, 2) * u * first + 3.0 * (1.0 - u) * u * u * second + u * u * u * target
		particle.modulate.a = 1.0 - smoothstep(0.87, 1.0, u)
	particle.position = point - position

func _part_arrived(particle: Sprite2D) -> void:
	particle.queue_free()
	_parts_remaining -= 1
	if _parts_remaining == 0 and not _received_once:
		_received_once = true
		phase = Phase.DONE
		received.emit(currency, value)
		queue_free()
