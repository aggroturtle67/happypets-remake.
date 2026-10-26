extends Node

signal coins_changed(new_value: int)
signal xp_changed(current_value: int, required_value: int)
signal level_changed(new_value: int)
signal care_reward_credited(event_id: int, care_kind: StringName, source: Node2D, coins: int, xp: int)

const CareRewards = preload("res://scripts/managers/care_rewards.gd")
var coins: int = 100
var current_xp: int = 0
var level: int = 1
var required_xp: int = 20
var _progress: Dictionary = CareRewards.normalize({})
var _care_event_id: int = 0

func _ready() -> void:
	# RoomManager loads and checkpoints offline rewards before this autoload is ready.
	restore_progress(get_node("/root/RoomManager").get("progress_state"))

func change_coins(amount: int) -> void:
	# Only credited whole coins can be spent; care remainders remain untouched.
	_progress["coins"] = maxi(int(_progress["coins"]) + amount, 0)
	_sync_coins()

func add_xp(amount: int) -> void:
	CareRewards.add_xp(_progress, float(amount))
	_sync_xp()

func award_care(restored_points: float, care_kind: StringName = &"food", source: Node2D = null) -> void:
	if not is_finite(restored_points) or restored_points <= 0.0:
		return
	var coins_before: int = int(_progress["coins"])
	var xp_before: int = int(_progress["total_xp"])
	CareRewards.add_points(_progress, restored_points, care_kind)
	# Capture care-only differences before any observer can grant, for example,
	# an unrelated level-up bonus from coins_changed/level_changed/xp_changed.
	var coin_gain: int = int(_progress["coins"]) - coins_before
	var xp_gain: int = int(_progress["total_xp"]) - xp_before
	# Save before UI observers too: a level-up listener may change the scene.
	# export_progress mirrors this public value, so synchronize it without emitting.
	coins = int(_progress["coins"])
	if coin_gain > 0 or xp_gain > 0:
		get_node("/root/RoomManager").save_game()
	_sync_coins()
	_sync_xp()
	if coin_gain <= 0 and xp_gain <= 0:
		return
	# Collection has no economy callback. A removed source needs no visual replay.
	if is_instance_valid(source) and source.is_inside_tree():
		_care_event_id += 1
		care_reward_credited.emit(_care_event_id, care_kind, source, coin_gain, xp_gain)

func export_progress() -> Dictionary:
	_progress["coins"] = coins
	return _progress.duplicate(true)

func restore_progress(record: Variant) -> void:
	_progress = CareRewards.normalize(record)
	_sync_coins()
	_sync_xp()

func _sync_coins() -> void:
	coins = int(_progress["coins"])
	coins_changed.emit(coins)

func _sync_xp() -> void:
	var state: Dictionary = CareRewards.position(_progress)
	var previous_level: int = level
	level = int(state["level"])
	current_xp = int(state["current_xp"])
	required_xp = int(state["required_xp"])
	if level != previous_level:
		level_changed.emit(level)
	xp_changed.emit(current_xp, required_xp)
