class_name LevelRunner
extends RefCounted
## Runs a level: the ordered list of stages between one visit to the Office
## and the next.
##
## It knows which stage you are on, what the previous stages produced, and
## whether the level is finished. It does not know how a battle works — that
## is BattleEngine's job — and like everything else in scripts/rules/ it
## never reads a file, touches an autoload, or draws anything.
##
## TYPICAL USE
##     var runner := LevelRunner.new(level_data)
##     while not runner.is_finished():
##         var stage := runner.current_stage()
##         ... play it ...
##         runner.finish_stage(outcome, score)
##     runner.outcome()   # "win" or "loss"

## How the level as a whole ended.
const ONGOING := "ongoing"
const WON := "win"
const LOST := "loss"

var level: Dictionary = {}
var stages: Array = []

## Which stage we are on, counting from zero.
var index := 0

## What each finished stage produced, keyed by its seq. Each entry is
## { "outcome": "win"/"loss", "score": int, "boosters": [booster ids] }.
var results: Dictionary = {}

var _outcome := ONGOING


func _init(level_data: Dictionary = {}) -> void:
	level = level_data
	stages = level_data.get("stages", []).duplicate(true)
	stages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("seq", 0)) < int(b.get("seq", 0)))


## Anything wrong with this level, in plain words. Empty when it is usable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if stages.is_empty():
		found.append("the level has no stages")
		return found

	var seen: Array[int] = []
	for stage: Dictionary in stages:
		var seq := int(stage.get("seq", -1))
		if seq < 0:
			found.append("a stage has no seq number, so its order is unknown")
		elif seen.has(seq):
			found.append("two stages both claim seq %d" % seq)
		else:
			seen.append(seq)

		# A stage needs someone or something to push back. Usually that is
		# opponents; in a press conference it is the reporters' questions,
		# which is why either will do.
		if stage.get("opponents", []).is_empty() and stage.get("questions", []).is_empty():
			found.append("stage %d has neither opponents nor questions" % seq)
	return found


func is_valid() -> bool:
	return problems().is_empty()


# ---------------------------------------------------------------------------
# Moving through the level
# ---------------------------------------------------------------------------

func current_stage() -> Dictionary:
	if index < 0 or index >= stages.size():
		return {}
	return stages[index]


func stage_count() -> int:
	return stages.size()


## "Stage 2 of 4", for the header.
func progress_caption() -> String:
	return "Stage %d of %d" % [mini(index + 1, stages.size()), stages.size()]


func is_finished() -> bool:
	return _outcome != ONGOING


func outcome() -> String:
	return _outcome


## Records how a stage went and moves to the next one.
##
## `score` matters for a stage whose win_mode is "score" — the caucus, where
## there is no threshold and how far you got is the point. `boosters` are the
## organisations pleased along the way, which later stages can draw on.
##
## Losing any stage ends the level: you go back to the Office either way.
func finish_stage(stage_outcome: String, score: int = 0, boosters: Array = []) -> void:
	if is_finished():
		return

	var stage := current_stage()
	if stage.is_empty():
		return

	results[int(stage.get("seq", index + 1))] = {
		"outcome": stage_outcome,
		"score": score,
		"boosters": boosters.duplicate(),
	}

	if stage_outcome == LOST:
		_outcome = LOST
		return

	index += 1
	if index >= stages.size():
		_outcome = WON


# ---------------------------------------------------------------------------
# What earlier stages left behind
# ---------------------------------------------------------------------------

## The buffs waiting for the stage now in play.
##
## A stage says which earlier stages it draws on with "carries_buffs_from".
## Everything those stages produced is gathered here:
##
##   support_bonus   added to the player's starting support
##   boosters        organisations pleased, whose modifiers can switch on
##
## A stage that names nobody gets nothing, which is the normal case.
func carried_buffs() -> Dictionary:
	var stage := current_stage()
	var buffs := {"support_bonus": 0, "boosters": []}

	for seq: int in stage.get("carries_buffs_from", []):
		var result: Variant = results.get(int(seq))
		if result == null:
			continue

		# A caucus score above the halfway mark is worth something; below it
		# is worth nothing rather than a penalty. Scaled down deliberately:
		# a good caucus should help, not decide the floor debate on its own.
		var score := int((result as Dictionary).get("score", 0))
		if score > 50:
			buffs["support_bonus"] = int(buffs["support_bonus"]) + int(floor(float(score - 50) / 10.0))

		for booster_id: String in (result as Dictionary).get("boosters", []):
			if not (buffs["boosters"] as Array).has(booster_id):
				(buffs["boosters"] as Array).append(booster_id)

	return buffs


## A plain-English summary of what is being carried, for the details panel.
##
## `names` maps a booster ID to what that organisation is called. The rules
## engine has no access to the data files, so whoever is showing this passes
## the names in; without them the IDs are printed as they are.
func describe_carried_buffs(names: Dictionary = {}) -> String:
	var buffs := carried_buffs()
	var lines: Array[String] = []

	var bonus := int(buffs["support_bonus"])
	if bonus > 0:
		lines.append("The caucus went well: you start %d ahead." % bonus)

	var boosters: Array = buffs["boosters"]
	if not boosters.is_empty():
		var named: Array[String] = []
		for booster_id: String in boosters:
			named.append(str(names.get(booster_id, booster_id)))
		lines.append("Pleased at the press conference: %s." % ", ".join(named))

	if lines.is_empty():
		return "Nothing carried over from the earlier stages."
	return "\n".join(lines)


func to_dictionary() -> Dictionary:
	return {
		"level_id": level.get("level_id", ""),
		"index": index,
		"results": results.duplicate(true),
		"outcome": _outcome,
	}
