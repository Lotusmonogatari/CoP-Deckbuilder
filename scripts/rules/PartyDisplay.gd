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


## A protagonist/opponent row's own "party" field as a string, or "" for a
## blank cell. Most opponents have no party at all, and a blank workbook
## cell exports as JSON null — str(null) is the literal text "<null>",
## the same bug class OpponentDisplay.title_for() already guards title
## text against, so every party-name display site reads through this
## rather than stringifying the raw value itself.
static func party_name(row: Dictionary) -> String:
	var party: Variant = row.get("party")
	return "" if party == null else str(party)


## WCAG relative luminance of a colour (0 black to 1 white).
static func luminance(c: Color) -> float:
	var parts: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		parts.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * parts[0] + 0.7152 * parts[1] + 0.0722 * parts[2]


## WCAG contrast ratio of two colours (1 to 21).
static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## The plate a party's name is set on (panel P4, item 4, 2026-11-17; Cameron chose a plate per
## party). The party colour is canon and never changes: the plate is near-white or near-black,
## whichever reads better against it (every party in the data reaches 4.5 to 1).
const PLATE_LIGHT := Color(0.96, 0.95, 0.92)
const PLATE_DARK := Color(0.05, 0.05, 0.07)


## Large, heavy party names only need 3 to 1 (WCAG's large-text level), so a colour that reads that well on the
## light plate keeps it: pure red (Keizaijiyuutou) is 3.6 to 1 on light, and on the near-black plate it was
## harder to read (Cameron, 2026-11-18). A colour that fails even 3 to 1 on light goes to whichever plate is better.
const LARGE_TEXT_CONTRAST := 3.0


static func plate_for(party_colour: Color) -> Color:
	var on_light := contrast(party_colour, PLATE_LIGHT)
	if on_light >= LARGE_TEXT_CONTRAST:
		return PLATE_LIGHT
	return PLATE_LIGHT if on_light >= contrast(party_colour, PLATE_DARK) else PLATE_DARK
