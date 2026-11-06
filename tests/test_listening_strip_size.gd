extends GutTest
## Five organizations that fit on one row stay full size (Cameron, 2026-11-06:
## the strip used to drop to two rows at five tiles and shrink every icon).


func _strip(count: int, width: float, height: float) -> ListeningStrip:
	var strip := ListeningStrip.new()
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, height)
	holder.size = Vector2(width, height)
	add_child_autofree(holder)
	holder.add_child(strip)
	strip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ids: Array = []
	for booster in DataDB.boosters.slice(0, count):
		ids.append(str(booster.get("booster_id", "")))
	strip.show_listeners(ids)
	strip._fit()
	return strip


func test_five_tiles_fit_one_row_at_full_size() -> void:
	var strip := _strip(5, 1000.0, 130.0)
	assert_gte(strip._icon_size, 110.0, "five tiles on a wide strip are not shrunk")


func test_tiles_that_cannot_fit_one_row_wrap_smaller() -> void:
	var strip := _strip(5, 400.0, 260.0)
	assert_lt(strip._icon_size, 130.0)
