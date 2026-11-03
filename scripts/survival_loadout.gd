extends RefCounted
# Shared DOPAGAKI weapon types migrated from main.gd, using its condition rules.
const WEAR = preload("res://scripts/weapon_condition_rules.gd")
const NAMES := ["PISTOL", "BOW", "SWORD", "GREATSWORD", "REPEATING CROSSBOW", "ARCANE STAFF", "HEALING STAFF", "KUNAI"]
const RARITIES := ["通常", "レア", "エピック", "伝説", "神話"]
const CLASS_NAMES := ["戦士", "弓兵", "連弩士", "メイジ", "バーサーカー", "ヒーラー", "忍者"]
const CLASS_WEAPONS := [2, 1, 4, 5, 3, 6, 7]
const BASE_DAMAGE := [54.0, 70.0, 57.0, 98.0, 44.0, 72.0, 35.0, 43.0]

static func starter() -> Dictionary:
	return {"kind": 2, "rarity": 0, "condition": 100.0}

static func clean_weapon(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var kind := int(raw.get("kind", -1))
	if kind < 0 or kind >= NAMES.size():
		return {}
	return {"kind": kind, "rarity": clampi(int(raw.get("rarity", 0)), 0, 4), "condition": clampf(float(raw.get("condition", 100.0)), 0.0, 100.0)}

static func clean_weapons(raw: Variant, maximum: int) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not raw is Array:
		return output
	for value in raw:
		if output.size() >= maximum:
			break
		var item := clean_weapon(value)
		if not item.is_empty():
			output.append(item)
	return output

static func name_for(weapon: Dictionary) -> String:
	if weapon.is_empty():
		return "素手"
	var kind := clampi(int(weapon.get("kind", 2)), 0, NAMES.size() - 1)
	var rarity := clampi(int(weapon.get("rarity", 0)), 0, RARITIES.size() - 1)
	return "%s %s" % [RARITIES[rarity], NAMES[kind]]

static func is_ranged(weapon: Dictionary) -> bool:
	return not weapon.is_empty() and int(weapon.get("kind", 2)) in [0, 1, 4, 5, 7]

static func range_for(weapon: Dictionary) -> float:
	return 455.0 if is_ranged(weapon) else (105.0 if int(weapon.get("kind", 2)) == 3 else 82.0)

static func damage_for(weapon: Dictionary, class_id: int) -> float:
	if weapon.is_empty():
		return 15.0
	var kind := clampi(int(weapon.get("kind", 2)), 0, NAMES.size() - 1)
	var rarity := clampi(int(weapon.get("rarity", 0)), 0, 4)
	var specialized := 1.12 if CLASS_WEAPONS[clampi(class_id, 0, 6)] == kind else 1.0
	return BASE_DAMAGE[kind] * (1.0 + float(rarity) * 0.33) * WEAR.power_factor(float(weapon.get("condition", 100.0))) * specialized

static func worn(weapon: Dictionary) -> Dictionary:
	var cleaned := clean_weapon(weapon)
	if cleaned.is_empty():
		return cleaned
	cleaned["condition"] = WEAR.after_attack(float(cleaned["condition"]), int(cleaned["kind"]))
	return cleaned

static func repair(weapon: Dictionary, available_scrap: int) -> Dictionary:
	var cleaned := clean_weapon(weapon)
	if cleaned.is_empty() or available_scrap < 2 or float(cleaned["condition"]) > 99.5:
		return {}
	cleaned["condition"] = minf(100.0, float(cleaned["condition"]) + 40.0)
	return cleaned

static func random_weapon(rng: RandomNumberGenerator, zone: int) -> Dictionary:
	var kind := rng.randi_range(0, NAMES.size() - 1)
	var rarity := rng.randi_range(0, mini(3, maxi(0, zone) + 1))
	return {"kind": kind, "rarity": rarity, "condition": WEAR.initial_condition(rng.randf(), rarity)}
