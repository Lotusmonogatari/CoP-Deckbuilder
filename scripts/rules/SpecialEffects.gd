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
## The family bonus_if_target_segment_ge_10 .. _100 (see apply()) is spelled
## out here too, one string per ten-point threshold, rather than generated —
## KNOWN_KEYS is a const and this is what the exporter and the tests check a
## workbook value against, so every value it can actually be needs to appear
## literally.
const TARGET_SEGMENT_BONUS_PREFIX := "bonus_if_target_segment_ge_"

const KNOWN_KEYS := [
	"bonus_if_kanban_ge_60",
	"double_if_target_segment_ge_50",
	"bonus_if_target_segment_ge_10",
	"bonus_if_target_segment_ge_20",
	"bonus_if_target_segment_ge_30",
	"bonus_if_target_segment_ge_40",
	"bonus_if_target_segment_ge_50",
	"bonus_if_target_segment_ge_60",
	"bonus_if_target_segment_ge_70",
	"bonus_if_target_segment_ge_80",
	"bonus_if_target_segment_ge_90",
	"bonus_if_target_segment_ge_100",
	"buff_next_card_this_turn",
	"reveal_next_intent",
	"bonus_opp_minus_if_opp_gaffe",
	"pierce_guard",
	"bonus_if_self_gaffe_0",
	"bonus_if_behind",
	"discount_next_card_this_turn",
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
##   self_gaffe          the player's own gaffe meter
##   player_support      where the player stands on the bar
##   opponent_support    where the opponent stands on it
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

	# The whole ge_10 .. ge_100 family in one place: the threshold is the
	# number on the end of the key, not a value column, so C04 (>= 30%) and
	# C09 (>= 50%) are the same effect at two different marks rather than
	# two effects to maintain.
	if special_key.begins_with(TARGET_SEGMENT_BONUS_PREFIX):
		var threshold := int(special_key.substr(TARGET_SEGMENT_BONUS_PREFIX.length()))
		if share >= threshold / 100.0:
			result["self_plus"] = int(result.get("self_plus", 0)) + amount
			result["flags"]["special_triggered"] = true
		return result

	match special_key:
		"bonus_if_kanban_ge_60":
			# "Gain N; +M more if Kanban (Reputation) >= 60." Not used by any
			# card today (C04 moved to the target-segment family above), kept
			# for the next card that wants a Reputation threshold instead of
			# an audience one.
			if int(context.get("kanban", 0)) >= 60:
				result["self_plus"] = int(result.get("self_plus", 0)) + amount
				result["flags"]["special_triggered"] = true

		"double_if_target_segment_ge_50":
			# C06: "Gain 4; doubled if Constituents >= 50%."
			if share >= 0.5:
				result["self_plus"] = int(result.get("self_plus", 0)) * 2
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

		"pierce_guard":
			# C16, C42, C49: "Ignores N of the opponent's Guard."
			#
			# A flag rather than a number change: the guard is not spent by
			# being ignored, so the battle has to take it off the opponent's
			# bank BEFORE the attack lands rather than afterwards. Doing it
			# here would either double-count or leave the bank wrong.
			result["flags"]["pierce_guard"] = amount
			result["flags"]["special_triggered"] = true

		"bonus_if_self_gaffe_0":
			# C25, C29: "+N more if YOUR gaffe meter is 0."
			# The reward for a clean record, and the reason to keep one.
			if int(context.get("self_gaffe", 0)) == 0:
				result["self_plus"] = int(result.get("self_plus", 0)) + amount
				result["flags"]["special_triggered"] = true

		"bonus_if_behind":
			# C33, C53: "+N more if you trail the opponent in support."
			#
			# Strictly behind: level pegging is not behind. A comeback card
			# that also fires when you are even would be a card that fires
			# most of the time.
			if int(context.get("player_support", 0)) < int(context.get("opponent_support", 0)):
				result["self_plus"] = int(result.get("self_plus", 0)) + amount
				result["flags"]["special_triggered"] = true

		"discount_next_card_this_turn":
			# C36: "Your next card this turn costs 1 less."
			# The mirror of buff_next_card_this_turn: the battle spends it
			# on the next card played and it does not survive the turn.
			result["flags"]["next_card_discount"] = amount
			result["flags"]["special_triggered"] = true

	return result
