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


# ---------------------------------------------------------------------------
# Stage outfits (entirely optional, 2026-09-27) — a character can have one
# drawing for one room, without anything else needing to change.
# ---------------------------------------------------------------------------

func test_a_stage_id_is_tried_before_the_plain_file_of_the_same_expression() -> void:
	var candidates := ArtLoader.character_path_candidates("OP03", "attacking", "ST04")
	var folder := ArtLoader.folder("opponent")
	var stage_specific := candidates.find(folder + "OP03_ST04_attacking.png")
	var plain := candidates.find(folder + "OP03_attacking.png")
	assert_gte(stage_specific, 0, "the stage outfit is offered at all")
	assert_gte(plain, 0, "the plain drawing is still offered")
	assert_lt(stage_specific, plain, "the stage outfit comes first")


func test_a_plain_drawing_of_the_right_expression_still_beats_a_stage_outfit_of_the_wrong_one() -> void:
	# neutral (fallback) should never be offered, stage-specific or not,
	# before the plain RIGHT expression — expression_chain() order still
	# governs which expression is tried first.
	var candidates := ArtLoader.character_path_candidates("OP03", "attacking", "ST04")
	var folder := ArtLoader.folder("opponent")
	var plain_attacking := candidates.find(folder + "OP03_attacking.png")
	var stage_neutral := candidates.find(folder + "OP03_ST04_neutral.png")
	assert_gte(stage_neutral, 0)
	assert_lt(plain_attacking, stage_neutral)


func test_no_stage_id_means_no_stage_candidates_at_all() -> void:
	for candidate: String in ArtLoader.character_path_candidates("OP03", "attacking"):
		assert_false(candidate.contains("_ST"), candidate)


func test_a_stage_id_with_nothing_drawn_for_it_still_falls_back_cleanly() -> void:
	assert_eq(ArtLoader.character_path("OP99", "attacking", "ST04"), "")
	assert_not_null(ArtLoader.character("OP99", "attacking", "ST04"))


# ---------------------------------------------------------------------------
# PlaceholderArt's own art draws behind any child already in the scene
# (regression: the battle screen's "you" chip was hidden by the opponent
# portrait's own texture, which used to always land on top — 2026-09-27).
# ---------------------------------------------------------------------------

func test_the_art_and_label_are_always_the_back_two_children() -> void:
	var art := PlaceholderArt.new()
	var pretend_static_child := Control.new()
	pretend_static_child.name = "AlreadyThere"
	art.add_child(pretend_static_child)
	add_child_autofree(art)   # enters the tree -> _ready() -> _build()
	assert_eq(art.get_child_count(), 3)
	assert_eq(art.get_child(2).name, "AlreadyThere",
		"a child present before _build() runs stays in front of the art")
