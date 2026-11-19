class_name LayoutWatch
extends RefCounted
## Looks for a screen that is laid out wrongly, from a list of boxes (2026-11-19). The Promises button
## that jumped over the payments box was a button sitting outside the group that was supposed to hold
## it; nobody saw it until a playtest. This finds that kind of fault, and finds which control a
## player circled on a screenshot.
##
## Pure: it is handed boxes, never nodes. ControlProbe.collect() turns the live screen into boxes.
## A box is { "path": "Safe/Scroll/Column/StyleTiles/PromisesButton", "kind": "Button", "text":
## "Promises (1)", "rect": Rect2 (screen pixels), "parent_rect": Rect2 or null (the group box, when
## the parent is a plain container), "interactive": bool, "scrolled": bool (inside a scrolling list,
## where running past the screen's edge is normal), "skip": bool (a card: a hand overlaps and fans on
## purpose) }. The list is in drawing order: later is on top.

const TOLERANCE := 2.0
## Two buttons that overlap by more than this share of the smaller one are reported.
const OVERLAP_SHARE := 0.3
const MAX_PROBLEMS := 12


## Faults: { "what": "off_screen" | "outside_group" | "overlapping", "path": ..., "text": ..., "detail": ... }.
static func problems(boxes: Array, screen: Rect2) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var wide := screen.grow(TOLERANCE)
	var buttons: Array = []
	for box: Dictionary in boxes:
		if bool(box.get("skip", false)) or not bool(box.get("interactive", false)):
			continue
		buttons.append(box)
		var rect: Rect2 = box["rect"]
		if not bool(box.get("scrolled", false)) and not wide.encloses(rect):
			found.append(_fault("off_screen", box, "reaches %s on a screen %s" % [_rect_text(rect), _size_text(screen.size)]))
		var parent: Variant = box.get("parent_rect")
		if parent is Rect2 and not (parent as Rect2).grow(TOLERANCE).encloses(rect):
			found.append(_fault("outside_group", box, "sits at %s, outside the group that holds it (%s)" % [_rect_text(rect), _rect_text(parent as Rect2)]))
	for first in buttons.size():
		for second in range(first + 1, buttons.size()):
			var a: Dictionary = buttons[first]
			var b: Dictionary = buttons[second]
			if _is_family(str(a["path"]), str(b["path"])):
				continue
			var share := overlap_share(a["rect"], b["rect"])
			if share > OVERLAP_SHARE:
				found.append(_fault("overlapping", a, "overlaps %s by %d%%" % [_name_of(b), int(share * 100.0)]))
	if found.size() > MAX_PROBLEMS:
		found.resize(MAX_PROBLEMS)
	return found


## The share of the smaller rectangle that the other covers (0 to 1).
static func overlap_share(first: Rect2, second: Rect2) -> float:
	var smaller := minf(first.get_area(), second.get_area())
	if smaller <= 0.0:
		return 0.0
	return first.intersection(second).get_area() / smaller


## Boxes that contain `point`, the one drawn on top first.
static func under_point(boxes: Array, point: Vector2) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for index in range(boxes.size() - 1, -1, -1):
		var box: Dictionary = boxes[index]
		if (box["rect"] as Rect2).has_point(point):
			hits.append(box)
	return hits


## Boxes mostly inside `area` (a circled region), smallest first, so the thing circled comes before
## the page it sits on. Only boxes with text or that can be pressed are worth naming.
static func inside_area(boxes: Array, area: Rect2, min_share: float = 0.6) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for box: Dictionary in boxes:
		var rect: Rect2 = box["rect"]
		if rect.get_area() <= 0.0:
			continue
		if not (bool(box.get("interactive", false)) or not str(box.get("text", "")).is_empty()):
			continue
		if area.intersection(rect).get_area() / rect.get_area() >= min_share:
			hits.append(box)
	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["rect"] as Rect2).get_area() < (b["rect"] as Rect2).get_area())
	return hits


## "PromisesButton (Button) 'Promises (1)' at x 378-702, y 1984-2110" for the report.
static func describe(box: Dictionary) -> String:
	var text := str(box.get("text", ""))
	var quoted := " '%s'" % text if not text.is_empty() else ""
	return "%s (%s)%s at %s [%s]" % [_name_of(box), str(box.get("kind", "")), quoted, _rect_text(box["rect"]), str(box.get("path", ""))]


static func _fault(what: String, box: Dictionary, detail: String) -> Dictionary:
	return {"what": what, "path": str(box["path"]), "text": str(box.get("text", "")),
		"detail": "%s %s" % [_name_of(box), detail]}


static func _name_of(box: Dictionary) -> String:
	return str(box["path"]).get_slice("/", str(box["path"]).get_slice_count("/") - 1)


static func _is_family(first: String, second: String) -> bool:
	return first.begins_with(second + "/") or second.begins_with(first + "/")


static func _rect_text(rect: Rect2) -> String:
	return "x %d-%d, y %d-%d" % [int(rect.position.x), int(rect.end.x), int(rect.position.y), int(rect.end.y)]


static func _size_text(size: Vector2) -> String:
	return "%dx%d" % [int(size.x), int(size.y)]
