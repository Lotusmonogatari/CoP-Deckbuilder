extends GutTest
## The How to Play guide's rules: reading order, grouping, and live numbers.
## (HowToPlayPanel.gd draws it; tests/interaction/how_to_play_driver.gd
## clicks it open from both screens.)


func _row(id: String, order: Variant, group: Variant, heading: Variant, body: Variant) -> Dictionary:
	return {"entry_id": id, "order": order, "group": group,
		"heading_en": heading, "body_en": body}


func test_entries_come_out_in_order_not_workbook_order() -> void:
	var rows := [_row("HT2", 20.0, "A", "Second", "b"), _row("HT1", 10.0, "A", "First", "b")]
	var ordered := HowToPlay.ordered(rows)
	assert_eq(ordered[0]["entry_id"], "HT1")
	assert_eq(ordered[1]["entry_id"], "HT2")


func test_equal_orders_fall_back_to_the_entry_id_and_unnumbered_rows_go_last() -> void:
	var rows := [_row("HT9", null, "A", "Unnumbered", "b"),
		_row("HT3", 5.0, "A", "Three", "b"), _row("HT2", 5.0, "A", "Two", "b")]
	var ids: Array = []
	for entry: Dictionary in HowToPlay.ordered(rows):
		ids.append(entry["entry_id"])
	assert_eq(ids, ["HT2", "HT3", "HT9"])


func test_a_row_with_nothing_to_show_is_dropped() -> void:
	var rows := [_row("HT1", 1.0, "A", null, null), _row("HT2", 2.0, "A", "", "  "),
		_row("HT3", 3.0, "A", "Only a heading", null)]
	var ordered := HowToPlay.ordered(rows)
	assert_eq(ordered.size(), 1)
	assert_eq(ordered[0]["entry_id"], "HT3")


func test_groups_sit_where_their_first_entry_does() -> void:
	var rows := [_row("HT1", 10.0, "Goal", "a", "x"), _row("HT2", 20.0, "Cards", "b", "x"),
		_row("HT3", 30.0, "Goal", "c", "x")]
	var groups := HowToPlay.grouped(rows)
	assert_eq(groups.size(), 2)
	assert_eq(groups[0]["group"], "Goal")
	assert_eq((groups[0]["entries"] as Array).size(), 2, "a later Goal entry joins the first Goal group")
	assert_eq(groups[1]["group"], "Cards")


func test_a_blank_group_is_kept_under_an_unnamed_group() -> void:
	var groups := HowToPlay.grouped([_row("HT1", 1.0, null, "a", "x")])
	assert_eq(groups[0]["group"], "")


func test_known_tokens_are_filled_and_unknown_ones_are_left_visible() -> void:
	var text := HowToPlay.fill_tokens("{majority} of {seats} seats, {typo}", {"majority": 51, "seats": 101})
	assert_eq(text, "51 of 101 seats, {typo}")


func test_live_tokens_read_the_floor_debate_and_the_rules() -> void:
	var stages := [
		{"stage_id": "ST02", "mode": "Combat", "win_threshold": 51, "bar_max": 101, "gaffe_limit": 4},
		{"stage_id": "ST05", "mode": "Combat", "win_threshold": 60, "bar_max": 100, "gaffe_limit": 6},
		{"stage_id": "ST07", "mode": "Non-combat", "gaffe_limit": 99},
	]
	var tokens := HowToPlay.live_tokens(stages, {"guard_cap": 5, "pass_energy_penalty": {"value": 1}})
	assert_eq(tokens["majority"], 51)
	assert_eq(tokens["seats"], 101)
	assert_eq(tokens["gaffe_min"], 4)
	assert_eq(tokens["gaffe_max"], 6, "a Non-combat room's number does not count")
	assert_eq(tokens["guard_cap"], 5, "a bare value")
	assert_eq(tokens["pass_penalty"], 1, "and rules.json's own {value: N} shape")


func test_a_number_that_cannot_be_found_is_left_out_not_guessed() -> void:
	var tokens := HowToPlay.live_tokens([], {})
	assert_false(tokens.has("majority"))
	assert_false(tokens.has("gaffe_min"))
	assert_eq(HowToPlay.fill_tokens("{majority}", tokens), "{majority}")


func test_every_token_in_the_real_guide_resolves_against_the_real_data() -> void:
	var tokens := HowToPlay.live_tokens(DataDB.stages, DataDB.rules)
	for name: String in HowToPlay.TOKEN_NAMES:
		assert_true(tokens.has(name), "the live token {%s} has a value" % name)
	for entry: Dictionary in HowToPlay.ordered(DataDB.how_to_play):
		for key in ["heading_en", "body_en", "caption"]:
			var text = entry.get(key)
			if text == null:
				continue
			assert_eq(HowToPlay.unresolved_tokens(str(text), tokens), [],
				"%s %s names a token the game cannot fill" % [entry.get("entry_id"), key])


func test_the_real_guide_has_entries_in_several_groups() -> void:
	var groups := HowToPlay.grouped(DataDB.how_to_play)
	assert_gt(groups.size(), 2, "the seeded guide is not empty")


func test_the_real_guide_mentions_winning_and_losing() -> void:
	var found := false
	for entry: Dictionary in HowToPlay.ordered(DataDB.how_to_play):
		if str(entry.get("group", "")).to_lower().contains("losing"):
			found = true
	assert_true(found, "the guide has a Winning and Losing section")
