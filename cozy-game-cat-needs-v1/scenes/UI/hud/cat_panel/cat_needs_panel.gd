extends PanelContainer

var selected_cat: Node2D
@onready var title: Label = $Margin/Rows/Header/Title
@onready var hint: Label = $Margin/Rows/Hint

func _ready() -> void:
	$Margin/Rows/Header/Close.pressed.connect(clear_selection)
	hide()

func select_cat(cat: Node2D) -> void:
	selected_cat = cat
	var index: int = get_node("/root/RoomManager").room_nodes(&"cats").find(cat)
	title.text = str(cat.get_meta("display_name", "Katze %d" % (index + 1)))
	show()
	refresh()

func clear_selection() -> void:
	selected_cat = null
	hide()

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(selected_cat) or selected_cat.is_queued_for_deletion():
		clear_selection()
		return
	refresh()

func refresh() -> void:
	if not is_node_ready() or not is_instance_valid(selected_cat):
		return
	var manager: Node = get_node("/root/RoomManager")
	_set_value("Satiety", float(selected_cat.get("satiety")))
	_set_value("Affection", float(selected_cat.get("affection")))
	_set_value("Cleanliness", float(manager.get("room_cleanliness")))
	_set_value("Satisfaction", float(selected_cat.call("get_satisfaction")))
	hint.text = "Wird gestreichelt …" if selected_cat.get("is_being_petted") else "Zum Streicheln die Maustaste\nüber der Katze gedrückt halten."

func _set_value(row: String, value: float) -> void:
	var section: Node = $Margin/Rows.get_node(row)
	section.get_node("Bar").value = value
	section.get_node("Heading/Value").text = "%d %%" % roundi(value)
