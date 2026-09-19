class_name SpecialEffects
extends RefCounted
## The named effects behind cards whose text says "if".
##
## A card's effect_text is for the player to read — the game never tries to
## parse it. Instead, a card names an effect here in its `special` column, and
## the size of the effect lives in `special_value` so it stays a number in the
## workbook rather than a number buried in code.
##
## NOTE: the `special` and `special_value` columns do not exist in the
## workbook yet. They are proposed in design/proposals/. Everything here is
## written and tested, and starts working for a card the moment the column is
## filled in for it. Until then these cards play as their plain numbers, and
## the exporter says so in its report.
##
## ADDING A NEW ONE
## Add a case to `apply()` below, then tell Cameron the key to put in the
## workbook. Keys read as sentences on purpose: a threshold that never varies
## (60, 50%) lives in the key, and the part he may want to tune lives in
## `special_value`.

## Every key this registry understands. The exporter and the tests check
## against this list, so a typo in the workbook is caught rather than
## silently doing nothing.
const KNOWN_KEYS := [
	"bonus_if_kanban_ge_60",
	"double_if_target_segment_ge_50",
	"bonus_if_target_segment_ge_50",
	"buff_next_card_this_turn",
	"reveal_next_intent",
	"bonus_opp_minus_if_opp_gaffe",
	"pass_turn",
]


## Applies a card's special effect to the numbers already worked out for it.
##
## `effect` is the card's resolved amounts so far: self_plus, opp_minus,
## guard, draw, gaffe. This returns a modified copy plus any side effects the
## battle needs to act on, under "flags".
##
## `context` describes the situation:
##   affinity            the suit multiplier for this stage
##   segment_share       0..1, how much of this audience is the card's target
##   kanban              the player's reputation
##   opponent_gaffe      the opponent's gaffe meter
static func apply(key: Variant, value: Variant, effect: Dictionary, context: Dictionary) -> Dictionary:
	var result := effect.duplicate()
	result["flags"] = effect.get("flags", {}).duplicate()

	if key == null or str(key).is_empty():
		return result

	var special_key := str(key)
	if not KNOWN_KEYS.has(special_key):
		push_warning("SpecialEffects: no effect called '%s'. The card will play as its plain numbers." % special_key)
		return result

	# `special_value` is how much, when the effect needs a number.
	var amount := 0 if value == null else int(value)
	var share := float(context.get("segment_share", 0.0))

	match special_key:
		"bonus_if_kanban_ge_60":
			# C04: "Gain 6; +2 more if Kanban >= 60."
			if int(context.get("kanban", 0)) >= 60:
				result["self_plus"] = int(result.get("self_plus", 0)) + amount
				result["flags"]["special_triggered"] = true

		"double_if_target_segment_ge_50":
			# C06: "Gain 4; doubled if Constituents >= 50%."
			if share >= 0.5:
				result["self_plus"] = int(result.get("self_plus", 0)) * 2
				result["flags"]["special_triggered"] = true

		"bonus_if_target_segment_ge_50":
			# C09 and C10: "+2 if Loyalists / Constituents >= 50%."
			# One effect covers both, because the card's target_segment
			# already says which audience to look at.
			if share >= 0.5:
				result["self_plus"] = int(result.get("self_plus", 0)) + amount
				result["flags"]["special_triggered"] = true

		"buff_next_card_this_turn":
			# C11 Groundwork: "Your next card this turn gets +2."
			# The battle picks this up and adds it to the next card played.
			result["flags"]["next_card_bonus"] = amount
			result["flags"]["special_triggered"] = true

		"reveal_next_intent":
			# C12 Head Count: "Reveal opponent's next intent."
			result["flags"]["reveal_next_intent"] = true
			result["flags"]["special_triggered"] = true

		"bonus_opp_minus_if_opp_gaffe":
			# C15: "Opponent -6; -2 more if opponent gaffe > 0."
			if int(context.get("opponent_gaffe", 0)) > 0:
				result["opp_minus"] = int(result.get("opp_minus", 0)) + amount
				result["flags"]["special_triggered"] = true

		"pass_turn":
			# PT_C01 Don't Engage: "Pass the round."
			#
			# The card's own gaffe number is the price; this key only says
			# that playing it hands the round over. In a press conference the
			# round IS the question, and every card answers a question
			# already, so this does nothing there and the card still works:
			# you have declined, out loud, and the next reporter speaks.
			result["flags"]["end_turn"] = true
			result["flags"]["special_triggered"] = true

	return result
