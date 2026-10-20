extends Control

const State = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/room.gd")
const GREEN := Color("376b52")
const INK := Color("35473d")
const MUTED := Color("8d9884")
const PAPER := Color("fffef8")

var game := State.new()
var room: PetRoom
var coin_label: Label
var level_label: Label
var name_label: Label
var species_label: Label
var pet_picture: TextureRect
var pet_count: Label
var save_label: Label
var edit_button: Button
var gift_button: Button
var editing_bar: HBoxContainer
var edit_label: Label
var roster: HBoxContainer
var quest_list: VBoxContainer
var need_bars: Dictionary = {}
var need_values: Dictionary = {}
var buttons: Dictionary = {}
var toast: PanelContainer
var toast_label: Label
var toast_timer: Timer
var active_popup: PopupPanel
var can_save := true

func _ready() -> void:
	get_tree().auto_accept_quit = false
	can_save = game.load_game()
	_build_theme()
	_build_ui()
	_refresh()
	var timer := Timer.new()
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(func():
		game.advance_time()
		_persist()
		_refresh())
	add_child(timer)
	if not game.last_error.is_empty():
		notify(game.last_error)
	elif not game.recovery_message.is_empty():
		notify(game.recovery_message)
	else:
		_persist()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_persist()
		get_tree().quit()

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", GREEN)
	theme.set_color("font_disabled_color", "Button", Color("a5ae99"))
	theme.set_stylebox("normal", "Button", _style(Color("f0f3e7"), 9, Color("dfe6d2")))
	theme.set_stylebox("hover", "Button", _style(Color("e3ecd7"), 9, Color("afc299")))
	theme.set_stylebox("pressed", "Button", _style(Color("d8e5c9"), 9, Color("8ca776")))
	theme.set_stylebox("disabled", "Button", _style(Color("eeefe5"), 9))
	theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), 9, Color("9fb88c"), 2))
	theme.set_stylebox("panel", "PopupPanel", _style(PAPER, 16, Color("dce3cf")))
	theme.set_stylebox("normal", "LineEdit", _style(Color("fbfcf3"), 8, Color("bcccaa")))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", GREEN)
	var bar_background := _style(Color("edf0e3"), 4)
	bar_background.set_content_margin_all(0)
	theme.set_stylebox("background", "ProgressBar", bar_background)

func _style(color: Color, radius: int = 10, border: Color = Color.TRANSPARENT, width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.border_color = border
	box.set_border_width_all(width if border.a > 0 else 0)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _label(text: String, font_size: int = 15, color: Color = INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result

func _button(text: String, action: Callable, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 37
	result.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	result.pressed.connect(action)
	if primary:
		result.add_theme_stylebox_override("normal", _style(GREEN, 8))
		result.add_theme_stylebox_override("hover", _style(Color("28583f"), 8))
		result.add_theme_stylebox_override("pressed", _style(Color("204e37"), 8))
		result.add_theme_color_override("font_color", PAPER)
		result.add_theme_color_override("font_hover_color", PAPER)
		result.add_theme_color_override("font_pressed_color", PAPER)
	return result

func _vbox(spacing: int = 10) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", spacing)
	return box

func _hbox(spacing: int = 10) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", spacing)
	return box

func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

func _card(color: Color = PAPER, padding: int = 16) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(color, 13, Color("e0e5d7"))
	style.set_content_margin_all(padding)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _picture(art: String, minimum: Vector2) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(_art_resource(art))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = minimum
	picture.mouse_filter = MOUSE_FILTER_IGNORE
	return picture

func _art_resource(art: String) -> String:
	return "res://assets/cat_portrait.png" if art == "cat" else "res://assets/" + art + ".svg"

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var page := _vbox(14)
	margin.add_child(page)
	var header := _hbox(15)
	page.add_child(header)
	header.add_child(_picture("icon", Vector2(43, 43)))
	var brand := _vbox(1)
	header.add_child(brand)
	brand.add_child(_label("pfotenstube", 27, GREEN))
	brand.add_child(_label("DEIN KLEINES HAUSTIERGLÜCK", 9, MUTED))
	header.add_child(_spacer())
	level_label = _label("", 13, MUTED)
	header.add_child(level_label)
	coin_label = _label("", 18, Color("9e834e"))
	coin_label.custom_minimum_size.x = 130
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(coin_label)
	gift_button = _button("Geschenk +75", func(): _apply(game.claim_gift()))
	buttons.gift = gift_button
	header.add_child(gift_button)
	header.add_child(_button("Hilfe", show_help))
	page.add_child(HSeparator.new())
	var welcome := _hbox()
	page.add_child(welcome)
	var greeting := _vbox(3)
	welcome.add_child(greeting)
	greeting.add_child(_label("Schön, dass du da bist.", 28))
	greeting.add_child(_label("Deine kleinen Lieblinge haben dich schon vermisst.", 13, MUTED))
	welcome.add_child(_spacer())
	var adopt_button := _button("♥  Tier adoptieren", func(): show_shop("pets"), true)
	buttons.shop = adopt_button
	welcome.add_child(adopt_button)
	welcome.add_child(_button("Einrichtung", func(): show_shop("decor")))

	var body := _hbox(20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	var left := _vbox(9)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var title := _hbox()
	left.add_child(title)
	title.add_child(_label("Dein kleines Zuhause", 18))
	pet_count = _label("", 12, MUTED)
	title.add_child(pet_count)
	title.add_child(_spacer())
	title.add_child(_button("Möbellager", show_inventory))
	edit_button = _button("Einrichten", func():
		room.set_editing(not room.editing)
		_refresh())
	buttons.edit = edit_button
	title.add_child(edit_button)
	var room_card := _card(Color("fffdf4"), 5)
	room_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(room_card)
	room = Room.new()
	room.game = game
	room.custom_minimum_size = Vector2(0, 330)
	room.pet_clicked.connect(_on_pet_clicked)
	room.furniture_changed.connect(func():
		_persist()
		_refresh())
	room.furniture_selected.connect(func(_id: String): _refresh_edit_bar())
	room_card.add_child(room)
	editing_bar = _hbox(8)
	left.add_child(editing_bar)
	edit_label = _label("Möbel auswählen und ziehen", 12, MUTED)
	edit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	editing_bar.add_child(edit_label)
	editing_bar.add_child(_button("Drehen", func(): _furniture_action("flip")))
	editing_bar.add_child(_button("Einlagern", func(): _furniture_action("store")))
	editing_bar.add_child(_button("Fertig", func():
		room.set_editing(false)
		_refresh(), true))
	save_label = _label("", 11, MUTED)
	left.add_child(save_label)
	var roster_heading := _hbox()
	left.add_child(roster_heading)
	roster_heading.add_child(_label("Deine Mitbewohner", 17))
	roster_heading.add_child(_spacer())
	roster_heading.add_child(_label("Kleine Persönlichkeiten. Große Liebe.", 11, MUTED))
	var roster_scroll := ScrollContainer.new()
	roster_scroll.custom_minimum_size.y = 104
	roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(roster_scroll)
	roster = _hbox(10)
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_scroll.add_child(roster)

	var side_scroll := ScrollContainer.new()
	side_scroll.custom_minimum_size.x = 285
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(side_scroll)
	var sidebar := _vbox(14)
	sidebar.custom_minimum_size.x = 275
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.add_child(sidebar)
	var care_card := _card()
	sidebar.add_child(care_card)
	var care_box := _vbox(8)
	care_card.add_child(care_box)
	var detail_heading := _hbox()
	care_box.add_child(detail_heading)
	detail_heading.add_child(_label("●  DEIN LIEBLING", 10, MUTED))
	detail_heading.add_child(_spacer())
	var rename := _button("Name", show_rename)
	rename.custom_minimum_size.y = 28
	rename.add_theme_font_size_override("font_size", 11)
	detail_heading.add_child(rename)
	pet_picture = _picture("cat", Vector2(0, 88))
	care_box.add_child(pet_picture)
	name_label = _label("", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	care_box.add_child(name_label)
	species_label = _label("", 11, MUTED)
	species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	care_box.add_child(species_label)
	for spec in [["hunger", "Satt", "93ad7d"], ["joy", "Glücklich", "d9ad6b"], ["clean", "Sauber", "95b3bf"]]:
		var section := _vbox(4)
		care_box.add_child(section)
		var line := _hbox()
		section.add_child(line)
		line.add_child(_label(spec[1], 12, MUTED))
		line.add_child(_spacer())
		var value := _label("", 11, MUTED)
		need_values[spec[0]] = value
		line.add_child(value)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 6
		bar.show_percentage = false
		var bar_fill := _style(Color(spec[2]), 4)
		bar_fill.set_content_margin_all(0)
		bar.add_theme_stylebox_override("fill", bar_fill)
		need_bars[spec[0]] = bar
		section.add_child(bar)
	care_box.add_child(HSeparator.new())
	var actions := _hbox(6)
	care_box.add_child(actions)
	for spec in [["feed", "Füttern\n−8 Münzen"], ["play", "Spielen\n+12 Münzen"], ["clean", "Pflegen\n+10 Münzen"]]:
		var action: String = spec[0]
		var button := _button(spec[1], func(): _do_care(action))
		button.custom_minimum_size.y = 56
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		buttons[action] = button
		actions.add_child(button)
	var tip := _label("Gute Pflege schenkt euch beiden Glück.", 10, MUTED)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	care_box.add_child(tip)
	var quest_card := _card(Color("eff2e6"), 14)
	sidebar.add_child(quest_card)
	var quests := _vbox(12)
	quest_card.add_child(quests)
	quests.add_child(_label("Kleine Tagesziele", 16))
	quests.add_child(_label("Ein bisschen Fürsorge lohnt sich.", 11, MUTED))
	quest_list = _vbox(9)
	quests.add_child(quest_list)
	var footer := _hbox()
	page.add_child(footer)
	footer.add_child(_label("♥  Ein kleines Spiel zum Runterkommen. Mach’s dir gemütlich.", 11, MUTED))
	footer.add_child(_spacer())
	footer.add_child(_label("Esc: Fenster schließen · F11: Vollbild", 10, MUTED))
	_build_toast()

func _build_toast() -> void:
	toast = _card(Color("fffbea"), 13)
	toast.z_index = 200
	toast.visible = false
	toast_label = _label("", 14, GREEN)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_child(toast_label)
	add_child(toast)
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 1.0
	toast.anchor_bottom = 1.0
	toast.offset_left = -360
	toast.offset_right = 360
	toast.offset_top = -76
	toast.offset_bottom = -24
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 4.5
	toast_timer.timeout.connect(func(): toast.hide())
	add_child(toast_timer)

func notify(message: String) -> void:
	toast_label.text = message
	toast.show()
	toast_timer.start()

func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _refresh() -> void:
	if not is_instance_valid(coin_label):
		return
	coin_label.text = str(int(game.data.coins)) + " Münzen"
	level_label.text = "★ Level " + str(game.level()) + "  ·  " + str(int(game.data.xp) % 100) + "/100 XP"
	pet_count.text = str(game.data.pets.size()) + " / 6 Tiere"
	gift_button.disabled = game.data.gift_date == game.date_key(Time.get_unix_time_from_system())
	gift_button.text = "Geschenk abgeholt" if gift_button.disabled else "Geschenk +75"
	var pet := game.selected_pet()
	name_label.text = str(pet.name) + "  ♥"
	species_label.text = str(State.SPECIES[pet.species]) + " · Fühlt sich bei dir zu Hause"
	pet_picture.texture = load(_art_resource(str(pet.art)))
	for key in ["hunger", "joy", "clean"]:
		need_bars[key].value = float(pet[key])
		need_values[key].text = str(roundi(float(pet[key]))) + " / 100"
	_clear(roster)
	for item in game.data.pets:
		var id: String = item.id
		var button := _button("", func():
			game.data.selected = id
			_persist()
			_refresh())
		button.custom_minimum_size = Vector2(145, 98)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = str(item.name) + " auswählen"
		if id == game.data.selected:
			button.add_theme_stylebox_override("normal", _style(Color("e9f0dd"), 10, Color("a4b98d")))
		roster.add_child(button)
		var row := _hbox(5)
		row.mouse_filter = MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.offset_right = -8
		button.add_child(row)
		row.add_child(_picture(str(item.art), Vector2(64, 82)))
		var text := _vbox(4)
		text.mouse_filter = MOUSE_FILTER_IGNORE
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(text)
		var display_name: String = str(item.name)
		if display_name.length() > 9:
			display_name = display_name.substr(0, 8) + "…"
		text.add_child(_label(display_name, 14))
		text.add_child(_label(str(State.SPECIES[item.species]), 10, MUTED))
	if game.data.pets.size() < State.MAX_PETS:
		var add := _button("+\nNeuer Freund", func(): show_shop("pets"))
		add.custom_minimum_size = Vector2(120, 98)
		add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roster.add_child(add)
	_clear(quest_list)
	for quest in State.QUESTS:
		var key: String = quest.id
		var row := _hbox(6)
		quest_list.add_child(row)
		var done: bool = int(game.data.quests.progress[key]) > 0
		var claimed: bool = key in game.data.quests.claimed
		row.add_child(_label(("✓  " if done else "○  ") + str(quest.title), 12, MUTED))
		row.add_child(_spacer())
		var reward := _button("✓" if claimed else "+" + str(quest.reward), func(): _apply(game.claim_quest(key)))
		reward.custom_minimum_size.y = 26
		reward.add_theme_font_size_override("font_size", 11)
		reward.disabled = not done or claimed
		row.add_child(reward)
	room.refresh()
	_refresh_edit_bar()

func _refresh_edit_bar() -> void:
	editing_bar.visible = room.editing
	edit_button.text = "Fertig" if room.editing else "Einrichten"
	edit_label.text = "Möbel auswählen und ziehen"
	for item in game.data.furniture:
		if item.id == room.selected_furniture:
			for catalog in State.DECOR:
				if catalog.kind == item.kind:
					edit_label.text = str(catalog.name)

func _persist() -> bool:
	if not is_instance_valid(save_label):
		return false
	if not can_save:
		save_label.text = "Speichern gesperrt: beschädigten Spielstand zuerst sichern."
		return false
	var ok := game.save_game()
	save_label.text = "✓  Spielstand auf diesem PC gespeichert" if ok else "!  " + game.last_error
	return ok

func _apply(result: Dictionary) -> bool:
	if result.ok:
		_persist()
	_refresh()
	notify(str(result.message))
	return bool(result.ok)

func _do_care(action: String, pet_id: String = "") -> void:
	var result := game.care(action, pet_id)
	if _apply(result):
		var messages := {"feed": "Mmmh! ♥", "play": "Juhuu! ✦", "clean": "Blitzblank!", "pet": "Hab dich lieb! ♥"}
		var id: String = game.data.selected
		if room.actors.has(id):
			room.actors[id].react(messages[action])
			room.actors[id].play_action(action)

func _on_pet_clicked(id: String) -> void:
	_do_care("pet", id)

func _furniture_action(action: String) -> void:
	if room.selected_furniture.is_empty():
		notify("Wähle zuerst ein Möbelstück im Zimmer aus.")
		return
	for item in game.data.furniture:
		if item.id == room.selected_furniture:
			if action == "flip":
				item.flipped = not item.flipped
			else:
				item.placed = false
				room.selected_furniture = ""
				notify("Im Möbellager verstaut. Du kannst es jederzeit wieder aufstellen.")
	_persist()
	_refresh()

func _close_popup() -> void:
	if is_instance_valid(active_popup):
		active_popup.hide()
		active_popup.queue_free()
	active_popup = null

func _popup(title: String, popup_size: Vector2i) -> VBoxContainer:
	_close_popup()
	active_popup = PopupPanel.new()
	active_popup.name = "GameDialog"
	active_popup.theme = theme
	add_child(active_popup)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	active_popup.add_child(margin)
	var box := _vbox(16)
	margin.add_child(box)
	var header := _hbox(14)
	box.add_child(header)
	header.add_child(_label(title, 23))
	header.add_child(_spacer())
	header.add_child(_button("×", _close_popup))
	active_popup.popup_centered(popup_size)
	return box

func show_shop(category: String) -> void:
	var box := _popup("Ein kleines Stück mehr Zuhause.", Vector2i(800, 630))
	var tabs := _hbox()
	box.add_child(tabs)
	tabs.add_child(_button("Tiere adoptieren", func(): show_shop("pets"), category == "pets"))
	tabs.add_child(_button("Einrichtung", func(): show_shop("decor"), category == "decor"))
	tabs.add_child(_spacer())
	tabs.add_child(_label(str(int(game.data.coins)) + " Münzen", 16, Color("a28b52")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(752, 430)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var catalog: Array = State.PETS if category == "pets" else State.DECOR
	for item in catalog:
		var card := _card(Color("f3f4e9"), 10)
		card.custom_minimum_size.x = 174
		grid.add_child(card)
		var content := _vbox(9)
		card.add_child(content)
		var art: String = item.id if category == "pets" else item.kind
		content.add_child(_picture(art, Vector2(150, 135)))
		content.add_child(_label(str(item.name), 13))
		if category == "pets":
			content.add_child(_label(str(State.SPECIES[item.species]), 11, MUTED))
		var item_id: String = art
		var locked: bool = category == "pets" and game.level() < int(item.level)
		var text := "Ab Level " + str(item.get("level", 1)) if locked else ("Adoptieren" if category == "pets" else "Kaufen") + "  ·  " + str(item.price)
		var buy := _button(text, func():
			if category == "pets":
				if _apply(game.adopt(item_id)):
					_close_popup()
			else:
				var result := game.buy_decor(item_id)
				if _apply(result):
					_close_popup()
					room.set_editing(true)
					room.selected_furniture = str(result.id)
					room.grab_focus()
					_refresh(), true)
		buy.add_theme_font_size_override("font_size", 11)
		buy.disabled = locked or int(game.data.coins) < int(item.price) or (category == "pets" and game.data.pets.size() >= State.MAX_PETS) or (category == "decor" and game.data.furniture.size() >= 40)
		content.add_child(buy)
	box.add_child(_label("Münzen verdienst du beim Spielen, Pflegen und mit deinen Tageszielen.", 12, MUTED))

func show_inventory() -> void:
	var box := _popup("Deine kleinen Schätze.", Vector2i(650, 470))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 350)
	box.add_child(scroll)
	var list := _vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var count := 0
	for item in game.data.furniture:
		if item.placed:
			continue
		count += 1
		var id: String = item.id
		var row := _hbox(15)
		list.add_child(row)
		row.add_child(_picture(str(item.kind), Vector2(75, 75)))
		for catalog in State.DECOR:
			if catalog.kind == item.kind:
				row.add_child(_label(str(catalog.name), 16))
		row.add_child(_spacer())
		row.add_child(_button("Aufstellen", func():
			for furniture in game.data.furniture:
				if furniture.id == id:
					furniture.placed = true
					furniture.x = 50.0
					furniture.y = 88.0 if furniture.kind == "rug" else 74.0
			_close_popup()
			room.set_editing(true)
			room.selected_furniture = id
			_persist()
			_refresh(), true))
	if count == 0:
		var empty := _label("Alles hat schon seinen Platz.\n\nLagere Möbel im Einrichtungsmodus ein.\nHier warten sie auf ihren nächsten Auftritt.", 17, MUTED)
		empty.custom_minimum_size.y = 250
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		list.add_child(empty)

func show_rename() -> void:
	var box := _popup("Ein Name voller Liebe.", Vector2i(480, 230))
	box.add_child(_label("Wie soll dein kleiner Liebling heißen?", 14, MUTED))
	var input := LineEdit.new()
	input.name = "PetName"
	input.text = str(game.selected_pet().name)
	input.max_length = 18
	input.custom_minimum_size = Vector2(420, 40)
	box.add_child(input)
	var submit := func():
		if _apply(game.rename_pet(input.text)):
			_close_popup()
	input.text_submitted.connect(func(_text: String): submit.call())
	box.add_child(_button("Namen speichern", submit, true))
	input.grab_focus.call_deferred()
	input.select_all.call_deferred()

func show_help() -> void:
	var box := _popup("Willkommen in der Pfotenstube.", Vector2i(730, 620))
	var text := _label("Wähle ein Tier aus und kümmere dich um seine Bedürfnisse.\nEin Klick im Zimmer ist eine Streicheleinheit.\n\nFutter kostet 8 Münzen. Spielen bringt 12, Pflegen 10 Münzen.\nBereits gut versorgte Tiere geben keine weiteren Belohnungen.\nJe 100 XP steigt dein Level; ab Level 2 ziehen Kaninchen ein.\n\nIm Einrichtungsmodus kannst du Möbel mit der Maus ziehen.\nPfeiltasten: verschieben · R: drehen · Entf: einlagern.\n\nBedürfnisse sinken langsam, auch während einer Pause\n(höchstens acht Stunden). Deine Tiere können nicht sterben.\nEs gibt keine Käufe mit echtem Geld.\n\nDein Fortschritt wird automatisch auf diesem PC gespeichert.\nExportiere eine Sicherung, bevor du das Gerät wechselst.", 15, MUTED)
	box.add_child(text)
	var actions := _hbox(10)
	box.add_child(actions)
	actions.add_child(_button("Spielstand exportieren", func(): _file_dialog(false)))
	actions.add_child(_button("Spielstand importieren", func(): _file_dialog(true)))
	box.add_child(_button("Spielstand-Ordner öffnen", func(): OS.shell_open(ProjectSettings.globalize_path("user://"))))
	box.add_child(_label("Ein eigenständiges Haustierspiel. Ohne Facebook-Verbindung.", 11, MUTED))

func _file_dialog(importing: bool) -> void:
	var dialog := FileDialog.new()
	dialog.title = "Spielstand importieren" if importing else "Spielstand exportieren"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if importing else FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Pfotenstube-Spielstand"])
	dialog.current_file = "pfotenstube-spielstand.json" if not importing else ""
	dialog.use_native_dialog = true
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		if importing:
			_import_save(path)
		else:
			notify("Spielstand exportiert." if game.save_game(path) else game.last_error)
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_ratio(0.75)

func _import_save(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 200000:
		notify("Die Datei konnte nicht gelesen werden oder ist zu groß.")
		return
	var parsed: Variant = game.parse_json(file.get_as_text())
	file.close()
	if not game.validate_save(parsed):
		notify("Diese Datei enthält keinen gültigen Pfotenstube-Spielstand.")
		return
	var confirmation := ConfirmationDialog.new()
	confirmation.title = "Spielstand ersetzen?"
	confirmation.dialog_text = "Den aktuellen Fortschritt durch diese Sicherung ersetzen?\nDer aktuelle Stand wird vorher gesichert."
	add_child(confirmation)
	confirmation.confirmed.connect(func():
		if not game.save_game("user://spielstand.vor_import.json"):
			notify(game.last_error)
			confirmation.queue_free()
			return
		game.data = parsed
		game.advance_time()
		can_save = true
		room.set_editing(false)
		_close_popup()
		_persist()
		_refresh()
		notify("Deine Pfoten sind wieder zu Hause. Spielstand importiert!")
		confirmation.queue_free())
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.popup_centered()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(active_popup) and active_popup.visible:
			_close_popup()
		elif room.editing:
			room.set_editing(false)
			_refresh()
		get_viewport().set_input_as_handled()
