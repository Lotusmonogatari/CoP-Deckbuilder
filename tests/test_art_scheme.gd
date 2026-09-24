extends GutTest
## Where art is looked for (data/art.json, ArtLoader).


func test_each_kind_of_character_has_its_own_folder() -> void:
	assert_eq(ArtLoader.character_folder("PC01"), ArtLoader.folder("protagonist"))
	assert_eq(ArtLoader.character_folder("OP03"), ArtLoader.folder("opponent"))
	assert_eq(ArtLoader.character_folder("SF02"), ArtLoader.folder("staff"))
	assert_eq(ArtLoader.character_folder("VI01"), ArtLoader.folder("visitor"))
	assert_eq(ArtLoader.character_folder("JR_A"), ArtLoader.folder("journalist"))


func test_a_committee_members_name_goes_with_the_opponents() -> void:
	assert_eq(ArtLoader.character_folder("Member Tanaka"), ArtLoader.folder("opponent"))


func test_the_file_a_placeholder_asks_for() -> void:
	assert_eq(ArtLoader.expected_character_path("OP03", "guarding"),
		ArtLoader.folder("opponent") + "OP03_guarding.png")


func test_the_five_expressions_are_the_ones_the_art_file_lists() -> void:
	assert_eq(DataDB.art.get("expressions"),
		[ArtLoader.NEUTRAL, ArtLoader.ATTACKING, ArtLoader.GUARDING, ArtLoader.GAINING, ArtLoader.DAMAGED])


func test_a_missing_face_falls_back_to_neutral_in_the_end() -> void:
	assert_eq(ArtLoader.expression_chain("attacking"), ["attacking", "neutral"] as Array[String])
	assert_eq(ArtLoader.expression_chain("defeated"), ["defeated", "damaged", "neutral"] as Array[String])
	assert_eq(ArtLoader.expression_chain("neutral"), ["neutral"] as Array[String])


func test_art_that_is_not_drawn_gives_a_placeholder_not_nothing() -> void:
	assert_eq(ArtLoader.character_path("OP99", "attacking"), "")
	assert_not_null(ArtLoader.character("OP99", "attacking"))
	assert_not_null(ArtLoader.card("C999"))
	assert_not_null(ArtLoader.background("ST99"))
