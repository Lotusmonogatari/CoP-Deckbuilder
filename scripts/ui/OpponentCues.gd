class_name OpponentCues
extends RefCounted
## What an opponent says on their own turn, from the workbook's Opponent
## Cues tab.
##
## Two kinds of row: a bespoke one names one or more Opponent IDs and is
## checked FIRST — never blended with the general pool. A general row names
## no opponent at all, and is the pool every opponent with that Suit draws
## from for that Verb, when no bespoke line exists for them. An opponent's
## "suit_1" is the one that picks their pool [DEFAULT] — the first of up to
## three suits an opponent has, since a cue is flavour, not a rules
## decision, and does not need a rules.json switch.
##
## THE CHOICE IS NOT RANDOM, the same as CardCues: worked out from the
## opponent, the verb, the stage and the turn, so it is stable for that
## moment and does not repeat within a stage by coincidence.
##
## This is presentation. The rules never see a cue, and an opponent or suit
## with nothing written yet simply says nothing — BattleScreen falls back to
## today's narration-only banner.

## One of the opponent's lines for this moment: what is said, and the key a
## recording of it would live under in data/sounds.json.
##
## Comes back empty where nothing is written for this opponent/suit and
## verb, which is what the screen checks before it says anything.
static func for_move(opponent: Dictionary, verb: String, stage_id: String, turn: int) -> Dictionary:
	var opp_id := str(opponent.get("opp_id", ""))
	if opp_id.is_empty() or verb.is_empty():
		return {"text": "", "line_id": ""}

	var lines: Array[String] = DataDB.get_bespoke_opponent_cue_lines(opp_id, verb)
	if lines.is_empty():
		lines = DataDB.get_general_opponent_cue_lines(str(opponent.get("suit_1", "")), verb)
	if lines.is_empty():
		return {"text": "", "line_id": ""}

	var which := _index_for(opp_id, verb, stage_id, turn) % lines.size()
	return {
		"text": lines[which],
		"line_id": "%s_%s_%d" % [opp_id, verb, which + 1],
	}


## Which line, as a number that is stable for a given moment. See
## CardCues._index_for() — same idea, one more field (the verb) since one
## opponent has a line for each of the three verbs.
static func _index_for(opp_id: String, verb: String, stage_id: String, turn: int) -> int:
	return absi(hash("%s|%s|%s|%d" % [opp_id, verb, stage_id, turn]))
