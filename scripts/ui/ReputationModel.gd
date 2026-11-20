class_name ReputationModel
extends RefCounted
## What the Overview tab of Reputation and Results shows (P13, 2026-11-20), as plain data: the four meta numbers with
## what moved them last level, the organizations that moved most, the parties' opinion of the player, the latest law,
## and the levels cleared. It reads the same sources the old Your Record page read (GameState, DataDB), says nothing it
## did not, and ReputationView only draws it.
##
## `helpers` carries the Office's own wording functions: "vote_word" (a Callable, "Yes" to "Aye"), "pressure_name".


## The Overview as a dictionary: tiles, footer, moves, parties, law, levels.
static func overview(helpers: Dictionary) -> Dictionary:
	return {
		"tiles": tiles(),
		"footer": {"xp": Text.say("office.xp", {"count": GameState.xp}),
			"pressure": Text.say("record.pressure_line", {"name": str(helpers.get("pressure_name", ""))})},
		"moves": moves(),
		"parties": parties(),
		"law": latest_law(helpers),
		"tiers": tier_lines(),
		"levels": level_lines(),
	}


## The four meta numbers, as the old Your Record page showed them: Party support is the LIVE number the rules read.
static func tiles() -> Array:
	var out: Array = []
	for variable: Dictionary in DataDB.sanban:
		var name := str(variable.get("name_en", ""))
		var is_party := name == "Party support"
		var shown: Variant = GameState.party_support_effective() if is_party else GameState.meta.get(name, 0)
		var change := GameState.party_support_change_this_level() if is_party else int(GameState.last_meta_change.get(name, 0))
		out.append({"name": name, "value": Phrase.meta_amount(name, int(shown)), "change": change,
			"change_text": Phrase.meta_amount(name, change, true) if change != 0 else "",
			"node": "MetaChange_" + name.replace(" ", "_")})
	return out


## The three organizations whose standing moved most last level.
static func moves() -> Array:
	var order: Array = []
	for booster: Dictionary in DataDB.boosters:
		order.append(str(booster.get("booster_id", "")))
	var out: Array = []
	for id: String in ReputationOverview.biggest_moves(GameState.last_booster_change, order, 3):
		var booster := DataDB.get_booster(id)
		var change := int(GameState.last_booster_change.get(id, 0))
		out.append({"id": id, "booster": booster, "name": str(booster.get("name_en", id)),
			"standing": int(GameState.booster_standing.get(id, 50)), "change": change, "change_text": "%+d" % change,
			"node": "StandingChange_" + id})
	return out


## Each party with the opinion score it holds of the player, in its own colour; the player's own party is marked.
static func parties() -> Array:
	var out: Array = []
	var own := GameState.own_party_id()
	for party: Dictionary in DataDB.parties:
		var id := str(party.get("party_id", ""))
		out.append({"id": id, "name": str(party.get("name", id)), "colour": PartyDisplay.color_for(party),
			"score": int(GameState.party_opinion_detail(id)["opinion"]), "own": id == own})
	return out


## The latest law, or {} when no bill has come to a vote: its name, whether it passed, the tally and how the player voted.
static func latest_law(helpers: Dictionary) -> Dictionary:
	var law := ReputationOverview.latest_law(GameState.statute_book)
	if law.is_empty():
		return {}
	var id := str(law.get("bill_id", ""))
	var vote_word: Callable = helpers["vote_word"]
	var absent := bool(law.get("absent", false))
	return {"law": law, "node": "Law_" + id, "passed": bool(law.get("passed", false)), "absent": absent,
		"name": str(DataDB.floor_votes.get(id, {}).get("bill_name", id)),
		"tally": "" if absent else Text.say("record.law_tally", {"yes": int(law.get("yes", 0)),
			"no": int(law.get("no", 0)), "abstain": int(law.get("abstain", 0))}),
		"vote": "" if absent else Text.say("record.law_voted", {"vote": vote_word.call(str(law.get("player_vote", "")))})}


## Clears per tier: "Tier 1: 4 clears", derived from the level tally as the old page did.
static func tier_lines() -> Array[String]:
	var out: Array[String] = []
	var tiers: Array = []
	for level: Dictionary in DataDB.levels:
		if not tiers.has(level.get("tier")):
			tiers.append(level.get("tier"))
	tiers.sort()
	for tier: Variant in tiers:
		var total := 0
		for level: Dictionary in DataDB.levels:
			if level.get("tier") == tier:
				total += int(GameState.levels_cleared.get(str(level.get("level_id", "")), 0))
		out.append(Text.say("office.record_tier_line", {"tier": int(tier), "count": total}))
	return out


## Each level cleared at least once, with how many times; the empty line when none.
static func level_lines() -> Array[String]:
	var out: Array[String] = []
	for level: Dictionary in DataDB.levels:
		var level_id := str(level.get("level_id", ""))
		var count := int(GameState.levels_cleared.get(level_id, 0))
		if count > 0:
			out.append(Text.say("office.record_level_line", {"level": level.get("description", level_id), "count": count}))
	if out.is_empty():
		out.append(Text.say("office.record_levels_empty"))
	return out
