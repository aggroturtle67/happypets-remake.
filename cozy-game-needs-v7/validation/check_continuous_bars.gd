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
	var cat = get_first_node_in_group("cats")
	var box: LitterBox = get_first_node_in_group("litter_boxes")
	var display: NeedsDisplay = scene.find_child("NeedsDisplay", true, false)
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	box.set_process(false)
	check(display.hunger_bar.step == 0.0 and display.cleanliness_bar.step == 0.0,
		"Bars must not round to whole percent values")
	box.set_cleanliness(100.0)
	cat.set_satiety(100.0)
	box._process(0.1)
	cat._update_feeding(0.1)
	check(display.cleanliness_bar.value < 100.0 and display.cleanliness_bar.value > 99.9,
		"Clean bar must decrease by a fractional value immediately")
	check(display.hunger_bar.value < 100.0 and display.hunger_bar.value > 99.9,
		"Food bar must decrease by a fractional value immediately")
	check(display.cleanliness_bar.value == box.cleanliness_amount and display.hunger_bar.value == cat.satiety,
		"Fractional bars must match actual game values")
	check(box.litter_state.texture == box.clean_texture, "Clean graphic stays during first quarter of decay")
	# Tiny deltas must not be discarded; elapsed time must determine the result.
	box.set_cleanliness(100.0)
	cat.set_satiety(100.0)
	for frame in 240:
		box._process(1.0 / 240.0)
		cat._update_feeding(1.0 / 240.0)
	check(is_equal_approx(box.cleanliness_amount, 100.0 - 25.0 / 180.0), "Clean drain must be independent of frame size")
	check(is_equal_approx(cat.satiety, 100.0 - 50.0 / 600.0), "Tiny hunger changes must accumulate")
	var values: Array[float] = [100.0, 75.0, 50.0, 25.0, 0.0]
	var textures := [box.clean_texture, box.light_texture, box.medium_texture, box.dirt_texture, box.full_texture]
	box.set_cleanliness(100.0)
	for state in range(1, 5):
		box._process(180.0)
		check(is_equal_approx(box.cleanliness_amount, values[state]), "Three minutes must drain 25 points")
		check(box.litter_state.texture == textures[state], "Five images change at the corresponding boundaries")
	check(display.cleanliness_bar.value == 0.0, "Klo and bar reach zero after twelve minutes")
	# Filling is intentionally discrete; only draining uses fractional updates.
	var bowl: FoodBowl = get_first_node_in_group("food_bowls")
	bowl.set_fill(100.0)
	cat.food_bowl = bowl
	cat.global_position = cat._bowl_standing_spot(bowl)
	cat.behavior_state = cat.BehaviorState.EATING
	cat.set_satiety(0.0)
	cat._update_feeding(1.0)
	check(display.hunger_bar.value == 0.0, "Food increase waits for the next quarter portion")
	cat._update_feeding(1.5)
	check(display.hunger_bar.value == 25.0, "First quarter raises Food to 25")
	for quarter in range(2, 5):
		cat._update_feeding(2.5)
		check(display.hunger_bar.value == quarter * 25.0, "Food fills only in 25-point steps")
	check(bowl.fill_amount == 0.0 and cat.satiety == 100.0, "Full meal ends at full satiety and empty bowl")
	cat._update_feeding(0.1)
	check(display.hunger_bar.value < 100.0 and display.hunger_bar.value > 99.9,
		"After filling in steps, Food resumes smooth fractional draining")

	print("CONTINUOUS_BARS_OK" if failures.is_empty() else "CONTINUOUS_BARS_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
