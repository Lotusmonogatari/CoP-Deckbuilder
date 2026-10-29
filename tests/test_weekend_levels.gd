extends GutTest
## Weekend-flagged levels (2026-10-23, made data-driven 2026-10-29): every level
## marked Weekend OK must fit a weekend day, so it can really be started then.


func test_every_weekend_level_fits_a_weekend_day() -> void:
	var seen := 0
	for level: Dictionary in DataDB.levels:
		if str(level.get("weekend_ok", "")) != "Yes":
			continue
		seen += 1
		assert_lte(GameState.level_hours(level), 4, "%s fits a weekend day" % level["level_id"])
	assert_gt(seen, 0, "some level is weekend-ready")
