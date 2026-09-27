class_name PartyDisplay
extends RefCounted
## A party's own official colour, wherever its name is shown.
##
## data/parties.json carries each of the six real parties' own RGB (their
## actual branding, not a design choice) as three separate 0-255 ints —
## r/g/b, not a packed array. Every screen that shows a party name by it
## (the Office header, the New Game protagonist picker, the battle
## screen's own Details panel) reads through this rather than repeating
## the /255.0 conversion, so any one of them retuning stays a one-line fix.
##
## Pure and UI-free (CLAUDE.md §12): takes the row it needs as an
## argument, no autoload access, so it is tested headless like
## OpponentDisplay.gd.

## A neutral grey — visible on both light and dark backgrounds — for a
## party row that could not be found, so an unmatched name never renders
## as invisible (black-on-black or white-on-white) text.
const UNKNOWN_PARTY_COLOR := Color(0.6, 0.6, 0.6)


## `party` is a data/parties.json row (get_party()/get_party_by_id()'s own
## return shape); {} for a name that did not resolve.
static func color_for(party: Dictionary) -> Color:
	if party.is_empty():
		return UNKNOWN_PARTY_COLOR
	return Color(
		int(party.get("r", 153)) / 255.0,
		int(party.get("g", 153)) / 255.0,
		int(party.get("b", 153)) / 255.0)
