extends GutTest
## The hidden share of a projected vote keeps the house size and never
## takes more from a bucket than it holds.


func test_split_keeps_the_house_size() -> void:
	var out := VoteProjection.split({"Yes": 46, "No": 47, "Abstain": 8}, 15.0)
	assert_eq(int(out["Yes"]) + int(out["No"]) + int(out["Abstain"]) + int(out["Unknown"]), 101)
	assert_eq(out["Unknown"], 15)


func test_split_takes_in_proportion() -> void:
	var out := VoteProjection.split({"Yes": 50, "No": 40, "Abstain": 10}, 20.0)
	assert_eq(out["Unknown"], 20)
	assert_eq(out["Yes"], 40)
	assert_eq(out["No"], 32)
	assert_eq(out["Abstain"], 8)


func test_zero_percent_hides_nothing() -> void:
	var out := VoteProjection.split({"Yes": 51, "No": 50, "Abstain": 0}, 0.0)
	assert_eq(out["Unknown"], 0)
	assert_eq(out["Yes"], 51)


func test_empty_house_is_safe() -> void:
	var out := VoteProjection.split({}, 15.0)
	assert_eq(out["Unknown"], 0)


func test_narrowed_range_never_goes_below_zero() -> void:
	assert_eq(VoteProjection.narrowed_range(10, 25, 6), [4, 19])
	assert_eq(VoteProjection.narrowed_range(10, 25, 12), [0, 13])
	assert_eq(VoteProjection.narrowed_range(10, 25, 30), [0, 0])


func test_tier_values_are_not_added() -> void:
	assert_eq(VoteProjection.by_tier([1, 2, 3], 2), 3)
	assert_eq(VoteProjection.by_tier([1, 2, 3], 0), 1)
	assert_eq(VoteProjection.by_tier([1, 2, 3], -1), 0)
