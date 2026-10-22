extends RefCounted
## Whole credited balances, shared by live care and offline simulation.
## Uncredited care remainders persist separately; no per-click rounding bonus.
const XP_PER_POINT: float = 8.0 / 100.0
const GOLD_PER_POINT: Dictionary = {
	&"food": 10.0 / 100.0,
	&"clean": 9.0 / 100.0,
	&"pet": 6.0 / 100.0,
}
const EPS: float = 0.0000001

static func finite_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if not (value is float or value is int) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), minimum, maximum)

static func normalize(raw: Variant) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	var xp: float = finite_number(source.get("total_xp"), 0.0, 0.0, 1.0e12)
	var coins: float = finite_number(source.get("coins"), 100.0, 0.0, 1.0e12)
	# Migrate earlier fractional balances into whole credit plus a saved remainder.
	var xp_pending: float = xp - floorf(xp) + finite_number(source.get("xp_pending"), 0.0, 0.0, 1.0)
	var coin_pending: float = coins - floorf(coins) + finite_number(source.get("coin_pending"), 0.0, 0.0, 1.0)
	var xp_carry: int = int(floor(xp_pending + EPS))
	var coin_carry: int = int(floor(coin_pending + EPS))
	return {"total_xp": int(floor(xp)) + xp_carry,
		"xp_pending": maxf(0.0, xp_pending - xp_carry),
		"xp_compensation": finite_number(source.get("xp_compensation"), 0.0, -1.0, 1.0),
		"coins": int(floor(coins)) + coin_carry,
		"coin_pending": maxf(0.0, coin_pending - coin_carry),
		"coin_compensation": finite_number(source.get("coin_compensation"), 0.0, -1.0, 1.0)}

static func add_points(state: Dictionary, restored_points: float, care_kind: StringName = &"food") -> void:
	if not is_finite(restored_points) or restored_points <= 0.0 or not GOLD_PER_POINT.has(care_kind):
		return
	add_xp(state, restored_points * XP_PER_POINT)
	add_coins(state, restored_points * float(GOLD_PER_POINT[care_kind]))

static func add_coins(state: Dictionary, amount: float) -> void:
	_credit(state, "coins", "coin_pending", "coin_compensation", amount)

static func add_xp(state: Dictionary, amount: float) -> void:
	_credit(state, "total_xp", "xp_pending", "xp_compensation", amount)

static func _credit(state: Dictionary, balance_key: String, pending_key: String, compensation_key: String, amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	# Sum sub-point care, then credit only complete units. EPS corrects floating-
	# point boundary noise; it is never added to the accumulated remainder.
	var adjusted: float = amount - float(state[compensation_key])
	var previous: float = float(state[pending_key])
	var total: float = previous + adjusted
	var whole: int = int(floor(total + EPS))
	state[compensation_key] = (total - previous) - adjusted
	state[pending_key] = maxf(0.0, total - whole)
	state[balance_key] = int(state[balance_key]) + whole

static func position(state: Dictionary) -> Dictionary:
	var total: int = int(state["total_xp"])
	# Thresholds:20,50,90,...; each level needs ten more XP than the previous one.
	# EPS is only a floating-point boundary tolerance, never a per-action payout.
	var level: int = maxi(1, int(floor((sqrt(9.0 + 0.8 * (total + EPS)) - 1.0) / 2.0)))
	var base: int = 5 * (level - 1) * (level + 2)
	var required: int = 10 * (level + 1)
	return {"level": level, "current_xp": maxi(0, total - base), "required_xp": required}
