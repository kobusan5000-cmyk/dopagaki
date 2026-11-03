extends SceneTree
# Host-authoritative multiplayer parity regression: no real guest and no stash writes.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	scene.call("coop_host_pressed")
	var session: Node = scene.get("coop")
	_check(session.is_host(), "Host opens authoritative session")
	# Test an authenticated guest actor without a live ENet peer.
	session.peer_id = 2
	scene.set("coop_snapshot_clock", 99999.0)
	scene.call("_on_coop_introduced", 5, "TEST")
	_check(int((scene.get("coop_guest_equipped") as Dictionary)["kind"]) == 6, "Guest receives healer starter staff")
	_check(is_equal_approx(float(scene.get("coop_guest_max_hp")), 115.0), "Healer guest max HP")

	# Skill cast uses guest HP, MP and class; host's character must not change.
	scene.set("phase", "combat")
	scene.set("coop_guest_pos", Vector2(2900, 1700))
	scene.set("coop_guest_hp", 32.0)
	scene.set("coop_guest_level", 5)
	scene.set("coop_guest_mp", 30.0)
	var host_hp: float = scene.get("hp")
	var host_job: int = scene.get("class_id")
	scene.call("_on_coop_guest_action", "skill", 1)
	_check(float(scene.get("coop_guest_hp")) > 32.0, "Guest healer skill heals guest")
	_check(is_equal_approx(float(scene.get("coop_guest_mp")), 12.0), "Guest skill costs MP")
	_check(is_equal_approx(float(scene.get("hp")), host_hp), "Guest skill does not heal host")
	_check(int(scene.get("class_id")) == host_job, "Host class unchanged by guest skill")
	var skill_fx := false
	for event in scene.get("coop_fx_events"):
		if str(event.get("kind", "")) == "skill":
			skill_fx = true
	_check(skill_fx, "Guest skill creates synchronized FX event")

	# Guard and perfect parry prevent damage only within the frontal arc.
	scene.set("coop_guest_hp", 100.0)
	scene.set("coop_guest_guard", true)
	scene.set("coop_guest_aim", 0.0)
	scene.set("coop_guest_guard_parry_clock", 0.2)
	var at: Vector2 = scene.get("coop_guest_pos")
	scene.call("coop_guest_receive_hit", 40.0, at + Vector2(60, 0), {})
	_check(is_equal_approx(float(scene.get("coop_guest_hp")), 100.0), "Guest perfect parry blocks frontal damage")
	_check(is_equal_approx(float(scene.get("coop_guest_guard_parry_clock")), 0.0), "Parry window consumed once")
	var parry_fx := false
	for event in scene.get("coop_fx_events"):
		if str(event.get("kind", "")) == "parry":
			parry_fx = true
	_check(parry_fx, "Guest parry creates synchronized FX event")
	scene.call("coop_guest_receive_hit", 40.0, at + Vector2(60, 0), {})
	_check(float(scene.get("coop_guest_hp")) < 100.0, "Following guard takes reduced damage")

	# Both player actors have a 20-second downed state and E-equivalent rescue.
	scene.set("coop_guest_guard", false)
	scene.set("coop_guest_hp", 5.0)
	scene.call("coop_guest_receive_hit", 40.0, at + Vector2(60, 0), {})
	_check(is_equal_approx(float(scene.get("coop_guest_downed_clock")), 20.0), "Guest down timer starts at 20 seconds")
	scene.call("coop_revive_guest")
	_check(is_equal_approx(float(scene.get("coop_guest_hp")), 45.0), "Host revives guest with 45 HP")
	_check(is_equal_approx(float(scene.get("coop_guest_downed_clock")), 0.0), "Guest timer clears on revive")
	scene.set("hp", 0.0)
	scene.call("player_died")
	_check(is_equal_approx(float(scene.get("coop_host_downed_clock")), 20.0), "Host also gets 20-second down timer")
	_check(str(scene.get("state")) == "playing", "Host down does not freeze world")
	scene.set("coop_guest_pos", scene.get("player") + Vector2(40, 0))
	scene.call("coop_process_guest_interaction")
	_check(is_equal_approx(float(scene.get("hp")), 45.0), "Guest can revive host using interaction")
	_check(is_equal_approx(float(scene.get("coop_host_downed_clock")), 0.0), "Host timer clears on rescue")

	# Separate guest spending, food use and inventory dropping.
	scene.set("phase", "hub")
	scene.set("coop_guest_pos", Vector2(1780, 985))
	scene.set("coop_guest_coins", 100)
	scene.set("coop_guest_seeds", 8)
	var host_coins: int = scene.get("coins")
	scene.call("coop_guest_buy", 4)
	_check(int(scene.get("coop_guest_coins")) == 88, "Guest merchant purchase debits own wallet")
	_check(int(scene.get("coop_guest_seeds")) == 11, "Guest merchant purchase delivers seeds")
	_check(int(scene.get("coins")) == host_coins, "Merchant never debits host wallet")
	scene.set("coop_guest_pos", Vector2(2900, 1700))
	scene.call("coop_guest_buy", 4)
	_check(int(scene.get("coop_guest_coins")) == 88, "Guest purchase rejected when away from shop")

	scene.set("coop_guest_hp", 25.0)
	scene.set("coop_guest_stew_meals", 1)
	scene.call("coop_guest_eat", 0)
	_check(is_equal_approx(float(scene.get("coop_guest_hp")), 65.0), "Guest food heals guest")
	_check(int(scene.get("coop_guest_stew_meals")) == 0, "Guest meal consumed exactly once")
	_check(is_equal_approx(float(scene.get("hp")), 45.0), "Guest food does not heal host")

	# A crop seed drop is collectable by the guest regardless of expedition state.
	scene.set("expedition_active", true)
	var seed_pos := Vector2(2900, 1700)
	var seed_drops: Array = scene.get("crop_drops")
	seed_drops.append({"pos": seed_pos, "crop": 1, "life": 65.0, "phase": 0.0})
	var seed_count: int = scene.get("coop_guest_melon_seeds")
	scene.call("coop_process_guest_interaction")
	_check(int(scene.get("coop_guest_melon_seeds")) == seed_count + 1, "Guest picks up expedition crop seed")
	_check((scene.get("crop_drops") as Array).is_empty(), "Guest seed pickup consumes ground drop")

	# Wager and claims run on host; duplicate claims never mint currency.
	scene.set("phase", "hub")
	scene.set("expedition_active", false)
	scene.set("coop_guest_pos", Vector2(865, 895))
	scene.set("coop_guest_coins", 100)
	scene.call("coop_guest_slot_wager", 25)
	_check(int(scene.get("coop_guest_coins")) == 75, "Guest slot wager charged once")
	_check(bool(scene.get("coop_guest_slot_pending")), "Guest spin is pending")
	var serial: int = scene.get("coop_guest_slot_serial")
	scene.call("coop_guest_slot_claim", serial - 1)
	_check(bool(scene.get("coop_guest_slot_pending")), "Forged claim serial rejected")
	scene.call("coop_guest_slot_claim", serial)
	_check(not bool(scene.get("coop_guest_slot_pending")), "Valid spin serial claimed")
	var after_claim: int = scene.get("coop_guest_coins")
	scene.call("coop_guest_slot_claim", serial)
	_check(int(scene.get("coop_guest_coins")) == after_claim, "Duplicate claim cannot pay twice")

	# Once the host starts a sortie, safe-camp machines must keep working
	# for the guest without granting access from outside the interaction radius.
	scene.set("phase", "combat")
	scene.set("expedition_active", true)
	scene.set("wave", 3)
	scene.set("coop_guest_pos", Vector2(1780, 985))
	scene.set("coop_guest_coins", 100)
	scene.set("coop_guest_seeds", 10)
	scene.call("_on_coop_guest_action", "buy", 4)
	_check(int(scene.get("coop_guest_coins")) == 88, "Guest purchase works at safe-camp merchant during combat")
	_check(int(scene.get("coop_guest_seeds")) == 13, "Guest receives combat-phase merchant purchase")
	scene.set("coop_guest_pos", Vector2(865, 895))
	scene.set("coop_guest_slot_pending", false)
	scene.set("coop_guest_slot_replay", false)
	scene.call("_on_coop_guest_action", "slot_wager", 25)
	_check(int(scene.get("coop_guest_coins")) == 63, "Guest slot charges own wallet during combat")
	_check(bool(scene.get("coop_guest_slot_pending")), "Guest slot spins during combat")
	var active_spin: int = scene.get("coop_guest_slot_serial")
	scene.call("coop_guest_slot_claim", active_spin)
	scene.set("coop_guest_pos", Vector2(2900, 1700))
	scene.set("coop_guest_slot_pending", false)
	scene.set("coop_guest_slot_replay", false)
	var remote_balance: int = scene.get("coop_guest_coins")
	scene.call("_on_coop_guest_action", "slot_wager", 25)
	_check(int(scene.get("coop_guest_coins")) == remote_balance, "Combat-phase slot rejects distant guests")
	scene.call("_on_coop_guest_action", "buy", 4)
	_check(int(scene.get("coop_guest_coins")) == remote_balance, "Combat-phase merchant rejects distant guests")
	# Restore peaceful hub for jail release tests.
	scene.set("expedition_active", false)

	# Jail can be resolved symmetrically by teammate E, and guest R in the hub.
	scene.set("phase", "hub")
	scene.set("coop_host_jailed", true)
	scene.set("hp", 0.0)
	scene.set("coop_guest_hp", 100.0)
	scene.set("coop_guest_pos", scene.get("player") + Vector2(35.0, 0))
	scene.call("coop_process_guest_interaction")
	_check(not bool(scene.get("coop_host_jailed")), "Guest E releases host from jail")
	_check(is_equal_approx(float(scene.get("hp")), 45.0), "Host jail release recovers HP")
	scene.set("coop_guest_jailed", true)
	scene.set("coop_guest_hp", 0.0)
	scene.set("coop_guest_pos", scene.get("player") + Vector2(35.0, 0))
	scene.call("interact_nearby")
	_check(not bool(scene.get("coop_guest_jailed")), "Host E releases guest from jail")
	_check(is_equal_approx(float(scene.get("coop_guest_hp")), 45.0), "Guest jail release recovers HP")
	scene.set("coop_guest_jailed", true)
	scene.set("coop_guest_hp", 0.0)
	scene.call("_on_coop_guest_action", "release", 1)
	_check(not bool(scene.get("coop_guest_jailed")), "Guest hub R-equivalent release is honored")
	_check(is_equal_approx(float(scene.get("coop_guest_hp")), float(scene.get("coop_guest_max_hp"))), "Guest home release fully restores HP")

	# A peer disconnect cannot strand the remaining host in a downed state.
	scene.set("coop_host_downed_clock", 12.0)
	scene.set("hp", 0.0)
	scene.call("_on_coop_peer_disconnected", 2)
	_check(is_equal_approx(float(scene.get("coop_host_downed_clock")), 0.0), "Disconnect clears host rescue timer")
	_check(float(scene.get("hp")) > 0.0, "Disconnected host can resume solo play")
	session.peer_id = 0
	scene.get("coop").close_game()
	scene.queue_free()
	if failures > 0:
		push_error("Co-op gameplay parity regression failed: %d" % failures)
	else:
		print("Co-op gameplay parity regression passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
