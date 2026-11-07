extends RefCounted
## Deterministic, pure LUMI SLOT odds shared by solo and LAN guest spins.
## Setting 6 is fixed. No real-money gambling or user-adjustable odds.
const BIG_ODDS := 17.0
const REG_ODDS := 6.2
const GRAPE_ODDS := 6.0
const CHERRY_ODDS := 35.0
const REPLAY_ODDS := 7.3
const REG_RARITY_CUTOFFS := [0.75, 0.97] # common 75 / rare 22 / epic 3
const BIG_RARITY_CUTOFFS := [0.74, 0.97] # epic 74 / legendary 23 / mythic 3

static func outcome_for_roll(roll: float) -> String:
	if roll < 0.0 or roll >= 1.0:
		return "MISS"
	var cut := 1.0 / BIG_ODDS
	if roll < cut:
		return "BIG"
	cut += 1.0 / REG_ODDS
	if roll < cut:
		return "REG"
	cut += 1.0 / GRAPE_ODDS
	if roll < cut:
		return "GRAPE"
	cut += 1.0 / CHERRY_ODDS
	if roll < cut:
		return "CHERRY"
	cut += 1.0 / REPLAY_ODDS
	if roll < cut:
		return "REPLAY"
	return "MISS"

static func prize_rarity(outcome: String, roll: float) -> int:
	if roll < 0.0 or roll >= 1.0:
		return -1
	if outcome == "REG":
		return 0 if roll < REG_RARITY_CUTOFFS[0] else (1 if roll < REG_RARITY_CUTOFFS[1] else 2)
	if outcome == "BIG":
		return 2 if roll < BIG_RARITY_CUTOFFS[0] else (3 if roll < BIG_RARITY_CUTOFFS[1] else 4)
	return -1
