extends SceneTree
# Smoke-test offline, hosting, and LAN co-op hooks without using permanent stash.
var failures := 0
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 6)
	var session: Node = scene.get("coop")
	_check(session != null, "Network session created")
	_check(session.get("name") == "CoopSession", "Stable network node path")
	_check(not session.is_guest(), "Solo is not a guest")
	_check(not session.is_host(), "Solo is not a host")
	_check(int(session.PORT) == 24566, "Default UDP port is stable")
	_check(int(session.MAX_PEERS) == 1, "At most one remote peer")
	_check((scene.get("coop_panel") as Control) != null, "Host/join UI created")
	_check(str(scene.get("phase")) == "hub", "Still in hub before hosting")
	scene.call("coop_host_pressed")
	_check(session.is_host(), "Host opens an ENet session")
	_check(session.peer_id == 0, "No phantom second player")
	var before_pos: Vector2 = scene.get("coop_guest_pos")
	scene.call("_on_coop_guest_controls", Vector2(50, 0), 0.0, true, false)
	# Input is normally validated by transport; host never trusts oversized moves.
	scene.call("coop_guest_tick", 0.05)
	_check((scene.get("coop_guest_pos") as Vector2).distance_to(before_pos) < 15.0, "Remote movement bounded per tick")
	scene.call("coop_leave_pressed")
	_check(not session.is_host(), "Closing session restores solo")
	_check(not session.is_guest(), "Closing session disconnects guest")
	_check(str(scene.get("state")) == "playing", "No solo gameplay reset")
	scene.queue_free()
	if failures == 0:
		print("Co-op LAN session smoke test passed.")
	else:
		push_error("Co-op LAN smoke test failed (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, name: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + name)
