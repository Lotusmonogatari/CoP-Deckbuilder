extends GutTest
## BillStance: stakeholders, the rhetoric rule, win drift and the vote.

const CFG := {"vote_delta": 2, "abandoned_penalty": 5, "recovery_percent": 25,
	"party_away": 3, "party_toward": 1}

var _sides := {"supporters": ["BO28", "BO29"], "opponents": ["BO05", "BO15"]}


func _law_rows() -> Array:
	return [
		{"bill_id": "BI01", "outcome": "Passed", "timing": "Once", "effects": [
			{"target": "BO28", "delta": 3}, {"target": "BO29", "delta": 2},
			{"target": "BO05", "delta": -2}, {"target": "BO15", "delta": -2},
			{"target": "BO01", "delta": 2}]},
		{"bill_id": "BI01", "outcome": "Failed", "timing": "Once", "effects": [
			{"target": "BO28", "delta": -1}]},
		{"bill_id": "BI02", "outcome": "Passed", "timing": "Once", "effects": [
			{"target": "BO10", "delta": 3}]},
	]


func test_sides_come_from_the_passed_row_and_leave_out_party_bodies() -> void:
	var found := BillStance.sides({"bill_id": "BI01"}, _law_rows(), ["BO01", "BO02"])
	assert_eq(found["supporters"], ["BO28", "BO29"])
	assert_eq(found["opponents"], ["BO05", "BO15"])


func test_a_stakeholders_override_replaces_the_derived_list() -> void:
	var found := BillStance.sides({"bill_id": "BI01", "stakeholders_override": "BO28+; BO15-; BO09+"},
		_law_rows(), [])
	assert_eq(found["supporters"], ["BO28", "BO09"])
	assert_eq(found["opponents"], ["BO15"])


func test_a_bill_with_no_rows_has_no_sides() -> void:
	var found := BillStance.sides({"bill_id": "BI99"}, _law_rows(), [])
	assert_eq(found["supporters"], [])
	assert_eq(found["opponents"], [])


func test_my_side_and_the_far_side_follow_the_lean() -> void:
	assert_eq(BillStance.my_side(_sides, "Oppose"), ["BO05", "BO15"])
	assert_eq(BillStance.other_side(_sides, "Oppose"), ["BO28", "BO29"])
	assert_eq(BillStance.my_side(_sides, "Support"), ["BO28", "BO29"])
	assert_eq(BillStance.my_side(_sides, ""), [])


func test_far_side_pleasing_counts_half_rounded_down() -> void:
	var tally := {"BO28": {"pleased": 3, "displeased": 1, "opposed": 0},
		"BO05": {"pleased": 3, "displeased": 0, "opposed": 0}}
	var out := BillStance.adjust_tally(tally, ["BO28"], 50)
	assert_eq(out["BO28"]["pleased"], 1, "3 answers count as 1")
	assert_eq(out["BO28"]["displeased"], 1, "annoying is untouched")
	assert_eq(out["BO05"]["pleased"], 3, "the near side is untouched")
	assert_eq(tally["BO28"]["pleased"], 3, "the original tally is not changed")


func test_a_single_far_side_answer_counts_for_nothing() -> void:
	var out := BillStance.adjust_tally({"BO28": {"pleased": 1, "displeased": 0, "opposed": 0}}, ["BO28"], 50)
	assert_eq(out["BO28"]["pleased"], 0)


func test_win_drift_moves_both_sides() -> void:
	var drift := BillStance.win_drift(_sides, "Oppose", 2)
	assert_eq(drift["BO28"], -2)
	assert_eq(drift["BO05"], 2)
	assert_eq(BillStance.win_drift(_sides, "", 2), {})


func test_a_vote_that_matches_the_lean_moves_each_side_by_the_vote_delta() -> void:
	var out := BillStance.vote(_sides, "Oppose", "No", {"BO28": 6}, "Opposed", CFG)
	assert_false(out["flip"])
	assert_eq(out["deltas"]["BO05"], 2)
	assert_eq(out["deltas"]["BO28"], -2)
	assert_eq(out["party_delta"], 0, "no flip, so no flip cost")
	assert_eq(out["recovery"], {})


func test_abstaining_moves_nobody() -> void:
	var out := BillStance.vote(_sides, "Oppose", "Abstain", {"BO28": 6}, "Opposed", CFG)
	assert_false(out["flip"])
	assert_eq(out["deltas"], {})


func test_switching_costs_the_abandoned_side_five_and_recovers_a_quarter() -> void:
	# Cameron's example: three wins cost the Ainu groups 6 each.
	var out := BillStance.vote(_sides, "Oppose", "Yes", {"BO28": 6, "BO29": 6}, "Opposed", CFG)
	assert_true(out["flip"])
	assert_eq(out["deltas"]["BO28"], 3, "+2 for the vote, +1 recovered (25% of 6, rounded down)")
	assert_eq(out["recovery"]["BO28"], 1)
	assert_eq(out["deltas"]["BO05"], -5, "the side you leave loses 5, not 2")
	assert_eq(out["deltas"]["BO15"], -5)


func test_recovery_never_reaches_a_quarter_of_nothing() -> void:
	var out := BillStance.vote(_sides, "Oppose", "Yes", {"BO28": 3}, "Opposed", CFG)
	assert_eq(out["deltas"]["BO28"], 2, "25% of 3 rounds down to 0")


func test_switching_against_your_party_costs_three_party_support() -> void:
	# Leaned with a Supportive party, then voted No.
	var out := BillStance.vote(_sides, "Support", "No", {}, "Supportive", CFG)
	assert_true(out["flip"])
	assert_eq(out["party_delta"], -3)


func test_switching_toward_your_party_earns_one() -> void:
	# Country Initiative (Opposed) leaned Support, then voted No: back with the party.
	var out := BillStance.vote(_sides, "Support", "No", {}, "Opposed", CFG)
	assert_eq(out["party_delta"], 1)


func test_a_neutral_party_has_no_position_to_switch_to_or_from() -> void:
	var out := BillStance.vote(_sides, "Support", "No", {}, "Neutral", CFG)
	assert_true(out["flip"])
	assert_eq(out["party_delta"], 0)


func test_no_stance_means_the_vote_moves_nobody() -> void:
	var out := BillStance.vote(_sides, "", "Yes", {}, "Supportive", CFG)
	assert_false(out["flip"])
	assert_eq(out["deltas"], {})


func test_a_bill_with_no_stakeholders_still_prices_a_flip_on_party_support() -> void:
	var out := BillStance.vote({"supporters": [], "opponents": []}, "Support", "No", {}, "Supportive", CFG)
	assert_true(out["flip"])
	assert_eq(out["deltas"], {})
	assert_eq(out["party_delta"], -3)
