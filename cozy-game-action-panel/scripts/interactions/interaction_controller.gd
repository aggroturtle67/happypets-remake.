extends Node
class_name InteractionController

signal tool_changed(tool: int)
signal action_succeeded(tool: int, target: Node2D)
signal target_selected(target: Node2D)
signal cat_petted(cat: Node2D)

const POINTER := ActionPanel.Tool.POINTER
const FOOD := ActionPanel.Tool.FOOD
const SCOOP := ActionPanel.Tool.SCOOP
const CURSOR_SOURCES: Array[Texture2D] = [
	preload("res://assets/UI/cursors/pointer.png"),
	preload("res://assets/UI/cursors/food_bag.png"),
	preload("res://assets/UI/cursors/scoop.png")
]

var current_tool: int = POINTER
var selected_target: Node2D
var _cursors: Array[Texture2D] = []
var _hotspots: Array[Vector2] = []
var _hit_images: Dictionary = {}
@onready var room: Node2D = $"../MainRoom"
@onready var panel: ActionPanel = $"../CanvasLayer/HUD/ActionPanel"

func _ready() -> void:
	_prepare_cursors()
	panel.tool_selected.connect(set_tool)
	set_tool(POINTER)

func _prepare_cursors() -> void:
	for index in range(CURSOR_SOURCES.size()):
		var image := CURSOR_SOURCES[index].get_image()
		image = image.get_region(image.get_used_rect())
		var factor := 48.0 / maxf(image.get_width(), image.get_height())
		image.resize(maxi(1, roundi(image.get_width() * factor)), maxi(1, roundi(image.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
		_cursors.append(ImageTexture.create_from_image(image))
		var hotspot := Vector2(image.get_width() * 0.5, 1)
		if index == FOOD:
			hotspot.y = image.get_height() * 0.5
		elif index == SCOOP:
			hotspot.y = image.get_height() - 4
		_hotspots.append(hotspot)

func set_tool(tool: int) -> void:
	if tool < POINTER or tool > SCOOP:
		return
	current_tool = tool
	panel.set_active_tool(tool)
	if DisplayServer.get_name() != "headless":
		for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]:
			Input.set_custom_mouse_cursor(_cursors[tool], shape, _hotspots[tool])
	tool_changed.emit(tool)

func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		set_tool(POINTER)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_position: Vector2 = room.get_canvas_transform().affine_inverse() * event.position
		var target := target_at(world_position)
		if current_tool != POINTER or target != null:
			activate_target(target)
			get_viewport().set_input_as_handled()

func activate_target(target: Node2D) -> bool:
	if current_tool == FOOD:
		if not target is FoodBowl:
			panel.show_message("Bitte den Napf anklicken.")
			return false
		if target.fill_amount >= 100.0:
			panel.show_message("Der Napf ist bereits voll.")
			return false
		target.set_fill(100.0)
		_complete(FOOD, target, "Napf aufgefüllt")
		return true
	if current_tool == SCOOP:
		if not target is LitterBox:
			panel.show_message("Bitte das Katzenklo anklicken.")
			return false
		if target.cleanliness_amount >= 100.0:
			panel.show_message("Das Katzenklo ist bereits sauber.")
			return false
		target.set_cleanliness(100.0)
		_complete(SCOOP, target, "Katzenklo gereinigt")
		return true
	if target == null:
		return false
	selected_target = target
	target_selected.emit(target)
	if _is_cat(target):
		target.set_meta("pet_count", int(target.get_meta("pet_count", 0)) + 1)
		cat_petted.emit(target)
		panel.show_message("♥ Gestreichelt")
	else:
		panel.show_message("Futternapf ausgewählt" if target is FoodBowl else "Katzenklo ausgewählt" if target is LitterBox else str(target.name))
	return true

func _complete(tool: int, target: Node2D, message: String) -> void:
	action_succeeded.emit(tool, target)
	set_tool(POINTER)
	panel.show_message(message)

func _is_cat(target: Node2D) -> bool:
	return target is CharacterBody2D and target.has_node("VisualPivot/CatVisual")

func target_at(world_position: Vector2) -> Node2D:
	var candidates: Array[Node2D] = []
	for layer_name in ["FloorYSortLayer", "WallItemLayer", "OverlayLayer"]:
		var layer := room.get_node_or_null(layer_name)
		if layer != null:
			for child in layer.get_children():
				if child is Node2D and child.is_visible_in_tree():
					candidates.append(child)
	candidates.sort_custom(func(a: Node2D, b: Node2D): return a.global_position.y > b.global_position.y)
	for target in candidates:
		var sprites := target.find_children("*", "Sprite2D", true, false)
		sprites.append_array(target.find_children("*", "AnimatedSprite2D", true, false))
		for sprite in sprites:
			if sprite.is_visible_in_tree() and _sprite_hit(sprite, world_position):
				return target
	return null

func _sprite_hit(sprite: Node2D, world_position: Vector2) -> bool:
	if sprite is Sprite2D:
		return sprite.texture != null and sprite.is_pixel_opaque(sprite.to_local(world_position))
	if not sprite is AnimatedSprite2D or sprite.sprite_frames == null:
		return false
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return false
	var point: Vector2 = sprite.to_local(world_position) - sprite.offset
	if sprite.centered:
		point += texture.get_size() * 0.5
	if not Rect2(Vector2.ZERO, texture.get_size()).has_point(point):
		return false
	if sprite.flip_h:
		point.x = texture.get_width() - 1 - point.x
	if sprite.flip_v:
		point.y = texture.get_height() - 1 - point.y
	var key := texture.get_instance_id()
	if not _hit_images.has(key):
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		_hit_images[key] = image
	return (_hit_images[key] as Image).get_pixelv(Vector2i(point)).a > 0.1
