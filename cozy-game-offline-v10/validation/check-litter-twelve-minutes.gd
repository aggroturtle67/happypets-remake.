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
	var manager = root.get_node("RoomManager")
	var room = scene.get_node("MainRoom")
	var box = manager.room_nodes(&"litter_boxes")[0]
	box.set_process(false)
	var reference: Array[float] = []
	for count in [1, 6]:
		if count == 6:
			for index in 5:
				room.try_add_cat(Vector2(550 + index * 200, 950))
		for cat in manager.room_nodes(&"cats"):
			cat.set_physics_process(false)
			cat.wander_timer.stop()
		check(manager.room_nodes(&"cats").size() == count, "Use actual room cat count")
		box.set_cleanliness(100.0)
		box._process(0.1)
		check(box.cleanliness_amount < 100.0 and box.cleanliness_amount > 99.9, "Drain stays continuous")
		box._process(179.9)
		var values: Array[float] = [box.cleanliness_amount]
		check(is_equal_approx(box.cleanliness_amount, 75.0), "Three minutes reach75 for either cat count")
		for stage in range(2, 5):
			box._process(180.0)
			values.append(box.cleanliness_amount)
			check(is_equal_approx(box.cleanliness_amount, 100.0 - stage * 25.0), "Each three minutes drain25")
		check(box.cleanliness_amount == 0.0 and manager.room_cleanliness == 0.0,
			"Twelve minutes reach empty room Clean bar")
		if count == 1:
			reference = values
		else:
			check(values == reference, "Six cats must have identical twelve-minute timing")
	box.set_cleanliness(100.0)
	box.is_being_cleaned = true
	box._process(720.0)
	check(box.cleanliness_amount == 100.0, "Active cleaning still pauses soiling")
	box.is_being_cleaned = false
	box.set_process(true)
	paused = true
	await create_timer(0.05, true).timeout
	check(box.cleanliness_amount == 100.0, "Game pause still freezes soiling")
	paused = false
	box.set_process(false)
	print("LITTER_TWELVE_MINUTES_OK " + str(reference) if failures.is_empty() else "LITTER_TWELVE_MINUTES_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
