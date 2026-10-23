class_name VoteWhip
extends RefCounted
## Whipping the vote (2026-10-22, Cameron): the player spends Party support to
## pull extra members of their own party to their pick. Prices and limits are
## Balance levers; this file is only the arithmetic.
##
## A whip costs the base price, and a multiple of it (3x) when the pick goes
## against the player's own party's position on the bill: a Supportive party
## voting Aye is with the party, anything else is against it; an Opposed party
## voting Nay is with the party, anything else is against it; a Neutral party
## has no position to go against.
##
## Pure and UI-free (CLAUDE.md section 12).


## True when `choice` ("Yes", "No" or "Abstain") goes against a party whose
## position on the bill is `disposition` (Supportive, Opposed or Neutral).
static func against_party(disposition: String, choice: String) -> bool:
	match disposition:
		"Supportive":
			return choice != "Yes"
		"Opposed":
			return choice != "No"
	return false


## What one whipped vote costs, in Party support.
static func unit_cost(disposition: String, choice: String, base_cost: int, against_multiplier: int) -> int:
	return base_cost * (maxi(against_multiplier, 1) if against_party(disposition, choice) else 1)


## How many votes can be whipped: limited by what the player can spare above
## the floor (stored Party support may not drop below it), by the seats left in
## their party outside their pick, and by the per-vote cap.
static func max_whips(unit: int, party_support: int, floor_value: int, capacity: int, per_vote_cap: int) -> int:
	var spare := maxi(party_support - floor_value, 0)
	var affordable := capacity if unit <= 0 else spare / unit
	return maxi(mini(mini(affordable, capacity), per_vote_cap), 0)


## Organizations whose goodwill makes whipping cheaper: standing at or above
## `min_standing`, a positive stake in the player's own party (`stakeholders`,
## party_stakeholders.json rows for OWN or the own party_id), and not already a
## row of the vote-influence gate that applies to the own party. Returns the
## booster_ids in stakeholder order.
static func discount_orgs(stakeholders: Array, triggers: Array, standing: Dictionary,
		own_party_id: String, min_standing: int, default_standing: int) -> Array[String]:
	var gate_orgs := {}
	for row: Variant in triggers:
		var trigger := row as Dictionary
		if str(trigger.get("enabled", "")) != "Yes":
			continue
		var scoped: Variant = trigger.get("applies_to_parties")
		var scope: Array = scoped if scoped is Array else []
		if scope.is_empty() or scope.has(own_party_id):
			gate_orgs[str(trigger.get("variable", ""))] = true
	var out: Array[String] = []
	for row: Variant in stakeholders:
		var entry := row as Dictionary
		var who := str(entry.get("party_id", ""))
		if who != "OWN" and who != own_party_id:
			continue
		var booster_id := str(entry.get("booster_id", ""))
		if float(entry.get("weight", 0.0)) <= 0.0 or gate_orgs.has(booster_id) or out.has(booster_id):
			continue
		if int(standing.get(booster_id, default_standing)) >= min_standing:
			out.append(booster_id)
	return out


## The per-vote price after the discount: `amount` off when at least one
## organization qualifies (a flat amount, not per organization), never below
## `floor_cost`, and never raised if the price is already at or under it.
static func discounted_unit(unit: int, qualifying: int, amount: int, floor_cost: int) -> int:
	if qualifying <= 0 or amount <= 0:
		return unit
	return mini(unit, maxi(unit - amount, floor_cost))
