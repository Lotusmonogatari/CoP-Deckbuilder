extends GutTest
## A stage's result is saved when it is shown, so closing the app on a loss
## screen comes back to a loss that is already counted (2026-11-11, Cameron).

var _saved_run: Dictionary = {}


func before_each() -> void:
	_saved_run = GameState.to_save()
	GameState.pending_stage_result = {}
	var runner := LevelRunner.new({
		"level_id": "TEST_PENDING",
		"stages": [
			{"seq": 1, "stage_id": "ST02", "name_en": "First", "opponents": [{"opp_id": "A"}]},
			{"seq": 2, "stage_id": "ST03", "name_en": "Second", "opponents": [{"opp_id": "B"}]},
		],
	})
	GameState.begin_level(runner)


func after_each() -> void:
	GameState.end_level()
	GameState.load_save(_saved_run)
	GameState.mid_stage = false


func _args(outcome: String) -> Dictionary:
	return {"outcome": outcome, "score": 0, "boosters": [], "gaffe_loss": false, "gaffes": 0,
		"displeased": [], "crushed": [], "opposed": [], "tally": {}}


func test_a_recorded_result_belongs_to_the_stage_it_was_recorded_for() -> void:
	GameState.record_pending_stage_result(_args("loss"))
	assert_eq(str(GameState.pending_result_for_current_stage()["outcome"]), "loss")


func test_it_is_saved_with_the_run_and_comes_back() -> void:
	GameState.record_pending_stage_result(_args("loss"))
	var saved := GameState.to_save()
	GameState.pending_stage_result = {}
	GameState.load_save(saved)
	assert_eq(str(GameState.pending_stage_result.get("outcome", "")), "loss")


func test_counting_the_stage_clears_it() -> void:
	GameState.record_pending_stage_result(_args("loss"))
	GameState.finish_stage(LevelRunner.LOST)
	assert_true(GameState.pending_stage_result.is_empty())


func test_a_result_for_another_stage_is_discarded() -> void:
	GameState.record_pending_stage_result(_args("loss"))
	GameState.finish_stage(LevelRunner.WON)
	GameState.pending_stage_result = {"key": "OTHER:0:ST99", "outcome": "loss"}
	assert_true(GameState.pending_result_for_current_stage().is_empty())
	assert_true(GameState.pending_stage_result.is_empty())
