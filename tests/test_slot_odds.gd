extends SceneTree
# Deterministic boundaries and exact probability mass, not random Monte Carlo.
const ODDS = preload("res://scripts/slot_odds_rules.gd")
const SLOT = preload("res://scripts/lumi_slot.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var big := 1.0 / ODDS.BIG_ODDS
	var reg := 1.0 / ODDS.REG_ODDS
	_check(is_equal_approx(big, 1.0 / 17.0), "Fixed setting 6 BIG is 1/17")
	_check(is_equal_approx(reg, 1.0 / 6.2), "Fixed setting 6 REG is 1/6.2")
	_check(absf(1.0 / (big + reg) - 4.5431) < 0.001, "Combined bonus odds approximately 1/4.54")
	_check(ODDS.outcome_for_roll(0.0) == "BIG", "BIG begins at zero")
	_check(ODDS.outcome_for_roll(big - 0.00001) == "BIG", "BIG upper edge")
	_check(ODDS.outcome_for_roll(big) == "REG", "REG starts immediately after BIG")
	_check(ODDS.outcome_for_roll(big + reg - 0.00001) == "REG", "REG upper edge")
	_check(ODDS.outcome_for_roll(big + reg) == "GRAPE", "Grape follows bonus range")
	_check(ODDS.outcome_for_roll(big + reg + 1.0 / ODDS.GRAPE_ODDS) == "CHERRY", "Cherry follows grape")
	_check(ODDS.outcome_for_roll(big + reg + 1.0 / ODDS.GRAPE_ODDS + 1.0 / ODDS.CHERRY_ODDS) == "REPLAY", "Replay follows cherry")
	_check(ODDS.outcome_for_roll(0.99999) == "MISS", "Miss remains possible")
	_check(ODDS.outcome_for_roll(-0.1) == "MISS", "Invalid roll cannot win")
	_check(ODDS.prize_rarity("REG", 0.0) == 0, "REG common lower bound")
	_check(ODDS.prize_rarity("REG", 0.74999) == 0, "REG common 75 percent")
	_check(ODDS.prize_rarity("REG", 0.75) == 1, "REG rare 22 percent")
	_check(ODDS.prize_rarity("REG", 0.96999) == 1, "REG rare upper bound")
	_check(ODDS.prize_rarity("REG", 0.97) == 2, "REG epic 3 percent")
	_check(ODDS.prize_rarity("BIG", 0.73999) == 2, "BIG epic 74 percent")
	_check(ODDS.prize_rarity("BIG", 0.74) == 3, "BIG legendary 23 percent")
	_check(ODDS.prize_rarity("BIG", 0.96999) == 3, "BIG legendary upper bound")
	_check(ODDS.prize_rarity("BIG", 0.97) == 4, "BIG mythic 3 percent")
	_check(ODDS.prize_rarity("MISS", 0.5) == -1, "No prize tier for miss")
	_check(ODDS.prize_rarity("BIG", 1.0) == -1, "Invalid prize roll rejected")
	var panel := SLOT.new()
	root.add_child(panel)
	await process_frame
	_check(is_equal_approx(panel.BIG_ODDS, ODDS.BIG_ODDS), "Solo panel uses shared BIG odds")
	_check(is_equal_approx(panel.REG_ODDS, ODDS.REG_ODDS), "Solo panel uses shared REG odds")
	panel.queue_free()
	if failures > 0:
		push_error("Slot odds regression failures: %d" % failures)
	else:
		print("Slot fixed-setting odds and rarity boundaries passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
