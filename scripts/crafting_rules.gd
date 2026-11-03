extends RefCounted
# Crafting converts *banked* expedition salvage into provisions, so escaping
# with scrap/cores matters beyond simply filling the pouch.
const NAMES := ["浄水ボトル×2", "携帯食料×2", "応急包帯×1"]
const DESCRIPTIONS := [
	"スクラップ2 + 電力コア1 → 飲料水2個",
	"スクラップ1 + ニンジン2 → 非常食2個",
	"スクラップ2 + キノコ1 → 包帯1個（HP+45）"
]
const MATERIAL_COSTS := [[2, 1, 0], [1, 0, 0], [2, 0, 0]]
const CARROT_COSTS := [0, 2, 0]
const MUSHROOM_COSTS := [0, 0, 1]
const OUTPUT_COUNTS := [2, 2, 1]
const MAX_COUNTS := [6, 6, 3]

static func can_craft(index: int, materials: Array[int], carrots: int, mushrooms: int, owned: int) -> bool:
	if index < 0 or index >= NAMES.size() or materials.size() < 3:
		return false
	if owned < 0 or owned + int(OUTPUT_COUNTS[index]) > int(MAX_COUNTS[index]):
		return false
	if carrots < int(CARROT_COSTS[index]) or mushrooms < int(MUSHROOM_COSTS[index]):
		return false
	for i in range(3):
		if materials[i] < int(MATERIAL_COSTS[index][i]):
			return false
	return true

static func remaining_materials(index: int, materials: Array[int]) -> Array[int]:
	var result: Array[int] = materials.duplicate()
	if index < 0 or index >= NAMES.size() or result.size() < 3:
		return result
	for i in range(3):
		result[i] -= int(MATERIAL_COSTS[index][i])
	return result
