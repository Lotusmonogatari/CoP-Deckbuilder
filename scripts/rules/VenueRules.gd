class_name VenueRules
extends RefCounted
## Capitol venues (P16, 2026-11-23, Cameron): when the player may step out, what a visit costs, and which venues are built so far.
## Venues are reached by Step out, not during a level and not once the work week is full; every venue is open every day, weekends
## included. At the Capitol office the map lists the Capitol Building and the Capital Area; at the District office it lists the
## District's own places (the station, 2026-11-24). Walking between the Capitol office, the Capitol Building and the Capital Area
## costs the Rules rows' hours (0 today). Pure: no screens, no autoloads, no files (the tests prove it).

## Why the player cannot step out right now; "" when they can.
const OPEN := ""
const IN_LEVEL := "in_level"       # a level is in progress
const WEEK_FULL := "week_full"     # no work hours left this week

## The activity kinds built so far (P16 phase 1). A venue whose activity is another kind shows as "Coming soon".
const BUILT_KINDS: Array[String] = ["chat", "watch", "train", "travel", "act", "read", "research", "office", "listen", "perform"]
## The kinds that deal daily lines.
const LINE_KINDS: Array[String] = ["chat", "watch"]


## Whether the player may step out, as one of the reason codes above (OPEN when they may). Both offices can step out.
static func step_out_state(in_level: bool, hours_left: int) -> String:
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


## A venue is built when any of its activities is built (the Library has a greyed Browse the Shelves beside two that are).
static func venue_built(activities: Array, venue_id: String) -> bool:
	for activity: Variant in activities:
		if activity is Dictionary and str((activity as Dictionary).get("venue_id", "")) == venue_id and is_built(activity as Dictionary):
			return true
	return false


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


## The picture a venue shows in a season (Cameron, 2026-11-23): the venue's own background ID with the season on the end in capitals
## (CAPITOL_GARDENS_WINTER) when that picture exists, else the plain one, so a venue with no seasonal pictures never changes.
## `exists` takes a background ID and says whether its picture is there. A blank season gives the plain one.
static func seasonal_background(base_id: String, season: String, exists: Callable) -> String:
	if base_id.is_empty() or season.strip_edges().is_empty():
		return base_id
	var seasonal := "%s_%s" % [base_id, season.strip_edges().to_upper()]
	return seasonal if bool(exists.call(seasonal)) else base_id


## The zone a venue sits in for the player's office: "District" venues belong to the District office, every other venue to the Capitol.
const ZONE_DISTRICT := "District"


## The Unlock value of a venue that a Decision Scene opens (Activates venue:VN10, P20): until then the map does not list it.
const UNLOCK_SCENE := "scene"


## The venues the map lists at an office (the District's own places there, the Capitol's at the Capitol), in Order. A venue whose Unlock is
## `scene` is listed only once its ID is in `opened` (the run's opened venues).
static func venues_at(venues: Array, at_capitol: bool, opened: Array = []) -> Array:
	var found: Array = []
	for venue: Variant in venues:
		if not (venue is Dictionary):
			continue
		var unlock: Variant = (venue as Dictionary).get("unlock")
		if unlock != null and str(unlock) == UNLOCK_SCENE and not opened.has(str((venue as Dictionary).get("venue_id", ""))):
			continue
		if (str((venue as Dictionary).get("zone", "")) == ZONE_DISTRICT) != at_capitol:
			found.append(venue)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("order", 0)) < int(b.get("order", 0)))
	return found


## A District venue's words and picture follow the District office: `{office}` becomes its town ("Daikoku") and `{OFFICE_ID}` the
## same in capitals with underscores ("AKENO_SHINMACHI"), the spelling the picture files use (AREA_DAIKOKU_STATION). A blank town
## leaves the text as it is.
static func fill_office(text: String, office_town: String) -> String:
	var town := office_town.strip_edges()
	if town.is_empty():
		return text
	return text.replace("{office}", town).replace("{OFFICE_ID}", town.to_upper().replace(" ", "_").replace("-", "_"))


## A District venue's picture is the protagonist's own: `{PC_ID}` becomes their ID ("PC03"), as in AREA_SHRINE_PC03 and AREA_SHOTENGAI_PC03.
static func fill_protagonist(text: String, protagonist_id: String) -> String:
	return text if protagonist_id.strip_edges().is_empty() else text.replace("{PC_ID}", protagonist_id.strip_edges())


## The second screen inside a station (the tracks): the venue's picture with `_TRACKS` on the end, when that picture exists.
static func tracks_background(base_id: String, exists: Callable) -> String:
	var tracks := "%s_TRACKS" % base_id
	return tracks if not base_id.is_empty() and bool(exists.call(tracks)) else ""


static func _whole(raw: Variant) -> int:
	return 0 if raw == null else int(raw)
