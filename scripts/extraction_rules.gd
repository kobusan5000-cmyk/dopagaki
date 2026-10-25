extends RefCounted
# v0.25: a finite, no-wave extraction map built on the existing large ARENA.
const MATERIAL_NAMES := ["スクラップ", "電力コア", "古代結晶"]
const CARGO_CAPACITY := 12
const EXTRACTION_SECONDS := 12.0
const EXTRACTION_RADIUS := 100.0
const SEARCH_RADIUS := 90.0
# Enemies patrol until they detect movement or a nearby disturbance.
const PATROL_DETECTION_RADIUS := 330.0
const CROUCH_DETECTION_RADIUS := 135.0
const NOISE_SHOT_RADIUS := 600.0
const NOISE_SEARCH_RADIUS := 290.0
const NOISE_EXTRACTION_RADIUS := 1250.0
const ALERT_DURATION := 8.0
const EXIT_REINFORCEMENTS := 3
# Optional fast-but-costly escape. Uses ONLY loot carried during this sortie.
const HATCH_POSITION := Vector2(690, 1080)
const HATCH_SCRAP_COST := 2
const HATCH_CORE_COST := 1
const HATCH_SECONDS := 4.0
const CRATES := [
	{"pos": Vector2(1710, 495), "tier": 0},
	{"pos": Vector2(2450, 600), "tier": 1},
	{"pos": Vector2(3250, 700), "tier": 2},
	{"pos": Vector2(760, 1600), "tier": 0},
	{"pos": Vector2(2050, 1710), "tier": 1},
	{"pos": Vector2(2850, 1910), "tier": 2},
	{"pos": Vector2(550, 470), "tier": 1},
	{"pos": Vector2(3390, 2190), "tier": 2},
	{"pos": Vector2(2260, 2150), "tier": 1},
	{"pos": Vector2(1510, 2070), "tier": 0}
]
const EXITS := [Vector2(960, 2090), Vector2(3180, 1370)]

static func cargo_count(cargo: Array[int]) -> int:
	var result := 0
	for amount in cargo:
		result += amount
	return result

static func can_search(cargo: Array[int]) -> bool:
	return cargo_count(cargo) < CARGO_CAPACITY

static func is_near_exit(pos: Vector2, exit_pos: Vector2) -> bool:
	return pos.distance_to(exit_pos) <= EXTRACTION_RADIUS

static func material_kind(tier: int, roll: float) -> int:
	# Higher risk crates bias toward power cores and ancient crystals.
	if tier >= 2 and roll < 0.31:
		return 2
	if tier >= 1 and roll < 0.69:
		return 1
	return 0

static func can_use_hatch(cargo: Array[int]) -> bool:
	return cargo.size() >= 3 and cargo[0] >= HATCH_SCRAP_COST and cargo[1] >= HATCH_CORE_COST

static func enemy_can_detect(distance: float, moving_quietly: bool, was_alerted: bool) -> bool:
	return was_alerted or distance <= (CROUCH_DETECTION_RADIUS if moving_quietly else PATROL_DETECTION_RADIUS)
