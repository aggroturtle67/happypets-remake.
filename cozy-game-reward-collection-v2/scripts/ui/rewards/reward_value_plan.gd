extends RefCounted
## A lazy multiset: arbitrarily large awards need only two integer counters.
static func build(amount: int, rng: RandomNumberGenerator) -> Dictionary:
	if amount <= 0:
		return {"singles": 0, "doubles": 0}
	var doubles: int = 0
	if amount == 2:
		doubles = rng.randi_range(0, 1)
	elif amount >= 3:
		var maximum: int = int((amount - 1) / 2.0)
		var low: int = clampi(int(amount * 0.25), 1, maximum)
		var high: int = clampi(int(ceil(amount * 0.43)), low, maximum)
		doubles = rng.randi_range(low, high)
	return {"singles": amount - doubles * 2, "doubles": doubles}

static func take(plan: Dictionary, rng: RandomNumberGenerator) -> int:
	var count: int = int(plan.singles) + int(plan.doubles)
	if count <= 0:
		return 0
	if rng.randi_range(0, count - 1) < int(plan.singles):
		plan.singles -= 1
		return 1
	plan.doubles -= 1
	return 2
