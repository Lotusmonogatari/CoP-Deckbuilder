extends GutTest
## District activities (2026-10-23): four single-stage outings, each an Office
## Hours clone with its own pool of local visitors.

const ACTIVITIES := {
	"ST267": {"level": "LV94", "hours": 2, "seats": 6},
	"ST268": {"level": "LV95", "hours": 3, "seats": 6},
	"ST269": {"level": "LV96", "hours": 2, "seats": 8},
	"ST270": {"level": "LV97", "hours": 4, "seats": 10},
}


func test_each_activity_is_a_weekend_ready_single_stage_level() -> void:
	for stage_id: String in ACTIVITIES.keys():
		var spec: Dictionary = ACTIVITIES[stage_id]
		var level := DataDB.get_level(str(spec["level"]))
		assert_eq(str(level.get("stage_1")), stage_id)
		assert_eq(str(level.get("weekend_ok")), "Yes", stage_id)
		assert_ne(str(level.get("needs_discovery", "")), "Yes", "%s is open from the start" % stage_id)
		var stage := DataDB.get_stage(stage_id)
		assert_eq(int(stage["time_units"]), int(spec["hours"]), stage_id)
		assert_eq((stage["opponent_count"] as Dictionary)["min"], int(spec["seats"]), stage_id)


func test_each_pool_is_bigger_than_one_visit_and_every_visitor_has_two_questions() -> void:
	for stage_id: String in ACTIVITIES.keys():
		var pool: Array = []
		for visitor: Dictionary in DataDB.visitors:
			var stages: Array = visitor.get("stages", [])
			if stages.has(stage_id):
				pool.append(str(visitor["visitor_id"]))
				assert_false(stages.has("ST07"), "%s is local only" % visitor["visitor_id"])
		assert_gt(pool.size(), int((ACTIVITIES[stage_id] as Dictionary)["seats"]), "%s pool" % stage_id)
		for id: String in pool:
			var count := 0
			for question: Dictionary in DataDB.visitor_questions:
				if (question.get("visitor_ids", []) as Array).has(id):
					count += 1
			assert_gte(count, 2, "%s has two questions" % id)
