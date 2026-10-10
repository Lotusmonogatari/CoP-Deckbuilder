class_name StageCarryOver
extends RefCounted
## What resets, and what carries over, when a stage moves on to its next
## opponent. Pure rules, no UI: the level briefing and the battle Details panel
## both read this, so the player is told exactly what BattleEngine does.
##
## Mirrors BattleEngine._advance_to_next_opponent(): keep the two in step.
##   reset      - everything starts again (committees)
##   stream     - energy refills; gaffes, clock, guard and hand carry (Town Hall)
##   continuous - only support starts again; the rest carries (Floor Debate, Caucus)

const SUPPORT := "support"
const ENERGY := "energy"
const GAFFES := "gaffes"
const TURNS := "turns"
const GUARD := "guard"
const HAND := "hand"
const ALL := [SUPPORT, ENERGY, GAFFES, TURNS, GUARD, HAND]


## {resets: [...], carries: [...]} for a stage that fights several opponents,
## or {} for one that fights a single opponent.
static func between_opponents(stage: Dictionary) -> Dictionary:
	if opponent_total(stage) <= 1:
		return {}
	var resets: Array[String] = []
	match str(stage.get("sequence_mode", "single")):
		"reset":
			resets.assign(ALL)
		"stream":
			resets.assign([SUPPORT, ENERGY])
		"continuous":
			resets.assign([SUPPORT])
		_:
			return {}
	var carries: Array[String] = []
	for resource: String in ALL:
		if not resets.has(resource):
			carries.append(resource)
	return {"resets": resets, "carries": carries}


## How many opponents the stage will really fight: the ones already drawn
## into it, else the workbook's own count.
static func opponent_total(stage: Dictionary) -> int:
	var drawn: Variant = stage.get("opponents")
	if drawn is Array and not (drawn as Array).is_empty():
		return (drawn as Array).size()
	var declared: Variant = stage.get("opponent_count")
	if declared is Dictionary:
		return int((declared as Dictionary).get("max", 1))
	return 1
