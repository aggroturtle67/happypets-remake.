extends VBoxContainer
class_name NeedsDisplay

@onready var hunger_bar: ProgressBar = $HungerRow/HungerBar
@onready var cleanliness_bar: ProgressBar = $CleanlinessRow/CleanlinessBar


var observed_cat: CharacterBody2D
var observed_litter_box: LitterBox

func _ready() -> void:
	hunger_bar.tooltip_text = "Sättigung: 100 = satt, 0 = hungrig"
	$CleanlinessRow.tooltip_text = "Sauberkeit des Katzenklos: 100 = sauber, 0 = voll"
	set_hunger(0.0)
	set_cleanliness(0.0)


func set_hunger(value: float) -> void:
	hunger_bar.value = clampf(value, hunger_bar.min_value, hunger_bar.max_value)


func set_cleanliness(value: float) -> void:
	cleanliness_bar.value = clampf(
		value,
		cleanliness_bar.min_value,
		cleanliness_bar.max_value
	)


func set_needs(hunger: float, cleanliness: float) -> void:
	set_hunger(hunger)
	set_cleanliness(cleanliness)


func _process(_delta: float) -> void:
	if not is_instance_valid(observed_cat):
		var cat := get_tree().get_first_node_in_group(&"cats") as CharacterBody2D
		if cat != null and cat.has_signal("satiety_changed"):
			observed_cat = cat
			observed_cat.connect("satiety_changed", set_hunger)
			set_hunger(float(observed_cat.get("satiety")))
		else:
			set_hunger(0.0)

	if not is_instance_valid(observed_litter_box):
		var box := get_tree().get_first_node_in_group(&"litter_boxes") as LitterBox
		if box != null:
			observed_litter_box = box
			observed_litter_box.cleanliness_changed.connect(set_cleanliness)
			set_cleanliness(observed_litter_box.cleanliness_amount)
		else:
			set_cleanliness(0.0)
