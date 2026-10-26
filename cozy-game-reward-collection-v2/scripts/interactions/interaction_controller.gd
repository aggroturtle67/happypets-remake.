extends Node
class_name InteractionController

signal tool_changed(tool: int)
signal action_succeeded(tool: int, target: Node2D)
signal target_selected(target: Node2D)
signal cat_petted(cat: Node2D)

const CAT_PANEL_SCENE = preload("res://scenes/UI/hud/cat_panel/cat_needs_panel.tscn")
const REWARD_PRESENTER = preload("res://scenes/UI/rewards/reward_presenter.tscn")

const POINTER := ActionPanel.Tool.POINTER
const FOOD := ActionPanel.Tool.FOOD
const SCOOP := ActionPanel.Tool.SCOOP
const CURSOR_SOURCES: Array[Texture2D] = [
	preload("res://assets/UI/cursors/pointer.png"),
	preload("res://assets/UI/cursors/food_bag.png"),
	preload("res://assets/UI/cursors/scoop.png")
]

var cat_panel: Control
var _pointer_held: bool = false
var _petting_cat: Node2D
var _pet_contact_point: Vector2

var _cleaning_box: LitterBox
var _filling_bowl: FoodBowl
var current_tool: int = POINTER
var selected_target: Node2D
var _cursors: Array[Texture2D] = []
var _hotspots: Array[Vector2] = []
var _hit_images: Dictionary = {}
@onready var room: Node2D = $"../MainRoom"
@onready var panel: ActionPanel = $"../CanvasLayer/HUD/ActionPanel"

func _ready() -> void:
	cat_panel = CAT_PANEL_SCENE.instantiate()
	$"../CanvasLayer/HUD".add_child(cat_panel)
	if $"../CanvasLayer/HUD".get_node_or_null("CareRewardPresenter") == null:
		$"../CanvasLayer/HUD".add_child(REWARD_PRESENTER.instantiate())
	_prepare_cursors()
	panel.tool_selected.connect(set_tool)
	set_tool(POINTER)

func _prepare_cursors() -> void:
	for index in range(CURSOR_SOURCES.size()):
		var image := CURSOR_SOURCES[index].get_image()
		image = image.get_region(image.get_used_rect())
		var cursor_size := 48.0 if index == POINTER else (96.0 if index == SCOOP else 80.0)
		var factor := cursor_size / maxf(image.get_width(), image.get_height())
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
	_stop_petting()
	_pointer_held = false
	if tool != POINTER and is_instance_valid(cat_panel):
		cat_panel.call("clear_selection")
	if tool != FOOD:
		_release_filling_bowl()
	if tool != SCOOP:
		_release_cleaning_box()
	current_tool = tool
	panel.set_active_tool(tool)
	if DisplayServer.get_name() != "headless":
		for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]:
			Input.set_custom_mouse_cursor(_cursors[tool], shape, _hotspots[tool])
	tool_changed.emit(tool)

func _exit_tree() -> void:
	_stop_petting()
	_release_cleaning_box()
	_release_filling_bowl()
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		set_tool(POINTER)
		cat_panel.call("clear_selection")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_position: Vector2 = room.get_canvas_transform().affine_inverse() * event.position
		var target := target_at(world_position)
		activate_target(target)
		_pointer_held = current_tool == POINTER and target != null and _is_cat(target)
		if current_tool != POINTER or target != null:
			get_viewport().set_input_as_handled()

func activate_target(target: Node2D) -> bool:
	if current_tool == FOOD:
		if not target is FoodBowl:
			panel.show_message("Bitte den Napf anklicken.")
			return false
		if target.fill_amount >= 100.0:
			panel.show_message("Der Napf ist bereits voll.")
			return false
		if _filling_bowl != target:
			_release_filling_bowl()
			_filling_bowl = target
		target.is_being_filled = true
		target.set_fill(minf(target.fill_amount + 25.0, 100.0))
		if target.fill_amount >= 100.0:
			_complete(FOOD, target, "Napf voll – 100 %")
		else:
			action_succeeded.emit(FOOD, target)
			panel.show_message("Napf: %d %%" % roundi(target.fill_amount))
		get_node("/root/RoomManager").save_game()
		return true
	if current_tool == SCOOP:
		if not target is LitterBox:
			panel.show_message("Bitte das Katzenklo anklicken.")
			return false
		if target.cleanliness_amount >= 100.0:
			panel.show_message("Das Katzenklo ist bereits sauber.")
			return false
		if _cleaning_box != target:
			_release_cleaning_box()
			_cleaning_box = target
		target.is_being_cleaned = true
		var cleanliness_before: float = target.cleanliness_amount
		target.set_cleanliness(minf(target.cleanliness_amount + 25.0, 100.0))
		get_node("/root/GameManager").call("award_care", maxf(0.0, target.cleanliness_amount - cleanliness_before), &"clean", target)
		if target.cleanliness_amount >= 100.0:
			_complete(SCOOP, target, "Katzenklo sauber – 100 %")
		else:
			action_succeeded.emit(SCOOP, target)
			panel.show_message("Katzenklo: %d %% sauber" % roundi(target.cleanliness_amount))
		get_node("/root/RoomManager").save_game()
		return true
	if target == null:
		_stop_petting()
		selected_target = null
		cat_panel.call("clear_selection")
		return false
	if selected_target != target:
		_stop_petting()
	selected_target = target
	target_selected.emit(target)
	if _is_cat(target):
		target.set_meta("pet_count", int(target.get_meta("pet_count", 0)) + 1)
		cat_panel.call("select_cat", target)
		panel.show_message("")
	else:
		cat_panel.call("clear_selection")
		panel.show_message("Futternapf ausgewählt" if target is FoodBowl else "Katzenklo ausgewählt" if target is LitterBox else str(target.name))
	return true

func _release_cleaning_box() -> void:
	if is_instance_valid(_cleaning_box):
		_cleaning_box.is_being_cleaned = false
	_cleaning_box = null

func _release_filling_bowl() -> void:
	if is_instance_valid(_filling_bowl):
		_filling_bowl.is_being_filled = false
	_filling_bowl = null

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


func _input(event: InputEvent) -> void:
	# Releases over UI must end a stroke as reliably as releases over the room.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_pointer_held = false
		_stop_petting()
	elif event is InputEventMouseMotion and _pointer_held and current_tool == POINTER:
		var world: Vector2 = room.get_canvas_transform().affine_inverse() * event.position
		_update_pet_contact(true, world, get_viewport().gui_get_hovered_control() != null)
		if is_instance_valid(_petting_cat):
			var was_moving: bool = _petting_cat.call("has_pet_motion")
			_petting_cat.call("add_pet_motion", event.relative.length())
			if not was_moving and _petting_cat.call("has_pet_motion"):
				cat_petted.emit(_petting_cat)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_pointer_held = false
		_stop_petting()


func _process(_delta: float) -> void:
	var over_ui: bool = get_viewport().gui_get_hovered_control() != null
	_update_pet_contact(_pointer_held and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), room.get_global_mouse_position(), over_ui)


func _update_pet_contact(held: bool, world_position: Vector2, over_ui: bool) -> void:
	if not held or over_ui or current_tool != POINTER or not is_instance_valid(selected_target) or not _is_cat(selected_target):
		_stop_petting()
		return
	var on_cat: bool = target_at(world_position) == selected_target
	# A switch from walking to idle can move the silhouette beneath a stationary
	# pointer. A small contact margin keeps that change from interrupting a stroke.
	if not on_cat and not (_petting_cat == selected_target and world_position.distance_to(_pet_contact_point) <= 24.0):
		_stop_petting()
		return
	if on_cat:
		_pet_contact_point = world_position
	if _petting_cat != selected_target:
		_stop_petting()
		_petting_cat = selected_target
		_petting_cat.call("set_petting", true)


func _stop_petting() -> void:
	if is_instance_valid(_petting_cat):
		_petting_cat.call("set_petting", false)
		if is_inside_tree():
			get_node("/root/RoomManager").save_game()
	_petting_cat = null
