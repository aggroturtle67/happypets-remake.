extends CharacterBody2D

enum BehaviorState {
	IDLE,
	WALKING,
	SITTING_DOWN,
	SITTING,
	STANDING_UP,
	SITTING_TO_LYING,
	LYING,
	LYING_TO_SITTING,
	STANDING_TO_LYING,
	LYING_TO_STANDING,
	EATING
}

enum PoseState {
	NONE,
	STANDING,
	SITTING,
	LYING
}

signal affection_changed(value: float)
signal satiety_changed(value: float)
signal feeding_started
signal feeding_finished

@export_category("Zuneigung")
@export_range(0.0, 100.0) var starting_affection: float = 100.0
## From 100 to 45 in 36 hours, online and offline.
@export var affection_loss_per_second: float = 55.0 / (36.0 * 3600.0)
@export var affection_gain_per_second: float = 5.0
var affection: float = 100.0
var is_being_petted: bool = false
var _petting_timer_remaining: float = -1.0

@export_category("Hunger und Fressen")
## 100 = satt, 0 = hungrig. Nach einer vollen Mahlzeit ca. 10 Minuten satt.
@export_range(0.0, 100.0) var starting_satiety: float = 70.0
## Für den aktuellen Test: unabhängig von gespeicherten Startwerten bei 0 beginnen.
@export var start_hungry_for_testing: bool = true
@export var satiety_loss_per_second: float = 50.0 / 600.0
@export var hungry_threshold: float = 50.0
@export var satisfied_threshold: float = 100.0
## Verbrauch in Napf-Prozentpunkten pro Sekunde: voller Napf = 10 Sekunden.
@export var eating_per_second: float = 10.0
## Ein halber Napf ist eine Mahlzeit und macht eine Katze satt.
@export var pet_id: String = ""
## Abstand der Standposition zum Napf (Raumkoordinaten).
@export var bowl_standing_offset: Vector2 = Vector2(115, 65)

var satiety: float = 70.0
var food_bowl: FoodBowl
var seeking_food: bool = false
var food_status: Label
var _meal_start_satiety: float = 0.0
var _meal_consumed_food: float = 0.0
var _meal_total_food: float = FoodBowl.MEAL_SIZE
var _resuming_meal: bool = false
var pending_meal_restore: Dictionary = {}

@export_category("Bewegung")

@export var movement_speed: float = 120.0
@export var arrival_distance: float = 8.0

# Verhindert kaum sichtbare Mini-Laufwege.
@export var minimum_wander_distance: float = 250.0

# Sorgt für eine erkennbare seitliche Bewegung.
@export var minimum_horizontal_change: float = 120.0

# Sorgt dafür, dass nicht nur auf einer Linie gelaufen wird.
@export var minimum_vertical_change: float = 20.0


@export_category("Sicherheitsabstand zum Raumrand")

# Die PetWalkArea beschreibt die gesamte Bodenfläche.
# Dieser Abstand hält Kopf und Schwanz innerhalb der seitlichen Raumränder.
@export var horizontal_edge_margin: float = 190.0

# Kleiner Abstand zwischen den Pfoten und dem unteren Raumrand.
@export var bottom_edge_margin: float = 10.0


@export_category("Perspektive")

# Größe am oberen Rand des Laufbereichs.
@export var far_perspective_multiplier: float = 1.0

# Größe am unteren Rand des Laufbereichs.
@export var near_perspective_multiplier: float = 1.2



@export_category("Pausen")

@export var minimum_pause_time: float = 0.7
@export var maximum_pause_time: float = 1.8


@onready var visual_pivot: Node2D = $VisualPivot
@onready var cat_visual = $VisualPivot/CatVisual
@onready var wander_timer: Timer = $WanderTimer

@export_category("Entscheidungen im Stehen")

# Die restlichen 10 % bleibt die Katze einfach stehen.
@export_range(0.0, 1.0, 0.05) var walk_chance: float = 0.65
@export_range(0.0, 1.0, 0.05) var sit_chance: float = 0.22
@export_range(0.0, 1.0, 0.05) var stand_to_lie_chance: float = 0.03


@export_category("Sitzen")

@export var minimum_sit_time: float = 1.3
@export var maximum_sit_time: float = 3.0

# Die restlichen 20 % bleibt die Katze länger sitzen.
@export_range(0.0, 1.0, 0.05) var sit_to_lie_chance: float = 0.1
@export_range(0.0, 1.0, 0.05) var sit_to_stand_chance: float = 0.70


@export_category("Liegen")

@export var minimum_lie_time: float = 2
@export var maximum_lie_time: float = 4.5

# Die restlichen 65 % bleibt die Katze gemütlich liegen.
@export_range(0.0, 1.0, 0.05) var lie_to_sit_chance: float = 0.35
@export_range(0.0, 1.0, 0.05) var lie_to_stand_chance: float = 0.5
# Der im Hauptraum eingezeichnete Laufbereich.
var pet_walk_area: Area2D

# Die rechteckige Form des Laufbereichs.
var walk_area_shape: CollisionShape2D


var movement_target: Vector2 = Vector2.ZERO
var has_movement_target: bool = false

# 1 bedeutet rechts, -1 bedeutet links.
var facing_direction: float = 1.0

var behavior_state: int = BehaviorState.IDLE

# Diese Pose darf bei der nächsten Entscheidung
# nicht sofort wieder gewählt werden.
var blocked_return_pose: int = PoseState.NONE


func _ready() -> void:
	if pet_id.is_empty():
		pet_id = "cat_start" if name == "Cat" else RoomManager.next_cat_id()
	if RoomManager.has_loaded_save and pet_id == "cat_start" and not RoomManager.saved_cat_states.has(pet_id):
		set_physics_process(false)
		queue_free()
		return
	if not RoomManager.register_cat(self):
		set_physics_process(false)
		queue_free()
		return
	satiety = 0.0 if start_hungry_for_testing else clampf(starting_satiety, 0.0, 100.0)
	affection = clampf(starting_affection, 0.0, 100.0)
	RoomManager.restore_cat(self)
	food_status = Label.new()
	food_status.name = "FoodStatus"
	food_status.position = Vector2(-75, -340)
	food_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	food_status.add_theme_font_size_override("font_size", 22)
	food_status.add_theme_color_override("font_outline_color", Color(0.2, 0.13, 0.12))
	food_status.add_theme_constant_override("outline_size", 5)
	add_child(food_status)
	# Sucht den Laufbereich des aktuellen Raums.
	pet_walk_area = get_tree().get_first_node_in_group(
		&"pet_walk_area"
	) as Area2D

	if pet_walk_area == null:
		push_error(
			"Es wurde keine PetWalkArea mit der Gruppe "
			+ "'pet_walk_area' gefunden."
		)
		set_physics_process(false)
		return

	walk_area_shape = pet_walk_area.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if (
		walk_area_shape == null
		or not walk_area_shape.shape is RectangleShape2D
	):
		push_error(
			"PetWalkArea benötigt eine RectangleShape2D."
		)
		set_physics_process(false)
		return

	if visual_pivot.scale.x < 0.0:
		facing_direction = -1.0

	wander_timer.timeout.connect(
	_on_wander_timer_timeout
)

	cat_visual.sit_down_finished.connect(
	_on_sit_down_finished
)

	cat_visual.stand_up_finished.connect(
	_on_stand_up_finished
)

	cat_visual.sit_to_lie_finished.connect(
	_on_sit_to_lie_finished
	)

	cat_visual.lie_to_sit_finished.connect(
	_on_lie_to_sit_finished
	)

	cat_visual.stand_to_lie_finished.connect(
	_on_stand_to_lie_finished
	)

	cat_visual.lie_to_stand_finished.connect(
	_on_lie_to_stand_finished
	)

	wander_timer.one_shot = true
	# Falls die Startposition außerhalb liegt,
	# wird sie sofort in das Rechteck gesetzt.
	_keep_position_inside_walk_area()

	_update_perspective()
	_start_wander_pause()


func _physics_process(delta: float) -> void:
	_try_resume_meal()
	_update_feeding(delta)
	_update_affection(delta)
	if is_being_petted and not wander_timer.is_stopped():
		_petting_timer_remaining = wander_timer.time_left
		wander_timer.stop()
	if is_being_petted and behavior_state == BehaviorState.WALKING:
		velocity = Vector2.ZERO
		cat_visual.play_idle()
		return
	if (
		behavior_state == BehaviorState.WALKING
		and has_movement_target
	):
		var distance_to_target: float = (
			global_position.distance_to(movement_target)
		)

		if distance_to_target <= arrival_distance:
			stop_moving()
		else:
			var direction: Vector2 = (
				global_position.direction_to(movement_target)
			)

			velocity = direction * minf(movement_speed, distance_to_target / maxf(delta, 0.001))
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Die tatsächliche Position kann das Rechteck nicht verlassen.
	_keep_position_inside_walk_area()

	_update_perspective()
	_update_animation()


func set_movement_target(new_target: Vector2) -> void:
	wander_timer.stop()

	var walk_rect: Rect2 = _get_walk_rect()

	# Auch das Ziel wird innerhalb des Rechtecks gehalten.
	movement_target = Vector2(
		clampf(
			new_target.x,
			walk_rect.position.x,
			walk_rect.end.x
		),
		clampf(
			new_target.y,
			walk_rect.position.y,
			walk_rect.end.y
		)
	)

	if movement_target.x > global_position.x:
		facing_direction = 1.0
	elif movement_target.x < global_position.x:
		facing_direction = -1.0

	behavior_state = BehaviorState.WALKING
	has_movement_target = true


func stop_moving() -> void:
	var was_moving: bool = has_movement_target

	has_movement_target = false
	velocity = Vector2.ZERO

	if was_moving:
		behavior_state = BehaviorState.IDLE
		if (
			_is_food_bowl_usable(food_bowl)
			and global_position.distance_to(_bowl_standing_spot(food_bowl)) <= arrival_distance * 2.0
		):
			behavior_state = BehaviorState.EATING
			if not _resuming_meal:
				_meal_start_satiety = satiety
				_meal_consumed_food = 0.0
				_meal_total_food = FoodBowl.MEAL_SIZE
			_resuming_meal = false
			facing_direction = 1.0 if food_bowl.global_position.x >= global_position.x else -1.0
			wander_timer.stop()
			# Die vorhandene Grafik bleibt unverändert; eine Fresspose folgt später.
			cat_visual.play_idle()
			feeding_started.emit()
		else:
			_start_wander_pause()

func _on_wander_timer_timeout() -> void:
	if _prioritize_food():
		return
	match behavior_state:
		BehaviorState.IDLE:
			_choose_standing_action()

		BehaviorState.SITTING:
			_choose_sitting_action()

		BehaviorState.LYING:
			_choose_lying_action()


func _choose_standing_action() -> void:
	var decision: float = randf()

	if decision < walk_chance:
		# Nach dem Laufen darf jede Pose wieder gewählt werden.
		blocked_return_pose = PoseState.NONE
		_choose_new_wander_target()

	elif decision < walk_chance + sit_chance:
		if blocked_return_pose == PoseState.SITTING:
			_stay_in_current_pose_and_unlock()
		else:
			_start_sitting()

	elif (
		decision
		< walk_chance + sit_chance + stand_to_lie_chance
	):
		if blocked_return_pose == PoseState.LYING:
			_stay_in_current_pose_and_unlock()
		else:
			_start_stand_to_lie()

	else:
		_stay_in_current_pose_and_unlock()


func _choose_sitting_action() -> void:
	var decision: float = randf()

	if decision < sit_to_lie_chance:
		if blocked_return_pose == PoseState.LYING:
			_stay_in_current_pose_and_unlock()
		else:
			_start_sit_to_lie()

	elif decision < sit_to_lie_chance + sit_to_stand_chance:
		if blocked_return_pose == PoseState.STANDING:
			_stay_in_current_pose_and_unlock()
		else:
			_start_standing_up()

	else:
		_stay_in_current_pose_and_unlock()


func _choose_lying_action() -> void:
	var decision: float = randf()

	if decision < lie_to_sit_chance:
		if blocked_return_pose == PoseState.SITTING:
			_stay_in_current_pose_and_unlock()
		else:
			_start_lie_to_sit()

	elif decision < lie_to_sit_chance + lie_to_stand_chance:
		if blocked_return_pose == PoseState.STANDING:
			_stay_in_current_pose_and_unlock()
		else:
			_start_lie_to_stand()

	else:
		_stay_in_current_pose_and_unlock()
		
func _stay_in_current_pose_and_unlock() -> void:
	# Nach einer weiteren vollständigen Pause
	# darf die vorherige Pose wieder gewählt werden.
	blocked_return_pose = PoseState.NONE

	match behavior_state:
		BehaviorState.IDLE:
			_start_wander_pause()

		BehaviorState.SITTING:
			_start_sit_pause()

		BehaviorState.LYING:
			_start_lie_pause()


func _start_sitting() -> void:
	blocked_return_pose = PoseState.STANDING
	wander_timer.stop()

	has_movement_target = false
	velocity = Vector2.ZERO
	behavior_state = BehaviorState.SITTING_DOWN

	cat_visual.play_sit_down()


func _start_standing_up() -> void:
	blocked_return_pose = PoseState.SITTING
	wander_timer.stop()

	behavior_state = BehaviorState.STANDING_UP
	cat_visual.play_stand_up()


func _start_sit_to_lie() -> void:
	blocked_return_pose = PoseState.SITTING
	wander_timer.stop()

	has_movement_target = false
	velocity = Vector2.ZERO
	behavior_state = BehaviorState.SITTING_TO_LYING

	cat_visual.play_sit_to_lie()


func _start_lie_to_sit() -> void:
	blocked_return_pose = PoseState.LYING
	wander_timer.stop()

	behavior_state = BehaviorState.LYING_TO_SITTING
	cat_visual.play_lie_to_sit()


func _start_stand_to_lie() -> void:
	blocked_return_pose = PoseState.STANDING
	wander_timer.stop()

	has_movement_target = false
	velocity = Vector2.ZERO
	behavior_state = BehaviorState.STANDING_TO_LYING

	cat_visual.play_stand_to_lie()


func _start_lie_to_stand() -> void:
	blocked_return_pose = PoseState.LYING
	wander_timer.stop()

	behavior_state = BehaviorState.LYING_TO_STANDING
	cat_visual.play_lie_to_stand()


func _on_sit_down_finished() -> void:
	if behavior_state != BehaviorState.SITTING_DOWN:
		return

	behavior_state = BehaviorState.SITTING
	_start_sit_pause()


func _on_stand_up_finished() -> void:
	if behavior_state != BehaviorState.STANDING_UP:
		return

	behavior_state = BehaviorState.IDLE
	_start_wander_pause()


func _on_sit_to_lie_finished() -> void:
	if behavior_state != BehaviorState.SITTING_TO_LYING:
		return

	behavior_state = BehaviorState.LYING
	_start_lie_pause()


func _on_lie_to_sit_finished() -> void:
	if behavior_state != BehaviorState.LYING_TO_SITTING:
		return

	behavior_state = BehaviorState.SITTING
	_start_sit_pause()


func _on_stand_to_lie_finished() -> void:
	if behavior_state != BehaviorState.STANDING_TO_LYING:
		return

	behavior_state = BehaviorState.LYING
	_start_lie_pause()


func _on_lie_to_stand_finished() -> void:
	if behavior_state != BehaviorState.LYING_TO_STANDING:
		return

	behavior_state = BehaviorState.IDLE
	_start_wander_pause()


func _start_sit_pause() -> void:
	if _prioritize_food():
		return
	var random_sit_time: float = randf_range(
		minimum_sit_time,
		maximum_sit_time
	)

	wander_timer.start(random_sit_time)


func _start_lie_pause() -> void:
	if _prioritize_food():
		return
	var random_lie_time: float = randf_range(
		minimum_lie_time,
		maximum_lie_time
	)

	wander_timer.start(random_lie_time)

func _choose_new_wander_target() -> void:
	var walk_rect: Rect2 = _get_walk_rect()

	var new_target: Vector2 = global_position
	var valid_target_found: bool = false

	for attempt in range(20):
		var candidate: Vector2 = Vector2(
			randf_range(
				walk_rect.position.x,
				walk_rect.end.x
			),
			randf_range(
				walk_rect.position.y,
				walk_rect.end.y
			)
		)

		var total_distance: float = (
			global_position.distance_to(candidate)
		)

		var horizontal_change: float = abs(
			candidate.x - global_position.x
		)

		var vertical_change: float = abs(
			candidate.y - global_position.y
		)

		if (
			total_distance >= minimum_wander_distance
			and horizontal_change >= minimum_horizontal_change
			and vertical_change >= minimum_vertical_change
		):
			new_target = candidate
			valid_target_found = true
			break

	# Ersatzpunkt, falls kein ausreichend entfernter Punkt gefunden wurde.
	if not valid_target_found:
		var middle_x: float = (
			walk_rect.position.x + walk_rect.end.x
		) * 0.5

		if global_position.x < middle_x:
			new_target.x = walk_rect.end.x
		else:
			new_target.x = walk_rect.position.x

		new_target.y = randf_range(
			walk_rect.position.y,
			walk_rect.end.y
		)

	set_movement_target(new_target)


# Ermittelt die tatsächlichen globalen Grenzen des Rechtecks
# und berücksichtigt die sichtbare Breite der Katze.
func _get_walk_rect() -> Rect2:
	var rectangle_shape: RectangleShape2D = (
		walk_area_shape.shape as RectangleShape2D
	)

	var half_size: Vector2 = rectangle_shape.size * 0.5

	var first_corner: Vector2 = walk_area_shape.to_global(
		-half_size
	)

	var second_corner: Vector2 = walk_area_shape.to_global(
		half_size
	)

	var minimum_corner: Vector2 = Vector2(
		minf(first_corner.x, second_corner.x),
		minf(first_corner.y, second_corner.y)
	)

	var maximum_corner: Vector2 = Vector2(
		maxf(first_corner.x, second_corner.x),
		maxf(first_corner.y, second_corner.y)
	)

	var room_walk_rect: Rect2 = Rect2(
		minimum_corner,
		maximum_corner - minimum_corner
	)

	var safe_width: float = maxf(
		room_walk_rect.size.x - horizontal_edge_margin * 2.0,
		1.0
	)

	var safe_height: float = maxf(
		room_walk_rect.size.y - bottom_edge_margin,
		1.0
	)

	return Rect2(
		room_walk_rect.position + Vector2(
			horizontal_edge_margin,
			0.0
		),
		Vector2(safe_width, safe_height)
	)


# Harte Begrenzung auf das eingezeichnete Rechteck.
func _keep_position_inside_walk_area() -> void:
	var walk_rect: Rect2 = _get_walk_rect()

	global_position = Vector2(
		clampf(
			global_position.x,
			walk_rect.position.x,
			walk_rect.end.x
		),
		clampf(
			global_position.y,
			walk_rect.position.y,
			walk_rect.end.y
		)
	)


# Oberer Rechteckrand = normale Größe.
# Unterer Rechteckrand = größere Perspektivdarstellung.
func _update_perspective() -> void:
	var walk_rect: Rect2 = _get_walk_rect()

	var perspective_progress: float = inverse_lerp(
		walk_rect.position.y,
		walk_rect.end.y,
		global_position.y
	)

	perspective_progress = clampf(
		perspective_progress,
		0.0,
		1.0
	)

	var perspective_multiplier: float = lerpf(
		far_perspective_multiplier,
		near_perspective_multiplier,
		perspective_progress
	)

	visual_pivot.scale = Vector2(
		perspective_multiplier * facing_direction,
		perspective_multiplier
	)


func _start_wander_pause() -> void:
	if _prioritize_food():
		return
	var random_pause: float = randf_range(
		minimum_pause_time,
		maximum_pause_time
	)

	wander_timer.start(random_pause)


func _update_animation() -> void:
	match behavior_state:
		BehaviorState.IDLE:
			cat_visual.play_idle()

		BehaviorState.WALKING:
			cat_visual.play_walk()


func set_satiety(value: float) -> void:
	var next_value: float = clampf(value, 0.0, 100.0)
	if satiety != next_value:
		satiety = next_value
		satiety_changed.emit(satiety)


func _update_feeding(delta: float) -> void:
	if behavior_state == BehaviorState.EATING:
		if is_instance_valid(food_bowl) and food_bowl.is_being_filled:
			food_status.text = "Wartet …"
			return
		if not _is_food_bowl_usable(food_bowl):
			_finish_feeding()
			return
		var spot: Vector2 = _bowl_standing_spot(food_bowl)
		if global_position.distance_to(spot) > arrival_distance * 2.0:
			_resuming_meal = true
			set_movement_target(spot)
			return
		var portion: float = food_bowl.consume_meal(self, maxf(eating_per_second, 0.0) * delta)
		_meal_consumed_food += portion
		var progress: float = clampf(_meal_consumed_food / maxf(_meal_total_food, 0.001), 0.0, 1.0)
		set_satiety(lerpf(_meal_start_satiety, 100.0, progress))
		food_status.text = "Frisst …"
		if food_bowl.reserved_food_remaining <= 0.000001:
			set_satiety(100.0)
			_finish_feeding()
		return

	set_satiety(satiety - maxf(satiety_loss_per_second, 0.0) * delta)
	if satiety <= hungry_threshold:
		seeking_food = true
	elif satiety >= satisfied_threshold:
		seeking_food = false
	food_status.text = "Hungrig" if seeking_food else ""

	if is_instance_valid(food_bowl) and not _is_food_bowl_usable(food_bowl):
		_release_food_reservation()
		food_bowl = null
		stop_moving()
	_prioritize_food()


# Variant erlaubt auch die sichere Prüfung eines gerade entfernten Napfes.
func _is_food_bowl_usable(bowl: Variant) -> bool:
	return (
		is_instance_valid(bowl)
		and bowl.can_claim(self)
		and bowl.is_visible_in_tree()
		and bowl.get_parent() == get_parent()
		and _bowl_standing_spot(bowl).is_finite()
	)


func _prioritize_food() -> bool:
	if not pending_meal_restore.is_empty():
		return true # Erst nach dem Raumaufbau die gespeicherte Portion fortsetzen.
	if behavior_state == BehaviorState.EATING:
		return true
	if satiety <= hungry_threshold:
		seeking_food = true
	if not seeking_food:
		return false
	if not _is_food_bowl_usable(food_bowl):
		_release_food_reservation()
		food_bowl = _find_food_bowl()
		if is_instance_valid(food_bowl) and not food_bowl.reserve_meal(self):
			food_bowl = null
	if food_bowl == null:
		return false # Ohne gefüllten Napf bleiben normale Tätigkeiten möglich.

	# Das Ziel bleibt während der Aufstehanimation reserviert. Jeder Einstieg
	# in zufällige Tätigkeiten prüft diese Priorität ebenfalls.
	wander_timer.stop()
	match behavior_state:
		BehaviorState.SITTING:
			_start_standing_up()
		BehaviorState.LYING:
			_start_lie_to_stand()
		BehaviorState.IDLE, BehaviorState.WALKING:
			var spot: Vector2 = _bowl_standing_spot(food_bowl)
			if not has_movement_target or movement_target.distance_to(spot) > arrival_distance:
				set_movement_target(spot)
	return true


func _bowl_standing_spot(bowl: FoodBowl) -> Vector2:
	var left: Vector2 = bowl.global_position + Vector2(-bowl_standing_offset.x, bowl_standing_offset.y)
	var right: Vector2 = bowl.global_position + bowl_standing_offset
	var rect: Rect2 = _get_walk_rect()
	if rect.has_point(left):
		return left
	if rect.has_point(right):
		return right
	return Vector2(INF, INF)


func _find_food_bowl() -> FoodBowl:
	var closest: FoodBowl
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group(&"food_bowls"):
		var bowl := node as FoodBowl
		if bowl == null or not bowl.is_visible_in_tree() or not bowl.can_claim(self):
			continue
		# Nur Näpfe im selben Raum berücksichtigen.
		if bowl.get_parent() != get_parent():
			continue
		var spot: Vector2 = _bowl_standing_spot(bowl)
		if not spot.is_finite():
			continue
		var distance: float = global_position.distance_squared_to(spot)
		if distance < best_distance:
			closest = bowl
			best_distance = distance
	return closest


func _release_food_reservation() -> void:
	if is_instance_valid(food_bowl):
		food_bowl.release_meal(self)
	_resuming_meal = false


func _exit_tree() -> void:
	_release_food_reservation()


func _finish_feeding() -> void:
	_release_food_reservation()
	_meal_consumed_food = 0.0
	_resuming_meal = false
	food_bowl = null
	behavior_state = BehaviorState.IDLE
	has_movement_target = false
	velocity = Vector2.ZERO
	seeking_food = satiety <= hungry_threshold
	food_status.text = "Hungrig" if seeking_food else ""
	_start_wander_pause()
	feeding_finished.emit()
	RoomManager.save_game()


func export_food_state() -> Dictionary:
	var meal: Dictionary = {}
	if is_instance_valid(food_bowl) and food_bowl.has_reservation(self):
		if is_instance_valid(food_bowl) and food_bowl.placed_item_data != null:
			meal = {"bowl_id": food_bowl.placed_item_data.instance_id,
				"start_satiety": _meal_start_satiety, "consumed": _meal_consumed_food,
				"total": _meal_total_food, "travelling": behavior_state != BehaviorState.EATING,
				"target": [get_parent().to_local(_bowl_standing_spot(food_bowl)).x,
					get_parent().to_local(_bowl_standing_spot(food_bowl)).y]}
			if behavior_state != BehaviorState.EATING and not _resuming_meal:
				meal["consumed"] = 0.0
				meal["total"] = FoodBowl.MEAL_SIZE
				meal["start_satiety"] = satiety
	elif not pending_meal_restore.is_empty():
		meal = pending_meal_restore.duplicate(true)
	return {"id": pet_id, "satiety": satiety, "position": [position.x, position.y], "meal": meal,
		"affection": affection, "affection_loss_per_second": affection_loss_per_second,
		"satiety_loss_per_second": satiety_loss_per_second, "hungry_threshold": hungry_threshold,
		"eating_per_second": eating_per_second, "movement_speed": movement_speed,
		"bowl_offset": [-bowl_standing_offset.x, bowl_standing_offset.y]}


func _try_resume_meal() -> void:
	if pending_meal_restore.is_empty():
		return
	var record: Dictionary = pending_meal_restore
	pending_meal_restore = {}
	var total_value: Variant = record.get("total", FoodBowl.MEAL_SIZE)
	var consumed_value: Variant = record.get("consumed", 0.0)
	var start_value: Variant = record.get("start_satiety", satiety)
	if not (total_value is float or total_value is int) or not (consumed_value is float or consumed_value is int) or not (start_value is float or start_value is int):
		return
	var total: float = float(total_value)
	var consumed: float = float(consumed_value)
	if not is_finite(total) or not is_finite(consumed) or not is_finite(float(start_value)):
		return
	if total <= 0.0 or total > FoodBowl.MEAL_SIZE or consumed < 0.0 or consumed >= total:
		return
	for node in get_parent().get_children():
		if not node is FoodBowl or node.placed_item_data == null:
			continue
		if node.placed_item_data.instance_id != str(record.get("bowl_id", "")):
			continue
		if not node.reserve_meal(self, total - consumed):
			return
		food_bowl = node
		_meal_total_food = total
		_meal_consumed_food = consumed
		_meal_start_satiety = clampf(float(start_value), 0.0, 100.0)
		_resuming_meal = consumed > 0.0 or not record.get("travelling", false)
		seeking_food = true
		set_movement_target(_bowl_standing_spot(food_bowl))
		return


func set_affection(value: float) -> void:
	var next: float = clampf(value, 0.0, 100.0)
	if next != affection:
		affection = next
		affection_changed.emit(affection)


func _update_affection(delta: float) -> void:
	var change: float = maxf(affection_gain_per_second, 0.0) if is_being_petted else -maxf(affection_loss_per_second, 0.0)
	set_affection(affection + change * maxf(delta, 0.0))


func get_satisfaction() -> float:
	var clean: float = float(get_node("/root/RoomManager").get("room_cleanliness"))
	return clampf((satiety + affection + clean) / 3.0, 0.0, 100.0)


func set_petting(active: bool) -> void:
	if active == is_being_petted:
		return
	is_being_petted = active
	if active:
		_petting_timer_remaining = wander_timer.time_left if not wander_timer.is_stopped() else -1.0
		wander_timer.stop()
	elif _petting_timer_remaining > 0.0:
		wander_timer.start(maxf(_petting_timer_remaining, 0.1))
		_petting_timer_remaining = -1.0
