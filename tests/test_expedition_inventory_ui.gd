extends SceneTree
# UI/inventory regression: no writes to the user's saved equipment or materials.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	_check(str(scene.get("phase")) == "hub", "Class choice starts in peaceful hub")
	var sortie: Button = scene.get("hub_sortie_button")
	var panel: Control = scene.get("inventory_panel")
	var materials: Label = scene.get("inventory_materials_label")
	_check(sortie.visible, "Sortie button visible when hub menus closed")

	scene.call("toggle_inventory")
	await process_frame
	_check(panel.visible, "Bag opens")
	_check(not sortie.visible, "Sortie button hidden while bag is open")
	scene.call("toggle_inventory")
	await process_frame
	_check(sortie.visible, "Sortie button returns when bag closes")

	scene.call("start_sortie")
	_check(bool(scene.get("expedition_active")), "Exploration started")
	scene.set("carried_materials", [2, 3, 1])
	scene.call("refresh_inventory_ui")
	_check(materials.visible, "Materials shown inside bag during exploration")
	_check(materials.text.contains("探索素材 6/12"), "Material capacity text")
	_check(materials.text.contains("スクラップ 2"), "Scrap amount displayed")
	_check(materials.text.contains("電力コア 3"), "Core amount displayed")
	_check(materials.text.contains("古代結晶 1"), "Crystal amount displayed")

	var ground_items: Array = scene.get("drops")
	ground_items.append({"type": "weapon", "rarity": 1, "name": "TEST RARE SWORD", "kind": 2, "trait": 0, "bonus": 1.0, "pos": Vector2.ZERO})
	var picked: bool = scene.call("auto_collect_expedition_gear")
	var bag: Array = scene.get("backpack")
	_check(picked, "Available gear slot automatically collects exploration drop")
	_check(str((bag[0] as Dictionary).get("name", "")) == "TEST RARE SWORD", "Real gear arrives in bag")
	_check(ground_items.is_empty(), "Collected gear removed from world")

	# All 5 equipment slots full: valuables must not silently disappear.
	for i in range(1, bag.size()):
		bag[i] = bag[0].duplicate(true)
	ground_items.append({"type": "weapon", "rarity": 2, "name": "TEST EPIC", "kind": 2, "trait": 0, "bonus": 1.0, "pos": Vector2.ZERO})
	picked = scene.call("auto_collect_expedition_gear")
	_check(not picked, "Full equipment bag blocks automatic pickup")
	_check(ground_items.size() == 1, "Gear stays on ground when equipment bag full")
	_check(str(ground_items[0]["name"]) == "TEST EPIC", "Original gear is still available for manual E pickup")
	_check((scene.get("carried_materials") as Array)[0] == 2, "Materials do not consume gear slots")

	scene.queue_free()
	if failures > 0:
		push_error("Exploration inventory test failures: %d" % failures)
	else:
		print("Exploration inventory UI and loot test passed.")
	quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + description)
