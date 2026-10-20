class_name RequestLines
extends RefCounted
## What the Request panel says about a patron bill (patron step 4, 2026-10-19):
## the bill's parts, the default vote, where the player's own party stands and
## what passing or declining would do. Reads the composed bill and the Balance
## levers it is given; the words come from the Text tab.

const STANCE_KEYS := {
	"Supportive": "request.stance_supportive",
	"Opposed": "request.stance_opposed",
	"Neutral": "request.stance_neutral",
}


## The vote if nobody is swayed: "46 Aye, 30 Nay, 25 abstaining; 51 Aye needed."
static func default_vote_line(bill: Dictionary) -> String:
	var totals := {"Yes": 0, "No": 0, "Abstain": 0}
	for position: Dictionary in (bill.get("positions", []) as Array):
		totals["Yes"] += int(position.get("votes_yes", 0))
		totals["No"] += int(position.get("votes_no", 0))
		totals["Abstain"] += int(position.get("votes_abstain", 0))
	return Text.say("request.default_vote", {"yes": totals["Yes"], "no": totals["No"],
		"abstain": totals["Abstain"], "needed": FloorVoteEngine.yes_needed(totals,
			FloorVoteEngine.requirement_of(bill), int(DataDB.balance.get("supermajority_percent", 67)))})


## Where the player's own party stands on the bill ("" if it has no position).
static func own_party_line(bill: Dictionary, party_name: String) -> String:
	var own_id := str(DataDB.get_party(party_name).get("party_id", ""))
	for position: Dictionary in (bill.get("positions", []) as Array):
		if str(position.get("party_id", "")) == own_id:
			var key: String = STANCE_KEYS.get(str(position.get("disposition", "Neutral")), "request.stance_neutral")
			return Text.say(key, {"party": party_name})
	return ""


## What passing would do for the patron and the ally: one entry each
## ({ "id", "delta" }), drawn as organization chips.
static func reward_entries(row: Dictionary, ally: String, amended: bool) -> Array:
	var entries: Array = []
	var result := PatronRequests.outcome(row, ally, [], true, amended, DataDB.balance)
	for entry: Dictionary in (result["standing"] as Array):
		var delta := int(entry["delta"])
		if delta > 0:
			entries.append({"id": str(entry["target"]), "delta": delta})
	return entries


## Who thinks more or less of you after a sponsored bill's vote, as chip
## entries; empty for any other vote.
static func outcome_entries(outcome: Dictionary) -> Array:
	var entries: Array = []
	for entry: Dictionary in (outcome.get("standing", []) as Array):
		var delta := int(entry.get("delta", 0))
		if delta != 0:
			entries.append({"id": str(entry["target"]), "delta": delta})
	return entries


## What a sponsored bill's vote did: who thinks more or less of you, what is
## now law, and any backing granted. One line each; empty for any other vote.
static func outcome_lines(outcome: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if outcome.is_empty():
		return lines
	lines.append(Text.say("request.outcome_heading"))
	var backing_org := str(outcome.get("backing_org", ""))
	if not backing_org.is_empty():
		lines.append(Text.say("request.outcome_backing", {
			"org": str(DataDB.get_booster(backing_org).get("name_en", backing_org))}))
	if bool(outcome.get("passed", false)):
		var parts: Array[String] = []
		for component_id: Variant in (outcome.get("components", []) as Array):
			var phrase := str(ComposedBill.index(DataDB.bill_components).get(component_id, {}).get("phrase", ""))
			if not phrase.is_empty():
				parts.append(phrase)
		if not parts.is_empty():
			lines.append(Text.say("request.outcome_law", {"parts": "; ".join(parts)}))
	return lines
