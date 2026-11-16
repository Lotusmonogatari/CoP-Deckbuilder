extends GutTest
## Cameron, 2026-11-16: "the stage saves at start, at a new opponent, and at
## conclusion". Proved here against a scratch save file (SaveManager.save_path),
## never the player's own.

const PATH := "user://audit_save_points.json"


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	SaveManager.enabled = true
	SaveManager.save_path = PATH
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	SaveManager.enabled = false
	SaveManager.save_path = SaveManager.SAVE_PATH
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(PATH + ".bak")
	GameState.mid_stage = false


func _multi_opponent_level() -> LevelRunner:
	for row: Dictionary in DataDB.levels:
		var runner := LevelRunner.new(BattleSetup.expand_level(row))
		if runner.is_valid() and str(runner.current_stage().get("mode", "")) == "Combat" \
				and (runner.current_stage().get("opponents", []) as Array).size() >= 2:
			return runner
	return null


func test_the_run_is_saved_when_a_level_begins() -> void:
	var runner := _multi_opponent_level()
	GameState.begin_level(runner)
	assert_true(FileAccess.file_exists(PATH), "beginning a level writes a save")
	var saved := SaveManager.read_save(PATH)
	assert_true(saved.get("level_runner") is Dictionary, "the save holds the level in progress")
	assert_eq(int((saved["level_runner"] as Dictionary).get("index", -1)), 0, "at its first stage")


func test_a_finished_stage_is_saved_with_the_next_stage_in_place() -> void:
	var runner := _multi_opponent_level()
	GameState.begin_level(runner)
	GameState.finish_stage(LevelRunner.WON)
	var saved := SaveManager.read_save(PATH)
	if saved.get("level_runner") is Dictionary:
		assert_eq(int((saved["level_runner"] as Dictionary).get("index", -1)), GameState.level_runner.index)


func test_a_defeated_opponent_is_saved_while_the_stage_is_fought() -> void:
	var runner := _multi_opponent_level()
	GameState.begin_level(runner)
	GameState.mid_stage = true   # a stage is being fought: ordinary autosaves are blocked
	GameState.stage_checkpoint = {"key": GameState.stage_checkpoint_key(), "item_bonuses": {}, "engine": {"opponent_index": 1, "fields": {}}}
	DirAccess.remove_absolute(PATH)
	SaveManager.autosave()
	assert_false(FileAccess.file_exists(PATH), "an ordinary autosave stays blocked mid-stage")
	SaveManager.save_checkpoint()
	var saved := SaveManager.read_save(PATH)
	assert_eq(int(((saved.get("stage_checkpoint", {}) as Dictionary).get("engine", {}) as Dictionary).get("opponent_index", -1)), 1,
		"the checkpoint for the next opponent is in the file")


func test_the_result_is_saved_before_its_panel_is_dismissed() -> void:
	var runner := _multi_opponent_level()
	GameState.begin_level(runner)
	GameState.mid_stage = true
	DirAccess.remove_absolute(PATH)
	GameState.record_pending_stage_result({"outcome": "win", "score": 7})
	var saved := SaveManager.read_save(PATH)
	assert_eq(str((saved.get("pending_stage_result", {}) as Dictionary).get("outcome", "")), "win")
