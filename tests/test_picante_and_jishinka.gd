extends GutTest
## VI168 Picante Paul and VI169 Kakata Jishinka (2026-11-22, Cameron): four seasonal flavor questions that only Paul asks, four
## questions about the nineties and the Ministry of Ethics and Prosecution that only Jishinka asks, both Capitol only.

const FLAVORS := {"Spring": "Mikan", "Summer": "Cherries", "Autumn": "Chestnut", "Winter": "Yuzu"}

var _calendar_before: Dictionary = {}


func before_each() -> void:
	_calendar_before = GameState.calendar.duplicate()


func after_each() -> void:
	GameState.calendar = _calendar_before


func _choices(question: Dictionary) -> Array:
	return [question["choice_a"], question["choice_b"], question["choice_c"], question["choice_d"]]


func test_picante_paul_has_one_question_for_each_season_and_the_right_flavor_wins() -> void:
	var questions := DataDB.get_questions_for_visitor("VI168")
	assert_eq(questions.size(), 4)
	var seen_seasons: Array = []
	var all_flavors: Array = []
	for question: Dictionary in questions:
		var seasons: Array = question.get("seasons", [])
		assert_eq(seasons.size(), 1, "%s names one season" % question["question_id"])
		var season := str(seasons[0])
		seen_seasons.append(season)
		var right: String = _choices(question)[["A", "B", "C", "D"].find(str(question["correct_choice"]))]
		assert_eq(right, FLAVORS[season], "%s: %s's flavor is right" % [question["question_id"], season])
		assert_true(str(question["question_text"]).contains("Doki Doki Picante Pulse"), "the brand is named")
		for flavor: String in _choices(question):
			assert_false(all_flavors.has(flavor), "%s is not repeated in another question" % flavor)
			all_flavors.append(flavor)
	seen_seasons.sort()
	assert_eq(seen_seasons, ["Autumn", "Spring", "Summer", "Winter"])
	assert_eq(all_flavors.size(), 16)


func test_the_question_asked_is_the_one_for_the_season_it_is() -> void:
	for week in range(0, 52, 3):
		GameState.calendar = {"week": week, "phase": "work", "hours": 0}
		var asked := BattleSetup._question_for_visitor("VI168")
		assert_true(GameState.in_season(asked), "week %d: %s is in season" % [week, asked.get("question_id", "")])


func test_an_unseasoned_visitor_is_unaffected() -> void:
	# Seasonless questions are always in season.
	assert_true(GameState.in_season({"seasons": null}))
	assert_true(GameState.in_season({}))


func test_kakata_jishinka_asks_four_questions_and_states_no_backstory() -> void:
	var questions := DataDB.get_questions_for_visitor("VI169")
	assert_eq(questions.size(), 4)
	for question: Dictionary in questions:
		var text := (str(question["question_text"]) + " " + " ".join(PackedStringArray(_choices(question)))).to_lower()
		assert_false(text.contains("1993"), "the year of his ministry is not stated")
		assert_false(text.contains("keizaijiyuutou") or text.contains("coalition") or text.contains("minister of ethics"),
			"his ministry and the coalition are not stated in the question")


func test_both_are_capitol_only_with_their_organizations() -> void:
	var paul := DataDB.get_visitor("VI168")
	var jishinka := DataDB.get_visitor("VI169")
	assert_eq(str(paul.get("location")), "Capitol")
	assert_eq(str(jishinka.get("location")), "Capitol")
	assert_eq(str(paul.get("name_en")), "Picante Paul")
	assert_eq(str(jishinka.get("name_jp")), "侍臣家 過形")
	var paul_orgs := str(paul.get("reward")) + str(paul.get("penalty"))
	assert_true(paul_orgs.contains("BO05") and paul_orgs.contains("BO16"), "Chamber of Commerce and Innovation Society")
	var jishinka_orgs := str(jishinka.get("reward")) + str(jishinka.get("penalty"))
	assert_true(jishinka_orgs.contains("BO17") and jishinka_orgs.contains("BO16"), "Members of Parliament and Innovation Society")
