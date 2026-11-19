extends GutTest
## The pure parts of the problem report (2026-11-19): the black box, the hold gesture, the layout
## rules, the report text and the circle painter.


# ----------------------------------------------------------------- ActionLog

func test_log_keeps_only_the_newest_entries() -> void:
	var log := ActionLog.new(3)
	for index in 5:
		log.add(float(index), "press", "Button%d" % index)
	assert_eq(log.size(), 3)
	assert_eq(str(log.entries()[0]["text"]), "Button2", "the two oldest were dropped")
	assert_eq(str(log.entries()[2]["text"]), "Button4")


func test_log_folds_the_same_entry_pressed_again_into_a_count() -> void:
	var log := ActionLog.new(10)
	log.add(1.0, "press", "Continue")
	log.add(2.0, "press", "Continue")
	log.add(3.0, "press", "Continue")
	assert_eq(log.size(), 1)
	assert_eq(int(log.entries()[0]["count"]), 3)
	assert_string_contains(log.lines(3.0)[0], "(x3)")


func test_log_lines_say_how_long_ago() -> void:
	var log := ActionLog.new(10)
	log.add(0.0, "screen", "OfficeScreen")
	log.add(48.0, "press", "Marketplace")
	var lines := log.lines(120.0)
	assert_string_contains(lines[0], "2 min ago")
	assert_string_contains(lines[1], "72 s ago")
	assert_string_contains(log.lines(60.0)[1], "12 s ago")
	assert_eq(ActionLog.ago(0.4), "now")


func test_log_survives_being_saved_and_read_back() -> void:
	var log := ActionLog.new(10)
	log.add(1.0, "press", "A")
	log.add(2.0, "error", "boom")
	var back := ActionLog.from_array(log.to_array(), 10)
	assert_eq(back.entries(), log.entries())
	var damaged := ActionLog.from_array([{"kind": "press"}, "junk", {"kind": "tap", "text": "ok"}], 10)
	assert_eq(damaged.size(), 1, "entries that are not well formed are dropped")


# ---------------------------------------------------------------- HoldGesture

func test_hold_fires_once_after_the_time_with_enough_fingers() -> void:
	var hold := HoldGesture.new(3, 2.0)
	hold.press(0)
	hold.press(1)
	assert_false(hold.tick(5.0), "two fingers are not enough")
	hold.press(2)
	assert_false(hold.tick(1.0))
	assert_almost_eq(hold.progress(), 0.5, 0.001)
	assert_true(hold.tick(1.0), "fires at two seconds")
	assert_false(hold.tick(1.0), "and only once")


func test_letting_go_starts_the_hold_over() -> void:
	var hold := HoldGesture.new(2, 2.0)
	hold.press(KEY_VOLUMEUP)
	hold.press(KEY_VOLUMEDOWN)
	hold.tick(1.9)
	hold.release(KEY_VOLUMEDOWN)
	assert_eq(hold.progress(), 0.0)
	hold.press(KEY_VOLUMEDOWN)
	assert_false(hold.tick(1.9), "the earlier 1.9 s does not count")
	assert_true(hold.tick(0.2))


func test_a_hold_can_fire_again_after_it_was_let_go() -> void:
	var hold := HoldGesture.new(2, 1.0)
	hold.press(1)
	hold.press(2)
	assert_true(hold.tick(1.0))
	hold.release(2)
	hold.press(2)
	assert_true(hold.tick(1.0))


# ---------------------------------------------------------------- LayoutWatch

func _box(path: String, rect: Rect2, interactive: bool = true, parent: Variant = null, skip: bool = false, scrolled: bool = false) -> Dictionary:
	return {"path": path, "kind": "Button", "text": path.get_file(), "rect": rect, "parent_rect": parent,
		"interactive": interactive, "skip": skip, "scrolled": scrolled}


func test_a_button_outside_its_group_is_found() -> void:
	# The 2026-11-18 playtest: the Promises tile sat above the grid that was meant to hold it.
	var grid := Rect2(0, 1984, 1000, 260)
	var boxes := [_box("Safe/Grid/PromisesButton", Rect2(378, 1623, 324, 122), true, grid)]
	var found := LayoutWatch.problems(boxes, Rect2(0, 0, 1080, 2340))
	assert_eq(found.size(), 1)
	assert_eq(found[0]["what"], "outside_group")
	assert_string_contains(found[0]["detail"], "PromisesButton")


func test_a_button_inside_its_group_and_the_screen_is_fine() -> void:
	var grid := Rect2(0, 1984, 1000, 260)
	var boxes := [_box("Grid/A", Rect2(0, 1984, 324, 122), true, grid), _box("Grid/B", Rect2(338, 1984, 324, 122), true, grid)]
	assert_eq(LayoutWatch.problems(boxes, Rect2(0, 0, 1080, 2340)).size(), 0)


func test_a_button_off_the_screen_is_found() -> void:
	var found := LayoutWatch.problems([_box("Panel/Back", Rect2(900, 2300, 300, 120))], Rect2(0, 0, 1080, 2340))
	assert_eq(found[0]["what"], "off_screen")


func test_two_buttons_on_top_of_each_other_are_found_but_a_parent_and_child_are_not() -> void:
	var boxes := [_box("A/One", Rect2(0, 0, 300, 100)), _box("B/Two", Rect2(20, 10, 300, 100))]
	var found := LayoutWatch.problems(boxes, Rect2(0, 0, 1080, 2340))
	assert_eq(found.size(), 1)
	assert_eq(found[0]["what"], "overlapping")
	var nested := [_box("A", Rect2(0, 0, 300, 100)), _box("A/Inner", Rect2(0, 0, 300, 100))]
	assert_eq(LayoutWatch.problems(nested, Rect2(0, 0, 1080, 2340)).size(), 0)


func test_cards_and_non_interactive_boxes_are_left_alone() -> void:
	var boxes := [_box("Hand/Card", Rect2(0, 2500, 300, 100), true, null, true), _box("Page/Title", Rect2(0, 2500, 300, 100), false)]
	assert_eq(LayoutWatch.problems(boxes, Rect2(0, 0, 1080, 2340)).size(), 0)


func test_a_scrolling_page_may_run_past_the_screen_but_not_out_of_its_group() -> void:
	var grid := Rect2(0, 2500, 1000, 260)
	var below_the_fold := _box("Scroll/Grid/A", Rect2(0, 2500, 324, 122), true, grid, false, true)
	assert_eq(LayoutWatch.problems([below_the_fold], Rect2(0, 0, 1080, 2340)).size(), 0, "past the edge is normal in a scrolling page")
	var strayed := _box("Scroll/Grid/B", Rect2(0, 2000, 324, 122), true, grid, false, true)
	assert_eq(LayoutWatch.problems([strayed], Rect2(0, 0, 1080, 2340))[0]["what"], "outside_group", "but being out of its group is not")


func test_what_was_circled_is_named_smallest_first() -> void:
	var boxes := [
		_box("Page", Rect2(0, 0, 1080, 2340), false),
		_box("Page/Grid/Promises", Rect2(300, 1000, 300, 120)),
		_box("Page/Grid/Events", Rect2(0, 1000, 280, 120)),
	]
	var under := LayoutWatch.under_point(boxes, Vector2(400, 1050))
	assert_eq(str(under[0]["path"]), "Page/Grid/Promises", "the control drawn on top comes first")
	var inside := LayoutWatch.inside_area(boxes, Rect2(280, 980, 340, 160))
	assert_eq(str(inside[0]["path"]), "Page/Grid/Promises")
	assert_false(inside.any(func(box: Dictionary) -> bool: return str(box["path"]) == "Page"), "the whole page is not 'inside' a small circle")
	assert_string_contains(LayoutWatch.describe(boxes[1]), "Promises")


# ----------------------------------------------------------------- ReportCard

func test_the_gzip_mode_is_the_engines_own() -> void:
	assert_eq(ReportCard.GZIP_MODE, FileAccess.COMPRESSION_GZIP)


func test_the_save_packs_into_text_and_comes_back_exactly() -> void:
	var save := JSON.stringify({"version": 1, "run": {"meta": {"Funds": 50000}, "text": "日本語 and \"quotes\""}})
	var blob := ReportCard.pack_blob(save)
	assert_false(blob.contains(" "))
	for line in blob.split("\n"):
		assert_lte(line.length(), ReportCard.LINE_WIDTH)
	assert_eq(ReportCard.unpack_blob(blob), save)


func test_the_packed_save_is_found_inside_a_whole_report() -> void:
	var blob := ReportCard.pack_blob("{\"a\":1}")
	var text := ReportCard.to_text({"kind": "looks", "note": "x"}, blob)
	assert_eq(ReportCard.find_blob(text), blob)
	assert_eq(ReportCard.unpack_blob(ReportCard.find_blob(text)), "{\"a\":1}")
	assert_eq(ReportCard.find_blob("no block here"), "")


func test_a_report_says_where_and_what_and_holds_no_personal_detail() -> void:
	var text := ReportCard.to_text({
		"kind": "broken", "note": "The button moved", "source": "touch", "made_at": "2026-11-19T10:00:00",
		"build": "0.1.0", "platform": "Android", "model": "Pixel", "screen": "1080x2340", "scene": "OfficeScreen",
		"style": "woodblock", "text_size": "normal", "run": {"Week": 3, "Funds": 50000},
		"circled": ["Under the centre: PromisesButton"], "layout": ["PromisesButton sits outside the group"],
		"actions": ["  3 s ago  press   Marketplace"], "errors": []}, "")
	for part: String in ["Kind: broken", "The button moved", "Phone model: Pixel", "Display style: woodblock", "Funds: 50000",
			"Under the centre: PromisesButton", "outside the group", "Marketplace", "(no save included)"]:
		assert_string_contains(text, part)
	assert_false(text.contains("## Errors"), "an empty section is left out")


func test_a_report_without_a_note_says_so() -> void:
	assert_string_contains(ReportCard.to_text({"kind": "idea"}), "Note: (none)")


# ---------------------------------------------------------------- StrokePaint

## A picture stores each colour in 8 bits, so it comes back a hair off the float it was painted with.
func _is_ink(colour: Color) -> bool:
	return absf(colour.r - StrokePaint.INK.r) < 0.01 and absf(colour.g - StrokePaint.INK.g) < 0.01 and absf(colour.b - StrokePaint.INK.b) < 0.01


func test_a_stroke_changes_pixels_along_it_and_nowhere_else() -> void:
	var image := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	var stroke := PackedVector2Array([Vector2(20, 100), Vector2(180, 100)])
	StrokePaint.paint(image, [stroke], 1.0)
	assert_true(_is_ink(image.get_pixel(100, 100)), "on the line it is the red ink")
	assert_eq(image.get_pixel(100, 20), Color.BLACK, "far from the line nothing changed")


func test_a_stroke_scales_to_a_picture_of_a_different_size() -> void:
	var image := Image.create(400, 400, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	StrokePaint.paint(image, [PackedVector2Array([Vector2(20, 100), Vector2(180, 100)])], 2.0)
	assert_true(_is_ink(image.get_pixel(200, 200)), "screen (100, 100) is picture (200, 200) at scale 2")


func test_the_box_round_the_strokes() -> void:
	var box := StrokePaint.bounds([PackedVector2Array([Vector2(10, 20), Vector2(110, 80)]), PackedVector2Array([Vector2(60, 200)])])
	assert_eq(box, Rect2(10, 20, 100, 180))
	assert_eq(StrokePaint.bounds([]), Rect2())


func test_actions_given_as_a_packed_array_still_appear() -> void:
	var log := ActionLog.new(5)
	log.add(1.0, "press", "Marketplace")
	var text := ReportCard.to_text({"actions": log.lines(2.0)})
	assert_string_contains(text, "Marketplace")
