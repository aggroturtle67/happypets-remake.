extends Control
## One default for current and future UI, including dynamically created labels
## and tooltip popups that are outside the HUD's own theme inheritance.
const HANDWRITING: Font = preload("res://assets/UI/fonts/PatrickHand-Regular.ttf")

func _enter_tree() -> void:
	ThemeDB.get_default_theme().default_font = HANDWRITING
	ThemeDB.fallback_font = HANDWRITING
