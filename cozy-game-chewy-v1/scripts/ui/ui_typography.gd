extends Control
## One default for current and future UI, including dynamically created labels
## and tooltip popups that are outside the HUD's own theme inheritance.
const UI_FONT: Font = preload("res://assets/UI/fonts/Chewy-Regular.ttf")

func _enter_tree() -> void:
	ThemeDB.get_default_theme().default_font = UI_FONT
	ThemeDB.fallback_font = UI_FONT
