extends Control


@onready var coin_display: CoinDisplay = (
	$Background/SafeMargin/MainRow/CenterSlot
	/CoinDisplay
)

@onready var level_display: LevelDisplay = (
	$Background/SafeMargin/MainRow/LeftSlot
	/LevelDisplay
)


func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.xp_changed.connect(_on_xp_changed)

	_on_coins_changed(GameManager.coins)
	_on_level_changed(GameManager.level)
	_on_xp_changed(
		GameManager.current_xp,
		GameManager.required_xp
	)


func _on_coins_changed(new_value: int) -> void:
	coin_display.set_coin_amount(new_value)


func _on_level_changed(new_value: int) -> void:
	level_display.set_level(new_value)


func _on_xp_changed(
	current_value: int,
	required_value: int
) -> void:
	level_display.set_xp_progress(
		current_value,
		required_value
	)
