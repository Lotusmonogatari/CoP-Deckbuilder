extends GutTest
## TimeClock.gd and the game clock in GameState (2026-10-18).

var _units_before := 0
var _runner_before: LevelRunner = null
var _interval_before: Variant = null
var _calendar_before: Dictionary = {}
var _awareness_before: Dictionary = {}
var _meta_before: Dictionary = {}
var _party_before: Dictionary = {}
var _owned_before: Array = []


func before_each() -> void:
	_units_before = GameState.time_units
	_interval_before = DataDB.balance.get("decay_interval")
	_calendar_before = GameState.calendar.duplicate()
	_awareness_before = GameState.awareness.duplicate()
	_meta_before = GameState.meta.duplicate()
	_party_before = GameState.party_standing.duplicate()
	_owned_before = GameState.owned_modifiers.duplicate()
	# Neutral awareness, so a week end in these tests applies no awareness effects.
	GameState.awareness = {"district": 60, "national": 50}
	# Decay by hours is off in the shipped data (it runs at week end now); these
	# tests exercise the optional interval path, so they turn it on.
	DataDB.balance["decay_interval"] = 6
	_runner_before = GameState.level_runner
	GameState.time_units = 0


func after_each() -> void:
	GameState.time_units = _units_before
	GameState.calendar = _calendar_before
	GameState.awareness = _awareness_before
	GameState.meta = _meta_before
	GameState.party_standing = _party_before
	GameState.owned_modifiers.assign(_owned_before)
	DataDB.balance["decay_interval"] = _interval_before
	GameState.level_runner = _runner_before


func test_a_blank_time_units_cell_costs_one_unit() -> void:
	assert_eq(TimeClock.units_for_stage({"stage_id": "ST05"}), 1)
	assert_eq(TimeClock.units_for_stage({"time_units": null}), 1)


func test_a_stage_can_cost_more_or_nothing() -> void:
	assert_eq(TimeClock.units_for_stage({"time_units": 3}), 3)
	assert_eq(TimeClock.units_for_stage({"time_units": 0}), 0)
	assert_eq(TimeClock.units_for_stage({"time_units": -2}), 0)


func test_a_countdown_has_elapsed_once_its_delay_has_passed() -> void:
	assert_false(TimeClock.has_elapsed(10, 5, 14))
	assert_true(TimeClock.has_elapsed(10, 5, 15))
	assert_true(TimeClock.has_elapsed(10, 5, 20))


func test_finishing_each_stage_of_a_level_moves_the_clock_by_that_stages_cost() -> void:
	var runner := LevelRunner.new({
		"level_id": "TEST",
		"stages": [
			{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 2},
			{"seq": 2, "stage_id": "ST04", "mode": "Combat"},
			{"seq": 3, "stage_id": "ST03", "mode": "Combat", "time_units": 0},
		],
	})
	GameState.begin_level(runner)
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.time_units, 2)
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.time_units, 3)
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.time_units, 3)


func test_a_real_stage_row_carries_its_time_units_through_level_expansion() -> void:
	var level := BattleSetup.expand_level(DataDB.get_level("LV01"))
	assert_true(level.has("stages"))
	for stage: Dictionary in level["stages"]:
		assert_true(stage.has("time_units"), "%s lost its Time Units cell" % stage.get("stage_id"))
		assert_gte(TimeClock.units_for_stage(stage), 0)


func test_a_new_run_starts_the_clock_at_zero() -> void:
	GameState.time_units = 40
	GameState.start_new_run("PC01")
	assert_eq(GameState.time_units, 0)


func test_the_clock_is_saved() -> void:
	assert_true("time_units" in GameState._SAVED_FIELDS)


func _two_organizations() -> void:
	GameState.reset_booster_standing()
	GameState.booster_standing["BO05"] = 50
	GameState.booster_standing["BO09"] = 10
	GameState.last_decay_at = GameState.time_units
	GameState.booster_moved_in_period = {}


func test_decay_waits_for_the_decay_interval() -> void:
	var interval := int(DataDB.balance.get("decay_interval", 6))
	_two_organizations()
	GameState.time_units += interval - 1
	GameState._apply_time_decays()
	assert_eq(int(GameState.booster_standing["BO05"]), 50, "one unit short of the interval")
	GameState.time_units += 1
	GameState._apply_time_decays()
	assert_lt(int(GameState.booster_standing["BO05"]), 50, "the interval has passed")
	assert_gt(int(GameState.booster_standing["BO09"]), 10)


func test_decay_catches_up_one_tick_per_interval_and_clears_the_moved_list() -> void:
	var interval := int(DataDB.balance.get("decay_interval", 6))
	_two_organizations()
	GameState.booster_moved_in_period = {"BO09": true}
	GameState.time_units += interval * 2
	GameState._apply_time_decays()
	assert_eq(GameState.last_decay_at, GameState.time_units)
	assert_true(GameState.booster_moved_in_period.is_empty())


func test_an_organization_moved_since_the_last_tick_is_spared_neglect_decay_once() -> void:
	var interval := int(DataDB.balance.get("decay_interval", 6))
	var steps_before := int(DataDB.booster_standing.get("neglect_decay", 0))
	if steps_before <= 0:
		pending("neglect decay is off")
		return
	_two_organizations()
	GameState.booster_moved_in_period = {"BO09": true}
	GameState.time_units += interval
	GameState._apply_neglect_decay()
	assert_eq(int(GameState.booster_standing["BO09"]), 10, "dealt with, so left alone")
	assert_lt(int(GameState.booster_standing["BO05"]), 50)


func test_a_cooldown_is_measured_in_clock_units() -> void:
	var level := {"level_id": "LV_T", "cooldown": 12}
	var cleared := {"LV_T": 30}
	assert_eq(Ledger.level_cooldown_remaining(level, 30, cleared), 12)
	assert_eq(Ledger.level_cooldown_remaining(level, 40, cleared), 2)
	assert_eq(Ledger.level_cooldown_remaining(level, 42, cleared), 0)


func test_finishing_a_level_records_the_clock_it_finished_at() -> void:
	GameState.begin_level(LevelRunner.new({"level_id": "LV_REC", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 4}]}))
	var before := GameState.time_units
	GameState.finish_stage(LevelRunner.WON)
	# the id is not a real level, but the record is keyed by the runner's level id
	assert_eq(int(GameState.level_cleared_units.get("LV_REC", -1)), before + 4)
	GameState.level_cleared_units.erase("LV_REC")
	GameState.level_last_completed_at.erase("LV_REC")


func test_week_end_decay_pulls_standing_back_once_per_week() -> void:
	DataDB.balance["decay_interval"] = 0
	_two_organizations()
	GameState.go_home()
	assert_lt(int(GameState.booster_standing["BO05"]), 50, "standing settles at the week end")
	assert_gt(int(GameState.booster_standing["BO09"]), 10)
	assert_true(GameState.booster_moved_in_period.is_empty())


func test_going_home_moves_to_the_next_monday_and_counts_skipped_hours() -> void:
	DataDB.balance["decay_interval"] = 0
	GameState.calendar = WeekCalendar.fresh()
	GameState.time_units = 0
	var result := GameState.go_home()
	assert_eq(int(GameState.calendar["week"]), 1)
	assert_eq(str(GameState.calendar["phase"]), WeekCalendar.WORK)
	assert_eq(str(result["date"]), "18.10.08")
	assert_eq(GameState.time_units, 40 + 8, "an unplayed work week and weekend still pass")


func test_a_finished_stage_uses_up_calendar_hours() -> void:
	GameState.calendar = WeekCalendar.fresh()
	GameState.begin_level(LevelRunner.new({"level_id": "LV_CAL", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 4}]}))
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(int(GameState.calendar["hours"]), 4)
	GameState.level_cleared_units.erase("LV_CAL")
	GameState.level_last_completed_at.erase("LV_CAL")
