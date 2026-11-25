extends GutTest
## The Sapporo Stage (2026-11-25, Cameron): who is about by weekday and month (VEN04 Wed and Sun, Oct to Dec and Apr to Jul; VEN05 Fri and Sat,
## Aug to Mar), the Stage Events by date, Sit and Listen (1 hour, 3 a day) and Watch the Performance (2 hours, once a day, one of two rewards).

var _real_events: Array


func before_each() -> void:
	_real_events = DataDB.stage_events


func after_each() -> void:
	DataDB.stage_events = _real_events


func _fresh_run() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}


## Moves the calendar to a day with that weekday (0 = Sunday) and month; false when the run has none.
func _go_to_day(weekday: int, month: int) -> bool:
	for week in range(0, 45):
		for day in range(0, 7):
			GameState.calendar = {"week": week, "phase": "work", "hours": day * 8}
			if GameState.weekday_today() == weekday and GameState.current_month() == month:
				return true
	return false


# --- Rules --------------------------------------------------------------------------------------------------------------------------

func test_days_and_months_are_read_with_ranges_and_wrapping() -> void:
	assert_eq(AreaCharacters.days_of("Wed; Sun"), [3, 0] as Array[int])
	assert_eq(AreaCharacters.days_of("fri, SAT"), [5, 6] as Array[int])
	assert_eq(AreaCharacters.months_of("10-12; 4-7"), [10, 11, 12, 4, 5, 6, 7] as Array[int])
	assert_eq(AreaCharacters.months_of("8-12; 1-3"), [8, 9, 10, 11, 12, 1, 2, 3] as Array[int])
	assert_eq(AreaCharacters.months_of("11-2"), [11, 12, 1, 2] as Array[int], "a range may wrap past December")
	assert_eq(AreaCharacters.months_of(null).size(), 0)


func test_vens_schedules_from_the_workbook() -> void:
	var ven04 := DataDB.get_area_character("VEN04")
	var ven05 := DataDB.get_area_character("VEN05")
	assert_true(AreaCharacters.present_on(ven04, 3, 10), "VEN04 on a Wednesday in October")
	assert_true(AreaCharacters.present_on(ven04, 0, 5), "and a Sunday in May")
	assert_false(AreaCharacters.present_on(ven04, 1, 10), "not on a Monday")
	assert_false(AreaCharacters.present_on(ven04, 3, 8), "not in August")
	assert_false(AreaCharacters.present_on(ven04, 3, 2), "nor in February")
	assert_true(AreaCharacters.present_on(ven05, 5, 8), "VEN05 on a Friday in August")
	assert_true(AreaCharacters.present_on(ven05, 6, 3), "and a Saturday in March")
	assert_false(AreaCharacters.present_on(ven05, 5, 5), "not in May")
	assert_false(AreaCharacters.present_on(ven05, 3, 8), "not on a Wednesday")
	assert_true(AreaCharacters.present_on(DataDB.get_area_character("VEN03"), 1, 1), "VEN03 is always there")


func test_stage_events_are_found_by_date_and_a_draft_is_hidden() -> void:
	var events := [{"event_id": "SE1", "date_from": "18.10.10", "date_to": "18.10.20", "performer": "VEN05", "note": null},
		{"event_id": "SE2", "date_from": "18.10.10", "date_to": "18.10.20", "performer": "VEN04", "note": "DRAFT: hidden"},
		{"event_id": "SE3", "date_from": "18.11.01", "date_to": null, "performer": null, "note": null}]
	var day := WeekCalendar.parse_date("18.10.15")
	assert_eq(StageEvents.active(events, day).map(func(e: Dictionary) -> String: return str(e["event_id"])), ["SE1"])
	assert_eq(StageEvents.active(events, WeekCalendar.parse_date("18.12.25")).map(func(e: Dictionary) -> String: return str(e["event_id"])), ["SE3"], "an open end")
	assert_eq(StageEvents.active(events, WeekCalendar.parse_date("18.10.09")).size(), 0)


func test_a_speaker_list_names_whoever_is_about() -> void:
	assert_eq(AreaCharacters.speakers_of("VEN04|VEN05"), ["VEN04", "VEN05"] as Array[String])
	assert_eq(AreaCharacters.speakers_of("area"), ["area"] as Array[String])


# --- In the run ---------------------------------------------------------------------------------------------------------------------

func test_the_performers_follow_the_schedule_and_an_event_adds_its_performer() -> void:
	_fresh_run()
	DataDB.stage_events = []
	assert_true(_go_to_day(3, 10))
	assert_eq(GameState.stage_performers("VN05").map(func(p: Dictionary) -> String: return str(p["character_id"])), ["VEN04"], "Wednesday in October")
	assert_true(_go_to_day(1, 11))
	assert_eq(GameState.stage_performers("VN05").size(), 0, "a Monday in November: nobody")
	DataDB.stage_events = [{"event_id": "SE9", "name": "Festival", "kind": "event", "date_from": GameState.calendar_date_text(), "date_to": GameState.calendar_date_text(),
		"performer": "VEN05", "blurb": "A festival.", "note": null}]
	assert_eq(GameState.stage_performers("VN05").map(func(p: Dictionary) -> String: return str(p["character_id"])), ["VEN05"], "the event's performer, off schedule")
	assert_eq(GameState.stage_events_today().size(), 1)


func test_sit_and_listen_takes_an_hour_three_times_a_day_and_draws_a_line() -> void:
	_fresh_run()
	DataDB.stage_events = []
	assert_true(_go_to_day(1, 11))
	var hours := GameState.work_hours_left()
	for turn in range(3):
		var done := GameState.do_activity("VA05")
		assert_true(bool(done["ok"]), "listen %d: %s" % [turn + 1, str(done.get("reason", ""))])
		assert_false(str((done["heard"] as Dictionary)["text"]).is_empty(), "a line is heard")
	assert_eq(GameState.work_hours_left(), hours - 3, "an hour each")
	assert_eq(GameState.activity_refusal("VA05"), Text.say("venue.refuse_limit"), "three a day")
	assert_true(bool(GameState.venue_activity("VA05").get("per_day") == 3))


func test_sit_and_listen_never_picks_a_performer_who_is_not_about() -> void:
	_fresh_run()
	DataDB.stage_events = []
	assert_true(_go_to_day(1, 11))   # a Monday in November: neither VEN04 nor VEN05
	for turn in range(60):
		var heard := GameState._stage_listen("VN05", "VA05", turn)
		assert_false(["VEN04", "VEN05"].has(str(heard["speaker"])), "%s is not about" % heard["speaker"])


func test_watch_the_performance_needs_a_performer_costs_two_hours_once_a_day() -> void:
	_fresh_run()
	DataDB.stage_events = []
	assert_true(_go_to_day(1, 11))
	assert_eq(GameState.activity_refusal("VA20"), Text.say("stage.no_performer"), "nobody on stage")
	assert_true(_go_to_day(3, 10))
	assert_eq(GameState.activity_refusal("VA20"), "")
	var hours := GameState.work_hours_left()
	var done := GameState.do_activity("VA20")
	assert_true(bool(done["ok"]), str(done.get("reason", "")))
	assert_eq(GameState.work_hours_left(), hours - 2, "two hours")
	assert_eq(str((done["heard"] as Dictionary)["speaker"]), "VEN04", "the performer on stage")
	assert_true(["The crisp notes complement the crisp Sapporo air.", "Even the birds are swaying along to the melody."].has(str((done["heard"] as Dictionary)["text"])),
		"one of the two basic lines: %s" % (done["heard"] as Dictionary)["text"])
	assert_eq(GameState.activity_refusal("VA20"), Text.say("venue.refuse_limit"), "once a day")


func test_the_reward_is_one_of_the_two_and_both_come_up() -> void:
	_fresh_run()
	var activity := GameState.venue_activity("VA20")
	var seen := {}
	for turn in range(40):
		var xp_before := GameState.xp
		var standing_before := [int(GameState.booster_standing.get("BO15", 0)), int(GameState.booster_standing.get("BO27", 0))]
		GameState._give_either(activity, turn)
		var xp_gain := GameState.xp - xp_before
		var gained := [int(GameState.booster_standing.get("BO15", 0)) - standing_before[0], int(GameState.booster_standing.get("BO27", 0)) - standing_before[1]]
		if xp_gain == 50:
			assert_eq(gained, [0, 0], "XP and standing never together")
			seen["xp"] = true
		else:
			assert_eq(xp_gain, 0)
			assert_eq(gained, [1, 1], "+1 to both organizations")
			seen["standing"] = true
	assert_eq(seen.size(), 2, "both outcomes come up over many draws")


func test_the_card_tells_what_it_may_give_before_it_is_done() -> void:
	_fresh_run()
	var lines := GameState.activity_gives_lines(GameState.venue_activity("VA20"))
	assert_eq(lines.size(), 1)
	assert_eq(lines[0], "one of Our Traditional Society +1 and Urban Neighborhood Alliance +1, or XP +50")


func test_the_stage_screen_lists_what_is_on_and_sit_and_listen_stands_someone_over_it() -> void:
	_fresh_run()
	DataDB.stage_events = [{"event_id": "SE9", "name": "Festival", "kind": "event", "date_from": null, "date_to": null, "performer": "VEN05", "blurb": "A festival.",
		"note": null}]
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	office._venues.show_venue("VN05")
	await get_tree().process_frame
	var venue := office.get_node("VenuePanel") as Overlay
	assert_not_null(venue.find_child("StageEvent_SE9", true, false), "the event is on the Stage's screen")
	assert_not_null(venue.find_child("StagePerformer_VEN05", true, false), "and who is on stage")
	assert_not_null(venue.find_child("Activity_VA05", true, false), "Sit and Listen")
	assert_not_null(venue.find_child("Activity_VA20", true, false), "Watch the Performance")
	office._venues._on_do_activity("VA05")
	await get_tree().process_frame
	var line := office.get_node("VenueLinePanel") as Overlay
	assert_true(line.visible, "the line is heard")
	assert_eq((line.find_child("Confirm", true, false) as Button).text, Text.say("stage.back"), "Back to the Stage")
