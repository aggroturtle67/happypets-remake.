extends Node
## A separate, disposable room for testing the personal needs UI with F6.
func _ready() -> void:
	var manager: Node = get_node("/root/RoomManager")
	manager.persistence_enabled = false
	manager.start_new_game_room()
	var game: Node = load("res://scenes/main/main/main.tscn").instantiate()
	add_child(game)
	var room: Node = game.get_node("MainRoom")
	var first: Node2D = manager.room_nodes(&"cats")[0]
	first.position = Vector2(650, 850)
	first.set_satiety(75.0)
	first.seeking_food = false
	first.set_affection(45.0)
	var second: Node2D = room.try_add_cat(Vector2(1200, 850))
	second.set_satiety(90.0)
	second.seeking_food = false
	second.set_affection(75.0)
	# Keep the two demonstration cats in place so the UI is easy to try.
	# Only this disposable F6 scene does this; the normal F5 game keeps its AI.
	for cat in [first, second]:
		cat.wander_timer.stop()
		cat.has_movement_target = false
		cat.behavior_state = cat.BehaviorState.IDLE
		cat.velocity = Vector2.ZERO
		cat.cat_visual.play_idle()
	for box in manager.room_nodes(&"litter_boxes"):
		box.set_cleanliness(60.0)
	manager.refresh_room_needs()
	game.get_node("InteractionController").activate_target(first)
