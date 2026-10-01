class_name StageRouting
extends RefCounted
## Which scene plays a given stage.
##
## Three screens all have to make this same call — OfficeScreen opening a
## level or resuming one already in progress, and BattleScreen/VisitorScreen
## moving on to the next stage of the same level once their own is done —
## and a level can freely mix Combat and Non-combat stages (Office Hours
## sitting between two floor fights, say). One place, so those three calls
## can't quietly drift out of step with each other.

const BATTLE_SCENE := "res://scenes/battle/BattleScreen.tscn"
const VISITOR_SCENE := "res://scenes/office_hours/VisitorScreen.tscn"
const FLOOR_VOTE_SCENE := "res://scenes/office_hours/FloorVoteScreen.tscn"
const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

## Not a stage in its own right — a level-level beat (2026-09-27) shown once,
## between the Office and a level's first stage, when LevelIntroCues.resolve()
## has something for a hired staff member to say. Named here alongside the
## other three so a fourth caller joins this one place rather than bypassing
## it — see OfficeScreen._on_start().
const LEVEL_INTRO_SCENE := "res://scenes/office_hours/LevelIntroScreen.tscn"

## A short beat between two stages of the SAME level (2026-10-01, §7.9),
## opt-in per stage via stages.json's own `show_transition` — see
## go_to_next_stage() below, StageTransitionScreen.gd, StageTransition.gd.
const TRANSITION_SCENE := "res://scenes/office_hours/StageTransitionScreen.tscn"


## The screen this stage plays on — VisitorScreen for Office Hours (mode
## "Non-combat"), FloorVoteScreen for National Assembly Floor Voting (mode
## "Vote"), BattleScreen for everything else.
static func scene_for(stage: Dictionary) -> String:
	match str(stage.get("mode", "")):
		"Non-combat": return VISITOR_SCENE
		"Vote": return FLOOR_VOTE_SCENE
		_: return BATTLE_SCENE


## What BattleScreen/VisitorScreen/FloorVoteScreen all call once their own
## stage is done and the level isn't over: go to the next stage's screen,
## reloading in place when it's the same screen type (the cheap path every
## one of them already took), UNLESS the upcoming stage wants a Stage
## Transition first — checked here, once, so a transition can't be skipped
## by one of the three call sites forgetting to check it themselves.
##
## `from_scene_const` is whichever of this file's own *_SCENE constants the
## caller's own screen is, so it can tell "the next stage is the same kind
## of screen I already am" from "it's a different one" without duplicating
## that comparison at every call site.
static func go_to_next_stage(tree: SceneTree, from_scene_const: String) -> void:
	var stage := GameState.level_runner.current_stage()
	if StageTransition.should_show(stage):
		tree.change_scene_to_file(TRANSITION_SCENE)
		return

	var next_scene := scene_for(stage)
	if next_scene == from_scene_const:
		tree.reload_current_scene()
	else:
		tree.change_scene_to_file(next_scene)
