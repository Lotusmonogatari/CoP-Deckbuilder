extends GutTest
## Name awareness (2026-10-23): two meters, and gaffes left at a stage's end
## counting against both.

var _awareness_before: Dictionary = {}
var _runner_before: LevelRunner = null


func before_each() -> void:
	_awareness_before = GameState.awareness.duplicate()
	_runner_before = GameState.level_runner
	GameState.reset_awareness()


func after_each() -> void:
	GameState.awareness = _awareness_before
	GameState.level_runner = _runner_before


func test_a_fresh_run_starts_both_meters_from_balance() -> void:
	assert_eq(int(GameState.awareness["district"]), 20)
	assert_eq(int(GameState.awareness["national"]), 10)


func test_meters_stay_between_zero_and_the_maximum() -> void:
	GameState.apply_awareness_delta("national", -50)
	assert_eq(int(GameState.awareness["national"]), 0)
	GameState.apply_awareness_delta("district", 500)
	assert_eq(int(GameState.awareness["district"]), 100)


func test_gaffes_left_cost_both_meters_one_point_each() -> void:
	GameState.apply_awareness_gaffes(3)
	assert_eq(int(GameState.awareness["district"]), 17)
	assert_eq(int(GameState.awareness["national"]), 7)
	assert_eq(int(GameState.last_awareness_change["district"]), -3)


func test_no_gaffes_left_costs_nothing() -> void:
	GameState.apply_awareness_gaffes(0)
	assert_eq(int(GameState.awareness["district"]), 20)


func test_finishing_a_combat_stage_applies_the_gaffes_it_ended_with() -> void:
	GameState.begin_level(LevelRunner.new({"level_id": "LV_AW", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 2}]}))
	# A stage lost to gaffes ends with the whole limit on the counter.
	GameState.finish_stage(LevelRunner.LOST, 0, [], true, 5)
	assert_eq(int(GameState.awareness["district"]), 15)
	assert_eq(int(GameState.awareness["national"]), 5)
	GameState.level_cleared_units.erase("LV_AW")
	GameState.level_last_completed_at.erase("LV_AW")


func test_a_non_combat_stage_never_costs_awareness() -> void:
	GameState.begin_level(LevelRunner.new({"level_id": "LV_AW2", "stages": [
		{"seq": 1, "stage_id": "ST07", "mode": "Non-combat", "time_units": 2}]}))
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 4)
	assert_eq(int(GameState.awareness["district"]), 20)
	GameState.level_cleared_units.erase("LV_AW2")
	GameState.level_last_completed_at.erase("LV_AW2")


func test_awareness_is_saved_with_the_run() -> void:
	GameState.apply_awareness_delta("district", 7)
	assert_eq(int((GameState.to_save()["awareness"] as Dictionary)["district"]), 27)
