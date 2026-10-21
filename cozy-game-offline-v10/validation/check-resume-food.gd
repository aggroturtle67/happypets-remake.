extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manager = root.get_node("RoomManager")
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var room = scene.get_node("MainRoom")
	var cat = manager.room_nodes(&"cats")[0]
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	cat.behavior_state = cat.BehaviorState.IDLE
	cat.has_movement_target = false
	cat.set_satiety(0.0)
	var bowl = manager.room_nodes(&"food_bowls")[0]
	bowl.set_fill(100.0)
	cat._prioritize_food()
	cat.global_position = cat._bowl_standing_spot(bowl)
	cat.stop_moving()
	cat._update_feeding(2.0)
	check(bowl.fill_amount == 80.0 and is_equal_approx(cat.satiety, 40.0), "Twenty food points give forty percent of one meal")
	check(bowl.reserved_food_remaining == 30.0, "Remaining half-meal reservation tracks consumption")
	# A second, non-default cat must also resume after all bowls are loaded.
	var extra = room.try_add_cat(Vector2(900, 850))
	extra.set_physics_process(false)
	extra.wander_timer.stop()
	var extra_id: String = extra.pet_id
	var other = room.try_add_food_bowl(Vector2(900, 730))
	other.set_fill(100.0)
	extra._prioritize_food()
	extra.global_position = extra._bowl_standing_spot(other)
	extra.stop_moving()
	extra._update_feeding(1.0)
	check(other.fill_amount == 90.0 and extra.satiety == 20.0, "Second cat has its own partial meal")
	manager.save_path = "/workspace/.godot-environment/resume-food-test-save.json"
	manager.persistence_enabled = true
	check(manager.save_game(), "Mid-meal snapshot saves")
	manager.persistence_enabled = false
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame
	check(manager.load_game(float(JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))["saved_at_seconds"])), "Mid-meal snapshot loads")
	var restored = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(restored)
	current_scene = restored
	cat = manager.room_nodes(&"cats")[0]
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	bowl = manager.room_nodes(&"food_bowls")[0]
	check(cat.satiety == 40.0 and bowl.fill_amount == 80.0, "Zero elapsed time preserves meal progress")
	for member in manager.room_nodes(&"cats"):
		member.set_physics_process(false)
		member.wander_timer.stop()
		if member.pet_id == extra_id:
			extra = member
	check(extra.satiety == 20.0, "Additional cat restores its private hunger")
	extra._try_resume_meal()
	other = extra.food_bowl
	check(other != null and other.reserved_food_remaining == 40.0, "Additional cat resumes only remaining portion")
	extra.global_position = extra._bowl_standing_spot(other)
	extra.stop_moving()
	extra._update_feeding(4.0)
	check(extra.satiety == 100.0 and other.fill_amount == 50.0, "Second resumed meal consumes only its own half")
	cat._try_resume_meal()
	check(bowl.reserved_food_remaining == 30.0 and bowl.reserved_by == cat, "Resume reserves only the remaining amount")
	cat.global_position = cat._bowl_standing_spot(bowl)
	cat.stop_moving()
	cat._update_feeding(3.0)
	check(cat.satiety == 100.0 and bowl.fill_amount == 50.0, "Resumed meal still consumes exactly half overall")
	# A refill during a meal adds stock, never enlarges the reserved meal.
	cat.set_satiety(0.0)
	cat.food_bowl = null
	bowl.set_fill(100.0)
	cat._prioritize_food()
	cat.global_position = cat._bowl_standing_spot(bowl)
	cat.stop_moving()
	cat._update_feeding(2.0)
	bowl.is_being_filled = true
	cat._update_feeding(10.0)
	check(bowl.fill_amount == 80.0 and cat.satiety == 40.0, "Refilling pauses active meal")
	bowl.set_fill(100.0)
	bowl.is_being_filled = false
	cat._update_feeding(3.0)
	check(cat.satiety == 100.0 and bowl.fill_amount == 70.0, "Refill does not reset or enlarge meal")
	# Deleting a cat must release its booked portion.
	cat.set_satiety(0.0)
	cat.food_bowl = null
	cat._prioritize_food()
	check(bowl.reserved_by == cat, "Reservation exists before removal")
	cat.queue_free()
	await process_frame
	await process_frame
	var replacement = restored.get_node("MainRoom").try_add_cat(Vector2(800, 850))
	replacement.set_physics_process(false)
	replacement.wander_timer.stop()
	check(bowl.reserve_meal(replacement), "Removed cat cannot leave a permanent reservation")
	print("RESUME_FOOD_OK" if failures.is_empty() else "RESUME_FOOD_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
