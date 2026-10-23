class_name EventEngine
extends RefCounted
## Events (2026-10-23, Cameron): a screen of flavor text and a few fixed
## choices, each with variable rewards. An event is bought ("Buyable") or
## arrives on its own ("Random"). Data: the workbook's Events and Event Choices
## tabs. Pure and UI-free (CLAUDE.md section 12): the run's readings come in
## through `ctx`:
##   { weekend: bool, week_full: bool, hours_left: int, funds: int, xp: int,
##     now: int (the clock), last_at: { event_id: clock at last use },
##     default_cooldown: int, district: int, national: int, dues_owed: int }

const REFUSE_WEEK_OVER := "week_over"
const REFUSE_WEEKDAY := "weekday"
const REFUSE_WEEKEND := "weekend"
const REFUSE_HOURS := "hours"
const REFUSE_COOLDOWN := "cooldown"
const REFUSE_FUNDS := "funds"
const REFUSE_XP := "xp"


## An event's choices in letter order.
static func choices_for(choices: Array, event_id: String) -> Array:
	var found: Array = []
	for row: Dictionary in choices:
		if str(row.get("event_id", "")) == event_id:
			found.append(row)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("choice", "")) < str(b.get("choice", "")))
	return found


static func hours_of(event: Dictionary) -> int:
	var raw: Variant = event.get("hours")
	return maxi(0, int(raw)) if raw != null else 0


## Whether the event's Available cell allows it in this phase of the week.
static func available_now(event: Dictionary, weekend: bool) -> bool:
	match str(event.get("available", "Both")):
		"Weekday":
			return not weekend
		"Weekend":
			return weekend
	return true


static func _cooldown_over(event: Dictionary, ctx: Dictionary) -> bool:
	var id := str(event.get("event_id", ""))
	var last: Dictionary = ctx.get("last_at", {})
	if not last.has(id):
		return true
	var own: Variant = event.get("cooldown_hours")
	var cooldown := int(own) if own != null else int(ctx.get("default_cooldown", 0))
	return int(ctx.get("now", 0)) - int(last[id]) >= cooldown


## Why a bought event cannot be arranged now, as a code, or "" when it can.
static func refusal(event: Dictionary, ctx: Dictionary) -> String:
	var weekend := bool(ctx.get("weekend", false))
	if bool(ctx.get("week_full", false)) and not weekend:
		return REFUSE_WEEK_OVER
	if not available_now(event, weekend):
		return REFUSE_WEEKEND if str(event.get("available", "")) == "Weekend" else REFUSE_WEEKDAY
	if weekend and hours_of(event) > int(ctx.get("hours_left", 0)):
		return REFUSE_HOURS
	if not _cooldown_over(event, ctx):
		return REFUSE_COOLDOWN
	var cost_funds: Variant = event.get("cost_funds")
	if cost_funds != null and int(ctx.get("funds", 0)) < int(cost_funds):
		return REFUSE_FUNDS
	var cost_xp: Variant = event.get("cost_xp")
	if cost_xp != null and int(ctx.get("xp", 0)) < int(cost_xp):
		return REFUSE_XP
	return ""


## The Random events that could arrive now: right time of the week, off
## cooldown, and the player known enough (Min District/National Awareness).
static func eligible_random(events: Array, ctx: Dictionary) -> Array:
	var found: Array = []
	var weekend := bool(ctx.get("weekend", false))
	for event: Dictionary in events:
		if str(event.get("trigger", "")) != "Random":
			continue
		if int(event.get("weight", 0) if event.get("weight") != null else 0) <= 0:
			continue
		if not available_now(event, weekend) or not _cooldown_over(event, ctx):
			continue
		if str(event.get("needs_dues_owed", "")) == "Yes" and int(ctx.get("dues_owed", 0)) <= 0:
			continue
		if event.get("min_district_awareness") != null \
				and int(ctx.get("district", 0)) < int(event["min_district_awareness"]):
			continue
		if event.get("min_national_awareness") != null \
				and int(ctx.get("national", 0)) < int(event["min_national_awareness"]):
			continue
		found.append(event)
	return found


## One event by weight; `roll` is a number from 0 up to (not including) 1.
static func pick_weighted(events: Array, roll: float) -> Dictionary:
	var total := 0
	for event: Dictionary in events:
		total += int(event.get("weight", 0))
	if total <= 0:
		return {}
	var target := clampf(roll, 0.0, 0.999999) * float(total)
	var running := 0.0
	for event: Dictionary in events:
		running += float(int(event.get("weight", 0)))
		if target < running:
			return event
	return events[events.size() - 1]
