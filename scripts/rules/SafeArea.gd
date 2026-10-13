class_name SafeArea
extends RefCounted
## Pure maths for device safe areas (notches, rounded corners, the home bar).
##
## A phone reports its usable rectangle in WINDOW pixels; the game lays
## itself out in BASE pixels (1080 wide, stretched with `canvas_items`), so
## the inset on each side is scaled by how many base pixels one window pixel
## covers. A desktop window reports its whole area, so every inset is 0.
## Layout.gd (the autoload) is the one place this touches the display.


## {left, top, right, bottom} in base pixels. `safe` and `window_size` are in
## window pixels; `viewport_size` is the stretched game area in base pixels.
static func insets(safe: Rect2, window_size: Vector2, viewport_size: Vector2) -> Dictionary:
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	return {
		"left": maxf(0.0, safe.position.x) * scale.x,
		"top": maxf(0.0, safe.position.y) * scale.y,
		"right": maxf(0.0, window_size.x - safe.end.x) * scale.x,
		"bottom": maxf(0.0, window_size.y - safe.end.y) * scale.y,
	}


## A screen's margin on one side: its own designed margin, or the device
## inset when that is larger — never the sum, because the designed margins
## already leave room for a typical status bar.
static func margin_for(designed: int, inset: float) -> int:
	return maxi(designed, ceili(inset))
