extends SceneTree
const GROUND = preload("res://scripts/ground_tile_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check_coverage(center: Vector2, viewport: Vector2, zoom: Vector2, name: String) -> void:
	var tiles: Rect2i = GROUND.visible_tile_range(center, viewport, zoom)
	var covered := Rect2(Vector2(tiles.position) * GROUND.TILE_SIZE, Vector2(tiles.size) * GROUND.TILE_SIZE)
	var half := viewport * 0.5 / zoom
	var screen := Rect2(center - half, half * 2.0)
	if not covered.encloses(screen):
		failures += 1
		print("FAIL: " + name + " camera view not covered: " + str(covered) + " vs " + str(screen))

func _run() -> void:
	# Camera is clamped to the map right edge while player stands further right.
	_check_coverage(Vector2(3064, 1400), Vector2(1152, 648), Vector2.ONE, "Right edge")
	_check_coverage(Vector2(616, 1400), Vector2(1152, 648), Vector2.ONE, "Left edge")
	_check_coverage(Vector2(1750, 429), Vector2(1152, 648), Vector2.ONE, "Top edge")
	_check_coverage(Vector2(1750, 2161), Vector2(1152, 648), Vector2.ONE, "Bottom edge")
	_check_coverage(Vector2(3064, 1400), Vector2(1920, 1080), Vector2.ONE, "Wide window")
	_check_coverage(Vector2(3064, 1400), Vector2(1152, 648), Vector2(0.8, 0.8), "Zoomed out")
	_check_coverage(Vector2(2800, 1400), Vector2(1152, 648), Vector2.ONE, "Camera smoothing lag")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	if not scene.has_method("ground_paint_bounds"):
		failures += 1
		print("FAIL: Main scene ground bounds missing")
	else:
		var painted: Rect2 = scene.call("ground_paint_bounds")
		if not painted.encloses(Rect2(Vector2(40, 105), Vector2(3600, 2380))):
			failures += 1
			print("FAIL: Painted bounds do not cover arena")
	scene.queue_free()
	if failures == 0:
		print("Ground tile camera-edge coverage passed.")
	else:
		push_error("Ground camera coverage failures: %d" % failures)
	quit(1 if failures > 0 else 0)
