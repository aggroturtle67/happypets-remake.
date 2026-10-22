extends SceneTree
const Sim = preload("res://scripts/managers/offline_consumption.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func near(a: float, b: float) -> bool:
	return absf(a-b) < 0.0001
func cat_record(id: String, satiety: float = 100.0) -> Dictionary:
	return {"id": id, "satiety": satiety, "position": [385.0, 765.0], "meal": {}}
func item(id: String, key: String, amount: float) -> PlacedItemData:
	var placed = PlacedItemData.new()
	placed.instance_id = id
	placed.position = Vector2(500,700)
	placed.state = {key: amount}
	return placed
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var cats: Dictionary = {"cat_start": cat_record("cat_start")}
	var bowl = item("bowl", "fill", 100.0)
	var box = item("box", "cleanliness", 100.0)
	Sim.advance(cats, [bowl, box], 120.0)
	check(near(cats.cat_start.satiety,90.0) and bowl.state.fill == 100.0, "Two minutes:100 becomes90; stocked food untouched until hunger")
	check(near(box.state.cleanliness,100.0-120.0*25.0/180.0), "Offline litter uses twelve-minute rate")
	Sim.advance(cats, [bowl,box],480.0)
	check(near(cats.cat_start.satiety,50.0), "Hunger threshold reached at ten minutes")
	Sim.advance(cats, [bowl,box],2.5)
	check(near(cats.cat_start.satiety,75.0) and near(bowl.state.fill,75.0), "Halfway meal:75 satiety and75 bowl")
	Sim.advance(cats, [bowl,box],2.5)
	check(near(cats.cat_start.satiety,100.0) and near(bowl.state.fill,50.0), "Five-second meal consumes half bowl")
	Sim.advance(cats, [bowl,box],605.0)
	check(near(cats.cat_start.satiety,100.0) and near(bowl.state.fill,0.0), "Remaining half supports next meal without a refill")
	Sim.advance(cats, [bowl,box],86400.0*365.0)
	check(cats.cat_start.satiety == 0.0 and bowl.state.fill == 0.0 and box.state.cleanliness == 0.0, "Year-long absence reaches zero efficiently; no negatives")
	Sim.advance(cats, [bowl,box],120.0)
	check(cats.cat_start.satiety == 0.0, "Empty values stay empty")
	# Splitting an absence must not alter timing, travel, stock or satiety.
	var whole: Dictionary = {}
	for i in 6:
		whole[str(i)] = cat_record(str(i), 45.0 + i)
		whole[str(i)].position = [100.0+i*80.0,850.0]
	var split: Dictionary = whole.duplicate(true)
	var a: Array = [item("a","fill",100),item("b","fill",100),item("c","fill",100)]
	a[1].position = Vector2(900,700)
	a[2].position = Vector2(1300,700)
	var b: Array = []
	for placed in a:
		b.append(placed.duplicate(true))
	Sim.advance(whole,a,33.75)
	for step in [0.1,0.2,0.45,1.0,2.0,10.0,20.0]:
		Sim.advance(split,b,step)
	for id in whole:
		check(near(whole[id].satiety,split[id].satiety), "Repeated reopen retains chronological satiety for cat"+id)
		check(whole[id].meal.is_empty() and split[id].meal.is_empty(), "All six meals finish")
	for index in 3:
		check(near(a[index].state.fill,0.0) and near(b[index].state.fill,0.0), "Six cats share three bowls without duplicated meals")
	# Short reopen while walking cannot instantly feed the cat.
	cats = {"cat_start": cat_record("cat_start",40.0)}
	cats.cat_start.position = [25.0,765.0]
	bowl.state.fill = 100.0
	Sim.advance(cats,[bowl],1.0)
	check(near(cats.cat_start.position[0],145.0) and bowl.state.fill == 100.0, "One-second absence advances walk, not an instant meal")
	Sim.advance(cats,[bowl],2.0)
	check(near(cats.cat_start.position[0],385.0) and bowl.state.fill == 100.0, "Arrival preserves food until eating")
	Sim.advance(cats,[bowl],5.0)
	check(near(cats.cat_start.satiety,100.0) and bowl.state.fill == 50.0, "Meal after travel restores full satiety")
	# Existing partial meal continues even though satiety is above hunger threshold.
	cats.cat_start.satiety = 70.0
	cats.cat_start.meal = {"bowl_id":"bowl","total":50.0,"consumed":20.0,"start_satiety":50.0}
	bowl.state.fill = 80.0
	Sim.advance(cats,[bowl],3.0)
	check(near(cats.cat_start.satiety,100.0) and near(bowl.state.fill,50.0), "Existing partial meal consumes only the thirty remaining food points")
	bowl.state.fill = 25.0
	cats.cat_start.satiety = 10.0
	Sim.advance(cats,[bowl],200.0)
	check(cats.cat_start.satiety == 0.0 and bowl.state.fill == 25.0, "Quarter bowl is insufficient; no invented food")
	# Real save/load migration, injected timestamps and live resume.
	var manager = root.get_node("RoomManager")
	var scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var live = manager.room_nodes(&"cats")[0]
	live.set_physics_process(false)
	live.wander_timer.stop()
	live.set_satiety(100.0)
	var live_bowl = manager.room_nodes(&"food_bowls")[0]
	live_bowl.set_fill(100.0)
	manager.save_path = "/workspace/.godot-environment/offline-consumption-save.json"
	manager.persistence_enabled = true
	check(manager.save_game(),"Timestamped snapshot writes")
	manager.persistence_enabled = false
	var snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))
	var timestamp: float = snapshot.saved_at_seconds
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame
	manager.persistence_enabled = true
	check(manager.load_game(timestamp+120.0),"Timed snapshot loads")
	check(near(manager.saved_cat_states.cat_start.satiety,90.0),"Real load charges exactly two minutes")
	check(manager.load_game(timestamp+120.0) and near(manager.saved_cat_states.cat_start.satiety,90.0),"Loading same timestamp twice cannot double charge")
	check(manager.load_game(timestamp+121.0) and near(manager.saved_cat_states.cat_start.satiety,90.0-1.0/12.0),"Next load charges only new elapsed time")
	check(manager.load_game(timestamp+100.0) and near(manager.saved_cat_states.cat_start.satiety,90.0-1.0/12.0),"Clock moving backwards cannot increase needs")
	check(manager.load_game(timestamp+121.0) and near(manager.saved_cat_states.cat_start.satiety,90.0-1.0/12.0),"Clock recovery cannot charge the same twenty-one seconds twice")
	# Old version-one files have no offline baseline; migration is neutral.
	snapshot.erase("saved_at_seconds")
	manager._write_record(snapshot)
	check(manager.load_game(timestamp+1000000.0) and manager.saved_cat_states.cat_start.satiety == 100.0,"Old timestamp-less save migrates with no retroactive consumption")
	# Mid-meal offline record resumes in the real cat script.
	snapshot.saved_at_seconds = timestamp
	snapshot.cats[0].satiety = 50.0
	snapshot.cats[0].position = [385.0,765.0]
	snapshot.cats[0].meal = {"bowl_id":"food_bowl_start","start_satiety":0.0,"consumed":25.0,"total":50.0}
	for entry in snapshot.room.items:
		if entry.id == "food_bowl_start":
			entry.state.fill = 75.0
	manager._write_record(snapshot)
	check(manager.load_game(timestamp+1.0),"Interrupted meal advances while closed")
	manager.persistence_enabled = false
	scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	live = manager.room_nodes(&"cats")[0]
	live.set_physics_process(false)
	live.wander_timer.stop()
	live_bowl = manager.room_nodes(&"food_bowls")[0]
	check(near(live.satiety,70.0) and near(live_bowl.fill_amount,65.0),"Live scene restores exact offline meal progress")
	live._try_resume_meal()
	live.global_position = live._bowl_standing_spot(live_bowl)
	live.stop_moving()
	live._update_feeding(1.5)
	check(near(live.satiety,100.0) and near(live_bowl.fill_amount,50.0),"Live cat finishes remaining meal without duplicate consumption")
	print("OFFLINE_CONSUMPTION_OK" if failures.is_empty() else "OFFLINE_CONSUMPTION_FAILED "+str(failures))
	quit(0 if failures.is_empty() else 1)
