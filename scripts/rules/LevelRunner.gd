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
		#
		# Non-combat is the one declared exception — Office Hours (ST07) is
		# not a battle at all (CLAUDE.md §8), so it has neither, by design,
		# until its own visitor-event system exists. test_real_battle.gd's
		# test_every_real_level_can_be_set_up() already skips it the same
		# way; without this check here too, every level that includes it
		# (LV11, LV12, LV14, LV17, LV23, LV26, LV27, LV28 today) failed to
		# start at all — not just its Office Hours stage, the whole level.
		#
		# Missing "mode" (every hand-written playtest fixture, and the two
		# tests just above this one) still gets the check — only a stage that
		# explicitly declares itself Non-combat is exempt, not merely "not
		# declared Combat".
		if str(stage.get("mode", "")) != "Non-combat" \
				and stage.get("opponents", []).is_empty() and not _asks_questions(stage):
			found.append("stage %d has neither opponents nor questions" % seq)

		# A Non-combat stage's own equivalent, now that Office Hours draws a
		# real visitor pool (BattleSetup.expand_level()): a stage with an
		# empty pool is silently unplayable in exactly the same way an empty
		# opponent pool used to be, so it gets the same hard check rather
		# than a quiet empty screen.
		if str(stage.get("mode", "")) == "Non-combat" and stage.get("visitors", []).is_empty():
			found.append("stage %d has no eligible visitors" % seq)
	return found


## Whether this room puts questions to the player.
##
## Two ways of saying so: a stage may write its questions out longhand, or
## name a number and draw that many from the pool for its type. Asked in one
## place so neither shape is forgotten.
static func _asks_questions(stage: Dictionary) -> bool:
	if not stage.get("questions", []).is_empty():
		return true
	return int(stage.get("questions_count", 0)) > 0


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


## "Stage 2 of 4", for the header. The wording is handed in, like every
## other sentence the rules say.
func progress_caption(words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	return say.say("caption.stage", {
		"number": mini(index + 1, stages.size()),
		"total": stages.size(),
	})


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
func describe_carried_buffs(names: Dictionary = {}, words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var buffs := carried_buffs()
	var lines: Array[String] = []

	# Named stage by stage rather than as one number, because "you start 2
	# behind" without saying what did it is not something a player can act on
	# next time.
	for entry: Dictionary in carried_breakdown():
		var bonus := int(entry["support_bonus"])
		if bonus > 0:
			lines.append(say.say("carried.went_well",
				{"name": entry["name"], "count": bonus}))
		elif bonus < 0:
			lines.append(say.say("carried.went_badly",
				{"name": entry["name"], "count": -bonus}))

	var boosters: Array = buffs["boosters"]
	if not boosters.is_empty():
		var named: Array[String] = []
		for booster_id: String in boosters:
			named.append(str(names.get(booster_id, booster_id)))
		lines.append(say.say("carried.pleased", {"names": ", ".join(named)}))

	if lines.is_empty():
		return say.say("carried.nothing")
	return "\n".join(lines)


## Whether anything at all carried into this stage.
##
## The screens used to work this out by looking at the sentence above and
## checking whether it began with "Nothing" — so rewording that one line
## would have quietly stopped the carried-over block appearing. They ask
## here instead, and the wording is free to change.
func anything_carried() -> bool:
	for entry: Dictionary in carried_breakdown():
		if int(entry["support_bonus"]) != 0:
			return true
	return not (carried_buffs()["boosters"] as Array).is_empty()


func to_dictionary() -> Dictionary:
	return {
		"level_id": level.get("level_id", ""),
		"index": index,
		"results": results.duplicate(true),
		"outcome": _outcome,
	}


## Everything needed to pick this level up again later: the level exactly as
## it was dealt (its opponents and visitors are drawn at random when it
## starts, so they are kept rather than drawn again), and how far through it
## the player is.
func snapshot() -> Dictionary:
	var saved := to_dictionary()
	saved["level"] = level.duplicate(true)
	return saved


## A runner rebuilt from snapshot(). Returns null when the snapshot is not
## one, so a damaged save falls back to the Office instead of a broken level.
static func restored(saved: Dictionary) -> LevelRunner:
	if not (saved.get("level") is Dictionary):
		return null
	var runner := LevelRunner.new(saved["level"])
	if runner.stages.is_empty():
		return null
	runner.index = clampi(int(saved.get("index", 0)), 0, runner.stages.size())
	runner.results = (saved.get("results", {}) as Dictionary).duplicate(true)
	var outcome := str(saved.get("outcome", ONGOING))
	runner._outcome = outcome if outcome in [ONGOING, WON, LOST] else ONGOING
	return runner


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


## The workbook's column names, and what the player calls them. Renamed
## 2026-09-22: win_delta_kanban/win_delta_kaban became win_delta_reputation/
## win_delta_yen in stages.json.
const WIN_DELTA_KEYS := {
	"win_delta_jiban": "Constituency support",
	"win_delta_reputation": "Reputation",
	"win_delta_yen": "Funds",
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
	# 2026-09-22: xp_reward was renamed win_delta_xp.
	if int(stage.get("win_delta_xp", 0)) != 0:
		return false
	return not stage.has("tone_effects")


## What a stage produces that is not a flat reward — described, not forecast.
##
## Cameron asked the briefing for STATIC values only: a press conference's
## worth depends on the tone it closes on and a caucus's on its score, so
## those are named as variable rather than given a number that would be a
## guess.
static func variable_rewards(stage: Dictionary, words: Phrase = null) -> Array[String]:
	var say := words if words != null else Phrase.new()
	var lines: Array[String] = []
	var effects: Dictionary = stage.get("tone_effects", {})

	var per_variable: Dictionary = effects.get("meta", {})
	for name: String in per_variable.keys():
		var per := int(per_variable[name])
		if per > 0:
			lines.append(say.say("reward.by_finish", {
				"name": name,
				"baseline": int(effects.get("baseline", 50)),
				"per": per,
			}))

	var per_support := int(effects.get("support_per_points", 0))
	if per_support > 0:
		lines.append(say.say("reward.head_start", {
			"per": per_support,
			"baseline": int(effects.get("baseline", 50)),
		}))

	if _asks_questions(stage):
		lines.append(say.say("reward.standing"))

	return lines
