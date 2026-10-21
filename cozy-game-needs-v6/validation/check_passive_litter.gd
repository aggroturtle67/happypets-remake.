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
	var box: LitterBox = scene.get_node("MainRoom").placed_item_nodes["litter_box_start"]
	var control: InteractionController = scene.get_node("InteractionController")
	var cat = get_first_node_in_group("cats")
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	box.set_process(false)
	box._soiling_elapsed = 0.0
	check(box.cleanliness_amount == 0.0, "Klo starts fully dirty for requested test")
	box.set_cleanliness(100.0)
	check(not cat.has_signal("bladder_changed"), "Cat must have no toilet behavior")
	var textures := [box.clean_texture, box.light_texture, box.medium_texture, box.dirt_texture, box.full_texture]
	var timeline: Array[float] = [box.cleanliness_amount]
	box._process(179.0)
	check(box.cleanliness_amount == 100.0, "No dirtying before three minutes")
	box._process(1.0)
	check(box.cleanliness_amount == 75.0 and box.litter_state.texture == textures[1], "First timed dirt step")
	timeline.append(box.cleanliness_amount)
	for step in range(2, 5):
		box._process(180.0)
		check(box.cleanliness_amount == 100.0 - step * 25.0, "Each timed step subtracts 25")
		check(box.litter_state.texture == textures[step], "Timed step displays correct image")
		check(float(box.placed_item_data.state["cleanliness"]) == box.cleanliness_amount, "Placed state tracks timer")
		timeline.append(box.cleanliness_amount)
	box._process(9999.0)
	check(box.cleanliness_amount == 0.0, "Full Klo stays full")
	control.set_tool(control.SCOOP)
	for click in range(1, 5):
		check(control.activate_target(box), "Cleaning click succeeds")
		box._process(1800.0)
		if click < 4:
			check(box.is_being_cleaned and box.cleanliness_amount == click * 25.0, "Active cleaning blocks new dirt")
		else:
			# Fourth click releases the session, so process() may advance normally.
			check(control.current_tool == control.POINTER and not box.is_being_cleaned, "Clean Klo returns pointer")
	# Cleaning restarts the timer; no stale interval may immediately re-dirty.
	box.set_cleanliness(100.0)
	box._process(179.0)
	check(box.cleanliness_amount == 100.0, "Cleaning resets countdown")
	box._process(1.0)
	check(box.cleanliness_amount == 75.0, "Dirtying resumes after cleaning")
	# A manually stopped partial clean must release the countdown too.
	box.set_cleanliness(0.0)
	control.set_tool(control.SCOOP)
	control.activate_target(box)
	control.set_tool(control.POINTER)
	check(not box.is_being_cleaned, "Manual tool switch releases cleaning session")
	box._process(180.0)
	check(box.cleanliness_amount == 0.0, "Partial clean resumes timed dirtying")
	box.set_cleanliness(100.0)
	box.automatic_soiling = false
	box._process(720.0)
	check(box.cleanliness_amount == 100.0, "Automatic dirtying can be disabled")
	box.automatic_soiling = true
	box._process(540.0)
	check(box.cleanliness_amount == 25.0, "Long frame advances all elapsed stages")
	box.set_cleanliness(100.0)
	box.set_process(true)
	paused = true
	var before: float = box._soiling_elapsed
	await create_timer(0.05, true).timeout
	check(box._soiling_elapsed == before and box.cleanliness_amount == 100.0, "Pause freezes timer")
	paused = false
	box.set_process(false)
	print("PASSIVE_LITTER_OK " + JSON.stringify({"timeline": timeline, "four_click_cleaning": true, "pause": true, "no_cat_behavior": true}) if failures.is_empty() else "PASSIVE_LITTER_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
