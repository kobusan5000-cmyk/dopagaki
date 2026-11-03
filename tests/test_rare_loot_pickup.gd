extends SceneTree
# Gear pickup celebrates only acquired inventory; cannot delete or duplicate dropped loot.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _make_gear(name: String, tier: int, pos: Vector2) -> Dictionary:
	return {"type": "weapon", "name": name, "kind": 2, "rarity": tier, "trait": 0, "bonus": 1.2, "condition": 100.0, "pos": pos, "life": 32.0, "phase": 0.0}

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	scene.call("start_sortie")
	var player_pos := Vector2(2570, 1550)
	scene.set("player", player_pos)
	var bag: Array = scene.get("backpack")
	for i in range(bag.size()):
		bag[i] = {}
	var loot: Array = scene.get("drops")
	loot.clear()
	var sparks: Array = scene.get("impact_sparks")
	sparks.clear()
	loot.append(_make_gear("TEST EPIC SWORD", 2, player_pos + Vector2(22, 0)))
	scene.call("pickup_nearby")
	_check(loot.is_empty(), "Manual epic pickup removes exactly one ground drop")
	_check(int((bag[0] as Dictionary).get("rarity", -1)) == 2, "Epic loot enters first available slot")
	_check(str((scene.get("banner") as Label).text).contains("エピック拾得"), "Epic pickup shows special reward text")
	_check(sparks.size() > 0, "Epic pickup triggers victory sparks")
	var before_sparks := sparks.size()
	scene.call("pickup_nearby")
	_check(sparks.size() == before_sparks, "Repeated pickup with no loot does not retrigger effects")
	# Full bag: preserve world drop and never claim it as an acquisition.
	for i in range(1, bag.size()):
		bag[i] = bag[0].duplicate(true)
	scene.set("legendary_glow_clock", 0.0)
	loot.append(_make_gear("TEST UNCLAIMED MYTHIC", 4, player_pos + Vector2(30, 0)))
	scene.call("pickup_nearby")
	_check(loot.size() == 1, "Full bag keeps mythic equipment on the ground")
	_check(float(scene.get("legendary_glow_clock")) == 0.0, "No mythic pickup celebration until actually collected")
	# Collect via expedition cache auto-collection path.
	bag[1] = {}
	var collected: bool = scene.call("auto_collect_expedition_gear")
	_check(collected and loot.is_empty(), "Auto-collection consumes one actual ground item")
	_check(int((bag[1] as Dictionary).get("rarity", -1)) == 4, "Mythic gear goes into newly free slot")
	_check(float(scene.get("legendary_glow_clock")) > 0.0, "Mythic pickup starts legendary screen glow")
	_check(str((scene.get("banner") as Label).text).contains("神話級"), "Mythic shows tier-specific pickup message")
	# Common gear should not shake the screen or start a legendary flash.
	scene.set("legendary_glow_clock", 0.0)
	bag[2] = {}
	loot.append(_make_gear("TEST COMMON SWORD", 0, player_pos + Vector2(25, 0)))
	scene.call("pickup_nearby")
	_check(int((bag[2] as Dictionary).get("rarity", -1)) == 0, "Common gear remains collectible")
	_check(float(scene.get("legendary_glow_clock")) == 0.0, "Common gear does not cause a legendary flash")
	_check(str((scene.get("banner") as Label).text).contains("装備を拾った"), "Common gear uses quieter pickup message")
	scene.queue_free()
	if failures > 0:
		push_error("Rare pickup celebration failures: %d" % failures)
	else:
		print("Rare gear pickup visuals, one-time loot and full bag safeguards passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
