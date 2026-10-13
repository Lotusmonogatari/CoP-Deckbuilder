extends GutTest
## Party salience (2026-10-14): a party's opinion moves more on a bill that
## sits on its own priorities.


func test_blank_salience_changes_nothing() -> void:
	assert_eq(PartySalience.factor(null, 50.0, 0.5, 2.0), 1.0)
	assert_eq(PartySalience.scaled(3, 1.0), 3)


func test_factor_is_linear_and_clamped() -> void:
	assert_eq(PartySalience.factor(50, 50.0, 0.5, 2.0), 1.0)
	assert_eq(PartySalience.factor(100, 50.0, 0.5, 2.0), 2.0)
	assert_eq(PartySalience.factor(500, 50.0, 0.5, 2.0), 2.0, "capped")
	assert_eq(PartySalience.factor(5, 50.0, 0.5, 2.0), 0.5, "floored")
	assert_eq(PartySalience.factor(-75, 50.0, 0.5, 2.0), 1.5, "sign does not matter")


func test_a_small_move_never_rounds_to_nothing() -> void:
	assert_eq(PartySalience.scaled(1, 0.5), 1)
	assert_eq(PartySalience.scaled(-1, 0.5), -1)
	assert_eq(PartySalience.scaled(0, 2.0), 0)
	assert_eq(PartySalience.scaled(3, 1.5), 5)
	assert_eq(PartySalience.scaled(-3, 0.5), -2)


func test_floor_vote_deltas_scale_with_each_partys_salience() -> void:
	var engine := FloorVoteEngine.new()
	var bill := {"bill_id": "BX", "favorability_delta_supportive": 2, "favorability_delta_opposed": -2,
		"favorability_delta_neutral": 0,
		"positions": [
			{"party_id": "PT01", "party_name": "A", "votes_yes": 10, "votes_no": 0, "votes_abstain": 0,
				"disposition": "Supportive", "favorability_factor": 2.0},
			{"party_id": "PT02", "party_name": "B", "votes_yes": 0, "votes_no": 10, "votes_abstain": 0,
				"disposition": "Opposed", "favorability_factor": 0.5},
		]}
	assert_true(engine.setup({"bill": bill, "player_party": ""}))
	var result := engine.choose("Yes")
	var deltas: Dictionary = result["favorability_deltas"]
	assert_eq(deltas["A"], 4, "high salience doubles the gain")
	assert_eq(deltas["B"], -1, "low salience halves the loss")


func test_real_bills_carry_a_salience_for_every_party() -> void:
	for bill_id: String in DataDB.floor_votes:
		for position: Dictionary in DataDB.floor_votes[bill_id]["positions"]:
			assert_not_null(position.get("salience"), "%s %s has a Salience" % [bill_id, position["party_id"]])
