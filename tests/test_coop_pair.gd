extends SceneTree
# Launch twice in CI: -- --host and -- --guest
# Tests actual loopback ENet handshake plus guest-visible host world state.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--host"):
		scene.call("select_class", 0)
		scene.call("coop_host_pressed")
		_check(scene.get("coop").is_host(), "Host ENet server active")
		await create_timer(2.0).timeout
		_check(int(scene.get("coop").peer_id) > 1, "Host detected a guest over loopback UDP")
		scene.call("start_sortie")
		_check(bool(scene.get("expedition_active")), "Host launched expedition")
		await create_timer(2.1).timeout
		_check(int(scene.get("coop").peer_id) > 1, "Guest remains connected for world sync")
		# The client exits after its checks, so do not require it to remain
		# connected at the end of this extra window.
		await create_timer(2.4).timeout
	else:
		scene.call("select_class", 6)
		scene.get("coop_ip_input").text = "127.0.0.1"
		scene.call("coop_join_pressed")
		await create_timer(2.0).timeout
		_check(scene.get("coop").is_guest(), "Guest ENet client active")
		_check(str(scene.get("coop_connection_status")) == "接続済み", "Guest received host world snapshot")
		await create_timer(1.6).timeout
		_check(bool(scene.get("expedition_active")), "Guest received host expedition flag")
		_check((scene.get("enemies") as Array).size() > 0, "Guest received enemies from host")
		_check(str(scene.get("coop_remote_host_name")) == "Ookami", "Host identity replicated")
		_check(str(scene.get("phase")) == "combat", "Guest has entered the combat phase")
		# Reproduce the reported regression: the friend presses E inside the
		# physical safe camp after the host launched a sortie.
		var e := InputEventKey.new()
		e.keycode = KEY_E
		e.pressed = true
		scene.set("player", Vector2(1390, 1085))
		scene.call("_input", e)
		_check(bool(scene.get("stash_open")), "Guest can open stash with E during combat")
		if bool(scene.get("stash_open")):
			scene.call("toggle_stash")
		scene.set("player", Vector2(1780, 985))
		scene.call("_input", e)
		_check(bool(scene.get("merchant_open")), "Guest can open merchant with E during combat")
		if bool(scene.get("merchant_open")):
			scene.call("toggle_merchant")
		scene.set("player", Vector2(865, 895))
		scene.call("_input", e)
		_check(bool(scene.get("slot_open")), "Guest can open slot with E during combat")
		if bool(scene.get("slot_open")):
			scene.call("toggle_slot")
		scene.set("player", Vector2(1170, 842))
		scene.call("_input", e)
		_check(bool(scene.get("cooking_open")), "Guest can open cooking with E during combat")
		if bool(scene.get("cooking_open")):
			scene.call("toggle_cooking")
	scene.get("coop").close_game()
	scene.queue_free()
	if failures > 0:
		push_error("Two-process co-op network test failed: %d" % failures)
	else:
		print("Two-process co-op network connection and world sync passed.")
	quit(1 if failures > 0 else 0)

func _check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + label)
