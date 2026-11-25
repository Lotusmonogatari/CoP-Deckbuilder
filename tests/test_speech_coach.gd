extends GutTest
## The speech coach (2026-11-22, Cameron's upload; VEN01 in the Area Characters tab since 2026-11-25): a picture in the area characters
## folder, found by its ID, and shown at the top of the Rhetoric Training page with his name, kanji and title from his row.


func test_the_picture_is_found_by_id_in_the_area_folder() -> void:
	assert_eq(ArtLoader.character_folder("VEN01"), "res://assets/characters/area/")
	var path := ArtLoader.character_path("VEN01")
	assert_eq(path, "res://assets/characters/area/VEN01.png")
	assert_true(ArtLoader.exists(path), "the picture is imported")


func test_an_ordinary_id_is_not_sent_to_the_capitol_folder() -> void:
	assert_eq(ArtLoader.character_folder("VI05"), "res://assets/characters/visitors/")
	assert_eq(ArtLoader.character_folder("OP10"), "res://assets/characters/opponents/")


func test_the_rhetoric_training_page_opens_with_the_coach() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	var rows: Array = office._rhetoric_cards(OfficeFrameStyles.look())
	assert_gt(rows.size(), 1, "the coach, then the training sessions")
	var first := rows[0] as Control
	assert_eq(first.name, "SpeechCoachCard")
	var coach := first.find_child("SpeechCoach", true, false) as PlaceholderArt
	assert_not_null(coach)
	assert_eq(coach.art_id, "VEN01")
	assert_eq((first.find_child("CoachName", true, false) as Label).text, "Masayuki Katō", "his name, with the accented ō")
	assert_eq((first.find_child("CoachNameJp", true, false) as Label).text, "加藤正幸", "his name in kanji beside it")
	for row: Variant in rows:
		(row as Node).queue_free()
