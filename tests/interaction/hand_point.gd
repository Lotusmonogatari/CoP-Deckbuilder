class_name HandPoint
extends RefCounted
## Where a real finger lands on a card in the hand (P9, 2026-11-17). The hand's cards overlap, so
## the centre of a card can lie under its right-hand neighbour. A person taps the part that shows:
## the card's left strip, up to where the next card begins. Click drivers use this point for a card
## in the hand and the plain centre for anything else.


static func center(control: Control) -> Vector2:
	var rect := control.get_global_rect()
	var point := rect.get_center()
	if control is CardView and control.get_parent() is HBoxContainer:
		var siblings := control.get_parent().get_children()
		var index := control.get_index()
		if index + 1 < siblings.size() and siblings[index + 1] is Control:
			var next_x := (siblings[index + 1] as Control).get_global_rect().position.x
			var end := minf(rect.end.x, next_x)
			if end > rect.position.x + 20.0:
				point.x = (rect.position.x + end) * 0.5
	return point
