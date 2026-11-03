extends SceneTree
# New continuous-world flow: supplies, shelter transactions, death and persistence.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var file_path := "user://dopagaki_world_v1.json"
	var had_save := FileAccess.file_exists(file_path)
	var previous_data := ""
	if had_save:
		previous_data = FileAccess.get_file_as_string(file_path)
		DirAccess.remove_absolute(file_path)
	var scene: Node = load("res://scenes/survival_world.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.get("dead") == false, "A new survivor starts alive")
	_check((scene.get("caches") as Array).size() >= 80, "Explorable map provides numerous supply sites")
	var supply: Dictionary = scene.get("carried")
	supply["木材"] = 8
	supply["スクラップ"] = 5
	scene.set("survivor", Vector2(700, 750))
	scene.call("build_shelter")
	_check((scene.get("shelters") as Array).size() == 1, "Build a permanent shelter")
	_check(int(supply["木材"]) == 2 and int(supply["スクラップ"]) == 2, "Building consumes its exact ingredients")
	scene.call("interact")
	_check(int(supply["木材"]) == 0 and int(supply["スクラップ"]) == 0, "Depositing removes resources from backpack")
	var stored: Dictionary = scene.get("stored")
	_check(int(stored["木材"]) == 2 and int(stored["スクラップ"]) == 2, "Deposited resources survive in stash")
	scene.call("withdraw_from_shelter")
	_check(int(supply["木材"]) == 2 and int(stored["木材"]) == 0, "Withdrawal cannot mint duplicate resources")
	supply["飲料水"] = 1
	scene.set("water", 22.0)
	scene.call("use_item", "飲料水")
	_check(float(scene.get("water")) == 72.0 and int(supply["飲料水"]) == 0, "Drinking consumes one bottle")
	scene.call("interact")
	_check(int(stored["木材"]) == 2, "Shelter stash can be reused")
	scene.call("hurt", 10000.0)
	_check(bool(scene.get("dead")), "Lethal damage ends survivor life")
	_check((scene.get("corpses") as Array).size() == 1, "Corpse remains for gear recovery")
	_check(int(stored["木材"]) == 2, "Death does not wipe stashed items")
	scene.call("new_survivor")
	_check(not bool(scene.get("dead")), "R-equivalent starts a new survivor")
	_check(int((scene.get("carried") as Dictionary)["木材"]) == 0, "New survivor has no previous carried loot")
	_check(int((scene.get("stored") as Dictionary)["木材"]) == 2, "Shelter persists after respawn")
	scene.call("save_survivor")
	scene.queue_free()
	await process_frame
	var reopened: Node = load("res://scenes/survival_world.tscn").instantiate()
	root.add_child(reopened)
	await process_frame
	_check(int((reopened.get("stored") as Dictionary)["木材"]) == 2, "Stashed items survive reload")
	_check((reopened.get("shelters") as Array).size() == 1, "Built shelter survives reload")
	reopened.queue_free()
	await process_frame
	if had_save:
		var file := FileAccess.open(file_path, FileAccess.WRITE)
		if file != null:
			file.store_string(previous_data)
	else:
		DirAccess.remove_absolute(file_path)
	if failures == 0:
		print("Survival sandbox, death and shelter persistence passed.")
	else:
		push_error("Survival sandbox regression failures: %d" % failures)
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
