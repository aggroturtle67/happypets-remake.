extends SceneTree

const ACTIONS := ["walk", "run", "jump", "sit", "groom", "sleep", "eat", "drink", "litter"]

func _initialize() -> void:
	_capture.call_deferred()

func snapshot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _capture() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	for i in range(8):
		await process_frame
	main.game.reset()
	main._refresh()
	var cat: RoomPet = main.room.actors.momo
	cat.set_process(false)
	cat.play_action("feed")
	await snapshot("/tmp/cat-approach.png")
	for i in range(900):
		cat.advance(1.0 / 60.0)
		if cat.current_animation == "eat":
			break
	for i in range(45):
		cat.advance(1.0 / 60.0)
	cat._update_layout()
	await snapshot("/tmp/cat-eating.png")
	main.queue_free()
	await process_frame
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 1260)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Control.new()
	viewport.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("e8eee2")
	background.size = viewport.size
	stage.add_child(background)
	var rigs: Array = []
	var labels: Array = []
	for i in range(18):
		var label := Label.new()
		label.text = ACTIONS[i % 9] + (" →" if i < 9 else " ←")
		label.position = Vector2(i % 3 * 420 + 12, i / 3 * 210 + 5)
		label.add_theme_color_override("font_color", Color("334b40"))
		stage.add_child(label)
		labels.append(label)
		var rig := CatRig.new()
		rig.position = Vector2(i % 3 * 420 + 210, i / 3 * 210 + 185)
		rig.scale = Vector2.ONE * 0.53
		rig.facing_right = i < 9
		stage.add_child(rig)
		rigs.append(rig)
	for frame in range(24):
		for i in range(18):
			rigs[i].update_pose(ACTIONS[i % 9], float(frame) / 24.0, float(frame) / 24.0, 1.0)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/cat-poses-%02d.png" % frame)
	for frame in range(24):
		for i in range(18):
			var next: String = ACTIONS[(i + 1) % 9]
			labels[i].text = next + (" →" if i < 9 else " ←")
			rigs[i].update_pose(next, 1.0 + float(frame) / 24.0, float(frame) / 24.0, 1.0 / 24.0)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/cat-transitions-%02d.png" % frame)
	print("CAT RENDER CHECK: approach, eating and all nine poses in both directions captured")
	quit(0)
