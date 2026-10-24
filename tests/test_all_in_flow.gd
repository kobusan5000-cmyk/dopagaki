extends SceneTree
# Headless in-game flow check. Never performs a cash-out or writes to the user's stash.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	_check(str(scene.get("state")) == "playing", "Class selection starts a run")

	scene.set("wave", 1)
	scene.set("phase", "combat")
	scene.call("advance_phase")
	_check(bool(scene.get("all_in_open")), "Wave1 opens build choice")
	_check(str(scene.get("all_in_stage")) == "upgrade", "Wave1 has no cash-out")
	var first_choices: Array = scene.get("all_in_options")
	_check(first_choices.size() == 3, "There are three different perks")
	if first_choices.size() == 3:
		_check(first_choices[0] != first_choices[1] and first_choices[1] != first_choices[2] and first_choices[0] != first_choices[2], "Perks are distinct")
		scene.call("select_all_in_perk", 0)
		_check(str(scene.get("phase")) == "rest", "Selecting perk resumes the timer")
		_check(not bool(scene.get("all_in_open")), "Selecting perk closes modal")
		_check((scene.get("all_in_stacks") as Dictionary).size() == 1, "Perk stored for this run")

	scene.set("wave", 3)
	scene.set("phase", "combat")
	scene.call("advance_phase")
	_check(str(scene.get("phase")) == "all_in", "Wave3 enters all-in phase")
	_check(str(scene.get("all_in_stage")) == "decision", "Wave3 offers extraction")
	_check(bool(scene.get("all_in_open")), "Wave3 freezes game for decision")
	# Let one frame pass to confirm that the all-in countdown does not elapse.
	var remaining: float = float(scene.get("phase_clock"))
	await process_frame
	_check(is_equal_approx(float(scene.get("phase_clock")), remaining), "No countdown during choice")
	scene.call("start_all_in_upgrades")
	_check(str(scene.get("all_in_stage")) == "upgrade", "ALL IN leads to perks")
	scene.call("show_all_in_decision")
	_check(str(scene.get("all_in_stage")) == "decision", "Back button returns to extraction")
	scene.queue_free()
	if failures > 0:
		push_error("ALL IN gameplay flow failed: %d" % failures)
	else:
		print("ALL IN gameplay flow passed.")
	quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + description)
