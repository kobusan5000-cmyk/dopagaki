extends SceneTree
# The camera viewport must never see the unpainted clear color at map edges.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var arena: Rect2 = scene.ARENA
	var viewport_size: Vector2 = scene.SIZE
	var painted: Rect2 = scene.call("ground_paint_bounds")
	var camera: Camera2D = scene.get("camera")
	_check(painted.encloses(arena), "All playable ground is inside painted area")
	_check(painted.position.x <= arena.position.x - viewport_size.x * 0.5, "Background extends a half-screen to the left")
	_check(painted.end.x >= arena.end.x + viewport_size.x * 0.5, "Background extends a half-screen to the right")
	_check(painted.position.y <= arena.position.y - viewport_size.y * 0.5, "Background extends a half-screen above")
	_check(painted.end.y >= arena.end.y + viewport_size.y * 0.5, "Background extends a half-screen below")
	_check(camera.limit_right == int(arena.end.x), "Playable right edge camera limit unchanged")
	for position in [arena.position, Vector2(arena.end.x, arena.position.y), Vector2(arena.position.x, arena.end.y), arena.end]:
		var visible := Rect2(position - viewport_size * 0.5, viewport_size)
		_check(painted.encloses(visible), "Background fully covers the viewport at map corner %s" % position)
	scene.queue_free()
	if failures > 0:
		push_error("Background edge regression failed: %d" % failures)
	else:
		print("All map corners have painted ground beyond the camera viewport.")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + label)
