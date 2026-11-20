extends GutTest
## Two offices, slice 1 (2026-11-20): where the player stands, trips and their hours, what a level's office and its
## built-in trips do to the list, the hours and the end of the level, and the saved state.

func before_each() -> void:
	GameState.start_new_run("PC01")
	GameState.calendar = WeekCalendar.fresh()
	GameState.office_location = Offices.CAPITOL
	GameState.level_travel = {}


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.level_travel = {}
	GameState.level_runner = null


func _left() -> int:
	return WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())


func test_a_new_run_starts_at_the_capitol_and_names_its_district_office() -> void:
	assert_eq(GameState.office_location, Offices.CAPITOL)
	assert_eq(GameState.district_office_name(), "Noheji", "PC01 is the Aomori protagonist now")
	GameState.start_new_run("PC04")
	assert_eq(GameState.district_office_name(), "Daikoki")
	GameState.start_new_run("PC03")
	assert_eq(GameState.district_office_name(), "Teine Ward")


func test_a_trip_spends_its_hours_and_crosses_to_the_other_office() -> void:
	var before := _left()
	assert_eq(GameState.travel_refusal(), "")
	assert_true(GameState.travel())
	assert_eq(GameState.office_location, Offices.DISTRICT)
	assert_eq(_left(), before - 7, "seven hours by rail from Noheji")
	assert_true(GameState.travel())
	assert_eq(GameState.office_location, Offices.CAPITOL)
	assert_eq(_left(), before - 14)


func test_a_trip_runs_the_hidden_clock_like_any_hours() -> void:
	var clock := GameState.time_units
	GameState.travel()
	assert_gt(GameState.time_units, clock, "promise deadlines keep running while travelling (Cameron, 2026-11-20)")


func test_a_trip_is_refused_with_a_reason() -> void:
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": 36}
	assert_eq(GameState.travel_refusal(), Text.say("travel.refuse_hours", {"count": 7}))
	assert_false(GameState.travel())
	assert_eq(GameState.office_location, Offices.CAPITOL, "nothing changed")
	GameState.calendar = WeekCalendar.fresh()
	GameState.begin_level(LevelRunner.new({"level_id": "T", "stages": [{"seq": 1, "stage_id": "ST02", "name_en": "S", "opponents": [{"opp_id": "A"}]}]}))
	assert_eq(GameState.travel_refusal(), Text.say("travel.refuse_in_level"))


func test_no_travel_at_the_weekend() -> void:
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WEEKEND, "hours": 0}
	assert_eq(GameState.travel_refusal(), Text.say("travel.refuse_weekend"))


func test_a_level_is_listed_only_at_its_own_office() -> void:
	var capitol := DataDB.get_level("LV05")      # Mixed, Capitol
	var district := DataDB.get_level("LV01")     # Talking with Constituents
	var either := DataDB.get_level("LV02")
	assert_true(GameState.level_at_this_office(capitol))
	assert_false(GameState.level_at_this_office(district))
	assert_true(GameState.level_at_this_office(either))
	assert_eq(GameState.level_office_refusal(district), Text.say("travel.refuse_elsewhere_district"))
	GameState.office_location = Offices.DISTRICT
	assert_false(GameState.level_at_this_office(capitol))
	assert_eq(GameState.level_office_refusal(capitol), Text.say("travel.refuse_elsewhere_capitol"))
	assert_true(GameState.level_at_this_office(district))
	assert_true(GameState.level_at_this_office(either))


func test_a_mixed_levels_trips_are_in_its_hours() -> void:
	var level := DataDB.get_level("LV21")   # Capitol, a town hall in the middle: out and back
	assert_eq(Travel.level_trips(level), 2)
	assert_eq(GameState.level_trip_hours(level), 14, "two seven-hour trips")
	assert_eq(GameState.level_total_hours(level), GameState.level_hours(level) + 14)
	assert_eq(GameState.level_trip_hours(level, Travel.PLANE), 4, "PC01's fast mode is a plane ticket")
	assert_eq(GameState.level_trip_hours(DataDB.get_level("LV01")), 0, "an ordinary level has none")


func test_starting_a_mixed_level_charges_its_trips_and_it_ends_where_it_began() -> void:
	var level := DataDB.get_level("LV21")
	var before := _left()
	GameState.pay_level_travel(level)
	assert_eq(_left(), before - 14)
	assert_eq(GameState.level_travel, {"start": Offices.CAPITOL, "trips": 2})
	GameState.end_level()
	assert_eq(GameState.office_location, Offices.CAPITOL, "out and back")
	assert_true(GameState.level_travel.is_empty())


func test_a_one_trip_level_ends_at_the_other_office() -> void:
	GameState.office_location = Offices.DISTRICT
	var level := DataDB.get_level("LV12")   # starts in the District, finishes at the Capitol
	assert_eq(Travel.level_trips(level), 1)
	GameState.pay_level_travel(level)
	GameState.end_level()
	assert_eq(GameState.office_location, Offices.CAPITOL)


func test_abandoning_a_mixed_level_still_settles_the_office() -> void:
	GameState.office_location = Offices.DISTRICT
	GameState.pay_level_travel(DataDB.get_level("LV62"))
	GameState.abandon_level()
	assert_eq(GameState.office_location, Offices.CAPITOL)


func test_an_ordinary_level_pays_nothing_and_moves_nobody() -> void:
	var before := _left()
	GameState.pay_level_travel(DataDB.get_level("LV05_NOT_A_LEVEL"))
	assert_eq(_left(), before)
	assert_true(GameState.level_travel.is_empty())


func test_the_dated_event_opens_the_week_at_the_capitol() -> void:
	GameState.office_location = Offices.DISTRICT
	var before := _left()
	assert_true(GameState.arrive_for_event(GameState.get_event("EV47")))
	assert_eq(GameState.office_location, Offices.CAPITOL)
	assert_eq(_left(), before, "a forced move costs no hours (Balance: Travel Forced Hours is 0)")
	assert_false(GameState.arrive_for_event(GameState.get_event("EV47")), "already there")
	assert_false(GameState.arrive_for_event(GameState.get_event("EV01")), "an untagged event moves nobody")


func test_where_the_player_stands_is_saved() -> void:
	GameState.office_location = Offices.DISTRICT
	GameState.level_travel = {"start": Offices.DISTRICT, "trips": 1}
	var saved := GameState.to_save()
	GameState.office_location = Offices.CAPITOL
	GameState.level_travel = {}
	GameState.load_save(saved)
	assert_eq(GameState.office_location, Offices.DISTRICT)
	assert_eq(GameState.level_travel, {"start": Offices.DISTRICT, "trips": 1})


func test_an_old_save_without_an_office_loads_at_the_capitol() -> void:
	var saved := GameState.to_save()
	saved.erase("office_location")
	saved.erase("level_travel")
	GameState.office_location = Offices.DISTRICT
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.office_location, Offices.CAPITOL)


func test_the_calendar_refusal_counts_a_mixed_levels_trips() -> void:
	# LV10 is 27 hours; PC01 by rail adds 14 (41): too long for any week. With the plane it is 31.
	var level := DataDB.get_level("LV10")
	assert_eq(GameState.level_calendar_refusal(level), Text.say("calendar.refuse_too_long"))
	assert_eq(GameState.level_calendar_refusal(level, Travel.PLANE), "")


func test_the_district_offices_share_one_pin_set() -> void:
	var shared: Dictionary = DataDB.art["office_hotspots"]["DISTRICT_OFFICE"]
	GameState.office_location = Offices.DISTRICT
	for pid: String in ["PC01", "PC02", "PC03", "PC04"]:
		GameState.protagonist_id = pid
		assert_eq(RoomObjects.hotspots(), shared, "the same pins in all four District offices (Cameron, 2026-11-20)")
	GameState.protagonist_id = "PC01"
	GameState.office_location = Offices.CAPITOL
	assert_eq(RoomObjects.hotspots(), DataDB.art["office_hotspots"]["OFFICE"], "the Capitol keeps its own")
