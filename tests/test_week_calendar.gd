extends GutTest
## The week calendar (2026-10-23): hours pooled into a work week and an
## optional weekend, hours past a pool lost, dates from 1 October 2018.

var _cfg := WeekCalendar.settings({})


func test_the_run_starts_on_monday_the_first_of_october_2018() -> void:
	assert_eq(WeekCalendar.date_text(WeekCalendar.fresh(), _cfg), "18.10.01")


func test_hours_pool_across_the_work_week() -> void:
	var state := WeekCalendar.advance(WeekCalendar.fresh(), 10, _cfg)
	assert_eq(WeekCalendar.day_index(state, _cfg), 1, "10 hours reaches Tuesday")
	assert_eq(WeekCalendar.hours_left_today(state, _cfg), 6)
	assert_eq(WeekCalendar.date_text(state, _cfg), "18.10.02")


func test_a_stage_that_runs_past_a_day_spills_into_the_next() -> void:
	var state := WeekCalendar.advance(WeekCalendar.fresh(), 6, _cfg)
	state = WeekCalendar.advance(state, 4, _cfg)
	assert_eq(WeekCalendar.day_index(state, _cfg), 1)
	assert_eq(WeekCalendar.hours_left_today(state, _cfg), 6)


func test_hours_past_the_work_week_are_lost() -> void:
	var state := WeekCalendar.advance(WeekCalendar.fresh(), 100, _cfg)
	assert_eq(int(state["hours"]), 40)
	assert_true(WeekCalendar.is_full(state, _cfg))
	assert_eq(WeekCalendar.hours_left_today(state, _cfg), 0)
	assert_eq(WeekCalendar.date_text(state, _cfg), "18.10.05", "stays on Friday")


func test_the_week_can_be_ended_early_only_on_friday() -> void:
	var tuesday := WeekCalendar.advance(WeekCalendar.fresh(), 12, _cfg)
	assert_false(WeekCalendar.can_end_work_week_early(tuesday, _cfg))
	var friday := WeekCalendar.advance(WeekCalendar.fresh(), 34, _cfg)
	assert_true(WeekCalendar.can_end_work_week_early(friday, _cfg))
	var full := WeekCalendar.advance(WeekCalendar.fresh(), 40, _cfg)
	assert_false(WeekCalendar.can_end_work_week_early(full, _cfg), "nothing left to end early")


func test_ending_the_work_week_starts_the_weekend_and_reports_skipped_hours() -> void:
	var friday := WeekCalendar.advance(WeekCalendar.fresh(), 34, _cfg)
	var moved := WeekCalendar.end_work_week(friday, _cfg)
	assert_eq(int(moved["skipped"]), 6)
	var weekend: Dictionary = moved["state"]
	assert_eq(str(weekend["phase"]), WeekCalendar.WEEKEND)
	assert_eq(WeekCalendar.date_text(weekend, _cfg), "18.10.06", "Saturday")
	assert_eq(WeekCalendar.hours_left_today(weekend, _cfg), 4)


func test_sunday_is_the_second_weekend_day() -> void:
	var weekend: Dictionary = WeekCalendar.end_work_week(WeekCalendar.fresh(), _cfg)["state"]
	weekend = WeekCalendar.advance(weekend, 5, _cfg)
	assert_eq(WeekCalendar.date_text(weekend, _cfg), "18.10.07")
	assert_eq(WeekCalendar.hours_left_today(weekend, _cfg), 3)


func test_going_home_starts_next_monday() -> void:
	var weekend: Dictionary = WeekCalendar.end_work_week(WeekCalendar.fresh(), _cfg)["state"]
	var moved := WeekCalendar.go_home(weekend, _cfg)
	assert_eq(int(moved["skipped"]), 8, "an unplayed weekend still passes")
	assert_eq(WeekCalendar.date_text(moved["state"], _cfg), "18.10.08")
	assert_eq(str((moved["state"] as Dictionary)["phase"]), WeekCalendar.WORK)


func test_weekend_takes_only_flagged_levels_that_fit() -> void:
	var weekend: Dictionary = WeekCalendar.end_work_week(WeekCalendar.fresh(), _cfg)["state"]
	assert_eq(WeekCalendar.level_refusal(weekend, _cfg, 2, true), "")
	assert_eq(WeekCalendar.level_refusal(weekend, _cfg, 2, false), WeekCalendar.REFUSE_NOT_WEEKEND)
	assert_eq(WeekCalendar.level_refusal(weekend, _cfg, 9, true), WeekCalendar.REFUSE_TOO_LONG)


func test_weekdays_take_any_level_until_the_week_is_full() -> void:
	assert_eq(WeekCalendar.level_refusal(WeekCalendar.fresh(), _cfg, 35, false), "")
	var full := WeekCalendar.advance(WeekCalendar.fresh(), 40, _cfg)
	assert_eq(WeekCalendar.level_refusal(full, _cfg, 2, true), WeekCalendar.REFUSE_WEEK_OVER)


func test_a_year_boundary_rolls_the_date_over() -> void:
	var cfg := WeekCalendar.settings({"calendar_start_year": 2018, "calendar_start_month": 12, "calendar_start_day": 31})
	var state := WeekCalendar.advance(WeekCalendar.fresh(), 8, cfg)
	assert_eq(WeekCalendar.date_text(state, cfg), "19.01.01")


func test_a_save_without_a_calendar_starts_a_fresh_week() -> void:
	assert_eq(WeekCalendar.normalized(null), WeekCalendar.fresh())
	assert_eq(str(WeekCalendar.normalized({"phase": "nonsense", "hours": -4})["phase"]), WeekCalendar.WORK)


func test_the_weekday_follows_the_date() -> void:
	# 2018-10-01 was a Monday; Sunday is 0.
	assert_eq(WeekCalendar.weekday_index(WeekCalendar.fresh(), _cfg), 1)
	var state := WeekCalendar.fresh()
	state["phase"] = WeekCalendar.WEEKEND
	assert_eq(WeekCalendar.weekday_index(state, _cfg), 6, "the first weekend day is a Saturday")


func test_exactly_one_hour_is_written_in_the_singular() -> void:
	var phrase := Phrase.new(DataDB.strings)
	assert_eq(phrase.say("event.hours_line", {"hours": 1, "count": 1}), "It took 1 hour.")
	assert_eq(phrase.say("event.hours_line", {"hours": 2, "count": 2}), "It took 2 hours.")
	assert_eq(phrase.say("calendar.hours_work", {"hours": 1, "count": 1}), "1 Work Hour")
	assert_eq(phrase.say("calendar.hours_work", {"hours": 8, "count": 8}), "8 Work Hours")
	assert_eq(phrase.say("calendar.hours_weekend", {"hours": 1, "count": 1}), "1 Weekend Hour")
	assert_eq(phrase.say("office.end_work_week_body", {"hours": 1, "count": 1}),
		"You still have 1 work hour this week. End the work week now?")
	assert_eq(phrase.say("event.row_free", {"title": "Tea", "hours": 1, "count": 1}), "Tea (1 hour)")


func test_ymd_dates_parse_the_way_the_square_writes_them() -> void:
	var start := WeekCalendar.today_number(WeekCalendar.fresh(), _cfg)
	assert_eq(WeekCalendar.parse_ymd("18.10.01"), start)
	assert_eq(WeekCalendar.parse_ymd("18.10.32"), -1)
	assert_eq(WeekCalendar.parse_ymd("nonsense"), -1)
