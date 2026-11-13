extends GutTest
## The Scroll speed setting (2026-11-13): five levels, level 1 the original speed.

func test_the_levels_cycle_one_to_five_then_back() -> void:
	assert_eq(ScrollSpeed.next(1), 2)
	assert_eq(ScrollSpeed.next(4), 5)
	assert_eq(ScrollSpeed.next(5), 1)
	assert_eq(ScrollSpeed.next(99), 1, "a nonsense level counts as the top one")


func test_odd_saved_values_mean_level_one() -> void:
	assert_eq(ScrollSpeed.clean(null), 1)
	assert_eq(ScrollSpeed.clean("fast"), 1)
	assert_eq(ScrollSpeed.clean(0), 1)
	assert_eq(ScrollSpeed.clean(3.0), 3)
	assert_eq(ScrollSpeed.clean(9), 5)


func test_level_one_is_the_original_speed_and_each_level_is_faster() -> void:
	var balance := DataDB.balance
	assert_eq(ScrollSpeed.factor(1, balance), 1.0, "level 1 changes nothing")
	var last := 0.0
	for level in range(1, ScrollSpeed.LEVELS + 1):
		var factor := ScrollSpeed.factor(level, balance)
		assert_gt(factor, last, "level %d is faster than the one before" % level)
		last = factor


func test_a_missing_lever_means_no_change() -> void:
	assert_eq(ScrollSpeed.factor(4, {}), 1.0)
