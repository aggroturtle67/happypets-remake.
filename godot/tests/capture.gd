extends SceneTree

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	for i in range(8):
		await process_frame
	main.game.reset()
	main._refresh()
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/pfotenstube-godot.png")
	var feed: Button = main.buttons.feed
	var point := feed.get_global_rect().get_center()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = point
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = point
	click.pressed = false
	Input.parse_input_event(click)
	await process_frame
	if main.game.data.coins != 272:
		printerr("Real pointer interaction failed: ", main.game.data.coins, " at ", point)
		quit(1)
		return
	main.show_shop("pets")
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/pfotenstube-godot-shop.png")
	print("NATIVE GUI CHECK PASSED: rendered room, mouse-click feeding, shop dialog")
	quit(0)
