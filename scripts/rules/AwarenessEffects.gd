class_name AwarenessEffects
extends RefCounted
## What name awareness does (2026-10-23, Cameron). data/awareness_effects.json
## (the workbook's Awareness Effects tab) is a list of rows: a meter (District
## or National), a condition (At least / At most a threshold), and an effect.
##
##   Timing "State":    holds while the condition is met (a dues reduction, a
##                      starting bonus in some rooms).
##   Timing "Week end": applied once at each week's end while the condition is
##                      met (standing, XP, a free coupon).
##   Stacking "Escalating": the value is multiplied by how many weeks in a row
##                      the condition has held (-5, then -10, then -15).
##
## Pure and UI-free (CLAUDE.md section 12).

const DUES_REDUCTION := "DUES_REDUCTION"
const FREE_TRAINING_COUPON := "FREE_TRAINING_COUPON"
const STAGE_START_BONUS := "STAGE_START_BONUS"
const STANDING_CHANGE := "STANDING_CHANGE"
const XP_CHANGE := "XP_CHANGE"


## Whether the row's condition holds for these meter readings
## ({ "district": n, "national": n }).
static func is_met(effect: Dictionary, awareness: Dictionary) -> bool:
	var key := str(effect.get("meter", "")).to_lower()
	if not awareness.has(key):
		return false
	var value := int(awareness[key])
	var threshold := int(effect.get("threshold", 0))
	return value >= threshold if str(effect.get("condition", "")) == "At least" else value <= threshold


## The stage ids or organization ids a row's Target cell names.
static func targets_of(effect: Dictionary) -> Array[String]:
	var found: Array[String] = []
	for part: String in str(effect.get("target", "")).split(";"):
		var cleaned := part.strip_edges()
		if not cleaned.is_empty():
			found.append(cleaned)
	return found


## Yen taken off the base dues by State rows that are met.
static func dues_reduction(effects: Array, awareness: Dictionary) -> int:
	var total := 0
	for effect: Dictionary in effects:
		if str(effect.get("effect_type", "")) == DUES_REDUCTION and str(effect.get("timing", "")) == "State" \
				and is_met(effect, awareness):
			total += maxi(0, int(effect.get("value", 0)))
	return total


## Starting support added to a stage by State rows that are met and name it.
static func stage_start_bonus(effects: Array, awareness: Dictionary, stage_id: String) -> int:
	var total := 0
	for effect: Dictionary in effects:
		if str(effect.get("effect_type", "")) == STAGE_START_BONUS and str(effect.get("timing", "")) == "State" \
				and is_met(effect, awareness) and targets_of(effect).has(stage_id):
			total += int(effect.get("value", 0))
	return total


## The week-end pass: updates each Week end row's run of consecutive weeks and
## returns what applies. `streaks` is { effect_id: weeks }; the result is
## { "streaks": the new streaks, "applied": [{ effect, amount }] }.
static func week_end(effects: Array, awareness: Dictionary, streaks: Dictionary) -> Dictionary:
	var new_streaks := {}
	var applied: Array = []
	for effect: Dictionary in effects:
		if str(effect.get("timing", "")) != "Week end":
			continue
		var id := str(effect.get("effect_id", ""))
		if not is_met(effect, awareness):
			new_streaks[id] = 0
			continue
		var weeks := int(streaks.get(id, 0)) + 1
		new_streaks[id] = weeks
		var amount := int(effect.get("value", 0))
		if str(effect.get("stacking", "")) == "Escalating":
			amount *= weeks
		applied.append({"effect": effect, "amount": amount})
	return {"streaks": new_streaks, "applied": applied}
