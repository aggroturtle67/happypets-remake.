extends SceneTree

var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func until_state(cat, state: int, frames: int = 1500) -> bool:
	for index in frames:
		if cat.behavior_state == cat.BehaviorState.WALKING and is_instance_valid(cat.food_bowl):
			check(cat.movement_target.distance_to(cat._bowl_standing_spot(cat.food_bowl)) < 1.0,
				"Hungry cat must never take an unrelated wandering target")
		if cat.behavior_state == state:
			return true
		await physics_frame
	return false

func run() -> void:
	Engine.time_scale = 4.0
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var cat = get_first_node_in_group("cats")
	var bowl = get_first_node_in_group("food_bowls")
	var display = scene.find_child("NeedsDisplay", true, false)
	cat.satiety_loss_per_second = 0.0
	cat.wander_timer.stop()
	cat.behavior_state = cat.BehaviorState.IDLE
	cat.has_movement_target = false
	cat.global_position = Vector2(750, 850)
	bowl.set_fill(100.0)
	cat.set_satiety(45.0)
	# A hunger decision must preempt a random wander timeout in the same frame.
	cat._on_wander_timer_timeout()
	check(cat.food_bowl == bowl and cat.has_movement_target, "Hunger must take immediate priority")
	check(cat.wander_timer.is_stopped(), "No wandering timer may remain while going to food")
	await process_frame
	check(is_equal_approx(display.hunger_bar.value, 45.0), "HUD must display cat satiety")
	await physics_frame
	await physics_frame
	check(cat.food_bowl == bowl, "Hungry cat must choose filled bowl")
	check(is_equal_approx(bowl.fill_amount, 100.0), "Walking must not consume food")
	check(await until_state(cat, cat.BehaviorState.EATING), "Cat must reach bowl")
	check(cat.global_position.distance_to(cat._bowl_standing_spot(bowl)) < 10.0, "No remote feeding")
	check(await until_state(cat, cat.BehaviorState.IDLE), "Feeding must finish")
	check(is_equal_approx(cat.satiety, 100.0), "Full meal must restore satiety")
	check(is_equal_approx(bowl.fill_amount, 0.0), "The entire meal must be consumed")
	await process_frame
	check(is_equal_approx(display.hunger_bar.value, 100.0), "HUD must track feeding")
	# Empty bowls must not trap the cat; refill must trigger a new approach.
	bowl.set_fill(0.0)
	cat.set_satiety(20.0)
	await physics_frame
	await physics_frame
	check(cat.food_bowl == null, "Empty bowl must not be selected")
	bowl.set_fill(3.0)
	check(await until_state(cat, cat.BehaviorState.EATING), "Refill must be discovered")
	check(await until_state(cat, cat.BehaviorState.IDLE), "Emptying bowl must end feeding")
	check(is_equal_approx(cat.satiety, 21.8), "Partial meals provide proportionate satiety")
	check(is_zero_approx(bowl.fill_amount), "Bowl must empty exactly")
	check(not bowl.food_fill.visible, "Empty bowl must visibly hide the food layer")
	check(float(bowl.placed_item_data.state["fill"]) == 0.0, "Placed bowl state must also be empty")
	# A sitting cat must stand up before seeking food.
	cat.wander_timer.stop()
	cat.cat_visual.play_sit_idle()
	cat.behavior_state = cat.BehaviorState.SITTING
	bowl.set_fill(30.0)
	await physics_frame
	await physics_frame
	check(cat.behavior_state == cat.BehaviorState.STANDING_UP, "Sitting cat must use standing transition")
	cat._on_wander_timer_timeout()
	check(cat.behavior_state == cat.BehaviorState.STANDING_UP and cat.food_bowl == bowl,
		"Food target must survive the standing transition")
	check(await until_state(cat, cat.BehaviorState.EATING), "Sitting cat must eventually reach food")
	# Moving a bowl must pause consumption and trigger a fresh approach.
	var fill_before_move: float = bowl.fill_amount
	bowl.global_position += Vector2(180, 0)
	cat._update_feeding(0.1)
	check(cat.behavior_state == cat.BehaviorState.WALKING, "Moved bowl requires a new approach")
	check(is_equal_approx(bowl.fill_amount, fill_before_move), "No eating from a distance after moving bowl")
	check(await until_state(cat, cat.BehaviorState.EATING), "Cat must reach relocated bowl")
	# Pausing the game must pause hunger and consumption.
	paused = true
	var paused_satiety: float = cat.satiety
	var paused_fill: float = bowl.fill_amount
	await create_timer(0.05, true).timeout
	check(cat.satiety == paused_satiety and bowl.fill_amount == paused_fill, "Pause must freeze feeding")
	paused = false
	# A lying cat must also stand and go directly to the bowl.
	cat.behavior_state = cat.BehaviorState.LYING
	cat.has_movement_target = false
	cat.cat_visual.play_lie_idle()
	cat._update_feeding(0.01)
	check(cat.behavior_state == cat.BehaviorState.LYING_TO_STANDING, "Lying cat must stand for food")
	check(await until_state(cat, cat.BehaviorState.EATING), "Lying cat must reach food without wandering")
	# Removing a bowl while eating must exit safely.
	bowl.queue_free()
	await process_frame
	await physics_frame
	await physics_frame
	check(cat.behavior_state != cat.BehaviorState.EATING, "Deleted bowl must end feeding safely")
	cat.set_physics_process(false)
	cat.set_satiety(101.0)
	check(cat.satiety == 100.0, "Satiety upper clamp")
	cat.set_satiety(-5.0)
	check(cat.satiety == 0.0, "Satiety lower clamp")
	cat.satiety_loss_per_second = 50.0 / 600.0
	cat.seeking_food = false
	cat.set_satiety(100.0)
	cat._update_feeding(599.0)
	check(cat.satiety > 50.0 and not cat.seeking_food, "Full meal must last nearly ten minutes")
	cat._update_feeding(1.1)
	check(cat.satiety < 50.0 and cat.seeking_food, "Hunger must resume after about ten minutes")
	print("FEEDING_CHECK_OK" if failures.is_empty() else "FEEDING_CHECK_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)
