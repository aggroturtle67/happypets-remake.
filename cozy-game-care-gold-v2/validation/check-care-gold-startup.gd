extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manager = root.get_node("RoomManager")
	var game = root.get_node("GameManager")
	assert(manager.has_loaded_save)
	assert(absf(game.export_progress().total_xp-8.0)<0.00001)
	assert(absf(game.coins-127.8)<0.00001)
	assert(game.level==1 and absf(game.current_xp-8.0)<0.00001)
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var display = scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/LeftSlot/LevelDisplay")
	await process_frame
	assert(absf(display.xp_bar.value-40.0)<0.001)
	var coins = scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/CenterSlot/CoinDisplay/CoinAmount")
	assert(coins.text=="127,80")
	print("REAL_STARTUP_OFFLINE_GOLD_LEGACY_BALANCE_AND_INITIAL_HUD_OK")
	manager.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
