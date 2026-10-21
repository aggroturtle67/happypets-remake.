extends Node2D


@onready var wall_surface: Sprite2D = $SurfaceLayer/WallSurface
@onready var floor_surface: Sprite2D = $SurfaceLayer/FloorSurface

@onready var wall_item_layer: Node2D = $WallItemLayer
@onready var floor_y_sort_layer: Node2D = $FloorYSortLayer
@onready var overlay_layer: Node2D = $OverlayLayer


# Verknüpft die instance_id eines platzierten Items
# mit seinem erzeugten Node im Raum.
var placed_item_nodes: Dictionary = {}


func _ready() -> void:
	floor_y_sort_layer.y_sort_enabled = true

	if RoomManager.current_room_state == null:
		RoomManager.start_new_game_room()

	load_room(RoomManager.current_room_state)
	for id in RoomManager.saved_cat_states:
		var present: bool = false
		for child in floor_y_sort_layer.get_children():
			if child.is_in_group(&"cats") and str(child.get("pet_id")) == str(id):
				present = true
		if not present:
			var record: Dictionary = RoomManager.saved_cat_states[id]
			var point := Vector2(float(record["position"][0]), float(record["position"][1]))
			try_add_cat(point, str(id))
	RoomManager.attach_room(self)


func load_room(room_state: RoomState) -> void:
	apply_surfaces(room_state)
	load_placed_items(room_state)


func apply_surfaces(room_state: RoomState) -> void:
	var wall_data: ItemData = ItemDatabase.get_item(
		room_state.active_wall_id
	)

	if wall_data != null:
		wall_surface.texture = wall_data.default_texture

	var floor_data: ItemData = ItemDatabase.get_item(
		room_state.active_floor_id
	)

	if floor_data != null:
		floor_surface.texture = floor_data.default_texture


func load_placed_items(room_state: RoomState) -> void:
	for placed_data in room_state.placed_items:
		_create_placed_item(placed_data)


func _create_placed_item(
	placed_data: PlacedItemData
) -> void:
	var item_data: ItemData = ItemDatabase.get_item(
		placed_data.item_id
	)

	if item_data == null:
		return

	if item_data.scene == null:
		push_warning(
			"Item besitzt keine Szene: " + item_data.item_id
		)
		return

	var target_layer := _get_item_layer(
		item_data.layer_type
	)

	if target_layer == null:
		return

	var item_instance: Node = item_data.scene.instantiate()

	if not item_instance is Node2D:
		push_warning(
			"Item-Szene benötigt einen Node2D als Hauptnode: "
			+ item_data.item_id
		)
		item_instance.queue_free()
		return

	var item_node := item_instance as Node2D
	if item_node is FoodBowl and food_bowl_count() >= RoomManager.MAX_FOOD_BOWLS:
		item_node.free()
		return

	target_layer.add_child(item_node)
	item_node.position = placed_data.position

	if item_node.has_method("setup"):
		item_node.call(
			"setup",
			item_data,
			placed_data
		)

	placed_item_nodes[placed_data.instance_id] = item_node


func _get_item_layer(layer_type: String) -> Node2D:
	match layer_type:
		"wall_item":
			return wall_item_layer

		"floor_y_sort":
			return floor_y_sort_layer

		"overlay":
			return overlay_layer

		_:
			push_warning(
				"Unbekannter Layer Type: " + layer_type
			)
			return null


func food_bowl_count() -> int:
	var count: int = 0
	for node in floor_y_sort_layer.get_children():
		if node is FoodBowl and not node.is_queued_for_deletion():
			count += 1
	return count


func try_add_food_bowl(at_position: Vector2) -> FoodBowl:
	if food_bowl_count() >= RoomManager.MAX_FOOD_BOWLS:
		return null
	var placed := PlacedItemData.new()
	placed.instance_id = "food_bowl_%s" % Time.get_ticks_usec()
	placed.item_id = "food_bowl_basic_pink"
	placed.position = at_position
	placed.state = {"fill": 0.0}
	_create_placed_item(placed)
	var bowl := placed_item_nodes.get(placed.instance_id) as FoodBowl
	if bowl != null:
		RoomManager.current_room_state.placed_items.append(placed)
	return bowl


func try_add_cat(at_position: Vector2, cat_id: String = "") -> CharacterBody2D:
	var count: int = 0
	for node in floor_y_sort_layer.get_children():
		if node.is_in_group(&"cats") and not node.is_queued_for_deletion():
			count += 1
	if count >= RoomManager.MAX_CATS:
		return null
	var cat: CharacterBody2D = load("res://scenes/pets/cats/cat.tscn").instantiate()
	cat.set("pet_id", cat_id if not cat_id.is_empty() else RoomManager.next_cat_id())
	cat.position = at_position
	floor_y_sort_layer.add_child(cat)
	return cat
