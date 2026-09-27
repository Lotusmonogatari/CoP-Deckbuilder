extends GutTest
## OfficeTicker.gd: which data/office_ticker.json lines are eligible right
## now, and which one comes next. Fake rows throughout, the same way
## test_office_notices.gd proves its own logic without the real workbook.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_an_always_row_is_always_eligible() -> void:
	var rows := [
		{"ticker_id": "TK01", "condition_type": "always", "text_en": "line one"},
	]
	var lines := OfficeTicker.eligible_lines(rows, {}, {})
	assert_eq(lines, ["line one"])


func test_a_meta_threshold_row_is_eligible_only_when_it_holds() -> void:
	var rows := [
		{"ticker_id": "TK04", "condition_type": "meta", "condition_target": "Reputation",
			"condition_op": "<", "condition_value": 30, "text_en": "low reputation line"},
	]
	assert_eq(OfficeTicker.eligible_lines(rows, {}, {"Reputation": 10}), ["low reputation line"])
	assert_eq(OfficeTicker.eligible_lines(rows, {}, {"Reputation": 50}), [],
		"the threshold is not crossed at Reputation 50")


func test_unlike_office_notices_every_eligible_row_shows_not_just_one() -> void:
	var rows := [
		{"ticker_id": "TK01", "condition_type": "always", "text_en": "line one"},
		{"ticker_id": "TK02", "condition_type": "always", "text_en": "line two"},
	]
	var lines := OfficeTicker.eligible_lines(rows, {}, {})
	assert_eq(lines, ["line one", "line two"])


func test_next_line_is_empty_when_nothing_is_eligible() -> void:
	var rows := [
		{"ticker_id": "TK04", "condition_type": "meta", "condition_target": "Reputation",
			"condition_op": "<", "condition_value": 30, "text_en": "low reputation line"},
	]
	var ticker := OfficeTicker.new()
	assert_eq(ticker.next_line(rows, {}, {"Reputation": 50}, _rng(1)), "")


func test_next_line_is_the_only_eligible_line_when_there_is_one() -> void:
	var rows := [
		{"ticker_id": "TK01", "condition_type": "always", "text_en": "only line"},
	]
	var ticker := OfficeTicker.new()
	assert_eq(ticker.next_line(rows, {}, {}, _rng(1)), "only line")


func test_next_line_never_immediately_repeats_when_another_is_eligible() -> void:
	var rows := [
		{"ticker_id": "TK01", "condition_type": "always", "text_en": "line one"},
		{"ticker_id": "TK02", "condition_type": "always", "text_en": "line two"},
	]
	var ticker := OfficeTicker.new()
	var rng := _rng(7)
	var last := ""
	for i in 20:
		var picked := ticker.next_line(rows, {}, {}, rng)
		assert_ne(picked, "", "every pull should find something eligible")
		if i > 0:
			assert_ne(picked, last, "should never repeat the line just shown")
		last = picked


func test_next_line_can_repeat_when_it_is_the_only_one_eligible() -> void:
	var rows := [
		{"ticker_id": "TK01", "condition_type": "always", "text_en": "only line"},
	]
	var ticker := OfficeTicker.new()
	var rng := _rng(3)
	for i in 5:
		assert_eq(ticker.next_line(rows, {}, {}, rng), "only line")
