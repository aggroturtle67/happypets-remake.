extends VBoxContainer
class_name NeedsDisplay

@onready var hunger_bar: ProgressBar = $HungerRow/HungerBar
@onready var cleanliness_bar: ProgressBar = $CleanlinessRow/CleanlinessBar


func _ready() -> void:
	hunger_bar.step = 0.0
	cleanliness_bar.step = 0.0
	hunger_bar.tooltip_text = "Durchschnittliche Sättigung aller Katzen im Raum"
	$CleanlinessRow.tooltip_text = "Durchschnittliche Sauberkeit der Katzenklos im Raum"
	get_node("/root/RoomManager").room_food_changed.connect(set_hunger)
	get_node("/root/RoomManager").room_cleanliness_changed.connect(set_cleanliness)
	get_node("/root/RoomManager").refresh_room_needs()


func set_hunger(value: float) -> void:
	hunger_bar.value = clampf(value, hunger_bar.min_value, hunger_bar.max_value)


func set_cleanliness(value: float) -> void:
	cleanliness_bar.value = clampf(value, cleanliness_bar.min_value, cleanliness_bar.max_value)


func set_needs(hunger: float, cleanliness: float) -> void:
	set_hunger(hunger)
	set_cleanliness(cleanliness)
