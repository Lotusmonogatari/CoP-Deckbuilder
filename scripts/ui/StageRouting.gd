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


## The screen this stage plays on — VisitorScreen for Office Hours (mode
## "Non-combat"), FloorVoteScreen for National Assembly Floor Voting (mode
## "Vote"), BattleScreen for everything else.
static func scene_for(stage: Dictionary) -> String:
	match str(stage.get("mode", "")):
		"Non-combat": return VISITOR_SCENE
		"Vote": return FLOOR_VOTE_SCENE
		_: return BATTLE_SCENE
