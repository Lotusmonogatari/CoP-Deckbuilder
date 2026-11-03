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
			FloorVoteEngine.requirement_of(bill), int(DataDB.balance.get("supermajority_percent_of_house", 67)))})


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


## The party ids holding any seats outside Yes: the parties a sway would have
## to move, so the only ones whose influence gates matter for this bill.
static func parties_outside_yes(bill: Dictionary) -> Array:
	var out: Array = []
	for position: Dictionary in (bill.get("positions", []) as Array):
		if int(position.get("votes_no", 0)) + int(position.get("votes_abstain", 0)) > 0:
			out.append(str(position.get("party_id", "")))
	return out


## "Your influence is not yet strong enough ... Still needed: Party Faction 62
## of 75, Funds 100,000 of 500,000." from a VoteInfluence.status() result.
## Shared by the Floor Vote screen and the Request and Draft panels (2026-11-03).
static func readiness_text(status: Dictionary) -> String:
	if bool(status.get("ready", false)):
		return Text.say("floor_vote.influence_ready")
	var needs: Array[String] = []
	var gaps: Array = status.get("missing", [])
	for gap: Dictionary in gaps.slice(0, 3):
		needs.append(Text.say("floor_vote.influence_need", {
			"name": variable_name(str(gap.get("variable", ""))),
			"have": Phrase.with_separators(int(gap.get("value", 0))),
			"needed": Phrase.with_separators(int(gap.get("threshold", 0)))}))
	if gaps.size() > 3:
		needs.append(Text.say("floor_vote.influence_more", {"more": gaps.size() - 3}))
	return Text.say("floor_vote.influence_not_ready", {"needs": ", ".join(needs)})


## Readiness for a bill before its vote: the influence gates of the parties a
## sway would need, checked against the player's standing now.
static func readiness_line(bill: Dictionary, triggers: Array, meta: Dictionary,
		standing: Dictionary, default_threshold: int) -> String:
	return readiness_text(VoteInfluence.status(triggers, meta, standing,
		default_threshold, parties_outside_yes(bill)))


## A gate variable's display name: an organization id becomes its name; a
## meta variable such as Reputation names itself.
static func variable_name(variable: String) -> String:
	if not variable.begins_with("BO"):
		return variable
	var booster := DataDB.get_booster(variable)
	return str(booster.get("name_en", variable)) if not booster.is_empty() else variable
