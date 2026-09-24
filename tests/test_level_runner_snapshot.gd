extends GutTest
## LevelRunner.snapshot()/restored(): a level picked up exactly where it was
## left. Pure rules, no autoloads.

func _level() -> Dictionary:
	return {"level_id": "LVX", "stages": [
		{"seq": 1, "opponents": [{"opp_id": "OP01"}]},
		{"seq": 2, "opponents": [{"opp_id": "OP02"}], "carries_buffs_from": [1]},
	]}


func test_a_snapshot_restores_position_and_results() -> void:
	var runner := LevelRunner.new(_level())
	runner.finish_stage(LevelRunner.WON, 70, ["BO02"])
	var back := LevelRunner.restored(runner.snapshot())
	assert_eq(back.index, 1)
	assert_eq(back.current_stage().get("seq"), 2)
	assert_eq(back.carried_buffs(), runner.carried_buffs())
	assert_false(back.is_finished())


func test_a_finished_level_stays_finished() -> void:
	var runner := LevelRunner.new(_level())
	runner.finish_stage(LevelRunner.LOST)
	assert_eq(LevelRunner.restored(runner.snapshot()).outcome(), LevelRunner.LOST)


func test_a_snapshot_with_no_level_is_refused() -> void:
	assert_null(LevelRunner.restored({"index": 1}))
	assert_null(LevelRunner.restored({"level": {"stages": []}}))


func test_a_nonsense_position_is_kept_in_range() -> void:
	var saved := LevelRunner.new(_level()).snapshot()
	saved["index"] = 99
	saved["outcome"] = "bananas"
	var back := LevelRunner.restored(saved)
	assert_eq(back.index, 2)
	assert_eq(back.outcome(), LevelRunner.ONGOING)
