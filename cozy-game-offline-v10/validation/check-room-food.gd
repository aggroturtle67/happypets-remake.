extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func freeze(cat) -> void:
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	cat.behavior_state = cat.BehaviorState.IDLE
	cat.has_movement_target = false
	cat.cat_visual.play_idle()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	Engine.time_scale = 4.0
	var manager = root.get_node("RoomManager")
	check(not manager.persistence_enabled, "Verification must isolate normal save files")
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var room = scene.get_node("MainRoom")
	var display: NeedsDisplay = scene.find_child("NeedsDisplay", true, false)
	var control: InteractionController = scene.get_node("InteractionController")
	var cats: Array = manager.room_nodes(&"cats")
	freeze(cats[0])
	for index in 5:
		var cat = room.try_add_cat(Vector2(550 + index * 210, 950))
		check(cat != null, "Six cats can live in room")
		freeze(cat)
	cats = manager.room_nodes(&"cats")
	check(cats.size() == 6 and room.try_add_cat(Vector2(900, 900)) == null, "Seventh cat must be refused")
	for index in 6:
		cats[index].set_satiety(100.0 if index < 5 else 0.0)
	check(is_equal_approx(display.hunger_bar.value, 500.0 / 6.0), "Room Food must average all six cats")
	var first: FoodBowl = room.placed_item_nodes["food_bowl_start"]
	var second: FoodBowl = room.try_add_food_bowl(Vector2(900, 730))
	var third: FoodBowl = room.try_add_food_bowl(Vector2(1400, 750))
	check(second != null and third != null and room.try_add_food_bowl(Vector2(1200, 900)) == null,
		"Room permits exactly three bowls")
	var bowls: Array[FoodBowl] = [first, second, third]
	for cat in cats:
		cat.set_satiety(0.0)
		cat.satiety_loss_per_second = 0.0
	for bowl in bowls:
		control.set_tool(control.FOOD)
		for click in 4:
			check(control.activate_target(bowl), "Unlimited free quarter refills succeed")
		check(bowl.fill_amount == 100.0, "Four clicks fill each bowl")
	for cat in cats:
		cat._prioritize_food()
	var claimed: int = 0
	var owners: Dictionary = {}
	for bowl in bowls:
		if is_instance_valid(bowl.reserved_by):
			claimed += 1
			owners[bowl.reserved_by.get_instance_id()] = true
			check(bowl.reserved_food_remaining == 50.0, "A reservation claims half a bowl")
	check(claimed == 3 and owners.size() == 3, "Three distinct cats reserve three distinct bowls")
	for cat in cats:
		cat.set_physics_process(true)
	var all_fed: bool = false
	for frame in 1800:
		all_fed = true
		for cat in cats:
			if cat.satiety < 99.9:
				all_fed = false
		if all_fed:
			break
		await physics_frame
	check(all_fed, "Three full bowls must feed all six cats once")
	for cat in cats:
		freeze(cat)
	for bowl in bowls:
		check(is_zero_approx(bowl.fill_amount), "Six meals consume exactly three bowls")
	check(is_equal_approx(display.hunger_bar.value, 100.0), "All six full cats give room Food100")
	# Explicit one-meal check: even a starving cat consumes only half and becomes full.
	var cat = cats[0]
	cat.set_satiety(0.0)
	first.set_fill(100.0)
	check(first.reserve_meal(cat), "Cat claims meal")
	cat.food_bowl = first
	cat._meal_start_satiety = 0.0
	cat._meal_consumed_food = 0.0
	cat._meal_total_food = 50.0
	cat.global_position = cat._bowl_standing_spot(first)
	cat.behavior_state = cat.BehaviorState.EATING
	cat._update_feeding(5.0)
	check(cat.satiety == 100.0 and first.fill_amount == 50.0, "One cat eats half; other half remains")
	check(not is_instance_valid(first.reserved_by), "Completed meal releases reservation")
	# No waiting until zero: a cat at49 can reserve the remaining half.
	cats[1].set_satiety(49.0)
	cats[1]._prioritize_food()
	check(cats[1].food_bowl == first, "Hungry cat uses available food before zero")
	cats[1]._release_food_reservation()
	cats[1].food_bowl = null
	# Persistence restores six cats and three bowl states with no offline advancement.
	for index in 6:
		freeze(cats[index])
		cats[index].set_satiety(100.0 - index * 5.0)
	first.set_fill(100.0)
	second.set_fill(50.0)
	third.set_fill(0.0)
	var box: LitterBox = manager.room_nodes(&"litter_boxes")[0]
	box.set_cleanliness(75.0)
	manager.save_path = "/workspace/.godot-environment/room-food-test-save.json"
	manager.persistence_enabled = true
	check(manager.save_game(), "Save must succeed")
	manager.persistence_enabled = false
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame
	check(manager.load_game(float(JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))["saved_at_seconds"])), "Saved food room must load")
	var restored = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(restored)
	current_scene = restored
	for restored_cat in manager.room_nodes(&"cats"):
		freeze(restored_cat)
	for restored_box in manager.room_nodes(&"litter_boxes"):
		restored_box.set_process(false)
	await process_frame
	check(manager.room_nodes(&"cats").size() == 6, "All six cats must restore")
	check(manager.room_nodes(&"food_bowls").size() == 3, "All three bowls restore")
	check(is_equal_approx(manager.room_food, 87.5), "Zero elapsed time preserves room satiety")
	var total_food: float = 0.0
	for bowl in manager.room_nodes(&"food_bowls"):
		total_food += bowl.fill_amount
	check(total_food == 150.0, "Evening food stock survives reload unchanged")
	check(manager.room_cleanliness == 75.0, "Zero elapsed time preserves cleanliness")
	print("ROOM_FOOD_OK" if failures.is_empty() else "ROOM_FOOD_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
