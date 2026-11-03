extends RefCounted
# Combat collision, separate from foot position/movement so the tall STAR DUO
# can be hit over its visible torso and head (sprite: -92..+16px).
const STAR_DUO_RADIUS := 32.0
const STAR_DUO_TOP := -63.0
const STAR_DUO_BOTTOM := -14.0
const DEFAULT_PROJECTILE_RADIUS := 18.0
const DEFAULT_MELEE_PADDING := 16.0

static func projectile_hits(kind: String, feet: Vector2, shot: Vector2, shot_radius: float) -> bool:
	var safe_radius := maxf(0.0, shot_radius)
	if kind != "star_duo":
		return feet.distance_to(shot) <= DEFAULT_PROJECTILE_RADIUS + safe_radius
	var upper: Vector2 = feet + Vector2(0.0, STAR_DUO_TOP)
	var lower: Vector2 = feet + Vector2(0.0, STAR_DUO_BOTTOM)
	var closest := Geometry2D.get_closest_point_to_segment(shot, upper, lower)
	return shot.distance_to(closest) <= STAR_DUO_RADIUS + safe_radius

static func melee_hits(kind: String, feet: Vector2, attacker: Vector2, aim_angle: float, reach: float, half_angle: float) -> bool:
	if kind != "star_duo":
		return _point_inside_melee(feet, attacker, aim_angle, reach, half_angle)
	# Sample the whole tall body, not only the floor position.
	for y_offset in [0.0, -20.0, -42.0, -64.0, -82.0]:
		if _point_inside_melee(feet + Vector2(0.0, y_offset), attacker, aim_angle, reach + 10.0, half_angle):
			return true
	return false

static func close_enough_for_ninja(kind: String, feet: Vector2, attacker: Vector2, max_range: float) -> bool:
	if kind != "star_duo":
		return feet.distance_to(attacker) < max_range
	for offset in [0.0, -25.0, -50.0, -75.0]:
		if (feet + Vector2(0, offset)).distance_to(attacker) < max_range:
			return true
	return false

static func _point_inside_melee(target: Vector2, attacker: Vector2, aim_angle: float, reach: float, half_angle: float) -> bool:
	var diff := target - attacker
	if diff.length() > reach + DEFAULT_MELEE_PADDING:
		return false
	return diff.length() <= 1.0 or absf(wrapf(diff.angle() - aim_angle, -PI, PI)) <= half_angle
