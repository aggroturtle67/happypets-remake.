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
	var bar = scene.get_node("CanvasLayer/HUD/TopBar2")
	var row = bar.get_node("Background/SafeMargin/MainRow")
	var level = row.get_node("LeftSlot/LevelDisplay")
	var coins = row.get_node("CenterSlot/CoinDisplay/CoinAmount")
	var needs = row.get_node("RightSlot/RightGroup/NeedsDisplay")
	var pause = row.get_node("RightSlot/RightGroup/PauseButton")
	check(bar.get_node("Background").color.is_equal_approx(Color("d9bcba")), "Opaque rose background preserved")
	check(needs.get_node("HungerRow/Icon").texture != null and needs.get_node("CleanlinessRow/Icon").texture != null, "Existing drawn icons load")
	check(needs.get_node("HungerRow/HungerLabel").get_theme_color("font_color").r < 0.4, "Warm dark text inherits theme")
	root.get_node("GameManager").coins_changed.emit(12345)
	root.get_node("GameManager").level_changed.emit(7)
	root.get_node("GameManager").xp_changed.emit(40,100)
	await process_frame
	check(coins.text == "12345" and level.level_number.text == "7" and is_equal_approx(level.xp_bar.value,40.0), "Currency level and XP bindings remain functional")
	needs.set_hunger(72.25)
	needs.set_cleanliness(61.75)
	check(is_equal_approx(needs.hunger_bar.value,72.25) and is_equal_approx(needs.cleanliness_bar.value,61.75), "Need bars retain fractional display")
	pause.pressed.emit()
	check(paused,"Pause button pauses game")
	pause.pressed.emit()
	check(not paused,"Pause button resumes game")
	for viewport_size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(800,600),Vector2i(2560,1080)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		var left: Rect2 = row.get_node("LeftSlot/LevelDisplay").get_global_rect()
		var middle: Rect2 = row.get_node("CenterSlot/CoinDisplay").get_global_rect()
		var right: Rect2 = row.get_node("RightSlot/RightGroup").get_global_rect()
		check(left.end.x <= middle.position.x and middle.end.x <= right.position.x, "Topbar groups do not overlap at "+str(viewport_size))
		check(right.end.x <= bar.size.x and right.position.y >= 0.0 and right.end.y <= bar.size.y, "Right controls remain within topbar at "+str(viewport_size))
	print("TOPBAR_LAYOUT_AND_BINDINGS_OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
