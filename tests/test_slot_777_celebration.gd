extends SceneTree
# BIG jackpot celebration must not change the underlying slot result or payout.
const SLOT = preload("res://scripts/lumi_slot.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: PanelContainer = SLOT.new()
	root.add_child(panel)
	await process_frame
	var result_events: Array = []
	panel.spin_resolved.connect(func(outcome: String, payout: int) -> void:
		result_events.append([outcome, payout])
	)
	var player: AudioStreamPlayer = panel.get("jackpot_sound_player")
	_check(player != null, "Jackpot audio player created")
	if player != null:
		var sound: AudioStreamWAV = player.stream as AudioStreamWAV
		_check(sound != null and sound.data.size() > 30000, "Original winning jingle is generated")
	panel.call("begin_spin")
	panel.set("result_name", "BIG")
	panel.set("spin_time", 1.0)
	for index in range(3):
		panel.call("stop_reel", index)
	_check(result_events.size() == 1, "BIG emits exactly one resolved event")
	if result_events.size() >= 1:
		_check(result_events[0] == ["BIG", SLOT.ROLE_PAYOUT["BIG"]], "BIG pays exactly the existing 160G")
	_check(not bool(panel.get("spinning")), "BIG spin completes")
	_check(int(panel.get("games")) == 1 and int(panel.get("big_count")) == 1, "BIG counted once")
	_check(float(panel.get("jackpot_flash_clock")) > 0.0, "777 activates rainbow animation")
	_check((panel.get("jackpot_banner") as Label).visible, "777 banner becomes visible")
	panel.call("stop_reel", 2)
	_check(result_events.size() == 1, "Repeated STOP cannot duplicate prize")
	panel.call("_process", SLOT.JACKPOT_FLASH_SECONDS + 0.1)
	_check(not (panel.get("jackpot_banner") as Label).visible, "Rainbow banner expires")
	_check(is_equal_approx(float(panel.get("jackpot_flash_clock")), 0.0), "Jackpot clock resets after animation")
	panel.call("begin_spin")
	panel.set("result_name", "REG")
	panel.set("spin_time", 1.0)
	for index in range(3):
		panel.call("stop_reel", index)
	_check(result_events.size() == 2, "REG also emits exactly one event")
	_check(float(panel.get("jackpot_flash_clock")) == 0.0, "REG does not trigger 777 animation")
	_check(not (panel.get("jackpot_banner") as Label).visible, "REG has no 777 banner")
	panel.call("prepare_new_game")
	_check(float(panel.get("jackpot_flash_clock")) == 0.0, "Session reset clears active celebration")
	panel.queue_free()
	if failures > 0:
		push_error("LUMI 777 celebration regressions failed: %d" % failures)
	else:
		print("LUMI 777 animation, audio and single payout passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
