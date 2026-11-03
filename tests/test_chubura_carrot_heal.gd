extends SceneTree
# Test live carrot healing for Chubura, including co-op ownership validation.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	scene.set("player", Vector2(1200, 900))
	scene.set("rabbit_pet", Vector2(1230, 900))
	scene.set("rabbit_hp", 20.0)
	scene.set("rabbit_hunger", 100.0)
	scene.set("carrots", 2)
	scene.call("toggle_rabbit_menu")
	_check(bool(scene.get("rabbit_menu_open")), "Chubura care menu opens while injured")
	var buttons: Array = scene.get("rabbit_menu_buttons")
	_check(not (buttons[2] as Button).disabled, "Carrot healing available even when pet is full")
	scene.call("rabbit_action_selected", 2)
	_check(is_equal_approx(float(scene.get("rabbit_hp")), 45.0), "One carrot heals 25 HP")
	_check(int(scene.get("carrots")) == 1, "Healing consumes one actual carrot")
	_check(is_equal_approx(float(scene.get("rabbit_hunger")), 100.0), "Feeding never overfills hunger")
	_check(float(scene.get("rabbit_feed_cooldown")) > 0.0, "Healing enforces a cooldown")
	scene.call("rabbit_action_selected", 2)
	_check(int(scene.get("carrots")) == 1, "Repeated feeding during cooldown does not spend carrots")
	_check(is_equal_approx(float(scene.get("rabbit_hp")), 45.0), "Cooldown prevents spammable HP regeneration")
	scene.call("_process", 5.1)
	_check(float(scene.get("rabbit_feed_cooldown")) <= 0.0, "Cooldown counts down while menu is open")
	_check(not (buttons[2] as Button).disabled, "Heal button re-enables when cooldown ends")
	scene.call("rabbit_action_selected", 2)
	_check(is_equal_approx(float(scene.get("rabbit_hp")), 65.0), "Carrot heal caps at Chubura max HP")
	_check(int(scene.get("carrots")) == 0, "Second heal consumes last carrot")
	scene.set("carrots", 1)
	scene.set("rabbit_feed_cooldown", 0.0)
	scene.call("rabbit_action_selected", 2)
	_check(int(scene.get("carrots")) == 1, "Full HP and full hunger do not waste carrots")
	scene.set("rabbit_hp", 15.0)
	scene.set("rabbit_hunger", 40.0)
	scene.set("player", Vector2(1800, 1400))
	scene.call("rabbit_action_selected", 2)
	_check(int(scene.get("carrots")) == 1 and is_equal_approx(float(scene.get("rabbit_hp")), 15.0), "Cannot heal Chubura from across the map")
	scene.set("player", Vector2(1200, 900))
	scene.set("rabbit_hp", 0.0)
	scene.call("rabbit_action_selected", 2)
	_check(int(scene.get("carrots")) == 1, "Carrot does not replace soul-at-shrine revival")
	scene.set("rabbit_hp", 20.0)
	scene.call("toggle_rabbit_menu")
	scene.call("coop_host_pressed")
	var session: Node = scene.get("coop")
	session.peer_id = 2
	scene.set("rabbit_feed_cooldown", 0.0)
	scene.set("rabbit_hunger", 99.0)
	scene.set("rabbit_hp", 30.0)
	scene.set("carrots", 3)
	scene.set("coop_guest_carrots", 2)
	scene.set("coop_guest_pos", Vector2(1220, 910))
	scene.call("coop_guest_rabbit_action", 2)
	_check(is_equal_approx(float(scene.get("rabbit_hp")), 55.0), "Guest can heal shared Chubura within reach")
	_check(int(scene.get("coop_guest_carrots")) == 1, "Host charges guest's own carrot inventory")
	_check(int(scene.get("carrots")) == 3, "Guest healing leaves host's carrots untouched")
	scene.set("coop_guest_pos", Vector2(2400, 1850))
	scene.set("rabbit_feed_cooldown", 0.0)
	scene.call("coop_guest_rabbit_action", 2)
	_check(int(scene.get("coop_guest_carrots")) == 1, "Host rejects guest feeding from out of range")
	session.peer_id = 0
	session.close_game()
	scene.queue_free()
	if failures > 0:
		push_error("Chubura carrot healing failures: %d" % failures)
	else:
		print("Chubura carrot healing, cooldown, revival and co-op permissions passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
