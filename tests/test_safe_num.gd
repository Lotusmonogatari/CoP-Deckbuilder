extends GutTest
## Number reading that survives blank cells (review R10).


func test_null_and_junk_fall_back() -> void:
	assert_eq(SafeNum.to_int(null), 0)
	assert_eq(SafeNum.to_int(null, 7), 7)
	assert_eq(SafeNum.to_int("abc", 3), 3)
	assert_eq(SafeNum.to_int([], 4), 4)


func test_real_numbers_pass_through() -> void:
	assert_eq(SafeNum.to_int(5), 5)
	assert_eq(SafeNum.to_int(2.9), 2)
	assert_eq(SafeNum.to_int("12"), 12)


func test_a_blank_intent_value_does_not_crash_the_runner() -> void:
	assert_eq(IntentRunner._shape_of({"value": null}), [0])
