extends GutTest
## The run's statistics (2026-11-25, Cameron): the tallies (RunStats), the hooks in the run (cards, items, people, promises, venue
## visits, win type), saving and New Game, and the report (StatsReport).


func _fresh_run() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = WeekCalendar.fresh()
	GameState.promises = []


# --- RunStats -------------------------------------------------------------------------------------------------------------------------

func test_bump_counts_and_ignores_blank_keys() -> void:
	var stats := RunStats.fresh()
	RunStats.bump(stats, "suits", "Earnest")
	RunStats.bump(stats, "suits", "Earnest")
	RunStats.bump(stats, "suits", "Appeal", 3)
	RunStats.bump(stats, "suits", "")
	assert_eq(stats["suits"], {"Earnest": 2, "Appeal": 3})
	assert_eq(RunStats.total(stats["suits"]), 5)


func test_ranked_orders_by_count_then_name_and_leaders_include_ties() -> void:
	var counts := {"Beta": 2, "Alpha": 2, "Gamma": 5, "Zero": 0}
	assert_eq(RunStats.ranked(counts), [["Gamma", 5], ["Alpha", 2], ["Beta", 2]])
	assert_eq(RunStats.leaders(counts), ["Gamma"] as Array[String])
	assert_eq(RunStats.leaders({"B": 3, "A": 3, "C": 1}), ["A", "B"] as Array[String])
	assert_eq(RunStats.leaders({}), [] as Array[String])


func test_a_person_in_the_same_scene_is_one_meeting() -> void:
	var stats := RunStats.fresh()
	assert_true(RunStats.note_met(stats, "OP01", "L1/0"))
	assert_false(RunStats.note_met(stats, "OP01", "L1/0"), "shown again in the same stage")
	assert_true(RunStats.note_met(stats, "OP01", "L1/1"), "the next stage is a new meeting")
	assert_true(RunStats.note_met(stats, "OP01", ""), "no scene always counts")
	assert_false(RunStats.note_met(stats, "", "L1/1"))
	assert_eq(stats["met"], {"OP01": 3})


func test_promises_and_wins_are_counted_and_an_unknown_win_kind_is_other() -> void:
	var stats := RunStats.fresh()
	RunStats.note_promise(stats, true)
	RunStats.note_promise(stats, true)
	RunStats.note_promise(stats, false)
	assert_eq(stats["promises"], {"kept": 2, "broken": 1})
	RunStats.note_win(stats, RunStats.KIND_ZERO)
	RunStats.note_win(stats, "")
	RunStats.note_win(stats, "something else")
	assert_eq(stats["wins"], {"threshold": 0, "zero": 1, "other": 2})


func test_normalized_repairs_a_damaged_or_old_save() -> void:
	assert_eq(RunStats.normalized(null), RunStats.fresh())
	assert_eq(RunStats.normalized({}), RunStats.fresh())
	var repaired := RunStats.normalized({"suits": {"Earnest": 4, "Bad": "x"}, "wins": {"zero": 2, "junk": 9}, "venues": "nope"})
	assert_eq(repaired["suits"], {"Earnest": 4})
	assert_eq(repaired["wins"], {"threshold": 0, "zero": 2, "other": 0})
	assert_eq(repaired["venues"], {})


# --- The hooks in the run ------------------------------------------------------------------------------------------------------------

func test_a_new_run_starts_with_nothing_counted() -> void:
	_fresh_run()
	assert_eq(GameState.run_stats, RunStats.fresh())


func test_a_played_card_counts_its_suit() -> void:
	_fresh_run()
	var card: Dictionary = DataDB.cards[0]
	GameState.record_card_played(str(card["card_id"]))
	GameState.record_card_played(str(card["card_id"]))
	assert_eq(GameState.run_stats["suits"], {str(card["suit"]): 2})


func test_going_to_a_venue_counts() -> void:
	_fresh_run()
	GameState.record_venue_visit("VN01")
	GameState.record_venue_visit("VN01")
	GameState.record_venue_visit("VN03")
	assert_eq(GameState.run_stats["venues"], {"VN01": 2, "VN03": 1})


func test_meeting_a_character_counts_once_per_scene_and_still_marks_them_met() -> void:
	_fresh_run()
	GameState.meet_character("OP01")
	GameState.meet_character("OP01")
	assert_true(GameState.met_characters.has("OP01"))
	assert_eq(GameState.run_stats["met"], {"OP01": 2}, "outside a level there is no scene, so each call counts")


func test_keeping_and_breaking_a_promise_are_counted() -> void:
	_fresh_run()
	GameState.promises = [{"id": "P1", "kind": "hours", "hours": 1, "funds": 0, "due_at": GameState.time_units + 500, "made_at": 0,
		"for_org": "", "source": "test", "location": "Either"}]
	assert_eq(GameState.keep_promise("P1"), "")
	assert_eq(GameState.run_stats["promises"]["kept"], 1)
	GameState.promises = [{"id": "P2", "kind": "hours", "hours": 1, "funds": 0, "due_at": 0, "made_at": 0,
		"for_org": "", "source": "test", "location": "Either"}]
	GameState.time_units = 50
	GameState.level_clock_started = -1
	GameState._break_overdue_promises()
	assert_eq(GameState.run_stats["promises"]["broken"], 1)


func test_using_an_item_counts_it() -> void:
	_fresh_run()
	# A dinner or walking tour opens a hosted event (the walking tour is the District's); it counts when it is used.
	GameState.calendar = {"week": 0, "phase": "weekend", "hours": 4}
	GameState.office_location = Offices.DISTRICT
	GameState.inventory["SH20"] = 1
	assert_true(GameState.use_item_in_office("SH20", "BO07")["ok"])
	assert_eq(GameState.run_stats["items"], {"SH20": 1})
	GameState.hosted_session = {}
	# Any other use spends a copy through the same counter.
	GameState.inventory["SH01"] = 2
	GameState._spend_use("SH01")
	GameState._spend_use("SH01")
	assert_eq(GameState.run_stats["items"]["SH01"], 2)


func test_a_stage_win_counts_how_it_was_won() -> void:
	_fresh_run()
	GameState.begin_level(LevelRunner.new({"level_id": "LV_RS", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 2},
		{"seq": 2, "stage_id": "ST05", "mode": "Combat", "time_units": 2}]}))
	GameState.finish_stage(LevelRunner.WON, 10, [], false, 0, [], [], [], {}, RunStats.KIND_ZERO)
	assert_eq(GameState.run_stats["wins"], {"threshold": 0, "zero": 1, "other": 0})
	GameState.finish_stage(LevelRunner.LOST, 0)
	assert_eq(RunStats.total(GameState.run_stats["wins"]), 1, "a loss counts as no win")
	GameState.level_cleared_units.erase("LV_RS")
	GameState.level_last_completed_at.erase("LV_RS")


# --- Saving and New Game ---------------------------------------------------------------------------------------------------------------

func test_the_statistics_survive_a_save_and_an_old_save_loads_with_none() -> void:
	_fresh_run()
	GameState.record_venue_visit("VN02")
	RunStats.bump(GameState.run_stats, "suits", "Earnest", 4)
	var saved := GameState.to_save()
	_fresh_run()
	GameState.load_save(saved)
	assert_eq(GameState.run_stats["venues"], {"VN02": 1})
	assert_eq(GameState.run_stats["suits"], {"Earnest": 4})
	saved.erase("run_stats")
	_fresh_run()
	GameState.load_save(saved)
	assert_eq(GameState.run_stats, RunStats.fresh(), "an older save has no statistics")


func test_a_new_game_clears_the_statistics() -> void:
	_fresh_run()
	GameState.record_venue_visit("VN01")
	GameState.start_new_run("PC01")
	assert_eq(GameState.run_stats, RunStats.fresh())


# --- The report --------------------------------------------------------------------------------------------------------------------------

func test_the_report_names_things_and_says_when_nothing_was_counted() -> void:
	_fresh_run()
	var stats := RunStats.fresh()
	RunStats.bump(stats, "suits", "Earnest", 3)
	RunStats.bump(stats, "suits", "Appeal", 1)
	RunStats.bump(stats, "venues", "VN01", 2)
	RunStats.bump(stats, "met", "OP01", 2)
	RunStats.note_win(stats, RunStats.KIND_THRESHOLD)
	var sections := StatsReport.sections(stats, 5, 1, {"VA01": 4})
	var by_id := {}
	for section: Dictionary in sections:
		by_id[section["id"]] = section
	assert_eq((by_id["suits"] as Dictionary)["rows"], [["Earnest", "3"], ["Appeal", "1"]])
	assert_string_contains(str(by_id["suits"]["note"]), "Earnest")
	assert_eq(by_id["venues"]["rows"][0], [str(GameState.venue_row("VN01").get("name", "")), "2"])
	assert_eq(by_id["activities"]["rows"][0], [str(GameState.venue_activity("VA01").get("name", "")), "4"])
	assert_eq(by_id["people"]["rows"][0], [str(DataDB.get_opponent("OP01").get("name", "OP01")), "2"])
	assert_eq(by_id["gaffes"]["rows"][0][1], "5")
	assert_eq(by_id["wins"]["rows"][0][1], "1")
	assert_true((by_id["items"] as Dictionary)["rows"].is_empty())
	var text := StatsReport.text(sections)
	assert_string_contains(text, Text.say("stats.report_title"))
	assert_string_contains(text, Text.say("stats.nothing"), "the empty Items section says so")
	assert_string_contains(text, "Earnest: 3")


func test_the_report_is_written_and_the_clipboard_filled() -> void:
	var made := StatsReport.export("hello report", 12345)
	assert_true(made["ok"])
	assert_eq(DisplayServer.clipboard_get() if DisplayServer.get_name() != "headless" else "hello report", "hello report")
	var path := "user://".path_join(str(made["file"]))
	assert_eq(FileAccess.get_file_as_string(path), "hello report")
	DirAccess.remove_absolute(path)
