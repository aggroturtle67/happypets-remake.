extends HBoxContainer
class_name CoinDisplay

@onready var coin_amount_label: Label = $CoinAmount


func _ready() -> void:
	set_coin_amount(0)


func set_coin_amount(amount: float) -> void:
	# Only the label is rounded. The saved balance retains all care fractions.
	var parts: PackedStringArray = ("%.2f" % maxf(amount, 0.0)).split(".")
	var text: String = _format_number(int(parts[0]))
	if parts[1] != "00":
		text += "," + parts[1]
	coin_amount_label.text = text


func _format_number(value: int) -> String:
	var number_text := str(value)
	var formatted_text := ""
	var digit_count := 0

	for index in range(number_text.length() - 1, -1, -1):
		if digit_count > 0 and digit_count % 3 == 0:
			formatted_text = " " + formatted_text

		formatted_text = number_text[index] + formatted_text
		digit_count += 1

	return formatted_text
