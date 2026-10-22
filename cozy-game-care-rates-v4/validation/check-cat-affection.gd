extends SceneTree
const Sim = preload("res://scripts/managers/offline_consumption.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func find_point(controller: Node, cat: Node2D) -> Vector2:
	for sprite in cat.find_children("*", "Sprite2D", true, false):
		if not sprite.is_visible_in_tree() or sprite.texture == null:
			continue
		for y in range(1,20):
			for x in range(1,20):
				var p = Vector2(x,y)/20.0*sprite.texture.get_size()
				if sprite.centered:
					p -= sprite.texture.get_size()*0.5
				p += sprite.offset
				var world: Vector2 = sprite.to_global(p)
				if controller.target_at(world) == cat:
					return world
	return Vector2(INF,INF)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manager = root.get_node("RoomManager")
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var cat = manager.room_nodes(&"cats")[0]
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	cat.position = Vector2(650,850)
	var controller = scene.get_node("InteractionController")
	controller.set_process(false)
	check(cat.affection == 100.0,"Fresh cat starts with full affection")
	cat._update_affection(36.0*3600.0)
	check(absf(cat.affection-45.0)<0.00001,"36 online hours:100 to45")
	cat.set_affection(0.0)
	check(not controller.cat_panel.visible,"Panel hidden before selection")
	controller.activate_target(cat)
	check(controller.cat_panel.visible and cat.affection == 0.0,"Click opens this cat, no instant affection reward")
	var point: Vector2 = find_point(controller,cat)
	check(point.is_finite(),"Found opaque cat pixel")
	controller._update_pet_contact(true,point,false)
	check(cat.is_being_petted,"Holding pointer over cat starts a stroke")
	cat._update_affection(10.0)
	check(cat.affection == 0.0,"Holding still gives no affection")
	for frame in 100:
		cat.add_pet_motion(25.0)
		cat._update_affection(0.1)
	check(absf(cat.affection - 50.0) < 0.0001,"Ten seconds of moving strokes earns fifty points")
	var after_motion: float = cat.affection
	cat._update_affection(1.0)
	check(cat.affection <= after_motion,"Stopping movement cannot keep rewarding a stationary hold")
	cat.add_pet_motion(1000000.0)
	cat._update_affection(0.05)
	check(cat.affection <= after_motion + 0.25,"Fast pointer movement cannot bypass the per-second limit")
	cat.set_petting(false)
	cat.set_affection(0.0)
	cat.set_petting(true)
	for frame in 60:
		cat.add_pet_motion(2.0)
		cat._update_affection(1.0/60.0)
	check(cat.affection > 3.5 and cat.affection < 5.0,"Gentle small mouse movements accumulate into strokes")
	controller._update_pet_contact(true,point,true)
	check(not cat.is_being_petted,"Hovering UI stops petting")
	controller._update_pet_contact(true,point,false)
	controller._update_pet_contact(true,Vector2(-10000,-10000),false)
	check(not cat.is_being_petted,"Leaving cat stops petting")
	controller._update_pet_contact(true,point,false)
	var release = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	controller._input(release)
	check(not cat.is_being_petted,"Mouse release ends stroke even over UI")
	controller._update_pet_contact(true,point,false)
	controller.set_tool(controller.FOOD)
	check(not cat.is_being_petted and not controller.cat_panel.visible,"Changing tool stops petting and hides cat UI")
	controller._update_pet_contact(true,point,false)
	check(not cat.is_being_petted,"Food tool cannot pet")
	controller.set_tool(controller.POINTER)
	controller.activate_target(cat)
	cat.set_satiety(90.0)
	cat.set_affection(30.0)
	var box = manager.room_nodes(&"litter_boxes")[0]
	box.set_process(false)
	box.set_cleanliness(60.0)
	check(absf(cat.get_satisfaction()-60.0)<0.0001,"Satisfaction is average of personal satiety affection and room cleanliness")
	controller.cat_panel.refresh()
	check(controller.cat_panel.get_node("Margin/Rows/Satisfaction/Bar").value == 60.0,"Selected cat panel displays computed satisfaction")
	var extra = scene.get_node("MainRoom").try_add_cat(Vector2(1200,850))
	extra.set_physics_process(false)
	extra.wander_timer.stop()
	extra.set_affection(75.0)
	controller.activate_target(extra)
	controller.cat_panel.refresh()
	check(controller.cat_panel.get_node("Margin/Rows/Affection/Bar").value == 75.0,"Panel switches to selected cat's own affection")
	check(cat.affection == 30.0,"Other cat affection remains independent")
	controller.cat_panel.get_node("Margin/Rows/Header/Close").pressed.emit()
	check(not controller.cat_panel.visible,"Close button works")
	# Pause stops online affection even when a stroke was active.
	cat.set_physics_process(true)
	cat.is_being_petted = true
	var before: float = cat.affection
	paused = true
	await process_frame
	await process_frame
	check(cat.affection == before,"Pause freezes affection gains and losses")
	paused = false
	cat.set_physics_process(false)
	cat.is_being_petted = false
	cat.set_affection(100.0)
	manager.save_path = "/workspace/.godot-environment/cat-affection-test-save.json"
	manager.persistence_enabled = true
	check(manager.save_game(),"Affection snapshot saves")
	manager.persistence_enabled = false
	var snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))
	check(snapshot.cats[0].affection == 100.0,"Saved record includes personal affection")
	check(manager.load_game(float(snapshot.saved_at_seconds)+36.0*3600.0),"Timed affection snapshot loads")
	check(absf(manager.saved_cat_states.cat_start.affection-45.0)<0.00001,"36 offline hours:100 to45")
	var whole = {"a":{"satiety":0.0,"affection":100.0,"meal":{},"position":[0,0]}}
	var split = whole.duplicate(true)
	Sim.advance(whole,[],129600.0)
	Sim.advance(split,[],64800.0)
	Sim.advance(split,[],64800.0)
	check(whole.a.affection == split.a.affection and absf(whole.a.affection-45.0)<0.00001,"Repeated opens do not change 36h decay")
	Sim.advance(whole,[],1.0e9)
	check(whole.a.affection == 0.0,"Long absence clamps affection at zero")
	# Legacy states have no affection: start at100 now, do not charge their age.
	for record in snapshot.cats:
		record.erase("affection")
		record.erase("affection_loss_per_second")
	manager._write_record(snapshot)
	manager.load_game(float(snapshot.saved_at_seconds)+200.0*3600.0)
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame
	scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	cat = manager.room_nodes(&"cats")[0]
	cat.set_physics_process(false)
	check(cat.affection == 100.0,"Old save migration grants initial affection without retroactive loss")
	controller = scene.get_node("InteractionController")
	controller.set_process(false)
	controller.activate_target(cat)
	cat.queue_free()
	await process_frame
	await process_frame
	check(not controller.cat_panel.visible,"Removing selected cat hides panel safely")
	print("CAT_AFFECTION_SELECTION_PETTING_OFFLINE_OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
