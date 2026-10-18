extends GutTest
## TimeClock.gd and the game clock in GameState (2026-10-18).

var _units_before := 0
var _runner_before: LevelRunner = null


func before_each() -> void:
	_units_before = GameState.time_units
	_runner_before = GameState.level_runner
	GameState.time_units = 0


func after_each() -> void:
	GameState.time_units = _units_before
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
