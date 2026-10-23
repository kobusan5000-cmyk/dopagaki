extends SceneTree
## Run: godot --headless --path . --script res://tests/test_lumi_slot_odds.gd
## Uses actual Godot scripts (not source-text matching), seeded RNG and exact boundaries.

const ODDS = preload("res://scripts/lumi_slot_odds.gd")
const SLOT_SCRIPT = preload("res://scripts/lumi_slot.gd")
const SPINS := 100000
const PRIZES := 100000

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, detail: String) -> void:
	if not condition:
		failures.append(detail)


func _run() -> void:
	# Exact setting-6 configuration and threshold boundaries.
	_check(is_equal_approx(ODDS.BIG_ODDS, 17.0), "BIG odds must remain 1/17")
	_check(is_equal_approx(ODDS.REG_ODDS, 6.2), "REG odds must remain 1/6.2")
	var combined: float = 1.0 / (1.0 / ODDS.BIG_ODDS + 1.0 / ODDS.REG_ODDS)
	_check(absf(combined - 4.54) < 0.01, "Combined bonus odds must be about 1/4.54")
	var big_edge: float = 1.0 / ODDS.BIG_ODDS
	var reg_edge: float = big_edge + 1.0 / ODDS.REG_ODDS
	_check(ODDS.bonus_outcome(0.0) == "BIG", "BIG start boundary")
	_check(ODDS.bonus_outcome(big_edge - 0.000001) == "BIG", "BIG end boundary")
	_check(ODDS.bonus_outcome(big_edge) == "REG", "REG start boundary")
	_check(ODDS.bonus_outcome(reg_edge - 0.000001) == "REG", "REG end boundary")
	_check(ODDS.bonus_outcome(reg_edge) == "", "Non-bonus start boundary")

	# Exact prize rarity bands; the same function is used by the live world dispenser.
	_check(ODDS.prize_rarity("REG", 0.0) == 0, "REG common start")
	_check(ODDS.prize_rarity("REG", 0.749999) == 0, "REG common end")
	_check(ODDS.prize_rarity("REG", 0.75) == 1, "REG rare start")
	_check(ODDS.prize_rarity("REG", 0.969999) == 1, "REG rare end")
	_check(ODDS.prize_rarity("REG", 0.97) == 2, "REG epic start")
	_check(ODDS.prize_rarity("BIG", 0.0) == 2, "BIG epic start")
	_check(ODDS.prize_rarity("BIG", 0.739999) == 2, "BIG epic end")
	_check(ODDS.prize_rarity("BIG", 0.74) == 3, "BIG legendary start")
	_check(ODDS.prize_rarity("BIG", 0.969999) == 3, "BIG legendary end")
	_check(ODDS.prize_rarity("BIG", 0.97) == 4, "BIG mythic start")
	_check(ODDS.prize_rarity("MISS", 0.5) == -1, "No prize rarity for MISS")

	# Exercise the live slot outcome function, not a duplicated probability model.
	var slot = SLOT_SCRIPT.new()
	root.add_child(slot)
	_check(slot.odds_label.text.contains("BIG 1/17.0"), "Visible BIG odds must be fixed")
	_check(slot.odds_label.text.contains("REG 1/6.2"), "Visible REG odds must be fixed")
	_check(slot.find_children("*", "OptionButton", true, false).is_empty(), "No setting selector allowed")
	_check(int(SLOT_SCRIPT.ROLE_PAYOUT["BIG"]) == 160, "BIG payout must stay 160G")
	_check(int(SLOT_SCRIPT.ROLE_PAYOUT["REG"]) == 60, "REG payout must stay 60G")
	slot.rng.seed = 20261024
	var bonus_counts := {"BIG": 0, "REG": 0}
	for i in range(SPINS):
		var outcome: String = slot._draw_outcome()
		if bonus_counts.has(outcome):
			bonus_counts[outcome] += 1
	for outcome in ["BIG", "REG"]:
		var target: float = 1.0 / (ODDS.BIG_ODDS if outcome == "BIG" else ODDS.REG_ODDS)
		var observed: float = float(bonus_counts[outcome]) / float(SPINS)
		_check(absf(observed - target) < 0.004, "%s frequency: got %.5f expected %.5f" % [outcome, observed, target])
	slot.queue_free()

	# Seeded Monte Carlo verifies every REG and BIG prize tier at the actual cutoffs.
	var prize_rng := RandomNumberGenerator.new()
	prize_rng.seed = 20261025
	var expected := {
		"REG": {0: 0.75, 1: 0.22, 2: 0.03},
		"BIG": {2: 0.74, 3: 0.23, 4: 0.03},
	}
	for outcome in ["REG", "BIG"]:
		var rarity_counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
		for i in range(PRIZES):
			var rarity: int = ODDS.prize_rarity(outcome, prize_rng.randf())
			rarity_counts[rarity] += 1
		for rarity in expected[outcome]:
			var observed: float = float(rarity_counts[rarity]) / float(PRIZES)
			var target: float = float(expected[outcome][rarity])
			_check(absf(observed - target) < 0.008, "%s tier %d: got %.5f expected %.5f" % [outcome, rarity, observed, target])

	if failures.is_empty():
		print("PASS: LUMI SLOT setting 6, boundaries, %d live spins and %d rarity draws per bonus" % [SPINS, PRIZES])
		quit(0)
	else:
		for failure in failures:
			push_error("LUMI SLOT REGRESSION: " + failure)
		print("FAIL: %d LUMI SLOT regression assertion(s)" % failures.size())
		quit(1)
