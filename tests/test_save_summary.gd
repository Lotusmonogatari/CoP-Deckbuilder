extends GutTest
## SaveSummary and the restore safety copy (2026-10-15).

func test_summary_picks_the_most_recently_cleared_level() -> void:
	var run := {
		"levels_cleared": {"LV01": 1, "LV02": 2, "LV03": 0},
		"level_last_completed_at": {"LV01": 1, "LV02": 3, "LV03": 4},
		"inventory": {"SH04": 2, "SH21": 1},
		"xp": 340, "meta": {"Funds": 80000},
	}
	var summary := SaveSummary.of(run)
	assert_eq(summary["level_id"], "LV02", "LV03 has no clears, so LV02 is the latest")
	assert_eq(summary["items"], 3)
	assert_eq(summary["xp"], 340)
	assert_eq(summary["funds"], 80000)


func test_summary_of_a_fresh_run_has_no_level() -> void:
	assert_eq(SaveSummary.of({})["level_id"], "")


func test_a_restore_keeps_an_undo_copy_that_brings_the_old_run_back() -> void:
	var was_enabled := SaveManager.enabled
	SaveManager.enabled = true
	SaveManager.delete_save(SaveManager.MANUAL_PATH)
	SaveManager.delete_save(SaveManager.UNDO_PATH)
	GameState.start_new_run("PC01")
	GameState.xp = 100
	assert_true(SaveManager.backup_now())
	GameState.xp = 900
	assert_true(SaveManager.restore_backup())
	assert_eq(GameState.xp, 100)
	assert_true(SaveManager.has_undo())
	assert_true(SaveManager.restore_undo())
	assert_eq(GameState.xp, 900)
	assert_false(SaveManager.has_undo(), "the undo copy is spent")
	SaveManager.delete_save(SaveManager.MANUAL_PATH)
	SaveManager.delete_save()
	SaveManager.enabled = was_enabled
