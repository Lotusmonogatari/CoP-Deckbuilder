extends GutTest
## Party alignment (P20, 2026-11-26): 50 with no votes, 100 when the player always sides with their party, 0 when never, neutral bills skipped,
## stronger positions weighing more, and only an Aye or a Nay counting.

const PARTY := "PT01"


func _bill(disposition: String, salience: int) -> Dictionary:
	return {"positions": [{"party_id": "PT09", "disposition": "Opposed", "salience": 99}, {"party_id": PARTY, "disposition": disposition, "salience": salience}]}


func _vote(bill_id: String, choice: String) -> Dictionary:
	return {"bill_id": bill_id, "passed": true, "player_vote": choice, "absent": false}


func test_no_bills_is_fifty() -> void:
	assert_eq(PartyAlignment.score([], {}, PARTY), 50)


func test_always_with_the_party_is_one_hundred() -> void:
	var bills := {"B1": _bill("Supportive", 10), "B2": _bill("Opposed", 10)}
	assert_eq(PartyAlignment.score([_vote("B1", "Yes"), _vote("B2", "No")], bills, PARTY), 100)


func test_always_against_the_party_is_zero() -> void:
	var bills := {"B1": _bill("Supportive", 10), "B2": _bill("Opposed", 10)}
	assert_eq(PartyAlignment.score([_vote("B1", "No"), _vote("B2", "Yes")], bills, PARTY), 0)


func test_a_neutral_party_says_nothing_and_the_bill_is_skipped() -> void:
	var bills := {"B1": _bill("Neutral", 50), "B2": _bill("Supportive", 10)}
	assert_eq(PartyAlignment.score([_vote("B1", "No"), _vote("B2", "Yes")], bills, PARTY), 100, "only B2 counts")
	assert_eq(PartyAlignment.score([_vote("B1", "No")], bills, PARTY), 50, "only neutral bills: no evidence")


func test_a_stronger_position_weighs_more() -> void:
	var bills := {"B1": _bill("Supportive", 30), "B2": _bill("Supportive", 10)}
	# agreed 30, disagreed 10: 50 + 50 x 20 / 40 = 75
	assert_eq(PartyAlignment.score([_vote("B1", "Yes"), _vote("B2", "No")], bills, PARTY), 75)
	assert_eq(PartyAlignment.score([_vote("B1", "No"), _vote("B2", "Yes")], bills, PARTY), 25)


func test_an_absence_or_an_abstention_does_not_count() -> void:
	var bills := {"B1": _bill("Supportive", 10), "B2": _bill("Supportive", 10), "B3": _bill("Supportive", 10)}
	var absent := _vote("B2", "Yes")
	absent["absent"] = true
	assert_eq(PartyAlignment.score([_vote("B1", "Yes"), absent, _vote("B3", "Abstain")], bills, PARTY), 100, "only the Aye on B1")


func test_a_bill_with_no_position_for_the_party_is_skipped_and_the_result_rounds() -> void:
	var bills := {"B1": _bill("Supportive", 10), "B2": {"positions": [{"party_id": "PT09", "disposition": "Supportive", "salience": 5}]}}
	assert_eq(PartyAlignment.score([_vote("B1", "Yes"), _vote("B2", "No")], bills, PARTY), 100)
	var thirds := {"B1": _bill("Supportive", 1), "B2": _bill("Supportive", 1), "B3": _bill("Supportive", 1)}
	# agreed 2, disagreed 1: 50 + 50 / 3 = 66.67 -> 67
	assert_eq(PartyAlignment.score([_vote("B1", "Yes"), _vote("B2", "Yes"), _vote("B3", "No")], thirds, PARTY), 67)


func test_the_real_floor_votes_carry_positions_to_read() -> void:
	var bill: Dictionary = DataDB.floor_votes["BI01"]
	assert_gt((bill["positions"] as Array).size(), 0)
	assert_true((bill["positions"][0] as Dictionary).has("disposition"))
