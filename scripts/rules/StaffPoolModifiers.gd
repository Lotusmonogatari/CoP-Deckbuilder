class_name StaffPoolModifiers
extends RefCounted
## What changes the day's task pool besides the families' own ranges (Cameron,
## 2026-11-16; design/proposals/STAFF_TASKS_EXPANSION_2026-11-16.md): the
## **drivers** (game-state conditions on the Staff Task Drivers tab) and the
## **active changes** left by items and events for the next pools. Both come
## out the same way: extra tasks (or fewer) for a family, a change to the day's
## maximum, and the reasons, so the screen can say why the day looks as it does.
##
## Pure rules: no UI, no autoloads, no files. The game state comes in as a
## dictionary of plain numbers (see GameState.staff_driver_state()).

## The family name that means "the day's maximum" instead of one family.
const MAX := "MAX"

const TEST_AT_LEAST := "At least"
const TEST_AT_MOST := "At most"
const TEST_IS_TRUE := "Is true"
const TEST_PER := "Per"
const TEST_EQUALS := "Equals"


## How many times a driver fires for the state: 0 when its test fails, 1 for a
## plain test that passes, and for "Per" one for every `threshold` of the value.
@warning_ignore("integer_division")
static func times(driver: Dictionary, state: Dictionary) -> int:
	var variable := str(driver.get("variable", ""))
	if not state.has(variable):
		return 0
	var value := int(state[variable])
	var threshold := int(driver.get("threshold", 0)) if driver.get("threshold") != null else 0
	match str(driver.get("test", "")):
		TEST_AT_LEAST:
			return 1 if value >= threshold else 0
		TEST_AT_MOST:
			# A variable that is not applicable (no staff: -1) never fires.
			return 1 if value >= 0 and value <= threshold else 0
		TEST_IS_TRUE:
			return 1 if value != 0 else 0
		TEST_EQUALS:
			return 1 if value == threshold else 0
		TEST_PER:
			return value / threshold if threshold > 0 else 0
	return 0


## What the drivers add today. Returns
## { adds: { family: n }, max_delta: n, reasons: [ { note, family, amount } ] }.
## Each firing rolls its Add Min to Add Max; the driver's total is held to its Cap.
static func from_drivers(drivers: Array, state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var result := {"adds": {}, "max_delta": 0, "reasons": []}
	for driver: Dictionary in drivers:
		var fired := times(driver, state)
		if fired <= 0:
			continue
		var amount := 0
		for _i in fired:
			amount += rng.randi_range(int(driver.get("add_min", 0)), maxi(int(driver.get("add_min", 0)), int(driver.get("add_max", 0))))
		var cap := int(driver.get("cap", 0)) if driver.get("cap") != null else 0
		if cap > 0:
			amount = clampi(amount, -cap, cap)
		_add(result, str(driver.get("family", "")), amount, str(driver.get("note", "")))
	return result


## What the items and events left for this pool. `mods` are { family, amount,
## draws_left, label }; each applies to the next `draws_left` pools drawn.
## Returns the same shape as from_drivers().
static func from_mods(mods: Array) -> Dictionary:
	var result := {"adds": {}, "max_delta": 0, "reasons": []}
	for mod: Dictionary in mods:
		if int(mod.get("draws_left", 0)) > 0:
			_add(result, str(mod.get("family", "")), int(mod.get("amount", 0)), str(mod.get("label", "")))
	return result


## The mods after one pool was drawn: one draw fewer each, those used up dropped.
static func after_draw(mods: Array) -> Array:
	var kept: Array = []
	for mod: Dictionary in mods:
		var left := int(mod.get("draws_left", 0)) - 1
		if left > 0:
			var copy := mod.duplicate()
			copy["draws_left"] = left
			kept.append(copy)
	return kept


## Two results combined (drivers, then item and event changes).
static func merged(first: Dictionary, second: Dictionary) -> Dictionary:
	var result := {"adds": (first["adds"] as Dictionary).duplicate(), "max_delta": int(first["max_delta"]) + int(second["max_delta"]),
		"reasons": (first["reasons"] as Array).duplicate()}
	for family: String in (second["adds"] as Dictionary).keys():
		result["adds"][family] = int(result["adds"].get(family, 0)) + int(second["adds"][family])
	(result["reasons"] as Array).append_array(second["reasons"])
	return result


static func _add(result: Dictionary, family: String, amount: int, note: String) -> void:
	if amount == 0 or family.is_empty():
		return
	if family == MAX:
		result["max_delta"] = int(result["max_delta"]) + amount
	else:
		result["adds"][family] = int(result["adds"].get(family, 0)) + amount
	(result["reasons"] as Array).append({"note": note, "family": family, "amount": amount})
