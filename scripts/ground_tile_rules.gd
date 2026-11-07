extends RefCounted
# The viewport can be offset from the wolf near Camera2D limits or during
# smoothing. Culling forest tiles around the wolf alone exposes dark strips.
const TILE_SIZE := 256.0
const TILE_PADDING := 256.0

static func visible_tile_range(screen_center: Vector2, viewport_size: Vector2, zoom: Vector2 = Vector2.ONE) -> Rect2i:
	var safe_zoom := Vector2(maxf(0.01, absf(zoom.x)), maxf(0.01, absf(zoom.y)))
	var half_view := viewport_size * 0.5 / safe_zoom
	var low := screen_center - half_view - Vector2.ONE * TILE_PADDING
	var high := screen_center + half_view + Vector2.ONE * TILE_PADDING
	var left := floori(low.x / TILE_SIZE)
	var top := floori(low.y / TILE_SIZE)
	var right := ceili(high.x / TILE_SIZE)
	var bottom := ceili(high.y / TILE_SIZE)
	return Rect2i(left, top, right - left + 1, bottom - top + 1)
