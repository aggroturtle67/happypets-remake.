class_name PetRoom
extends Control

signal pet_clicked(pet_id: String)
signal furniture_selected(item_id: String)
signal furniture_changed

const PetActor = preload("res://scripts/pet_actor.gd")
var game: PetGameState
var editing := false
var selected_furniture := ""
var actors: Dictionary = {}
var textures: Dictionary = {}
var backdrop: Texture2D = preload("res://assets/room.svg")
var dragging := false
var drag_offset := Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(refresh)
	for item in PetGameState.DECOR:
		textures[item.kind] = load("res://assets/" + str(item.kind) + ".svg")

func refresh() -> void:
	if game == null or not is_inside_tree():
		return
	var keep: Array = []
	for i in range(game.data.pets.size()):
		var pet: Dictionary = game.data.pets[i]
		keep.append(pet.id)
		if not actors.has(pet.id):
			var actor := PetActor.new()
			actor.foot = Vector2(0.43 + float(i % 3) * 0.17, 0.77 + float(i / 3) * 0.08 + float(i % 2) * 0.07)
			actor.target = actor.foot
			actor.wander_time = 6.5
			actor.clicked.connect(func(id: String): pet_clicked.emit(id))
			actors[pet.id] = actor
			add_child(actor)
		actors[pet.id].editing = editing
		actors[pet.id].configure(pet, pet.id == game.data.selected, size)
	for id in actors.keys():
		if not id in keep:
			actors[id].queue_free()
			actors.erase(id)
	queue_redraw()

func set_editing(value: bool) -> void:
	editing = value
	dragging = false
	if not value:
		selected_furniture = ""
	refresh()

func item_rect(item: Dictionary) -> Rect2:
	var widths := {"rug": 0.39, "bed": 0.19, "plant": 0.17, "scratch": 0.18, "bowl": 0.16, "cushion": 0.18, "lamp": 0.18, "toys": 0.14}
	var width := size.x * float(widths[item.kind])
	var texture: Texture2D = textures.get(item.kind)
	var height := width * float(texture.get_height()) / float(texture.get_width()) if texture else width
	if item.kind == "rug":
		height *= minf(1.0, size.y * 1.6129 / size.x)
	return Rect2(Vector2(float(item.x) / 100.0, float(item.y) / 100.0) * size - Vector2(width / 2.0, height), Vector2(width, height))

func _sorted_furniture() -> Array:
	var items: Array = []
	if game == null:
		return items
	for item in game.data.furniture:
		if item.placed:
			items.append(item)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.kind == "rug" and b.kind != "rug":
			return true
		if b.kind == "rug" and a.kind != "rug":
			return false
		return float(a.y) < float(b.y))
	return items

func _draw() -> void:
	draw_texture_rect(backdrop, Rect2(Vector2.ZERO, size), false)
	# Godot's SVG renderer omits patterns, so draw the wooden floor joints here.
	for row in range(6):
		var y := size.y * (0.525 + float(row) * 0.095)
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.64, 0.46, 0.26, 0.17), 1.0)
		for column in range(5):
			var x := size.x * (float(column) * 0.23 + (0.10 if row % 2 else 0.0))
			draw_line(Vector2(x, y), Vector2(x, minf(size.y, y + size.y * 0.095)), Color(0.64, 0.46, 0.26, 0.13), 1.0)
	if game == null:
		return
	if editing:
		for i in range(1, 17):
			var x := size.x * float(i) / 17.0
			draw_line(Vector2(x, size.y * 0.53), Vector2(x, size.y), Color(1, 1, 1, 0.3))
		for i in range(8):
			var y := size.y * (0.53 + float(i) * 0.065)
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.3))
	for item in _sorted_furniture():
		var rect := item_rect(item)
		var tex: Texture2D = textures.get(item.kind)
		if item.flipped:
			draw_texture_rect(tex, Rect2(rect.position + Vector2(rect.size.x, 0), Vector2(-rect.size.x, rect.size.y)), false)
		else:
			draw_texture_rect(tex, rect, false)
		if editing and item.id == selected_furniture:
			draw_rect(rect.grow(3), Color("fff4ce"), false, 2.0)
	var font := ThemeDB.fallback_font
	var message := "Möbel ziehen · Pfeiltasten: verschieben · R: drehen · Entf: einlagern" if editing else "Klicke ein Tier zum Streicheln."
	var width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2((size.x - width) / 2.0, size.y - 14), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("89785a"))

func _gui_input(event: InputEvent) -> void:
	if not editing or game == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus()
			var items := _sorted_furniture()
			items.reverse()
			for item in items:
				if item_rect(item).has_point(event.position):
					selected_furniture = str(item.id)
					dragging = true
					drag_offset = event.position / size * 100.0 - Vector2(item.x, item.y)
					furniture_selected.emit(selected_furniture)
					queue_redraw()
					accept_event()
					break
		else:
			if dragging:
				dragging = false
				furniture_changed.emit()
			accept_event()
	if event is InputEventMouseMotion and dragging:
		var point: Vector2 = event.position / size * 100.0 - drag_offset
		game.move_furniture(selected_furniture, point.x, point.y)
		queue_redraw()
		accept_event()
	if event is InputEventKey and event.pressed and not selected_furniture.is_empty():
		for item in game.data.furniture:
			if item.id != selected_furniture:
				continue
			var movement := Vector2.ZERO
			match event.keycode:
				KEY_LEFT: movement.x = -2
				KEY_RIGHT: movement.x = 2
				KEY_UP: movement.y = -2
				KEY_DOWN: movement.y = 2
				KEY_R: item.flipped = not item.flipped
				KEY_DELETE:
					item.placed = false
					selected_furniture = ""
				_: return
			game.move_furniture(str(item.id), float(item.x) + movement.x, float(item.y) + movement.y)
			furniture_changed.emit()
			queue_redraw()
			accept_event()

func _input(event: InputEvent) -> void:
	# Finish dragging even when the pointer is released outside the room.
	if dragging and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = false
		furniture_changed.emit()
