extends GutTest
## Campaign Pressure (Difficulty.gd, 2026-11-02): Relaxed, Standard, Harder.
## Standard must be the game exactly as it was; the others change only the
## Balance numbers the proposal lists, and the tier is raised, never lowered.


func after_each() -> void:
	# Leave the shared singletons the way every other test expects them.
	GameState.start_new_run(str(DataDB.player.get("player_id", "PC01")))


func test_a_tier_can_be_raised_but_not_lowered() -> void:
	assert_true(Difficulty.can_raise_to("relaxed", "standard"))
	assert_true(Difficulty.can_raise_to("standard", "harder"))
	assert_false(Difficulty.can_raise_to("harder", "standard"))
	assert_false(Difficulty.can_raise_to("standard", "standard"))
	assert_false(Difficulty.can_raise_to("standard", "brutal"), "an unknown tier is refused")


func test_standard_returns_the_fallback_and_other_tiers_read_their_row() -> void:
	var balance := {"difficulty_harder_reward_percent": 85, "difficulty_relaxed_reward_percent": 115}
	assert_eq(Difficulty.number(balance, "standard", "reward_percent", 100.0), 100.0)
	assert_eq(Difficulty.number(balance, "harder", "reward_percent", 100.0), 85.0)
	assert_eq(Difficulty.number(balance, "relaxed", "reward_percent", 100.0), 115.0)
	assert_eq(Difficulty.number(balance, "harder", "no_such_lever", 7.0), 7.0, "a blank row falls back")


func test_payout_scales_gains_and_never_touches_a_penalty() -> void:
	var balance := {"difficulty_harder_reward_percent": 85}
	assert_eq(Difficulty.payout(30000, balance, "harder"), 25500)
	assert_eq(Difficulty.payout(0, balance, "harder"), 0)
	assert_eq(Difficulty.payout(-10000, balance, "harder"), -10000)
	assert_eq(Difficulty.payout(30000, balance, "standard"), 30000)


func test_balance_is_rewritten_for_a_tier_and_restored_for_standard() -> void:
	var base := {"dues_reward_percent": 30, "dues_holiday_weeks": 3, "week_decay_multiplier": 2.5,
		"promise_broken_standing": -5, "promise_default_deadline_hours": 48,
		"election_gain_per_week": 2.5, "election_fall_per_week": 1.5,
		"difficulty_harder_dues_reward_percent": 35, "difficulty_harder_dues_holiday_weeks": 0,
		"difficulty_harder_week_decay_multiplier": 3.0, "difficulty_harder_promise_broken_standing": -7,
		"difficulty_harder_promise_deadline_percent": 75, "difficulty_harder_election_gain_per_week": 2.0,
		"difficulty_harder_election_fall_per_week": 2.0}
	var live := base.duplicate()
	Difficulty.apply_balance(live, base, "harder")
	assert_eq(float(live["dues_reward_percent"]), 35.0)
	assert_eq(float(live["dues_holiday_weeks"]), 0.0)
	assert_eq(float(live["week_decay_multiplier"]), 3.0)
	assert_eq(float(live["promise_broken_standing"]), -7.0)
	assert_eq(int(live["promise_default_deadline_hours"]), 36)
	assert_eq(float(live["election_gain_per_week"]), 2.0)
	Difficulty.apply_balance(live, base, "standard")
	assert_eq(float(live["dues_reward_percent"]), 30.0)
	assert_eq(int(live["promise_default_deadline_hours"]), 48)
	assert_eq(float(live["week_decay_multiplier"]), 2.5)


func test_shop_prices_scale_from_the_original_rows() -> void:
	var base: Array = [{"item_id": "A", "cost_yen": 10000, "cost_xp": 0}, {"item_id": "B", "cost_yen": 0, "cost_xp": 100}]
	var live: Array = base.duplicate(true)
	var balance := {"difficulty_harder_item_price_percent": 115, "difficulty_relaxed_item_price_percent": 85}
	Difficulty.apply_shop(live, base, balance, "harder")
	assert_eq(int(live[0]["cost_yen"]), 11500)
	assert_eq(int(live[1]["cost_xp"]), 115)
	assert_eq(int(live[0]["cost_xp"]), 0, "a free price stays free")
	Difficulty.apply_shop(live, base, balance, "relaxed")
	assert_eq(int(live[0]["cost_yen"]), 8500, "it scales from the original, not the last tier")
	Difficulty.apply_shop(live, base, balance, "standard")
	assert_eq(int(live[0]["cost_yen"]), 10000)


func test_a_fight_gets_a_wider_or_narrower_margin() -> void:
	var balance := {"difficulty_harder_opponent_start": 3, "difficulty_relaxed_opponent_start": -3}
	var pool := {"bar_model": "Shared_pool", "opp_start": 40, "win_threshold": 51}
	assert_eq(int(Difficulty.adjust_stage(pool, balance, "harder")["opp_start"]), 43)
	assert_eq(int(Difficulty.adjust_stage(pool, balance, "relaxed")["opp_start"]), 37)
	assert_eq(int(Difficulty.adjust_stage(pool, balance, "standard")["opp_start"]), 40)
	var single := {"bar_model": "Single", "opp_start": 45, "win_threshold": 55}
	assert_eq(int(Difficulty.adjust_stage(single, balance, "harder")["win_threshold"]), 58, "a single bar asks for more")
	assert_eq(int(single["win_threshold"]), 55, "the original stage is not changed")


func test_gaffe_room_never_drops_below_two() -> void:
	var balance := {"difficulty_harder_gaffe_limit": -1, "difficulty_relaxed_gaffe_limit": 1}
	assert_eq(Difficulty.gaffe_limit_bonus(balance, "harder", 4, 0), -1)
	assert_eq(Difficulty.gaffe_limit_bonus(balance, "harder", 2, 0), 0, "a limit of 2 stays 2")
	assert_eq(Difficulty.gaffe_limit_bonus(balance, "relaxed", 3, 1), 2)
	assert_eq(Difficulty.gaffe_limit_bonus(balance, "standard", 1, 0), 0, "Standard never clamps")


func test_leftover_gaffes_cost_more_or_less_awareness() -> void:
	var balance := {"difficulty_harder_awareness_gaffe_percent": 150, "difficulty_relaxed_awareness_gaffe_percent": 50}
	assert_eq(Difficulty.awareness_gaffes(4, balance, "harder"), 6)
	assert_eq(Difficulty.awareness_gaffes(4, balance, "relaxed"), 2)
	assert_eq(Difficulty.awareness_gaffes(4, balance, "standard"), 4)
	assert_eq(Difficulty.awareness_gaffes(0, balance, "harder"), 0)


func test_the_dues_holiday_covers_only_the_first_weeks() -> void:
	assert_true(Difficulty.dues_holiday(0, 3))
	assert_true(Difficulty.dues_holiday(2, 3))
	assert_false(Difficulty.dues_holiday(3, 3))
	assert_false(Difficulty.dues_holiday(0, 0))


func test_a_new_run_takes_the_tier_and_a_standard_run_restores_the_numbers() -> void:
	var standard_share := float(DataDB.balance_base.get("dues_reward_percent", 30))
	assert_true(GameState.start_new_run("PC01", "harder"))
	assert_eq(GameState.difficulty, "harder")
	assert_eq(float(DataDB.balance.get("dues_reward_percent")), float(DataDB.balance_base["difficulty_harder_dues_reward_percent"]))
	assert_true(GameState.start_new_run("PC01"))
	assert_eq(GameState.difficulty, "standard")
	assert_eq(float(DataDB.balance.get("dues_reward_percent")), standard_share)


func test_the_tier_is_raised_in_a_run_and_never_lowered() -> void:
	GameState.start_new_run("PC01", "relaxed")
	assert_true(GameState.raise_difficulty("standard"))
	assert_true(GameState.raise_difficulty("harder"))
	assert_false(GameState.raise_difficulty("relaxed"))
	assert_eq(GameState.difficulty, "harder")


func test_the_tier_survives_a_save_and_an_old_save_loads_as_standard() -> void:
	GameState.start_new_run("PC01", "harder")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.difficulty, "harder")
	assert_eq(float(DataDB.balance.get("dues_reward_percent")), float(DataDB.balance_base["difficulty_harder_dues_reward_percent"]), "the numbers are re-applied on load")
	saved.erase("difficulty")
	GameState.load_save(saved)
	assert_eq(GameState.difficulty, "standard")


func test_a_win_pays_less_on_harder() -> void:
	GameState.start_new_run("PC01", "harder")
	GameState.meta["Funds"] = 0
	var stage := {"stage_id": "STX", "name_en": "Test", "win_delta_yen": 20000, "win_delta_xp": 100}
	var xp_before := GameState.xp
	GameState._apply_stage_rewards(stage, LevelRunner.WON, 0)
	assert_eq(int(GameState.meta["Funds"]), 17000, "85% of 20,000")
	assert_eq(GameState.xp - xp_before, 85, "85% of 100 XP")


func test_the_first_weeks_owe_no_dues_on_standard_and_harder_has_no_holiday() -> void:
	GameState.start_new_run("PC01")
	GameState.week_funds_earned = 100000
	GameState.calendar["week"] = 0
	assert_eq(int(GameState.dues_preview()["week_dues"]), 0, "week 0 is a holiday")
	GameState.calendar["week"] = 3
	assert_gt(int(GameState.dues_preview()["week_dues"]), 0, "week 3 owes dues")
	GameState.start_new_run("PC01", "harder")
	GameState.week_funds_earned = 100000
	GameState.calendar["week"] = 0
	assert_gt(int(GameState.dues_preview()["week_dues"]), 0, "Harder has no holiday")
