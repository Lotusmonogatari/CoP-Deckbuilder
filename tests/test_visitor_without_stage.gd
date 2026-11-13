extends GutTest
## A visitor row whose Stage cell is blank exports a null "stages". It used to
## crash every visitor lookup ("Invalid cast: could not convert value to
## 'Array'"); now it simply never appears (2026-11-13, found when Cameron's
## new visitor VI167 arrived with no stages).

func test_a_visitor_with_blank_stages_is_never_offered_and_crashes_nothing() -> void:
	var blank := {"visitor_id": "VI_TEST_BLANK", "name_en": "Test Visitor", "stages": null, "reward": null, "penalty": null}
	DataDB.visitors.append(blank)
	var pool := DataDB.get_visitors_for_stage("ST07")
	DataDB.visitors.erase(blank)
	for visitor: Dictionary in pool:
		assert_ne(str(visitor.get("visitor_id", "")), "VI_TEST_BLANK")
	assert_gt(pool.size(), 0, "the ordinary visitors are still found")


func test_the_volcanologist_now_has_rooms_and_questions() -> void:
	# VI167 arrived with no Stage cell (2026-11-13); his rooms, standing and
	# six questions were drafted the same day, so he is now offered.
	var visitor := DataDB.get_visitor("VI167")
	assert_false(visitor.is_empty(), "Cameron's new volcanologist is loaded")
	assert_gt((visitor.get("stages", []) as Array).size(), 0, "he has rooms")
	var found_in_office_hours := false
	for found: Dictionary in DataDB.get_visitors_for_stage("ST07"):
		if str(found.get("visitor_id", "")) == "VI167":
			found_in_office_hours = true
	assert_true(found_in_office_hours, "he is offered in Office Hours")
	var question_count := 0
	for question: Dictionary in DataDB.visitor_questions:
		if (question.get("visitor_ids", []) as Array).has("VI167"):
			question_count += 1
	assert_eq(question_count, 6, "he asks six questions")
