class_name Offices
extends RefCounted
## The two places the player stands in (two offices, 2026-11-20, Cameron): the Capitol and a District office.
##
## A level, an event or a notice is tagged Capitol, District or Either (a blank tag means Either: it can be
## reached from both offices and never costs a trip). Pure and UI-free: callers pass in the tag and where the
## player is.

const CAPITOL := "Capitol"
const DISTRICT := "District"
const EITHER := "Either"


## The tag as one of the three words; blank, null or anything unknown reads as Either.
static func normalize(tag: Variant) -> String:
	var text := str(tag).strip_edges() if tag != null else ""
	if text == CAPITOL or text == DISTRICT:
		return text
	return EITHER


## The other office. Either has no other: it stays Either.
static func other(office: String) -> String:
	match normalize(office):
		CAPITOL:
			return DISTRICT
		DISTRICT:
			return CAPITOL
	return EITHER


## True when something tagged `tag` can be started or met at `here`. Either is always reachable.
static func is_here(tag: Variant, here: String) -> bool:
	var office := normalize(tag)
	return office == EITHER or office == normalize(here)


## Where the player ends after `trips` trips that began at `start`: an odd number crosses over, an even one
## comes back. (Zero trips: where they started.)
static func end_office(start: String, trips: int) -> String:
	return other(start) if trips % 2 == 1 else normalize(start)
