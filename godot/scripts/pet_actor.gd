class_name RoomPet
extends Control

signal clicked(pet_id: String)

const Rig = preload("res://scripts/cat_rig.gd")
const ACTIONS := ["idle", "walk", "run", "jump", "sit", "groom", "sleep", "eat", "drink", "litter"]
const DURATIONS := {"eat": 5.0, "drink": 4.0, "run": 3.0, "groom": 4.0, "jump": 1.2, "litter": 5.0, "sit": 4.0, "sleep": 8.0}
const IDLE_ACTIONS := ["sit", "groom", "sleep", "drink", "litter"]

var pet: Dictionary = {}
var selected := false
var body_texture: Texture2D
var rig: CatRig
var elapsed := 0.0
var bubble := ""
var bubble_time := 0.0
var foot := Vector2.ZERO
var target := Vector2.ZERO
var wander_time := 0.0
var room_size := Vector2(800, 500)
var editing := false
var current_animation := "sit"
var action_time := 0.0
var action_duration := 0.0
var facing_right := true
var pending_action := ""
var station_id := ""
var station_kind := ""
var is_cat := false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL

func configure(value: Dictionary, is_selected: bool, area: Vector2) -> void:
	pet = value
	selected = is_selected
	room_size = area
	is_cat = str(pet.get("art", "")) == "cat"
	if is_cat and rig == null:
		rig = Rig.new()
		rig.name = "CatRig"
		add_child(rig)
	elif not is_cat:
		body_texture = load("res://assets/" + str(pet.art) + ".svg")
	tooltip_text = str(pet.name) + " streicheln"
	_update_layout()

func _process(delta: float) -> void:
	if not editing:
		advance(delta)
	_update_layout()
	queue_redraw()

# Separate from rendering so complete journeys can be checked deterministically.
func advance(delta: float) -> void:
	elapsed += delta
	bubble_time = maxf(0.0, bubble_time - delta)
	wander_time -= delta
	if not station_id.is_empty():
		_update_station(delta)
	elif action_time > 0:
		action_time = maxf(0, action_time - delta)
		if current_animation == "run":
			_move_to_target(delta, 0.17)
			if foot.distance_to(target) <= 0.001:
				action_time = 0.0
		if action_time <= 0:
			_finish_action()
	elif foot.distance_to(target) > 0.001:
		_set_animation("walk")
		_move_to_target(delta, 0.075)
	else:
		_set_animation("sit")
		if wander_time <= 0:
			wander_time = randf_range(5, 10)
			if is_cat and randf() < 0.60:
				play_action(IDLE_ACTIONS.pick_random())
			else:
				target = Vector2(randf_range(0.15, 0.83), randf_range(0.68, 0.88))
	if rig != null:
		rig.facing_right = facing_right
		var progress := 1.0 - action_time / action_duration if action_duration > 0 else 0.0
		rig.update_pose(current_animation, elapsed, progress, delta)

func _update_layout() -> void:
	var width := room_size.x * (0.20 if is_cat else 0.135)
	size = Vector2(width, width * (0.80 if is_cat else 1.2) + 24)
	position = foot * room_size - Vector2(size.x * 0.5, size.y - 24)
	z_index = int(foot.y * 100)
	mouse_filter = MOUSE_FILTER_IGNORE if editing else MOUSE_FILTER_STOP
	if rig != null:
		rig.position = Vector2(size.x * 0.5, size.y - 24)
		rig.scale = Vector2.ONE * cat_scale()

func cat_scale() -> float:
	return room_size.x * 0.20 / 400.0

func _set_animation(value: String) -> void:
	if current_animation != value:
		current_animation = value
		elapsed = 0.0

func _move_to_target(delta: float, speed: float) -> void:
	if absf(target.x - foot.x) > 0.001:
		facing_right = target.x > foot.x
	foot = foot.move_toward(target, delta * speed)

func react(text: String) -> void:
	bubble = text
	bubble_time = 3.5

func play_action(action: String) -> void:
	if not is_cat:
		return
	var mapping := {"feed": "eat", "play": "run", "clean": "groom", "pet": "jump"}
	var animation: String = str(mapping.get(action, action))
	if not animation in ACTIONS:
		return
	station_id = ""
	station_kind = ""
	pending_action = ""
	action_time = 0.0
	if animation in ["eat", "drink", "litter"]:
		var room := get_parent()
		if room != null and room.has_method("find_station"):
			var station: Dictionary = room.find_station(self, animation)
			if not station.is_empty():
				station_id = str(station.id)
				station_kind = animation
				pending_action = animation
				_set_animation("walk")
				return
		_finish_action()
		return
	_start_action(animation)
	if animation == "run":
		target = Vector2(0.78 if foot.x < 0.5 else 0.22, clampf(foot.y, 0.68, 0.88))
	else:
		target = foot

func _start_action(animation: String) -> void:
	_set_animation(animation)
	elapsed = 0.0
	action_duration = float(DURATIONS.get(animation, 3.0))
	action_time = action_duration

func _finish_action() -> void:
	station_id = ""
	station_kind = ""
	pending_action = ""
	action_time = 0.0
	action_duration = 0.0
	target = foot
	wander_time = randf_range(3, 6)
	_set_animation("sit")

func _update_station(delta: float) -> void:
	var room := get_parent()
	var station: Dictionary = room.station_target(self, station_id, station_kind)
	if station.is_empty():
		_finish_action()
		return
	target = station.foot
	if foot.distance_to(target) > 0.001:
		pending_action = station_kind
		action_time = 0.0
		_set_animation("walk")
		_move_to_target(delta, 0.10)
		return
	foot = target
	facing_right = bool(station.facing_right)
	if not pending_action.is_empty():
		var next := pending_action
		pending_action = ""
		_start_action(next)
	else:
		action_time = maxf(0, action_time - delta)
		if action_time <= 0:
			_finish_action()

func _draw() -> void:
	if selected:
		var ring := PackedVector2Array()
		for i in range(41):
			var angle := float(i) / 40 * TAU
			ring.append(Vector2(size.x * 0.5 + cos(angle) * size.x * 0.40, size.y - 24 + sin(angle) * 6))
		draw_polyline(ring, Color("fff8dd"), 2.0, true)
	if not is_cat and body_texture != null:
		draw_texture_rect(body_texture, Rect2(0, sin(elapsed * 2.2), size.x, size.y - 24), false)
	var font := ThemeDB.fallback_font
	var name_text: String = str(pet.get("name", "")) + ("  ♥" if selected else "")
	var name_width := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var tag := Rect2((size.x - name_width - 16) * 0.5, size.y - 19, name_width + 16, 21)
	draw_style_box(_tag_style(), tag)
	draw_string(font, tag.position + Vector2(8, 15), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("6b6550"))
	if bubble_time > 0:
		var bubble_width := font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20
		var rect := Rect2((size.x - bubble_width) * 0.5, -28, bubble_width, 26)
		draw_style_box(_tag_style(), rect)
		draw_string(font, rect.position + Vector2(10, 18), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9f7957"))

func _tag_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff9e8")
	style.set_corner_radius_all(9)
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(str(pet.id))
		accept_event()
	if event.is_action_pressed("ui_accept"):
		clicked.emit(str(pet.id))
		accept_event()
