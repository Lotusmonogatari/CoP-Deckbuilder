extends GutTest
## P21 phase B (2026-11-26, Cameron): gaffe thresholds, Blunders!, the spokesperson's cancel, the floor and the accusation roll.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false


func test_a_total_that_passes_several_thresholds_in_one_stage_rolls_once_for_each() -> void:
	assert_eq(Blunders.crossed(0, 29, 30), 0)
	assert_eq(Blunders.crossed(29, 31, 30), 1)
	assert_eq(Blunders.crossed(20, 95, 30), 3, "30, 60 and 90")
	assert_eq(Blunders.crossed(0, 120, 25), 4)
	assert_eq(Blunders.crossed(50, 50, 25), 0)


func test_the_draw_is_the_same_for_the_same_seed_and_counter() -> void:
	assert_eq(Blunders.draw(1234, 7), Blunders.draw(1234, 7))
	assert_ne(Blunders.draw(1234, 7), Blunders.draw(1234, 8))
	assert_ne(Blunders.draw(1234, 7), Blunders.draw(4321, 7))
	var r := Blunders.draw(99, 1)
	assert_true(r >= 0.0 and r < 1.0)


func test_a_blunder_takes_ten_but_never_below_the_floor_of_21() -> void:
	assert_eq(Blunders.loss(60), 10)
	assert_eq(Blunders.loss(31), 10)
	assert_eq(Blunders.loss(28), 7, "down to 21 and no further")
	assert_eq(Blunders.loss(21), 0, "at the floor: nothing")
	assert_eq(Blunders.loss(10), 0, "under it: nothing")


func test_cancel_prices_fall_with_the_spokespersons_tier() -> void:
	assert_eq(Blunders.cancel_price(0), 200)
	assert_eq(Blunders.cancel_price(1), 150)
	assert_eq(Blunders.cancel_price(2), 100)
	assert_eq(Blunders.cancel_price(9), 100, "a tier above the top is the top")


func test_cancelling_halves_both_accusation_chances() -> void:
	# Scandal 1/8 = 0.125; Rumor 1/3. A roll of 0.1 is a Scandal! unless cancelled (then the chance is 0.0625).
	assert_eq(Blunders.accusation(false, 0.1, 0.9), "scandal")
	assert_eq(Blunders.accusation(true, 0.1, 0.9), "", "halved: 0.1 is over 0.0625")
	assert_eq(Blunders.accusation(false, 0.9, 0.3), "rumor")
	assert_eq(Blunders.accusation(true, 0.9, 0.3), "", "halved: 0.3 is over 0.1667")
	assert_eq(Blunders.accusation(true, 0.9, 0.1), "rumor")
	assert_eq(Blunders.accusation(false, 0.05, 0.05), "scandal", "the Scandal! is checked first")


func test_gaffes_add_to_one_run_total_and_progress_is_shown() -> void:
	GameState.gaffe_total = 0
	GameState.apply_awareness_gaffes(10)
	GameState.apply_awareness_gaffes(14)
	assert_eq(GameState.gaffe_total, 24)
	var progress := GameState.blunder_progress()
	assert_eq(int(progress["awareness_at"]), 30)
	assert_eq(int(progress["blunder_at"]), 25)


func test_a_threshold_roll_can_queue_a_blunder_and_the_run_is_deterministic() -> void:
	var seed_value := GameState.run_seed
	var first := _queued_after(100)
	GameState.start_new_run("PC01")
	GameState.run_seed = seed_value
	var second := _queued_after(100)
	assert_eq(first, second, "the same seed gives the same Blunders!")


func _queued_after(gaffes: int) -> int:
	GameState.gaffe_total = 0
	GameState.blunder_rolls = 0
	GameState.blunder_cards = []
	for i in gaffes:
		GameState.apply_awareness_gaffes(1)
	return GameState.blunder_cards.size() * 1000 + int(GameState.awareness["district"]) * 10 + int(GameState.awareness["national"])


func test_a_stage_lost_to_gaffes_makes_its_own_check() -> void:
	var rolls_before := GameState.blunder_rolls
	GameState.apply_awareness_gaffes(5, true)
	assert_gt(GameState.blunder_rolls, rolls_before, "a lost stage rolls even under every threshold")
	var rolls_mid := GameState.blunder_rolls
	GameState.apply_awareness_gaffes(5, false)
	assert_eq(GameState.blunder_rolls, rolls_mid, "a stage that was not lost does not")


func test_taking_a_blunder_costs_ten_awareness_and_never_below_the_floor() -> void:
	GameState.awareness = {"district": 60, "national": 25}
	GameState.blunder_cards = [{"id": 1}]
	var done := GameState.resolve_blunder(false)
	assert_true(bool(done["ok"]))
	assert_eq(int(GameState.awareness["district"]), 50)
	assert_eq(int(GameState.awareness["national"]), 21, "25 would have gone to 15: held at the floor")
	assert_eq(int(done["lost_national"]), 4)
	assert_true(GameState.blunder_cards.is_empty())


func test_a_media_spokesperson_cancels_for_the_price_of_their_tier() -> void:
	var spokesperson_row := {}
	for row: Dictionary in DataDB.staff:
		if str(row["role"]) == "Media Spokesperson":
			spokesperson_row = row
	assert_false(spokesperson_row.is_empty())
	assert_eq(GameState.blunder_spokesperson(), {}, "none hired: nobody to ask")
	GameState.blunder_cards = [{"id": 1}]
	assert_eq(GameState.blunder_cancel_refusal(), Text.say("blunder.no_spokesperson"))
	GameState.xp = 1000
	GameState.meta["Funds"] = 1000000
	GameState.hire_staff(str(spokesperson_row["staff_id"]))
	var who := GameState.blunder_spokesperson()
	assert_false(who.is_empty())
	assert_eq(int(who["price"]), Blunders.cancel_price(int(who["tier"])))
	GameState.awareness = {"district": 60, "national": 60}
	var done := GameState.resolve_blunder(true)
	assert_true(bool(done["ok"]))
	assert_eq(int(GameState.awareness["district"]), 60, "cancelled: nothing lost")
	assert_eq(GameState.xp, 1000 - int(who["price"]))


func test_cancel_is_refused_without_the_capital() -> void:
	var row := {}
	for staff_row: Dictionary in DataDB.staff:
		if str(staff_row["role"]) == "Media Spokesperson":
			row = staff_row
	GameState.meta["Funds"] = 1000000
	GameState.xp = 5000
	GameState.hire_staff(str(row["staff_id"]))
	GameState.xp = 10
	GameState.blunder_cards = [{"id": 1}]
	assert_eq(GameState.blunder_cancel_refusal(), Text.say("blunder.refuse_pc"))
	assert_false(bool(GameState.resolve_blunder(true)["ok"]))
	assert_eq(GameState.blunder_cards.size(), 1, "a refused cancel leaves the Blunder! waiting")


func test_an_accusation_is_recorded_not_shown() -> void:
	# Find a counter whose draws give a Scandal! or Rumor! for a taken Blunder!, then check it is recorded.
	var found := false
	for seed_value in range(1, 400):
		GameState.run_seed = seed_value
		GameState.blunder_rolls = 0
		GameState.accusations_pending = []
		GameState.blunder_cards = [{"id": 1}]
		var done := GameState.resolve_blunder(false)
		if not str(done["accusation"]).is_empty():
			assert_eq(GameState.accusations_pending.size(), 1)
			assert_eq(str(GameState.accusations_pending[0]["kind"]), str(done["accusation"]))
			assert_eq(str(GameState.accusations_pending[0]["target"]), "player")
			found = true
			break
	assert_true(found, "some seed leaves an accusation")


func test_the_new_state_survives_a_save_and_an_old_save_keeps_its_tally() -> void:
	GameState.gaffe_total = 44
	GameState.blunder_count = 2
	GameState.blunder_cards = [{"id": 2}]
	GameState.accusations_pending = [{"kind": "rumor"}]
	GameState.blunder_rolls = 9
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(data)
	assert_eq(GameState.gaffe_total, 44)
	assert_eq(GameState.blunder_count, 2)
	assert_eq(GameState.blunder_cards.size(), 1)
	assert_eq(GameState.blunder_rolls, 9)
	data.erase("gaffe_total")
	data["awareness_gaffe_tally"] = {"district": 31, "national": 31}
	GameState.load_save(data)
	assert_eq(GameState.gaffe_total, 31, "an older save: the District tally is the total")
