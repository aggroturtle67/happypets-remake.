extends Node


var current_room_state: RoomState


func start_new_game_room() -> void:
	current_room_state = RoomState.new()

	current_room_state.active_wall_id = "wallpaper_001"
	current_room_state.active_floor_id = "floor_001"

	var food_bowl := _create_starting_food_bowl()
	current_room_state.placed_items.append(food_bowl)

	var litter_box := PlacedItemData.new()
	litter_box.instance_id = "litter_box_start"
	litter_box.item_id = "litter_box_basic"
	litter_box.position = Vector2(1120, 790)
	litter_box.state = {"cleanliness": 100.0}
	current_room_state.placed_items.append(litter_box)


func _create_starting_food_bowl() -> PlacedItemData:
	var food_bowl := PlacedItemData.new()

	food_bowl.instance_id = "food_bowl_start"
	food_bowl.item_id = "food_bowl_basic_pink"
	food_bowl.position = Vector2(500, 700)
	food_bowl.state = {
		"fill": 0.0
	}

	return food_bowl
