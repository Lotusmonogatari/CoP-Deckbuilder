extends GutTest
## P21 phase A (2026-11-26, Cameron): the run's side of Political Capital upkeep. Holds and their streaks, what fades at a week's end, the dues
## bailout, the Funds limit's petition steps and the two calls, and the monthly District 80 coupon.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT
	GameState.meta["Funds"] = 50000


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL


func test_a_week_end_fades_political_capital_party_support_and_awareness() -> void:
	GameState.xp = 1000
	GameState.meta["Party support"] = 60
	GameState.awareness["district"] = 70
	GameState.awareness["national"] = 50
	var lines := GameState._apply_pc_and_meter_decay()
	assert_eq(GameState.xp, 895, "1,000 loses 105")
	assert_eq(int(GameState.meta["Party support"]), 55)
	assert_eq(int(GameState.awareness["district"]), 69, "2% of the 50 above 20 is 1")
	assert_eq(int(GameState.awareness["national"]), 49)
	assert_gt(lines.size(), 3)
	assert_eq(GameState.xp_earned_total, GameState.xp_earned_total, "lifetime Political Capital is not touched")


func test_a_hold_stops_one_meter_and_costs_a_step_more_each_week_in_a_row() -> void:
	GameState.xp = 2000
	GameState.meta["Party support"] = 60
	assert_eq(GameState.hold_price_of("meter:Party support"), 200)
	assert_eq(GameState.buy_hold("meter:Party support"), "")
	assert_eq(GameState.xp, 1800)
	assert_eq(GameState.buy_hold("meter:Party support"), Text.say("upkeep.refuse_held"), "once a week")
	GameState._apply_pc_and_meter_decay()
	assert_eq(int(GameState.meta["Party support"]), 60, "the held meter did not fade")
	assert_eq(GameState.hold_price_of("meter:Party support"), 250, "a second week in a row costs 50 more")
	GameState._apply_pc_and_meter_decay()   # a week without a hold
	assert_eq(GameState.hold_price_of("meter:Party support"), 200, "and a week without resets it")


func test_a_hold_is_refused_when_nothing_fades_or_the_capital_is_short() -> void:
	GameState.meta["Party support"] = 50
	GameState.xp = 2000
	assert_eq(GameState.buy_hold("meter:Party support"), Text.say("upkeep.refuse_not_fading"))
	GameState.meta["Party support"] = 70
	GameState.xp = 100
	assert_eq(GameState.buy_hold("meter:Party support"), Text.say("upkeep.refuse_pc"))
	assert_eq(GameState.xp, 100, "a refused hold costs nothing")


func test_keeping_in_touch_holds_an_organizations_standing_for_the_week() -> void:
	var id := ""
	for booster: Dictionary in DataDB.boosters:
		GameState.booster_standing[str(booster["booster_id"])] = 90
		id = str(booster["booster_id"])
	GameState.xp = 500
	assert_gt(GameState.org_fade(id), 0)
	assert_eq(GameState.hold_price_of("org:" + id), 60)
	assert_eq(GameState.buy_hold("org:" + id), "")
	var other := str(DataDB.boosters[0]["booster_id"]) if str(DataDB.boosters[0]["booster_id"]) != id else str(DataDB.boosters[1]["booster_id"])
	GameState._apply_week_decay()
	assert_eq(int(GameState.booster_standing[id]), 90, "the held organization did not fade")
	assert_lt(int(GameState.booster_standing[other]), 90, "the others did")


func test_prices_follow_the_difficulty() -> void:
	GameState.difficulty = Difficulty.RELAXED
	assert_eq(GameState.hold_price_of("meter:Party support"), 170)
	GameState.difficulty = Difficulty.HARDER
	assert_eq(GameState.hold_price_of("meter:Party support"), 230)


func test_the_dues_bailout_writes_off_ten_thousand_and_never_goes_below_nothing() -> void:
	GameState.xp = 500
	assert_eq(GameState.buy_bailout(), Text.say("upkeep.refuse_no_dues"))
	GameState.dues_balance = 25000
	assert_eq(GameState.buy_bailout(), "")
	assert_eq(GameState.dues_balance, 15000)
	assert_eq(GameState.xp, 400)
	GameState.dues_balance = 4000
	GameState.buy_bailout()
	assert_eq(GameState.dues_balance, 0, "never below nothing owed")


func test_the_petition_price_steps_up_each_purchase() -> void:
	var item := DataDB.get_shop_item("SH13")
	assert_eq(int(item["cost_xp"]), 100)
	GameState.xp = 10000
	GameState.meta["Funds"] = 1000
	assert_true(bool(GameState.buy_funds_cap("SH13")["ok"]))
	assert_eq(int(DataDB.get_shop_item("SH13")["cost_xp"]), 150)
	assert_true(bool(GameState.buy_funds_cap("SH13")["ok"]))
	assert_eq(int(DataDB.get_shop_item("SH13")["cost_xp"]), 200)
	assert_eq(GameState.funds_limit(), 300000)


func test_the_petition_stops_at_one_million_and_the_calls_go_beyond_it() -> void:
	GameState.xp = 100000
	GameState.meta["Party support"] = 90
	GameState.booster_standing[GameState.cap_call_org()] = 90
	assert_eq(GameState.cap_call_refusal(GameState.CAP_PARTY), Text.say("upkeep.cap_refuse_petition", {"ceiling": 1000000}), "petitions come first")
	GameState.funds_cap_bonus = 900000
	assert_true(GameState.funds_cap_maxed(), "the petition reads 1,000,000 as its ceiling")
	assert_eq(GameState.funds_limit(), 1000000)
	assert_eq(GameState.buy_cap_call(GameState.CAP_PARTY), "")
	assert_eq(GameState.funds_limit(), 1500000)
	assert_eq(int(GameState.meta["Party support"]), 40, "50 Party support paid")
	assert_eq(GameState.xp, 99800, "200 Political Capital paid together")
	assert_eq(GameState.buy_cap_call(GameState.CAP_PARTY), Text.say("upkeep.cap_refuse_done"), "once per run")
	assert_eq(GameState.buy_cap_call(GameState.CAP_FINANCE), "")
	assert_eq(GameState.funds_limit(), 2000000, "the hard ceiling")
	assert_eq(int(GameState.booster_standing[GameState.cap_call_org()]), 50)


func test_the_calls_need_support_and_standing_over_70() -> void:
	GameState.xp = 10000
	GameState.funds_cap_bonus = 900000
	GameState.meta["Party support"] = 70
	GameState.booster_standing[GameState.cap_call_org()] = 70
	assert_ne(GameState.cap_call_refusal(GameState.CAP_PARTY), "", "over 70, not at 70")
	assert_ne(GameState.cap_call_refusal(GameState.CAP_FINANCE), "")
	GameState.meta["Party support"] = 71
	assert_eq(GameState.cap_call_refusal(GameState.CAP_PARTY), "")


func test_the_dues_limit_follows_the_funds_cap() -> void:
	GameState.funds_cap_bonus = 900000
	assert_eq(int(PartyDues.settings(DataDB.balance, GameState.funds_limit())["max_per_week"]), 900000)


func test_the_district_80_coupon_pays_once_a_month() -> void:
	GameState.awareness["district"] = 85
	GameState.inventory = {}
	var first := GameState._apply_awareness_week_end()
	var coupon := str(DataDB.get_rule("training_coupon_item", ""))
	assert_eq(int(GameState.inventory.get(coupon, 0)), 1, "the first week of the month pays")
	GameState._apply_awareness_week_end()
	assert_eq(int(GameState.inventory.get(coupon, 0)), 1, "the second week the same month does not")
	GameState.calendar = {"week": int(GameState.calendar["week"]) + 6, "phase": "work", "hours": 0}
	GameState._apply_awareness_week_end()
	assert_eq(int(GameState.inventory.get(coupon, 0)), 2, "a later month pays again")
	assert_gt(first.size(), 0)


func test_the_new_state_survives_a_save_and_an_old_save_gets_its_petition_count() -> void:
	GameState.decay_holds = ["meter:Reputation"]
	GameState.hold_streaks = {"meter:Reputation": 2}
	GameState.cap_calls_done = ["party"]
	GameState.funds_cap_petitions = 3
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(data)
	assert_eq(GameState.decay_holds, ["meter:Reputation"])
	assert_eq(int(GameState.hold_streaks["meter:Reputation"]), 2)
	assert_eq(GameState.cap_calls_done, ["party"])
	assert_eq(GameState.funds_cap_petitions, 3)
	data.erase("funds_cap_petitions")
	data["funds_cap_bonus"] = 400000
	GameState.load_save(data)
	assert_eq(GameState.funds_cap_petitions, 4, "an older save: the petitions already bought")
