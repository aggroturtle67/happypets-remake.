extends SceneTree
const Plan = preload("res://scripts/ui/rewards/reward_value_plan.gd")
var failures: Array[String] = []
var events: Array[Dictionary] = []
var game: Node
var manager: Node
var scene: Node
var presenter: Node
var cat: Node2D
var bowl: Node2D
var box: Node2D
var controller: Node

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func near(a: float, b: float) -> bool:
	return absf(a - b) < 0.00001

func _initialize() -> void:
	call_deferred("run")

func _event(id: int, kind: StringName, source: Node2D, coins: int, xp: int) -> void:
	events.append({"id": id, "kind": kind, "source": source, "coins": coins, "xp": xp})

func _event_sum(kind: StringName) -> int:
	var total: int = 0
	for event in events:
		total += int(event[kind])
	return total

func _clear_visuals() -> void:
	for token in presenter._tokens:
		if is_instance_valid(token):
			token.free()
	presenter._tokens.clear()
	presenter._batches.clear()
	presenter._queue.clear()
	presenter._occupied.clear()
	presenter._spawn_elapsed = 0.0
	presenter.received_totals = {&"coins": 0, &"xp": 0}
	for plus in [presenter._coin_plus, presenter._xp_plus]:
		if is_instance_valid(plus._fade):
			plus._fade.kill()
		plus._finish_fade()

func _reset() -> void:
	game.restore_progress({})
	events.clear()
	_clear_visuals()

func _spawn_all() -> void:
	for step in 200:
		presenter._process(0.2)
		if presenter._queue.is_empty() and presenter._batches.is_empty():
			break

func _represented(kind: StringName) -> int:
	var result: int = presenter.received_totals[kind]
	for batch in presenter._batches.values():
		result += int(batch[kind])
	for entry in presenter._queue:
		if entry.kind == kind:
			result += int(entry.plan.singles) + int(entry.plan.doubles) * 2
	for token in presenter._tokens:
		if is_instance_valid(token) and not token.is_queued_for_deletion() and token.currency == kind:
			result += token.value
	return result

func _land(token: Node) -> void:
	if token.phase == token.Phase.LANDED:
		return
	token.flight_tween.kill()
	token._fly(1.0)
	token._land()
	token._process(0.0)

func _meal(satiety: float) -> void:
	cat._release_food_reservation()
	cat.food_bowl = null
	cat.set_satiety(satiety)
	cat._meal_consumed_food = 0.0
	cat._meal_total_food = 50.0
	cat._meal_start_satiety = satiety
	bowl.set_fill(100.0)
	check(bowl.reserve_meal(cat), "Meal reserves existing food")
	cat.food_bowl = bowl
	cat.global_position = cat._bowl_standing_spot(bowl)
	cat.behavior_state = cat.BehaviorState.EATING

func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var variations: Dictionary = {}
	for amount in range(0, 301):
		for sample in 12:
			var plan: Dictionary = Plan.build(amount, rng)
			check(int(plan.singles) + int(plan.doubles) * 2 == amount, "Symbol plan preserves exact value")
			if amount >= 3:
				check(int(plan.singles) >= 1 and int(plan.doubles) >= 1, "Rewards >=3 mix singles and doubles")
			if amount == 8:
				variations[str(plan)] = true
			if amount == 1:
				check(plan.singles == 1 and plan.doubles == 0, "One point is exactly one single")
			if amount == 2:
				check((plan.singles == 2 and plan.doubles == 0) or (plan.singles == 0 and plan.doubles == 1), "Two points use a double or two singles")
	check(variations.size() > 1, "Eight-point combinations vary")
	var huge: Dictionary = Plan.build(1000001, rng)
	check(huge.size() == 2 and huge.singles + huge.doubles * 2 == 1000001, "Large awards have no symbol cap and use constant-size plans")
	game = root.get_node("GameManager")
	manager = root.get_node("RoomManager")
	manager.persistence_enabled = false
	manager.start_new_game_room()
	scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	cat = manager.room_nodes(&"cats")[0]
	cat.set_physics_process(false)
	cat.wander_timer.stop()
	bowl = manager.room_nodes(&"food_bowls")[0]
	box = manager.room_nodes(&"litter_boxes")[0]
	box.set_process(false)
	controller = scene.get_node("InteractionController")
	controller.set_process(false)
	presenter = scene.get_node("CanvasLayer/HUD/CareRewardPresenter")
	check(presenter._coin_target == scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/CenterSlot/CoinDisplay"), "Coin particles bind the actual coin display")
	check(presenter._xp_target == scene.get_node("CanvasLayer/HUD/TopBar2/Background/SafeMargin/MainRow/LeftSlot/LevelDisplay/XPBarContainer/XPBar"), "XP particles bind the actual XP bar")
	presenter.set_process(false)
	presenter.settings = presenter.settings.duplicate()
	presenter.settings.batch_quiet_time = 0.0
	presenter.settings.collection_duration = 0.02
	presenter.settings.particle_duration = 0.04
	presenter.settings.particle_speed = 3.0
	presenter._rng.seed = 84
	var camera: Camera2D = scene.get_node("MainRoom/RoomCamera")
	camera.edge_scroll_enabled = false
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	camera.set_process(false)
	game.care_reward_credited.connect(_event)
	_reset()
	controller.set_tool(controller.FOOD)
	for step in 4:
		controller.activate_target(bowl)
	check(events.is_empty() and presenter._batches.is_empty(), "Refilling never emits a reward animation")
	controller.set_tool(controller.SCOOP)
	box.set_cleanliness(0.0)
	for step in 4:
		controller.activate_target(box)
	check(events.size() == 4 and _event_sum(&"coins") == 9 and _event_sum(&"xp") == 8, "Successful cleaning emits exactly9 coins and8XP")
	for event in events:
		check(event.source == box and event.kind == &"clean", "Cleaning visuals originate at the toilet")
	controller.set_tool(controller.SCOOP)
	controller.activate_target(box)
	check(events.size() == 4, "An already clean toilet emits nothing")
	_spawn_all()
	check(_represented(&"coins") == 9 and _represented(&"xp") == 8, "Every cleaning point is represented exactly")
	var dedup: Dictionary = events.back()
	presenter._on_care_reward(dedup.id, dedup.kind, dedup.source, dedup.coins, dedup.xp)
	check(presenter._batches.is_empty(), "Duplicate event IDs cannot spawn a second receipt")
	_reset()
	controller.set_tool(controller.POINTER)
	_meal(0.0)
	for frame in 300:
		cat._update_feeding(1.0 / 60.0)
	check(game.coins == 110 and game.export_progress().total_xp == 8, "Food values are unchanged")
	check(_event_sum(&"coins") == 10 and _event_sum(&"xp") == 8, "Frame-sized food credits animate exact actual deltas")
	for event in events:
		check(event.source == bowl and event.kind == &"food", "Food originates from bowl, not the cat")
	var count: int = events.size()
	cat._finish_feeding()
	cat._finish_feeding()
	check(events.size() == count, "Repeated meal completion does not repeat visuals")
	_spawn_all()
	check(_represented(&"coins") == 10 and _represented(&"xp") == 8, "Batched food symbols match all real credit")
	_reset()
	_meal(50.0)
	cat._update_feeding(5.0)
	check(_event_sum(&"coins") == 5 and _event_sum(&"xp") == 4, "Half-hunger meal animates5 coins and4XP only")
	_reset()
	cat.set_affection(0)
	cat.set_petting(true)
	cat._update_affection(1.0)
	check(events.is_empty(), "Stationary petting does not animate")
	for step in 200:
		cat.add_pet_motion(25.0)
		cat._update_affection(0.1)
	check(_event_sum(&"coins") == 6 and _event_sum(&"xp") == 8, "Actual stroking gives6 coins and8XP visuals")
	for event in events:
		check(event.source == cat and event.kind == &"pet", "Pet visuals originate from the stroked cat")
	cat.set_petting(false)
	_reset()
	game.add_xp(100)
	game.change_coins(100)
	game.restore_progress({"total_xp": 500, "coins": 300})
	check(events.is_empty() and presenter._batches.is_empty(), "Other rewards, level-ups and loading never animate")
	_reset()
	game.restore_progress({"total_xp": 19, "coins": 100})
	game.level_changed.connect(func(_level: int) -> void:
		game.change_coins(50)
		game.add_xp(1), CONNECT_ONE_SHOT)
	game.award_care(25, &"clean", box)
	check(game.coins == 152 and game.export_progress().total_xp == 22, "Simulated independent level bonus is still credited normally")
	check(_event_sum(&"coins") == 2 and _event_sum(&"xp") == 2, "A level bonus fired inside a care callback never leaks into care visuals")
	# A large burst remains fully accounted for when the visible room fills up.
	_reset()
	game.award_care(10000, &"food", bowl)
	for frame in 200:
		var before: int = presenter._tokens.size()
		presenter._process(0.2)
		if before == presenter._tokens.size() and not presenter._queue.is_empty():
			break
	check(not presenter._queue.is_empty(), "An overcrowded room queues remaining symbols")
	check(_represented(&"coins") == 1000 and _represented(&"xp") == 800, "No cap or loss for large awards")
	var landing_points: Array[Vector2] = []
	for token in presenter._tokens:
		var point: Vector2 = presenter._world_to_surface(token.landing_world)
		check(presenter._safe_rect().has_point(point) and not presenter._over_hud(point, 26.4), "Landings stay inside room and avoid UI")
		for previous in landing_points:
			check(point.distance_to(previous) >= presenter._spacing() - 0.01, "Concurrent landing positions preserve space between symbols")
		landing_points.append(point)
	# Landed symbols follow the world/camera rather than sticking to screen space.
	var ground: Node = presenter._tokens[0]
	_land(ground)
	var fixed_world: Vector2 = ground.landing_world
	var old_point: Vector2 = ground.position
	camera.position += Vector2(150, 0)
	camera.force_update_scroll()
	ground._process(0.0)
	check(ground.landing_world == fixed_world and ground.position.distance_to(old_point) > 100, "Ground receipts follow camera without changing their world location")
	camera.position -= Vector2(150, 0)
	camera.force_update_scroll()
	_reset()
	game.award_care(100, &"clean", box)
	_spawn_all()
	var shimmer: Node = presenter._tokens[0]
	_land(shimmer)
	var saw_glow: bool = false
	for step in 130:
		shimmer._shimmer.custom_step(0.05)
		var strength: float = shimmer._material.get_shader_parameter("shimmer")
		check(strength >= 0 and strength <= presenter.settings.shimmer_intensity + 0.00001, "Shimmer remains subtle and bounded")
		saw_glow = saw_glow or strength > 0.01
	check(saw_glow, "Occasional shimmer actually animates")
	var expected: Dictionary = game.export_progress()
	var coin_count: int = 0
	var xp_count: int = 0
	for token in presenter._tokens:
		_land(token)
		var correct_target: Control = presenter._coin_target if token.currency == &"coins" else presenter._xp_target
		check(Vector2(token._target.call()).is_equal_approx(presenter._control_rect(correct_target).get_center()), "Particle destination follows its own currency UI")
		var mouse: Vector2 = token.position + Vector2(presenter.settings.magnet_radius * 0.9, 0)
		check(token.try_collect(mouse), "Near-hover magnet collects without pixel-perfect hit")
		check(not token.try_collect(mouse), "Each token accepts collection only once")
		check(near(token._material.get_shader_parameter("shimmer"), 0.0), "Shimmer stops on collection")
		if token.currency == &"coins":
			coin_count += token.value
		else:
			xp_count += token.value
	await create_timer(0.35).timeout
	check(presenter.received_totals.coins == coin_count and presenter.received_totals.xp == xp_count, "All concurrent single/double particles arrive once at matching UI")
	check(presenter._coin_plus.total == 9 and presenter._xp_plus.total == 8, "One plus accumulator per currency sums actual collected values")
	check(game.export_progress() == expected, "Collection never grants coins or XP a second time")
	await create_timer(0.35).timeout
	check(presenter._coin_target.scale.is_equal_approx(Vector2.ONE) and presenter._xp_target.scale.is_equal_approx(Vector2.ONE), "UI pulse restores original scale after overlapping receipts")
	# Adding during fade continues the existing series, then clears after inactivity.
	var plus: Node = presenter._coin_plus
	if is_instance_valid(plus._fade):
		plus._fade.kill()
	plus._finish_fade()
	plus.hold_duration = 0.04
	plus.fade_duration = 0.15
	for points in [2, 1, 2, 2, 1]:
		plus.add_value(points)
	check(plus.total == 8 and plus.text == "+8", "Plus example2+1+2+2+1 totals8")
	await create_timer(0.09).timeout
	check(plus._fading, "Plus label enters a gentle fade")
	plus.add_value(2)
	check(plus.total == 10 and near(plus.modulate.a, 1.0) and not plus._fading, "New collection during fade restores visibility and continues sum")
	await create_timer(0.25).timeout
	check(not plus.visible and plus.total == 0, "Plus hides and resets only after full inactivity/fade")
	for dimensions in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(2560, 1440)]:
		root.size = dimensions
		await process_frame
		await process_frame
		for kind in [&"coins", &"xp"]:
			var target: Vector2 = presenter._target_center(kind)
			check(target.is_finite() and get_root().get_visible_rect().has_point(target), "Live UI targets adapt to different window aspects")
	# Save credit before display; remove scene without collecting; reload with no replay.
	_reset()
	manager.save_path = "user://reward_collection_test_snapshot.json"
	manager.persistence_enabled = true
	if FileAccess.file_exists(manager.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path))
	var already_saved: Array[bool] = []
	game.coins_changed.connect(func(_coins: int) -> void:
		var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path)) if FileAccess.file_exists(manager.save_path) else null
		already_saved.append(record is Dictionary and record.progress.coins == 102 and record.progress.total_xp == 2), CONNECT_ONE_SHOT)
	box.set_cleanliness(0.0)
	controller.set_tool(controller.SCOOP)
	controller.activate_target(box)
	check(already_saved == [true], "Care credit is saved even before UI observers can trigger a scene change")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manager.save_path))
	check(saved.progress.coins == 102 and saved.progress.total_xp == 2, "Whole reward and need state are already saved before hover")
	check(saved.room.items[1].state.cleanliness == 25.0, "Same snapshot records exactly the cleaned amount")
	var instant: float = saved.saved_at_seconds
	manager.persistence_enabled = false
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame
	manager.persistence_enabled = true
	check(manager.load_game(instant), "Saved scene transition state loads")
	check(game.coins == 102 and game.export_progress().total_xp == 2, "Uncollected visual rewards survive scene change as credited balance")
	events.clear()
	scene = load("res://scenes/main/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var replacement: Node = scene.get_node("CanvasLayer/HUD/CareRewardPresenter")
	check(events.is_empty() and replacement._batches.is_empty() and replacement._tokens.is_empty(), "Loading never replays already credited receipts")
	manager.persistence_enabled = false
	print("REWARD_COLLECTION_ALL_CHECKS_PASSED" if failures.is_empty() else "REWARD_COLLECTION_FAILED " + str(failures))
	quit(0 if failures.is_empty() else 1)
