extends RefCounted
## Advances validated room records between timed events, without simulating frames.
## Every bowl has one owner; a meal always consumes at most fifty food points.
const EPS: float = 0.0000001

static func number(value: Variant, fallback: float, minimum: float = 0.0, maximum: float = 1.0e12) -> float:
	if not (value is int or value is float) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), minimum, maximum)

static func point(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(number(value[0], fallback.x, -1.0e9, 1.0e9), number(value[1], fallback.y, -1.0e9, 1.0e9))
	return fallback

static func advance(cats: Dictionary, items: Array, elapsed: float) -> void:
	if elapsed <= 0.0 or not is_finite(elapsed):
		return
	# Missing affection marks an older save: no retroactive decay before this feature.
	for cat in cats.values():
		if cat.has("affection"):
			cat["affection"] = maxf(0.0, number(cat["affection"], 100.0, 0.0, 100.0) - elapsed * number(cat.get("affection_loss_per_second"), 55.0 / (36.0 * 3600.0)))
	var bowls: Dictionary = {}
	for placed in items:
		if placed.state.has("fill"):
			bowls[placed.instance_id] = placed
		elif placed.state.has("cleanliness") and placed.state.get("automatic_soiling", true):
			var stage: float = number(placed.state.get("seconds_per_stage"), 180.0, 1.0)
			placed.state["cleanliness"] = maxf(0.0, float(placed.state["cleanliness"]) - elapsed * 25.0 / stage)
	var owners: Dictionary = {}
	# Restore existing meals before assigning any new ones.
	for id in cats:
		var cat: Dictionary = cats[id]
		var meal: Dictionary = cat.get("meal", {})
		cat["meal"] = {}
		var bowl_id: String = str(meal.get("bowl_id", ""))
		if not bowls.has(bowl_id) or owners.has(bowl_id):
			continue
		var total: float = number(meal.get("total"), 50.0, 0.0, 50.0)
		var consumed: float = number(meal.get("consumed"), 0.0, 0.0, total)
		if total - consumed <= EPS or float(bowls[bowl_id].state["fill"]) + EPS < total - consumed:
			continue
		meal["total"] = total
		meal["consumed"] = consumed
		meal["start_satiety"] = number(meal.get("start_satiety"), float(cat["satiety"]), 0.0, 100.0)
		meal["travelling"] = meal.get("travelling", false) == true
		meal["target"] = meal.get("target", cat["position"])
		cat["meal"] = meal
		owners[bowl_id] = id
	var remaining: float = elapsed
	while remaining > EPS:
		# A waiting hungry cat gets the nearest available half bowl.
		for id in cats:
			var cat: Dictionary = cats[id]
			if not cat["meal"].is_empty() or float(cat["satiety"]) > number(cat.get("hungry_threshold"), 50.0, 0.0, 100.0) + EPS:
				continue
			var nearest: String = ""
			var best: float = INF
			var target: Vector2
			for bowl_id in bowls:
				if owners.has(bowl_id) or float(bowls[bowl_id].state["fill"]) + EPS < 50.0:
					continue
				var spot: Vector2 = bowls[bowl_id].position + point(cat.get("bowl_offset"), Vector2(-115, 65))
				var distance: float = point(cat["position"]).distance_squared_to(spot)
				if distance < best:
					nearest = bowl_id
					best = distance
					target = spot
			if not nearest.is_empty():
				cat["meal"] = {"bowl_id": nearest, "start_satiety": cat["satiety"], "consumed": 0.0,
					"total": 50.0, "travelling": true, "target": [target.x, target.y]}
				owners[nearest] = id
		var step: float = remaining
		for cat in cats.values():
			var meal: Dictionary = cat["meal"]
			if not meal.is_empty():
				if meal["travelling"]:
					var speed: float = number(cat.get("movement_speed"), 120.0)
					if speed > EPS:
						step = minf(step, point(cat["position"]).distance_to(point(meal["target"])) / speed)
				else:
					var rate: float = number(cat.get("eating_per_second"), 10.0)
					if rate > EPS:
						step = minf(step, (float(meal["total"]) - float(meal["consumed"])) / rate)
			elif not bowls.is_empty():
				var loss: float = number(cat.get("satiety_loss_per_second"), 50.0 / 600.0)
				var excess: float = float(cat["satiety"]) - number(cat.get("hungry_threshold"), 50.0, 0.0, 100.0)
				if loss > EPS and excess > EPS:
					step = minf(step, excess / loss)
		for id in cats:
			var cat: Dictionary = cats[id]
			var meal: Dictionary = cat["meal"]
			if meal.is_empty() or meal["travelling"]:
				cat["satiety"] = maxf(0.0, float(cat["satiety"]) - number(cat.get("satiety_loss_per_second"), 50.0 / 600.0) * step)
			if meal.is_empty():
				continue
			if meal["travelling"]:
				var target: Vector2 = point(meal["target"])
				var pos: Vector2 = point(cat["position"]).move_toward(target, number(cat.get("movement_speed"), 120.0) * step)
				cat["position"] = [pos.x, pos.y]
				if pos.distance_to(target) <= EPS:
					meal["travelling"] = false
					if float(meal["consumed"]) <= EPS:
						meal["start_satiety"] = cat["satiety"]
			else:
				var portion: float = minf(float(meal["total"]) - float(meal["consumed"]), number(cat.get("eating_per_second"), 10.0) * step)
				meal["consumed"] = float(meal["consumed"]) + portion
				var bowl: PlacedItemData = bowls[str(meal["bowl_id"])]
				bowl.state["fill"] = maxf(0.0, float(bowl.state["fill"]) - portion)
				cat["satiety"] = lerpf(float(meal["start_satiety"]), 100.0, float(meal["consumed"]) / float(meal["total"]))
				if float(meal["total"]) - float(meal["consumed"]) <= EPS:
					cat["satiety"] = 100.0
					owners.erase(str(meal["bowl_id"]))
					cat["meal"] = {}
		remaining -= step
