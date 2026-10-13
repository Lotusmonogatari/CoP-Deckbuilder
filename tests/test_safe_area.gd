extends GutTest
## Safe-area maths (plan step 1): insets scale from window pixels to base
## pixels, a desktop window has none, and a designed margin is only raised.


func test_a_desktop_window_has_no_insets() -> void:
	var r := SafeArea.insets(Rect2(0, 0, 440, 953), Vector2(440, 953), Vector2(1080, 2340))
	assert_eq(r, {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0})


func test_a_notch_and_home_bar_scale_to_base_pixels() -> void:
	# A 1080-wide phone window: 100 px notch at the top, 60 px home bar.
	var r := SafeArea.insets(Rect2(0, 100, 1080, 2180), Vector2(1080, 2340), Vector2(1080, 2340))
	assert_eq(r["top"], 100.0)
	assert_eq(r["bottom"], 60.0)
	# The same phone reported at half resolution scales up by two.
	var half := SafeArea.insets(Rect2(0, 50, 540, 1090), Vector2(540, 1170), Vector2(1080, 2340))
	assert_eq(half["top"], 100.0)
	assert_eq(half["bottom"], 60.0)


func test_a_missing_safe_area_is_ignored() -> void:
	var r := SafeArea.insets(Rect2(), Vector2(1080, 2340), Vector2(1080, 2340))
	assert_eq(r["top"], 0.0)


func test_a_designed_margin_is_only_raised_never_added_to() -> void:
	assert_eq(SafeArea.margin_for(70, 0.0), 70)
	assert_eq(SafeArea.margin_for(70, 40.0), 70)
	assert_eq(SafeArea.margin_for(70, 110.4), 111)
