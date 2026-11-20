extends GutTest
## Two offices, slice 1 (2026-11-20): where a thing can be started, what a trip costs, and when it is refused.

func test_a_tag_is_one_of_three_words() -> void:
	assert_eq(Offices.normalize("Capitol"), Offices.CAPITOL)
	assert_eq(Offices.normalize("District"), Offices.DISTRICT)
	assert_eq(Offices.normalize(""), Offices.EITHER, "blank means Either")
	assert_eq(Offices.normalize(null), Offices.EITHER)
	assert_eq(Offices.normalize("Mars"), Offices.EITHER)


func test_either_is_reachable_from_both_offices() -> void:
	assert_true(Offices.is_here("Either", Offices.CAPITOL))
	assert_true(Offices.is_here("Either", Offices.DISTRICT))
	assert_true(Offices.is_here(null, Offices.DISTRICT))
	assert_true(Offices.is_here("Capitol", Offices.CAPITOL))
	assert_false(Offices.is_here("Capitol", Offices.DISTRICT))
	assert_false(Offices.is_here("District", Offices.CAPITOL))


func test_an_odd_number_of_trips_ends_at_the_other_office() -> void:
	assert_eq(Offices.end_office(Offices.CAPITOL, 2), Offices.CAPITOL)
	assert_eq(Offices.end_office(Offices.DISTRICT, 1), Offices.CAPITOL)
	assert_eq(Offices.end_office(Offices.CAPITOL, 0), Offices.CAPITOL)


func test_the_settled_hours_are_in_the_balance() -> void:
	var b := DataDB.balance
	assert_eq(Travel.hours(b, "PC01", Travel.PASS), 7, "Noheji by train")
	assert_eq(Travel.hours(b, "PC01", Travel.PLANE), 2, "PC01's fast mode is a plane ticket")
	assert_eq(Travel.hours(b, "PC01", Travel.CAR), -1, "PC01 has no private car")
	assert_eq(Travel.hours(b, "PC02", Travel.PASS), 1)
	assert_eq(Travel.hours(b, "PC03", Travel.CAR), 1)
	assert_eq(Travel.hours(b, "PC04", Travel.PASS), 6, "Daikoki by train")
	assert_eq(Travel.hours(b, "PC04", Travel.CAR), 4)
	assert_eq(Travel.hours(b, "PC04", Travel.TICKET), 6, "the paid ticket takes the train's hours")


func test_each_protagonist_has_one_fast_mode() -> void:
	assert_eq(Travel.fast_mode(DataDB.balance, "PC01"), Travel.PLANE)
	for pid: String in ["PC02", "PC03", "PC04"]:
		assert_eq(Travel.fast_mode(DataDB.balance, pid), Travel.CAR, pid)


func test_a_mixed_levels_trips_add_their_hours() -> void:
	var level := {"travel_trips": 2}
	assert_eq(Travel.level_hours(level, DataDB.balance, "PC01", Travel.PASS), 14, "a round trip from Noheji")
	assert_eq(Travel.level_hours(level, DataDB.balance, "PC04", Travel.PASS), 12)
	assert_eq(Travel.level_hours(level, DataDB.balance, "PC03", Travel.PASS), 2)
	assert_eq(Travel.level_hours(level, DataDB.balance, "PC01", Travel.PLANE), 4)
	assert_eq(Travel.level_hours({"travel_trips": 1}, DataDB.balance, "PC04", Travel.CAR), 4)
	assert_eq(Travel.level_hours({}, DataDB.balance, "PC01", Travel.PASS), 0, "no trips, no hours")
	assert_eq(Travel.level_hours({"travel_trips": null}, DataDB.balance, "PC01", Travel.PASS), 0)


func test_the_levels_are_tagged_and_the_trips_make_sense() -> void:
	var counts := {"Capitol": 0, "District": 0, "Either": 0}
	var with_trips := 0
	for level: Dictionary in DataDB.levels:
		var office := Offices.normalize(level.get("location"))
		counts[office] += 1
		var trips := Travel.level_trips(level)
		if trips > 0:
			with_trips += 1
			assert_ne(office, Offices.EITHER, "%s has trips but no office" % level["level_id"])
	assert_eq(counts, {"Capitol": 80, "District": 29, "Either": 5})
	assert_eq(with_trips, 24, "24 mixed levels")
	for lid: String in ["LV12", "LV61", "LV62"]:
		var level := DataDB.get_level(lid)
		assert_eq(Offices.normalize(level.get("location")), Offices.DISTRICT, lid)
		assert_eq(Travel.level_trips(level), 1, "%s ends at the Capitol" % lid)
	for lid: String in ["LV10", "LV21", "LV28"]:
		assert_eq(Offices.normalize(DataDB.get_level(lid).get("location")), Offices.CAPITOL, lid)
	assert_eq(Offices.normalize(DataDB.get_level("LV83").get("location")), Offices.DISTRICT, "the Town Hall crisis")
	assert_eq(Offices.normalize(DataDB.get_level("LV84").get("location")), Offices.CAPITOL, "the Steering Committee")


func test_no_mixed_level_passes_forty_hours_with_its_trips() -> void:
	# The audit's concern: a level must end within the 40-hour week. PC01's seven-hour train is the worst case.
	var over: Array[String] = []
	for level: Dictionary in DataDB.levels:
		for pid: String in ["PC01", "PC04"]:
			var rooms := GameState.level_hours(level)
			var total := rooms + Travel.level_hours(level, DataDB.balance, pid, Travel.PASS)
			if total > 40:
				over.append("%s %s %d" % [pid, level["level_id"], total])
	# LV10 (27 hours) with a 14-hour round trip is 41 for PC01 by train: it needs the plane ticket (4 hours).
	assert_eq(over, ["PC01 LV10 41"] as Array[String])


func test_a_trip_is_refused_in_a_level_at_the_weekend_or_with_too_few_hours() -> void:
	var ok := {"in_level": false, "weekend": false, "travel_at_weekend": false, "hours_left": 8, "trip_hours": 7}
	assert_eq(Travel.refusal(ok), "")
	var in_level := ok.duplicate()
	in_level["in_level"] = true
	assert_eq(Travel.refusal(in_level), Travel.REFUSE_IN_LEVEL)
	var weekend := ok.duplicate()
	weekend["weekend"] = true
	assert_eq(Travel.refusal(weekend), Travel.REFUSE_WEEKEND)
	weekend["travel_at_weekend"] = true
	assert_eq(Travel.refusal(weekend), "", "a house rule can allow weekend trips")
	var short := ok.duplicate()
	short["hours_left"] = 6
	assert_eq(Travel.refusal(short), Travel.REFUSE_HOURS)
