extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var data = root.get_node("ItemDatabase").get_item("litter_box_basic")
	check(data != null and data.default_texture != null, "Database loads basic litter base texture")
	var keys = ["clean","light","medium","dirt","full"]
	for key in keys:
		check(data.state_textures.get(key) is Texture2D,"Database defines "+key)
	var a = data.scene.instantiate()
	check(a.get_node("BoxSprite").texture == null and a.get_node("LitterState").texture == null,"Shared scene contains no fixed artwork")
	root.add_child(a)
	var placed = PlacedItemData.new()
	placed.instance_id = "test_basic"
	placed.item_id = data.item_id
	placed.state = {"cleanliness":50.0}
	a.setup(data,placed)
	a.set_process(false)
	check(a.box_sprite.texture == data.default_texture and a.litter_state.texture == data.state_textures.medium,"Main setup applies saved cleanliness and database graphics")
	check(a.is_visible_in_tree() and a.scale == Vector2(0.6,0.6),"Runtime item is visible and enlarged")
	for i in 5:
		a.set_cleanliness(100.0-i*25.0)
		check(a.litter_state.texture == data.state_textures[keys[i]],"Basic state texture "+keys[i])
	# Different purchasable data can reuse exactly the same scene and behavior.
	var other = data.duplicate()
	other.item_id = "test_other_litter"
	other.default_texture = load("res://assets/items/companion_accesories/bowls/cat_bowls/food_bowl_basic_blue.png")
	other.state_textures = {}
	for i in 5:
		other.state_textures[keys[i]] = data.state_textures[keys[4-i]]
	var b = other.scene.instantiate()
	root.add_child(b)
	var other_placed = placed.duplicate(true)
	other_placed.instance_id = "test_other"
	other_placed.item_id = other.item_id
	b.setup(other,other_placed)
	b.set_process(false)
	check(b.box_sprite.texture == other.default_texture and b.box_sprite.texture != a.box_sprite.texture,"Second item uses its own base, no scene fallback")
	for i in 5:
		b.set_cleanliness(100.0-i*25.0)
		check(b.litter_state.texture == other.state_textures[keys[i]],"Second item owns its "+keys[i]+" graphic")
	a.setup(other,other_placed)
	a.set_cleanliness(100.0)
	check(a.clean_texture == other.state_textures.clean and a.box_sprite.texture == other.default_texture,"Reusing a node clears all previous item artwork")
	print("LITTER_ITEM_DATA_AND_SHARED_SCENE_OK" if failures.is_empty() else str(failures))
	a.queue_free()
	b.queue_free()
	quit(0 if failures.is_empty() else 1)
