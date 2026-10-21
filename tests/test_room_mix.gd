extends GutTest
## RoomMix: the room's audience as whole percentages that add to exactly 100,
## with the rest counted as Other (2026-10-21).


func _segments() -> Array:
	return DataDB.segments


func _total(entries: Array) -> int:
	var sum := 0
	for entry: Dictionary in entries:
		sum += int(entry["pct"])
	return sum


func test_the_missing_share_becomes_other_and_the_total_is_100() -> void:
	# ST03 names only Party Members at 55 percent; the rest is Other.
	var entries := RoomMix.entries({"segment_mix": {"SG02": 0.55}, "pct_other": 0.45}, _segments(), "Other")
	assert_eq(_total(entries), 100)
	assert_eq(entries[0]["name"], "Party Members")
	assert_eq(entries[-1]["name"], "Other")
	assert_eq(int(entries[-1]["pct"]), 45)


func test_a_mix_that_falls_short_without_pct_other_still_reaches_100() -> void:
	var entries := RoomMix.entries({"segment_mix": {"SG01": 0.1, "SG02": 0.4}}, _segments(), "Other")
	assert_eq(_total(entries), 100)
	assert_eq(int(entries[-1]["pct"]), 50, "the unnamed half is Other")


func test_rounding_never_adds_to_99_or_101() -> void:
	var entries := RoomMix.entries({"segment_mix": {"SG01": 1.0 / 3.0, "SG02": 1.0 / 3.0, "SG03": 1.0 / 3.0}}, _segments(), "Other")
	assert_eq(_total(entries), 100)


func test_every_real_combat_stage_adds_to_100() -> void:
	for stage: Dictionary in DataDB.stages:
		if str(stage.get("mode", "")) != "Combat":
			continue
		var entries := RoomMix.entries(stage, _segments(), "Other")
		assert_eq(_total(entries), 100, str(stage.get("stage_id", "")))


func test_a_room_with_no_audience_shows_nothing() -> void:
	assert_eq(RoomMix.entries({}, _segments(), "Other").size(), 0)
