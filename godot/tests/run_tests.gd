extends SceneTree

const State = preload("res://scripts/game_state.gd")
const MainScene = preload("res://main.tscn")
var passed := 0
var failed := 0
var now := float(Time.get_unix_time_from_datetime_string("2026-10-20T12:00:00"))

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		printerr("FAIL: ", description)

func _run() -> void:
	_test_care()
	_test_shop()
	_test_rewards_and_time()
	_test_save_validation()
	_test_file_persistence()
	await _test_scene()
	print("GODOT TEST RESULT: ", passed, " passed, ", failed, " failed")
	quit(1 if failed else 0)

func _test_care() -> void:
	var game := State.new(now)
	check(game.data.pets.size() == 2 and game.data.coins == 280 and game.validate_save(game.data), "new game is valid with two starter pets")
	var result := game.care("feed")
	check(result.ok and game.data.coins == 272 and game.data.pets[0].hunger == 97.0 and game.data.pets[1].hunger == 75.0, "feeding restores only the chosen pet and charges eight coins")
	check(not game.care("feed").ok and game.data.coins == 272, "full pets cannot consume duplicate feeding rewards")
	game.reset(now)
	check(game.care("play", "milo").ok and game.data.selected == "milo" and game.data.coins == 292 and game.data.pets[1].joy == 88.0, "playing selects the pet and awards coins and happiness")
	check(not game.care("play").ok and game.data.coins == 292, "playing rewards cannot be farmed while happy")
	game.reset(now)
	game.data.coins = 0
	check(not game.care("feed").ok and game.care("clean").ok and game.data.coins == 10, "care remains a route to coins when food cannot be afforded")
	check(not game.care("invalid").ok and not game.care("pet", "missing").ok, "invalid actions and pets are rejected")
	check(game.rename_pet("  Keks  ").ok and game.selected_pet().name == "Keks" and not game.rename_pet("   ").ok, "names are trimmed and empty names rejected")

func _test_shop() -> void:
	var game := State.new(now)
	check(not game.adopt("cloud").ok and game.data.pets.size() == 2, "rabbit adoption is locked before level two")
	check(game.adopt("peach").ok and game.data.pets.size() == 3 and game.data.coins == 160 and game.selected_pet().name == "Pfirsich", "adoption charges the listed price and selects the new companion")
	game.reset(now)
	game.data.xp = 100
	check(game.adopt("cloud").ok and game.selected_pet().species == "bunny", "rabbit adoption unlocks at level two")
	game.reset(now)
	game.data.coins = 0
	check(not game.adopt("peach").ok and not game.buy_decor("plant").ok, "shop prevents purchases without sufficient coins")
	game.data.coins = 10000
	for i in range(4):
		game.adopt("peach")
	check(game.data.pets.size() == 6 and not game.adopt("peach").ok, "room capacity is limited to six animals")
	game.reset(now)
	var decor := game.buy_decor("lamp")
	check(decor.ok and game.data.coins == 225 and game.data.furniture[-1].placed, "decoration purchase creates a placeable object")
	game.move_furniture(str(decor.id), -100, 200)
	check(game.data.furniture[-1].x == 8.0 and game.data.furniture[-1].y == 91.0, "furniture stays within room boundaries")
	game.move_furniture(str(decor.id), NAN, 70)
	check(game.data.furniture[-1].x == 8.0, "invalid dragging coordinates cannot corrupt a save")

func _test_rewards_and_time() -> void:
	var game := State.new(now)
	check(not game.claim_quest("feed").ok, "daily tasks cannot be claimed before completion")
	game.care("feed")
	check(game.claim_quest("feed").ok and game.data.coins == 302 and game.data.xp == 35 and not game.claim_quest("feed").ok, "quest rewards are awarded exactly once")
	check(game.claim_gift(now).ok and game.data.coins == 377 and not game.claim_gift(now + 1).ok, "daily gift is granted once per calendar date")
	game.advance_time(now + 86400)
	check(game.data.quests.claimed.is_empty() and game.data.quests.progress.feed == 0 and game.claim_gift(now + 86400).ok, "a new day resets tasks and allows the next gift")
	var short := State.new(now)
	short.advance_time(now + 60)
	check(is_equal_approx(short.data.pets[0].hunger, 61.7), "needs decay at the configured per-minute rate")
	var day := State.new(now)
	var week := State.new(now)
	day.advance_time(now + 86400)
	week.advance_time(now + 86400 * 7)
	check(day.data.pets[0].hunger == 0 and day.data.pets[0].joy == week.data.pets[0].joy and day.data.pets[0].clean == week.data.pets[0].clean, "offline decay is capped at eight hours and needs remain nonnegative")

func _test_save_validation() -> void:
	var game := State.new(now)
	check(game.validate_save(JSON.parse_string(JSON.stringify(game.data))), "JSON round-trip preserves a valid game")
	check(not game.validate_save(null) and not game.validate_save({}) and not game.validate_save(game.parse_json("{broken")), "missing and malformed data are rejected")
	var invalid: Dictionary = game.data.duplicate(true)
	invalid.coins = -1
	check(not game.validate_save(invalid), "negative currency in imported data is rejected")
	invalid = game.data.duplicate(true)
	invalid.selected = "missing"
	check(not game.validate_save(invalid), "save validation requires a valid selected pet")
	invalid = game.data.duplicate(true)
	invalid.pets[0].art = "../../secret"
	check(not game.validate_save(invalid), "art paths are restricted to bundled assets")
	invalid = game.data.duplicate(true)
	invalid.furniture[0].x = 1000
	check(not game.validate_save(invalid), "invalid furniture coordinates are rejected on import")

func _test_file_persistence() -> void:
	var path := "user://automated-test.json"
	for suffix in ["", ".backup", ".tmp", ".damaged"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var game := State.new()
	game.rename_pet("Dateitest")
	game.data.coins = 456
	check(game.save_game(path), "native save writes a real file")
	var loaded := State.new()
	check(loaded.load_game(path) and loaded.data.coins == 456 and loaded.selected_pet().name == "Dateitest", "native saves reload pets and currency")
	game.data.coins = 567
	check(game.save_game(path) and FileAccess.file_exists(path + ".backup"), "saving again keeps the previous file as a backup")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var recovered := State.new()
	check(recovered.load_game(path) and recovered.data.coins == 456 and FileAccess.file_exists(path + ".damaged"), "corrupted saves recover their backup and preserve damaged data")

func _find_button(node: Node, contains: String) -> Button:
	if node is Button and contains in node.text:
		return node
	for child in node.get_children():
		var found := _find_button(child, contains)
		if found != null:
			return found
	return null

func _test_scene() -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.game.reset()
	main._refresh()
	check(main.room.actors.size() == 2 and main.need_bars.hunger.value == 62, "main scene loads real pet actors and need displays")
	main.buttons.feed.pressed.emit()
	check(main.game.data.coins == 272 and main.need_bars.hunger.value == 97, "native Feed button updates game state and visible progress")
	check(main.room.actors["momo"].current_animation == "eat" and main.room.actors["momo"].action_time > 0, "feeding starts the cat bowl animation")
	main.room.pet_clicked.emit("milo")
	check(main.game.data.selected == "milo" and "Milo" in main.name_label.text and main.game.selected_pet().joy == 66, "room pet interaction selects and pets the animal")
	main.room.pet_clicked.emit("momo")
	check(main.room.actors["momo"].current_animation == "jump", "petting the cat starts its jump animation")
	main.show_shop("pets")
	await process_frame
	var adopt_button := _find_button(main.active_popup, "120")
	check(adopt_button != null and not adopt_button.disabled, "shop exposes an affordable adoption action")
	if adopt_button != null:
		adopt_button.pressed.emit()
	check(main.game.data.pets.size() == 3 and main.game.data.coins == 152 and main.room.actors.size() == 3, "native shop button adopts an animal and spawns its room actor")
	main.show_rename()
	var input: LineEdit = main.active_popup.find_child("PetName", true, false)
	input.text = "Flocke"
	_find_button(main.active_popup, "Namen speichern").pressed.emit()
	check(main.game.selected_pet().name == "Flocke" and "Flocke" in main.name_label.text, "native rename dialog saves its text field")
	main.buttons.edit.pressed.emit()
	await process_frame
	check(main.room.editing and main.editing_bar.visible, "edit mode exposes room decoration controls")
	main.room.selected_furniture = "plant-start"
	main._furniture_action("store")
	main.show_inventory()
	await process_frame
	var restore := _find_button(main.active_popup, "Aufstellen")
	check(restore != null, "stored furniture is visible in the inventory")
	if restore != null:
		restore.pressed.emit()
	var plant: Dictionary = main.game.data.furniture[2]
	check(plant.placed and main.room.selected_furniture == "plant-start", "inventory restores furniture without charging currency")
	main._persist()
	var restored := State.new()
	check(restored.load_game() and restored.data.pets.size() == 3 and restored.selected_pet().name == "Flocke", "interactions in the real scene survive a fresh game-state load")
	main._close_popup()
	main.queue_free()
	await process_frame
