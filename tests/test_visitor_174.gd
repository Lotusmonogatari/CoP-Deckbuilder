extends GutTest
## VI174 Harue Kobayashi 小林春江 (2026-11-23, Cameron): the sister of VI154 Kimiko Hasegawa, a dairy farmer; she runs a farm creamery under her married name Kobayashi, the family name (and kanji) VI143 Mika Kobayashi has.


func test_she_is_in_kimikos_district_and_rooms() -> void:
	var harue := DataDB.get_visitor("VI174")
	var kimiko := DataDB.get_visitor("VI154")
	assert_eq(str(harue.get("name_en")), "Harue Kobayashi")
	assert_eq(str(harue.get("name_jp")), "小林春江")
	assert_eq(str(harue.get("name_jp")).substr(0, 2), str(DataDB.get_visitor("VI143").get("name_jp")).substr(0, 2), "the same family-name kanji as VI143")
	assert_eq(str(harue.get("location")), "District")
	assert_eq(harue.get("stages"), kimiko.get("stages"), "she turns up where her sister does")
	assert_true(FileAccess.file_exists("res://assets/characters/visitors/VI174.png"))


func test_she_asks_six_questions_and_never_states_the_machinery() -> void:
	var questions := DataDB.get_questions_for_visitor("VI174")
	assert_eq(questions.size(), 6)
	var winter := 0
	for question: Dictionary in questions:
		var seasons: Variant = question.get("seasons")
		if seasons is Array and not (seasons as Array).is_empty():
			winter += 1
			assert_eq(seasons, ["Autumn", "Winter"])
	assert_eq(winter, 1, "the snow-route question")
