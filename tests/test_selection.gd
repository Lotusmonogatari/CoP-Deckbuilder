extends GutTest
## The Candidate Selection Committee (P20, 2026-11-26): the score's weights, the influence part and the thresholds.

func test_the_thresholds_are_exact() -> void:
	assert_eq(Selection.outcome(39), "not_selected")
	assert_eq(Selection.outcome(40), "list")
	assert_eq(Selection.outcome(59), "list")
	assert_eq(Selection.outcome(60), "smd")
	assert_eq(Selection.outcome(74), "smd")
	assert_eq(Selection.outcome(75), "smd_safety_net")
	assert_eq(Selection.outcome(100), "smd_safety_net")
	assert_eq(Selection.outcome(0), "not_selected")


func test_influence_is_the_average_of_party_support_and_the_committees_standing() -> void:
	assert_eq(Selection.influence(60, 40), 50.0)
	assert_eq(Selection.influence(75, 76), 75.5)


func test_the_score_weights_strength_half_and_the_other_two_a_quarter_each() -> void:
	assert_eq(Selection.score(100.0, 100.0, 100.0), 100)
	assert_eq(Selection.score(0.0, 0.0, 0.0), 0)
	assert_eq(Selection.score(100.0, 0.0, 0.0), 50)
	assert_eq(Selection.score(0.0, 100.0, 0.0), 25)
	assert_eq(Selection.score(0.0, 0.0, 100.0), 25)
	assert_eq(Selection.score(80.0, 40.0, 50.0), 63, "40 + 10 + 12.5 = 62.5 rounds up")


func test_the_whole_decision_reports_its_three_parts() -> void:
	var decision := Selection.decide(80.0, 40.0, 60, 40)
	assert_eq(decision["strength"], 80.0)
	assert_eq(decision["alignment"], 40.0)
	assert_eq(decision["influence"], 50.0)
	assert_eq(decision["score"], 63)
	assert_eq(decision["outcome"], "smd")


func test_a_weak_campaign_is_not_selected() -> void:
	assert_eq(Selection.decide(10.0, 50.0, 40, 30)["outcome"], "not_selected", "5 + 12.5 + 8.75 = 26")
	assert_false(Selection.is_selected("not_selected"))
	assert_true(Selection.is_selected("list"))
	assert_true(Selection.is_selected("smd_safety_net"))
