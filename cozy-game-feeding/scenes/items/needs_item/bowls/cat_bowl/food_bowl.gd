extends Node2D
class_name FoodBowl


signal fill_changed(new_fill: float)


@export_category("Futterzustände")
@export var low_texture: Texture2D
@export var medium_texture: Texture2D
@export var high_texture: Texture2D
@export var full_texture: Texture2D


@onready var bowl_sprite: Sprite2D = $BowlSprite
@onready var food_fill: Sprite2D = $FoodFill


var placed_item_data: PlacedItemData
var fill_amount: float = 100.0


func _ready() -> void:
	add_to_group(&"food_bowls")
	_update_food_visual()


func setup(
	item_data: ItemData,
	placed_data: PlacedItemData
) -> void:
	placed_item_data = placed_data
	bowl_sprite.texture = item_data.default_texture

	fill_amount = clampf(
		float(placed_data.state.get("fill", 100.0)),
		0.0,
		100.0
	)

	placed_item_data.state["fill"] = fill_amount
	_update_food_visual()


func set_fill(new_fill: float) -> void:
	fill_amount = clampf(new_fill, 0.0, 100.0)

	if placed_item_data != null:
		placed_item_data.state["fill"] = fill_amount

	_update_food_visual()
	fill_changed.emit(fill_amount)


func _update_food_visual() -> void:
	if not is_node_ready():
		return

	if fill_amount <= 0.0:
		food_fill.hide()
		return

	food_fill.show()

	if fill_amount <= 25.0:
		food_fill.texture = low_texture
	elif fill_amount <= 50.0:
		food_fill.texture = medium_texture
	elif fill_amount <= 75.0:
		food_fill.texture = high_texture
	else:
		food_fill.texture = full_texture
