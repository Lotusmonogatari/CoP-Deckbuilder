extends GutTest
## Special Levels (2026-10-18): the Town Hall and Steering Committee crisis
## triggers start a countdown on the game clock; the level then sits at the top
## of the level list, and is forced in after the next ordinary level.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = {
		"meta": GameState.meta.duplicate(true), "runner": GameState.level_runner,
		"mid": GameState.mid_stage, "stakeholders": DataDB.party_stakeholders,
		"delay": DataDB.balance.get("special_level_delay"),
	}
	DataDB.party_stakeholders = []
	DataDB.balance["special_level_delay"] = 5
	GameState.reset_crisis_triggers()


func after_each() -> void:
	GameState.meta = _saved["meta"].duplicate(true)
	GameState.level_runner = _saved["runner"]
	GameState.mid_stage = _saved["mid"]
	DataDB.party_stakeholders = _saved["stakeholders"]
	DataDB.balance["special_level_delay"] = _saved["delay"]
	GameState.reset_crisis_triggers()


func _ordinary_level(stage_count: int) -> void:
	var stages: Array = []
	for i in stage_count:
		stages.append({"seq": i + 1, "stage_id": "ST02", "name_en": "S%d" % i,
			"opponents": [{"opp_id": "A"}]})
	GameState.begin_level(LevelRunner.new({"level_id": "TEST", "stages": stages}))


func test_the_real_data_has_one_special_level_per_trigger() -> void:
	assert_eq(SpecialLevels.level_for("Town Hall", DataDB.levels).get("level_id"), "LV83")
	assert_eq(SpecialLevels.level_for("Steering Committee", DataDB.levels).get("level_id"), "LV84")
	for level: Dictionary in DataDB.levels:
		if SpecialLevels.is_special(level):
			var expanded := BattleSetup.expand_level(level)
			assert_true(LevelRunner.new(expanded).is_valid(), "%s should start" % level.get("level_id"))


func test_a_special_level_is_due_only_after_the_delay_has_run() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 50
	_ordinary_level(8)
	GameState.finish_stage(LevelRunner.WON)   # clock 1; countdown starts here
	assert_true(GameState.due_special_levels().is_empty())
	for i in 4:
		GameState.finish_stage(LevelRunner.WON)
	assert_true(GameState.due_special_levels().is_empty(), "four more units is not five")
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.due_special_levels(), ["Town Hall"])


func test_both_come_due_town_hall_first() -> void:
	var armed := {"Steering Committee": {"armed_at": 0}, "Town Hall": {"armed_at": 0}}
	assert_eq(SpecialLevels.due(armed, 5, 5), ["Town Hall", "Steering Committee"])
	assert_eq(SpecialLevels.due(armed, 4, 5), [])


func test_a_due_special_level_is_forced_after_the_next_ordinary_level() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	_ordinary_level(1)
	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.special_forced)
	var forced := GameState.take_forced_special()
	assert_eq(forced.get("level_id"), "LV83")
	assert_false(GameState.special_forced, "taking it forgets the order")
	assert_true(GameState.take_forced_special().is_empty())


func test_a_special_level_that_is_not_yet_due_is_not_forced() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 9}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	_ordinary_level(1)
	GameState.finish_stage(LevelRunner.WON)
	assert_false(GameState.special_forced)
	assert_true(GameState.special_levels.has("Town Hall"))


func test_playing_a_special_level_clears_it_win_or_lose_and_forces_nothing() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}, "Steering Committee": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 50
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV83")))
	GameState.begin_level(runner)
	while not runner.is_finished():
		GameState.finish_stage(LevelRunner.LOST)
	assert_false(GameState.special_levels.has("Town Hall"))
	assert_true(GameState.special_levels.has("Steering Committee"), "the other one waits")
	assert_false(GameState.special_forced, "only an ordinary level forces one in")


func test_abandoning_a_special_level_leaves_it_waiting() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV83"))))
	GameState.abandon_level()
	assert_true(GameState.special_levels.has("Town Hall"))


func test_the_special_level_state_is_saved() -> void:
	assert_true("special_levels" in GameState._SAVED_FIELDS)
	assert_true("special_forced" in GameState._SAVED_FIELDS)


# ---------------------------------------------------------------------------
# A crisis that recovers cancels its waiting level (2026-11-19, Cameron)
# ---------------------------------------------------------------------------

func test_recovery_before_the_delay_drops_the_countdown() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 50
	GameState.check_crisis_triggers()
	assert_true(GameState.special_levels.has("Town Hall"), "falling in starts the countdown")

	GameState.meta["Constituency support"] = 40
	GameState.check_crisis_triggers()
	assert_false(GameState.special_levels.has("Town Hall"), "climbing out drops it")
	assert_true(GameState.due_special_levels().is_empty())


func test_recovery_after_it_is_due_removes_it_from_the_list_and_the_forced_start() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 50
	GameState.check_crisis_triggers()
	GameState.time_units = 20
	assert_eq(GameState.due_special_levels(), ["Town Hall"], "due by now")
	GameState.special_forced = true

	GameState.meta["Constituency support"] = 40
	GameState.check_crisis_triggers()

	assert_true(GameState.due_special_level_rows().is_empty(), "no longer at the top of the level list")
	assert_false(GameState.special_forced, "nothing left to force in")
	assert_true(GameState.take_forced_special().is_empty())


func test_the_steering_committee_is_cancelled_the_same_way() -> void:
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 10
	GameState.check_crisis_triggers()
	assert_true(GameState.special_levels.has("Steering Committee"))

	GameState.meta["Party support"] = 60
	GameState.check_crisis_triggers()
	assert_false(GameState.special_levels.has("Steering Committee"))


func test_recovery_cancels_only_its_own_level() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 10
	GameState.check_crisis_triggers()
	GameState.time_units = 20
	GameState.special_forced = true

	GameState.meta["Constituency support"] = 40
	GameState.check_crisis_triggers()

	assert_false(GameState.special_levels.has("Town Hall"))
	assert_true(GameState.special_levels.has("Steering Committee"), "the other crisis still stands")
	assert_true(GameState.special_forced, "and is still forced in")


func test_a_crisis_that_comes_back_starts_a_fresh_countdown() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 50
	GameState.check_crisis_triggers()
	GameState.meta["Constituency support"] = 40
	GameState.check_crisis_triggers()
	GameState.time_units = 30
	GameState.meta["Constituency support"] = 10
	GameState.check_crisis_triggers()
	assert_eq(int((GameState.special_levels["Town Hall"] as Dictionary)["armed_at"]), 30,
		"the new countdown runs from when it fell in again")
	assert_true(GameState.due_special_levels().is_empty())


func test_a_special_level_in_play_whose_meter_recovers_ends_cleanly() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.town_hall_active = true
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 50
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV83")))
	GameState.begin_level(runner)
	while not runner.is_finished():
		GameState.finish_stage(LevelRunner.WON)
	assert_false(GameState.special_levels.has("Town Hall"))
	assert_false(GameState.special_forced)


# ---------------------------------------------------------------------------
# A crisis overrides a full week (decided 2026-11-19, Cameron): pinned so a
# later change to this is deliberate.
# ---------------------------------------------------------------------------

func test_a_due_crisis_is_forced_even_when_the_work_week_is_full() -> void:
	var pool := WeekCalendar.pool_hours(WeekCalendar.WORK, GameState.calendar_config())
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": pool}
	GameState.special_levels = {"Town Hall": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	_ordinary_level(1)
	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.work_week_is_full())
	var forced := GameState.take_forced_special()
	assert_eq(forced.get("level_id"), "LV83", "it is still forced in")
	assert_ne(GameState.level_calendar_refusal(forced), "",
		"an ordinary level this long would be refused; the crisis is not asked")


func test_a_crisis_in_a_full_week_is_free_the_hours_stop_at_the_cap() -> void:
	var cfg := GameState.calendar_config()
	var pool := WeekCalendar.pool_hours(WeekCalendar.WORK, cfg)
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": pool}
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 50
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV83")))
	GameState.begin_level(runner)
	while not runner.is_finished():
		GameState.finish_stage(LevelRunner.WON)
	assert_eq(int(GameState.calendar["hours"]), pool, "overflow hours are not charged")


# ---------------------------------------------------------------------------
# The crisis warning survives closing the app (2026-11-19)
# ---------------------------------------------------------------------------

func test_the_crisis_warning_is_saved() -> void:
	assert_true("pending_trigger_alerts" in GameState._SAVED_FIELDS)
	var before: Array[Dictionary] = GameState.pending_trigger_alerts.duplicate(true)
	GameState.pending_trigger_alerts.assign([{"kind": "town_hall", "edge": "entered", "count": 12}])
	var saved: Array = GameState.to_save()["pending_trigger_alerts"]
	assert_eq(saved.size(), 1)
	assert_eq(int((saved[0] as Dictionary)["count"]), 12)
	GameState.pending_trigger_alerts.assign(before)
	# The full save-file round trip is in test_save_load.gd.
