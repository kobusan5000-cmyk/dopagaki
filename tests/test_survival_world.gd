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
	var loadout = preload("res://scripts/survival_loadout.gd")
	_check(loadout.name_for(loadout.starter()).contains("SWORD"), "Classic sword is starting weapon")
	_check(loadout.is_ranged({"kind": 7, "rarity": 0, "condition": 100.0}), "Classic kunai has ranged identity")
	_check(loadout.damage_for({"kind": 3, "rarity": 2, "condition": 100.0}, 4) > loadout.damage_for(loadout.starter(), 0), "Legendary heavy weapons maintain progression")
	_check(loadout.clean_weapon({"kind": 800}).is_empty(), "Corrupt weapon kind rejected")

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
	# Existing character jobs are playable only near an established safe shelter.
	scene.call("select_class", 6)
	_check(int(scene.get("class_id")) == 6, "Choose classic Ninja job at the survivor shelter")
	# Simulate visiting a weapon cache without depending on random map placement.
	(scene.get("caches") as Array).clear()
	scene.set("survivor", Vector2(1100, 750))
	(scene.get("caches") as Array).append({"position": Vector2(1100, 750), "item": 0, "cooldown": 0.0, "weapon": {"kind": 7, "rarity": 2, "condition": 81.0}})
	scene.call("interact")
	_check((scene.get("weapon_inventory") as Array).size() == 1, "Discover existing weapon archetype in world loot")
	scene.call("cycle_weapon")
	var selected: Dictionary = scene.get("equipped_weapon")
	_check(int(selected.get("kind", -1)) == 7, "Switch to looted ninja kunai")
	_check((scene.get("weapon_inventory") as Array).size() == 1, "Starter sword moves to spare inventory without duplication")
	(scene.get("zombies") as Array).clear()
	(scene.get("zombies") as Array).append({"position": Vector2(1180, 750), "health": 100.0, "attack": 5.0})
	supply["弾薬"] = 2
	scene.set("look_dir", Vector2.RIGHT)
	scene.call("attack", true)
	_check(int(supply["弾薬"]) == 1, "Ranged attacks consume real ammunition")
	_check(float((scene.get("equipped_weapon") as Dictionary).get("condition", 100.0)) < 81.0, "Original weapon wear applies after shots")
	_check(float((scene.get("zombies") as Array)[0]["health"]) < 100.0, "Aimed weapon hits nearby infected")
	(scene.get("caches") as Array).append({"position": Vector2(1200, 750), "item": 0, "cooldown": 0.0, "armor": {"slot": 1, "rarity": 2}})
	scene.set("survivor", Vector2(1200, 750))
	scene.call("interact")
	_check(not (scene.get("armor") as Array)[1].is_empty(), "Classic body armor can be equipped from loot")
	var old_hp: float = scene.get("health")
	scene.call("hurt", 10.0, true)
	_check(float(scene.get("health")) > old_hp - 10.0, "Original armor protects against infected melee damage")
	# Stash/retrieve/repair weapons without minting extra copies.
	scene.set("survivor", Vector2(700, 750))
	scene.call("stash_equipped_weapon")
	_check((scene.get("stored_weapons") as Array).size() == 1, "Stash holds equipped weapon without overwriting starter sword")
	_check((scene.get("equipped_weapon") as Dictionary).is_empty(), "Stashed weapon leaves active hands empty")
	scene.call("withdraw_weapon")
	_check((scene.get("stored_weapons") as Array).is_empty(), "Withdrawal consumes stashed weapon exactly once")
	_check(int((scene.get("equipped_weapon") as Dictionary)["kind"]) == 7, "Withdrawn weapon restored to active hand")
	supply["スクラップ"] = 2
	var before_repair: float = (scene.get("equipped_weapon") as Dictionary)["condition"]
	scene.call("repair_equipped_weapon")
	_check(int(supply["スクラップ"]) == 0, "Repair consumes 2 scrap")
	_check(float((scene.get("equipped_weapon") as Dictionary)["condition"]) > before_repair, "Repair increases weapon condition")

	scene.call("hurt", 10000.0)
	_check(bool(scene.get("dead")), "Lethal damage ends survivor life")
	_check((scene.get("corpses") as Array).size() == 1, "Corpse remains for gear recovery")
	_check(int(stored["木材"]) == 2, "Death does not wipe stashed items")
	_check(not ((scene.get("corpses") as Array)[0]["equipped"] as Dictionary).is_empty(), "Dead survivor drops their equipped rare weapon")
	_check(not ((scene.get("corpses") as Array)[0]["armor"] as Array)[1].is_empty(), "Dead survivor drops their armor")

	scene.call("new_survivor")
	_check(not bool(scene.get("dead")), "R-equivalent starts a new survivor")
	_check(int((scene.get("carried") as Dictionary)["木材"]) == 0, "New survivor has no previous carried loot")
	_check(int((scene.get("stored") as Dictionary)["木材"]) == 2, "Shelter persists after respawn")
	_check((scene.get("weapon_inventory") as Array).is_empty(), "New survivor does not inherit deceased weapons")
	_check((scene.get("armor") as Array)[1].is_empty(), "New survivor does not inherit deceased armor")

	scene.call("save_survivor")
	scene.queue_free()
	await process_frame
	var reopened: Node = load("res://scenes/survival_world.tscn").instantiate()
	root.add_child(reopened)
	await process_frame
	_check(int((reopened.get("stored") as Dictionary)["木材"]) == 2, "Stashed items survive reload")
	_check((reopened.get("shelters") as Array).size() == 1, "Built shelter survives reload")
	_check((reopened.get("corpses") as Array).size() == 1, "Death loot and item records survive reload")
	var body: Dictionary = (reopened.get("corpses") as Array)[0]
	reopened.set("survivor", body["position"])
	reopened.call("interact")
	_check((reopened.get("weapon_inventory") as Array).size() >= 1, "Former inventory is reclaimable from persistent corpse")
	_check((reopened.get("corpses") as Array).is_empty(), "Recovered corpse cannot be looted twice")

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
