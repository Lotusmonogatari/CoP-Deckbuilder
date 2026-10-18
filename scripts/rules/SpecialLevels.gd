class_name SpecialLevels
extends RefCounted
## Special Levels (2026-10-18, Cameron): the Constituency Town Hall and the
## Party Steering Committee Check-In. A crisis trigger (GameState) starts a
## countdown on the game clock (TimeClock); when it has run its Special Level
## Delay the level appears at the top of the level list. If the player plays
## an ordinary level instead, it is forced in right after that level.
##
## A level is special when its Levels-tab "Special Trigger" cell is set. The
## player never sees the clock or the countdown. Pure and UI-free.

const TOWN_HALL := "Town Hall"
const STEERING_COMMITTEE := "Steering Committee"

## The order they come due in when both are waiting.
const ORDER := [TOWN_HALL, STEERING_COMMITTEE]


## The level's Special Trigger, or "" for an ordinary level (a blank cell is
## JSON null -- the <null> trap).
static func trigger_of(level: Dictionary) -> String:
	var raw: Variant = level.get("special_trigger")
	return "" if raw == null else str(raw).strip_edges()


static func is_special(level: Dictionary) -> bool:
	return not trigger_of(level).is_empty()


## The triggers whose countdown has run out, in ORDER. `armed` maps a trigger
## to {"armed_at": clock units when the countdown began}.
static func due(armed: Dictionary, now: int, delay: int) -> Array[String]:
	var found: Array[String] = []
	for trigger: String in ORDER:
		if not armed.has(trigger):
			continue
		var started := int((armed[trigger] as Dictionary).get("armed_at", 0))
		if TimeClock.has_elapsed(started, delay, now):
			found.append(trigger)
	return found


## The level row carrying this trigger, or {}.
static func level_for(trigger: String, levels: Array) -> Dictionary:
	for level: Dictionary in levels:
		if trigger_of(level) == trigger:
			return level
	return {}
