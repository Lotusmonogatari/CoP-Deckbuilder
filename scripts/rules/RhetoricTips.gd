class_name RhetoricTips
extends RefCounted
## Rhetoric tips (P16, 2026-11-23, Cameron): a hint heard at a Capitol venue that tells the player which argument style a stage or an
## opponent responds to. A tip is built from data: a stage's Favored Suit, or an opponent's lead suit (suit_1). The player holds at
## most a few at a time, each for a number of days on the game calendar; a new one replaces the oldest, and hearing a tip about a
## target already held refreshes its days. Pure: no screens, no autoloads, no files (the tests prove it).
##
## A held tip is {"kind": "stage_suit" or "opponent_suit", "target": STxx or OPxx, "suit": "Earnest", "where": "cafeteria" or
## "gardens", "day": the day number it was heard}.

const STAGE := "stage_suit"
const OPPONENT := "opponent_suit"


## The targets a hint may be about this week, as {"stage_suit": [{"id", "suit"}], "opponent_suit": [{"id", "suit"}]}. `stage_ids` are
## the rooms of the levels on offer (and of the next Decision! scene), `stage_rows` the stages by ID (a stage with no Favored Suit is
## never a target), `opponents_by_stage` {stage_id: [opponent rows eligible for it]} and `extra_opponents` the people a Decision!
## scene names. Duplicates are left out.
static func targets(stage_ids: Array, stage_rows: Dictionary, opponents_by_stage: Dictionary, extra_opponents: Array) -> Dictionary:
	var stages: Array = []
	var people: Array = []
	var seen_stage := {}
	var seen_person := {}
	for raw: Variant in stage_ids:
		var stage_id := str(raw)
		var row: Dictionary = stage_rows.get(stage_id, {})
		var favored: Variant = row.get("favored_suit")
		if not row.is_empty() and favored != null and not str(favored).strip_edges().is_empty() and str(favored) != "—" \
				and not seen_stage.has(stage_id):
			seen_stage[stage_id] = true
			stages.append({"id": stage_id, "suit": str(favored)})
		for opponent: Variant in opponents_by_stage.get(stage_id, []):
			_add_person(people, seen_person, opponent as Dictionary)
	for opponent: Variant in extra_opponents:
		_add_person(people, seen_person, opponent as Dictionary)
	return {STAGE: stages, OPPONENT: people}


static func _add_person(people: Array, seen: Dictionary, opponent: Dictionary) -> void:
	var id := str(opponent.get("opp_id", ""))
	var suit: Variant = opponent.get("suit_1")
	if id.is_empty() or seen.has(id) or suit == null or str(suit).strip_edges().is_empty():
		return
	seen[id] = true
	people.append({"id": id, "suit": str(suit)})


## A held tip for a hint a venue dealt.
static func make(hint: Dictionary, where: String, day: int) -> Dictionary:
	return {"kind": str(hint.get("kind", "")), "target": str(hint.get("target", "")), "suit": str(hint.get("suit", "")),
		"where": where, "day": day}


## The tips after adding one: a tip about a target already held refreshes that tip (new day and place); otherwise it is added, and
## when `max_held` would be passed the oldest is dropped. Never changes the argument.
static func add(held: Array, tip: Dictionary, max_held: int) -> Array:
	var out: Array = []
	var refreshed := false
	for existing: Variant in held:
		var current := existing as Dictionary
		if str(current.get("kind", "")) == str(tip.get("kind", "")) and str(current.get("target", "")) == str(tip.get("target", "")):
			out.append(tip)
			refreshed = true
		else:
			out.append(current)
	if not refreshed:
		out.append(tip)
	while out.size() > maxi(max_held, 1):
		var oldest := 0
		for i in out.size():
			if int((out[i] as Dictionary).get("day", 0)) < int((out[oldest] as Dictionary).get("day", 0)):
				oldest = i
		out.remove_at(oldest)
	return out


## Days a tip has left today: `days` on the day it was heard, 1 on its last day, 0 once it has expired.
static func days_left(tip: Dictionary, today: int, days: int) -> int:
	return clampi(int(tip.get("day", 0)) + days - today, 0, days)


## The tips still held on `today`.
static func unexpired(held: Array, today: int, days: int) -> Array:
	return held.filter(func(tip: Variant) -> bool: return days_left(tip as Dictionary, today, days) > 0)


## The held tip about a stage or an opponent, or {}.
static func about(held: Array, kind: String, target: String) -> Dictionary:
	for tip: Variant in held:
		if str((tip as Dictionary).get("kind", "")) == kind and str((tip as Dictionary).get("target", "")) == target:
			return tip as Dictionary
	return {}
