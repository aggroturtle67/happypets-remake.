extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manager = root.get_node("RoomManager")
	var game = root.get_node("GameManager")
	assert(manager.has_loaded_save)
	assert(absf(game.export_progress().total_xp-8.0)<0.00001)
	assert(game.coins==129 and absf(game.export_progress().coin_pending-0.7)<0.00001)
	assert(game.level==1 and absf(game.current_xp-8.0)<0.00001)
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var display = scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/LeftSlot/LevelDisplay")
	await process_frame
	assert(absf(display.xp_bar.value-40.0)<0.001)
	var coins = scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/CenterSlot/CoinDisplay/CoinAmount")
	assert(coins.text=="129" and display.xp_bar.tooltip_text=="8 / 20 XP")
	print("REAL_STARTUP_NEW_FOOD_RATE_NO_DUPLICATE_OK")
	manager.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
