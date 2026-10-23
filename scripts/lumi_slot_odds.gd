extends RefCounted
## Pure probability rules shared by LUMI SLOT and the world prize dispenser.
## Fantasy setting 6 is fixed; no player-controlled settings.
## Keep these values unchanged unless a separate game-balance change is approved.

const BIG_ODDS: float = 17.0
const REG_ODDS: float = 6.2
const BIG_EPIC_CUTOFF: float = 0.74
const BIG_LEGENDARY_CUTOFF: float = 0.97
const REG_COMMON_CUTOFF: float = 0.75
const REG_RARE_CUTOFF: float = 0.97


static func bonus_outcome(roll: float) -> String:
	if roll < 1.0 / BIG_ODDS:
		return "BIG"
	if roll < 1.0 / BIG_ODDS + 1.0 / REG_ODDS:
		return "REG"
	return ""


static func prize_rarity(outcome: String, roll: float) -> int:
	match outcome:
		"BIG":
			return 2 if roll < BIG_EPIC_CUTOFF else (3 if roll < BIG_LEGENDARY_CUTOFF else 4)
		"REG":
			return 0 if roll < REG_COMMON_CUTOFF else (1 if roll < REG_RARE_CUTOFF else 2)
	return -1
