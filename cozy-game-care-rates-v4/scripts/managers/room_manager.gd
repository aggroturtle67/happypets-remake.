extends Node


signal room_food_changed(value: float)
signal room_cleanliness_changed(value: float)

const OfflineConsumption = preload("res://scripts/managers/offline_consumption.gd")

const CareRewards = preload("res://scripts/managers/care_rewards.gd")

const MAX_CATS: int = 6
const MAX_FOOD_BOWLS: int = 3
var active_room: Node2D
var room_food: float = 0.0
var room_cleanliness: float = 0.0
var saved_cat_states: Dictionary = {}
var _cat_sequence: int = 0

var persistence_enabled: bool = true
var save_path: String = "user://room_food_state_v1.json"
var has_loaded_save: bool = false
var _save_elapsed: float = 0.0
var _save_time_floor: float = 0.0
var progress_state: Dictionary = CareRewards.normalize({})

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Deterministic verification scripts explicitly disable normal user saves.
	persistence_enabled = OS.get_environment("COZYGAME_TEST_MODE") != "1"
	if not persistence_enabled or not load_game():
		start_new_game_room()
	get_tree().auto_accept_quit = false

func _process(delta: float) -> void:
	if not persistence_enabled:
		return
	_save_elapsed += delta
	if _save_elapsed >= 5.0:
		_save_elapsed = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

var current_room_state: RoomState


func start_new_game_room() -> void:
	progress_state = CareRewards.normalize({})
	_save_time_floor = 0.0
	var game: Node = get_node_or_null("/root/GameManager")
	if game != null:
		game.call("restore_progress", progress_state)
	has_loaded_save = false
	saved_cat_states.clear()
	current_room_state = RoomState.new()

	current_room_state.active_wall_id = "wallpaper_001"
	current_room_state.active_floor_id = "floor_001"

	var food_bowl := _create_starting_food_bowl()
	current_room_state.placed_items.append(food_bowl)

	var litter_box := PlacedItemData.new()
	litter_box.instance_id = "litter_box_start"
	litter_box.item_id = "litter_box_basic"
	litter_box.position = Vector2(1120, 790)
	litter_box.state = {"cleanliness": 0.0}
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


func attach_room(room: Node2D) -> void:
	active_room = room
	refresh_room_needs()


func room_nodes(group: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group):
		if not node.is_inside_tree() or node.is_queued_for_deletion():
			continue
		if is_instance_valid(active_room) and node.get_parent() != active_room.get_node("FloorYSortLayer"):
			continue
		result.append(node)
	return result


func register_cat(cat: CharacterBody2D) -> bool:
	var count: int = 0
	for other in get_tree().get_nodes_in_group(&"cats"):
		if other.get_parent() == cat.get_parent() and not other.is_queued_for_deletion():
			count += 1
	if count >= MAX_CATS:
		return false
	cat.add_to_group(&"cats")
	cat.connect("satiety_changed", _on_need_changed)
	cat.tree_exiting.connect(_refresh_after_exit)
	refresh_room_needs.call_deferred()
	return true


func next_cat_id() -> String:
	_cat_sequence += 1
	return "cat_%s_%s" % [Time.get_ticks_usec(), _cat_sequence]


func register_litter_box(box: Node2D) -> void:
	box.add_to_group(&"litter_boxes")
	box.cleanliness_changed.connect(_on_need_changed)
	box.tree_exiting.connect(_refresh_after_exit)
	refresh_room_needs.call_deferred()


func _on_need_changed(_value: float) -> void:
	refresh_room_needs()


func _refresh_after_exit() -> void:
	refresh_room_needs.call_deferred()


func refresh_room_needs() -> void:
	var cats: Array[Node] = room_nodes(&"cats")
	var food_total: float = 0.0
	for cat in cats:
		food_total += float(cat.get("satiety"))
	room_food = food_total / cats.size() if not cats.is_empty() else 0.0
	var boxes: Array[Node] = room_nodes(&"litter_boxes")
	var clean_total: float = 0.0
	for box in boxes:
		clean_total += float(box.get("cleanliness_amount"))
	room_cleanliness = clean_total / boxes.size() if not boxes.is_empty() else 0.0
	room_food_changed.emit(room_food)
	room_cleanliness_changed.emit(room_cleanliness)


func restore_cat(cat: CharacterBody2D) -> void:
	var record: Dictionary = saved_cat_states.get(str(cat.get("pet_id")), {})
	if record.is_empty():
		return
	cat.set("affection", OfflineConsumption.number(record.get("affection"), float(cat.get("starting_affection")), 0.0, 100.0))
	cat.set("satiety", clampf(float(record.get("satiety", 0.0)), 0.0, 100.0))
	cat.position = _read_vector(record.get("position", []), cat.position)
	cat.set("pending_meal_restore", record.get("meal", {}).duplicate(true))


func _read_vector(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if not value is Array or value.size() != 2:
		return fallback
	if not (value[0] is float or value[0] is int) or not (value[1] is float or value[1] is int):
		return fallback
	var result := Vector2(float(value[0]), float(value[1]))
	return result if result.is_finite() else fallback


func save_game() -> bool:
	if not persistence_enabled or not is_instance_valid(active_room) or not active_room.is_inside_tree():
		return false
	var items: Array = []
	for node in active_room.get_node("FloorYSortLayer").get_children():
		if node.is_queued_for_deletion() or not (node is FoodBowl or node is LitterBox):
			continue
		var placed: PlacedItemData = node.get("placed_item_data")
		if placed == null:
			continue
		items.append({"id": placed.instance_id, "item_id": placed.item_id,
			"position": [node.position.x, node.position.y], "state": placed.state.duplicate(true)})
		if node is LitterBox:
			items[-1]["state"]["seconds_per_stage"] = node.seconds_per_stage
			items[-1]["state"]["automatic_soiling"] = node.automatic_soiling
	var cats: Array = []
	for cat in room_nodes(&"cats"):
		cats.append(cat.call("export_food_state"))
	progress_state = get_node("/root/GameManager").call("export_progress")
	var snapshot_time: float = maxf(Time.get_unix_time_from_system(), _save_time_floor)
	var record: Dictionary = {"version": 1, "progress": progress_state, "saved_at_seconds": snapshot_time, "room": {
		"wall": current_room_state.active_wall_id, "floor": current_room_state.active_floor_id,
		"items": items}, "cats": cats}
	var saved: bool = _write_record(record)
	if saved:
		_save_time_floor = snapshot_time
	return saved


func _write_record(record: Dictionary) -> bool:
	var absolute: String = ProjectSettings.globalize_path(save_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(record))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(absolute + ".tmp", absolute) == OK


func load_game(now_seconds: float = -1.0) -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not record is Dictionary or record.get("version") != 1:
		return false
	var room_record: Variant = record.get("room")
	var cat_records: Variant = record.get("cats")
	if not room_record is Dictionary or not cat_records is Array or not room_record.get("items") is Array:
		return false
	var restored := RoomState.new()
	restored.active_wall_id = str(room_record.get("wall", "wallpaper_001"))
	restored.active_floor_id = str(room_record.get("floor", "floor_001"))
	var ids: Dictionary = {}
	var bowls: int = 0
	for entry in room_record["items"]:
		if not entry is Dictionary or not entry.get("state") is Dictionary:
			continue
		var item: ItemData = ItemDatabase.get_item(str(entry.get("item_id", "")))
		if item == null or item.scene == null:
			continue
		var probe: Node = item.scene.instantiate()
		var is_bowl: bool = probe is FoodBowl
		var supported: bool = is_bowl or probe is LitterBox
		probe.free()
		if not supported or (is_bowl and bowls >= MAX_FOOD_BOWLS):
			continue
		var id: String = str(entry.get("id", ""))
		if id.is_empty() or ids.has(id):
			continue
		var key: String = "fill" if is_bowl else "cleanliness"
		var number: Variant = entry["state"].get(key, 0.0)
		if not (number is int or number is float) or not is_finite(float(number)):
			continue
		var placed := PlacedItemData.new()
		placed.instance_id = id
		placed.item_id = item.item_id
		placed.position = _read_vector(entry.get("position", []))
		placed.state = {key: clampf(float(number), 0.0, 100.0)}
		if not is_bowl:
			placed.state["seconds_per_stage"] = OfflineConsumption.number(entry["state"].get("seconds_per_stage"), 180.0, 1.0)
			placed.state["automatic_soiling"] = entry["state"].get("automatic_soiling", true) == true
		restored.placed_items.append(placed)
		ids[id] = true
		if is_bowl:
			bowls += 1
	var cats: Dictionary = {}
	for entry in cat_records:
		if cats.size() >= MAX_CATS:
			break
		if not entry is Dictionary:
			continue
		var id: String = str(entry.get("id", ""))
		var value: Variant = entry.get("satiety")
		if id.is_empty() or cats.has(id) or not (value is float or value is int) or not is_finite(float(value)):
			continue
		var position: Vector2 = _read_vector(entry.get("position", []), Vector2(400, 750))
		cats[id] = {"id": id, "satiety": clampf(float(value), 0.0, 100.0),
			"position": [position.x, position.y], "meal": entry.get("meal", {}) if entry.get("meal", {}) is Dictionary else {}}
		if entry.has("affection"):
			cats[id]["affection"] = OfflineConsumption.number(entry["affection"], 100.0, 0.0, 100.0)
			cats[id]["affection_loss_per_second"] = OfflineConsumption.number(entry.get("affection_loss_per_second"), 55.0 / (36.0 * 3600.0))
		for key in ["satiety_loss_per_second", "hungry_threshold", "eating_per_second", "movement_speed", "bowl_offset"]:
			if entry.has(key):
				cats[id][key] = entry[key]
	if now_seconds < 0.0:
		now_seconds = Time.get_unix_time_from_system()
	# Older saves have no timestamp: start the clock now, without charging their age.
	var saved_at: float = OfflineConsumption.number(record.get("saved_at_seconds"), now_seconds)
	var progress: Dictionary = CareRewards.normalize(record.get("progress", {}))
	var food_restored: float = OfflineConsumption.advance(cats, restored.placed_items, maxf(0.0, now_seconds - saved_at))
	CareRewards.add_points(progress, food_restored, &"food")
	_save_time_floor = maxf(now_seconds, saved_at)
	record["progress"] = progress
	# Commit the advanced baseline before creating live nodes (prevents double charging).
	if persistence_enabled:
		record["saved_at_seconds"] = maxf(now_seconds, saved_at)
		record["cats"] = cats.values()
		for entry in room_record["items"]:
			if entry is Dictionary:
				for placed in restored.placed_items:
					if placed.instance_id == str(entry.get("id", "")):
						entry["state"] = placed.state.duplicate(true)
		if not _write_record(record):
			push_warning("Offline-Spielstand konnte nicht gespeichert werden.")
	progress_state = progress
	var game: Node = get_node_or_null("/root/GameManager")
	if game != null:
		game.call("restore_progress", progress_state)
	current_room_state = restored
	saved_cat_states = cats
	has_loaded_save = true
	return true
