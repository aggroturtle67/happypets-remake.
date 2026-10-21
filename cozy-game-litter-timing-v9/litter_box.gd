extends Node2D
class_name LitterBox


signal cleanliness_changed(new_cleanliness: float)


@export_category("Streuzustände")
@export var clean_texture: Texture2D
@export var light_texture: Texture2D
@export var medium_texture: Texture2D
@export var dirt_texture: Texture2D
@export var full_texture: Texture2D


@export_category("Automatische Verschmutzung")
@export var automatic_soiling: bool = true
## Kontinuierlicher Verlust: 25 Punkte in drei Minuten; voll nach zwölf Minuten.
@export_range(1.0, 3600.0, 1.0) var seconds_per_stage: float = 180.0

@onready var box_sprite: Sprite2D = $BoxSprite
@onready var litter_state: Sprite2D = $LitterState


var placed_item_data: PlacedItemData
var cleanliness_amount: float = 100.0
var is_being_cleaned: bool = false



func _ready() -> void:
	get_node("/root/RoomManager").register_litter_box(self)
	_update_litter_visual()


func setup(
	item_data: ItemData,
	placed_data: PlacedItemData
) -> void:
	placed_item_data = placed_data
	box_sprite.texture = item_data.default_texture

	cleanliness_amount = clampf(
		float(placed_data.state.get("cleanliness", 100.0)),
		0.0,
		100.0
	)

	placed_item_data.state["cleanliness"] = cleanliness_amount
	_update_litter_visual()


func set_cleanliness(new_cleanliness: float) -> void:
	cleanliness_amount = clampf(
		new_cleanliness,
		0.0,
		100.0
	)

	if placed_item_data != null:
		placed_item_data.state["cleanliness"] = cleanliness_amount

	_update_litter_visual()
	cleanliness_changed.emit(cleanliness_amount)


func _process(delta: float) -> void:
	if not automatic_soiling or is_being_cleaned or cleanliness_amount <= 0.0:
		return
	var loss: float = maxf(delta, 0.0) * 25.0 / maxf(seconds_per_stage, 1.0)
	set_cleanliness(cleanliness_amount - loss)


func _update_litter_visual() -> void:
	if not is_node_ready():
		return

	if cleanliness_amount > 75.0:
		litter_state.texture = clean_texture
	elif cleanliness_amount > 50.0:
		litter_state.texture = light_texture
	elif cleanliness_amount > 25.0:
		litter_state.texture = medium_texture
	elif cleanliness_amount > 0.0:
		litter_state.texture = dirt_texture
	else:
		litter_state.texture = full_texture
