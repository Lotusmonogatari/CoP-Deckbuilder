extends GutTest
## Hold to resign (2026-11-19, Cameron): the vignette maths and the numbers behind it.


func test_nothing_is_dark_when_the_hold_begins() -> void:
	for radius in [0.0, 0.5, 1.0, 1.414]:
		assert_almost_eq(ResignHold.shade(radius, 0.0), 0.0, 0.001, "radius %s at the start" % radius)


func test_everything_is_black_when_the_hold_is_complete() -> void:
	for radius in [0.0, 0.5, 1.0, 1.414]:
		assert_almost_eq(ResignHold.shade(radius, 1.0), 1.0, 0.001, "radius %s at the end" % radius)


func test_the_outside_goes_black_before_the_middle() -> void:
	# Halfway through, the corners are black and the middle is still clear.
	assert_almost_eq(ResignHold.shade(1.414, 0.5), 1.0, 0.001, "corner")
	assert_almost_eq(ResignHold.shade(0.0, 0.5), 0.0, 0.001, "centre")
	for progress in [0.2, 0.4, 0.6, 0.8]:
		assert_true(ResignHold.shade(1.3, progress) >= ResignHold.shade(0.6, progress), "outside at least as dark as inside at %s" % progress)


func test_the_black_only_grows_as_the_hold_goes_on() -> void:
	for radius in [0.3, 0.8, 1.2, 1.4]:
		var last := -1.0
		for step in 11:
			var dark := ResignHold.shade(radius, float(step) / 10.0)
			assert_true(dark >= last - 0.0001, "radius %s never lightens as progress rises (step %d)" % [radius, step])
			last = dark


func test_the_corners_start_to_darken_early() -> void:
	# A viewer should see the edges going dark soon after pressing, not only near the end.
	assert_true(ResignHold.shade(1.414, 0.15) > 0.05, "a corner at 15% of the hold")


func test_seconds_read_as_plain_numbers() -> void:
	assert_eq(ResignHold.seconds_text(5.0), "5")
	assert_eq(ResignHold.seconds_text(2.5), "2.5")


func test_the_hold_time_is_a_workbook_number_of_five_seconds() -> void:
	assert_eq(Levers.num("resign_confirm_hold_seconds"), 5.0)


func test_the_button_says_to_hold_and_for_how_long() -> void:
	var button := ResignScreen.button(func() -> void: pass)
	assert_string_contains(button.text, "hold 5 seconds")
	assert_true(button.get_node_or_null("ResignHold") is ResignHold, "the button carries the hold")
	button.free()


func test_a_press_that_is_not_held_does_nothing() -> void:
	var fired := [0]
	var button := Button.new()
	add_child_autofree(button)
	var hold := ResignHold.attach(button, 5.0, func() -> void: fired[0] += 1)
	assert_false(hold.is_holding())
	button.button_down.emit()
	assert_true(hold.is_holding())
	button.button_up.emit()
	assert_false(hold.is_holding())
	assert_eq(fired[0], 0, "letting go early confirms nothing")
