extends GutTest
## The Patron Visit opening stage (2026-10-19): the sponsoring organization's
## representative asks two dilemma questions about the bill.


func before_each() -> void:
	GameState.start_new_run("PC02")
	GameState.booster_standing["BO05"] = 75


func after_each() -> void:
	DataDB.clear_runtime()


func test_the_visit_has_two_questions_each_moving_the_patron() -> void:
	var built := PatronVisit.build("BO05", ["CB051", "CB052"])
	assert_eq((built["visitors"] as Array).size(), 2)
	for entry: Dictionary in built["visitors"]:
		var question: Dictionary = entry["question"]
		for key in PatronVisit.CHOICES:
			assert_ne(str(question["choice_%s" % key]), "")
			var effects: Array = question["effects_%s" % key]
			assert_eq(str(effects[0]["target"]), "BO05", "the patron comes first")
		assert_gt(int((question["effects_a"] as Array)[0]["delta"]), 0)
		assert_lt(int((question["effects_d"] as Array)[0]["delta"]), 0)
	assert_string_contains(str((built["visitors"] as Array)[0]["name_en"]), "Representative")


func test_a_sponsored_level_opens_with_the_visit() -> void:
	assert_true(GameState.start_patron_level("PB051"))
	var runner := GameState.level_runner
	assert_eq(str(runner.stages[0]["stage_id"]), PatronVisit.STAGE)
	assert_eq((runner.stages[0]["visitors"] as Array).size(), 2)
	assert_eq(runner.problems().size(), 0)


func test_answering_the_visit_moves_the_patrons_standing() -> void:
	GameState.start_patron_level("PB051")
	var engine := OfficeHoursEngine.new()
	assert_true(engine.setup({"visitors": GameState.level_runner.stages[0]["visitors"]}))
	var before := int(GameState.booster_standing["BO05"])
	var outcome := engine.answer("A")
	GameState.apply_visitor_reward_entries(outcome["effects"])
	assert_gt(int(GameState.booster_standing["BO05"]), before)
