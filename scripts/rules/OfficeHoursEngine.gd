class_name OfficeHoursEngine
extends RefCounted
## Office Hours (ST07): a multiple-choice visitor room.
##
## Deliberately the simplest engine in scripts/rules/ — no cards, no energy,
## no hand, no guard, no gaffe meter. One visitor at a time asks one already-
## drawn question (BattleSetup.expand_level() draws it, the same way a
## combat stage's opponent and question pool are drawn once at setup); the
## player picks one of its four choices; the visitor answers back, and the
## next visitor is next. There is no way to lose Office Hours short of never
## finishing it — see design/proposals/office_hours.md open point D2.
##
## Same discipline as every other file here: no autoload, no file access, no
## scene tree. setup() is handed already-resolved data (BattleSetup's job),
## and answer() hands back what a Reward/Penalty column named RAW, unresolved
## — this class has no DataDB to look a BOxx/Mxx/SHxx target up in, so
## resolving a target's real kind and rolling a range delta are the
## applying code's job (GameState.apply_visitor_reward_entries()), not this
## one's, the same separation BattleEngine keeps for the opponent's move.
##
## USE
##     var engine := OfficeHoursEngine.new()
##     engine.setup({"visitors": stage["visitors"]})
##     while not engine.is_finished():
##         var result := engine.answer(picked_letter)
##         ... narrate result, apply its reward/penalty ...
##         engine.advance()
##     engine.outcome()

## Set by setup() when the config could not be used. Empty means it worked.
var setup_problems: Array[String] = []

var _visitors: Array = []
var _index := 0

## Per-visitor results, appended by answer(): { "visitor_id", "correct", "effects" }.
## What outcome() summarises.
var _results: Array = []


## config = { "visitors": [ {visitor fields..., "question": {...}}, ... ] }
## — exactly BattleSetup.expand_level()'s stage["visitors"].
func setup(config: Dictionary) -> bool:
	setup_problems = []
	_visitors = (config.get("visitors", []) as Array).duplicate()
	_index = 0
	_results = []

	if _visitors.is_empty():
		setup_problems.append("no visitors to see")
		return false

	for visitor: Dictionary in _visitors:
		if (visitor.get("question", {}) as Dictionary).is_empty():
			setup_problems.append("%s has no question to ask" % visitor.get("visitor_id", "?"))

	return setup_problems.is_empty()


func current_visitor() -> Dictionary:
	return _visitors[_index] if _index < _visitors.size() else {}


func current_question() -> Dictionary:
	return current_visitor().get("question", {}) as Dictionary


## True once every visitor has been answered and advanced past.
func is_finished() -> bool:
	return _index >= _visitors.size()


## How many visitors in total, and how many are behind us — for a "3 of 5"
## style caption, the same shape BattleState.opponent_index/opponent_count
## already gives a committee or a continuous floor debate.
func visitor_count() -> int:
	return _visitors.size()


func visitor_index() -> int:
	return _index


## Answers the current visitor's question with one of "A"/"B"/"C"/"D"
## (case-insensitive). Returns:
##   { "correct": bool, "response_text": String, "reaction": String,
##     "effects": Array, "reward": Array, "penalty": Array }
##
## "Dilemma" questions (2026-10-16) carry an Effects list, a Response and a
## Reaction for EACH choice, so no choice is "right": every one is a trade.
## A choice without its own Effects falls back to how this room worked
## before — the visitor's Reward if the question's Correct Choice was
## picked, its Penalty otherwise — and without its own Response/Reaction to
## the old Right/Wrong lines, so a half-written question still plays.
##
## "effects" is the RAW target_delta_list that applies (unresolved — see this
## file's header for why); "correct" is true when the choice is not a net
## setback (the legacy right answer, or a dilemma choice whose numbers do not
## sum below zero). "reward"/"penalty" repeat "effects" under the old name
## (the other is always []) for older callers.
##
## Does not advance to the next visitor — call advance() once the result has
## been shown, the same two-step shape BattleEngine's card-then-end_turn()
## already uses, so a screen can display the response before moving on.
func answer(choice: String) -> Dictionary:
	if is_finished():
		return {}

	var visitor := current_visitor()
	var question := current_question()
	var picked := str(choice).strip_edges().to_upper()
	var key := picked.to_lower()

	var own: Variant = question.get("effects_%s" % key)
	var has_own := own is Array and not (own as Array).is_empty()
	var good: bool
	var effects: Array
	if has_own:
		effects = own as Array
		good = net_delta(effects) >= 0
	else:
		var correct := str(question.get("correct_choice", "")).strip_edges().to_upper()
		good = not correct.is_empty() and picked == correct
		effects = (visitor.get("reward", []) as Array) if good else (visitor.get("penalty", []) as Array)

	var response := str(question.get("response_%s" % key, "")).strip_edges()
	if response.is_empty():
		response = str(question.get("response_right" if good else "response_wrong", ""))
	var reaction := str(question.get("reaction_%s" % key, "")).strip_edges()
	if reaction.is_empty():
		reaction = str(question.get("reaction_right" if good else "reaction_wrong", ""))

	_results.append({"visitor_id": str(visitor.get("visitor_id", "")),
		"correct": good, "effects": effects})

	return {
		"correct": good,
		"response_text": response,
		"reaction": reaction,
		"effects": effects,
		"reward": effects if good else [],
		"penalty": effects if not good else [],
	}


## The sum of a target_delta_list's numbers (a {min,max} range counts as its
## middle) — whether a choice is a net gain or a net setback.
static func net_delta(effects: Array) -> float:
	var total := 0.0
	for entry: Variant in effects:
		if not (entry is Dictionary):
			continue
		var delta: Variant = (entry as Dictionary).get("delta")
		if delta is Dictionary:
			total += (float((delta as Dictionary).get("min", 0)) + float((delta as Dictionary).get("max", 0))) / 2.0
		elif delta != null:
			total += float(delta)
	return total


## Moves to the next visitor. Safe to call once finished — does nothing.
func advance() -> void:
	if not is_finished():
		_index += 1


## { "visited": n, "correct": n, "rewards": [...], "penalties": [...] } —
## rewards/penalties are the same raw, unresolved lists answer() already
## returned, collected across every visitor actually answered so far (not
## reduced to a total — different visitors' targets are not the same kind
## of thing to add together, and resolving/applying is not this file's job).
func outcome() -> Dictionary:
	var correct_count := 0
	var rewards: Array = []
	var penalties: Array = []
	var effects: Array = []
	for result: Dictionary in _results:
		var these: Array = result.get("effects", [])
		effects.append_array(these)
		if result.get("correct", false):
			correct_count += 1
			rewards.append_array(these)
		else:
			penalties.append_array(these)
	return {
		"visited": _results.size(),
		"correct": correct_count,
		"effects": effects,
		"rewards": rewards,
		"penalties": penalties,
	}
