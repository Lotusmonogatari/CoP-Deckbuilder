class_name VenueActivities
extends RefCounted
## Costed venue activities (2026-11-24, Cameron): what the Old Shrine, the Local Shotengai and the Library let the player do. A
## venue may have several (Venue Activities rows of Kind act); each has hours and Funds to spend, standing, awareness, energy or
## staff hours to give, and a limit per day. Some count how often they were done and hand out gifts at set counts (Venue Milestones),
## and one gives more staff hours after enough uses. Pure: no screens, no autoloads, no files (the tests prove it).
##
## State the caller keeps: a use log {activity_id: {"day": day number, "count": uses that day}} and totals {activity_id: uses ever}.

const KIND := "act"


static func is_act(activity: Dictionary) -> bool:
	return str(activity.get("kind", "")) == KIND


## Every activity row of a venue, in the workbook's order.
static func activities_of(activities: Array, venue_id: String) -> Array:
	var found: Array = []
	for activity: Variant in activities:
		if activity is Dictionary and str((activity as Dictionary).get("venue_id", "")) == venue_id:
			found.append(activity)
	return found


## How many times the activity was done on `today`.
static func uses_today(log: Dictionary, activity_id: String, today: int) -> int:
	var entry: Variant = log.get(activity_id)
	if entry is Dictionary and int((entry as Dictionary).get("day", -1)) == today:
		return int((entry as Dictionary).get("count", 0))
	return 0


## Times still allowed today; -1 when the activity has no daily limit.
static func left_today(activity: Dictionary, log: Dictionary, today: int) -> int:
	var raw: Variant = activity.get("per_day")
	if raw == null or int(raw) <= 0:
		return -1
	return maxi(0, int(raw) - uses_today(log, str(activity.get("activity_id", "")), today))


## The log with one more use today recorded (a new day starts again at 1).
static func with_use(log: Dictionary, activity_id: String, today: int) -> Dictionary:
	var next := log.duplicate(true)
	next[activity_id] = {"day": today, "count": uses_today(log, activity_id, today) + 1}
	return next


## Staff hours the activity gives all staff this time: its own, plus the bonus once `done_before` uses have been done (the 51st use of
## Read about management practices gives 2 when the bonus starts after 50). 0 for an activity with no staff hours.
static func staff_hours(activity: Dictionary, done_before: int) -> int:
	var base := int(activity.get("staff_hours", 0)) if activity.get("staff_hours") != null else 0
	if base <= 0:
		return 0
	var after: Variant = activity.get("bonus_after_uses")
	if after != null and int(after) > 0 and done_before >= int(after) and activity.get("bonus_staff_hours") != null:
		return base + int(activity["bonus_staff_hours"])
	return base


## The milestones this use reaches: those of the activity whose Count lies above `before` and at or below `after`, lowest first.
static func milestones_crossed(milestones: Array, activity_id: String, before: int, after: int) -> Array:
	var found: Array = []
	for row: Variant in milestones:
		if row is Dictionary and str((row as Dictionary).get("activity_id", "")) == activity_id:
			var count := int((row as Dictionary).get("count", 0))
			if count > before and count <= after:
				found.append(row)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) < int(b["count"]))
	return found


## Whether any milestone belongs to the activity (the screen then shows its count, and keeps the gifts a surprise).
static func has_milestones(milestones: Array, activity_id: String) -> bool:
	for row: Variant in milestones:
		if row is Dictionary and str((row as Dictionary).get("activity_id", "")) == activity_id:
			return true
	return false
