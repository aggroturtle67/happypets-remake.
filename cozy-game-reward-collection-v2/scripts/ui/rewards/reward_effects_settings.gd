extends Resource
## UI distances are in logical viewport pixels (Godot applies window stretch).
@export_group("Original artwork")
@export var coin_single: Texture2D
@export var coin_double: Texture2D
@export var xp_single: Texture2D
@export var xp_double: Texture2D
@export var coin_particle: Texture2D
@export var xp_particle: Texture2D

@export_group("Jump and landing")
@export_range(0.1, 5.0) var flight_speed: float = 1.0
@export_range(0.1, 3.0) var flight_duration: float = 0.65
@export_range(20.0, 500.0) var flight_distance: float = 130.0
@export_range(0.0, 150.0) var scatter: float = 55.0
@export_range(0.0, 250.0) var jump_height: float = 70.0
@export_range(0.0, 25.0) var landing_bounce: float = 7.0
@export_range(16.0, 100.0) var symbol_size: float = 48.0
@export_range(0.0, 0.3) var size_variation: float = 0.1
@export_range(1.0, 2.0) var double_coin_scale: float = 1.18
@export_range(1.0, 2.0) var double_xp_scale: float = 1.45
@export_range(2.0, 50.0) var symbol_gap: float = 12.0
@export var land_on_room_floor: bool = true
@export_range(0.0, 0.2) var shimmer_intensity: float = 0.065

@export_group("Hover and collection")
@export_range(10.0, 200.0) var magnet_radius: float = 65.0
@export_range(0.1, 1.0) var collection_duration: float = 0.32
@export_range(0.0, 70.0) var collection_jump: float = 23.0
@export_range(1, 64) var single_particles: int = 24
@export_range(1, 96) var double_particles: int = 36
@export_range(0.1, 5.0) var particle_speed: float = 1.0
@export_range(0.2, 3.0) var particle_duration: float = 0.85
@export_range(2.0, 14.0) var particle_size: float = 5.0
@export_range(0.1, 1.0) var particle_min_scale: float = 0.25
@export_range(1.0, 3.0) var particle_max_scale: float = 1.6
@export_range(0.2, 1.0) var particle_min_brightness: float = 0.65
@export_range(1.0, 2.5) var particle_max_brightness: float = 2.0
@export_range(0.0, 0.3) var particle_twinkle: float = 0.075
@export_range(0.0, 100.0) var particle_scatter: float = 26.0

@export_group("UI feedback")
@export_range(0.0, 0.1) var ui_pulse: float = 0.035
@export_range(0.2, 5.0) var plus_duration: float = 1.5
@export_range(0.1, 1.0) var plus_fade: float = 0.3

@export_group("Grouping and performance")
## Only presentation is grouped; credit and saving happen immediately.
@export_range(0.0, 2.0) var batch_quiet_time: float = 0.0
@export_range(0.2, 10.0) var batch_max_time: float = 6.0
@export_range(0.01, 0.3) var spawn_interval: float = 0.045
@export_range(1, 16) var spawns_per_frame: int = 4

var _images: Dictionary = {}
var _dust_material: ShaderMaterial

func symbol_scale(currency: StringName, value: int) -> float:
	if value != 2:
		return 1.0
	return double_coin_scale if currency == &"coins" else double_xp_scale

func maximum_symbol_size() -> float:
	return symbol_size * (1.0 + size_variation) * maxf(1.0, maxf(double_coin_scale, double_xp_scale))

func dust_material() -> ShaderMaterial:
	if _dust_material == null:
		_dust_material = ShaderMaterial.new()
		_dust_material.shader = preload("res://assets/UI/shaders/reward_dust.gdshader")
		_dust_material.set_shader_parameter("twinkle_strength", particle_twinkle)
	return _dust_material

func image_for(texture: Texture2D) -> Image:
	var key: int = texture.get_instance_id()
	if not _images.has(key):
		var image: Image = texture.get_image()
		if image.is_compressed():
			image.decompress()
		_images[key] = image
	return _images[key]

func artwork(currency: StringName, value: int) -> Texture2D:
	if currency == &"coins":
		return coin_double if value == 2 else coin_single
	return xp_double if value == 2 else xp_single

func particle_artwork(currency: StringName) -> Texture2D:
	return coin_particle if currency == &"coins" else xp_particle

func is_complete() -> bool:
	return coin_single != null and coin_double != null and xp_single != null and xp_double != null and coin_particle != null and xp_particle != null
