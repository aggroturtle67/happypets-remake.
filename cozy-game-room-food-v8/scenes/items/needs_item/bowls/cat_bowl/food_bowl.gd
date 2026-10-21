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
# Nur während des aktiven Auffüllens reserviert, nicht im Spielstand speichern.
var is_being_filled: bool = false


const MEAL_SIZE: float = 50.0
var reserved_by: CharacterBody2D
var reserved_food_remaining: float = 0.0

func has_reservation(cat: CharacterBody2D) -> bool:
	return is_instance_valid(reserved_by) and reserved_by == cat

func can_claim(cat: CharacterBody2D, amount: float = MEAL_SIZE) -> bool:
	if is_being_filled:
		return false
	if is_instance_valid(reserved_by):
		return reserved_by == cat and fill_amount > 0.0
	return fill_amount + 0.000001 >= amount

func reserve_meal(cat: CharacterBody2D, amount: float = MEAL_SIZE) -> bool:
	if not can_claim(cat, amount):
		return false
	if not has_reservation(cat):
		reserved_by = cat
		reserved_food_remaining = amount
	return true

func release_meal(cat: CharacterBody2D) -> void:
	if has_reservation(cat):
		reserved_by = null
		reserved_food_remaining = 0.0

func consume_meal(cat: CharacterBody2D, requested: float) -> float:
	if not has_reservation(cat) or is_being_filled:
		return 0.0
	var portion: float = minf(maxf(requested, 0.0), minf(reserved_food_remaining, fill_amount))
	reserved_food_remaining = maxf(reserved_food_remaining - portion, 0.0)
	set_fill(fill_amount - portion)
	return portion

func _ready() -> void:
	var count: int = 0
	for other in get_tree().get_nodes_in_group(&"food_bowls"):
		if other.get_parent() == get_parent() and not other.is_queued_for_deletion():
			count += 1
	if count >= get_node("/root/RoomManager").MAX_FOOD_BOWLS:
		queue_free()
		return
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
