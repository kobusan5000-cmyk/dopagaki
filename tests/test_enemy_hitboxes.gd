extends SceneTree
# Full-height STAR DUO hitboxes without changing other enemies' combat rules.
const HITBOX = preload("res://scripts/enemy_hitbox_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var feet := Vector2(2800, 1500)
	var upper_body := feet + Vector2(0, -72)
	_check(HITBOX.projectile_hits("star_duo", feet, upper_body, 4.0), "Arrow can hit STAR DUO upper body")
	_check(HITBOX.projectile_hits("star_duo", feet, feet + Vector2(0, -25), 4.0), "Gun can hit STAR DUO lower body")
	_check(not HITBOX.projectile_hits("star_duo", feet, feet + Vector2(70, -48), 4.0), "Far outside STAR DUO body is a miss")
	_check(not HITBOX.projectile_hits("grunt", feet, upper_body, 4.0), "Ordinary enemy retains old small circular hitbox")
	_check(HITBOX.projectile_hits("grunt", feet, feet + Vector2(13, 0), 4.0), "Ordinary enemy foot-level hits still register")
	var attacker := Vector2(2680, 1430)
	_check(HITBOX.melee_hits("star_duo", feet, attacker, 0.0, 110.0, 0.95), "Sword cleave connects to STAR DUO torso")
	_check(not HITBOX.melee_hits("grunt", feet, attacker, 0.0, 110.0, 0.95), "Ordinary enemy melee reach unchanged")
	_check(not HITBOX.melee_hits("star_duo", feet, Vector2(2630, 1430), PI, 110.0, 0.95), "Sword does not hit enemy behind swing")
	_check(HITBOX.close_enough_for_ninja("star_duo", feet, Vector2(2700, 1450), 108.0), "Ninja switches to melee based on visible torso")
	_check(not HITBOX.close_enough_for_ninja("grunt", feet, Vector2(2700, 1450), 108.0), "Ninja range for normal enemies unchanged")

	# Runtime verification: a real projectile must damage the tall sprite.
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("select_class", 0)
	scene.call("start_sortie")
	var foes: Array = scene.get("enemies")
	_check(foes.size() > 0, "Expedition spawns combat-ready enemies")
	if not foes.is_empty():
		var target: Dictionary = foes[0]
		foes.clear()
		target["kind"] = "star_duo"
		target["pos"] = feet
		target["hp"] = 100.0
		target["max_hp"] = 100.0
		foes.append(target)
		var shots: Array = scene.get("projectiles")
		shots.clear()
		var bullet := {"pos": upper_body, "vel": Vector2.ZERO, "life": 1.0, "hit_ids": [], "dmg": 10.0, "radius": 4.0, "pierce": 1, "accuracy": 1.0, "crit_chance": 0.0, "trait": -1, "owner": "hero", "tint": Color.WHITE}
		shots.append(bullet.duplicate(true))
		scene.call("update_projectiles", 0.01)
		_check(float(target["hp"]) < 100.0, "Live projectile damages STAR DUO upper body")
		target["hp"] = 100.0
		target["kind"] = "grunt"
		shots.append(bullet.duplicate(true))
		scene.call("update_projectiles", 0.01)
		_check(is_equal_approx(float(target["hp"]), 100.0), "Same upper-body shot does not enlarge ordinary enemy hitbox")
	scene.queue_free()
	if failures > 0:
		push_error("STAR DUO hitbox regressions: %d" % failures)
	else:
		print("STAR DUO full-body hit detection passed.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
