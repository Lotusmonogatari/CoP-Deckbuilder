class_name BillPositions
extends RefCounted
## How each party lines up on a composed bill (patron bills and Draft a Bill,
## 2026-10-19, Cameron). A bill carries "value tags" (a policy area and how far
## the bill pushes it, from -1 to +1); a party's LEAN on the bill is the sum
## of tag x the party's salience for that area (value x priority, the Party
## Values tab). A lean the size of `threshold` or more takes a side; below it
## the party is Neutral. This is the same model the twenty Batch 2 bills were
## built with (tools/workbook/archive/b2/model.py), ported so the game can run
## it for a bill that did not exist when the workbook was written.
##
## Patron rule (Cameron): no patron bill passes on its own. Yes votes above a
## cap (the votes needed minus a margin) are turned into Abstain, the weakest
## supporters first, so only the player's influence can carry the bill.
##
## Pure and UI-free (CLAUDE.md section 12). Deterministic: no rolls.


## "Taxation -1; Economic Liberalization +0.7" -> {"Taxation": -1.0,
## "Economic Liberalization": 0.7}. Entries split on ";" or ","; the number is
## the last word. A malformed entry is skipped (the exporter reports it).
static func parse_tags(text: Variant) -> Dictionary:
	var out := {}
	if text == null:
		return out
	var cleaned := str(text).replace(",", ";")
	for entry: String in cleaned.split(";", false):
		var piece := entry.strip_edges()
		var cut := piece.rfind(" ")
		if cut < 0:
			continue
		var weight_text := piece.substr(cut + 1).strip_edges()
		if not weight_text.is_valid_float():
			continue
		out[piece.substr(0, cut).strip_edges()] = weight_text.to_float()
	return out


## Adds tag dictionaries together (a bill's tags are the sum of its components').
static func merge_tags(list: Array) -> Dictionary:
	var out := {}
	for tags: Dictionary in list:
		for dimension: String in tags:
			out[dimension] = float(out.get(dimension, 0.0)) + float(tags[dimension])
	return out


## Party Values rows (party_id, dimension, salience) -> {party_id: {dimension: salience}}.
static func salience_table(rows: Array) -> Dictionary:
	var out := {}
	for row: Dictionary in rows:
		var party_id := str(row.get("party_id", ""))
		if not out.has(party_id):
			out[party_id] = {}
		(out[party_id] as Dictionary)[str(row.get("dimension", ""))] = float(row.get("salience", 0))
	return out


## The party's lean on a bill: sum of tag x salience.
static func lean(tags: Dictionary, party_salience: Dictionary) -> float:
	var total := 0.0
	for dimension: String in tags:
		total += float(tags[dimension]) * float(party_salience.get(dimension, 0.0))
	return total


## One party's seats split for a lean: {"disposition", "yes", "no", "abstain"}.
## A party that takes a side votes 66-96% that way (the stronger the lean, the
## more united); a weak side-taker abstains a little; a Neutral party splits
## roughly a third, a third and the rest. Whole seats by largest remainder.
static func split(party_lean: float, seats: int, threshold: float) -> Dictionary:
	var size := absf(party_lean)
	var yes_share := 0.0
	var no_share := 0.0
	var abstain_share := 0.0
	var disposition := "Neutral"
	if size >= threshold:
		var strength := minf(1.0, (size - threshold) / (3.0 * threshold))
		var for_side := 0.66 + 0.30 * strength
		if party_lean > 0.0:
			yes_share = for_side
			no_share = 1.0 - for_side
			disposition = "Supportive"
		else:
			yes_share = 1.0 - for_side
			no_share = for_side
			disposition = "Opposed"
		if strength < 0.25:
			abstain_share = 0.10 * (1.0 - strength / 0.25)
			yes_share -= abstain_share / 2.0
			no_share -= abstain_share / 2.0
	else:
		var t := party_lean / threshold
		yes_share = 0.31 + 0.22 * t
		no_share = 0.31 - 0.22 * t
		abstain_share = 1.0 - yes_share - no_share
	var raw := [yes_share * seats, no_share * seats, abstain_share * seats]
	var whole := [int(floor(raw[0])), int(floor(raw[1])), int(floor(raw[2]))]
	var left: int = seats - (whole[0] + whole[1] + whole[2])
	var order := [0, 1, 2]
	order.sort_custom(func(a: int, b: int) -> bool:
		var ra: float = raw[a] - whole[a]
		var rb: float = raw[b] - whole[b]
		return ra > rb if ra != rb else a < b)
	for i in range(left):
		whole[order[i]] += 1
	return {"disposition": disposition, "yes": whole[0], "no": whole[1], "abstain": whole[2]}


## Positions for every party in `parties` (parties.json rows: party_id, name,
## seats, r/g/b), in the shape FloorVoteEngine and BattleSetup read:
## party_id, party_name, party_color, votes_*, disposition, salience, cue_text.
##
## Patron shaping, both optional:
##   `yes_floor` (>= 0): a patron bill is one an organization thinks is worth
##     carrying, so its default Yes never starts below this. Seats move from
##     No, then Abstain, into Yes, the most favorable party first.
##   `yes_cap` (>= 0): default Yes never starts above this (the votes needed
##     minus a margin), so no patron bill passes without the player's
##     influence. Excess Yes becomes Abstain. With `capacity` ({party_id: the
##     seats that party's vote resistance lets the player swing}) the seats are
##     taken where they leave the most recoverable by influence, because a
##     party only gives up seats from the bucket it is mostly in; without it
##     the weakest supporters go first.
## `cues` ({party_id: line}) is optional.
static func positions(tags: Dictionary, parties: Array, salience_by_party: Dictionary,
		threshold: float, yes_cap: int = -1, cues: Dictionary = {},
		yes_floor: int = -1, capacity: Dictionary = {}) -> Array:
	var out: Array = []
	var leans := {}
	for party: Dictionary in parties:
		var party_id := str(party.get("party_id", ""))
		var party_lean := lean(tags, salience_by_party.get(party_id, {}) as Dictionary)
		leans[party_id] = party_lean
		var seats := split(party_lean, int(party.get("seats", 0)), threshold)
		out.append({
			"party_id": party_id,
			"party_name": str(party.get("name", "")),
			"party_color": [party.get("r", 128), party.get("g", 128), party.get("b", 128)],
			"votes_yes": seats["yes"],
			"votes_no": seats["no"],
			"votes_abstain": seats["abstain"],
			"disposition": seats["disposition"],
			"salience": int(roundf(absf(party_lean))),
			"cue_text": str(cues.get(party_id, "")),
		})
	if yes_floor >= 0:
		raise_yes(out, leans, yes_floor)
	if yes_cap >= 0:
		if capacity.is_empty():
			cap_yes(out, leans, yes_cap)
		else:
			cap_yes_recoverably(out, capacity, yes_cap)
	return out


## Lifts Yes to `yes_floor`: No seats first, then Abstain, from the party with
## the highest lean down. Changes `positions_list` in place.
static func raise_yes(positions_list: Array, leans: Dictionary, yes_floor: int) -> void:
	var need := yes_floor - total_yes(positions_list)
	if need <= 0:
		return
	var order := positions_list.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(leans.get(str(a.get("party_id", "")), 0.0)) > float(leans.get(str(b.get("party_id", "")), 0.0)))
	for position: Dictionary in order:
		for key: String in ["votes_no", "votes_abstain"]:
			if need <= 0:
				return
			var moved := mini(need, int(position[key]))
			position[key] = int(position[key]) - moved
			position["votes_yes"] = int(position["votes_yes"]) + moved
			need -= moved


## Moves Yes votes above `yes_cap` into Abstain, taking from the party with the
## lowest lean first (the weakest supporters). Changes `positions_list` in place.
static func cap_yes(positions_list: Array, leans: Dictionary, yes_cap: int) -> void:
	var over := total_yes(positions_list) - yes_cap
	if over <= 0:
		return
	var order := positions_list.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var la: float = leans.get(str(a.get("party_id", "")), 0.0)
		var lb: float = leans.get(str(b.get("party_id", "")), 0.0)
		return la < lb)
	for position: Dictionary in order:
		if over <= 0:
			break
		var moved := mini(over, int(position["votes_yes"]))
		position["votes_yes"] = int(position["votes_yes"]) - moved
		position["votes_abstain"] = int(position["votes_abstain"]) + moved
		over -= moved


## The cap again, but choosing which parties give up Yes seats so that the most
## can be won back. A party only gives up seats from the bucket it is mostly
## in, up to `capacity` of them, so turning a Yes-majority party into an
## Abstain-majority one makes its seats recoverable, while taking a few seats
## from a party that stays Yes-majority loses them for good. Dynamic
## programming over the parties: for every total removed (at least what the cap
## needs), the best sum of (recoverable seats - seats removed); ties keep more
## Yes. Changes `positions_list` in place.
static func cap_yes_recoverably(positions_list: Array, capacity: Dictionary, yes_cap: int) -> void:
	var yes_now := total_yes(positions_list)
	if yes_now <= yes_cap:
		return
	# best[t] = {"score": int, "removed": Array of per-party removals}
	var best := {0: {"score": 0, "removed": []}}
	for position: Dictionary in positions_list:
		var party_capacity := int(capacity.get(str(position.get("party_id", "")), 0))
		var yes := int(position["votes_yes"])
		var no := int(position["votes_no"])
		var abstain := int(position["votes_abstain"])
		var next := {}
		for total: int in best:
			var entry: Dictionary = best[total]
			for removed in range(0, yes + 1):
				var buckets := {"Yes": yes - removed, "No": no, "Abstain": abstain + removed}
				var majority := FloorVoteEngine.majority_bucket({
					"votes_yes": buckets["Yes"], "votes_no": buckets["No"], "votes_abstain": buckets["Abstain"]})
				var recoverable := 0
				if majority != "Yes":
					recoverable = mini(party_capacity, int(buckets[majority]))
				var score: int = int(entry["score"]) - removed + recoverable
				var key: int = total + removed
				if not next.has(key) or score > int((next[key] as Dictionary)["score"]):
					next[key] = {"score": score, "removed": (entry["removed"] as Array) + [removed]}
		best = next
	var chosen_total := -1
	for total: int in best:
		if yes_now - total > yes_cap:
			continue
		if chosen_total < 0:
			chosen_total = total
			continue
		var score: int = int((best[total] as Dictionary)["score"])
		var chosen_score: int = int((best[chosen_total] as Dictionary)["score"])
		if score > chosen_score or (score == chosen_score and total < chosen_total):
			chosen_total = total
	if chosen_total < 0:
		return
	var plan: Array = (best[chosen_total] as Dictionary)["removed"]
	for i in range(positions_list.size()):
		var position: Dictionary = positions_list[i]
		position["votes_yes"] = int(position["votes_yes"]) - int(plan[i])
		position["votes_abstain"] = int(position["votes_abstain"]) + int(plan[i])


static func total_yes(positions_list: Array) -> int:
	var total := 0
	for position: Dictionary in positions_list:
		total += int(position.get("votes_yes", 0))
	return total
