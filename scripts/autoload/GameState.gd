extends Node
## Holds the state of the current run: which level is being played, how far
## through it the player is, where the player's standing sits, and how the
## last level went.
##
## This is the campaign's memory. It is deliberately separate from the rules
## engine, which is the maths of a single battle and remembers nothing.
##
## STILL PARTLY A PLACEHOLDER. Saving to disk and the deck arrive at milestone
## M4. The meta-variables now live here, but only the press conference moves
## them so far — the stage win deltas in the workbook are still unwired.

## The level being played, or null when the player is in the Office.
var level_runner: LevelRunner = null

## How the last finished level went: "win", "loss", or empty if none yet.
## Lives only for this sitting until M4 adds saving.
var last_level_outcome: String = ""

## The player's standing: constituency support, reputation, funds and party
## support, by the English names sanban.json gives them. Seeded from that
## file's starting values and then moved by what happens in a stage.
##
## Lives only for this sitting until M4 adds saving.
var meta: Dictionary = {}

## What the last finished stage did to those variables, e.g.
## { "Reputation": 3 }. Cleared when the next stage starts. The battle screen
## reads it to tell the player what just happened to them.
var last_meta_change: Dictionary = {}

## Experience earned so far, and by the stage just finished.
##
## CLAUDE.md puts the XP checkpoint at milestone M5, so nothing spends this
## yet. It is banked rather than discarded so the checkpoint has a real
## number to open with, and so a stage's xp_reward stops being a column the
## workbook exports and no code has ever read.
var xp := 0
var last_xp_gained := 0

## Where the player stands with each of the ten organisations, by booster ID.
## Pleasing one at a press conference raises it, and it is held between
## levels — unlike the pleased list, which lasts one level.
##
## Lives only for this sitting until M4 adds saving.
var booster_standing: Dictionary = {}

## What the last finished level did to those, e.g. { "BO08": 5 }.
var last_booster_change: Dictionary = {}


func _ready() -> void:
	reset_meta()
	reset_booster_standing()


## Back to the starting standing in sanban.json.
func reset_meta() -> void:
	meta = BattleSetup.starting_meta()
	last_meta_change = {}
	xp = 0
	last_xp_gained = 0


## Every organisation back to where booster_standing.json starts them.
func reset_booster_standing() -> void:
	booster_standing = {}
	last_booster_change = {}

	var start := int(DataDB.booster_standing.get("start", 50))
	for booster: Dictionary in DataDB.boosters:
		booster_standing[str(booster.get("booster_id"))] = start


## Called by the Office when the player starts a level.
func begin_level(runner: LevelRunner) -> void:
	level_runner = runner
	last_level_outcome = ""
	last_meta_change = {}
	last_xp_gained = 0
	last_booster_change = {}


## True while a level is in progress.
func is_in_level() -> bool:
	return level_runner != null and not level_runner.is_finished()


## Records how a stage went and moves the level on. Returns true when the
## level is now over, which is the battle screen's cue to head back.
func finish_stage(outcome: String, score: int = 0, boosters: Array = []) -> bool:
	if level_runner == null:
		return true

	# What the stage just played did to the player's standing, before the
	# runner moves on and current_stage() becomes the next one.
	_apply_stage_rewards(level_runner.current_stage(), outcome, score)
	_please_organisations(boosters)

	level_runner.finish_stage(outcome, score, boosters)

	if level_runner.is_finished():
		last_level_outcome = level_runner.outcome()
		return true
	return false


## Everything a finished stage is worth, in the order the brief sets out.
##
## Two separate things, and they stack:
##
##   Win deltas — flat rewards for winning, straight off the stage row.
##   These have been in the workbook and in MetaRules since milestone 1 and
##   have never had a caller, so winning a stage moved nothing at all.
##
##   Score effects — what the closing number was worth, for the stages that
##   produce one. The conversion lives in the stage's own data, so what a
##   press conference is worth is a number Cameron can change rather than a
##   rule written in code.
##
## The playtest stages carry zeroes for the win deltas until Cameron fills
## them in; the wiring is here so the moment he does, they land.
func _apply_stage_rewards(stage: Dictionary, outcome: String, score: int) -> void:
	last_meta_change = {}
	last_xp_gained = 0
	if stage.is_empty():
		return

	# Losing a stage earns nothing. A score the player reached on the way to
	# losing still is not a result.
	if outcome == LevelRunner.WON:
		var won := MetaRules.apply_win_deltas(meta, stage, DataDB.sanban)
		meta = won["meta"]
		_record_meta_change(won["applied"])
		last_xp_gained = int(stage.get("xp_reward", 0))
		xp += last_xp_gained

	var scored := MetaRules.apply_score_effects(meta, stage, score, DataDB.sanban)
	meta = scored["meta"]
	_record_meta_change(scored["applied"])


## Folds one lot of changes into what the screen will report.
##
## A stage can move the same variable twice — a flat reward for winning and
## again for the score it closed on — and the player should be told the
## total, not shown the second overwriting the first.
func _record_meta_change(applied: Dictionary) -> void:
	for name: String in applied.keys():
		last_meta_change[name] = int(last_meta_change.get(name, 0)) + int(applied[name])


## Raises the player's standing with everyone pleased in a stage.
##
## Standing is what survives the level; the pleased list is what the floor
## debate draws on inside it. The two are separate on purpose: pleasing the
## same organisation twice in one level counts once for the floor debate, and
## once for the standing too, because the pleased list is deduplicated before
## it ever gets here.
func _please_organisations(boosters: Array) -> void:
	if boosters.is_empty():
		return

	var step := int(DataDB.booster_standing.get("per_please", 5))
	var low := int(DataDB.booster_standing.get("min", 0))
	var high := int(DataDB.booster_standing.get("max", 100))

	for booster_id: String in boosters:
		var before := int(booster_standing.get(booster_id, 50))
		var after := clampi(before + step, low, high)
		booster_standing[booster_id] = after
		if after != before:
			last_booster_change[booster_id] = after - before


## Clears the level, on the way back to the Office.
func end_level() -> void:
	level_runner = null
