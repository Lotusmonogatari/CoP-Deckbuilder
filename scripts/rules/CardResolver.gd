class_name CardResolver
extends RefCounted
## Works out what a card actually does in a particular stage.
##
## This is pure arithmetic: numbers in, numbers out, nothing touched and
## nothing remembered. The battle engine decides what to do with the result.
##
## THE ORDER MATTERS, and it is the order in the build brief:
##   1. Multiply the support numbers by the suit's affinity for this stage,
##      and round half up.
##   2. Apply the card's special effect, if it has one.
##   3. Everything else — guard, draw, gaffe — is used as written.
##
## Guard, draw and gaffe are deliberately NOT multiplied by affinity. A stage
## that suits your rhetoric makes your arguments land harder; it doesn't make
## you better at not putting your foot in your mouth.


## Rounds to the nearest whole number, with exact halves going up.
##
## GDScript's built-in round() rounds halves away from zero, so -2.5 becomes
## -3 where this gives -2. Support numbers are positive in practice, but the
## rule is written down here so nobody has to wonder later.
static func round_half_up(value: float) -> int:
	return int(floor(value + 0.5))


## Resolves one card.
##
## `card` is a row from cards.json.
## `context` describes the situation:
##   affinity          the suit multiplier for this stage (from affinity.json)
##   segment_share     0..1, how much of the audience is this card's target
##   kanban            the player's reputation, for cards that check it
##   opponent_gaffe    the opponent's gaffe meter
##   next_card_bonus   a bonus left behind by a card played earlier this turn
##
## Returns:
##   self_plus, opp_minus, guard, draw, gaffe   the amounts to apply
##   cost                                       energy this costs
##   flags                                      side effects for the battle
static func resolve(card: Dictionary, context: Dictionary) -> Dictionary:
	var affinity := float(context.get("affinity", 1.0))

	# Step 1: affinity applies to the two support numbers only.
	var effect := {
		"self_plus": round_half_up(float(_number(card, "self_plus")) * affinity),
		"opp_minus": round_half_up(float(_number(card, "opp_minus")) * affinity),
		"guard": _number(card, "guard"),
		"draw": _number(card, "draw"),
		"gaffe": _number(card, "gaffe"),
		"cost": _number(card, "cost"),
		"flags": {},
	}

	# A bonus from a card played earlier this turn (C11 Groundwork) is a flat
	# addition on top, not something the affinity multiplies again.
	var carried := int(context.get("next_card_bonus", 0))
	if carried != 0 and effect["self_plus"] > 0:
		effect["self_plus"] = int(effect["self_plus"]) + carried
		effect["flags"]["received_bonus"] = carried

	# Step 2: the card's named special effect, if it has one.
	effect = SpecialEffects.apply(card.get("special"), card.get("special_value"), effect, context)

	return effect


## How much of this stage's audience the card is aimed at, as 0..1.
##
## A card with no particular target ("Any") counts as the whole room, so an
## untargeted card is never penalised for the audience mix.
static func segment_share(card: Dictionary, stage: Dictionary) -> float:
	var segment_id: Variant = card.get("target_segment_id")
	if segment_id == null:
		return 1.0
	var mix: Dictionary = stage.get("segment_mix", {})
	return float(mix.get(segment_id, 0.0))


## Reads a number from a card row, treating a missing or empty cell as zero.
static func _number(card: Dictionary, key: String) -> int:
	var value: Variant = card.get(key)
	return 0 if value == null else int(value)
