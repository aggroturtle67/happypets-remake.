extends VBoxContainer
class_name LevelDisplay


@onready var level_number: Label = $LevelRow/LevelNumber
@onready var xp_bar: ProgressBar = $XPBarContainer/XPBar
@onready var heart_marker: TextureRect = (
	$XPBarContainer/XPBar/HeartMarker
)


var level: int = 1
var xp_progress: float = 0.0


func _ready() -> void:
	xp_bar.step = 0.0
	var tooltip_theme := Theme.new()
	tooltip_theme.set_color("font_color", "TooltipLabel", Color("fcedE2"))
	tooltip_theme.set_font_size("font_size", "TooltipLabel", 20)
	xp_bar.theme = tooltip_theme
	# Der Marker wird innerhalb der XPBar frei positioniert.
	heart_marker.set_anchors_preset(
		Control.PRESET_TOP_LEFT,
		true
	)

	xp_bar.resized.connect(_update_heart_position)

	_update_level_label()
	_update_xp_display()

	# Wartet auf die endgültige Größe der UI.
	await get_tree().process_frame
	_update_heart_position()


func set_level(new_level: int) -> void:
	level = maxi(new_level, 1)
	_update_level_label()


func set_xp_progress(
	current_xp: int,
	required_xp: int
) -> void:
	if required_xp <= 0.0:
		xp_progress = 0.0
	else:
		xp_progress = clampf(
			float(current_xp) / float(required_xp),
			0.0,
			1.0
		)

	xp_bar.tooltip_text = "%d / %d XP" % [current_xp, required_xp]
	_update_xp_display()


func _update_level_label() -> void:
	if not is_node_ready():
		return

	level_number.text = str(level)


func _update_xp_display() -> void:
	if not is_node_ready():
		return

	xp_bar.value = xp_progress * xp_bar.max_value
	_update_heart_position.call_deferred()


func _update_heart_position() -> void:
	if not is_node_ready():
		return

	var bar_width: float = xp_bar.size.x
	var marker_width: float = heart_marker.size.x

	var start_x: float = -marker_width * 0.25
	var end_x: float = bar_width - marker_width * 0.75

	# HeartMarker ist ein Kind der XPBar.
	# Seine Position wird deshalb lokal zur XPBar berechnet.
	heart_marker.position.x = lerpf(
		start_x,
		end_x,
		xp_progress
	)
