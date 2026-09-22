class_name MetaRules
extends RefCounted
## The rules that live between battles, not inside them.
##
## How hard a bill is to pass, what a win does to the player's standing, and
## which effects switch on when a meta-variable crosses a line.
##
## The four meta-variables, from sanban.json:
##   Constituency support (Jiban)  your local base
##   Reputation (Kanban)           how you play in the press
##   Funds (Kaban)                 money
##   Party support                 how your own party feels about you
##
## FOUR OF THE RULES BELOW ARE NOT CALLED BY THE GAME YET.
##
## Their arithmetic is right and it is tested, which is exactly the problem:
## a green test suite reads as though CLAUDE.md §8 were implemented, and four
## of its systems currently do nothing at all. Named here so that nobody —
## me included, six weeks from now — mistakes tested for wired:
##
##   town_hall_triggered          §8: Jiban ≤ 15 inserts a Town Hall (ST05)
##   steering_committee_triggered §8: party support < 25 inserts ST08
##   funding_frozen               §8: Jiban at 0 stops Kaban income
##   party_support_modifiers      §8: > 75 gives M09, < 50 gives M10
##
## They wait for the module runner at M4, which is where the brief puts the
## machinery that would insert a stage into a level. One thing that milestone
## will need FIRST: there is no "steering_committee" stage type in
## data/stage_types.json, so ST08 needs content from Cameron before it needs
## code. Inventing one here would be inventing canon.


## How much harder a bill is because the public disagrees with it.
##
##     difficulty = round((neutral - alignment) x factor)
##
## `alignment` is how much the public wants what the bill does. When the bill
## asks for MORE of a topic, that's simply the opinion value. When it asks for
## LESS, it's the opposite — 100 minus the value. So a bill cutting taxes is
## easy exactly when the public is cold on taxation.
##
## The result is added to the opponent's starting support: an unpopular bill
## means starting further behind.
static func bill_difficulty(direction: int, yoron_value: int,
		factor: float, neutral_point: float) -> int:
	var alignment := yoron_value if direction >= 0 else 100 - yoron_value
	return CardResolver.round_half_up((neutral_point - float(alignment)) * factor)


## The same thing, reading straight from the data files.
static func bill_difficulty_from_data(bill: Dictionary, topic: Dictionary,
		balance: Dictionary) -> int:
	return bill_difficulty(
		int(bill.get("direction", 1)),
		int(topic.get("start_value", 50)),
		float(balance.get("bill_difficulty_factor", 0.2)),
		float(balance.get("yoron_neutral_point", 50.0)),
	)


## Keeps a meta-variable inside the range sanban.json gives it.
static func clamp_meta(value: int, variable: Dictionary) -> int:
	var low := int(variable.get("min", 0))
	var high := int(variable.get("max", 100))
	return clampi(value, low, high)


## Applies a stage's win rewards to the player's standing.
##
## `meta` maps variable names to their current values. Returns a new
## dictionary — the original is left alone — along with what actually changed
## after clamping, so the UI can show "+3 Reputation" honestly rather than
## promising a rise that the maximum swallowed.
static func apply_win_deltas(meta: Dictionary, stage: Dictionary,
		sanban_rows: Array) -> Dictionary:
	var updated := meta.duplicate()
	var applied := {}

	var deltas := {
		"Constituency support": int(stage.get("win_delta_jiban", 0)),
		"Reputation": int(stage.get("win_delta_kanban", 0)),
		"Funds": int(stage.get("win_delta_kaban", 0)),
		"Party support": int(stage.get("win_delta_party_support", 0)),
	}

	for name: String in deltas.keys():
		var delta: int = deltas[name]
		if delta == 0:
			continue
		var variable := _find_variable(sanban_rows, name)
		var before := int(updated.get(name, variable.get("start", 0)))
		var after := clamp_meta(before + delta, variable)
		updated[name] = after
		applied[name] = after - before

	return {"meta": updated, "applied": applied}


## Applies what a stage's closing score did to the player's standing.
##
## A stage says what its score is worth under "tone_effects.meta": a variable
## name mapped to how many points of score make one point of it. A press
## conference that closes ten points above its baseline with a "Reputation"
## of 5 is worth two reputation; ten points below costs two.
##
## Same shape as apply_win_deltas: a new dictionary plus what actually
## changed once the minimums and maximums had their say.
static func apply_score_effects(meta: Dictionary, stage: Dictionary, score: int,
		sanban_rows: Array) -> Dictionary:
	var updated := meta.duplicate()
	var applied := {}

	var effects: Dictionary = stage.get("tone_effects", {})
	var per_variable: Dictionary = effects.get("meta", {})
	if per_variable.is_empty():
		return {"meta": updated, "applied": applied}

	var baseline := int(effects.get("baseline", 50))
	var distance := score - baseline

	for name: String in per_variable.keys():
		var per := int(per_variable[name])
		if per <= 0:
			continue

		# Towards zero in both directions, so falling just short of the
		# baseline costs nothing rather than a whole point.
		var delta := int(float(distance) / float(per))
		if delta == 0:
			continue

		var variable := _find_variable(sanban_rows, name)
		var before := int(updated.get(name, variable.get("start", 0)))
		var after := clamp_meta(before + delta, variable)
		updated[name] = after
		applied[name] = after - before

	return {"meta": updated, "applied": applied}


## Which modifiers are switched on by the player's standing with their party.
##
## Above the allied threshold, the party is behind you (M09 Party Backing).
## Below the debuff threshold, it is not (M10 Cold Shoulder). In between,
## neither applies.
static func party_support_modifiers(party_support: int, balance: Dictionary) -> Array:
	var allied := int(balance.get("party_support_allied_buff", 75))
	var debuff := int(balance.get("party_support_debuff", 50))

	if party_support > allied:
		return ["M09"]
	if party_support < debuff:
		return ["M10"]
	return []


## Whether the Party Steering Committee stage should be forced into the queue.
static func steering_committee_triggered(party_support: int, balance: Dictionary) -> bool:
	return party_support < int(balance.get("party_support_steering_committee", 25))


## Whether a Town Hall should be inserted because the local base has thinned.
static func town_hall_triggered(jiban: int, balance: Dictionary) -> bool:
	return jiban <= int(balance.get("jiban_town_hall_trigger", 15))


## Whether funding is frozen. At zero local support the money stops.
static func funding_frozen(jiban: int, balance: Dictionary) -> bool:
	return jiban <= int(balance.get("jiban_funding_freeze", 0))


## Reputation's effect on a press stage's starting support.
##
## A strong reputation opens a press conference in your favour and a poor one
## against you, by the amounts in sanban.json's thresholds.
static func press_start_adjustment(kanban: int, sanban_rows: Array) -> int:
	var reputation := _find_variable(sanban_rows, "Reputation")
	var low := int(reputation.get("low_threshold", 20))
	var high := int(reputation.get("high_threshold", 80))

	if kanban >= high:
		return 5
	if kanban <= low:
		return -5
	return 0


## Which modifiers are active given the stage's audience.
##
## A modifier only fires when the audience it cares about makes up at least
## its trigger share of the room. A modifier with no trigger share — the ones
## driven by party support rather than by who's watching — is left to the
## caller, since its condition lives elsewhere.
static func active_modifiers(modifier_rows: Array, stage: Dictionary,
		available_to: String = "Player") -> Array:
	var active: Array = []
	var mix: Dictionary = stage.get("segment_mix", {})

	for modifier: Dictionary in modifier_rows:
		var audience: Variant = modifier.get("available_to")
		if audience != null and audience != "Both" and audience != available_to:
			continue

		var minimum: Variant = modifier.get("trigger_min_pct")
		if minimum == null:
			continue   # not audience-driven; the caller decides

		var segment_id: Variant = modifier.get("trigger_segment_id")
		if segment_id == null:
			continue

		if float(mix.get(segment_id, 0.0)) >= float(minimum):
			active.append(modifier)

	return active


static func _find_variable(sanban_rows: Array, name: String) -> Dictionary:
	for row: Dictionary in sanban_rows:
		if row.get("name_en") == name:
			return row
	return {"min": 0, "max": 100, "start": 0}
