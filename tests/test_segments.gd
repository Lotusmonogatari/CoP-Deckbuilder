extends GutTest
## P21 phase C (2026-11-26, Cameron): segments, suit plays, credibility, spending and recovery.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.calendar = {"week": 10, "phase": "work", "hours": 0}


func test_the_segment_map_loads_with_five_segments_each_with_a_suit_and_organizations() -> void:
	assert_eq(DataDB.segment_map.size(), 5)
	var boosters := {}
	for booster: Dictionary in DataDB.boosters:
		boosters[str(booster["booster_id"])] = true
	var suits := DataDB.suits.map(func(s: Dictionary) -> String: return str(s["element"]))
	for row: Dictionary in DataDB.segment_map:
		assert_true(suits.has(str(row["suit"])), "%s has a real suit" % row["segment_id"])
		assert_gt((row["organizations"] as Array).size(), 0)
		for org: Variant in row["organizations"]:
			assert_true(boosters.has(str(org)), str(org))
	assert_eq(str(DataDB.segment_map[0]["suit"]), "Divisive")


func test_plays_count_only_inside_the_window() -> void:
	var by_week := {"10": {"Earnest": 5}, "8": {"Earnest": 4}, "6": {"Earnest": 9}, "9": {"Appeal": 3}}
	assert_eq(Segments.plays_in_window(by_week, 10, 4, "Earnest"), 9, "weeks 7 to 10: 5 and 4, not the 9 in week 6")
	assert_eq(Segments.plays_in_window(by_week, 10, 4, "Appeal"), 3)
	assert_eq(Segments.plays_in_window({}, 10, 4, "Earnest"), 0)


func test_favorability_is_the_average_standing_scaled_by_suit_use_less_the_debit() -> void:
	assert_eq(Segments.favorability(60.0, 20, 0), 60, "full use")
	assert_eq(Segments.favorability(60.0, 10, 0), 30, "half the target")
	assert_eq(Segments.favorability(60.0, 99, 0), 60, "capped at 1")
	assert_eq(Segments.favorability(60.0, 20, 15), 45)
	assert_eq(Segments.favorability(10.0, 20, 50), 0, "never below 0")
	assert_eq(Segments.favorability(100.0, 20, 0), 100)


func test_credibility_is_the_rounded_average_of_the_five() -> void:
	assert_eq(Segments.credibility([60, 60, 60, 60, 60]), 60)
	assert_eq(Segments.credibility([10, 20, 30, 40, 51]), 30)
	assert_eq(Segments.credibility([]), 0)


func test_the_game_reads_standing_and_suit_plays() -> void:
	for booster: Dictionary in DataDB.boosters:
		GameState.booster_standing[str(booster["booster_id"])] = 50
	GameState.suit_plays = {}
	assert_eq(GameState.credibility_now(), 0, "no cards played in a suit: nothing counts")
	GameState.suit_plays = {"10": {"Divisive": 20, "Appeal": 20, "Earnest": 20, "Emotional": 20, "Data Driven": 20}}
	assert_eq(GameState.credibility_now(), 50)
	var rows := GameState.segment_rows()
	assert_eq(rows.size(), 5)
	assert_eq(int(rows[0]["favorability"]), 50)
	assert_eq(str(rows[0]["suit"]), "Divisive")
	assert_gt((rows[2]["orgs"] as Array).size(), 5)


func test_playing_a_card_notes_its_suit_for_this_week() -> void:
	var card: Dictionary = DataDB.cards[0]
	GameState.record_card_played(str(card["card_id"]))
	GameState.record_card_played(str(card["card_id"]))
	assert_eq(int((GameState.suit_plays["10"] as Dictionary)[str(card["suit"])]), 2)


func test_spending_credibility_lowers_every_segment_and_is_limited() -> void:
	for booster: Dictionary in DataDB.boosters:
		GameState.booster_standing[str(booster["booster_id"])] = 80
	GameState.suit_plays = {"10": {"Divisive": 20, "Appeal": 20, "Earnest": 20, "Emotional": 20, "Data Driven": 20}}
	assert_eq(GameState.credibility_now(), 80)
	assert_eq(GameState.spend_credibility(20), "")
	assert_eq(GameState.credibility_now(), 60, "falls by the amount spent")
	assert_ne(GameState.spend_credibility(61), "", "cannot spend more than there is")
	assert_ne(GameState.spend_credibility(0), "")
	assert_eq(GameState.credibility_now(), 60, "a refused spend changes nothing")


func test_debits_come_back_ten_percent_a_week_rounded_down() -> void:
	assert_eq(Segments.debit_after_week(20), 18)
	assert_eq(Segments.debit_after_week(5), 4)
	assert_eq(Segments.debit_after_week(1), 0, "a small debit reaches nothing")
	assert_eq(Segments.debit_after_week(0), 0)
	GameState.segment_debits = {"SG01": 30}
	GameState._recover_credibility()
	assert_eq(int(GameState.segment_debits["SG01"]), 27)


func test_old_suit_plays_are_forgotten_and_the_state_is_saved() -> void:
	GameState.suit_plays = {"1": {"Earnest": 3}, "9": {"Earnest": 2}}
	GameState.segment_debits = {"SG02": 7}
	GameState._recover_credibility()
	assert_false(GameState.suit_plays.has("1"))
	assert_true(GameState.suit_plays.has("9"))
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	assert_true(GameState.suit_plays.is_empty())
	GameState.load_save(data)
	assert_true(GameState.suit_plays.has("9"))
	assert_eq(int(GameState.segment_debits["SG02"]), 6)
