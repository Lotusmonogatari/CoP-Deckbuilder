extends GutTest
## Ticker lines gated to days of the week and date ranges (2026-10-27).

func _facts(date: String, weekday: int) -> Dictionary:
	return {"today": WeekCalendar.parse_ymd(date), "weekday": weekday}


func _row(extra: Dictionary) -> Dictionary:
	var row := {"condition_type": "always", "text_en": "Line."}
	row.merge(extra)
	return row


func test_an_ungated_row_always_passes_even_without_calendar_facts() -> void:
	assert_true(OfficeTicker.calendar_met(_row({}), {}))


func test_a_weekday_row_shows_only_on_its_days() -> void:
	var row := _row({"weekdays": ["Mon", "Friday"]})
	assert_true(OfficeTicker.calendar_met(row, _facts("18.10.01", 1)))
	assert_true(OfficeTicker.calendar_met(row, _facts("18.10.05", 5)))
	assert_false(OfficeTicker.calendar_met(row, _facts("18.10.02", 2)))


func test_a_date_range_is_inclusive_at_both_ends() -> void:
	var row := _row({"from_date": "18.12.24", "to_date": "18.12.26"})
	assert_false(OfficeTicker.calendar_met(row, _facts("18.12.23", 0)))
	assert_true(OfficeTicker.calendar_met(row, _facts("18.12.24", 1)))
	assert_true(OfficeTicker.calendar_met(row, _facts("18.12.26", 3)))
	assert_false(OfficeTicker.calendar_met(row, _facts("18.12.27", 4)))


func test_one_open_ended_bound_works() -> void:
	assert_true(OfficeTicker.calendar_met(_row({"from_date": "18.12.01"}), _facts("19.03.01", 5)))
	assert_false(OfficeTicker.calendar_met(_row({"to_date": "18.12.01"}), _facts("19.03.01", 5)))


func test_a_gated_row_with_no_calendar_facts_stays_quiet() -> void:
	assert_false(OfficeTicker.calendar_met(_row({"weekdays": ["Mon"]}), {}))


func test_days_and_dates_and_the_condition_all_have_to_hold() -> void:
	var row := {"condition_type": "meta", "condition_target": "Funds", "condition_op": ">=",
		"condition_value": 50, "text_en": "Gated.", "weekdays": ["Mon"], "from_date": "18.10.01"}
	var facts := _facts("18.10.01", 1)
	assert_eq(OfficeTicker.eligible_lines([row], {}, {"Funds": 10}, "", facts), [] as Array[String])
	assert_eq(OfficeTicker.eligible_lines([row], {}, {"Funds": 60}, "", facts), ["Gated."] as Array[String])


func test_the_live_facts_carry_today_and_the_weekday() -> void:
	GameState.calendar = WeekCalendar.fresh()
	var facts := GameState.ticker_facts()
	assert_eq(int(facts["today"]), WeekCalendar.parse_ymd("18.10.01"))
	assert_eq(int(facts["weekday"]), 1, "the run starts on a Monday")
