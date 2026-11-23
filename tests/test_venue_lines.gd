extends GutTest
## Capitol venue lines (P16): eligibility by condition, date, season and law; the seeded daily set; the dry line.

const SEASONS := {"Winter": [12, 1, 2, 3], "Spring": [4, 5], "Summer": [6, 7, 8], "Autumn": [9, 10, 11]}


func _day(text: String) -> int:
	return WeekCalendar.parse_date(text)


func _ctx(today_text: String = "18.10.16", over: Dictionary = {}) -> Dictionary:
	var today := _day(today_text)
	var base := {"today": today, "month": int(WeekCalendar.civil_from_days(today)[1]), "seasons": SEASONS, "meta": {"Party support": 50},
		"laws": {}, "staff_hired": {}, "heard": {}}
	base.merge(over, true)
	return base


func _line(id: String, over: Dictionary = {}) -> Dictionary:
	var base := {"line_id": id, "pool": "cafeteria", "text": "Line " + id, "speaker": null, "weight": 1, "once": "N", "hint_kind": null,
		"hint_target": null, "condition_type": null, "on_date": null, "date_from": null, "date_to": null, "seasons": null, "after_law": null}
	base.merge(over, true)
	return base


func _plain(count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(_line("VL%03d" % i))
	return out


func test_a_line_outside_its_dates_never_appears() -> void:
	var window := _line("A", {"date_from": "18.10.15", "date_to": "18.10.31"})
	assert_true(VenueLines.line_ok(window, _ctx("18.10.16")))
	assert_false(VenueLines.line_ok(window, _ctx("18.10.14")), "before it opens")
	assert_false(VenueLines.line_ok(window, _ctx("18.11.01")), "after it closes")
	var day := _line("B", {"on_date": "18.10.15"})
	assert_true(VenueLines.line_ok(day, _ctx("18.10.15")))
	assert_false(VenueLines.line_ok(day, _ctx("18.10.16")), "only on its day")


func test_a_seasonal_line_shows_only_in_its_season() -> void:
	var winter := _line("W", {"seasons": ["Winter"]})
	assert_false(VenueLines.line_ok(winter, _ctx("18.10.16")), "October is autumn")
	assert_true(VenueLines.line_ok(winter, _ctx("18.12.03")))


func test_a_law_line_needs_that_law_decided_that_way() -> void:
	var passed := _line("L", {"after_law": "BI38 passed"})
	assert_false(VenueLines.line_ok(passed, _ctx()), "no law yet")
	assert_true(VenueLines.line_ok(passed, _ctx("18.10.16", {"laws": {"BI38": "passed"}})))
	assert_false(VenueLines.line_ok(passed, _ctx("18.10.16", {"laws": {"BI38": "failed"}})), "the other way round")


func test_a_condition_line_reads_the_meta_numbers() -> void:
	var high := _line("H", {"condition_type": "meta", "condition_target": "Party support", "condition_op": ">=", "condition_value": 70})
	assert_false(VenueLines.line_ok(high, _ctx()))
	assert_true(VenueLines.line_ok(high, _ctx("18.10.16", {"meta": {"Party support": 80}})))


func test_a_once_line_is_not_dealt_again_after_it_was_heard() -> void:
	var once := _line("O", {"once": "Y"})
	assert_true(VenueLines.line_ok(once, _ctx()))
	assert_false(VenueLines.line_ok(once, _ctx("18.10.16", {"heard": {"O": true}})))


func test_the_set_is_the_same_for_the_same_run_day_and_venue_and_differs_by_day() -> void:
	var lines := _plain(45)
	var ctx := _ctx()
	var first := VenueLines.deal(lines, "cafeteria", ctx, VenueLines.seed_for(7, 100, "VN01"), 12, 8, {}, {})
	var again := VenueLines.deal(lines, "cafeteria", ctx, VenueLines.seed_for(7, 100, "VN01"), 12, 8, {}, {})
	assert_eq(first, again, "a reload deals the same set")
	assert_eq(first.size(), 12)
	var other_day := VenueLines.deal(lines, "cafeteria", ctx, VenueLines.seed_for(7, 101, "VN01"), 12, 8, {}, {})
	assert_ne(first, other_day, "the next day is another set")
	var other_run := VenueLines.deal(lines, "cafeteria", ctx, VenueLines.seed_for(8, 100, "VN01"), 12, 8, {}, {})
	assert_ne(first, other_run, "another run is another set")


func test_a_dealt_set_never_repeats_a_line() -> void:
	var dealt := VenueLines.deal(_plain(45), "cafeteria", _ctx(), 123, 12, 8, {}, {})
	var seen := {}
	for entry: Dictionary in dealt:
		assert_false(seen.has(entry["line_id"]), "no repeats")
		seen[entry["line_id"]] = true


func test_a_line_written_for_today_is_always_in_the_set() -> void:
	var lines := _plain(45)
	lines.append(_line("TODAY", {"on_date": "18.10.15"}))
	for seed_value in 20:
		var ids: Array = []
		for entry: Dictionary in VenueLines.deal(lines, "cafeteria", _ctx("18.10.15"), seed_value, 12, 8, {}, {}):
			ids.append(entry["line_id"])
		assert_true(ids.has("TODAY"), "seed %d" % seed_value)


func test_about_one_slot_in_eight_is_a_hint_over_many_days() -> void:
	var lines := _plain(45)
	lines.append(_line("H1", {"hint_kind": "stage_suit"}))
	lines.append(_line("H2", {"hint_kind": "opponent_suit"}))
	var targets := {"stage_suit": [{"id": "ST01", "suit": "Earnest"}], "opponent_suit": [{"id": "OP01", "suit": "Appeal"}]}
	var phrasings := {"stage_suit.earnest": 3, "opponent_suit.appeal": 3}
	var hints := 0
	var slots := 0
	for day in 400:
		for entry: Dictionary in VenueLines.deal(lines, "cafeteria", _ctx(), VenueLines.seed_for(1, day, "VN01"), 12, 8, targets, phrasings):
			slots += 1
			hints += 0 if (entry["hint"] as Dictionary).is_empty() else 1
	var share := float(hints) / float(slots)
	assert_between(share, 0.09, 0.16, "about 1 in 8 (%.3f)" % share)


func test_a_hint_names_a_target_a_suit_and_a_phrasing_key_that_exists() -> void:
	var lines := [_line("H1", {"hint_kind": "stage_suit"})]
	lines.append_array(_plain(20))
	var targets := {"stage_suit": [{"id": "ST07", "suit": "Data Driven"}], "opponent_suit": []}
	var phrasings := {"stage_suit.data_driven": 3}
	var seen := 0
	for day in 200:
		for entry: Dictionary in VenueLines.deal(lines, "cafeteria", _ctx(), VenueLines.seed_for(2, day, "VN01"), 12, 2, targets, phrasings):
			var hint: Dictionary = entry["hint"]
			if hint.is_empty():
				continue
			seen += 1
			assert_eq(hint["target"], "ST07")
			assert_eq(hint["suit"], "Data Driven")
			assert_true(str(hint["text_key"]).begins_with("hint.stage_suit.data_driven_"))
			assert_between(int(str(hint["text_key"]).get_slice("_", 3)), 1, 3)
	assert_gt(seen, 20, "hints were dealt")


func test_a_hint_with_no_target_falls_back_to_a_plain_line() -> void:
	var lines := [_line("H1", {"hint_kind": "stage_suit"})]
	lines.append_array(_plain(20))
	for day in 50:
		for entry: Dictionary in VenueLines.deal(lines, "cafeteria", _ctx(), day, 12, 2, {"stage_suit": [], "opponent_suit": []}, {}):
			assert_true((entry["hint"] as Dictionary).is_empty(), "no target, no tip")
			assert_ne(entry["line_id"], "H1")


func test_a_named_hint_target_is_the_only_one_used() -> void:
	var lines := [_line("H1", {"hint_kind": "stage_suit", "hint_target": "ST02"})]
	lines.append_array(_plain(20))
	var targets := {"stage_suit": [{"id": "ST01", "suit": "Earnest"}, {"id": "ST02", "suit": "Appeal"}], "opponent_suit": []}
	var named_hints := 0
	for day in 100:
		for entry: Dictionary in VenueLines.deal(lines, "cafeteria", _ctx(), day, 12, 2, targets, {"stage_suit.earnest": 1, "stage_suit.appeal": 1}):
			if not (entry["hint"] as Dictionary).is_empty():
				named_hints += 1
				assert_eq(entry["hint"]["target"], "ST02")
	assert_gt(named_hints, 5, "hints were dealt")


func test_the_player_hears_the_dealt_lines_in_order_up_to_the_limit_then_the_set_is_done() -> void:
	var dealt := VenueLines.deal(_plain(45), "cafeteria", _ctx(), 9, 12, 8, {}, {})
	assert_eq(VenueLines.next_dealt(dealt, 0, 8)["line_id"], dealt[0]["line_id"])
	assert_eq(VenueLines.next_dealt(dealt, 7, 8)["line_id"], dealt[7]["line_id"])
	assert_true(VenueLines.next_dealt(dealt, 8, 8).is_empty(), "after 8 heard there is no next line")
	assert_true(VenueLines.next_dealt(dealt.slice(0, 3), 3, 8).is_empty(), "or when the set is used up")


func test_the_dry_line_comes_from_the_dry_pool_and_is_the_same_on_a_reload() -> void:
	var lines := _plain(5)
	lines.append(_line("D1", {"pool": "dry"}))
	lines.append(_line("D2", {"pool": "dry"}))
	var first := VenueLines.dry_line(lines, _ctx(), 55)
	assert_eq(first["pool"], "dry")
	assert_eq(VenueLines.dry_line(lines, _ctx(), 55)["line_id"], first["line_id"])
	assert_true(VenueLines.dry_line(_plain(3), _ctx(), 55).is_empty(), "no dry pool, no dry line")


func test_the_real_lines_never_have_a_protagonist_speaker() -> void:
	var protagonists := ["OP06", "OP22", "OP35", "OP40"]
	assert_eq(DataDB.venue_lines.size(), 90)
	for line: Dictionary in DataDB.venue_lines:
		assert_false(protagonists.has(str(line.get("speaker", ""))), "%s: a protagonist never speaks" % line["line_id"])
