extends SceneTree
# Pure map rules plus a live scene's exploration interaction. No save writes.
const RULES = preload("res://scripts/extraction_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(RULES.CRATES.size() >= 8, "Map offers substantial exploration")
	_check(RULES.EXITS.size() >= 2, "Two possible exits")
	_check(RULES.CARGO_CAPACITY == 12, "Finite cargo capacity")
	_check(not RULES.can_search([12, 0, 0]), "Cargo cannot be overfilled")
	_check(RULES.can_search([3, 2, 1]), "Partial cargo can be filled")
	_check(RULES.material_kind(2, 0.10) == 2, "Rare cache can yield ancient crystals")
	_check(RULES.is_near_exit(RULES.EXITS[0], RULES.EXITS[0]), "Exit detection")
	_check(not RULES.is_near_exit(Vector2.ZERO, RULES.EXITS[0]), "Distant location is not an exit")
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
	scene.call("return_to_safe_hub")
	_check(str(scene.get("phase")) == "hub", "Leaving exploration returns to camp")
	_check(RULES.cargo_count(scene.get("carried_materials")) == 0, "Unsecured materials are lost")
	_check(not bool(scene.get("expedition_active")), "Ambient enemies stop at camp")
	_check((scene.get("hub_sortie_button") as Control).visible, "Another expedition is available")
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
