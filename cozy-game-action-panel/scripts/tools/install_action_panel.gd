@tool
extends EditorScript

const MAIN_PATH := "res://scenes/main/main/main.tscn"
const PANEL_SCENE := preload("res://scenes/UI/hud/action_panel/action_panel.tscn")
const SHOP_SCENE := preload("res://scenes/UI/hud/components/shop_button.tscn")
const CONTROLLER_SCRIPT := preload("res://scripts/interactions/interaction_controller.gd")

# Adds only the new panel/controller. Existing ShopButton properties stay untouched.
static func configure_scene(scene: Node) -> void:
	var hud := scene.get_node("CanvasLayer/HUD") as Control
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not hud.has_node("ShopButton"):
		var shop := SHOP_SCENE.instantiate() as Control
		shop.name = "ShopButton"
		hud.add_child(shop)
		shop.owner = scene
		shop.set_anchor(SIDE_TOP, 1.0)
		shop.set_anchor(SIDE_BOTTOM, 1.0)
		shop.offset_left = 32.0
		shop.offset_top = -264.0
		shop.offset_right = 264.0
		shop.offset_bottom = -32.0
		shop.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var panel := hud.get_node_or_null("ActionPanel") as Control
	if panel == null:
		panel = PANEL_SCENE.instantiate() as Control
		panel.name = "ActionPanel"
		hud.add_child(panel)
		panel.owner = scene
	panel.set_anchor(SIDE_LEFT, 1.0)
	panel.set_anchor(SIDE_TOP, 1.0)
	panel.set_anchor(SIDE_RIGHT, 1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.offset_left = -320.0
	panel.offset_top = -320.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var controller := scene.get_node_or_null("InteractionController")
	if controller == null:
		controller = Node.new()
		controller.name = "InteractionController"
		controller.set_script(CONTROLLER_SCRIPT)
		scene.add_child(controller)
		controller.owner = scene

func _run() -> void:
	EditorInterface.save_all_scenes()
	var original_uid := ResourceLoader.get_resource_uid(MAIN_PATH)
	var packed := load(MAIN_PATH) as PackedScene
	if packed == null:
		push_error("Die Hauptszene wurde nicht gefunden: " + MAIN_PATH)
		return
	var scene := packed.instantiate()
	configure_scene(scene)
	var updated := PackedScene.new()
	var error := updated.pack(scene)
	if error == OK:
		error = ResourceSaver.save(updated, MAIN_PATH)
	if error == OK and original_uid != ResourceUID.INVALID_ID:
		error = ResourceSaver.set_uid(MAIN_PATH, original_uid)
	scene.free()
	if error != OK:
		push_error("Aktionspanel konnte nicht eingebaut werden. Fehler: " + str(error))
		return
	EditorInterface.reload_scene_from_path(MAIN_PATH)
	print("Aktionspanel eingebaut. Deine Shop-Position bleibt erhalten. Mit F5 starten.")
