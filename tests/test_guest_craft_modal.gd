extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	scene.set("player", Vector2(1390, 1085))
	scene.call("toggle_craft")
	_check(bool(scene.get("craft_open")), "Workbench opens in sanctuary")
	var panel: Control = scene.get("craft_panel")
	_check(panel.visible, "Workbench panel visible in sanctuary")
	scene.call("close_craft_on_remote_sortie")
	_check(bool(scene.get("craft_open")) and panel.visible, "Hub snapshot keeps crafting open")
	scene.set("phase", "combat")
	scene.set("expedition_active", true)
	scene.call("close_craft_on_remote_sortie")
	_check(not bool(scene.get("craft_open")), "Remote sortie closes workbench state")
	_check(not panel.visible, "Remote sortie hides workbench panel")
	scene.call("close_craft_on_remote_sortie")
	_check(not bool(scene.get("craft_open")), "Repeated snapshot is idempotent")
	scene.call("return_to_safe_hub")
	scene.set("player", Vector2(1390, 1085))
	scene.call("toggle_craft")
	_check(bool(scene.get("craft_open")) and panel.visible, "Workbench reopens after return")
	scene.queue_free()
	if failures > 0:
		push_error("Guest craft modal regression failed: %d" % failures)
	else:
		print("Guest craft modal regression passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
