extends GutTest
## The weekend levels (2026-10-23): a lobbyist meeting with no ambush after it,
## a weekend Office Hours, and "Attend a Local Festival" with ten constituents
## from a pool of local content.


func test_the_quiet_lobbyist_level_is_one_lobbyist_stage_and_nothing_else() -> void:
	var level := DataDB.get_level("LV85")
	assert_eq(str(level["stage_1"]), "ST20")
	assert_true(level["stage_2"] == null or str(level["stage_2"]).is_empty(), "no Media Ambush after it")
	assert_eq(GameState.level_hours(level), 2)


func test_weekend_office_hours_is_one_office_hours_stage() -> void:
	var level := DataDB.get_level("LV86")
	assert_eq(str(level["stage_1"]), "ST07")
	assert_eq(GameState.level_hours(level), 2)


func test_all_three_fit_a_weekend_day_and_are_flagged_for_it() -> void:
	for level_id: String in ["LV85", "LV86", "LV87"]:
		var level := DataDB.get_level(level_id)
		assert_eq(str(level["weekend_ok"]), "Yes", level_id)
		assert_lte(GameState.level_hours(level), 4, level_id)


func test_the_festival_seats_ten_distinct_constituents_each_with_a_question() -> void:
	var expanded := BattleSetup.expand_level(DataDB.get_level("LV87"))
	var stage: Dictionary = (expanded["stages"] as Array)[0]
	var visitors: Array = stage.get("visitors", [])
	assert_eq(visitors.size(), 10)
	var seen := {}
	for visitor: Dictionary in visitors:
		seen[str(visitor["visitor_id"])] = true
		assert_false((visitor.get("question", {}) as Dictionary).is_empty(), "%s has a question" % visitor["visitor_id"])
	assert_eq(seen.size(), 10, "no one is seen twice")


func test_the_festival_pool_is_bigger_than_one_visit_and_every_visitor_has_two_questions() -> void:
	var pool: Array = []
	for visitor: Dictionary in DataDB.visitors:
		if (visitor.get("stages", []) as Array).has("ST264"):
			pool.append(str(visitor["visitor_id"]))
	assert_gte(pool.size(), 14)
	for id: String in pool:
		var count := 0
		for question: Dictionary in DataDB.visitor_questions:
			if (question.get("visitor_ids", []) as Array).has(id):
				count += 1
		assert_gte(count, 2, "%s has two questions" % id)


func test_the_festival_is_for_the_local_visitors_only() -> void:
	for visitor: Dictionary in DataDB.visitors:
		var stages: Array = visitor.get("stages", [])
		if stages.has("ST264"):
			assert_false(stages.has("ST07"), "%s is not also an ordinary Office Hours visitor" % visitor["visitor_id"])
