extends GutTest
## The listening strip's rules (2026-10-18): what a card would tally, and
## which styles an organisation likes.

func _questions() -> Dictionary:
	var pool: Array = []
	for i in 6:
		pool.append({"pleases_boosters": ["BO07"],
			"grades": {"Earnest": "S", "Emotional": "M", "Appeal": "M",
				"Data Driven": "W", "Divisive": "W", "Duplicitous": "M"}})
	return {"pool": pool}


func test_taste_lists_liked_and_disliked_suits() -> void:
	var suits := ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]
	var taste := BoosterSuitTendency.taste_of(_questions(), "BO07", suits)
	assert_eq(taste["likes"], ["Earnest"])
	assert_eq(taste["dislikes"].size(), 2)
	assert_true(taste["dislikes"].has("Divisive"))


func test_unknown_organization_has_no_taste() -> void:
	var taste := BoosterSuitTendency.taste_of(_questions(), "BO99", ["Earnest"])
	assert_true((taste["likes"] as Array).is_empty())
	assert_true((taste["dislikes"] as Array).is_empty())


func test_real_battle_preview_matches_what_playing_does() -> void:
	GameState.start_new_run("PC01")
	var config := BattleSetup.for_level_stage("LV01", "ST05")
	var engine := BattleEngine.new()
	engine.setup(config)
	var question := engine.current_question()
	assert_false(question.is_empty(), "a Town Hall asks a question")
	var before := engine.booster_tally().duplicate(true)
	for card_id: String in engine.state.hand:
		var card := DataDB.get_card(card_id)
		var effect := engine.answer_effect(card)
		assert_eq(engine.booster_tally(), before, "asking changes nothing")
		var grade: String = effect["grade"]
		if grade == "S":
			assert_eq(effect["pleased"], question.get("pleases_boosters", []))
		elif grade == "W":
			assert_eq(effect["displeased"], question.get("pleases_boosters", []))
		else:
			assert_true((effect["pleased"] as Array).is_empty())
