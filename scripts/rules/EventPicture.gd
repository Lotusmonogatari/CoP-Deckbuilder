class_name EventPicture
extends RefCounted
## Which picture an event shows (2026-10-29, Cameron). The Events tab's Image
## cell holds one background ID, or several separated by semicolons
## ("OUT_HARBOR_1; OUT_HARBOR_2"); each time the event comes up, one of them is
## picked at random. Pure rules: no UI, no autoloads.


## The IDs in a cell, trimmed, in the order written. A blank or null cell is [].
static func options(cell: Variant) -> Array[String]:
	var found: Array[String] = []
	if cell == null:
		return found
	for piece: String in str(cell).replace("|", ";").split(";"):
		var id := piece.strip_edges()
		if not id.is_empty():
			found.append(id)
	return found


## One of the cell's IDs, or "" when it names none. A single ID is returned
## without touching the generator.
static func pick(cell: Variant, rng: RandomNumberGenerator = null) -> String:
	var choices := options(cell)
	if choices.is_empty():
		return ""
	if choices.size() == 1:
		return choices[0]
	if rng == null:
		return choices[randi() % choices.size()]
	return choices[rng.randi_range(0, choices.size() - 1)]
