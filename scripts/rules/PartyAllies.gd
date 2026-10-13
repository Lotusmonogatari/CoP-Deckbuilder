class_name PartyAllies
extends RefCounted
## Turns a party's stakeholder contributions (PartyOpinion.stakeholder()) into
## the two lists the Parties popup shows (2026-10-14):
##   ALLIES  organisations the party counts as friends (positive weight);
##           the higher their standing with you, the better for you
##   RIVALS  organisations the party counts as opponents (negative weight);
##           the LOWER their standing with you, the better for you
## Each entry carries a tag for what it is doing to the party's view of you
## RIGHT NOW, which is what the old "Helping/Hurting" lines got wrong by
## sounding like something you had done.

const IMPROVING := "improving"
const NEUTRAL := "neutral"
const REDUCING := "reducing"

## Below this many points either way an organisation is not moving the score.
const NEUTRAL_BAND := 0.5


## "improving" / "neutral" / "reducing" for one contribution's `effect`.
static func tag_for(effect: float) -> String:
	if effect >= NEUTRAL_BAND:
		return IMPROVING
	if effect <= -NEUTRAL_BAND:
		return REDUCING
	return NEUTRAL


## {allies: [...], rivals: [...]}, each entry {booster_id, weight, standing,
## effect, tag}, biggest weight first. Zero-weight entries are dropped.
static func groups(contributions: Array) -> Dictionary:
	var allies: Array[Dictionary] = []
	var rivals: Array[Dictionary] = []
	for entry: Variant in contributions:
		var row := (entry as Dictionary).duplicate()
		var weight := float(row.get("weight", 0.0))
		if is_zero_approx(weight):
			continue
		row["tag"] = tag_for(float(row.get("effect", 0.0)))
		if weight > 0.0:
			allies.append(row)
		else:
			rivals.append(row)
	var by_weight := func(a: Dictionary, b: Dictionary) -> bool:
		return absf(float(a["weight"])) > absf(float(b["weight"]))
	allies.sort_custom(by_weight)
	rivals.sort_custom(by_weight)
	return {"allies": allies, "rivals": rivals}
