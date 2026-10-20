class_name RoomPet
extends Control

signal clicked(pet_id: String)

var pet: Dictionary = {}
var selected := false
var body_texture: Texture2D
var locomotion_texture: Texture2D
var activity_texture: Texture2D
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
var facing_right := true
var idle_animation := "sit"

const ANIMATIONS := {
	"walk": {"sheet": "locomotion", "row": 0, "frames": 8, "fps": 8.0},
	"run": {"sheet": "locomotion", "row": 1, "frames": 8, "fps": 12.0},
	"jump": {"sheet": "locomotion", "row": 2, "frames": 8, "fps": 10.0},
	"sit": {"sheet": "activity", "row": 0, "frames": 6, "fps": 5.0},
	"groom": {"sheet": "activity", "row": 1, "frames": 8, "fps": 7.0},
	"sleep": {"sheet": "activity", "row": 2, "frames": 6, "fps": 2.0},
	"eat": {"sheet": "activity", "row": 3, "frames": 8, "fps": 6.0},
	"drink": {"sheet": "activity", "row": 4, "frames": 8, "fps": 7.0},
	"litter": {"sheet": "activity", "row": 5, "frames": 5, "fps": 4.0},
}

const IDLE_ANIMATIONS := ["sit", "groom", "sleep", "drink", "litter"]

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL

func configure(value: Dictionary, is_selected: bool, area: Vector2) -> void:
	pet = value
	selected = is_selected
	room_size = area
	body_texture = load("res://assets/" + str(pet.art) + ".svg")
	if str(pet.art) == "cat":
		locomotion_texture = load("res://assets/cat_locomotion.png")
		activity_texture = load("res://assets/cat_activities.png")
	tooltip_text = str(pet.name) + " streicheln"
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if str(pet.get("art", "")) == "cat":
		_update_cat_animation(delta)
	bubble_time = maxf(0.0, bubble_time - delta)
	wander_time -= delta
	if not editing and bubble_time <= 0 and action_time <= 0:
		if foot.distance_to(target) > 0.004:
			facing_right = target.x >= foot.x
			foot = foot.move_toward(target, delta * 0.035)
			current_animation = "walk"
		elif wander_time <= 0:
			wander_time = randf_range(4.0, 8.0)
			target = Vector2(randf_range(0.24, 0.78), randf_range(0.68, 0.88))
			idle_animation = IDLE_ANIMATIONS.pick_random()
		else:
			current_animation = idle_animation
	var width := room_size.x * (0.18 if str(pet.get("art", "")) == "cat" else 0.135)
	size = Vector2(width, width * 0.92 + 20)
	position = foot * room_size - Vector2(size.x / 2.0, size.y - 20.0)
	z_index = int(foot.y * 100.0)
	mouse_filter = MOUSE_FILTER_IGNORE if editing else MOUSE_FILTER_STOP
	queue_redraw()

func react(text: String) -> void:
	bubble = text
	bubble_time = 3.5

func play_action(action: String) -> void:
	if str(pet.get("art", "")) != "cat":
		return
	var mapping := {"feed": "eat", "play": "run", "clean": "groom", "pet": "jump"}
	current_animation = str(mapping.get(action, action))
	if not ANIMATIONS.has(current_animation):
		current_animation = "sit"
	action_time = {"eat": 4.0, "run": 3.0, "groom": 4.0, "jump": 1.6, "drink": 4.0, "litter": 5.0}.get(current_animation, 2.0)
	elapsed = 0.0

func _update_cat_animation(delta: float) -> void:
	if action_time > 0:
		action_time = maxf(0.0, action_time - delta)
		if action_time <= 0:
			current_animation = "sit"
			idle_animation = "sit"
			wander_time = 1.5

func _draw() -> void:
	if body_texture == null:
		return
	var bob := sin(elapsed * 2.2) * 1.0
	if selected:
		var ring: PackedVector2Array = []
		for i in range(41):
			var angle := float(i) / 40.0 * TAU
			ring.append(Vector2(size.x * 0.5 + cos(angle) * size.x * 0.40, size.y - 24 + sin(angle) * 6))
		draw_polyline(ring, Color("fff8dd"), 2.0, true)
	if str(pet.get("art", "")) == "cat" and locomotion_texture != null and activity_texture != null:
		_draw_animated_cat(bob)
	else:
		draw_texture_rect(body_texture, Rect2(0, bob, size.x, size.y - 20), false)
	var font := ThemeDB.fallback_font
	var name_text: String = str(pet.get("name", "")) + ("  ♥" if selected else "")
	var label_size := 12
	var name_width := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	var tag := Rect2((size.x - name_width - 16) / 2.0, size.y - 19, name_width + 16, 21)
	draw_style_box(_tag_style(), tag)
	draw_string(font, Vector2(tag.position.x + 8, tag.position.y + 15), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color("6b6550"))
	if bubble_time > 0:
		var bubble_width := font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20
		var rect := Rect2((size.x - bubble_width) / 2.0, -28, bubble_width, 26)
		draw_style_box(_tag_style(), rect)
		draw_string(font, rect.position + Vector2(10, 18), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9f7957"))

func _draw_animated_cat(bob: float) -> void:
	var spec: Dictionary = ANIMATIONS.get(current_animation, ANIMATIONS.sit)
	var texture: Texture2D = locomotion_texture if spec.sheet == "locomotion" else activity_texture
	var rows := 3 if spec.sheet == "locomotion" else 6
	var frames: int = int(spec.frames)
	var frame := int(elapsed * float(spec.fps)) % frames
	var cell_width := float(texture.get_width()) / 8.0
	var cell_height := float(texture.get_height()) / float(rows)
	var source := Rect2(frame * cell_width, int(spec.row) * cell_height, cell_width, cell_height)
	var destination := Rect2(0, bob, size.x, size.y - 20)
	if not facing_right:
		destination = Rect2(size.x, bob, -size.x, size.y - 20)
	draw_texture_rect_region(texture, destination, source)

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
