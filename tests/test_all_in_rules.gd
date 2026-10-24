extends SceneTree
# Pure Godot regression tests; exit status controls GitHub PR validation.
const RULES = preload("res://scripts/all_in_rules.gd")
var failures := 0

func _initialize() -> void:
	_check(RULES.reward_multiplier(1) == 1.0, "WAVE1 multiplier")
	_check(RULES.reward_multiplier(2) == 1.0, "WAVE2 multiplier")
	_check(is_equal_approx(RULES.reward_multiplier(3), 1.5), "WAVE3 payout")
	_check(is_equal_approx(RULES.reward_multiplier(4), 1.8), "WAVE4 payout")
	_check(is_equal_approx(RULES.reward_multiplier(5), 2.3), "WAVE5 payout")
	_check(is_equal_approx(RULES.reward_multiplier(6), 3.0), "WAVE6 payout")
	_check(RULES.reward_multiplier(100) <= 5.0, "WAVE cap")
	_check(RULES.danger_multiplier(3) == 1.0, "Safe early waves")
	_check(RULES.danger_multiplier(5) > RULES.danger_multiplier(4), "Difficulty escalation")
	_check(RULES.danger_multiplier(100) <= 1.75, "Difficulty cap")
	_check(RULES.loot_chance_multiplier(8) > RULES.loot_chance_multiplier(3), "Loot grows with danger")
	_check(not RULES.can_extract(2, "all_in"), "No extraction before WAVE3")
	_check(not RULES.can_extract(4, "combat"), "No extraction during WAVE")
	_check(not RULES.can_extract(4, "rest"), "No extraction outside decision")
	_check(RULES.can_extract(3, "all_in"), "WAVE3 clear permits extraction")
	_check(RULES.PERK_NAMES.size() == 9 and RULES.PERK_DESCRIPTIONS.size() == 9, "Each perk has a description")
	if failures > 0:
		push_error("ALL IN regressions failed: %d" % failures)
	else:
		print("ALL IN regression tests passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, name: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + name)
