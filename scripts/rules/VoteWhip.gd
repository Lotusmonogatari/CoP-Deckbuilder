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
