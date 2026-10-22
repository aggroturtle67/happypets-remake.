extends HBoxContainer
class_name CoinDisplay

@onready var coin_amount_label: Label = $CoinAmount


func _ready() -> void:
	set_coin_amount(0)


func set_coin_amount(amount: int) -> void:
	coin_amount_label.text = _format_number(maxi(amount, 0))


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
