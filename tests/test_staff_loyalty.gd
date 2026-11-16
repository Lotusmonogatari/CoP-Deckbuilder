extends GutTest
## Staff wages and Loyalty (Cameron, 2026-11-16): the pure rules, then the week
## end in a real run.

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 1000000
	GameState.dues_balance = 0
	GameState.staff_recruitment_tier = 2


func _hire(staff_id: String) -> void:
	assert_eq(GameState.hire_staff(staff_id), "", "hired " + staff_id)


# --- rules ----------------------------------------------------------------

func test_wage_is_ten_percent_of_everything_invested() -> void:
	assert_eq(StaffLoyalty.wage(40000, false), 4000)
	assert_eq(StaffLoyalty.wage(130000, false), 13000, "hire plus upgrades")
	assert_eq(StaffLoyalty.wage(40000, true), 6000, "raised pay is half as much again")


func test_new_hire_starts_loyal_enough_to_work() -> void:
	_hire("SF01")
	assert_eq(GameState.staff_loyalty_of("SF01"), 30)
	assert_eq(StaffLoyalty.band(30), StaffLoyalty.BAND_NORMAL, "30 is not restless")
	assert_eq(StaffLoyalty.band(29), StaffLoyalty.BAND_RESTLESS)
	assert_eq(StaffLoyalty.band(14), StaffLoyalty.BAND_LEAVING)


func test_affinity_moves_two_per_ten_points_from_fifty() -> void:
	var allies := {"BO01": 1}
	assert_eq(StaffLoyalty.affinity(allies, {"BO01": 70}), 4)
	assert_eq(StaffLoyalty.affinity(allies, {"BO01": 100}), 10)
	assert_eq(StaffLoyalty.affinity(allies, {"BO01": 20}), -6)
	assert_eq(StaffLoyalty.affinity(allies, {"BO01": 50}), 0)


func test_affinity_weights_an_organization_by_how_often_it_is_named() -> void:
	# Heavy tie to BO16 (3), light to BO17 (1): average (3*90 + 1*30) / 4 = 75 -> +5.
	assert_eq(StaffLoyalty.affinity({"BO16": 3, "BO17": 1}, {"BO16": 90, "BO17": 30}), 5)


func test_allies_count_each_mention_of_the_ranks_held() -> void:
	var marcus := DataDB.get_staff("SF04")
	var at_zero := StaffLoyalty.allies(marcus, 0)
	var at_two := StaffLoyalty.allies(marcus, 2)
	assert_eq(int(at_zero.get("BO16", 0)), 1)
	assert_eq(int(at_two.get("BO16", 0)), 3, "BO16 is named three times by rank 2")
	assert_eq(int(at_two.get("BO17", 0)), 1)


func test_paid_week_adds_two_and_a_missed_week_takes_twenty() -> void:
	assert_eq(StaffLoyalty.weekly_total(true, 0, 0, 0, 0), 2)
	assert_eq(StaffLoyalty.weekly_total(false, 0, 0, 0, 0), -20)


func test_weekly_swing_is_capped() -> void:
	assert_eq(StaffLoyalty.weekly_total(true, 30, 0, 0, 0), 15, "gain cap")
	assert_eq(StaffLoyalty.weekly_total(false, -30, 0, 0, 0), -30, "loss cap")


func test_pay_order_primary_first_then_least_loyal() -> void:
	var order := StaffLoyalty.pay_order([
		{"staff_id": "B", "primary": false, "loyalty": 80},
		{"staff_id": "A", "primary": false, "loyalty": 20},
		{"staff_id": "P", "primary": true, "loyalty": 90}])
	assert_eq(str(order[0]["staff_id"]), "P")
	assert_eq(str(order[1]["staff_id"]), "A")
	assert_eq(str(order[2]["staff_id"]), "B")


func test_nobody_is_part_paid() -> void:
	var result := StaffLoyalty.settle_wages([{"staff_id": "A", "wage": 6000}, {"staff_id": "B", "wage": 5000}], 7000)
	assert_eq(result["paid"], ["A"])
	assert_eq(result["missed"], ["B"])
	assert_eq(int(result["spent"]), 6000)


func test_rank_is_lost_only_after_a_missed_wage_under_fifteen() -> void:
	assert_true(bool(StaffLoyalty.after_week(14, true, 2, 0)["rank_lost"]))
	assert_false(bool(StaffLoyalty.after_week(14, false, 2, 0)["rank_lost"]), "paid: no loss")
	assert_false(bool(StaffLoyalty.after_week(15, true, 2, 0)["rank_lost"]), "15 is not under 15")
	assert_false(bool(StaffLoyalty.after_week(14, true, 0, 0)["rank_lost"]), "nothing below the hired rank")
	assert_eq(int(StaffLoyalty.after_week(14, true, 2, 0)["loyalty"]), 35, "restarts higher")


func test_zero_loyalty_quits() -> void:
	assert_true(bool(StaffLoyalty.after_week(0, false, 0, 0)["quits"]))


func test_leaving_penalties_quit_versus_fire() -> void:
	var quit := StaffLoyalty.leaving_penalty({"BO16": 3, "BO17": 1}, true)
	assert_eq(int(quit["reputation"]), -15)
	assert_eq(int(quit["standing"]["BO16"]), -60, "20 times a weight of three")
	assert_eq(int(quit["standing"]["BO17"]), -20)
	var fire := StaffLoyalty.leaving_penalty({"BO16": 3}, false)
	assert_eq(int(fire["reputation"]), 0, "firing costs no Reputation")
	assert_eq(int(fire["standing"]["BO16"]), -9)


func test_a_restless_person_does_strong_work_as_fair() -> void:
	assert_eq(StaffLoyalty.weakened_fit("strong", 20), "fair")
	assert_eq(StaffLoyalty.weakened_fit("fair", 20), "fair")
	assert_eq(StaffLoyalty.weakened_fit("fair", 10), "poor")
	assert_eq(StaffLoyalty.weakened_fit("strong", 60), "strong")


func test_severance_is_three_times_the_hiring_price() -> void:
	var hana := DataDB.get_staff("SF01")
	assert_eq(Ledger.staff_firing_cost(hana), 120000)


# --- the week end in a real run --------------------------------------------

func test_wages_are_paid_after_dues_and_loyalty_rises() -> void:
	_hire("SF01")
	GameState.booster_standing["BO21"] = 60   # an ally you treat well
	var before := int(GameState.meta["Funds"])
	var report := GameState._settle_staff_week()
	assert_eq(int(report["paid_total"]), 4000)
	assert_eq(int(GameState.meta["Funds"]), before - 4000)
	assert_gt(GameState.staff_loyalty_of("SF01"), 30, "paid on time: Loyalty up")


func test_a_missed_wage_drops_loyalty_and_is_reported() -> void:
	_hire("SF01")
	GameState.meta["Funds"] = 1000
	var report := GameState._settle_staff_week()
	assert_eq(report["missed"], ["Hana Takahashi"])
	assert_lt(GameState.staff_loyalty_of("SF01"), 30)


func test_a_person_with_no_loyalty_left_quits_for_good_at_a_cost() -> void:
	_hire("SF01")
	GameState.staff_loyalty["SF01"] = 5
	GameState.meta["Funds"] = 0
	GameState.meta["Reputation"] = 50
	var report := GameState._settle_staff_week()
	assert_eq((report["quit"] as Array).size(), 1)
	assert_true(GameState.hired_member("SF01").is_empty(), "off the staff list")
	assert_true(bool(GameState.staff_quit["SF01"]))
	assert_eq(int(GameState.meta["Reputation"]), 35, "Reputation -15")
	assert_ne(GameState.hire_staff("SF01"), "", "never hireable again")


func test_a_lost_rank_takes_its_rewards_back_and_can_be_bought_again() -> void:
	_hire("SF02")
	GameState.meta["Funds"] = 1000000
	GameState.staff_loyalty["SF02"] = 60
	assert_eq(GameState.upgrade_staff_member("SF02"), "", "rank 1 bought")
	for ally: String in StaffLoyalty.allies(DataDB.get_staff("SF02"), 1).keys():
		GameState.booster_standing[ally] = 50   # no affinity either way
	var standing_before := GameState.booster_standing.duplicate()
	GameState.staff_loyalty["SF02"] = 28
	GameState.meta["Funds"] = 0
	var report := GameState._settle_staff_week()
	assert_eq(report["rank_lost"], ["Yui Kobayashi"])
	assert_eq(int(GameState.hired_member("SF02")["tier"]), 0)
	GameState.staff_loyalty["SF02"] = 60
	GameState.meta["Funds"] = 1000000
	assert_eq(GameState.upgrade_staff_member("SF02"), "", "the rank can be bought again")
	assert_eq(int(GameState.hired_member("SF02")["tier"]), 1)
	assert_gt(int(standing_before.size()), 0)


func test_upgrades_count_toward_the_wage() -> void:
	_hire("SF02")
	assert_eq(GameState.staff_wage_of("SF02"), 3000)
	GameState.staff_loyalty["SF02"] = 60
	assert_eq(GameState.upgrade_staff_member("SF02"), "")
	assert_eq(GameState.staff_wage_of("SF02"), 9000, "30,000 hire plus 60,000 upgrade is 90,000")


func test_a_restless_person_will_not_take_a_promotion() -> void:
	_hire("SF02")
	GameState.staff_loyalty["SF02"] = 20
	assert_ne(GameState.upgrade_staff_member("SF02"), "")
	assert_eq(int(GameState.hired_member("SF02")["tier"]), 0)


func test_raise_pay_costs_more_and_pays_loyalty_once_a_week() -> void:
	_hire("SF01")
	assert_eq(GameState.raise_pay("SF01"), "")
	assert_eq(GameState.staff_loyalty_of("SF01"), 40)
	assert_eq(GameState.staff_wage_of("SF01"), 6000)
	assert_ne(GameState.raise_pay("SF01"), "", "once a week")


func test_firing_costs_no_reputation_but_hits_the_allies() -> void:
	_hire("SF01")
	GameState.meta["Reputation"] = 50
	var before := int(GameState.booster_standing["BO21"])
	assert_eq(GameState.fire_staff_member("SF01"), "")
	assert_eq(int(GameState.meta["Reputation"]), 50)
	assert_eq(int(GameState.booster_standing["BO21"]), before - 3)


func test_an_old_save_gets_loyalty_and_invested_filled_in() -> void:
	_hire("SF01")
	GameState.staff_loyalty = {}
	GameState.staff_invested = {}
	GameState.sanitize_loaded_run()
	assert_eq(GameState.staff_loyalty_of("SF01"), 30)
	assert_eq(int(GameState.staff_invested["SF01"]), 40000)


func test_loyalty_survives_a_save_round_trip() -> void:
	_hire("SF01")
	GameState.staff_loyalty["SF01"] = 77
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.staff_loyalty_of("SF01"), 77)
