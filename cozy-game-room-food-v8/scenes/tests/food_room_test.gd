extends Node

# Eigenständiger F6-Testraum. Keine Speicherung und kein Überschreiben des Spielstands.
func _ready() -> void:
	var manager := get_node("/root/RoomManager")
	manager.persistence_enabled = false
	manager.start_new_game_room()
	var game: Node = load("res://scenes/main/main/main.tscn").instantiate()
	add_child(game)
	var room: Node = game.get_node("MainRoom")
	for index in 5:
		room.try_add_cat(Vector2(550 + index * 210, 950))
	room.try_add_food_bowl(Vector2(900, 730))
	room.try_add_food_bowl(Vector2(1400, 750))
	manager.refresh_room_needs()
