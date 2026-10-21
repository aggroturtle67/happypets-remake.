extends VBoxContainer
class_name NeedsDisplay

@onready var hunger_bar: ProgressBar = $HungerRow/HungerBar
@onready var cleanliness_bar: ProgressBar = $CleanlinessRow/CleanlinessBar


var observed_cat: CharacterBody2D

func _ready() -> void:
	hunger_bar.tooltip_text = "Sättigung: 100 = satt, 0 = hungrig"
	$CleanlinessRow.tooltip_text = "Sauberkeit: folgt in einem späteren Schritt"
	set_hunger(0.0)
	set_cleanliness(80.0)


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
	if is_instance_valid(observed_cat):
		return
	var cat := get_tree().get_first_node_in_group(&"cats") as CharacterBody2D
	if cat == null or not cat.has_signal("satiety_changed"):
		return
	observed_cat = cat
	observed_cat.connect("satiety_changed", set_hunger)
	set_hunger(float(observed_cat.get("satiety")))
