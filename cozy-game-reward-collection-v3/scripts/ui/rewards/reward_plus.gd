extends Label
## One independent, restartable accumulator per currency, never an economy writer.
var currency: StringName = &"coins"
var total: int = 0
var hold_duration: float = 1.5
var fade_duration: float = 0.3
var _remaining: float = 0.0
var _fading: bool = false
var _fade: Tween
var _pop: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", Color("a8651e") if currency == &"coins" else Color("397eab"))
	visible = false

func add_value(value: int) -> void:
	if value <= 0:
		return
	if is_instance_valid(_fade):
		_fade.kill()
	if is_instance_valid(_pop):
		_pop.kill()
	# A receipt during fade continues the existing sum, rather than resetting it.
	total += value
	text = "+%d XP" % total if currency == &"xp" else "+%d" % total
	reset_size()
	pivot_offset = size * 0.5
	visible = true
	modulate.a = 1.0
	_fading = false
	_remaining = hold_duration
	scale = Vector2.ONE * 1.06
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not visible or _fading:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_fading = true
		_fade = create_tween()
		_fade.tween_property(self, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
		_fade.tween_callback(_finish_fade)

func _finish_fade() -> void:
	total = 0
	visible = false
	_fading = false
