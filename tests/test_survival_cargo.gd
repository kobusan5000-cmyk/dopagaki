extends SceneTree
# The material pouch, food/water and combat survival must not overwrite gear.
const RULES = preload("res://scripts/extraction_rules.gd")
const SURVIVAL = preload("res://scripts/survival_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(SURVIVAL.decrease_need(100.0, 1.0, 10.0, 0) == 90.0, "Forest baseline metabolism")
	_check(SURVIVAL.decrease_need(100.0, 1.0, 10.0, 2) < 90.0, "Forbidden zone drains water faster")
	_check(SURVIVAL.decrease_need(0.0, 1.0, 99.0, 2) == 0.0, "Needs never become negative")
	_check(SURVIVAL.movement_factor(100.0, 100.0) == 1.0, "Healthy survivor moves normally")
	_check(SURVIVAL.movement_factor(5.0, 100.0) < 1.0, "Hungry survivor moves more slowly")
	_check(SURVIVAL.cache_water_chance(2) > SURVIVAL.cache_water_chance(0), "Risky caches more likely to contain water")
	_check(SURVIVAL.can_use_supply(1, 30.0), "Use existing supply when thirsty")
	_check(not SURVIVAL.can_use_supply(0, 30.0), "No free supply can be conjured")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	_check(str(scene.get("phase")) == "hub", "Survival starts in sanctuary")
	scene.call("start_sortie")
	_check(bool(scene.get("expedition_active")), "Explore mode started")
	var dangerous := Vector2(3100, 1650)
	scene.set("player", dangerous)
	scene.call("update_survival", 60.0)
	_check(float(scene.get("survival_hunger")) < 100.0, "Hunger decays outside camp")
	_check(float(scene.get("survival_thirst")) < 100.0, "Thirst decays outside camp")
	var previous_hunger: float = scene.get("survival_hunger")
	scene.set("player", Vector2(1170, 842))
	scene.call("update_survival", 30.0)
	_check(is_equal_approx(float(scene.get("survival_hunger")), previous_hunger), "Safe camp prevents food drain")
	var host_rations: int = scene.get("survival_rations")
	scene.set("survival_hunger", 40.0)
	scene.call("use_survival_supply", 0)
	_check(float(scene.get("survival_hunger")) == 82.0, "Ration restores hunger")
	_check(int(scene.get("survival_rations")) == host_rations - 1, "Ration consumed once")
	scene.set("survival_thirst", 30.0)
	scene.call("use_survival_supply", 1)
	_check(float(scene.get("survival_thirst")) == 78.0, "Water restores hydration")
	var host_supply: int = scene.get("survival_rations")
	scene.set("coop_guest_hunger", 10.0)
	scene.set("coop_guest_rations", 2)
	scene.call("coop_guest_use_survival_supply", 0)
	_check(float(scene.get("coop_guest_hunger")) == 52.0, "Guest hunger independently restored")
	_check(int(scene.get("coop_guest_rations")) == 1, "Guest consumes personal ration")
	_check(int(scene.get("survival_rations")) == host_supply, "Guest supplies do not consume host rations")
	# A full salvage pouch must not prevent a cache's gold or gear rolls.
	var full_scrap: Array[int] = [12, 0, 0]
	scene.set("carried_materials", full_scrap)
	var cache: Dictionary = (scene.get("search_crates") as Array)[0]
	scene.set("player", cache["pos"])
	var before_gold: int = scene.get("coins")
	var opened: bool = scene.call("interact_expedition_site")
	_check(opened and bool(cache["opened"]), "Full cargo still opens one-time cache")
	_check(int(scene.get("coins")) > before_gold, "Full cargo still awards gold")
	_check(RULES.cargo_count(scene.get("carried_materials")) == 12, "Cargo does not overflow")
	_check((scene.get("backpack") as Array).size() == 5, "Equipment bag remains separate")
	# Discarding one unit makes room for another material and cannot go negative.
	scene.call("discard_material", 0)
	_check(RULES.cargo_count(scene.get("carried_materials")) == 11, "Discard opens one cargo slot")
	var empty_scrap: Array[int] = [0, 0, 0]
	scene.set("carried_materials", empty_scrap)
	scene.call("discard_material", 0)
	_check((scene.get("carried_materials") as Array)[0] == 0, "Cannot discard negative cargo")
	# Starvation damages outside camp, but not while resting safely.
	scene.set("player", dangerous)
	scene.set("survival_hunger", 0.0)
	scene.set("survival_thirst", 0.0)
	scene.set("survival_damage_clock", SURVIVAL.STARVATION_DAMAGE_SECONDS - 0.5)
	var old_hp: float = scene.get("hp")
	scene.call("update_survival", 1.0)
	_check(float(scene.get("hp")) < old_hp, "Starving survivor loses health outside sanctuary")
	# Host-authoritative guest discard is bounded by cargo inventory.
	scene.set("phase", "hub")
	scene.set("expedition_active", false)
	scene.call("coop_host_pressed")
	var session: Node = scene.get("coop")
	session.peer_id = 2
	scene.set("phase", "combat")
	scene.set("expedition_active", true)
	var one_scrap: Array[int] = [1, 0, 0]
	scene.set("carried_materials", one_scrap)
	scene.call("_on_coop_guest_action", "discard_material", 0)
	_check((scene.get("carried_materials") as Array)[0] == 0, "Guest can discard one team cargo unit")
	scene.call("_on_coop_guest_action", "discard_material", 0)
	_check((scene.get("carried_materials") as Array)[0] == 0, "Repeat discard cannot duplicate negative salvage")
	session.peer_id = 0
	session.close_game()
	scene.queue_free()
	if failures > 0:
		push_error("Survival and cargo regression failures: %d" % failures)
	else:
		print("Survival and salvage pouch regressions passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
