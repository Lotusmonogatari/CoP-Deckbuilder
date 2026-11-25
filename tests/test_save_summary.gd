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
