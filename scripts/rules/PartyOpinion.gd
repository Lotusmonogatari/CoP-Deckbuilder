class_name PartyOpinion
extends RefCounted
## How a party sees the player. Pure arithmetic, no UI, no autoloads.
##
## Every party, the player's own included, has two parts:
##   DIRECT       what votes, rewards and leans have done (the player's own
##                party: the Party support meta; the other five: party_standing)
##   STAKEHOLDER  how the organisations tied to the party feel about the
##                player (the workbook's Party Standing tab)
## and the OPINION is the two blended by the Balance tab's weights (50/50).
##
## STAKEHOLDER maths. Each tied organisation has a weight (negative = a
## rival) and a standing 0-100. Its pull is weight * (standing - 50), so 50
## is neutral for everyone, and the whole thing is divided by the sum of the
## ABSOLUTE weights so the scale of the weights never matters:
##     score = 50 + sum(weight * (standing - 50)) / sum(|weight|)
## With only positive weights this is the ordinary weighted average. A rival
## at 90 drags the score below 50; a rival at 10 lifts it above.
## A party with no rows has NO stakeholder part (score -1) and its opinion is
## just its direct number, so an empty table changes nothing.

const OWN := "OWN"
const NO_SCORE := -1


## The rows that apply to `party_id`: its own PTxx rows, plus the OWN rows if
## it is the player's party.
static func rows_for(table: Array, party_id: String, own_party_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Variant in table:
		if not (row is Dictionary):
			continue
		var who := str((row as Dictionary).get("party_id", ""))
		if who == party_id or (who == OWN and party_id == own_party_id and not own_party_id.is_empty()):
			out.append(row)
	return out


## {score: int (or NO_SCORE), contributions: [{booster_id, weight, standing,
## effect}]} where effect is how many points that organisation moved the score.
static func stakeholder(rows: Array, standing: Dictionary, default_standing: int) -> Dictionary:
	var total_abs := 0.0
	var pulls := {}
	var weights := {}
	for row: Variant in rows:
		var booster_id := str((row as Dictionary).get("booster_id", ""))
		var weight := _number((row as Dictionary).get("weight"))
		if booster_id.is_empty() or is_zero_approx(weight):
			continue
		total_abs += absf(weight)
		weights[booster_id] = float(weights.get(booster_id, 0.0)) + weight
	if total_abs <= 0.0:
		return {"score": NO_SCORE, "contributions": []}

	var contributions: Array[Dictionary] = []
	var sum := 0.0
	for booster_id: String in weights.keys():
		var here := int(standing.get(booster_id, default_standing))
		var weight := float(weights[booster_id])
		var effect := weight * float(here - 50) / total_abs
		sum += effect
		contributions.append({"booster_id": booster_id, "weight": weight,
			"standing": here, "effect": effect})
	return {"score": clampi(roundi(50.0 + sum), 0, 100), "contributions": contributions}


## Direct and stakeholder blended. No stakeholder part, or both weights zero,
## means the direct number stands alone.
static func opinion(direct: int, stakeholder_score: int, balance: Dictionary) -> int:
	var wd := maxf(_number(balance.get("party_opinion_direct_weight", 50)), 0.0)
	var ws := maxf(_number(balance.get("party_opinion_stakeholder_weight", 50)), 0.0)
	if stakeholder_score == NO_SCORE or (wd + ws) <= 0.0:
		return clampi(direct, 0, 100)
	return clampi(roundi((wd * direct + ws * stakeholder_score) / (wd + ws)), 0, 100)


## "hostile" .. "allied" for a score, from the Balance tab's cut-offs.
static func band(score: int, balance: Dictionary) -> String:
	if score < int(balance.get("party_opinion_hostile_below", 20)):
		return "hostile"
	if score < int(balance.get("party_opinion_cold_below", 40)):
		return "cold"
	if score < int(balance.get("party_opinion_neutral_below", 60)):
		return "neutral"
	if score < int(balance.get("party_opinion_warm_below", 80)):
		return "warm"
	return "allied"


static func _number(value: Variant) -> float:
	if value == null:
		return 0.0
	if value is int or value is float:
		return float(value)
	return 0.0
