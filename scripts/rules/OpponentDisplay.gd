class_name OpponentDisplay
extends RefCounted
## What to call an opponent on screen, beyond their bare name.
##
## The workbook's Title column (2026-09-26 pull) is almost always "N/A" —
## real posts (Prime Minister, a committee chair, a party leader, "; "
## joined when someone holds more than one) exist only for a handful of
## leadership rows. Everyone else's own Role column (a committee name, or a
## plain role like "Journalist"/"Constituent"/"Student" for the non-MP
## opponents a Non-combat stage draws) stands in for a title where there
## isn't a real one. Affiliation is a booster_id — an opponent's
## organisation, e.g. a journalist's National Media.
##
## Pure and UI-free (CLAUDE.md §12): takes the data it needs as arguments,
## no autoload access, so it can be tested headless.

const NO_TITLE_VALUES := ["", "N/A", "N/A;"]


## The title shown next to a name: the real Title column where there is
## one, else the Role column, else "" (nothing to show).
##
## Only the FIRST title of several (Cameron, 2026-09-27): a cell like
## "Minister of Agriculture; Chair of the Committee on Agriculture" shows as
## "Minister of Agriculture" — the whole list ran the name line off the side
## of a phone screen.
##
## A blank cell exports as JSON null, and str(null) is the literal text
## "<null>" — which used to be shown as the title of the ~110 opponents with
## no Title at all ("Yuriko Mayeda, <null>").
static func title_for(opponent: Dictionary) -> String:
	var title := _first_part(opponent.get("title"))
	if not NO_TITLE_VALUES.has(title):
		return title
	return _first_part(opponent.get("role"))


static func _first_part(value: Variant) -> String:
	if value == null:
		return ""
	return str(value).split(";")[0].strip_edges()


## The organisation an opponent's Affiliation booster_id names, or "" when
## it doesn't resolve (blank, or a booster_id the Boosters tab doesn't
## have — DataDB's own load-time validation catches that case as an error,
## so this only has to be quiet about it here).
static func affiliation_name_for(opponent: Dictionary, boosters: Array) -> String:
	var booster_id := str(opponent.get("affiliation", "")).strip_edges()
	if booster_id.is_empty():
		return ""
	for booster: Dictionary in boosters:
		if str(booster.get("booster_id", "")) == booster_id:
			return str(booster.get("name_en", ""))
	return ""
