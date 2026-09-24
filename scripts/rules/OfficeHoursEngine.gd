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

## Per-visitor results, appended by answer(): { "visitor_id", "correct" }.
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
##     "reward": Array, "penalty": Array }
## "reward" is the visitor's own Reward list on a correct answer, "penalty"
## its Penalty list on a wrong one — the other is always []. Both are the
## RAW target_delta_list entries from visitors.json, unresolved (see this
## file's own header comment for why).
##
## Does not advance to the next visitor — call advance() once the result has
## been shown, the same two-step shape BattleEngine's card-then-end_turn()
## already uses, so a screen can display the response before moving on.
func answer(choice: String) -> Dictionary:
	if is_finished():
		return {}

	var visitor := current_visitor()
	var question := current_question()
	var correct := str(question.get("correct_choice", "")).strip_edges().to_upper()
	var picked := str(choice).strip_edges().to_upper()
	var is_correct := not correct.is_empty() and picked == correct

	_results.append({"visitor_id": str(visitor.get("visitor_id", "")), "correct": is_correct})

	return {
		"correct": is_correct,
		"response_text": str(question.get("response_right" if is_correct else "response_wrong", "")),
		"reaction": str(question.get("reaction_right" if is_correct else "reaction_wrong", "")),
		"reward": (visitor.get("reward", []) as Array) if is_correct else [],
		"penalty": (visitor.get("penalty", []) as Array) if not is_correct else [],
	}


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
	for index in _results.size():
		var result: Dictionary = _results[index]
		var visitor: Dictionary = _visitors[index]
		if result.get("correct", false):
			correct_count += 1
			rewards.append_array(visitor.get("reward", []) as Array)
		else:
			penalties.append_array(visitor.get("penalty", []) as Array)
	return {
		"visited": _results.size(),
		"correct": correct_count,
		"rewards": rewards,
		"penalties": penalties,
	}
