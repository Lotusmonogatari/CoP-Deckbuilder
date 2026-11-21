class_name Travel
extends RefCounted
## What a trip between the offices costs and when it is refused (two offices, 2026-11-20, Cameron).
##
## Hours are Balance rows, one for each protagonist and mode ("Travel Hours: Train PC01"); a mode a protagonist
## does not have has no row. The rail pass and the paid train ticket both take the train's hours; the fast mode is
## a private car for most protagonists and a plane ticket for PC04. Pure: callers pass the Balance dictionary in.

const PASS := "train"      # the member's rail pass: free, always there
const TICKET := "ticket"   # a paid train ticket: the train's hours
const CAR := "car"
const PLANE := "plane"

const REFUSE_WEEKEND := "weekend"
const REFUSE_IN_LEVEL := "in_level"
const REFUSE_HOURS := "hours"


## One-way hours for `mode`; -1 when this protagonist does not have that mode.
static func hours(balance: Dictionary, protagonist_id: String, mode: String) -> int:
	var pid := protagonist_id.to_lower()
	var key := ""
	match mode:
		PASS, TICKET:
			key = "travel_hours_train_%s" % pid
		CAR:
			key = "travel_hours_car_%s" % pid
		PLANE:
			key = "travel_hours_plane_%s" % pid
	if key.is_empty() or not balance.has(key):
		return -1
	return int(balance[key])


## The fast mode this protagonist can buy: "plane" when they have a plane row, "car" otherwise, "" for neither.
static func fast_mode(balance: Dictionary, protagonist_id: String) -> String:
	for mode: String in [PLANE, CAR]:
		if hours(balance, protagonist_id, mode) >= 0:
			return mode
	return ""


## How many trips a level has built in (a mixed level): 0 for none.
static func level_trips(level: Dictionary) -> int:
	var value: Variant = level.get("travel_trips")
	return maxi(0, int(value)) if value != null else 0


## The hours a level's built-in trips add at `mode` (0 for a level with none, or a mode the protagonist lacks).
static func level_hours(level: Dictionary, balance: Dictionary, protagonist_id: String, mode: String) -> int:
	var trips := level_trips(level)
	if trips == 0:
		return 0
	return trips * maxi(0, hours(balance, protagonist_id, mode))


## Why a trip cannot be taken now: a REFUSE_ code, or "" when it can. `state`: in_level, weekend,
## travel_at_weekend (the Rules switch), hours_left and trip_hours.
static func refusal(state: Dictionary) -> String:
	if bool(state.get("in_level", false)):
		return REFUSE_IN_LEVEL
	if bool(state.get("weekend", false)) and not bool(state.get("travel_at_weekend", false)):
		return REFUSE_WEEKEND
	if int(state.get("trip_hours", 0)) > int(state.get("hours_left", 0)):
		return REFUSE_HOURS
	return ""
