extends RefCounted
# Small persistent wear per real attack. At poor condition weapons remain usable
# with a penalty, preventing a softlock when no salvage has been banked.
const REPAIR_SCRAP := 2
const REPAIR_CORE := 1

static func initial_condition(roll: float, rarity: int) -> float:
	return clampf(72.0 + clampf(roll, 0.0, 1.0) * 28.0 + float(clampi(rarity, 0, 4)) * 1.5, 72.0, 100.0)

static func wear_per_attack(kind: int) -> float:
	match kind:
		3: return 0.80 # Heavy sword: high impact, greater material fatigue.
		2, 7: return 0.55
		4: return 0.85 # One trigger pull launches a burst.
		_: return 0.40

static func after_attack(condition: float, kind: int) -> float:
	return maxf(0.0, clampf(condition, 0.0, 100.0) - wear_per_attack(kind))

static func power_factor(condition: float) -> float:
	return 0.60 + 0.40 * clampf(condition / 100.0, 0.0, 1.0)

static func can_repair(materials: Array[int], condition: float) -> bool:
	return materials.size() >= 3 and condition < 99.5 and materials[0] >= REPAIR_SCRAP and materials[1] >= REPAIR_CORE

static func after_repair_cost(materials: Array[int]) -> Array[int]:
	var updated: Array[int] = materials.duplicate()
	if updated.size() >= 3:
		updated[0] -= REPAIR_SCRAP
		updated[1] -= REPAIR_CORE
	return updated
