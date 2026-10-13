extends GutTest
## The text-size setting's arithmetic (plan step 5).


func test_next_cycles_small_normal_large_and_back() -> void:
	assert_eq(TextScale.next(TextScale.SMALL), TextScale.NORMAL)
	assert_eq(TextScale.next(TextScale.NORMAL), TextScale.LARGE)
	assert_eq(TextScale.next(TextScale.LARGE), TextScale.SMALL)
	assert_eq(TextScale.next("nonsense"), TextScale.NORMAL)


func test_factor_reads_the_balance_levers_and_defaults_to_no_change() -> void:
	var balance := {"text_scale_small": 90, "text_scale_large": 120}
	assert_eq(TextScale.factor(TextScale.SMALL, balance), 0.9)
	assert_eq(TextScale.factor(TextScale.NORMAL, balance), 1.0)
	assert_eq(TextScale.factor(TextScale.LARGE, balance), 1.2)
	assert_eq(TextScale.factor(TextScale.LARGE, {}), 1.0)


func test_scaled_sizes_round_and_never_vanish() -> void:
	assert_eq(TextScale.scaled(40, 1.2), 48)
	assert_eq(TextScale.scaled(10, 0.5), 8)
