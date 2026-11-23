class_name VenueRules
extends RefCounted
## Capitol venues (P16, 2026-11-23, Cameron): when the player may step out, what a visit costs, and which venues are built so far.
## Venues are reachable only from the Capitol office, not during a level, and not once the work week is full; every venue is open
## every day, weekends included. Walking between the Capitol office, the Capitol Building and the Capital Area costs the Rules rows'
## hours (0 today). Pure: no screens, no autoloads, no files (the tests prove it).

## Why the player cannot step out right now; "" when they can.
const OPEN := ""
const ELSEWHERE := "elsewhere"     # not at the Capitol office
const IN_LEVEL := "in_level"       # a level is in progress
const WEEK_FULL := "week_full"     # no work hours left this week

## The activity kinds built so far (P16 phase 1). A venue whose activity is another kind shows as "Coming soon".
const BUILT_KINDS: Array[String] = ["chat", "watch", "train"]
## The kinds that deal daily lines.
const LINE_KINDS: Array[String] = ["chat", "watch"]


## Whether the player may step out from where they are, as one of the reason codes above (OPEN when they may).
static func step_out_state(at_capitol: bool, in_level: bool, hours_left: int) -> String:
	if not at_capitol:
		return ELSEWHERE
	if in_level:
		return IN_LEVEL
	if hours_left <= 0:
		return WEEK_FULL
	return OPEN


## Hours of walking to reach a zone from the Capitol office: the building row, plus the area row for the Capital Area.
static func walk_hours(zone: String, building_hours: int, area_hours: int) -> int:
	return maxi(building_hours, 0) + (maxi(area_hours, 0) if zone == "Capital Area" else 0)


## Whether a venue is open on a day (0 = Sunday ... 6 = Saturday). Open Days is "Any" or blank (every day) or a list of weekdays.
static func open_on(venue: Dictionary, weekday: int) -> bool:
	var raw: Variant = venue.get("open_days")
	var text := "" if raw == null else str(raw).strip_edges().to_lower()
	if text.is_empty() or text == "any":
		return true
	var codes := ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
	for part: String in text.split(";"):
		if part.strip_edges().substr(0, 3) == codes[clampi(weekday, 0, 6)]:
			return true
	return false


## The activity of a venue (the first row naming it), or {}.
static func activity_of(activities: Array, venue_id: String) -> Dictionary:
	for activity: Variant in activities:
		if activity is Dictionary and str((activity as Dictionary).get("venue_id", "")) == venue_id:
			return activity as Dictionary
	return {}


## A venue is built in this phase when its activity's kind is one of BUILT_KINDS; the rest are "Coming soon".
static func is_built(activity: Dictionary) -> bool:
	return BUILT_KINDS.has(str(activity.get("kind", "")))


## Whether the venue's activity deals daily lines.
static func deals_lines(activity: Dictionary) -> bool:
	return LINE_KINDS.has(str(activity.get("kind", "")))


## The cost of one visit: {"hours", "funds", "xp"}; a blank cell is 0.
static func visit_cost(activity: Dictionary) -> Dictionary:
	return {"hours": _whole(activity.get("hours")), "funds": _whole(activity.get("funds")), "xp": _whole(activity.get("xp"))}


## Whether a visit can start: "" when it can, "hours" or "funds" or "xp" when that is what is short.
static func visit_refusal(activity: Dictionary, hours_left: int, funds: int, xp: int) -> String:
	var cost := visit_cost(activity)
	if int(cost["hours"]) > hours_left:
		return "hours"
	if int(cost["funds"]) > funds:
		return "funds"
	if int(cost["xp"]) > xp:
		return "xp"
	return ""


static func _whole(raw: Variant) -> int:
	return 0 if raw == null else int(raw)
