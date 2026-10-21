extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func click_screen(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventMouseButton.new()
	release.position = point
	release.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(release)
	await process_frame
	await process_frame

func click_target(controller: InteractionController, target: Node2D) -> void:
	var sprites := target.find_children("*", "Sprite2D", true, false)
	sprites.append_array(target.find_children("*", "AnimatedSprite2D", true, false))
	for sprite in sprites:
		if not sprite.is_visible_in_tree():
			continue
		var texture: Texture2D
		if sprite is Sprite2D:
			texture = sprite.texture
		elif sprite is AnimatedSprite2D:
			texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if texture == null:
			continue
		for y in range(1, 20):
			for x in range(1, 20):
				var local := Vector2(x, y) / 20.0 * texture.get_size()
				if sprite.centered:
					local -= texture.get_size() * 0.5
				local += sprite.offset
				var world: Vector2 = sprite.to_global(local)
				if controller.target_at(world) == target:
					await click_screen(controller.room.get_canvas_transform() * world)
					return
	assert(false, "No visible clickable pixel on target " + str(target.name))

func run_checks() -> void:
	assert(change_scene_to_file("res://scenes/main/main/main.tscn") == OK)
	await process_frame
	await process_frame
	var controller: InteractionController = current_scene.get_node("InteractionController")
	var panel: ActionPanel = controller.panel
	var room := controller.room
	var camera: Camera2D = room.get_node("RoomCamera")
	camera.edge_scroll_enabled = false
	var cat: CharacterBody2D = room.get_node("FloorYSortLayer/Cat")
	cat.wander_timer.stop()
	cat.set_physics_process(false)
	cat.global_position = Vector2(1500, 850)
	var bowl: FoodBowl = room.placed_item_nodes["food_bowl_start"]
	var box: LitterBox = room.placed_item_nodes["litter_box_start"]
	assert(bowl != null and box != null)
	assert(controller.current_tool == controller.POINTER)
	assert(controller._cursors.size() == 3)
	for index in 3:
		var cursor := controller._cursors[index]
		assert(maxi(cursor.get_width(), cursor.get_height()) == [48, 80, 96][index])
	assert(bowl.fill_amount == 0.0 and not bowl.food_fill.visible)
	assert(not panel._has_point(Vector2(10, 10)))
	assert(panel.tool_at(Vector2(160, 365) / 512.0 * panel.size) == controller.FOOD)
	assert(panel.tool_at(Vector2(350, 170) / 512.0 * panel.size) == controller.SCOOP)
	assert(panel.tool_at(Vector2(410, 410) / 512.0 * panel.size) == controller.POINTER)
	var layouts: Array = []
	for screen in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(800, 600), Vector2i(2560, 1440)]:
		root.size = screen
		await process_frame
		await process_frame
		var rect := panel.get_global_rect()
		assert(rect.size.is_equal_approx(Vector2(320, 320)))
		assert(rect.end.is_equal_approx(root.get_visible_rect().size))
		layouts.append({"window": [screen.x, screen.y], "panel_end": [rect.end.x, rect.end.y]})
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	var origin := panel.get_global_rect().position
	await click_screen(origin + Vector2(160, 365) / 512.0 * panel.size)
	assert(controller.current_tool == controller.FOOD)
	var pets_before: int = cat.get_meta("pet_count", 0)
	await click_target(controller, cat)
	assert(controller.current_tool == controller.FOOD)
	assert(cat.get_meta("pet_count", 0) == pets_before)
	box.set_cleanliness(30)
	await click_target(controller, box)
	assert(box.cleanliness_amount == 30 and controller.current_tool == controller.FOOD)
	var textures := [bowl.low_texture, bowl.medium_texture, bowl.high_texture, bowl.full_texture]
	for step in range(1, 5):
		await click_target(controller, bowl)
		assert(bowl.fill_amount == step * 25.0 and bowl.placed_item_data.state["fill"] == step * 25.0)
		assert(bowl.food_fill.visible and bowl.food_fill.texture == textures[step - 1])
		assert(controller.current_tool == (controller.FOOD if step < 4 else controller.POINTER))
		assert(bowl.is_being_filled == (step < 4))
	assert(controller.current_tool == controller.POINTER)
	controller.set_tool(controller.FOOD)
	await click_target(controller, bowl)
	assert(controller.current_tool == controller.FOOD)
	await click_screen(origin + Vector2(350, 170) / 512.0 * panel.size)
	assert(controller.current_tool == controller.SCOOP)
	bowl.set_fill(20)
	await click_target(controller, bowl)
	assert(bowl.fill_amount == 20 and controller.current_tool == controller.SCOOP)
	await click_target(controller, box)
	assert(box.cleanliness_amount == 100 and box.placed_item_data.state["cleanliness"] == 100)
	assert(controller.current_tool == controller.POINTER)
	controller.set_tool(controller.SCOOP)
	await click_target(controller, box)
	assert(controller.current_tool == controller.SCOOP)
	await click_screen(Vector2(900, 800))
	assert(controller.current_tool == controller.SCOOP)
	await click_screen(origin + Vector2(410, 410) / 512.0 * panel.size)
	assert(controller.current_tool == controller.POINTER)
	await click_target(controller, cat)
	assert(cat.get_meta("pet_count", 0) == pets_before + 1)
	assert(controller.current_tool == controller.POINTER)
	await click_target(controller, bowl)
	assert(controller.selected_target == bowl and bowl.fill_amount == 20)
	var before := panel.get_global_transform_with_canvas().origin
	camera.position.x += 400
	await process_frame
	assert(panel.get_global_transform_with_canvas().origin.is_equal_approx(before))
	# Switching tool or pressing Escape releases a partial portion for the cat.
	bowl.set_fill(0)
	controller.set_tool(controller.FOOD)
	assert(controller.activate_target(bowl))
	assert(bowl.fill_amount == 25 and bowl.is_being_filled)
	cat.set_satiety(40)
	cat._update_feeding(0.1)
	assert(cat.food_bowl == null)
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	Input.parse_input_event(escape)
	await process_frame
	assert(controller.current_tool == controller.POINTER and not bowl.is_being_filled)
	assert(bowl.fill_amount == 25)
	cat._update_feeding(0.1)
	assert(cat.food_bowl == bowl)
	# Irregular leftovers clamp at 100; the fourth click never overfills.
	controller.set_tool(controller.FOOD)
	bowl.set_fill(80)
	assert(controller.activate_target(bowl))
	assert(bowl.fill_amount == 100 and controller.current_tool == controller.POINTER)
	bowl.set_fill(0)
	controller.set_tool(controller.FOOD)
	assert(controller.activate_target(bowl))
	controller.set_tool(controller.SCOOP)
	assert(not bowl.is_being_filled and bowl.fill_amount == 25)
	# Even an already eating cat waits during a refill, then resumes consumption.
	cat.food_bowl = bowl
	cat.behavior_state = cat.BehaviorState.EATING
	cat.global_position = cat._bowl_standing_spot(bowl)
	controller.set_tool(controller.FOOD)
	assert(controller.activate_target(bowl))
	var held_fill: float = bowl.fill_amount
	cat._update_feeding(1.0)
	assert(bowl.fill_amount == held_fill)
	controller.set_tool(controller.POINTER)
	cat._update_feeding(0.1)
	assert(bowl.fill_amount < held_fill)

	print("ACTION_PANEL_INTERACTIONS_OK ", JSON.stringify({"layouts": layouts, "four_click_fill": true, "empty_start": true, "all_fill_textures": true, "cursor_sizes_preserved": true, "refill_reservation": true, "cleaning": true, "wrong_targets_blocked": true, "full_targets_keep_tool": true, "petting_only_in_pointer_mode": true, "auto_reset": true, "camera_independent": true}))
	quit(0)
