extends Node
## Disposable F6 room. Normal saves and normal F5 startup remain untouched.
func _ready() -> void:
	var manager: Node = get_node("/root/RoomManager")
	manager.persistence_enabled = false
	manager.start_new_game_room()
	var game: Node = load("res://scenes/main/main/main.tscn").instantiate()
	add_child(game)
	var cat: Node2D = manager.room_nodes(&"cats")[0]
	cat.position = Vector2(650, 850)
	cat.set_satiety(0.0)
	cat.set_affection(0.0)
	cat.wander_timer.stop()
	cat.has_movement_target = false
	cat.behavior_state = cat.BehaviorState.IDLE
	cat.velocity = Vector2.ZERO
	cat.cat_visual.play_idle()
	game.get_node("InteractionController").activate_target(cat)
