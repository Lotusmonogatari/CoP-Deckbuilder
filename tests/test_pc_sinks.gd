extends GutTest
## P21 phase E (2026-11-26, Cameron): the Political Capital sinks built on today's main: Trim the deck, Mentoring, Pep talk and the Library's Rush request.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 4, "phase": "work", "hours": 0}
	GameState.xp = 2000


func _hire_one() -> String:
	GameState.meta["Funds"] = 1000000
	GameState.staff_recruitment_tier = 5
	var id := str(DataDB.staff[0]["staff_id"])
	assert_eq(GameState.hire_staff(id), "")
	return id


func test_trimming_removes_a_card_and_a_deck_slot_and_the_price_steps_up() -> void:
	# Room to trim: the deck is raised above the minimum with spare owned cards.
	GameState.deck_size_bonus = 5
	for card: Dictionary in DataDB.cards:
		if not GameState.owned_cards.has(str(card["card_id"])) and GameState.deck.size() < GameState.deck_size():
			GameState.owned_cards.append(str(card["card_id"]))
			GameState.deck.append(str(card["card_id"]))
	var before_size := GameState.deck_size()
	var victim: String = GameState.deck[0]
	assert_eq(GameState.trim_price(), 75)
	assert_eq(GameState.trim_deck(victim), "")
	assert_false(GameState.deck.has(victim))
	assert_false(GameState.owned_cards.has(victim), "gone for the run")
	assert_eq(GameState.deck_size(), before_size - 1, "the deck loses a slot too, so it stays legal")
	assert_eq(GameState.xp, 1925)
	assert_eq(GameState.trim_price(), 100, "the second costs 25 more")


func test_the_deck_never_trims_below_twelve_and_a_card_outside_it_cannot_be_trimmed() -> void:
	GameState.deck_size_bonus = 0
	var base := GameState.deck_size()
	var why := GameState.trim_refusal(str(GameState.deck[0]))
	if base - 1 < 12:
		assert_eq(why, Text.say("trim.refuse_min", {"min": 12}))
	assert_ne(GameState.trim_refusal("NOT_A_CARD"), "")
	GameState.xp = 10
	GameState.deck_size_bonus = 6
	for card: Dictionary in DataDB.cards:
		if GameState.deck.size() < GameState.deck_size() and not GameState.deck.has(str(card["card_id"])):
			GameState.deck.append(str(card["card_id"]))
			GameState.owned_cards.append(str(card["card_id"]))
	assert_eq(GameState.trim_refusal(str(GameState.deck[0])), Text.say("trim.refuse_pc"))


func test_pep_talk_gives_loyalty_once_a_week() -> void:
	var id := _hire_one()
	var before := GameState.staff_loyalty_of(id)
	assert_eq(GameState.pep_talk_price(), 60)
	assert_eq(GameState.pep_talk(id), "")
	assert_eq(GameState.staff_loyalty_of(id), before + 5)
	assert_eq(GameState.xp, 1940)
	assert_eq(GameState.pep_talk(id), Text.say("staff.pep_talk_done"))
	assert_eq(GameState.xp, 1940, "a refused one costs nothing")


func test_mentoring_cancels_the_loyalty_loss_of_an_unpaid_week() -> void:
	var id := _hire_one()
	GameState.staff_loyalty[id] = 70
	GameState.meta["Funds"] = 0   # the wage cannot be paid
	GameState.dues_balance = 0
	var unmentored_before := GameState.staff_loyalty_of(id)
	GameState._settle_staff_week()
	var unmentored_after := GameState.staff_loyalty_of(id)
	assert_lt(unmentored_after, unmentored_before, "an unpaid week costs Loyalty")
	GameState.staff_loyalty[id] = 70
	GameState.meta["Funds"] = 0
	assert_eq(GameState.mentor(id), "")
	assert_eq(GameState.xp, 1900)
	GameState._settle_staff_week()
	assert_gt(GameState.staff_loyalty_of(id), unmentored_after, "mentored: the loss is cancelled")
	assert_eq(GameState.mentor(id), "", "the flag is reset at the week's end, so it can be bought again")


func test_mentoring_is_once_a_week_and_needs_the_capital() -> void:
	var id := _hire_one()
	assert_eq(GameState.mentor(id), "")
	assert_eq(GameState.mentor(id), Text.say("staff.mentoring_done"))
	GameState.staff_mentored = {}
	GameState.xp = 5
	assert_eq(GameState.mentor(id), Text.say("staff.refuse_pc"))


func test_a_rush_request_pays_capital_instead_of_hours_once_a_day() -> void:
	assert_eq(GameState.rush_price(), 60)
	assert_eq(GameState.rush_refusal(), "")
	var rooms := GameState.desk_rooms()
	if rooms.is_empty():
		pass_test("no room to look up in this data")
		return
	var hours := GameState.work_hours_left()
	var done := GameState.do_research(str(rooms[0]["stage_id"]), str(rooms[0]["level_id"]), true)
	assert_true(bool(done["ok"]), str(done.get("reason", "")))
	assert_eq(GameState.work_hours_left(), hours - GameState.venue_walk_hours("VN02"), "the reading's own hours are not spent")
	assert_eq(GameState.xp, 1940)
	assert_eq(GameState.rush_refusal(), Text.say("venue.rush_refuse_used"), "once a day")


func test_prices_follow_the_difficulty_and_the_state_is_saved() -> void:
	GameState.difficulty = Difficulty.HARDER
	assert_eq(GameState.pep_talk_price(), 70)
	GameState.trims_done = 2
	GameState.rush_day = 5
	GameState.staff_pepped = {"SF01": true}
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(data)
	assert_eq(GameState.trims_done, 2)
	assert_eq(GameState.rush_day, 5)
	assert_true(bool(GameState.staff_pepped["SF01"]))
