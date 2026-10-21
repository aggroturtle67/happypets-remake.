extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var display: NeedsDisplay = scene.find_child("NeedsDisplay", true, false)
	var cat = get_first_node_in_group("cats")
	var box: LitterBox = get_first_node_in_group("litter_boxes")
	var controller: InteractionController = scene.get_node("InteractionController")
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	box.set_process(false)
	check(display.observed_litter_box == box, "HUD must bind actual room Klo")
	check(display.cleanliness_bar.value == 0.0 and display.hunger_bar.value == 0.0,
		"Test starts with both bars empty")
	check(box.cleanliness_amount == 0.0 and cat.satiety == 0.0, "Test states match bars")
	box.set_cleanliness(100.0)
	check(display.cleanliness_bar.value == 100.0, "Clean Klo must show full bar")
	var dirt_values: Array[float] = [display.cleanliness_bar.value]
	for step in 4:
		box._process(180.0)
		check(display.cleanliness_bar.value == box.cleanliness_amount, "Timer must immediately update bar via signal")
		dirt_values.append(display.cleanliness_bar.value)
	check(dirt_values == [100.0, 75.0, 50.0, 25.0, 0.0], "Bar follows all timed dirt stages")
	controller.set_tool(controller.SCOOP)
	var clean_values: Array[float] = []
	for step in range(1, 5):
		check(controller.activate_target(box), "Cleaning click succeeds")
		check(display.cleanliness_bar.value == step * 25.0, "Every cleaning click raises bar by 25")
		clean_values.append(display.cleanliness_bar.value)
	check(display.cleanliness_bar.value == 100.0, "Completely cleaned Klo must show full bar")
	cat.set_satiety(42.0)
	check(display.hunger_bar.value == 42.0, "Food bar still follows cat satiety")
	check(display.cleanliness_bar.value == 100.0, "Hunger must not change cleanliness")
	# Binding must recover when a room item disappears or is recreated.
	var item_parent: Node = box.get_parent()
	box.queue_free()
	await process_frame
	await process_frame
	check(display.cleanliness_bar.value == 0.0, "Missing Klo must not retain stale full value")
	var replacement: LitterBox = load("res://scenes/items/needs_item/hygiene/litter_box.tscn").instantiate()
	item_parent.add_child(replacement)
	replacement.set_process(false)
	replacement.set_cleanliness(25.0)
	await process_frame
	await process_frame
	check(display.observed_litter_box == replacement and display.cleanliness_bar.value == 25.0, "Recreated Klo must rebind")
	replacement.set_cleanliness(100.0)
	check(display.cleanliness_bar.value == 100.0, "Rebound Klo must update through signals")
	# Klo updates must work without a cat being present.
	cat.queue_free()
	await process_frame
	await process_frame
	replacement.set_cleanliness(50.0)
	check(display.cleanliness_bar.value == 50.0, "Klo bar works independently of cat")
	print("NEEDS_HUD_OK " + JSON.stringify({"dirt": dirt_values, "clean": clean_values, "satiety": true, "rebind": true, "independent_of_cat": true}) if failures.is_empty() else "NEEDS_HUD_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
