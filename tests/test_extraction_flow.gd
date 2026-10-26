extends SceneTree
# Pure map rules plus a live scene's exploration interaction. No save writes.
const RULES = preload("res://scripts/extraction_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(RULES.zone_for_position(Vector2(900, 900)) == RULES.ZONE_FOREST, "Forest risk zone")
	_check(RULES.zone_for_position(Vector2(2200, 900)) == RULES.ZONE_RUINS, "Ruins risk zone")
	_check(RULES.zone_for_position(Vector2(3200, 900)) == RULES.ZONE_FORBIDDEN, "Forbidden risk zone")
	_check(RULES.loot_rarity_weight(2) > RULES.loot_rarity_weight(1), "Higher risk increases loot weighting")
	_check(RULES.loot_rarity_weight(1) > RULES.loot_rarity_weight(0), "Ruins reward exceeds forest")
	_check(RULES.pvp_enabled(Vector2(900, 900)) and RULES.pvp_enabled(Vector2(3200, 900)), "PvP allowed in all sortie zones")
	_check(RULES.exit_profile(0).get("risk", -1) < RULES.exit_profile(1).get("risk", -1), "Exit profiles offer risk tradeoff")
	_check(RULES.exit_profile(-1).is_empty(), "Invalid exit index is rejected")
	_check(RULES.CRATES.size() >= 8, "Map offers substantial exploration")
	_check(RULES.EXITS.size() >= 2, "Two possible exits")
	_check(RULES.CARGO_CAPACITY == 12, "Finite cargo capacity")
	_check(not RULES.can_search([12, 0, 0]), "Cargo cannot be overfilled")
	_check(RULES.can_search([3, 2, 1]), "Partial cargo can be filled")
	_check(RULES.material_kind(2, 0.10) == 2, "Rare cache can yield ancient crystals")
	_check(RULES.is_near_exit(RULES.EXITS[0], RULES.EXITS[0]), "Exit detection")
	_check(not RULES.is_near_exit(Vector2.ZERO, RULES.EXITS[0]), "Distant location is not an exit")
	_check(RULES.can_use_hatch([2, 1, 0]), "Scrap and core allow paid quick extraction")
	_check(not RULES.can_use_hatch([1, 1, 0]), "Hatch needs two scrap")
	_check(not RULES.can_use_hatch([2, 0, 0]), "Hatch needs one power core")
	_check(RULES.enemy_can_detect(190.0, false, false), "Visible walking is detected")
	_check(not RULES.enemy_can_detect(190.0, true, false), "Quiet walking reduces detection range")
	_check(RULES.enemy_can_detect(500.0, true, true), "Alerted enemy continues pursuit")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 6)
	_check(str(scene.get("phase")) == "hub", "Selecting a class starts safely at camp")
	scene.call("start_sortie")
	_check(bool(scene.get("expedition_active")), "Exploration mode active")
	_check(str(scene.get("phase")) == "combat", "Exploration uses existing combat engine")
	var caches: Array = scene.get("search_crates")
	_check(caches.size() == RULES.CRATES.size(), "Caches spawned across map")
	var first_cache: Dictionary = caches[0]
	scene.set("player", first_cache["pos"])
	var handled: bool = scene.call("interact_expedition_site")
	_check(handled, "Opening supply cache is interactive")
	_check(bool(first_cache["opened"]), "Cache is marked opened")
	var carried: Array[int] = scene.get("carried_materials")
	_check(RULES.cargo_count(carried) > 0, "Cache yields real carried materials")
	_check(int(scene.get("coins")) > 0, "Cache grants gold")
	scene.set("player", RULES.EXITS[0])
	handled = scene.call("interact_expedition_site")
	_check(handled, "Exit terminal activates on E")
	_check(int(scene.get("active_exit")) == 0, "Correct exit index activated")
	_check(is_equal_approx(float(scene.get("extraction_clock")), RULES.EXTRACTION_SECONDS), "12 second exit hold")
	scene.set("player", Vector2(1700, 1500))
	scene.call("update_expedition", 0.5)
	_check(int(scene.get("active_exit")) == -1, "Leaving extraction circle cancels hold")
	_check(float(scene.get("extraction_clock")) < 0.0, "Cancelled exit is not immediately banked")
	# Simulating death uses the hub transition: carried material count resets while
	# the independently persisted warehouse inventory remains untouched.
	# An alert from firing or searching must wake nearby patrols.
	var sentries: Array = scene.get("enemies")
	_check(sentries.size() > 0, "Patrol enemies spawn in exploration")
	if not sentries.is_empty():
		var sentry: Dictionary = sentries[0]
		sentry["alert_clock"] = 0.0
		scene.call("raise_expedition_noise", sentry["pos"], 350.0, "attack")
		_check(float(sentry.get("alert_clock", 0.0)) >= RULES.ALERT_DURATION, "Gunshot alerts nearby sentry")
	# Quiet hatch: it can start only if the player carries required loot.
	scene.set("player", RULES.HATCH_POSITION)
	var hatch_cost: Array[int] = [2, 1, 0]
	scene.set("carried_materials", hatch_cost)
	handled = scene.call("interact_expedition_site")
	_check(handled, "Hidden hatch responds to interaction")
	_check(bool(scene.get("extraction_hatch_active")), "Quiet escape is activated")
	_check(is_equal_approx(float(scene.get("extraction_clock")), RULES.HATCH_SECONDS), "Quiet hatch has shorter wait")
	var cargo_after_activation: Array[int] = scene.get("carried_materials")
	_check(cargo_after_activation == hatch_cost, "Hatch does not charge before successful extraction")
	scene.set("player", Vector2(1900, 1250))
	scene.call("update_expedition", 0.1)
	_check(not bool(scene.get("extraction_hatch_active")), "Leaving hatch radius cancels it")
	scene.call("return_to_safe_hub")
	_check(str(scene.get("phase")) == "hub", "Leaving exploration returns to camp")
	_check(RULES.cargo_count(scene.get("carried_materials")) == 0, "Unsecured materials are lost")
	_check(not bool(scene.get("expedition_active")), "Ambient enemies stop at camp")
	_check((scene.get("hub_sortie_button") as Control).visible, "Another expedition is available")
	# Death must not bank expedition cargo or modify already-secured warehouse items.
	scene.call("start_sortie")
	_check(bool(scene.get("expedition_active")), "A second expedition starts after returning to hub")
	var secured_before: Array = (scene.get("stash_items") as Array).duplicate(true)
	var stored_before: Array = (scene.get("stored_materials") as Array).duplicate()
	var gold_before: int = int(scene.get("banked_gold"))
	scene.set("carried_materials", [3, 2, 1])
	scene.set("coins", 73)
	scene.call("player_died")
	_check(str(scene.get("state")) == "dead", "Expedition death ends the run")
	_check((scene.get("stash_items") as Array) == secured_before, "Death leaves stored equipment untouched")
	_check((scene.get("stored_materials") as Array) == stored_before, "Death does not bank carried materials")
	_check(int(scene.get("banked_gold")) == gold_before, "Death does not bank carried gold")
	scene.queue_free()
	if failures > 0:
		push_error("Extraction gameplay tests failed: %d" % failures)
	else:
		print("Extraction gameplay tests passed.")
	quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + description)
