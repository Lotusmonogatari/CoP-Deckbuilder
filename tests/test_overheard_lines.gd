extends GutTest
## Overheard lines (2026-11-25): the Where cell and how a line fits a place, the pace and its wobble, the weighted draw with the boost for a
## line that names the place, the move counter in the run (saved, reload-safe, a place's own pace), the six sample lines in the data and
## the pop-up that shows one and then opens the place.

var _real_balance: Dictionary
var _real_lines: Array
var _real_people: Array
var _capitol := {"venue_id": "VN01", "zone": "Capitol Building", "overheard_every": null}
var _station := {"venue_id": "VN06", "zone": "Capital Area", "overheard_every": null}
var _ctx := {"today": 100, "month": 4, "seasons": {"Spring": [4, 5], "Winter": [12, 1, 2, 3]}, "meta": {}, "laws": {}, "staff_hired": {}, "heard": {}}


func before_each() -> void:
	_real_balance = DataDB.balance.duplicate()
	_real_lines = DataDB.venue_lines
	_real_people = DataDB.area_characters


func after_each() -> void:
	DataDB.balance = _real_balance
	DataDB.venue_lines = _real_lines
	DataDB.area_characters = _real_people


func _line(id: String, where: String, over: Dictionary = {}) -> Dictionary:
	var row := {"line_id": id, "pool": "overheard", "where": where, "speaker": null, "text": "Line " + id, "weight": null, "once": "N"}
	row.merge(over, true)
	return row


# --- Rules --------------------------------------------------------------------------------------------------------------------------

func test_a_where_cell_splits_on_semicolons_and_commas() -> void:
	assert_eq(OverheardLines.tokens("VN03; VN02, Capital Area"), ["VN03", "VN02", "Capital Area"] as Array[String])
	assert_eq(OverheardLines.tokens(null).size(), 0)


func test_a_line_fits_by_venue_by_zone_or_not_at_all() -> void:
	assert_eq(OverheardLines.fit(_line("a", "VN01"), _capitol), OverheardLines.SPECIFIC)
	assert_eq(OverheardLines.fit(_line("b", "Capitol Building"), _capitol), OverheardLines.ZONE)
	assert_eq(OverheardLines.fit(_line("c", "VN03"), _capitol), OverheardLines.NONE)
	assert_eq(OverheardLines.fit(_line("d", "Capital Area"), _capitol), OverheardLines.NONE)
	assert_eq(OverheardLines.fit(_line("e", "Capitol Building; VN01"), _capitol), OverheardLines.SPECIFIC, "the best fit wins")


func test_the_tracks_are_their_own_place_inside_the_station() -> void:
	var concourse := _line("a", "VN06")
	var tracks := _line("b", "VN06/tracks")
	assert_eq(OverheardLines.fit(concourse, _station, ""), OverheardLines.SPECIFIC)
	assert_eq(OverheardLines.fit(tracks, _station, ""), OverheardLines.NONE, "a tracks line is not heard at the concourse")
	assert_eq(OverheardLines.fit(tracks, _station, "tracks"), OverheardLines.SPECIFIC)
	assert_eq(OverheardLines.fit(concourse, _station, "tracks"), OverheardLines.NONE, "a concourse line is not heard on the tracks")
	assert_eq(OverheardLines.fit(_line("c", "Capital Area"), _station, "tracks"), OverheardLines.ZONE, "a zone line fits either screen")


func test_a_place_may_set_its_own_pace_and_zero_means_never() -> void:
	assert_eq(OverheardLines.pace({"overheard_every": null}, 6), 6)
	assert_eq(OverheardLines.pace({"overheard_every": 2}, 6), 2)
	assert_eq(OverheardLines.pace({"overheard_every": 0}, 6), 0)
	assert_false(OverheardLines.due(99, 0, 2, 1), "never")


func test_the_wait_stays_within_the_wobble_and_is_the_same_for_the_same_seed() -> void:
	var seen := {}
	for seed_value in range(200):
		var wait := OverheardLines.threshold(6, 2, seed_value)
		assert_between(wait, 4, 8)
		seen[wait] = true
		assert_eq(wait, OverheardLines.threshold(6, 2, seed_value))
	assert_eq(seen.size(), 5, "4, 5, 6, 7 and 8 all come up")
	for seed_value in range(50):
		assert_gte(OverheardLines.threshold(1, 3, seed_value), 1)


func test_a_line_naming_the_place_is_drawn_about_five_times_as_often_as_a_zone_line() -> void:
	var lines := [_line("specific", "VN01"), _line("zone", "Capitol Building")]
	var counts := {"specific": 0, "zone": 0}
	for seed_value in range(1200):
		counts[str(OverheardLines.pick(lines, _capitol, "", _ctx, [], 5, seed_value)["line_id"])] += 1
	assert_gt(counts["specific"], counts["zone"] * 3, "with a boost of 5 the specific line wins most draws (%s)" % [counts])
	assert_gt(counts["zone"], 0, "a zone line still comes up sometimes")


func test_recent_lines_are_skipped_unless_nothing_else_fits() -> void:
	var lines := [_line("a", "VN01"), _line("b", "VN01")]
	for seed_value in range(30):
		assert_eq(str(OverheardLines.pick(lines, _capitol, "", _ctx, ["a"], 5, seed_value)["line_id"]), "b")
	assert_false(OverheardLines.pick(lines, _capitol, "", _ctx, ["a", "b"], 5, 1).is_empty(), "when every line is recent one is drawn anyway")
	assert_true(OverheardLines.pick([], _capitol, "", _ctx, [], 5, 1).is_empty())


func test_only_overheard_lines_that_are_in_season_and_fit_the_place_are_drawn() -> void:
	var lines := [_line("winter", "Capitol Building", {"seasons": ["Winter"]}), _line("elsewhere", "Capital Area"),
		_line("cafeteria", "VN01", {"pool": "cafeteria"})]
	assert_true(OverheardLines.pick(lines, _capitol, "", _ctx, [], 5, 1).is_empty(), "April: not winter, wrong zone, wrong pool")
	var winter := _ctx.duplicate()
	winter["month"] = 1
	assert_eq(str(OverheardLines.pick(lines, _capitol, "", winter, [], 5, 1)["line_id"]), "winter")


func test_the_recent_list_keeps_the_last_few() -> void:
	var recent: Array = []
	for id: String in ["a", "b", "c", "d", "e"]:
		recent = OverheardLines.with_recent(recent, id, 4)
	assert_eq(recent, ["b", "c", "d", "e"])


# --- In the run ---------------------------------------------------------------------------------------------------------------------

func _run_with(lines: Array, every: int = 3, wobble: int = 0) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	DataDB.venue_lines = lines
	DataDB.balance["overheard_every"] = every
	DataDB.balance["overheard_wobble"] = wobble


func test_the_shipped_pace_is_six_moves_wobble_two_boost_five() -> void:
	assert_eq(int(DataDB.get_balance("overheard_every", 0)), 6)
	assert_eq(int(DataDB.get_balance("overheard_wobble", 0)), 2)
	assert_eq(int(DataDB.get_balance("overheard_specific_boost", 0)), 5)
	assert_eq(int(DataDB.get_balance("overheard_no_repeat", 0)), 4)


func test_a_line_comes_up_on_the_nth_move_and_the_count_starts_again() -> void:
	_run_with([_line("a", "Capitol Building")], 3, 0)
	assert_true(GameState.overheard_on_move("VN01").is_empty())
	assert_true(GameState.overheard_on_move("VN03").is_empty())
	var heard := GameState.overheard_on_move("VN02")
	assert_eq(str(heard["text"]), "Line a", "the third move")
	assert_eq(GameState.overheard_moves, 0)
	assert_true(GameState.overheard_on_move("VN01").is_empty())


func test_a_place_with_no_fitting_line_keeps_counting_until_one_fits() -> void:
	_run_with([_line("a", "Capital Area")], 2, 0)
	for _move in range(5):
		assert_true(GameState.overheard_on_move("VN01").is_empty(), "no Capitol line exists")
	assert_eq(GameState.overheard_moves, 5, "the count is kept")
	assert_false(GameState.overheard_on_move("VN06").is_empty(), "the next move to a place with a line is due at once")


func test_a_places_own_pace_overrides_the_default() -> void:
	_run_with([_line("a", "Capitol Building")], 3, 0)
	for venue: Dictionary in DataDB.venues:
		if str(venue["venue_id"]) == "VN01":
			venue["overheard_every"] = 0
	assert_true(GameState.overheard_on_move("VN01").is_empty())
	assert_true(GameState.overheard_on_move("VN01").is_empty())
	assert_true(GameState.overheard_on_move("VN01").is_empty(), "never at the Cafeteria")
	for venue: Dictionary in DataDB.venues:
		if str(venue["venue_id"]) == "VN01":
			venue["overheard_every"] = null


func test_the_counter_is_saved_and_a_reload_does_not_change_the_wait() -> void:
	_run_with([_line("a", "Capitol Building")], 6, 2)
	GameState.overheard_on_move("VN01")
	GameState.overheard_on_move("VN01")
	var saved := GameState.to_save()
	var seed_before := GameState.run_seed
	var expected: Array = []
	for _move in range(10):
		expected.append(not GameState.overheard_on_move("VN01").is_empty())
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.run_seed, seed_before)
	assert_eq(GameState.overheard_moves, 2)
	var again: Array = []
	for _move in range(10):
		again.append(not GameState.overheard_on_move("VN01").is_empty())
	assert_eq(again, expected, "the same moves bring the same lines after a reload")


func test_an_old_save_starts_the_counter_at_zero() -> void:
	_run_with([_line("a", "Capitol Building")])
	var saved := GameState.to_save()
	for field: String in ["overheard_moves", "overheard_fired", "overheard_recent"]:
		saved.erase(field)
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.overheard_moves, 0)
	assert_eq(GameState.overheard_recent.size(), 0)


func test_a_once_line_is_not_heard_again() -> void:
	_run_with([_line("a", "Capitol Building", {"once": "Y"})], 1, 0)
	assert_false(GameState.overheard_on_move("VN01").is_empty())
	assert_true(GameState.overheard_on_move("VN01").is_empty(), "heard once, never again")


func test_the_six_sample_lines_are_in_the_data_and_each_can_come_up_in_its_zone() -> void:
	var by_zone := {}
	for row: Dictionary in DataDB.venue_lines:
		if str(row.get("pool", "")) == "overheard":
			assert_eq(str(row["speaker"]), "area", str(row["line_id"]))
			by_zone[str(row["where"])] = int(by_zone.get(str(row["where"]), 0)) + 1
	assert_eq(by_zone, {"Capital Area": 2, "District": 2, "Capitol Building": 2})
	for venue: Dictionary in DataDB.venues:
		var fits := 0
		for row: Dictionary in DataDB.venue_lines:
			if str(row.get("pool", "")) == "overheard" and OverheardLines.fit(row, venue, "") != OverheardLines.NONE:
				fits += 1
		if str(venue["venue_id"]) in ["VN01", "VN04", "VN06", "VN08"]:
			assert_gt(fits, 0, "%s has overheard lines" % venue["name"])


# --- The pop-up ---------------------------------------------------------------------------------------------------------------------

func test_going_to_a_place_on_the_nth_move_shows_the_line_then_continue_opens_the_place() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	DataDB.area_characters = [{"character_id": "CB01", "name": "Passerby", "site": null}]
	DataDB.balance["overheard_every"] = 1
	DataDB.balance["overheard_wobble"] = 0
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	office._venues._go_to("VN01", "")
	var line_panel := office.get_node("VenueLinePanel") as Overlay
	assert_true(line_panel.visible, "the line comes first")
	assert_not_null(line_panel.find_child("VenueScene", true, false), "an area speaker stands over the background")
	assert_false(office.get_node("VenuePanel").visible, "the place is not open yet")
	var confirm := line_panel.find_child("Confirm", true, false) as Button
	assert_eq(confirm.text, Text.say("venue.overheard_continue"))
	assert_false(line_panel.show_back, "no Back: Continue is the way on")
	confirm.pressed.emit()
	await get_tree().process_frame
	assert_true(office.get_node("VenuePanel").visible, "Continue opens the Cafeteria")
	assert_eq(GameState.overheard_moves, 0)
