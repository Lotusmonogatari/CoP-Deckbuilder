extends GutTest
## The week calendar (2026-10-23): hours pooled into a work week and an
## optional weekend, hours past a pool lost, dates from 1 October 2018.

var _cfg := WeekCalendar.settings({})


func test_the_run_starts_on_monday_the_first_of_october_2018() -> void:
	assert_eq(WeekCalendar.date_text(WeekCalendar.fresh(), _cfg), "01.10.18")


func test_hours_pool_across_the_work_week() -> void:
	var state := WeekCalendar.advance(WeekCalendar.fresh(), 10, _cfg)
	assert_eq(WeekCalendar.day_index(state, _cfg), 1, "10 hours reaches Tuesday")
	assert_eq(WeekCalendar.hours_left_today(state, _cfg), 6)
	assert_eq(WeekCalendar.date_text(state, _cfg), "02.10.18")


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
	assert_eq(WeekCalendar.date_text(state, _cfg), "05.10.18", "stays on Friday")


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
	assert_eq(WeekCalendar.date_text(weekend, _cfg), "06.10.18", "Saturday")
	assert_eq(WeekCalendar.hours_left_today(weekend, _cfg), 4)


func test_sunday_is_the_second_weekend_day() -> void:
	var weekend: Dictionary = WeekCalendar.end_work_week(WeekCalendar.fresh(), _cfg)["state"]
	weekend = WeekCalendar.advance(weekend, 5, _cfg)
	assert_eq(WeekCalendar.date_text(weekend, _cfg), "07.10.18")
	assert_eq(WeekCalendar.hours_left_today(weekend, _cfg), 3)


func test_going_home_starts_next_monday() -> void:
	var weekend: Dictionary = WeekCalendar.end_work_week(WeekCalendar.fresh(), _cfg)["state"]
	var moved := WeekCalendar.go_home(weekend, _cfg)
	assert_eq(int(moved["skipped"]), 8, "an unplayed weekend still passes")
	assert_eq(WeekCalendar.date_text(moved["state"], _cfg), "08.10.18")
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
	assert_eq(WeekCalendar.date_text(state, cfg), "01.01.19")


func test_a_save_without_a_calendar_starts_a_fresh_week() -> void:
	assert_eq(WeekCalendar.normalized(null), WeekCalendar.fresh())
	assert_eq(str(WeekCalendar.normalized({"phase": "nonsense", "hours": -4})["phase"]), WeekCalendar.WORK)
