extends Control
class_name ActionPanel

signal tool_selected(tool: int)
enum Tool { POINTER, FOOD, SCOOP }

const PANEL_TEXTURE: Texture2D = preload("res://assets/UI/hud/action_panel/action_panel.png")
var active_tool: int = Tool.POINTER
var _mask: Image
@onready var message_label: Label = $Message
@onready var message_timer: Timer = $MessageTimer

func _ready() -> void:
	_mask = PANEL_TEXTURE.get_image()
	message_timer.timeout.connect(func(): message_label.text = "")
	queue_redraw()

func _has_point(point: Vector2) -> bool:
	if size.x <= 0.0 or size.y <= 0.0 or not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	if _mask == null:
		_mask = PANEL_TEXTURE.get_image()
	var pixel := Vector2i(point / size * Vector2(_mask.get_size()))
	return _mask.get_pixelv(pixel).a > 0.1

func tool_at(point: Vector2) -> int:
	if not _has_point(point):
		return -1
	var p := point / size * Vector2(512, 512)
	if p.distance_to(Vector2(512, 512)) <= 284.0:
		return Tool.POINTER
	return Tool.FOOD if p.x < p.y else Tool.SCOOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := tool_at(event.position)
		tooltip_text = ["Maus: Auswählen und Streicheln", "Futtersack: Napf auffüllen", "Schaufel: Katzenklo reinigen"][hovered] if hovered >= 0 else ""
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var tool := tool_at(event.position)
		if tool >= 0:
			tool_selected.emit(tool)
			accept_event()

func set_active_tool(tool: int) -> void:
	active_tool = tool
	queue_redraw()

func show_message(text: String) -> void:
	message_label.text = text
	message_timer.start()

func _draw() -> void:
	var points := [Vector2(486, 478), Vector2(118, 441), Vector2(421, 120)]
	var point: Vector2 = points[active_tool] / 512.0 * size
	draw_circle(point, 4.0, Color(0.97, 0.92, 0.86))
	draw_arc(point, 4.0, 0.0, TAU, 24, Color(0.49, 0.29, 0.27), 1.0, true)
