extends CanvasLayer
## Renders receipts from GameManager. Hover never grants currency or XP.
const Config = preload("res://scripts/ui/rewards/reward_effects_settings.gd")
const ValuePlan = preload("res://scripts/ui/rewards/reward_value_plan.gd")
const TokenScene = preload("res://scenes/UI/rewards/reward_token.tscn")
const Plus = preload("res://scripts/ui/rewards/reward_plus.gd")
@export var settings: Config = preload("res://data/UI/reward_effects.tres")
@export_node_path("Control") var topbar_path: NodePath = NodePath("../TopBar2")
@export_node_path("Control") var coin_target_path: NodePath = NodePath("../TopBar2/Background/SafeMargin/MainRow/LeftSlot/CoinDisplay")
@export_node_path("Control") var xp_target_path: NodePath = NodePath("../TopBar2/Background/SafeMargin/MainRow/LeftSlot/LevelDisplay/XPBarContainer/XPBar")

var _surface: Control
var _hud: Control
var _room: WeakRef
var _coin_target: Control
var _xp_target: Control
var _topbar: Control
var _coin_plus: Label
var _xp_plus: Label
var _rng := RandomNumberGenerator.new()
var _last_event_id: int = 0
var _batches: Dictionary = {}
var _queue: Array[Dictionary] = []
var _tokens: Array[Control] = []
var _occupied: Dictionary = {}
var _blocked_rects: Array[Rect2] = []
var _pulses: Dictionary = {}
var _target_cache_frame: int = -1
var _target_positions: Dictionary = {}
var _spawn_elapsed: float = 0.0
var received_totals: Dictionary = {&"coins": 0, &"xp": 0}

func _ready() -> void:
	layer = 30
	_rng.randomize()
	_hud = get_parent() as Control
	if _hud == null or settings == null:
		push_warning("CareRewardPresenter benoetigt ein HUD-Control und reward_effects-Einstellungen.")
		set_process(false)
		return
	_room = weakref(get_node("/root/RoomManager").get("active_room"))
	_surface = Control.new()
	_surface.name = "Surface"
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_surface)
	_topbar = get_node_or_null(topbar_path)
	if _topbar == null:
		_topbar = _hud.find_child("TopBar", true, false)
	if is_instance_valid(_topbar):
		_coin_target = get_node_or_null(coin_target_path)
		_xp_target = get_node_or_null(xp_target_path)
		if _coin_target == null:
			_coin_target = _topbar.find_child("CoinDisplay", true, false)
		if _xp_target == null:
			_xp_target = _topbar.find_child("XPBar", true, false)
	_coin_plus = _make_plus(&"coins")
	_xp_plus = _make_plus(&"xp")
	get_node("/root/GameManager").care_reward_credited.connect(_on_care_reward)

func _make_plus(kind: StringName) -> Label:
	var label: Label = Plus.new()
	label.currency = kind
	label.hold_duration = settings.plus_duration
	label.fade_duration = settings.plus_fade
	_surface.add_child(label)
	return label

func _on_care_reward(event_id: int, kind: StringName, source: Node2D, coins: int, xp: int) -> void:
	# IDs increase across the autoload's lifetime, including scene changes.
	if event_id <= _last_event_id:
		return
	_last_event_id = event_id
	if not settings.is_complete() or not is_instance_valid(source) or not source.is_inside_tree():
		return
	if not kind in [&"food", &"clean", &"pet"] or coins < 0 or xp < 0 or (coins == 0 and xp == 0):
		return
	var key: String = "%d:%s" % [source.get_instance_id(), kind]
	var local_offset: Vector2 = Vector2(0, -150) if kind == &"pet" else Vector2(0, -45)
	var point: Vector2 = source.get_global_transform() * local_offset
	if not _batches.has(key):
		_batches[key] = {"source": weakref(source), "offset": local_offset, "origin": point,
			"coins": 0, "xp": 0, "quiet": 0.0, "age": 0.0,
			"sent_coins": 0, "sent_xp": 0}
	var batch: Dictionary = _batches[key]
	batch.coins += coins
	batch.xp += xp
	batch.quiet = 0.0
	batch.origin = point
	# Display earned value in the signal's frame, including every cleaning click.
	_refresh_placement()
	_enqueue(batch)
	_drain_queue()

func _refresh_placement() -> void:
	_refresh_obstacles()
	for index in range(_tokens.size() - 1, -1, -1):
		if not is_instance_valid(_tokens[index]) or _tokens[index].is_queued_for_deletion():
			_tokens.remove_at(index)
	_occupied.clear()
	for token in _tokens:
		if token.phase == token.Phase.FLYING or token.phase == token.Phase.LANDED:
			_occupy(_world_to_surface(token.landing_world))

func _drain_queue() -> void:
	while not _queue.is_empty():
		if not _spawn_next():
			# An off-screen source has no valid visible landing. Its earned value
			# is already saved; never replay a stale visual after moving the camera.
			_queue.pop_front()

func _process(delta: float) -> void:
	_refresh_placement()
	for key in _batches.keys():
		var batch: Dictionary = _batches[key]
		batch.quiet += delta
		batch.age += delta
		var finished: bool = batch.quiet >= settings.stream_quiet_time
		if finished:
			_batches.erase(key)
	var mouse: Vector2 = _surface.get_local_mouse_position()
	if not _over_hud(mouse):
		for token in _tokens:
			token.try_collect(mouse)
	_place_plus(_coin_plus, _coin_target)
	_place_plus(_xp_plus, _xp_target)

func _enqueue(batch: Dictionary) -> void:
	for kind in [&"coins", &"xp"]:
		var amount: int = int(batch[kind])
		if amount <= 0:
			continue
		var sent_key: String = "sent_%s" % kind
		var sent: int = int(batch[sent_key])
		# Pair with a visible single instead of withholding the newly earned point.
		# The first two singles in each stream stay single for the desired mixture.
		for token in _tokens:
			if amount <= 0:
				break
			if token.currency == kind and token.get_meta("pairable", false) and token.get_meta("stream", null) == batch.source:
				if token.upgrade_to_double():
					amount -= 1
					batch[kind] -= 1
					batch[sent_key] += 1
		var plan: Dictionary
		if sent == 0 and amount >= 6:
			plan = ValuePlan.build(amount, _rng)
		else:
			# No remainder waits for a timeout: an odd earned point appears now.
			var singles: int = mini(amount, maxi(0, 2 - sent))
			var doubles: int = int((amount - singles) / 2)
			singles += (amount - singles) % 2
			plan = {"singles": singles, "doubles": doubles}
		var queued: int = int(plan.singles) + 2 * int(plan.doubles)
		if queued <= 0:
			continue
		batch[kind] -= queued
		batch[sent_key] += queued
		_queue.append({"kind": kind, "plan": plan, "source": batch.source,
			"offset": batch.offset, "origin": batch.origin, "protect": maxi(0, 2 - sent)})

func _spawn_next() -> bool:
	if not is_instance_valid(_coin_target) or not is_instance_valid(_xp_target):
		return false
	var entry: Dictionary = _queue[0]
	var source: Node2D = entry.source.get_ref()
	var start: Vector2 = entry.origin
	if is_instance_valid(source) and source.is_inside_tree():
		start = source.get_global_transform() * Vector2(entry.offset)
	# The floor radius is measured around the object, not its elevated emitter.
	var anchor: Vector2 = source.global_position if is_instance_valid(source) else start - Vector2(entry.offset)
	var landing: Vector2 = _find_landing(_world_to_surface(anchor), _source_rect(source))
	if not landing.is_finite():
		landing = _find_landing(_world_to_surface(anchor), _source_rect(source), true)
	if not landing.is_finite():
		return false
	var value: int = ValuePlan.take(entry.plan, _rng)
	var token: Control = TokenScene.instantiate()
	token.set_meta("stream", entry.source)
	var protect: bool = value == 1 and int(entry.get("protect", 0)) > 0
	if protect:
		entry.protect -= 1
	token.set_meta("pairable", value == 1 and not protect)
	var jump: Vector2 = _surface_to_world(landing + Vector2(0, settings.jump_height)) - _surface_to_world(landing)
	token.setup(settings, entry.kind, value, start, _surface_to_world(landing), jump,
		_world_to_surface, _target_center.bind(entry.kind), _rng.randi())
	token.received.connect(_on_received)
	_surface.add_child(token)
	_tokens.append(token)
	_occupy(landing)
	_queue.pop_front()
	if int(entry.plan.singles) + int(entry.plan.doubles) > 0:
		_queue.append(entry) # Interleave XP/coins and concurrent actions fairly.
	return true

func _spacing() -> float:
	return maxf(20.0, settings.maximum_symbol_size() * settings.spacing_factor + settings.symbol_gap)

func _occupy(point: Vector2) -> void:
	var spacing: float = _spacing()
	var cell := Vector2i(floor(point.x / spacing), floor(point.y / spacing))
	if not _occupied.has(cell):
		_occupied[cell] = []
	_occupied[cell].append(point)

func _has_space(point: Vector2) -> bool:
	var spacing: float = _spacing()
	var cell := Vector2i(floor(point.x / spacing), floor(point.y / spacing))
	# Spatial buckets preserve exact distance checks despite random placement,
	# camera motion and viewport changes, without all-pairs scans.
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			for other in _occupied.get(Vector2i(x, y), []):
				if point.distance_squared_to(Vector2(other)) < spacing * spacing:
					return false
	return true

func _find_landing(origin: Vector2, source_rect: Rect2 = Rect2(), relaxed: bool = false) -> Vector2:
	var rect: Rect2 = _safe_rect()
	var spacing: float = _spacing()
	var half: float = settings.maximum_symbol_size() * 0.5
	var best := Vector2(INF, INF)
	var best_score: float = INF
	var preferred: float = maxf(15.0, settings.flight_distance + _rng.randf_range(-settings.scatter, settings.scatter))
	# Stable grid cells make spacing reliable across simultaneous and large bursts.
	for y in range(int(ceil(rect.position.y / spacing)), int(floor(rect.end.y / spacing))):
		for x in range(int(ceil(rect.position.x / spacing)), int(floor(rect.end.x / spacing))):
			var cell := Vector2i(x, y)
			if not relaxed and _occupied.has(cell):
				continue
			var jitter: float = spacing * 0.23
			var point: Vector2 = (Vector2(cell) + Vector2.ONE * 0.5) * spacing + Vector2(_rng.randf_range(-jitter, jitter), _rng.randf_range(-jitter, jitter))
			if origin.distance_squared_to(point) > settings.landing_radius * settings.landing_radius:
				continue # A full local area queues receipts; never spill across the room.
			if not rect.grow(-half).has_point(point) or _over_hud(point, half):
				continue
			if not relaxed and not _has_space(point):
				continue
			if source_rect.has_area() and source_rect.grow(half * 0.15 if relaxed else half + 6.0).has_point(point):
				continue
			var score: float = absf(origin.distance_to(point) - preferred) + _rng.randf_range(0, settings.scatter)
			if score < best_score:
				best_score = score
				best = point
	return best

func _safe_rect() -> Rect2:
	var viewport: Rect2 = get_viewport().get_visible_rect()
	var inverse: Transform2D = _surface.get_global_transform_with_canvas().affine_inverse()
	var start: Vector2 = inverse * viewport.position
	var end: Vector2 = inverse * viewport.end
	var rect := Rect2(start, end - start).grow(-12.0)
	if is_instance_valid(_topbar):
		var top: float = maxf(rect.position.y, _control_rect(_topbar).end.y + 12.0)
		rect.size.y -= top - rect.position.y
		rect.position.y = top
	var room: Node2D = _room.get_ref() if _room != null else null
	if settings.land_on_room_floor and is_instance_valid(room):
		var floor_sprite: Sprite2D = room.get_node_or_null("SurfaceLayer/FloorSurface")
		if is_instance_valid(floor_sprite) and floor_sprite.texture != null:
			rect = rect.intersection(_canvas_rect(floor_sprite, floor_sprite.get_rect()))
	return rect

func _source_rect(source: Node2D) -> Rect2:
	if not is_instance_valid(source):
		return Rect2()
	if source.is_in_group(&"cats"):
		return _canvas_rect(source, Rect2(-105, -270, 210, 290))
	var sprite: Sprite2D = source.get_node_or_null("BowlSprite")
	if sprite == null:
		sprite = source.get_node_or_null("BoxSprite")
	if sprite != null and sprite.texture != null:
		var used: Rect2 = Rect2(settings.image_for(sprite.texture).get_used_rect())
		if sprite.centered:
			used.position -= sprite.texture.get_size() * 0.5
		used.position += sprite.offset
		return _canvas_rect(sprite, used)
	return Rect2()

func _refresh_obstacles() -> void:
	_blocked_rects.clear()
	if is_instance_valid(_topbar):
		_blocked_rects.append(_control_rect(_topbar))
	for name in ["ActionPanel", "ShopButton", "CatNeedsPanel"]:
		var control: Control = _hud.get_node_or_null(NodePath(name))
		if is_instance_valid(control) and control.is_visible_in_tree():
			_blocked_rects.append(_control_rect(control))

func _over_hud(point: Vector2, padding: float = 0.0) -> bool:
	for rect in _blocked_rects:
		if rect.grow(padding).has_point(point):
			return true
	return false

func _control_rect(control: Control) -> Rect2:
	return _canvas_rect(control, Rect2(Vector2.ZERO, control.size))

func _canvas_rect(item: CanvasItem, bounds: Rect2) -> Rect2:
	var transform: Transform2D = _surface.get_global_transform_with_canvas().affine_inverse() * item.get_global_transform_with_canvas()
	var rect := Rect2(transform * bounds.position, Vector2.ZERO)
	for corner in [Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]:
		rect = rect.expand(transform * corner)
	return rect

func _world_to_surface(point: Vector2) -> Vector2:
	var room: Node2D = _room.get_ref() if _room != null else null
	if not is_instance_valid(room):
		return point
	return _surface.get_global_transform_with_canvas().affine_inverse() * (room.get_canvas_transform() * point)

func _surface_to_world(point: Vector2) -> Vector2:
	var room: Node2D = _room.get_ref() if _room != null else null
	if not is_instance_valid(room):
		return point
	return room.get_canvas_transform().affine_inverse() * (_surface.get_global_transform_with_canvas() * point)

func _target_center(kind: StringName) -> Vector2:
	# Hundreds of flying particles share only two live targets per frame.
	var frame: int = Engine.get_process_frames()
	if frame != _target_cache_frame:
		_target_cache_frame = frame
		for currency in [&"coins", &"xp"]:
			var control: Control = _coin_target if currency == &"coins" else _xp_target
			_target_positions[currency] = _control_rect(control).get_center() if is_instance_valid(control) else _safe_rect().get_center()
	return _target_positions[kind]

func _on_received(kind: StringName, points: int) -> void:
	if not kind in [&"coins", &"xp"] or points <= 0:
		return
	received_totals[kind] += points
	var plus: Label = _coin_plus if kind == &"coins" else _xp_plus
	plus.add_value(points)
	_pulse(_coin_target if kind == &"coins" else _xp_target)

func _place_plus(label: Label, control: Control) -> void:
	if not label.visible or not is_instance_valid(control):
		return
	var rect: Rect2 = _control_rect(control)
	var viewport: Rect2 = get_viewport().get_visible_rect()
	if control == _coin_target:
		# Keep the temporary coin sum below the amount, clear of the XP bar.
		label.position = Vector2(clampf(rect.get_center().x - label.size.x * 0.5, 8.0, viewport.size.x - label.size.x - 8.0),
			clampf(rect.end.y + 4.0, 4.0, viewport.size.y - label.size.y - 4.0))
		return
	label.position = Vector2(clampf(rect.end.x + 12.0, 8.0, viewport.size.x - label.size.x - 8.0),
		clampf(rect.get_center().y - label.size.y * 0.5, 4.0, viewport.size.y - label.size.y - 4.0))

func _pulse(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var id: int = control.get_instance_id()
	if not _pulses.has(id):
		_pulses[id] = {"node": weakref(control), "scale": control.scale, "pivot": control.pivot_offset, "tween": null}
	var record: Dictionary = _pulses[id]
	if is_instance_valid(record.tween):
		record.tween.kill()
	control.scale = record.scale
	control.pivot_offset = control.size * 0.5
	var tween: Tween = create_tween()
	record.tween = tween
	tween.tween_property(control, "scale", Vector2(record.scale) * (1.0 + settings.ui_pulse), 0.09).set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "scale", record.scale, 0.2).set_trans(Tween.TRANS_SINE)

func _exit_tree() -> void:
	var game: Node = get_node_or_null("/root/GameManager")
	if game != null and game.care_reward_credited.is_connected(_on_care_reward):
		game.care_reward_credited.disconnect(_on_care_reward)
	for record in _pulses.values():
		if is_instance_valid(record.tween):
			record.tween.kill()
		var node: Control = record.node.get_ref()
		if is_instance_valid(node):
			node.scale = record.scale
			node.pivot_offset = record.pivot
