extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	Engine.time_scale = 4.0
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	var cat = scene.get_node("MainRoom/FloorYSortLayer/Cat")
	cat.starting_satiety = 49.0 # The current test start must override old inspector test values.
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var bowl: FoodBowl = get_first_node_in_group("food_bowls")
	var box: LitterBox = get_first_node_in_group("litter_boxes")
	var display: NeedsDisplay = scene.find_child("NeedsDisplay", true, false)
	var controller: InteractionController = scene.get_node("InteractionController")
	check(cat.satiety == 0.0 and bowl.fill_amount == 0.0 and box.cleanliness_amount == 0.0,
		"Cat, bowl and Klo must all start at zero")
	check(display.hunger_bar.value == 0.0 and display.cleanliness_bar.value == 0.0,
		"Both bars must start empty")
	check(not bowl.food_fill.visible and box.litter_state.texture == box.full_texture,
		"Test graphics must show empty bowl and dirty Klo")
	controller.set_tool(controller.FOOD)
	for click in 4:
		check(controller.activate_target(bowl), "Food click succeeds")
		check(display.hunger_bar.value == 0.0, "Refilling alone must not satisfy cat")
	check(bowl.fill_amount == 100.0 and controller.current_tool == controller.POINTER,
		"Fourth click fills bowl and returns pointer")
	controller.set_tool(controller.SCOOP)
	for click in range(1, 5):
		check(controller.activate_target(box), "Cleaning click succeeds")
		check(display.cleanliness_bar.value == click * 25.0, "Cleaning raises actual Clean bar")
	var reached: bool = false
	var finished: bool = false
	for frame in 1800:
		if cat.behavior_state == cat.BehaviorState.EATING:
			reached = true
		if reached and bowl.fill_amount == 0.0:
			finished = true
			break
		await physics_frame
	check(reached and finished, "Starving cat must walk to bowl and finish full meal")
	check(cat.satiety >= 99.9 and display.hunger_bar.value >= 99.9,
		"One full meal must fill the Food bar from zero to 100")
	check(display.cleanliness_bar.value > 95.0 and display.cleanliness_bar.value == box.cleanliness_amount and box.litter_state.texture == box.clean_texture,
		"Clean Klo remains full bar")
	check(not bowl.food_fill.visible and bowl.fill_amount == 0.0,
		"Finished meal leaves empty bowl")
	check(not cat.has_signal("bladder_changed"), "No cat toilet connection")
	print("ZERO_START_LOOP_OK" if failures.is_empty() else "ZERO_START_LOOP_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
