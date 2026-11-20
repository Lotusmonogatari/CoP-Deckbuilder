class_name DashedFrame
extends Control
## A dashed rectangle drawn over whatever it is placed on (P13, 2026-11-20): the outline of an open place in Office
## Management ("+ Hire a ..."). A StyleBox cannot dash. It takes no touch, so the button under it still gets the tap.

var colour := Color.WHITE
var width := 2.0
var dash := 12.0
var gap := 8.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var inset := width * 0.5
	var r := Rect2(Vector2(inset, inset), size - Vector2(width, width))
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], colour, width, dash)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
