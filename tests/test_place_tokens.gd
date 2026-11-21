extends GutTest
## Two offices, slice 5 (2026-11-20): place tokens in text, the Places tab, and Needs Place.

func after_each() -> void:
	DataDB.use_protagonist("PC04")


func test_a_token_becomes_the_protagonists_own_name() -> void:
	var names := {"harbor": ["Port of Wakkanai"]}
	assert_eq(PlaceTokens.fill("A letter from {place:harbor}.", names, "Daikoku", "EV27"), "A letter from Port of Wakkanai.")


func test_the_office_town_fills_office_city() -> void:
	assert_eq(PlaceTokens.fill("A priest from {office_city}.", {}, "Noheji", "EV19"), "A priest from Noheji.")
	assert_eq(PlaceTokens.fill("A priest from {office_city}.", {}, "", "EV19"), "A priest from your district.")


func test_several_names_pick_the_same_one_every_time_for_the_same_line() -> void:
	var names := {"school": ["North High", "South High", "East High"]}
	var first := PlaceTokens.fill("{place:school}", names, "", "EV24")
	for i in 5:
		assert_eq(PlaceTokens.fill("{place:school}", names, "", "EV24"), first, "stable")
	var other_lines := {}
	for key: String in ["EV24", "EV37", "EV42", "EV50", "EV52", "EV99"]:
		other_lines[PlaceTokens.fill("{place:school}", names, "", key)] = true
	assert_gt(other_lines.size(), 1, "different lines can pick different names")


func test_a_type_with_no_name_reads_as_the_plain_word() -> void:
	assert_eq(PlaceTokens.fill("near {place:onsen_town}", {}, "", "x"), "near onsen town")
	assert_eq(PlaceTokens.fill("no token here", {}, "", "x"), "no token here")


func test_the_types_in_a_text_and_whether_a_district_has_them() -> void:
	assert_eq(PlaceTokens.types_in("{place:harbor} and {place:school} and {place:harbor}"), ["harbor", "school"] as Array[String])
	var names := {"harbor": ["A"], "school": ["B"]}
	assert_true(PlaceTokens.has_types(names, ["harbor", "school"]))
	assert_false(PlaceTokens.has_types(names, ["harbor", "island"]))
	assert_true(PlaceTokens.has_types(names, null), "an event that needs nothing always fits")


func test_every_protagonist_has_a_district_of_places() -> void:
	for pid: String in ["PC04", "PC02", "PC03", "PC01"]:
		var names := PlaceTokens.names_by_type(DataDB.places, pid)
		assert_gt(names.size(), 18, "%s has most of the 23 place types" % pid)
	assert_gt(DataDB.places.size(), 100, "the catalog is not empty")


func test_pc04_and_pc01_have_swapped_districts() -> void:
	var pc04 := PlaceTokens.names_by_type(DataDB.places, "PC04")
	var pc01 := PlaceTokens.names_by_type(DataDB.places, "PC01")
	assert_true((pc04["station"] as Array).has("Noheji Station"), "PC04 is the Aomori protagonist now")
	assert_true((pc01["station"] as Array).has("Wakkanai Station"), "PC01 is the Wakkanai protagonist now")


func test_events_read_in_the_protagonists_own_places() -> void:
	DataDB.use_protagonist("PC01")
	assert_string_contains(str(GameState.get_event("EV02").get("flavor")), "Hokumon Shrine")
	DataDB.use_protagonist("PC03")
	assert_string_contains(str(GameState.get_event("EV02").get("flavor")), "Ishikari Benten Shrine")
	DataDB.use_protagonist("PC04")
	assert_string_contains(str(GameState.get_event("EV19").get("flavor")), "Noheji", "{office_city}")


func test_no_token_is_left_on_screen_for_any_protagonist() -> void:
	for pid: String in ["PC04", "PC02", "PC03", "PC01"]:
		DataDB.use_protagonist(pid)
		for event: Dictionary in DataDB.events:
			for field: String in ["title", "flavor"]:
				assert_false(str(event.get(field, "")).contains("{place:") or str(event.get(field, "")).contains("{office_city}"), "%s %s for %s" % [event["event_id"], field, pid])
		for choice: Dictionary in DataDB.event_choices:
			for field: String in ["choice_text", "result_text", "promise_kept_text"]:
				var text := str(choice.get(field, "")) if choice.get(field) != null else ""
				assert_false(text.contains("{place:") or text.contains("{office_city}"), "%s %s for %s" % [choice["event_id"], field, pid])


func test_an_event_that_needs_a_place_is_not_drawn_where_the_district_lacks_it() -> void:
	var ctx := GameState.event_context()
	ctx["district"] = 100
	ctx["national"] = 100
	ctx["dues_owed"] = 1
	ctx["office"] = Offices.DISTRICT
	ctx["place_types"] = ["harbor", "school"]
	for event: Dictionary in EventEngine.eligible_random(DataDB.events, ctx):
		for kind: Variant in event.get("needs_place", []) if event.get("needs_place") is Array else []:
			assert_true(["harbor", "school"].has(str(kind)), "%s needs %s" % [event["event_id"], kind])
	ctx["place_types"] = []
	for event: Dictionary in EventEngine.eligible_random(DataDB.events, ctx):
		assert_false(event.get("needs_place") is Array and not (event["needs_place"] as Array).is_empty(), "%s needs a place" % event["event_id"])


func test_the_events_with_tokens_each_list_what_they_need() -> void:
	var with_tokens := 0
	for event: Dictionary in DataDB.events:
		if event.get("needs_place") is Array and not (event["needs_place"] as Array).is_empty():
			with_tokens += 1
	assert_eq(with_tokens, 27, "27 events ask for place types")


func test_aomori_block_3_names_misawa_tohoku_and_shichinohe() -> void:
	# Cameron confirmed on 2026-11-20 that all three lie inside the block (PC04's district).
	var names := PlaceTokens.names_by_type(DataDB.places, "PC04")
	assert_true((names["town_hall"] as Array).has("Misawa City Hall"))
	assert_true((names["town_hall"] as Array).has("Shichinohe Town Hall"))
	assert_true((names["town_hall"] as Array).has("Tohoku Town Office"))
