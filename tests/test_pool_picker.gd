extends GutTest
## PoolPicker.gd: the generic "pool of choices" filter-then-random-pick,
## generalized from OfficeTicker.gd's own eligible/next_line shape.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_a_row_with_the_matching_scope_is_eligible() -> void:
	var rows := [{"id": "A", "stage_id": "ST02"}]
	assert_eq(PoolPicker.eligible(rows, "stage_id", "ST02"), [{"id": "A", "stage_id": "ST02"}])


func test_a_row_for_a_different_scope_is_not_eligible() -> void:
	var rows := [{"id": "A", "stage_id": "ST05"}]
	assert_eq(PoolPicker.eligible(rows, "stage_id", "ST02"), [])


func test_a_blank_scope_field_is_a_wildcard() -> void:
	var rows := [{"id": "A", "stage_id": ""}, {"id": "B"}]
	var found := PoolPicker.eligible(rows, "stage_id", "ST02")
	assert_eq(found.size(), 2, "both a blank string and a missing key count as the wildcard")


func test_pick_is_empty_when_nothing_is_eligible() -> void:
	var rows := [{"id": "A", "stage_id": "ST05"}]
	assert_eq(PoolPicker.pick(rows, "stage_id", "ST02", _rng(1)), {})


func test_pick_returns_the_only_eligible_row() -> void:
	var rows := [{"id": "A", "stage_id": "ST02"}]
	assert_eq(PoolPicker.pick(rows, "stage_id", "ST02", _rng(1)), {"id": "A", "stage_id": "ST02"})


func test_pick_never_immediately_repeats_the_excluded_row_when_another_is_eligible() -> void:
	var rows := [
		{"id": "A", "stage_id": "ST02"},
		{"id": "B", "stage_id": "ST02"},
	]
	var rng := _rng(7)
	var last := {}
	for i in 20:
		var picked := PoolPicker.pick(rows, "stage_id", "ST02", rng, last)
		assert_false(picked.is_empty(), "every pull should find something eligible")
		if i > 0:
			assert_ne(picked, last, "should never repeat the row just excluded")
		last = picked


func test_pick_can_repeat_when_it_is_the_only_one_eligible() -> void:
	var rows := [{"id": "A", "stage_id": "ST02"}]
	var rng := _rng(3)
	var last := {"id": "A", "stage_id": "ST02"}
	for i in 5:
		assert_eq(PoolPicker.pick(rows, "stage_id", "ST02", rng, last), last)
