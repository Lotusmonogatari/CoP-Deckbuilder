class_name PlaceTokens
extends RefCounted
## Place tokens in text (two offices, slice 5, 2026-11-20, Cameron). A line asks for a type of place, "{place:harbor}",
## and a protagonist's own Places-tab name takes its place ("Port of Wakkanai" for one, "Noheji" for another), so a
## District event names the right harbor, onsen town or school. "{office_city}" is the town of the District office.
##
## Where a protagonist has several names for one type, one is picked, but always the same one for the same event, so the
## flavor and the result agree. Pure: callers pass the Places rows and the protagonist in.

const PATTERN := "\\{place:([a-z_]+)\\}"
const OFFICE_CITY := "{office_city}"


## { type: [names] } for one protagonist, from the Places rows (data/places.json).
static func names_by_type(places: Array, protagonist_id: String) -> Dictionary:
	var found := {}
	for row: Variant in places:
		if not (row is Dictionary) or str((row as Dictionary).get("protagonist", "")) != protagonist_id:
			continue
		var kind := str((row as Dictionary).get("place_type", ""))
		if not found.has(kind):
			found[kind] = []
		(found[kind] as Array).append(str((row as Dictionary).get("name", "")))
	return found


## The place types a text asks for, each once.
static func types_in(text: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string(PATTERN)
	for match: RegExMatch in regex.search_all(text):
		var kind := match.get_string(1)
		if not found.has(kind):
			found.append(kind)
	return found


## True when a protagonist's names cover every type in `needed`.
static func has_types(names: Dictionary, needed: Variant) -> bool:
	if not (needed is Array):
		return true
	for kind: Variant in needed as Array:
		if not names.has(str(kind)) or (names[str(kind)] as Array).is_empty():
			return false
	return true


## The text with its tokens filled. `pick_key` makes the choice among several names the same every time for the same
## line of text; a type with no name reads as the plain word ("onsen town"); {office_city} reads `office_city`.
static func fill(text: String, names: Dictionary, office_city: String, pick_key: String) -> String:
	if not text.contains("{"):
		return text
	var result := text.replace(OFFICE_CITY, office_city if not office_city.is_empty() else "your district")
	var regex := RegEx.create_from_string(PATTERN)
	for match: RegExMatch in regex.search_all(result):
		var kind := match.get_string(1)
		var options: Array = names.get(kind, [])
		var name := kind.replace("_", " ")
		if not options.is_empty():
			name = str(options[absi(hash("%s|%s" % [pick_key, kind])) % options.size()])
		result = result.replace(match.get_string(0), name)
	return result
