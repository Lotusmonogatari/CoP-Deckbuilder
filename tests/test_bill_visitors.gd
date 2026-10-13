extends GutTest
## Each new bill level opens with its own Office Hours, and its own visitor
## (2026-10-14) is always one of the people who come.


func test_every_new_bill_level_seats_its_own_visitor_first() -> void:
	var seen := 0
	for n in range(63, 83):
		var level_id := "LV%d" % n
		var level := BattleSetup.expand_level(DataDB.get_level(level_id))
		var stage: Dictionary = level["stages"][0]
		assert_eq(stage["mode"], "Non-combat", "%s opens with Office Hours" % level_id)
		var ids: Array = []
		for visitor: Dictionary in stage["visitors"]:
			ids.append(visitor["visitor_id"])
			assert_false((visitor.get("question", {}) as Dictionary).is_empty(), "%s has a question" % visitor["visitor_id"])
		var pinned := ""
		for row: Dictionary in DataDB.level_visitor_overrides:
			if row["level_id"] == level_id:
				pinned = row["visitor_id"]
		assert_ne(pinned, "", "%s has a pin" % level_id)
		assert_true(ids.has(pinned), "%s's own visitor appears" % level_id)
		seen += 1
	assert_eq(seen, 20)


func test_a_bills_own_visitor_only_comes_to_that_bills_office_hours() -> void:
	var own := DataDB.get_visitor("VI40")
	assert_eq(own["stages"], ["ST101"])
	assert_true(DataDB.get_visitor("VI01")["stages"].has("ST101"), "general visitors also come")
