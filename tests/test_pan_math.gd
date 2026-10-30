extends GutTest
## PanMath: the arithmetic behind dragging and tilting an event picture.


func test_a_square_picture_in_a_wide_box_is_scaled_to_the_width() -> void:
	assert_almost_eq(PanMath.cover_scale(Vector2(900, 640), Vector2(1024, 1024)), 900.0 / 1024.0, 0.0001)


func test_a_square_picture_in_a_wide_box_can_move_up_and_down_only() -> void:
	var room := PanMath.spare(Vector2(900, 640), Vector2(1024, 1024))
	assert_almost_eq(room.x, 0.0, 0.01, "it already fits across")
	assert_almost_eq(room.y, 260.0, 0.01, "900 tall in a 640 box")


func test_a_panorama_can_move_across_only() -> void:
	var room := PanMath.spare(Vector2(900, 640), Vector2(2912, 1632))
	assert_gt(room.x, 0.0)
	assert_almost_eq(room.y, 0.0, 0.01)


func test_an_offset_never_leaves_an_edge_bare() -> void:
	var room := Vector2(200, 100)
	assert_eq(PanMath.clamp_offset(Vector2(500, -500), room), Vector2(100, -50))
	assert_eq(PanMath.clamp_offset(Vector2(30, 10), room), Vector2(30, 10))


func test_nothing_moves_along_an_axis_with_no_room() -> void:
	assert_eq(PanMath.clamp_offset(Vector2(80, 80), Vector2(0, 100)), Vector2(0, 50))


func test_a_tilt_reaches_the_edge_and_no_further() -> void:
	var room := Vector2(200, 100)
	assert_eq(PanMath.tilt_offset(Vector2(0.2, 0), 2.5, room), Vector2(50, 0), "half way")
	assert_eq(PanMath.tilt_offset(Vector2(1.0, -1.0), 2.5, room), Vector2(100, -50), "capped at the edge")


func test_a_negative_strength_turns_the_tilt_round() -> void:
	assert_eq(PanMath.tilt_offset(Vector2(0.2, 0), -2.5, Vector2(200, 0)), Vector2(-50, 0))


func test_following_moves_part_way_and_never_overshoots() -> void:
	var step := PanMath.follow(Vector2.ZERO, Vector2(100, 0), 6.0, 0.1)
	assert_gt(step.x, 0.0)
	assert_lt(step.x, 100.0)
	assert_eq(PanMath.follow(Vector2(5, 5), Vector2(5, 5), 6.0, 0.1), Vector2(5, 5))


func test_the_centred_picture_hangs_over_both_edges_equally() -> void:
	assert_eq(PanMath.picture_position(Vector2(900, 640), Vector2(900, 900), Vector2.ZERO), Vector2(0, -130))
	assert_eq(PanMath.picture_position(Vector2(900, 640), Vector2(900, 900), Vector2(0, 130)), Vector2(0, -260),
		"showing the bottom moves the picture up")
