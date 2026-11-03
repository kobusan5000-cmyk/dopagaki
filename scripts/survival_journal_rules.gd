extends RefCounted
# Durable exploration records. Counts reflect credited team events, while
# discoveries are sets so repeated zone visits never mint extra achievements.
const FOE_KEYS := ["grunt", "hihi", "runner", "tank", "spitter", "zigzag", "venom", "frost", "ember", "brute", "reaper"]
const FOE_NAMES := ["通常敵", "跳躍敵", "疾走敵", "重装敵", "射撃敵", "回避敵", "毒敵", "氷敵", "炎敵", "大型敵", "NIGHT REAPER"]
const RARITY_NAMES := ["通常", "レア", "エピック", "伝説", "神話"]

static func fresh() -> Dictionary:
	return {"kills": 0, "caches": 0, "escapes": 0, "zones": [], "foes": [], "rarities": []}

static func clean(raw: Variant) -> Dictionary:
	var entry := fresh()
	if typeof(raw) != TYPE_DICTIONARY:
		return entry
	for k in ["kills", "caches", "escapes"]:
		entry[k] = clampi(int(raw.get(k, 0)), 0, 10000000)
	if raw.get("zones") is Array:
		for zone in raw["zones"]:
			var id := int(zone)
			if id >= 0 and id < 3 and not entry["zones"].has(id):
				entry["zones"].append(id)
	if raw.get("foes") is Array:
		for foe in raw["foes"]:
			var code := str(foe)
			if FOE_KEYS.has(code) and not entry["foes"].has(code):
				entry["foes"].append(code)
	if raw.get("rarities") is Array:
		for rarity in raw["rarities"]:
			var id := int(rarity)
			if id >= 0 and id < RARITY_NAMES.size() and not entry["rarities"].has(id):
				entry["rarities"].append(id)
	return entry

static func add_zone(data: Dictionary, zone: int) -> bool:
	if zone < 0 or zone > 2 or data["zones"].has(zone):
		return false
	data["zones"].append(zone)
	return true

static func add_enemy(data: Dictionary, foe: String) -> void:
	data["kills"] = int(data["kills"]) + 1
	if FOE_KEYS.has(foe) and not data["foes"].has(foe):
		data["foes"].append(foe)

static func add_cache(data: Dictionary) -> void:
	data["caches"] = int(data["caches"]) + 1

static func add_escape(data: Dictionary) -> void:
	data["escapes"] = int(data["escapes"]) + 1

static func add_rarity(data: Dictionary, rarity: int) -> void:
	if rarity >= 0 and rarity < RARITY_NAMES.size() and not data["rarities"].has(rarity):
		data["rarities"].append(rarity)

static func earned_badges(data: Dictionary) -> Array[String]:
	var badges: Array[String] = []
	if (data["zones"] as Array).size() >= 3:
		badges.append("踏破者")
	if int(data["kills"]) >= 50:
		badges.append("狩人")
	if int(data["caches"]) >= 15:
		badges.append("物資王")
	if int(data["escapes"]) >= 3:
		badges.append("生還者")
	if (data["foes"] as Array).size() >= FOE_KEYS.size():
		badges.append("怪物研究家")
	return badges

static func missing_enemy_names(data: Dictionary) -> String:
	var names: Array[String] = []
	for i in range(FOE_KEYS.size()):
		if not data["foes"].has(FOE_KEYS[i]):
			names.append("？？？")
		else:
			names.append(FOE_NAMES[i])
	return " / ".join(names)

static func rarity_discovery(data: Dictionary) -> String:
	var names: Array[String] = []
	for i in range(RARITY_NAMES.size()):
		names.append(RARITY_NAMES[i] if data["rarities"].has(i) else "？？？")
	return " / ".join(names)
