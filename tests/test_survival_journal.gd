extends SceneTree
# Progression/codex tests run in an isolated CI Godot user directory.
const JOURNAL = preload("res://scripts/survival_journal_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var record: Dictionary = JOURNAL.fresh()
	_check(record["kills"] == 0 and (record["zones"] as Array).is_empty(), "Fresh journal empty")
	_check(JOURNAL.add_zone(record, 2), "Forbidden zone first discovery")
	_check(not JOURNAL.add_zone(record, 2), "Repeated zone visit not duplicated")
	_check(not JOURNAL.add_zone(record, 42), "Invalid zone ignored")
	JOURNAL.add_enemy(record, "runner")
	JOURNAL.add_enemy(record, "runner")
	_check(int(record["kills"]) == 2, "Kills count each defeat")
	_check((record["foes"] as Array).size() == 1, "Enemy type discovered only once")
	JOURNAL.add_rarity(record, 3)
	JOURNAL.add_rarity(record, 3)
	_check((record["rarities"] as Array).size() == 1, "Rarity collection is unique")
	JOURNAL.add_cache(record)
	JOURNAL.add_escape(record)
	_check(int(record["caches"]) == 1 and int(record["escapes"]) == 1, "Cache and escape counters advance")
	var malicious: Dictionary = {"kills": -50, "caches": 500000000, "zones": [2, 2, 99], "foes": ["runner", "???"], "rarities": [-1, 1, 1]}
	var normalized: Dictionary = JOURNAL.clean(malicious)
	_check(int(normalized["kills"]) == 0 and int(normalized["caches"]) == 10000000, "Corrupted counters clamped")
	_check((normalized["zones"] as Array).size() == 1 and (normalized["foes"] as Array).size() == 1, "Invalid discoveries filtered")
	_check((normalized["rarities"] as Array).size() == 1, "Duplicate rarity entries filtered")
	var badges: Dictionary = JOURNAL.fresh()
	for zone in range(3):
		JOURNAL.add_zone(badges, zone)
	for i in range(50):
		JOURNAL.add_enemy(badges, "grunt")
	for i in range(15):
		JOURNAL.add_cache(badges)
	for i in range(3):
		JOURNAL.add_escape(badges)
	_check(JOURNAL.earned_badges(badges).size() >= 4, "Milestone titles unlock from real progress")

	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	var old_host: Dictionary = (scene.get("journal_host") as Dictionary).duplicate(true)
	var old_guest: Dictionary = (scene.get("journal_guest") as Dictionary).duplicate(true)
	scene.set("journal_host", JOURNAL.fresh())
	scene.set("journal_guest", JOURNAL.fresh())
	scene.call("toggle_survival_journal")
	_check(bool(scene.get("journal_open")), "O key opens collection codex")
	_check((scene.get("journal_info") as Label).text.contains("討伐0体"), "Journal UI displays progress")
	scene.call("toggle_survival_journal")
	scene.call("journal_record_foe", {"kind": "runner", "elite": false, "boss": false})
	scene.call("journal_record_rarity", 3)
	scene.call("journal_record_rarity", 3)
	scene.call("journal_record_cache")
	scene.call("journal_record_escape")
	var actual: Dictionary = scene.get("journal_host")
	_check(int(actual["kills"]) == 1, "Enemy kill wired to journal")
	_check(int(actual["caches"]) == 1 and int(actual["escapes"]) == 1, "Loot and successful extraction recorded")
	_check((actual["rarities"] as Array).size() == 1, "Equipment rarity recorded only on pickup")
	scene.set("player", Vector2(3200, 1600))
	scene.call("journal_check_zones")
	_check((actual["zones"] as Array).has(2), "Forbidden region exploration recorded")
	scene.call("return_to_safe_hub")
	_check(int((scene.get("journal_host") as Dictionary)["kills"]) == 1, "Codex survives expedition reset")
	_check(bool(scene.call("save_survival_journal")), "Host journal can persist to disk")
	scene.set("journal_host", JOURNAL.fresh())
	scene.call("load_survival_journal")
	_check(int((scene.get("journal_host") as Dictionary)["kills"]) == 1, "Host journal reload from user data")
	scene.call("coop_host_pressed")
	var network: Node = scene.get("coop")
	network.peer_id = 2
	scene.call("journal_record_cache")
	_check(int((scene.get("journal_guest") as Dictionary)["caches"]) == 1, "Teammate gets shared cache credit")
	scene.call("journal_record_foe", {"kind": "tank", "elite": false, "boss": false})
	_check(int((scene.get("journal_guest") as Dictionary)["kills"]) == 1, "Co-op teammate gets team kill discovery")
	network.peer_id = 0
	network.close_game()
	# Restore test user's original records.
	scene.set("journal_host", old_host)
	scene.set("journal_guest", old_guest)
	scene.call("save_survival_journal", false)
	scene.call("save_survival_journal", true)
	scene.queue_free()
	if failures > 0:
		push_error("Survival journal regression failed: %d" % failures)
	else:
		print("Survival codex and durable discoveries passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
