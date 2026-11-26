class_name Selection
extends RefCounted
## The Candidate Selection Committee's decision (P20, 2026-11-26, Cameron), read on the morning Campaign Open begins:
##
##   score = strength x w_strength + alignment x w_alignment + influence x w_influence     (the weights are percents, Balance selection_weight_*)
##   influence = (Party support + the Candidate Selection Committee's standing, BO32) / 2
##
## Outcomes by score (thresholds from Balance selection_threshold_*): under the list threshold `not_selected`; from it to just under the
## district threshold `list`; from that to just under the safety-net threshold `smd`; at or above it `smd_safety_net`. Pure and UI-free.

const NOT_SELECTED := "not_selected"
const LIST := "list"
const SMD := "smd"
const SMD_SAFETY_NET := "smd_safety_net"


## The influence part: the average of Party support and standing with the Selection Committee (both 0 to 100).
static func influence(party_support: int, committee_standing: int) -> float:
	return (float(party_support) + float(committee_standing)) / 2.0


## The score, 0 to 100, rounded to a whole number (half away from zero).
static func score(strength: float, alignment: float, influence_value: float) -> int:
	var total := strength * Levers.num("selection_weight_strength") + alignment * Levers.num("selection_weight_alignment") \
		+ influence_value * Levers.num("selection_weight_influence")
	return clampi(roundi(total / 100.0), 0, 100)


## The outcome for a score.
static func outcome(score_value: int) -> String:
	if score_value >= Levers.whole("selection_threshold_safety_net"):
		return SMD_SAFETY_NET
	if score_value >= Levers.whole("selection_threshold_smd"):
		return SMD
	if score_value >= Levers.whole("selection_threshold_list"):
		return LIST
	return NOT_SELECTED


## The whole decision from the run's readings: {strength, alignment, influence, score, outcome}.
static func decide(strength: float, alignment: float, party_support: int, committee_standing: int) -> Dictionary:
	var influence_value := influence(party_support, committee_standing)
	var total := score(strength, alignment, influence_value)
	return {"strength": strength, "alignment": alignment, "influence": influence_value, "score": total, "outcome": outcome(total)}


## True for the outcomes that give the player a place on the ballot.
static func is_selected(outcome_id: String) -> bool:
	return outcome_id != NOT_SELECTED
