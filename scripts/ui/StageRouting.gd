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


## The screen this stage plays on — VisitorScreen for Office Hours (mode
## "Non-combat"), FloorVoteScreen for National Assembly Floor Voting (mode
## "Vote"), BattleScreen for everything else.
static func scene_for(stage: Dictionary) -> String:
	match str(stage.get("mode", "")):
		"Non-combat": return VISITOR_SCENE
		"Vote": return FLOOR_VOTE_SCENE
		_: return BATTLE_SCENE
