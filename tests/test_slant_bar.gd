extends GutTest
## SlantBar (2026-11-05, Cameron): the score bars lean at the cue band's angle
## and have gold top and bottom borders.

const RECT := Rect2(10, 100, 500, 50)


func test_the_slant_is_the_cue_bands_own() -> void:
	assert_eq(SlantBar.SLANT, 0.18)
	assert_eq(SlantBar.offset(50.0), 9.0)
	assert_eq(SlantBar.BORDER_COLOUR, CueBanner.EDGE_COLOUR, "the gold of the band's edge")


func test_divisions_run_from_the_left_edge_to_the_slanted_right_edge() -> void:
	assert_eq(SlantBar.bottom_x(RECT, 0.0), 10.0)
	assert_eq(SlantBar.bottom_x(RECT, 1.0), 10.0 + 500.0 - 9.0, "the bottom edge ends one slant short")
	assert_eq(SlantBar.bottom_x(RECT, 2.0), SlantBar.bottom_x(RECT, 1.0), "never past the end")
	assert_almost_eq(SlantBar.bottom_x(RECT, 0.5), 10.0 + 0.5 * 491.0, 0.001)


func test_the_parts_lean_and_split_by_weight() -> void:
	var shapes := SlantBar.shapes(RECT, [[1, Color.RED], [3, Color.BLUE]], 4.0)
	assert_eq(shapes.size(), 4, "two parts and two borders")
	var red: PackedVector2Array = shapes[0]["points"]
	# Top edge starts one slant to the right of the bottom edge: it leans "/".
	assert_eq(red[0].x - red[3].x, 9.0)
	assert_eq(red[0].y, 100.0)
	assert_eq(red[3].y, 150.0)
	# A quarter of the way across, and the next part starts where this one ends.
	var blue: PackedVector2Array = shapes[1]["points"]
	assert_almost_eq(red[2].x, 10.0 + 0.25 * 491.0 + 0.6, 0.001)
	assert_almost_eq(blue[3].x, 10.0 + 0.25 * 491.0, 0.001)
	assert_almost_eq(blue[2].x, 10.0 + 491.0, 0.001, "the last part ends flush")


func test_a_part_of_no_weight_draws_nothing() -> void:
	assert_eq(SlantBar.shapes(RECT, [[0, Color.RED], [5, Color.BLUE]], 4.0).size(), 3)


func test_gold_borders_run_along_the_top_and_bottom_only() -> void:
	var shapes := SlantBar.shapes(RECT, [[1, Color.RED]], 4.0)
	var top: PackedVector2Array = shapes[1]["points"]
	var bottom: PackedVector2Array = shapes[2]["points"]
	assert_eq(shapes[1]["colour"], CueBanner.EDGE_COLOUR)
	assert_eq(shapes[2]["colour"], CueBanner.EDGE_COLOUR)
	assert_eq(top[0].y, 100.0)
	assert_eq(top[2].y, 104.0, "4 px thick")
	assert_eq(bottom[3].y, 150.0)
	assert_eq(bottom[0].y, 146.0)
	assert_eq(shapes.size(), 3, "no strips down the sides")
