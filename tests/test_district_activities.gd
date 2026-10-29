extends GutTest
## Single-stage outings (festivals, district activities, weekend Office Hours):
## every level whose only stage is a Non-combat room and which is flagged Weekend OK
## (2026-10-23, made data-driven 2026-10-29: a new outing is covered with no edit here).


func _outings() -> Array:
	var found: Array = []
	for level: Dictionary in DataDB.levels:
		var only_stage := str(level.get("stage_1", ""))
		if only_stage.is_empty() or str(level.get("weekend_ok", "")) != "Yes":
			continue
		# A crisis level (Special Trigger) is not an outing.
		if level.get("special_trigger") != null and not str(level.get("special_trigger")).is_empty():
			continue
		var second: Variant = level.get("stage_2")
		if second != null and not str(second).is_empty():
			continue
		var stage := DataDB.get_stage(only_stage)
		if str(stage.get("mode", "")) == "Non-combat":
			found.append({"level": level, "stage": stage})
	return found


func _pool(stage_id: String) -> Array:
	var pool: Array = []
	for visitor: Dictionary in DataDB.visitors:
		if (visitor.get("stages", []) as Array).has(stage_id):
			pool.append(visitor)
	return pool


func _seats(stage: Dictionary) -> int:
	var count: Variant = stage.get("opponent_count")
	return int((count as Dictionary)["min"]) if count is Dictionary else 1


func test_the_data_has_outings() -> void:
	assert_gt(_outings().size(), 0)


func test_each_outing_is_weekend_ready_and_open_from_the_start() -> void:
	for entry: Dictionary in _outings():
		var level: Dictionary = entry["level"]
		var stage: Dictionary = entry["stage"]
		assert_ne(str(level.get("needs_discovery", "")), "Yes", "%s is open from the start" % level["level_id"])
		assert_lte(GameState.level_hours(level), 4, "%s fits a weekend day" % level["level_id"])
		assert_gte(_seats(stage), 1, str(stage["stage_id"]))


func test_each_pool_covers_its_seats_and_every_visitor_has_two_questions() -> void:
	for entry: Dictionary in _outings():
		var stage: Dictionary = entry["stage"]
		var stage_id := str(stage["stage_id"])
		var pool := _pool(stage_id)
		assert_gte(pool.size(), _seats(stage), "%s pool" % stage_id)
		for visitor: Dictionary in pool:
			# A visitor shared with other rooms (the ordinary Office Hours cast) is
			# not held to this rule; one written for this room alone has two questions.
			if (visitor.get("stages", []) as Array).size() > 1:
				continue
			var count := 0
			for question: Dictionary in DataDB.visitor_questions:
				if (question.get("visitor_ids", []) as Array).has(str(visitor["visitor_id"])):
					count += 1
			assert_gte(count, 2, "%s has two questions" % visitor["visitor_id"])


func test_an_outing_seats_distinct_visitors_each_with_a_question() -> void:
	for entry: Dictionary in _outings():
		var expanded := BattleSetup.expand_level(entry["level"])
		var stage: Dictionary = (expanded["stages"] as Array)[0]
		var visitors: Array = stage.get("visitors", [])
		assert_eq(visitors.size(), _seats(entry["stage"]), str(entry["level"]["level_id"]))
		var seen := {}
		for visitor: Dictionary in visitors:
			seen[str(visitor["visitor_id"])] = true
			assert_false((visitor.get("question", {}) as Dictionary).is_empty(), "%s has a question" % visitor["visitor_id"])
		assert_eq(seen.size(), visitors.size(), "no one is seen twice")
