class_name PetGameState
extends RefCounted

const SAVE_PATH := "user://spielstand.json"
const MAX_PETS := 6
const PETS := [
	{"id": "peach", "name": "Pfirsich", "species": "cat", "price": 120, "level": 1, "description": "Kleine Pfoten, große Neugier."},
	{"id": "cocoa", "name": "Kakao", "species": "dog", "price": 160, "level": 1, "description": "Dein neuer bester Freund."},
	{"id": "cloud", "name": "Wölkchen", "species": "bunny", "price": 180, "level": 2, "description": "Ein flauschiges Stück Glück."},
	{"id": "pepper", "name": "Pfeffer", "species": "cat", "price": 150, "level": 1, "description": "Samtpfote mit eigenem Kopf."}
]
const DECOR := [
	{"kind": "bed", "name": "Kuschelkörbchen", "price": 65},
	{"kind": "plant", "name": "Zimmergrün", "price": 35},
	{"kind": "scratch", "name": "Kratzbaum", "price": 80},
	{"kind": "rug", "name": "Sonnenteppich", "price": 50},
	{"kind": "bowl", "name": "Futternäpfe", "price": 25},
	{"kind": "cushion", "name": "Wolkenkissen", "price": 40},
	{"kind": "lamp", "name": "Leselämpchen", "price": 55},
	{"kind": "toys", "name": "Spielzeugkiste", "price": 45}
]
const QUESTS := [
	{"id": "feed", "title": "Ein voller Bauch", "reward": 30},
	{"id": "play", "title": "Gemeinsam spielen", "reward": 35},
	{"id": "clean", "title": "Frisch und flauschig", "reward": 30}
]
const SPECIES := {"cat": "Katze", "dog": "Hund", "bunny": "Kaninchen"}

var data: Dictionary = {}
var last_error := ""
var recovery_message := ""

func _init(now: float = -1.0) -> void:
	reset(now)

func date_key(now: float) -> String:
	# Godot's conversion is UTC; account for the player's local offset for daily rewards.
	var local_time := now + float(Time.get_time_zone_from_system().bias) * 60.0
	return Time.get_date_string_from_unix_time(int(local_time))

func reset(now: float = -1.0) -> void:
	if now < 0:
		now = Time.get_unix_time_from_system()
	data = {
		"version": 1, "coins": 280, "xp": 0, "selected": "momo", "last_updated": now, "gift_date": "",
		"quests": {"date": date_key(now), "progress": {"feed": 0, "play": 0, "clean": 0}, "claimed": []},
		"pets": [
			{"id": "momo", "name": "Momo", "species": "cat", "art": "cat", "hunger": 62.0, "joy": 72.0, "clean": 80.0},
			{"id": "milo", "name": "Milo", "species": "dog", "art": "dog", "hunger": 75.0, "joy": 58.0, "clean": 65.0}
		],
		"furniture": [
			{"id": "rug-start", "kind": "rug", "x": 50.0, "y": 88.0, "placed": true, "flipped": false},
			{"id": "bed-start", "kind": "bed", "x": 23.0, "y": 67.0, "placed": true, "flipped": false},
			{"id": "plant-start", "kind": "plant", "x": 89.0, "y": 63.0, "placed": true, "flipped": false},
			{"id": "scratch-start", "kind": "scratch", "x": 72.0, "y": 62.0, "placed": true, "flipped": false},
			{"id": "bowl-start", "kind": "bowl", "x": 20.0, "y": 89.0, "placed": true, "flipped": false},
			{"id": "toys-start", "kind": "toys", "x": 84.0, "y": 87.0, "placed": true, "flipped": false}
		]
	}

func level() -> int:
	return int(data.xp / 100.0) + 1

func selected_pet() -> Dictionary:
	for pet in data.pets:
		if pet.id == data.selected:
			return pet
	return data.pets[0]

func fail(message: String) -> Dictionary:
	return {"ok": false, "message": message}

func succeed(message: String) -> Dictionary:
	return {"ok": true, "message": message}

func advance_time(now: float = -1.0) -> void:
	if now < 0:
		now = Time.get_unix_time_from_system()
	var minutes := clampf((now - float(data.last_updated)) / 60.0, 0.0, 480.0)
	for pet in data.pets:
		pet.hunger = clampf(float(pet.hunger) - minutes * 0.3, 0.0, 100.0)
		pet.joy = clampf(float(pet.joy) - minutes * 0.2, 0.0, 100.0)
		pet.clean = clampf(float(pet.clean) - minutes * 0.15, 0.0, 100.0)
	data.last_updated = now
	if data.quests.date != date_key(now):
		data.quests = {"date": date_key(now), "progress": {"feed": 0, "play": 0, "clean": 0}, "claimed": []}

func care(action: String, pet_id: String = "") -> Dictionary:
	var settings := {
		"feed": {"need": "hunger", "amount": 35.0, "coins": -8, "xp": 15, "text": " lässt es sich schmecken!"},
		"play": {"need": "joy", "amount": 30.0, "coins": 12, "xp": 20, "text": " hat riesigen Spaß! +12 Münzen"},
		"clean": {"need": "clean", "amount": 35.0, "coins": 10, "xp": 15, "text": " ist wieder blitzsauber! +10 Münzen"},
		"pet": {"need": "joy", "amount": 8.0, "coins": 0, "xp": 3, "text": " genießt die Streicheleinheit."}
	}
	if not settings.has(action):
		return fail("Diese Aktion kenne ich nicht.")
	if not pet_id.is_empty():
		var found := false
		for candidate in data.pets:
			if candidate.id == pet_id:
				data.selected = pet_id
				found = true
		if not found:
			return fail("Dieses Tier wohnt nicht in deiner Stube.")
	var pet := selected_pet()
	var setting: Dictionary = settings[action]
	var limit := 95.0 if action == "pet" else 85.0
	if float(pet[setting.need]) > limit:
		return fail(str(pet.name) + " ist schon bestens versorgt. Versuch es später wieder!")
	if int(data.coins) + int(setting.coins) < 0:
		return fail("Dir fehlen Münzen fürs Futter. Beim Spielen und Pflegen verdienst du neue.")
	pet[setting.need] = minf(100.0, float(pet[setting.need]) + float(setting.amount))
	data.coins = int(data.coins) + int(setting.coins)
	data.xp = int(data.xp) + int(setting.xp)
	if action != "pet":
		data.quests.progress[action] = 1
	return succeed(str(pet.name) + str(setting.text) + "  +" + str(setting.xp) + " XP")

func adopt(catalog_id: String) -> Dictionary:
	for item in PETS:
		if item.id != catalog_id:
			continue
		if data.pets.size() >= MAX_PETS:
			return fail("Deine Stube ist voll. Bis zu sechs Tiere können hier wohnen.")
		if level() < int(item.level):
			return fail("Dieses Tier zieht ab Level " + str(item.level) + " ein.")
		if int(data.coins) < int(item.price):
			return fail("Dafür fehlen dir Münzen. Erledige die Tagesaufgaben!")
		var id := "pet-" + str(Time.get_ticks_usec())
		data.pets.append({"id": id, "name": item.name, "species": item.species, "art": item.id, "hunger": 70.0, "joy": 75.0, "clean": 85.0})
		data.coins = int(data.coins) - int(item.price)
		data.xp = int(data.xp) + 20
		data.selected = id
		return succeed("Willkommen zu Hause, " + str(item.name) + "!")
	return fail("Dieses Tier ist nicht verfügbar.")

func buy_decor(kind: String) -> Dictionary:
	for item in DECOR:
		if item.kind != kind:
			continue
		if data.furniture.size() >= 40:
			return fail("Dein Möbellager ist voll (40 Gegenstände).")
		if int(data.coins) < int(item.price):
			return fail("Dafür fehlen dir noch ein paar Münzen.")
		var id := "decor-" + str(Time.get_ticks_usec())
		data.furniture.append({"id": id, "kind": kind, "x": 50.0, "y": 88.0 if kind == "rug" else 72.0, "placed": true, "flipped": false})
		data.coins = int(data.coins) - int(item.price)
		var result := succeed(str(item.name) + " ist da! Ziehe es an deinen Lieblingsplatz.")
		result.id = id
		return result
	return fail("Dieser Gegenstand ist nicht verfügbar.")

func move_furniture(id: String, x: float, y: float) -> void:
	if not is_finite(x) or not is_finite(y):
		return
	for item in data.furniture:
		if item.id == id:
			item.x = clampf(x, 8.0, 92.0)
			item.y = clampf(y, 54.0, 91.0)

func claim_quest(key: String) -> Dictionary:
	for quest in QUESTS:
		if quest.id == key:
			if int(data.quests.progress[key]) == 0 or key in data.quests.claimed:
				return fail("Diese Belohnung ist noch nicht verfügbar.")
			data.coins = int(data.coins) + int(quest.reward)
			data.xp = int(data.xp) + 20
			data.quests.claimed.append(key)
			return succeed("Tagesziel geschafft! +" + str(quest.reward) + " Münzen · +20 XP")
	return fail("Diese Aufgabe gibt es nicht.")

func claim_gift(now: float = -1.0) -> Dictionary:
	if now < 0:
		now = Time.get_unix_time_from_system()
	if data.gift_date == date_key(now):
		return fail("Dein nächstes Geschenk wartet morgen auf dich.")
	data.coins = int(data.coins) + 75
	data.gift_date = date_key(now)
	return succeed("Schön, dass du da bist! +75 Münzen")

func rename_pet(new_name: String) -> Dictionary:
	var cleaned := new_name.strip_edges().substr(0, 18)
	if cleaned.is_empty():
		return fail("Gib deinem Tier einen Namen.")
	selected_pet().name = cleaned
	return succeed("Ein schöner Name: " + cleaned + "!")

func valid_number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

func validate_save(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in ["version", "coins", "xp", "pets", "furniture", "selected", "last_updated", "gift_date", "quests"]:
		if not value.has(key):
			return false
	if value.version != 1 or not valid_number(value.coins, 0, 1e9) or not valid_number(value.xp, 0, 1e9) or not valid_number(value.last_updated, 0, 1e14):
		return false
	if not value.pets is Array or value.pets.is_empty() or value.pets.size() > MAX_PETS or not value.furniture is Array or value.furniture.size() > 40:
		return false
	var pet_ids: Array = []
	for pet in value.pets:
		if not pet is Dictionary:
			return false
		for key in ["id", "name", "species", "art", "hunger", "joy", "clean"]:
			if not pet.has(key):
				return false
		if not pet.id is String or pet.id.is_empty() or pet.id.length() > 100 or pet.id in pet_ids:
			return false
		pet_ids.append(pet.id)
		if not pet.name is String or pet.name.is_empty() or pet.name.length() > 18 or not pet.species in SPECIES or not pet.art in ["cat", "dog", "peach", "cocoa", "cloud", "pepper"]:
			return false
		for key in ["hunger", "joy", "clean"]:
			if not valid_number(pet[key], 0, 100):
				return false
	if not value.selected in pet_ids:
		return false
	var decor_ids: Array = []
	for item in value.furniture:
		if not item is Dictionary:
			return false
		for key in ["id", "kind", "x", "y", "placed", "flipped"]:
			if not item.has(key):
				return false
		if not item.id is String or item.id.is_empty() or item.id in decor_ids or not item.kind in ["bed", "plant", "scratch", "rug", "bowl", "cushion", "lamp", "toys"] or not item.placed is bool or not item.flipped is bool:
			return false
		decor_ids.append(item.id)
		if not valid_number(item.x, 8, 92) or not valid_number(item.y, 54, 91):
			return false
	if not value.gift_date is String or not value.quests is Dictionary:
		return false
	var quests: Dictionary = value.quests
	if not quests.get("date") is String or not quests.get("progress") is Dictionary or not quests.get("claimed") is Array:
		return false
	for key in ["feed", "play", "clean"]:
		if not quests.progress.has(key) or not valid_number(quests.progress[key], 0, 1):
			return false
	var claimed: Array = []
	for key in quests.claimed:
		if not key in ["feed", "play", "clean"] or key in claimed:
			return false
		claimed.append(key)
	return true

func parse_json(raw: String) -> Variant:
	var parser := JSON.new()
	return parser.data if parser.parse(raw) == OK else null

func save_game(path: String = SAVE_PATH) -> bool:
	# Write a temporary file first. Keep the previous save as a recoverable backup.
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Speichern nicht möglich. Bitte prüfe den freien Speicher und die Zugriffsrechte."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		last_error = "Der Spielstand konnte nicht vollständig geschrieben werden."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var backup_error := DirAccess.copy_absolute(absolute, absolute + ".backup")
		if backup_error != OK:
			last_error = "Die Spielstandsicherung konnte nicht angelegt werden."
			return false
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), absolute)
	if rename_error != OK:
		last_error = "Der neue Spielstand konnte nicht übernommen werden."
		return false
	last_error = ""
	return true

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = parse_json(raw)
	if validate_save(parsed):
		data = parsed
		advance_time()
		return true
	var backup: Variant = parse_json(FileAccess.get_file_as_string(path + ".backup")) if FileAccess.file_exists(path + ".backup") else null
	# Preserve damaged data before future autosaves.
	var preserved := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".damaged"))
	if preserved != OK:
		last_error = "Der beschädigte Spielstand konnte nicht gesichert werden. Automatisches Speichern ist deaktiviert."
		return false
	if validate_save(backup):
		data = backup
		advance_time()
		recovery_message = "Dein letzter gesicherter Spielstand wurde wiederhergestellt."
	else:
		recovery_message = "Der alte Spielstand ist beschädigt. Eine Kopie wurde gesichert; deine Stube startet neu."
	return true
