extends RefCounted
# DOPAGAKI v0.23 ALL IN: clear, visible risk/reward values.
# The RNG never silently modifies the stated reward multiplier.
const PERK_NAMES := [
	"連射加速", "破壊の力", "不屈の生命", "疾風の足", "弾幕増殖",
	"貫通の刃", "血の祝福", "連鎖爆発", "鋭い一撃"
]
const PERK_DESCRIPTIONS := [
	"攻撃速度 +18%（累積）",
	"武器ダメージ +22%（累積）",
	"最大HPと現在HP +35",
	"移動速度 +14%（累積）",
	"発射時に追加弾が左右へ飛ぶ",
	"弾の貫通数 +1",
	"敵を倒すたびHPを3回復",
	"敵撃破時に周囲へ爆発ダメージ",
	"クリティカル率 +6%"
]

static func reward_multiplier(wave: int) -> float:
	if wave < 3:
		return 1.0
	match wave:
		3: return 1.5
		4: return 1.8
		5: return 2.3
		6: return 3.0
	return minf(5.0, 3.0 + float(wave - 6) * 0.4)

static func danger_multiplier(wave: int) -> float:
	if wave <= 3:
		return 1.0
	return minf(1.75, 1.0 + float(wave - 3) * 0.12)

static func loot_chance_multiplier(wave: int) -> float:
	if wave < 3:
		return 1.0
	return minf(2.0, 1.0 + float(wave - 2) * 0.12)

static func can_extract(cleared_wave: int, phase_name: String) -> bool:
	return cleared_wave >= 3 and phase_name == "all_in"
