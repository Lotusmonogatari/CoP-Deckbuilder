extends GutTest
## P21 phase A (2026-11-26, Cameron): Political Capital decay, meter decay, holds and difficulty prices.


func test_pc_loses_a_share_above_the_floor() -> void:
	assert_eq(PcDecay.xp_loss(1000), 105, "15% of the 700 above 300")
	assert_eq(PcDecay.xp_loss(300), 0)
	assert_eq(PcDecay.xp_loss(120), 0)
	assert_eq(PcDecay.xp_loss(301), 0, "a share of 1 rounds down to nothing")


func test_the_steady_state_is_about_3813() -> void:
	# 620 earned a week and nothing spent: each week adds 620 and loses 15% of what is above 300.
	var xp := 0
	for week in 300:
		xp += 620
		xp -= PcDecay.xp_loss(xp)
	assert_between(xp, 3800 - 400, 3813 + 400, "it settles near the 3,813 the design expects (the end of the week, before the next 620)")
	assert_lt(PcDecay.xp_loss(xp), 620, "and what fades is about what is earned")


func test_party_support_steps_down_and_stops_at_50() -> void:
	assert_eq(PcDecay.party_support_loss(40), 0)
	assert_eq(PcDecay.party_support_loss(50), 0)
	assert_eq(PcDecay.party_support_loss(52), 2, "never below 50")
	assert_eq(PcDecay.party_support_loss(60), 5)
	assert_eq(PcDecay.party_support_loss(74), 5)
	assert_eq(PcDecay.party_support_loss(75), 8, "one step, not both")
	assert_eq(PcDecay.party_support_loss(100), 8)


func test_awareness_loses_a_share_of_the_distance_above_its_start() -> void:
	assert_eq(PcDecay.awareness_loss(20, 20), 0)
	assert_eq(PcDecay.awareness_loss(15, 20), 0)
	assert_eq(PcDecay.awareness_loss(21, 20), 1, "at least 1 above the start")
	assert_eq(PcDecay.awareness_loss(100, 20), 1, "2% of 80 is 1.6, rounded down")
	assert_eq(PcDecay.awareness_loss(100, 10), 1, "2% of 90 is 1.8")
	assert_eq(PcDecay.awareness_loss(120, 20), 2)


func test_a_hold_costs_a_step_more_each_week_in_a_row() -> void:
	assert_eq(PcDecay.hold_price(200, 50, 0), 200)
	assert_eq(PcDecay.hold_price(200, 50, 2), 300)
	var streaks := PcDecay.next_streaks({"Party support": 1, "Reputation": 3}, ["Party support", "District awareness"])
	assert_eq(streaks, {"Party support": 2, "District awareness": 1}, "a meter not held starts again")


func test_difficulty_scales_prices_to_the_nearest_five() -> void:
	assert_eq(PcDecay.scaled_price(200, Difficulty.STANDARD), 200)
	assert_eq(PcDecay.scaled_price(200, Difficulty.RELAXED), 170)
	assert_eq(PcDecay.scaled_price(200, Difficulty.HARDER), 230)
	assert_eq(PcDecay.scaled_price(60, Difficulty.RELAXED), 50, "51 rounds to 50")
	assert_eq(PcDecay.scaled_price(60, Difficulty.HARDER), 70, "69 rounds to 70")


func test_dues_limit_is_a_share_of_the_funds_cap() -> void:
	assert_eq(int(PartyDues.settings(DataDB.balance)["max_per_week"]), 90000, "the starting cap of 100,000")
	assert_eq(int(PartyDues.settings(DataDB.balance, 1000000)["max_per_week"]), 900000)
	assert_eq(PartyDues.week_dues(PartyDues.settings(DataDB.balance, 1000000), 40, 0), 50000, "computed 50,000 is the base, under the limit")
	assert_eq(int(PartyDues.settings({})["max_per_week"]), 0, "no limit when the row is absent")
