extends GutTest
## BriefingSummary: the level briefing's rewards, totals and order.

func _stage(name: String, rep: int, jiban: int, yen: int, party: int, xp: int) -> Dictionary:
	return {"name_en": name, "win_delta_reputation": rep, "win_delta_jiban": jiban,
		"win_delta_yen": yen, "win_delta_party_support": party, "win_delta_xp": xp}


func test_rewards_are_listed_reputation_first_then_xp_then_funds() -> void:
	var rewards := BriefingSummary.stage_rewards(_stage("A", 1, 2, 30000, 3, 60))
	assert_eq(BriefingSummary.ordered(rewards),
		["Reputation", "Constituency support", "Party support", "XP", "Funds"] as Array[String])


func test_a_zero_reward_is_left_out() -> void:
	var rewards := BriefingSummary.stage_rewards(_stage("A", 0, 2, 0, 0, 10))
	assert_eq(BriefingSummary.ordered(rewards), ["Constituency support", "XP"] as Array[String])


func test_totals_add_every_stage_together() -> void:
	var total := BriefingSummary.total_rewards([_stage("A", 1, 2, 30000, 0, 60), _stage("B", 2, -2, 40000, 1, 55)])
	assert_eq(int(total["Reputation"]), 3)
	assert_false(total.has("Constituency support"), "+2 and -2 cancel out")
	assert_eq(int(total["Funds"]), 70000)
	assert_eq(int(total[BriefingSummary.XP]), 115)


func test_a_one_stage_level_named_like_its_stage_shows_only_the_stage() -> void:
	assert_true(BriefingSummary.is_just_its_stage("School Visit", [{"name_en": "School Visit"}]))
	assert_false(BriefingSummary.is_just_its_stage("A Day Out", [{"name_en": "School Visit"}]))
	assert_false(BriefingSummary.is_just_its_stage("School Visit",
		[{"name_en": "School Visit"}, {"name_en": "Town Hall"}]))
