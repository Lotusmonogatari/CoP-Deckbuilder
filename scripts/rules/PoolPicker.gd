class_name PoolPicker
extends RefCounted
## The generic "pool of choices" picker (2026-10-01): filter a flat table of
## rows to the ones eligible for a scope key, then pick one at random.
##
## Generalizes OfficeTicker.gd's own eligible-then-random-pick (the news
## ticker's "never repeat the line just shown" logic) so every pool this
## project adds — the Stage Transition screen's cast, background, and
## dialogue tables alike — goes through the one function instead of a new
## near-duplicate picker each time.
##
## A row's own `scope_field` is a WILDCARD when blank: it is eligible for
## every scope key, not just one. A table that always fills `scope_field`
## (Transition Dialogue's own Character ID, say) simply never exercises the
## wildcard case — this stays an exact-match filter for it instead, with no
## special-casing needed on the caller's side.
##
## Pure and UI-free (CLAUDE.md §12): the caller injects its own `rng`, so a
## test can hand in a seeded one and get a reproducible pick.


## Every row whose `scope_field` is blank or equal to `scope_key`.
static func eligible(rows: Array, scope_field: String, scope_key: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for row: Dictionary in rows:
		var row_key := str(row.get(scope_field, ""))
		if row_key.is_empty() or row_key == scope_key:
			found.append(row)
	return found


## A random eligible row, never the same as `exclude` unless it is the only
## one eligible. {} when nothing is eligible.
static func pick(rows: Array, scope_field: String, scope_key: String,
		rng: RandomNumberGenerator, exclude: Dictionary = {}) -> Dictionary:
	var choices := eligible(rows, scope_field, scope_key)
	if choices.is_empty():
		return {}
	if choices.size() > 1 and not exclude.is_empty() and choices.has(exclude):
		var without_exclude := choices.filter(func(row: Dictionary) -> bool: return row != exclude)
		if not without_exclude.is_empty():
			choices = without_exclude
	return choices[rng.randi_range(0, choices.size() - 1)]
