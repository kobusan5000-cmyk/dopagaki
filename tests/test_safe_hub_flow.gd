extends SceneTree
# No disk writes: call the hub transition directly without performing cash-out.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 6)
	_check(int(scene.get("class_id")) == 6, "Ninja selected at start")
	_check(str(scene.get("state")) == "playing", "Game entered")
	var plots_before: Array = scene.get("farm_plots")
	_check(plots_before.size() > 0, "Farm plots present")
	plots_before[0]["progress"] = 4.25
	scene.set("seeds", 31)
	scene.set("rabbit_affection", 63.0)
	scene.set("wave", 4)
	scene.set("level", 9)
	scene.set("coins", 143)
	scene.call("return_to_safe_hub")
	_check(str(scene.get("state")) == "playing", "Same gameplay state, not class selection")
	_check(str(scene.get("phase")) == "hub", "Safe hub phase")
	_check(int(scene.get("class_id")) == 6, "Ninja class retained")
	_check(not (scene.get("choose_panel") as Control).visible, "No class chooser on return")
	_check((scene.get("hub_sortie_button") as Control).visible, "Sortie button shown")
	_check(int(scene.get("wave")) == 0, "No active wave in hub")
	_check(int(scene.get("level")) == 1, "In-run level reset")
	_check(int(scene.get("coins")) == 0, "In-run gold zero after extraction")
	_check(int(scene.get("seeds")) == 31, "Farm seeds remain")
	_check(is_equal_approx(float(scene.get("rabbit_affection")), 63.0), "Rabbit affection remains")
	var plots_after: Array = scene.get("farm_plots")
	_check(is_equal_approx(float(plots_after[0]["progress"]), 4.25), "Growing crops stay planted")
	_check(int((scene.get("equipped") as Dictionary).get("kind", -1)) == 7, "Ninja starter weapon, not default pistol")
	await process_frame
	_check(str(scene.get("phase")) == "hub", "Hub cannot auto-start a wave")
	scene.call("start_sortie")
	_check(str(scene.get("phase")) == "prep", "Deliberate sortie begins preparation")
	_check(int(scene.get("class_id")) == 6, "Sortie retains chosen class")
	_check(not (scene.get("hub_sortie_button") as Control).visible, "Sortie button hidden after departure")
	_check(int(scene.get("wave")) == 0, "First sortie wave begins from 1")
	_check(float(scene.get("phase_clock")) > 0.0, "Preparation countdown started")
	scene.queue_free()
	if failures > 0:
		push_error("Safe hub regression failures: %d" % failures)
	else:
		print("Safe hub flow passed.")
	quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + description)
