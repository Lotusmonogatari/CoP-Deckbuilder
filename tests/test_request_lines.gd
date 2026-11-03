extends GutTest
## RequestLines readiness (component plan 4.1, 2026-11-03): the Request and
## Draft panels say what influence is still missing before the vote.

const TRIGGERS := [
	{"variable": "Reputation", "enabled": "Yes", "threshold": 60},
	{"variable": "BO02", "enabled": "Yes", "threshold": 75},
	{"variable": "Funds", "enabled": "Yes", "threshold": 500000, "applies_to_parties": ["PT04"]},
]


func _bill(positions: Array) -> Dictionary:
	return {"positions": positions}


func test_parties_outside_yes_skips_unanimous_parties() -> void:
	var bill := _bill([
		{"party_id": "PT01", "votes_yes": 10, "votes_no": 0, "votes_abstain": 0},
		{"party_id": "PT04", "votes_yes": 1, "votes_no": 5, "votes_abstain": 0},
	])
	assert_eq(RequestLines.parties_outside_yes(bill), ["PT04"])


func test_readiness_line_lists_missing_rows() -> void:
	var bill := _bill([{"party_id": "PT02", "votes_yes": 1, "votes_no": 9, "votes_abstain": 0}])
	var line := RequestLines.readiness_line(bill, TRIGGERS, {"Reputation": 40}, {"BO02": 62}, 85)
	assert_string_contains(line, "40 of 60")
	assert_string_contains(line, "62 of 75")


func test_readiness_line_ready_when_gate_passes() -> void:
	var bill := _bill([{"party_id": "PT02", "votes_yes": 1, "votes_no": 9, "votes_abstain": 0}])
	var line := RequestLines.readiness_line(bill, TRIGGERS, {"Reputation": 70}, {"BO02": 80}, 85)
	assert_eq(line, Text.say("floor_vote.influence_ready"))


func test_readiness_only_counts_parties_outside_yes() -> void:
	# PT04 is all Yes, so its Funds gate is not listed as missing.
	var bill := _bill([
		{"party_id": "PT04", "votes_yes": 6, "votes_no": 0, "votes_abstain": 0},
		{"party_id": "PT02", "votes_yes": 1, "votes_no": 9, "votes_abstain": 0},
	])
	var line := RequestLines.readiness_line(bill, TRIGGERS, {"Reputation": 40, "Funds": 0}, {"BO02": 62}, 85)
	assert_false(line.contains("500,000"), line)


func test_variable_name_uses_organization_name() -> void:
	assert_eq(RequestLines.variable_name("Reputation"), "Reputation")
	assert_eq(RequestLines.variable_name("BO02"), str(DataDB.get_booster("BO02").get("name_en")))
