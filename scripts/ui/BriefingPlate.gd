class_name BriefingPlate
extends Control
## A flat shape the level briefing draws itself (P12, 2026-11-19): a rectangle (the Woodblock seal), a ring (the Living
## Office hours badge) or a slanted plate (Broadcast's chip and bars), which a StyleBox cannot make. It takes no touch.
## A plate with children (labels) lays them out over its own face.

enum Shape { RECT, RING, SLANT }

var shape := Shape.RECT
var fill := Color(0, 0, 0, 0)
var edge := Color(0, 0, 0, 0)
var edge_width := 0.0
## The horizontal lean of a slanted plate, in pixels: the top edge is shifted right by this much, the bottom left.
var slant := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match shape:
		Shape.RECT:
			if fill.a > 0.0:
				draw_rect(r, fill)
			if edge_width > 0.0 and edge.a > 0.0:
				draw_rect(r.grow(-edge_width * 0.5), edge, false, edge_width)
		Shape.RING:
			var radius := minf(r.size.x, r.size.y) * 0.5 - edge_width * 0.5
			if fill.a > 0.0:
				draw_circle(r.get_center(), radius, fill)
			if edge_width > 0.0:
				draw_arc(r.get_center(), radius, 0.0, TAU, 64, edge, edge_width, true)
		Shape.SLANT:
			var lean := minf(slant, r.size.x * 0.5)
			var points := PackedVector2Array([Vector2(lean, 0), Vector2(r.size.x, 0), Vector2(r.size.x - lean, r.size.y), Vector2(0, r.size.y)])
			if fill.a > 0.0:
				draw_colored_polygon(points, fill)
			if edge_width > 0.0 and edge.a > 0.0:
				draw_polyline(points + PackedVector2Array([points[0]]), edge, edge_width, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
