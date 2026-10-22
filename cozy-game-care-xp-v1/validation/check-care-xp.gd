extends SceneTree
const Rewards = preload("res://scripts/managers/care_rewards.gd")
const Sim = preload("res://scripts/managers/offline_consumption.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func near(a: float, b: float) -> bool:
	return absf(a-b) < 0.00001
func xp(game: Node) -> float:
	return float(game.export_progress().total_xp)
func reset(game: Node) -> void:
	game.restore_progress({})
func freeze(cat: Node) -> void:
	cat.set_physics_process(false)
	cat.wander_timer.stop()
func begin_meal(cat: Node, bowl: Node, satiety: float) -> void:
	cat._release_food_reservation()
	cat.food_bowl = null
	cat.set_satiety(satiety)
	cat._meal_consumed_food = 0.0
	cat._meal_total_food = 50.0
	cat._meal_start_satiety = satiety
	cat.food_bowl = bowl
	check(bowl.reserve_meal(cat),"Meal can reserve a half bowl")
	cat.global_position = cat._bowl_standing_spot(bowl)
	cat.behavior_state = cat.BehaviorState.EATING
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = root.get_node("GameManager")
	var manager = root.get_node("RoomManager")
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var cat = manager.room_nodes(&"cats")[0]
	freeze(cat)
	var bowl = manager.room_nodes(&"food_bowls")[0]
	var box = manager.room_nodes(&"litter_boxes")[0]
	box.set_process(false)
	var control = scene.get_node("InteractionController")
	control.set_process(false)
	reset(game)
	control.set_tool(control.FOOD)
	for i in 4:
		check(control.activate_target(bowl),"Refill succeeds")
	check(xp(game)==0.0,"Refilling is not a reward")
	control.activate_target(bowl)
	check(xp(game)==0.0,"Clicking an already full bowl gives no XP")
	begin_meal(cat,bowl,50.0)
	cat._update_feeding(5.0)
	check(near(xp(game),4.0),"50 restored satiety gives4XP")
	reset(game)
	bowl.set_fill(100.0)
	begin_meal(cat,bowl,0.0)
	for i in 300:
		cat._update_feeding(1.0/60.0)
	check(near(xp(game),8.0),"Frame-sized bites total8XP from zero satiety")
	check(near(bowl.fill_amount,50.0),"Reward does not change meal size")
	for i in 10:
		cat._finish_feeding()
	check(near(xp(game),8.0),"Repeated completion callbacks cannot duplicate food XP")
	reset(game)
	box.set_cleanliness(0.0)
	control.set_tool(control.SCOOP)
	for i in 4:
		check(control.activate_target(box),"Scoop click succeeds")
		check(near(xp(game),(i+1)*2.0),"Each actual25-point clean gives2XP")
	control.set_tool(control.SCOOP)
	for i in 100:
		control.activate_target(box)
	check(near(xp(game),8.0),"Spamming a clean toilet gives no additional XP")
	reset(game)
	box.set_cleanliness(90.0)
	control.activate_target(box)
	check(near(xp(game),0.8),"Only ten remaining dirt points give0.8XP, not2")
	reset(game)
	for i in 100:
		box.set_cleanliness(99.9)
		control.set_tool(control.SCOOP)
		control.activate_target(box)
	check(near(xp(game),0.8),"Tiny actions retain fractions instead of rounding each click up")
	reset(game)
	control.set_tool(control.POINTER)
	cat.set_affection(0.0)
	cat.set_petting(true)
	cat._update_affection(1.0)
	check(xp(game)==0.0,"Holding a stationary pointer gives no XP")
	for i in 200:
		cat.add_pet_motion(25.0)
		cat._update_affection(0.1)
	check(near(cat.affection,100.0) and near(xp(game),8.0),"100 genuinely regained affection gives8XP")
	box.set_cleanliness(0.0)
	cat.set_satiety(0.0)
	for i in 100:
		cat.add_pet_motion(25.0)
		cat._update_affection(0.1)
	check(near(xp(game),8.0),"Full affection pays nothing even if satisfaction is low")
	cat.set_petting(false)
	reset(game)
	cat.set_affection(45.0)
	cat.set_petting(true)
	for i in 110:
		cat.add_pet_motion(25.0)
		cat._update_affection(0.1)
	check(near(xp(game),4.4),"45 to100 affection gives4.4XP")
	cat.set_petting(false)
	# Rewards survive a mid-meal restart and offline progress; consumed history is not paid twice.
	reset(game)
	bowl.set_fill(100.0)
	begin_meal(cat,bowl,0.0)
	cat._update_feeding(2.0)
	check(near(xp(game),3.2),"First40 satiety earns3.2XP")
	manager.save_path = "/workspace/.godot-environment/care-xp-save.json"
	manager.persistence_enabled = true
	check(manager.save_game(),"Combined needs and XP snapshot saves")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))
	var baseline: float = saved.saved_at_seconds
	check(near(saved.progress.total_xp,3.2) and near(saved.cats[0].meal.consumed,20.0),"The same snapshot contains both reward and meal watermark")
	manager.persistence_enabled = false
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame
	manager.persistence_enabled = true
	check(manager.load_game(baseline+1.0),"Offline partial meal loads")
	check(near(xp(game),4.8),"Only next20 satiety earns next1.6 offlineXP")
	check(manager.load_game(baseline+1.0) and near(xp(game),4.8),"Reloading same instant cannot re-award offline XP")
	check(manager.load_game(baseline+3.0) and near(xp(game),8.0),"Online and offline parts total8XP for one meal")
	for i in 20:
		manager.load_game(baseline+3.0)
	check(near(xp(game),8.0),"Repeated reloads cannot farm completed offline meals")
	manager.persistence_enabled = false
	# Six cats, three bowls, one full meal each: only48XP total even after a year.
	var cats: Dictionary = {}
	var items: Array = []
	for i in 6:
		cats[str(i)] = {"id":str(i),"satiety":0.0,"meal":{},"position":[385.0,765.0]}
	for i in 3:
		var item = PlacedItemData.new()
		item.instance_id = str(i)
		item.position = Vector2(500,700)
		item.state = {"fill":100.0}
		items.append(item)
	var regained: float = Sim.advance(cats,items,365.0*86400.0)
	check(near(regained,600.0),"Six half-bowl reservations restore exactly600 satiety points")
	check(Sim.advance(cats,items,86400.0)==0.0,"Empty stock gives no further offline reward")
	var state: Dictionary = Rewards.normalize({})
	Rewards.add_points(state,regained)
	check(near(state.total_xp,48.0),"Six meals from zero give48XP; no night-time repeat awards")
	# No bonus for splitting an absence or floating-point frame increments.
	var one = {"a":{"satiety":0.0,"meal":{},"position":[385.0,765.0]}}
	var split = one.duplicate(true)
	var a = PlacedItemData.new()
	a.instance_id = "bowl"
	a.position = Vector2(500,700)
	a.state = {"fill":100.0}
	var b = a.duplicate(true)
	var all_points: float = Sim.advance(one,[a],1210.0)
	var split_points: float = 0.0
	for interval in [1.0,2.0,2.0,600.0,1.0,2.0,2.0,600.0]:
		split_points += Sim.advance(split,[b],interval)
	check(near(all_points,split_points),"Absence partitioning cannot change food XP")
	state = Rewards.normalize({})
	for i in 100000:
		Rewards.add_points(state,0.001)
	check(near(state.total_xp,8.0),"One hundred thousand tiny contributions retain exactly8XP total")
	# Level carry and fractions persist, and clock rollback cannot reset offline high water.
	reset(game)
	game.add_xp(19)
	game.award_care(25.0)
	check(game.level==2 and near(game.current_xp,1.0) and game.required_xp==30,"Level-up retains excessXP")
	game.add_xp(79)
	check(game.level==4 and near(game.current_xp,10.0) and game.required_xp==50,"Multiple level-ups retain all excessXP")
	game.award_care(0.1)
	var expected_xp: float = xp(game)
	game.change_coins(23)
	scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for member in manager.room_nodes(&"cats"):
		freeze(member)
	manager.persistence_enabled = true
	manager.save_game()
	saved = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))
	check(manager.load_game(float(saved.saved_at_seconds)),"XP and level snapshot reloads")
	check(game.level==4 and near(xp(game),expected_xp) and game.coins==123,"Level fractions and coins survive reload without a reset")
	manager.load_game(float(saved.saved_at_seconds)-1000.0)
	manager.save_game()
	var rolled: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))
	check(float(rolled.saved_at_seconds)>=float(saved.saved_at_seconds),"Saving after clock rollback cannot move the baseline backwards")
	manager.persistence_enabled = false
	# Legacy progress: no fabricated XP for previously filled/clean objects.
	saved.erase("progress")
	manager._write_record(saved)
	manager.load_game(float(saved.saved_at_seconds))
	check(game.level==1 and xp(game)==0.0,"Old saves without XP migrate cleanly with no invented historical reward")
	game.award_care(0.1)
	var level_display = scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/LeftSlot/LevelDisplay")
	check(near(level_display.xp_bar.value,0.04),"Topbar shows fractional XP without integer truncation or quantization")
	print("CARE_XP_ACTIONS_OFFLINE_PERSISTENCE_ANTI_DUPLICATION_OK" if failures.is_empty() else "CARE_XP_FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
