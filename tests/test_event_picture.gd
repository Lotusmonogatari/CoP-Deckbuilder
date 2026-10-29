extends GutTest
## An event's Image cell can list several pictures (2026-10-29).


func test_one_id_is_returned_as_written() -> void:
	assert_eq(EventPicture.pick("PIC_A"), "PIC_A")


func test_blank_and_null_cells_pick_nothing() -> void:
	assert_eq(EventPicture.pick(null), "")
	assert_eq(EventPicture.pick(""), "")
	assert_eq(EventPicture.pick(" ; "), "")


func test_a_list_is_split_and_trimmed() -> void:
	assert_eq(EventPicture.options("PIC_A; PIC_B ;PIC_C"),
		["PIC_A", "PIC_B", "PIC_C"])


func test_a_list_only_ever_yields_its_own_ids_and_uses_them_all() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen := {}
	for i in 60:
		seen[EventPicture.pick("PIC_A; PIC_B", "", {}, rng)] = true
	assert_eq(seen.keys().size(), 2)
	assert_true(seen.has("PIC_A") and seen.has("PIC_B"))


func test_an_undrawn_numbered_outside_scene_shows_the_fallback() -> void:
	# A made-up id no file will ever match, so this holds whatever is drawn.
	assert_eq(ArtLoader.background_path("OUT_NEVER_DRAWN_2"),
		"res://assets/backgrounds/%s.png" % str(DataDB.art.get("outdoor_background_fallback", "")))


# Terms: synthetic names and words, so these hold whatever is drawn or written.
const TERMS := {"COLD": ["cold", "ice"], "WARM": ["warm"]}


func test_a_term_picture_needs_its_term_in_the_context() -> void:
	var rng := RandomNumberGenerator.new()
	for i in 20:
		assert_eq(EventPicture.pick("PIC_X_COLD; PIC_Y", "A sunny market", TERMS, rng), "PIC_Y")


func test_a_term_picture_is_preferred_when_the_context_invokes_it() -> void:
	var rng := RandomNumberGenerator.new()
	for i in 20:
		assert_eq(EventPicture.pick("PIC_X_COLD; PIC_Y", "Ice on the road", TERMS, rng), "PIC_X_COLD")


func test_a_related_word_counts() -> void:
	assert_true(EventPicture.context_invokes("COLD", "the ice melts", TERMS))
	assert_false(EventPicture.context_invokes("COLD", "a warm day", TERMS))


func test_a_list_of_only_term_pictures_is_never_left_empty() -> void:
	assert_eq(EventPicture.pick("PIC_X_COLD; PIC_Z_COLD", "nothing relevant", TERMS).begins_with("PIC_"), true)


func test_every_term_in_a_name_must_be_invoked() -> void:
	var fit := EventPicture.eligible(["PIC_COLD_WARM", "PIC_PLAIN"] as Array[String], "cold only", TERMS)
	assert_eq(fit, ["PIC_PLAIN"])
