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
	var buffs := {"support_bonus": 0, "boosters": []}

	for entry: Dictionary in carried_breakdown():
		buffs["support_bonus"] = int(buffs["support_bonus"]) + int(entry["support_bonus"])

	for seq: int in current_stage().get("carries_buffs_from", []):
		var result: Variant = results.get(int(seq))
		if result == null:
			continue
		for booster_id: String in (result as Dictionary).get("boosters", []):
			if not (buffs["boosters"] as Array).has(booster_id):
				(buffs["boosters"] as Array).append(booster_id)

	return buffs


## The same arithmetic, stage by stage, so it can be explained rather than
## just applied: one entry per earlier stage that left something behind.
func carried_breakdown() -> Array:
	var entries: Array = []

	for seq: int in current_stage().get("carries_buffs_from", []):
		var result: Variant = results.get(int(seq))
		if result == null:
			continue

		var from := stage_by_seq(int(seq))
		var score := int((result as Dictionary).get("score", 0))
		entries.append({
			"seq": int(seq),
			"name": str(from.get("name_en", "An earlier stage")),
			"score": score,
			"support_bonus": score_to_support(from, score),
		})

	return entries


## How much a stage's closing score is worth to a later one.
##
## The conversion belongs to the stage that produced the score, under its own
## "tone_effects", so a press conference and a caucus can be worth different
## things without either of them being written into this file:
##
##   baseline             the score that is worth nothing either way
##   support_per_points   how many points make one point of support
##   allow_negative       whether a score below the baseline costs you
##
## Rounding is towards zero in both directions, so being five points short of
## the baseline is worth nothing rather than costing a whole point.
static func score_to_support(stage: Dictionary, score: int) -> int:
	var effects: Dictionary = stage.get("tone_effects", {})

	var per := int(effects.get("support_per_points", 10))
	if per <= 0:
		return 0

	var baseline := int(effects.get("baseline", 50))
	var bonus := int(float(score - baseline) / float(per))

	if bonus < 0 and not bool(effects.get("allow_negative", false)):
		return 0
	return bonus


## Whether any later stage draws on what this one produces.
##
## A stage whose score nobody carries should not promise the player that it
## is worth something later, because it is not.
func score_is_carried_from(seq: int) -> bool:
	for stage: Dictionary in stages:
		if int(stage.get("seq", -1)) <= seq:
			continue
		for source: int in stage.get("carries_buffs_from", []):
			if int(source) == seq:
				return true
	return false


## A stage of this level by its seq number, or an empty dictionary.
func stage_by_seq(seq: int) -> Dictionary:
	for stage: Dictionary in stages:
		if int(stage.get("seq", -1)) == seq:
			return stage
	return {}


## A plain-English summary of what is being carried, for the details panel.
##
## `names` maps a booster ID to what that organisation is called. The rules
## engine has no access to the data files, so whoever is showing this passes
## the names in; without them the IDs are printed as they are.
func describe_carried_buffs(names: Dictionary = {}) -> String:
	var buffs := carried_buffs()
	var lines: Array[String] = []

	# Named stage by stage rather than as one number, because "you start 2
	# behind" without saying what did it is not something a player can act on
	# next time.
	for entry: Dictionary in carried_breakdown():
		var bonus := int(entry["support_bonus"])
		if bonus > 0:
			lines.append("%s went well: you start %d ahead." % [entry["name"], bonus])
		elif bonus < 0:
			lines.append("%s went badly: you start %d behind." % [entry["name"], -bonus])

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


# ---------------------------------------------------------------------------
# What a stage is worth
# ---------------------------------------------------------------------------
# Shared by the briefing screen before a level and the result panel after a
# stage, so the promise and the receipt cannot describe the same stage
# differently. Pure data in, plain strings out — no autoloads, no scene tree.

## The meta-variables a stage pays out on a win, as {name: delta}.
##
## Zero is left out rather than reported as "+0": a variable this stage does
## not touch is not news. An empty result means the stage pays nothing flat,
## which the screens say in words rather than showing four zeroes.
static func win_rewards(stage: Dictionary) -> Dictionary:
	var rewards := {}
	for key: String in WIN_DELTA_KEYS.keys():
		var delta := int(stage.get(key, 0))
		if delta != 0:
			rewards[WIN_DELTA_KEYS[key]] = delta
	return rewards


## The workbook's column names, and what the player calls them.
const WIN_DELTA_KEYS := {
	"win_delta_jiban": "Constituency support",
	"win_delta_kanban": "Reputation",
	"win_delta_kaban": "Funds",
	"win_delta_party_support": "Party support",
}


## True where a stage's rewards have not been decided yet.
##
## Every playtest stage is in this state on purpose: the slots are in the
## data with zeroes in them, waiting on Cameron's numbers. The screens must
## say "not set yet" rather than quietly implying the stage is worthless.
static func rewards_are_unset(stage: Dictionary) -> bool:
	if not win_rewards(stage).is_empty():
		return false
	if int(stage.get("xp_reward", 0)) != 0:
		return false
	return not stage.has("tone_effects")


## What a stage produces that is not a flat reward — described, not forecast.
##
## Cameron asked the briefing for STATIC values only: a press conference's
## worth depends on the tone it closes on and a caucus's on its score, so
## those are named as variable rather than given a number that would be a
## guess.
static func variable_rewards(stage: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var effects: Dictionary = stage.get("tone_effects", {})

	var per_variable: Dictionary = effects.get("meta", {})
	for name: String in per_variable.keys():
		var per := int(per_variable[name])
		if per > 0:
			lines.append("%s, by how far above %d you finish (1 per %d)"
				% [name, int(effects.get("baseline", 50)), per])

	var per_support := int(effects.get("support_per_points", 0))
	if per_support > 0:
		lines.append("A head start later in the level, 1 per %d above %d"
			% [per_support, int(effects.get("baseline", 50))])

	if not stage.get("questions", []).is_empty():
		lines.append("Standing with whichever organisations your answers please")

	return lines
