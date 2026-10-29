class_name EventPicture
extends RefCounted
## Which picture an event or stage shows (2026-10-29, Cameron). An Events Image
## cell, or a Stages Background ID cell, holds one background ID, or several
## separated by semicolons ("PIC_A; PIC_B"); one is picked at random each time.
##
## A picture whose name carries a TERM (OUT_FESTIVAL_2_WINTER carries WINTER)
## is only used when the event or stage names the same or a related thing:
## `terms` (data/art.json "image_terms") maps each term to the words that count
## as related, and `context` is the text to look in (an event's title and
## flavor, a stage's name). Order of preference: a term picture whose term the
## context invokes; otherwise a picture with no term; otherwise any (so a
## list is never left empty). Pure rules: no UI, no autoloads.


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


## The terms a picture's name carries: its underscore-separated words that are
## keys of `terms` (case-insensitive), upper-cased.
static func terms_of(id: String, terms: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var known := {}
	for key: Variant in terms.keys():
		known[str(key).to_upper()] = str(key)
	for word: String in id.to_upper().split("_"):
		if known.has(word) and not found.has(word):
			found.append(word)
	return found


## True when `context` names the term or any word `terms` lists as related.
static func context_invokes(term: String, context: String, terms: Dictionary) -> bool:
	var low := context.to_lower()
	var related: Array = [term.to_lower()]
	for key: Variant in terms.keys():
		if str(key).to_upper() == term.to_upper():
			related.append_array(terms[key] as Array if terms[key] is Array else [])
	for word: Variant in related:
		if not str(word).is_empty() and low.contains(str(word).to_lower()):
			return true
	return false


## The IDs that may be shown for this context, per the preference order above.
static func eligible(choices: Array[String], context: String = "", terms: Dictionary = {}) -> Array[String]:
	var matched: Array[String] = []
	var plain: Array[String] = []
	for id: String in choices:
		var carried := terms_of(id, terms)
		if carried.is_empty():
			plain.append(id)
			continue
		var all_invoked := true
		for term: String in carried:
			if not context_invokes(term, context, terms):
				all_invoked = false
		if all_invoked:
			matched.append(id)
	if not matched.is_empty():
		return matched
	if not plain.is_empty():
		return plain
	return choices


## One of the cell's IDs fit for this context, or "" when it names none. A
## single ID is returned without touching the generator.
static func pick(cell: Variant, context: String = "", terms: Dictionary = {},
		rng: RandomNumberGenerator = null) -> String:
	var choices := options(cell)
	if choices.is_empty():
		return ""
	if choices.size() == 1:
		return choices[0]
	var fit := eligible(choices, context, terms)
	if fit.size() == 1:
		return fit[0]
	if rng == null:
		return fit[randi() % fit.size()]
	return fit[rng.randi_range(0, fit.size() - 1)]
