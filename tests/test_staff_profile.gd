extends GutTest
## StaffProfile: the tier-by-tier content of the Staff Profile screen, on the
## real staff data (named candidates picked for the shapes they show).


func _tiers(staff_id: String) -> Array[Dictionary]:
	return StaffProfile.tiers(DataDB.get_staff(staff_id), DataDB.boosters, DataDB.segments, Text.phrase())


func test_someone_with_no_upgrades_has_exactly_one_tier() -> void:
	var tiers := _tiers("SF01")
	assert_eq(tiers.size(), 1)
	assert_eq(tiers[0]["tier"], 0)
	assert_true(tiers[0]["on_hire"])
	assert_null(tiers[0]["cost"], "the arrival tier is not bought")


func test_a_three_tier_candidate_lists_every_tier_with_its_upgrade_cost() -> void:
	var tiers := _tiers("SF04")
	assert_eq(tiers.size(), 3)
	assert_null(tiers[0]["cost"])
	assert_eq(tiers[1]["cost"], DataDB.get_staff("SF04")["upgrade_cost_0_to_1_yen"])
	assert_eq(tiers[2]["cost"], DataDB.get_staff("SF04")["upgrade_cost_1_to_2_yen"])
	assert_gt((tiers[2]["lines"] as Array).size(), (tiers[0]["lines"] as Array).size(),
		"a higher tier carries more bonuses")


func test_someone_who_starts_at_tier_one_has_no_tier_zero() -> void:
	var tiers := _tiers("SF07")
	assert_eq(tiers[0]["tier"], 1)
	assert_true(tiers[0]["on_hire"])
	assert_eq(tiers.size(), 2)
	assert_eq(tiers[1]["cost"], DataDB.get_staff("SF07")["upgrade_cost_1_to_2_yen"])


func test_a_bonus_line_names_the_organisation_and_the_audience_in_words() -> void:
	# SF02 tier 0 gives +2 with BO05; tier 1 adds an SG01 audience bonus.
	var first := _tiers("SF02")[0]["lines"] as Array
	assert_eq(first.size(), 1)
	assert_string_contains(first[0], "+2")
	assert_string_contains(first[0], str(DataDB.get_booster("BO05").get("name_en")))
	assert_false((first[0] as String).contains("BO05"), "no raw ID reaches the player")

	var second := _tiers("SF02")[1]["lines"] as Array
	var joined := " ".join(second)
	assert_string_contains(joined, str(DataDB.get_segment("SG01").get("name_en")))


func test_a_tier_with_no_reward_says_so_rather_than_showing_nothing() -> void:
	var lines := StaffProfile.reward_lines(null, DataDB.boosters, DataDB.segments, Text.phrase())
	assert_eq(lines, [Text.say("staff.reward_none")] as Array[String])


func test_a_negative_bonus_keeps_its_sign() -> void:
	var lines := StaffProfile.reward_lines([{"delta": -3, "target": "BO05"}],
		DataDB.boosters, DataDB.segments, Text.phrase())
	assert_string_contains(lines[0], "-3")


func test_every_real_candidate_builds_a_profile_with_no_blank_lines() -> void:
	for candidate: Dictionary in DataDB.staff:
		var tiers := StaffProfile.tiers(candidate, DataDB.boosters, DataDB.segments, Text.phrase())
		assert_gt(tiers.size(), 0, "%s has no tiers" % candidate.get("staff_id"))
		for entry: Dictionary in tiers:
			for line: String in entry["lines"]:
				assert_false(line.strip_edges().is_empty())
				assert_false(line.contains("{"), "an unfilled placeholder in '%s'" % line)
