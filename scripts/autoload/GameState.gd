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


func _ready() -> void:
	reset_meta()


## Back to the starting standing in sanban.json.
func reset_meta() -> void:
	meta = BattleSetup.starting_meta()
	last_meta_change = {}


## Called by the Office when the player starts a level.
func begin_level(runner: LevelRunner) -> void:
	level_runner = runner
	last_level_outcome = ""
	last_meta_change = {}


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
	_apply_score_effects(level_runner.current_stage(), score)

	level_runner.finish_stage(outcome, score, boosters)

	if level_runner.is_finished():
		last_level_outcome = level_runner.outcome()
		return true
	return false


## Moves the meta-variables by what the stage's closing score was worth.
##
## The conversion lives in the stage's own data, so what a press conference is
## worth is a number Cameron can change rather than a rule written in code.
func _apply_score_effects(stage: Dictionary, score: int) -> void:
	last_meta_change = {}
	if stage.is_empty():
		return

	var result := MetaRules.apply_score_effects(meta, stage, score, DataDB.sanban)
	meta = result["meta"]
	last_meta_change = result["applied"]


## Clears the level, on the way back to the Office.
func end_level() -> void:
	level_runner = null
