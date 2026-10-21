extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager = root.get_node("RoomManager")
	var cat = manager.room_nodes(&"cats")[0]
	cat.set_physics_process(false)
	cat.set_satiety(88.0)
	var bowl = manager.room_nodes(&"food_bowls")[0]
	bowl.set_fill(100.0)
	manager.save_path = "/workspace/.godot-environment/window-close-food-save.json"
	manager.persistence_enabled = true
	manager.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
