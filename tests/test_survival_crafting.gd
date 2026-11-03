extends SceneTree
# CI uses an isolated Godot user:// directory; all crafting tests restore
# their material balance before exiting.
const RULES = preload("res://scripts/crafting_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sample: Array[int] = [5, 2, 1]
	_check(RULES.can_craft(0, sample, 0, 0, 2), "Purifier: scrap and core make water")
	_check(not RULES.can_craft(0, [5, 0, 1], 0, 0, 2), "Missing power core blocks purifier")
	_check(RULES.can_craft(1, sample, 2, 0, 1), "Rations need scrap and carrots")
	_check(not RULES.can_craft(1, sample, 1, 0, 1), "Rations cannot ignore carrot cost")
	_check(RULES.can_craft(2, sample, 0, 1, 0), "Bandage needs mushrooms and scrap")
	_check(not RULES.can_craft(2, sample, 0, 1, 3), "Bandage capacity cannot be exceeded")
	_check(not RULES.can_craft(99, sample, 10, 10, 0), "Invalid recipe rejected")
	var remaining: Array[int] = RULES.remaining_materials(0, sample)
	_check(remaining == [3, 1, 1], "Consume exact banked material cost")
	_check(sample == [5, 2, 1], "Pure rules never mutate original materials")

	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	var initial: Array[int] = (scene.get("stored_materials") as Array[int]).duplicate()
	scene.set("stored_materials", [10, 10, 10] as Array[int])
	scene.set("player", Vector2(1390, 1085))
	_check(str(scene.get("phase")) == "hub", "Workbench only in hub")
	scene.call("toggle_craft")
	_check(bool(scene.get("craft_open")), "N-equivalent opens crafting panel")
	scene.set("survival_water", 2)
	scene.call("craft_recipe", 0)
	_check(int(scene.get("survival_water")) == 4, "Water craft supplies two bottles")
	_check(scene.get("stored_materials") == [8, 9, 10], "Water craft costs scrap and core")
	scene.set("carrots", 5)
	scene.set("survival_rations", 0)
	scene.call("craft_recipe", 1)
	_check(int(scene.get("survival_rations")) == 2, "Craft two emergency rations")
	_check(int(scene.get("carrots")) == 3, "Ration craft consumes carrots")
	scene.set("mushrooms", 3)
	scene.set("survival_bandages", 0)
	scene.call("craft_recipe", 2)
	_check(int(scene.get("survival_bandages")) == 1, "Bandage craft awards one kit")
	_check(int(scene.get("mushrooms")) == 2, "Bandage craft consumes mushroom")
	scene.set("hp", 20.0)
	scene.call("use_bandage")
	_check(is_equal_approx(float(scene.get("hp")), 65.0), "Using bandage restores 45 HP")
	_check(int(scene.get("survival_bandages")) == 0, "Used bandage is consumed")
	# A distant or deployed player cannot forge free crafts.
	scene.set("player", Vector2(3000, 1700))
	var before: Array[int] = (scene.get("stored_materials") as Array[int]).duplicate()
	scene.call("craft_recipe", 0)
	_check(scene.get("stored_materials") == before, "Remote crafting is rejected")
	scene.set("player", Vector2(1390, 1085))
	scene.call("toggle_craft")
	scene.call("start_sortie")
	_check(bool(scene.get("expedition_active")), "Expedition launched normally")
	scene.call("craft_for_actor", 0, false)
	_check(scene.get("stored_materials") == before, "Cannot craft mid-sortie")
	# Host can craft for the guest using team materials but not host consumables.
	scene.call("return_to_safe_hub")
	scene.call("coop_host_pressed")
	var coop: Node = scene.get("coop")
	coop.peer_id = 2
	scene.set("coop_guest_pos", Vector2(1390, 1085))
	scene.set("coop_guest_water", 0)
	scene.set("survival_water", 4)
	scene.call("_on_coop_guest_action", "craft", 0)
	_check(int(scene.get("coop_guest_water")) == 2, "Guest receives crafted water through host RPC")
	_check(int(scene.get("survival_water")) == 4, "Guest crafting does not grant host supplies")
	var finished: Array[int] = (scene.get("stored_materials") as Array[int]).duplicate()
	scene.set("coop_guest_pos", Vector2(3000, 1700))
	scene.call("_on_coop_guest_action", "craft", 0)
	_check(scene.get("stored_materials") == finished, "Host rejects remote guest crafting")
	scene.set("coop_guest_pos", Vector2(1390, 1085))
	scene.set("coop_guest_bandages", 1)
	scene.set("coop_guest_hp", 35.0)
	scene.call("_on_coop_guest_action", "bandage", 1)
	_check(is_equal_approx(float(scene.get("coop_guest_hp")), 80.0), "Guest bandage heals guest")
	_check(int(scene.get("coop_guest_bandages")) == 0, "Guest bandage consumed exactly once")
	coop.peer_id = 0
	coop.close_game()
	scene.set("stored_materials", initial)
	scene.call("save_stored_materials")
	scene.queue_free()
	if failures > 0:
		push_error("Field crafting regression failed: %d" % failures)
	else:
		print("Field crafting and co-op crafting regressions passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
