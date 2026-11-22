extends GutTest
## VI170 to VI173 (2026-11-22, Cameron's "Go"): four District service workers, six draft questions each.

const IDS := ["VI170", "VI171", "VI172", "VI173"]


func test_each_is_a_district_visitor_with_a_picture_rooms_and_six_questions() -> void:
	for id: String in IDS:
		var visitor := DataDB.get_visitor(id)
		assert_false(visitor.is_empty(), id)
		assert_eq(str(visitor.get("location")), "District", id)
		assert_false((visitor.get("stages", []) as Array).is_empty(), "%s has rooms" % id)
		assert_eq(DataDB.get_questions_for_visitor(id).size(), 6, "%s asks six questions" % id)
		assert_true(FileAccess.file_exists("res://assets/characters/visitors/%s.png" % id), "%s has a picture" % id)


func test_the_friendly_choice_is_the_marked_right_one_and_positions_vary() -> void:
	var letters: Dictionary = {}
	for id: String in IDS:
		for question: Dictionary in DataDB.get_questions_for_visitor(id):
			letters[str(question["correct_choice"])] = true
			var effects: Array = question.get("effects_%s" % str(question["correct_choice"]).to_lower(), [])
			assert_true(OfficeHoursEngine.net_delta(effects) >= 2.0, "%s: the right choice pleases" % question["question_id"])
	assert_eq(letters.size(), 4, "the right answer sits in every position across the 24 questions")


func test_winter_matters_are_asked_in_autumn_and_winter() -> void:
	var seasonal := 0
	for id: String in IDS:
		for question: Dictionary in DataDB.get_questions_for_visitor(id):
			var seasons: Variant = question.get("seasons")
			if seasons is Array and not (seasons as Array).is_empty():
				seasonal += 1
				assert_eq(question["seasons"], ["Autumn", "Winter"], str(question["question_id"]))
	assert_eq(seasonal, 4, "the four winter questions")
