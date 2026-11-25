extends GutTest
## A list this helper scrolls does not also pan by Godot's own touch scrolling (a tester's report, 2026-11-24: on a phone the staff assignment
## drag and drop did not work; the built-in panning took the finger's drag before a chip's own drag could start).


func test_an_attached_scroll_has_no_built_in_touch_panning() -> void:
	var scroll := ScrollContainer.new()
	add_child_autofree(scroll)
	assert_lt(scroll.scroll_deadzone, 1000, "a plain ScrollContainer keeps its small deadzone")
	DragScroll.attach(scroll)
	assert_eq(scroll.scroll_deadzone, DragScroll.NO_BUILT_IN_PAN, "attached: the built-in panning can never start")
	var sideways := ScrollContainer.new()
	add_child_autofree(sideways)
	DragScroll.attach(sideways, false)
	assert_eq(sideways.scroll_deadzone, DragScroll.NO_BUILT_IN_PAN, "the hand's sideways scroller too")
