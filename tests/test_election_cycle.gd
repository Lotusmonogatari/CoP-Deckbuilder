extends GutTest
## The election calendar (P20, 2026-11-26): phases around all three cycles, the rehire window and the day the run ends.

func _d(text: String) -> int:
	return WeekCalendar.parse_date(text)


func _phase(text: String) -> String:
	return str(ElectionCycle.phase_on(_d(text), DataDB.election_cycles)["phase"])


func test_the_three_cycles_are_in_the_data() -> void:
	assert_eq(DataDB.election_cycles.size(), 3)
	assert_eq(DataDB.election_cycles[0]["banners_date"], "21.10.11")
	assert_eq(DataDB.election_cycles[1]["election_day"], "24.12.08")
	assert_eq(DataDB.election_cycles[2]["player_runs"], "N")


func test_long_before_the_banners_it_is_building_for_the_cycle_ahead() -> void:
	var info := ElectionCycle.phase_on(_d("18.10.01"), DataDB.election_cycles)
	assert_eq(info, {"cycle_id": "EC01", "phase": "building", "player_runs": true})
	assert_eq(_phase("21.10.10"), "building", "the day before the Banners date")


func test_first_cycle_phase_boundaries() -> void:
	assert_eq(_phase("21.10.11"), "announcement", "the Banners date itself")
	assert_eq(_phase("21.10.12"), "mustering")
	assert_eq(_phase("21.11.29"), "mustering", "the day before Campaign Open")
	assert_eq(_phase("21.11.30"), "campaign")
	assert_eq(_phase("21.12.11"), "campaign", "the day before Election Day")
	assert_eq(_phase("21.12.12"), "election_day")
	assert_eq(ElectionCycle.phase_on(_d("21.12.12"), DataDB.election_cycles)["cycle_id"], "EC01")


func test_after_an_election_the_next_cycle_is_ahead_and_it_is_building() -> void:
	var info := ElectionCycle.phase_on(_d("21.12.13"), DataDB.election_cycles)
	assert_eq(info["cycle_id"], "EC02")
	assert_eq(info["phase"], "building")


func test_second_and_third_cycle_boundaries() -> void:
	assert_eq(_phase("24.10.07"), "announcement")
	assert_eq(_phase("24.11.26"), "campaign")
	assert_eq(_phase("24.12.08"), "election_day")
	assert_eq(_phase("27.10.11"), "announcement")
	assert_eq(_phase("27.11.30"), "campaign")
	assert_eq(_phase("27.12.12"), "election_day")


func test_the_player_does_not_run_in_the_last_cycle() -> void:
	assert_true(ElectionCycle.phase_on(_d("24.12.08"), DataDB.election_cycles)["player_runs"])
	assert_false(ElectionCycle.phase_on(_d("27.11.01"), DataDB.election_cycles)["player_runs"])
	assert_eq(ElectionCycle.run_end_date(DataDB.election_cycles), _d("27.12.12"))


func test_after_the_last_election_there_is_no_cycle_ahead() -> void:
	assert_eq(ElectionCycle.phase_on(_d("28.01.01"), DataDB.election_cycles), {"cycle_id": "", "phase": "building", "player_runs": true})


func test_mustering_starts_on_the_announcement_day() -> void:
	assert_true(ElectionCycle.is_mustering("announcement"))
	assert_true(ElectionCycle.is_mustering("mustering"))
	assert_false(ElectionCycle.is_mustering("building"))
	assert_false(ElectionCycle.is_mustering("campaign"))
	assert_true(ElectionCycle.is_campaign("campaign"))
	assert_true(ElectionCycle.is_campaign("election_day"))
	assert_false(ElectionCycle.is_campaign("mustering"))


func test_the_rehire_window_opens_on_the_first_of_january() -> void:
	assert_false(ElectionCycle.is_rehire_window(_d("21.12.12"), DataDB.election_cycles), "Election Day itself")
	assert_false(ElectionCycle.is_rehire_window(_d("21.12.31"), DataDB.election_cycles))
	assert_true(ElectionCycle.is_rehire_window(_d("22.01.01"), DataDB.election_cycles))
	assert_true(ElectionCycle.is_rehire_window(_d("23.06.01"), DataDB.election_cycles), "and it stays open until the next election")
	assert_false(ElectionCycle.is_rehire_window(_d("18.10.01"), DataDB.election_cycles), "before any election")


func test_hiring_is_blocked_from_the_day_after_an_election_to_the_end_of_that_year() -> void:
	assert_false(ElectionCycle.hiring_blocked(_d("21.12.12"), DataDB.election_cycles), "Election Day: still allowed")
	assert_true(ElectionCycle.hiring_blocked(_d("21.12.13"), DataDB.election_cycles))
	assert_true(ElectionCycle.hiring_blocked(_d("21.12.31"), DataDB.election_cycles))
	assert_false(ElectionCycle.hiring_blocked(_d("22.01.01"), DataDB.election_cycles))
	assert_true(ElectionCycle.is_day_after_election(_d("21.12.13"), DataDB.election_cycles))
	assert_false(ElectionCycle.is_day_after_election(_d("21.12.14"), DataDB.election_cycles))


func test_rows_with_bad_dates_are_left_out() -> void:
	var bad := [{"cycle_id": "X", "banners_date": "21.13.40", "campaign_open_date": "21.11.30", "election_day": "21.12.12", "player_runs": "Y"}]
	assert_eq(ElectionCycle.normalized(bad), [])
