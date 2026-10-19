class_name LobbyistTrade
extends RefCounted
## The lobbyist's trade (influence building step C, 2026-10-19, Cameron). A
## lobbyist whose organization a patron bill would hurt offers to bargain: the
## player may drop one component of the bill (never the last), and a short
## negotiation sets a LEVERAGE score, a budget the player spends on rewards:
## an office donation (Funds and XP), the organization's goodwill, a party's
## favor, or help working the bill (one seat for the player's pick).
##
## Refusing the lobbyist costs nothing on a Favor bill; on a Flagship, refusing
## costs seats (lobbyists work against the bill) and meeting without reaching
## an agreement costs fewer. Seats are BillAssist "worked_against".
##
## Pure and UI-free (CLAUDE.md section 12): all numbers arrive in `levers`
## (the Balance tab) and all people and pools from the caller.

const DONATION := "donation"
const SENTIMENT := "sentiment"
const PARTY_FAVOR := "party_favor"
const HELP := "help"
const REWARDS := [DONATION, SENTIMENT, PARTY_FAVOR, HELP]
const TRADE_STAGE := "ST262"


## The organization a lobbyist could speak for: one the bill's merged effects
## hurt (negative total), that is not the patron or the ally, and that has a
## representative among `lobbyists` (opponents with an affiliation). Returns
## {"org", "lobbyist"} for the most hurt such organization, or {}.
static func pick_lobbyist(effects: Array, patron: String, ally: String, lobbyists: Array,
		faced: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var hurt: Array = []
	for entry: Dictionary in effects:
		var target := str(entry.get("target", ""))
		if int(entry.get("delta", 0)) < 0 and target != patron and target != ally:
			hurt.append(entry)
	hurt.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["delta"]) < int(b["delta"]))
	for entry: Dictionary in hurt:
		var org := str(entry["target"])
		var pool: Array = lobbyists.filter(func(person: Dictionary) -> bool:
			return str(person.get("affiliation", "")) == org)
		var drawn := PeopleDraw.pick(pool, "opp_id", faced, 1, [], rng)
		if not drawn.is_empty():
			return {"org": org, "lobbyist": drawn[0]}
	return {}


## Components the player may drop: all of them, unless that would leave none
## (a one-component bill cannot be traded down).
static func drop_options(component_ids: Array) -> Array:
	return component_ids.duplicate() if component_ids.size() > 1 else []


## The component the lobbyist most wants gone: the one whose own `loses` list
## hurts `org` the most. "" when none hurts it.
static func asked_component(component_ids: Array, by_id: Dictionary, org: String) -> String:
	var worst := ""
	var worst_delta := 0
	for id: Variant in component_ids:
		var loses: Variant = (by_id.get(str(id), {}) as Dictionary).get("loses")
		if not (loses is Array):
			continue
		for entry: Dictionary in loses:
			if str(entry.get("target", "")) == org and int(entry.get("delta", 0)) < worst_delta:
				worst = str(id)
				worst_delta = int(entry["delta"])
	return worst


## Leverage when the bargaining starts: a share of the player's standing with
## the lobbyist's organization, plus a bonus when the dropped component is the
## one they asked for (a smaller one for any other).
static func starting_leverage(standing: int, dropped_is_asked: bool, levers: Dictionary) -> int:
	var base := floori(standing * int(levers.get("trade_leverage_standing_percent", 25)) / 100.0)
	var bonus := int(levers.get("trade_leverage_asked_bonus", 20)) if dropped_is_asked \
			else int(levers.get("trade_leverage_other_bonus", 5))
	return clampi(base + bonus, 0, 100)


## Leverage after an answer graded Strong, Medium or Weak.
static func after_answer(leverage: int, grade_letter: String, levers: Dictionary) -> int:
	var delta := int(levers.get("trade_strong_points", 15)) if grade_letter == MpVisit.STRONG \
			else (int(levers.get("trade_medium_points", 5)) if grade_letter == MpVisit.MEDIUM \
			else int(levers.get("trade_weak_points", -10)))
	return clampi(leverage + delta, 0, 100)


static func reward_cost(reward: String, levers: Dictionary) -> int:
	match reward:
		DONATION: return int(levers.get("trade_cost_donation", 20))
		SENTIMENT: return int(levers.get("trade_cost_sentiment", 30))
		PARTY_FAVOR: return int(levers.get("trade_cost_party_favor", 40))
		HELP: return int(levers.get("trade_cost_help", 50))
		_: return 0


## What a set of chosen rewards costs.
static func total_cost(chosen: Array, levers: Dictionary) -> int:
	var sum := 0
	for reward: Variant in chosen:
		sum += reward_cost(str(reward), levers)
	return sum


## A deal needs at least one reward and a cost within the leverage.
static func can_close(chosen: Array, leverage: int, levers: Dictionary) -> bool:
	return not chosen.is_empty() and total_cost(chosen, levers) <= leverage


## Seats the lobbyists take from the player's pick when the player refuses to
## meet (`refused`) or meets and reaches no agreement. Favor and Flagship have
## their own numbers (Favor: none by default).
static func seats_lost(kind: String, refused: bool, levers: Dictionary) -> int:
	var key := "trade_%s_%s_seats" % [kind.to_lower(), "refuse" if refused else "no_deal"]
	return int(levers.get(key, 0))


## The party a lobbyist's organization is best tied to (Party Standing, the
## highest weight) that has at least one seat in `pick`, so help or hindrance
## has somewhere to land. Falls back to any party with seats in `pick`.
## `ties` are Party Standing rows ({party_id, booster_id, weight}).
static func party_for_org(org: String, ties: Array, positions: Array, pick: String = "Yes") -> String:
	var has_seats := {}
	for position: Dictionary in positions:
		if int(position.get("votes_%s" % pick.to_lower(), 0)) > 0:
			has_seats[str(position.get("party_id", ""))] = int(position.get("votes_%s" % pick.to_lower(), 0))
	var best := ""
	var best_weight := -INF
	for row: Dictionary in ties:
		var party_id := str(row.get("party_id", ""))
		if str(row.get("booster_id", "")) != org or not has_seats.has(party_id):
			continue
		if float(row.get("weight", 0.0)) > best_weight:
			best = party_id
			best_weight = float(row.get("weight", 0.0))
	if not best.is_empty():
		return best
	var most := 0
	for party_id: String in has_seats:
		if int(has_seats[party_id]) > most:
			best = party_id
			most = int(has_seats[party_id])
	return best


## Standing the patron and the ally lose for a component of theirs that was
## traded away: [{"target", "delta"}].
static func drop_costs(dropped_owner: String, patron: String, ally: String, levers: Dictionary) -> Array:
	var out: Array = []
	if dropped_owner == patron:
		out.append({"target": patron, "delta": -int(levers.get("trade_patron_cost", 3))})
	elif dropped_owner == ally and not ally.is_empty():
		out.append({"target": ally, "delta": -int(levers.get("trade_ally_cost", 1))})
	return out


## The party "help working the bill" works on: the one best tied to the
## organization (highest Party Standing weight) that has at least one seat
## OUTSIDE `pick`, so there is a seat to win. Falls back to any party with
## seats outside `pick`; "" when every party is entirely on the player's side.
static func party_for_help(org: String, ties: Array, positions: Array, pick: String = "Yes") -> String:
	var outside := {}
	for position: Dictionary in positions:
		var seats := 0
		for bucket: String in FloorVoteEngine.BUCKETS:
			if bucket != pick:
				seats += int(position.get("votes_%s" % bucket.to_lower(), 0))
		if seats > 0:
			outside[str(position.get("party_id", ""))] = seats
	var best := ""
	var best_weight := -INF
	for row: Dictionary in ties:
		var party_id := str(row.get("party_id", ""))
		if str(row.get("booster_id", "")) == org and outside.has(party_id) and float(row.get("weight", 0.0)) > best_weight:
			best = party_id
			best_weight = float(row.get("weight", 0.0))
	if not best.is_empty():
		return best
	var most := 0
	for party_id: String in outside:
		if int(outside[party_id]) > most:
			best = party_id
			most = int(outside[party_id])
	return best
