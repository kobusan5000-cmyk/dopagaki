extends RefCounted
# Survival basics: compact enough for short extraction sorties, but the player
# must actually search for provisions before pushing into the forbidden zone.
const MAX_SUPPLIES := 6
const HUNGER_DRAIN_PER_SECOND := 0.075
const THIRST_DRAIN_PER_SECOND := 0.13
const RATION_RESTORE := 42.0
const WATER_RESTORE := 48.0
const LOW_THRESHOLD := 25.0
const STARVATION_DAMAGE := 2.0
const STARVATION_DAMAGE_SECONDS := 4.0

static func decrease_need(value: float, rate: float, delta: float, zone: int) -> float:
	return clampf(value - rate * maxf(0.0, delta) * (1.0 + 0.22 * float(clampi(zone, 0, 2))), 0.0, 100.0)

static func movement_factor(hunger: float, thirst: float) -> float:
	var lowest := minf(hunger, thirst)
	if lowest <= 0.0:
		return 0.74
	if lowest < LOW_THRESHOLD:
		return 0.87
	return 1.0

static func cache_food_chance(tier: int) -> float:
	return minf(0.90, 0.55 + float(clampi(tier, 0, 2)) * 0.15)

static func cache_water_chance(tier: int) -> float:
	return minf(0.90, 0.65 + float(clampi(tier, 0, 2)) * 0.12)

static func can_use_supply(available: int, need: float) -> bool:
	return available > 0 and need < 99.5
