extends GutTest
## The train strip's drag (two offices, slice 2, 2026-11-20).

func test_the_train_follows_the_drag_in_its_own_direction() -> void:
	assert_eq(Swipe.progress(300.0, 600.0, 1), 0.5)
	assert_eq(Swipe.progress(-300.0, 600.0, -1), 0.5, "pulled to the left from the District office")
	assert_eq(Swipe.progress(-100.0, 600.0, 1), 0.0, "the wrong way is no progress")
	assert_eq(Swipe.progress(900.0, 600.0, 1), 1.0, "it stops at the end of the track")
	assert_eq(Swipe.progress(50.0, 0.0, 1), 0.0, "no track, no progress")


func test_letting_go_past_the_commit_share_takes_the_trip() -> void:
	assert_true(Swipe.commits(0.6, 0.6))
	assert_true(Swipe.commits(0.95, 0.6))
	assert_false(Swipe.commits(0.59, 0.6), "short of it, the train springs back")
	assert_false(Swipe.commits(0.0, 0.6))


func test_a_press_that_hardly_moved_is_a_tap() -> void:
	assert_true(Swipe.is_tap(6.0, 14.0))
	assert_true(Swipe.is_tap(-14.0, 14.0))
	assert_false(Swipe.is_tap(40.0, 14.0))


func test_the_commit_share_is_a_balance_number() -> void:
	assert_eq(Levers.num("travel_swipe_commit_percent"), 60.0)
