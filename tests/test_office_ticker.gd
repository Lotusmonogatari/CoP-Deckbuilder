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


# ---------------------------------------------------------------------------
# The "{player}" token (2026-10-03)
# ---------------------------------------------------------------------------

func test_fill_tokens_replaces_player_with_the_given_name() -> void:
	assert_eq(OfficeTicker.fill_tokens("{player} is in the headlines.", "Haru Yashi"),
		"Haru Yashi is in the headlines.")


func test_fill_tokens_leaves_the_token_alone_when_no_name_is_given() -> void:
	# A blank name means no run has started yet, or a caller that doesn't
	# care about the token — leaving it untouched rather than blanking it
	# out means a half-wired caller never ships a broken-looking line.
	assert_eq(OfficeTicker.fill_tokens("{player} is in the headlines.", ""),
		"{player} is in the headlines.")


func test_fill_tokens_does_nothing_to_a_line_with_no_token() -> void:
	assert_eq(OfficeTicker.fill_tokens("Committee season is underway.", "Haru Yashi"),
		"Committee season is underway.")


func test_eligible_lines_fills_the_token_before_returning_a_line() -> void:
	var rows := [
		{"ticker_id": "TK07", "condition_type": "always", "text_en": "{player}'s office is busy today."},
	]
	var lines := OfficeTicker.eligible_lines(rows, {}, {}, "Haru Yashi")
	assert_eq(lines, ["Haru Yashi's office is busy today."])


func test_next_line_also_fills_the_token() -> void:
	var rows := [
		{"ticker_id": "TK07", "condition_type": "always", "text_en": "{player}'s office is busy today."},
	]
	var ticker := OfficeTicker.new()
	assert_eq(ticker.next_line(rows, {}, {}, _rng(1), "Haru Yashi"),
		"Haru Yashi's office is busy today.")
