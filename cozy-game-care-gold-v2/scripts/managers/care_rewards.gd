extends RefCounted
## One cumulative balance, shared by live care and offline simulation.
## Fractions are retained; no per-click rounding or minimum reward.
const XP_PER_POINT: float = 8.0 / 100.0
const GOLD_PER_POINT: float = 8.0 / 100.0
const EPS: float = 0.0000001

static func finite_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if not (value is float or value is int) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), minimum, maximum)

static func normalize(raw: Variant) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	return {"total_xp": finite_number(source.get("total_xp"), 0.0, 0.0, 1.0e12),
		"xp_compensation": finite_number(source.get("xp_compensation"), 0.0, -1.0, 1.0),
		"coins": finite_number(source.get("coins"), 100.0, 0.0, 1.0e12),
		"coin_compensation": finite_number(source.get("coin_compensation"), 0.0, -1.0, 1.0)}

static func add_points(state: Dictionary, restored_points: float) -> void:
	if not is_finite(restored_points) or restored_points <= 0.0:
		return
	add_xp(state, restored_points * XP_PER_POINT)
	add_coins(state, restored_points * GOLD_PER_POINT)

static func add_coins(state: Dictionary, amount: float) -> void:
	if not is_finite(amount) or amount == 0.0:
		return
	var adjusted: float = amount - float(state["coin_compensation"])
	var previous: float = float(state["coins"])
	var total: float = previous + adjusted
	state["coin_compensation"] = (total - previous) - adjusted
	state["coins"] = maxf(0.0, total)
	if total <= 0.0:
		state["coin_compensation"] = 0.0

static func add_xp(state: Dictionary, amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	# Compensated summation keeps frame-sized increments equivalent to whole actions.
	var adjusted: float = amount - float(state["xp_compensation"])
	var previous: float = float(state["total_xp"])
	var total: float = previous + adjusted
	state["xp_compensation"] = (total - previous) - adjusted
	state["total_xp"] = total

static func position(state: Dictionary) -> Dictionary:
	var total: float = float(state["total_xp"])
	# Thresholds:20,50,90,...; each level needs ten more XP than the previous one.
	# EPS is only a floating-point boundary tolerance, never a per-action payout.
	var level: int = maxi(1, int(floor((sqrt(9.0 + 0.8 * (total + EPS)) - 1.0) / 2.0)))
	var base: int = 5 * (level - 1) * (level + 2)
	var required: int = 10 * (level + 1)
	return {"level": level, "current_xp": maxf(0.0, total - float(base)), "required_xp": required}
