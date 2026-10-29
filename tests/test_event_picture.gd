extends GutTest
## An event's Image cell can list several pictures (2026-10-29).


func test_one_id_is_returned_as_written() -> void:
	assert_eq(EventPicture.pick("OUT_HARBOR"), "OUT_HARBOR")


func test_blank_and_null_cells_pick_nothing() -> void:
	assert_eq(EventPicture.pick(null), "")
	assert_eq(EventPicture.pick(""), "")
	assert_eq(EventPicture.pick(" ; "), "")


func test_a_list_is_split_and_trimmed() -> void:
	assert_eq(EventPicture.options("OUT_HARBOR_1; OUT_HARBOR_2 ;OUT_HARBOR_3"),
		["OUT_HARBOR_1", "OUT_HARBOR_2", "OUT_HARBOR_3"])


func test_a_list_only_ever_yields_its_own_ids_and_uses_them_all() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen := {}
	for i in 60:
		seen[EventPicture.pick("OUT_HARBOR_1; OUT_HARBOR_2", rng)] = true
	assert_eq(seen.keys().size(), 2)
	assert_true(seen.has("OUT_HARBOR_1") and seen.has("OUT_HARBOR_2"))


func test_an_undrawn_numbered_outside_scene_shows_the_town_hall() -> void:
	assert_eq(ArtLoader.background_path("OUT_LAKESIDE_2"), "res://assets/backgrounds/ST05.png")


func test_every_picture_an_event_names_resolves_to_a_file() -> void:
	for event: Dictionary in DataDB.events:
		for id: String in EventPicture.options(event.get("image")):
			assert_ne(ArtLoader.background_path(id), "", "%s names %s, which shows nothing" % [event.get("event_id"), id])


func test_the_drawn_harbor_pictures_are_used_not_the_town_hall() -> void:
	assert_eq(ArtLoader.background_path("OUT_HARBOR_1"), "res://assets/backgrounds/OUT_HARBOR_1.png")
