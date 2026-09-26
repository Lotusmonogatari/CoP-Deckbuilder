extends GutTest
## OpponentDisplay.gd: the title shown next to an opponent's name, and the
## organisation their Affiliation booster_id names. Pure and UI-free, so
## tested against fabricated rows rather than real data.


func test_a_real_title_is_shown_as_is() -> void:
	var opponent := {"title": "Prime Minister; Leader of the Yezo Heritage Party", "role": "Committee of the Cabinet"}
	assert_eq(OpponentDisplay.title_for(opponent), "Prime Minister; Leader of the Yezo Heritage Party")


func test_no_real_title_falls_back_to_the_role() -> void:
	var opponent := {"title": "N/A", "role": "Committee on the Environment"}
	assert_eq(OpponentDisplay.title_for(opponent), "Committee on the Environment")


func test_a_blank_title_also_falls_back_to_the_role() -> void:
	var opponent := {"title": "", "role": "Journalist"}
	assert_eq(OpponentDisplay.title_for(opponent), "Journalist")


func test_neither_title_nor_role_is_a_blank_string_not_a_crash() -> void:
	var opponent := {"title": "N/A", "role": ""}
	assert_eq(OpponentDisplay.title_for(opponent), "")


func test_the_affiliation_resolves_to_its_boosters_own_name() -> void:
	var opponent := {"affiliation": "BO08"}
	var boosters := [{"booster_id": "BO08", "name_en": "National Media"}]
	assert_eq(OpponentDisplay.affiliation_name_for(opponent, boosters), "National Media")


func test_a_blank_affiliation_resolves_to_nothing() -> void:
	assert_eq(OpponentDisplay.affiliation_name_for({}, [{"booster_id": "BO08", "name_en": "National Media"}]), "")


func test_an_affiliation_with_no_matching_booster_resolves_to_nothing() -> void:
	var opponent := {"affiliation": "BO99"}
	assert_eq(OpponentDisplay.affiliation_name_for(opponent, [{"booster_id": "BO08", "name_en": "National Media"}]), "")
