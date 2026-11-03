extends SceneTree
# Wear is deterministic per attack; tests restore banked materials.
const WEAR = preload("res://scripts/weapon_condition_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(is_equal_approx(WEAR.initial_condition(0.0, 0), 72.0), "Ordinary loot minimum condition")
	_check(is_equal_approx(WEAR.initial_condition(1.0, 0), 100.0), "Perfect loot is pristine")
	_check(WEAR.after_attack(100.0, 3) < WEAR.after_attack(100.0, 0), "Heavy sword wears more per attack")
	_check(is_equal_approx(WEAR.after_attack(0.0, 0), 0.0), "Condition never negative")
	_check(WEAR.power_factor(100.0) == 1.0 and WEAR.power_factor(0.0) >= 0.6, "Broken weapons retain reduced power instead of softlock")
	var bank: Array[int] = [3, 2, 0]
	_check(WEAR.can_repair(bank, 30.0), "Enough stored materials can repair damage")
	_check(not WEAR.can_repair(bank, 100.0), "Pristine gear cannot waste materials")
	_check(not WEAR.can_repair([1, 2, 0], 30.0), "Repair cannot bypass scrap cost")
	_check(WEAR.after_repair_cost(bank) == [1, 1, 0], "Repair spends correct scrap and core")
	_check(bank == [3, 2, 0], "Rules do not alter caller's bank")

	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	var original_materials: Array[int] = (scene.get("stored_materials") as Array[int]).duplicate()
	scene.call("start_sortie")
	scene.set("player", Vector2(3000.0, 1700.0))
	scene.call("attack")
	var active: Dictionary = scene.get("equipped")
	_check(float(active.get("condition", 100.0)) < 100.0, "Real attack wears equipped weapon")
	var after_one: float = float(active.get("condition", 100.0))
	scene.call("attack")
	_check(float(active.get("condition", 100.0)) < after_one, "Wear accumulates")
	# Restocking is not possible while still in combat.
	var spare: Array[int] = [7, 5, 0]
	scene.set("stored_materials", spare)
	scene.call("repair_weapon_for_actor", false)
	_check(is_equal_approx(float(active.get("condition", 100.0)), WEAR.after_attack(after_one, int(active["kind"]))), "No repairing during expedition")
	scene.call("return_to_safe_hub")
	var repair_bank: Array[int] = [7, 5, 0]
	scene.set("stored_materials", repair_bank)
	scene.set("player", Vector2(1390, 1085))
	scene.set("equipped", {"type": "weapon", "kind": 2, "rarity": 1, "name": "TEST SWORD", "condition": 27.0})
	scene.call("toggle_craft")
	_check(bool(scene.get("craft_open")), "Workbench opens for repair")
	scene.call("repair_equipped_weapon")
	_check(is_equal_approx(float((scene.get("equipped") as Dictionary).get("condition", 0.0)), 100.0), "Workbench restores equipped weapon")
	_check(scene.get("stored_materials") == [5, 4, 0], "Repair costs persistent salvage")
	var savings: Array[int] = (scene.get("stored_materials") as Array[int]).duplicate()
	scene.call("repair_equipped_weapon")
	_check(scene.get("stored_materials") == savings, "Repeated repair cannot spend on 100 percent condition")
	scene.call("toggle_craft")
	scene.call("coop_host_pressed")
	var session: Node = scene.get("coop")
	session.peer_id = 2
	scene.set("coop_guest_pos", Vector2(1390, 1085))
	scene.set("coop_guest_equipped", {"type": "weapon", "kind": 0, "rarity": 1, "name": "GUEST TEST PISTOL", "condition": 41.0})
	scene.call("_on_coop_guest_action", "repair", 1)
	_check(is_equal_approx(float((scene.get("coop_guest_equipped") as Dictionary).get("condition", 0.0)), 100.0), "Guest gets own weapon repaired on host")
	_check(scene.get("stored_materials") == [3, 3, 0], "Guest repair spends team salvage exactly once")
	var original_host_condition: float = float((scene.get("equipped") as Dictionary).get("condition", 0.0))
	_check(is_equal_approx(original_host_condition, 100.0), "Guest repair does not damage host equipment")
	scene.set("coop_guest_pos", Vector2(3000, 1700))
	scene.set("coop_guest_equipped", {"type": "weapon", "kind": 0, "rarity": 1, "name": "SECOND GUEST GUN", "condition": 4.0})
	savings = (scene.get("stored_materials") as Array[int]).duplicate()
	scene.call("_on_coop_guest_action", "repair", 1)
	_check(scene.get("stored_materials") == savings, "Remote guest repair blocked by workbench distance")
	session.peer_id = 0
	session.close_game()
	scene.set("stored_materials", original_materials)
	scene.call("save_stored_materials")
	scene.queue_free()
	if failures > 0:
		push_error("Weapon wear and repair regression failures: %d" % failures)
	else:
		print("Weapon condition and 2-player repairs passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
