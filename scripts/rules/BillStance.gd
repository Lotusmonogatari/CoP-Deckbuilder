class_name BillStance
extends RefCounted
## A bill level's through-line (2026-10-18): the lean you pick on the Level
## Intro screen decides who hears you as a friend or an opponent in every
## stage of that level, your own final vote moves them again, and switching
## your vote away from your lean costs the side you abandon and wins a little
## back from the side you join.
##
## Pure and UI-free (CLAUDE.md §12): callers hand in the bill, the Law Effects
## rows and the Balance numbers; nothing here reads DataDB or GameState.
##
##   sides()          who the bill's supporters and opponents are
##   adjust_tally()   the rhetoric rule: answers pleasing the far side count less
##   win_drift()      what winning a Combat stage in this level does to both sides
##   vote()           what the final vote does, including a flip's price
##
## The side you stand with is set by your lean: Support puts you with the
## bill's supporters, Oppose with its opponents.

const SUPPORT := "Support"
const OPPOSE := "Oppose"


## { "supporters": [booster_id...], "opponents": [booster_id...] }.
##
## An organization the bill's Passed Law Effects rows help is a supporter, one
## they hurt is an opponent (positive and negative deltas summed per
## organization; a range counts as its middle). Organizations in
## `excluded_ids` (the Party-tier ones, which follow your party instead) are
## left out. A bill with a Stakeholders Override ("BO28+; BO29+; BO15-") uses
## that instead.
static func sides(bill: Dictionary, law_rows: Array, excluded_ids: Array = []) -> Dictionary:
	var supporters: Array[String] = []
	var opponents: Array[String] = []
	var override_text := str(bill.get("stakeholders_override") if bill.get("stakeholders_override") != null else "").strip_edges()
	if not override_text.is_empty():
		for part: String in override_text.split(";"):
			var token := part.strip_edges()
			if token.length() < 3:
				continue
			var id := token.substr(0, token.length() - 1)
			if excluded_ids.has(id):
				continue
			if token.ends_with("+"):
				supporters.append(id)
			elif token.ends_with("-"):
				opponents.append(id)
		return {"supporters": supporters, "opponents": opponents}

	var bill_id := str(bill.get("bill_id", ""))
	var net := {}
	for row: Variant in law_rows:
		if not (row is Dictionary):
			continue
		if str(row.get("bill_id", "")) != bill_id or str(row.get("outcome", "")) != "Passed":
			continue
		var effects: Variant = row.get("effects")
		if not (effects is Array):
			continue
		for entry: Variant in effects:
			if not (entry is Dictionary):
				continue
			var target := str(entry.get("target", ""))
			if not RewardTargets.is_booster(target) or excluded_ids.has(target):
				continue
			net[target] = float(net.get(target, 0.0)) + _amount(entry.get("delta"))
	var ids := net.keys()
	ids.sort()
	for id: String in ids:
		if float(net[id]) > 0.0:
			supporters.append(id)
		elif float(net[id]) < 0.0:
			opponents.append(id)
	return {"supporters": supporters, "opponents": opponents}


static func _amount(delta: Variant) -> float:
	if delta is Dictionary:
		return (float((delta as Dictionary).get("min", 0)) + float((delta as Dictionary).get("max", 0))) / 2.0
	return 0.0 if delta == null else float(delta)


static func is_lean(lean: String) -> bool:
	return lean == SUPPORT or lean == OPPOSE


## The organizations on the player's own side for this lean.
static func my_side(side_ids: Dictionary, lean: String) -> Array:
	if lean == SUPPORT:
		return (side_ids.get("supporters", []) as Array).duplicate()
	if lean == OPPOSE:
		return (side_ids.get("opponents", []) as Array).duplicate()
	return []


## The organizations against the player's lean.
static func other_side(side_ids: Dictionary, lean: String) -> Array:
	if lean == SUPPORT:
		return (side_ids.get("opponents", []) as Array).duplicate()
	if lean == OPPOSE:
		return (side_ids.get("supporters", []) as Array).duplicate()
	return []


## The rhetoric rule. Returns a copy of a stage's booster tally in which every
## answer that pleased an organization on the far side counts `percent` as much
## (rounded down). Setting back and annoying are untouched.
static func adjust_tally(tally: Dictionary, far_side_ids: Array, percent: int) -> Dictionary:
	var out := tally.duplicate(true)
	for id: Variant in far_side_ids:
		if not out.has(id):
			continue
		var row: Dictionary = out[id]
		row["pleased"] = int(floor(float(int(row.get("pleased", 0))) * float(percent) / 100.0))
		out[id] = row
	return out


## What winning one Combat stage does: the far side loses `amount`, your own
## side gains `amount`. { booster_id: delta }.
static func win_drift(side_ids: Dictionary, lean: String, amount: int) -> Dictionary:
	var out := {}
	if not is_lean(lean) or amount == 0:
		return out
	for id: Variant in other_side(side_ids, lean):
		out[id] = -amount
	for id: Variant in my_side(side_ids, lean):
		out[id] = amount
	return out


## The final vote. `choice` is "Yes", "No" or "Abstain"; `cost` is how much the
## win drift has taken from each organization this level ({ id: positive });
## `party_position` is the player's own party's Disposition toward the bill
## ("Supportive", "Opposed", "Neutral" or ""). `cfg` carries the Balance
## numbers: vote_delta, abandoned_penalty, recovery_percent, party_away,
## party_toward.
##
## Returns { "flip": bool, "backing": SUPPORT/OPPOSE/"", "deltas": {id: delta}
## (everything, recovery included), "recovery": {id: delta}, "party_delta": int }.
##
## A flip is a Yes or No that contradicts the lean (Abstain never flips). The
## side you now vote with gains the vote delta plus a recovery of at most
## recovery_percent of its cost (rounded down); the side you leave loses the
## abandoned penalty instead of the ordinary vote delta; and Party support
## moves by party_toward when your vote now matches your party's position, or
## by minus party_away when it now opposes it (nothing for a Neutral party).
static func vote(side_ids: Dictionary, lean: String, choice: String, cost: Dictionary,
		party_position: String, cfg: Dictionary) -> Dictionary:
	var result := {"flip": false, "backing": "", "deltas": {}, "recovery": {}, "party_delta": 0}
	var backing := ""
	if choice == "Yes":
		backing = SUPPORT
	elif choice == "No":
		backing = OPPOSE
	if backing.is_empty() or not is_lean(lean):
		# No stance (an old save, a level without one) or an abstention: the
		# vote itself moves nobody.
		return result

	var vote_delta := int(cfg.get("vote_delta", 0))
	var abandoned := int(cfg.get("abandoned_penalty", vote_delta))
	var recovery_percent := int(cfg.get("recovery_percent", 0))
	var flip := backing != lean
	var deltas := {}
	var recovery := {}

	for id: Variant in my_side(side_ids, backing):
		deltas[id] = int(deltas.get(id, 0)) + vote_delta
		if flip:
			var back := int(floor(float(int(cost.get(id, 0))) * float(recovery_percent) / 100.0))
			if back > 0:
				recovery[id] = back
				deltas[id] = int(deltas[id]) + back
	for id: Variant in other_side(side_ids, backing):
		deltas[id] = int(deltas.get(id, 0)) - (abandoned if flip else vote_delta)

	var party_delta := 0
	if flip:
		var party_lean := ""
		if party_position == "Supportive":
			party_lean = SUPPORT
		elif party_position == "Opposed":
			party_lean = OPPOSE
		if not party_lean.is_empty():
			party_delta = int(cfg.get("party_toward", 0)) if party_lean == backing \
				else -int(cfg.get("party_away", 0))

	result["flip"] = flip
	result["backing"] = backing
	result["deltas"] = deltas
	result["recovery"] = recovery
	result["party_delta"] = party_delta
	return result
