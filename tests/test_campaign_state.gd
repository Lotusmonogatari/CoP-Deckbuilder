extends GutTest
## P20 phase B (2026-11-26, Cameron): the run's side of the campaign. What an action spends and gives, the weekly limit, hiring, the van, the
## Donate button, the week's end (wages, Loyalty, fading capital, the action count), staff leaving after Election Day, the phase banners and
## the save.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT
	GameState.open_venue("VN10")


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL


## Moves the calendar to the first week whose Monday is in `phase`, and returns false when none is (a data change that broke the test).
func _go_to(phase: String, work_hours: int = 0) -> bool:
	for week in range(1, 700):
		GameState.calendar = {"week": week, "phase": "work", "hours": work_hours}
		if str(GameState.election_phase()["phase"]) == phase and bool(GameState.election_phase()["player_runs"]):
			return true
	return false


func test_an_action_spends_hours_xp_and_capital_and_counts() -> void:
	assert_true(_go_to("building"))
	GameState.xp = 1000
	var hours_before := GameState.work_hours_left()
	var done := GameState.campaign_act(CampaignOffice.FUNDRAISE)
	assert_true(bool(done["ok"]), str(done["reason"]))
	assert_eq(GameState.work_hours_left(), hours_before - 4, "the action takes campaign_action_hours")
	assert_eq(GameState.xp, 900, "100 XP spent")
	assert_eq(GameState.campaign_capital, 100, "what was spent is capital now")
	assert_eq(GameState.campaign_actions_week, 1)
	assert_gt(GameState.campaign_fund, 0, "the fund got the yield")


func test_the_weekly_limit_stops_a_third_action_before_the_campaign_opens() -> void:
	assert_true(_go_to("building"))
	GameState.xp = 5000
	assert_true(bool(GameState.campaign_act(CampaignOffice.FUNDRAISE)["ok"]))
	assert_true(bool(GameState.campaign_act(CampaignOffice.FUNDRAISE)["ok"]))
	var third := GameState.campaign_act(CampaignOffice.FUNDRAISE)
	assert_false(bool(third["ok"]))
	assert_eq(str(third["reason"]), Text.say("campaign.reason.weekly_limit"))
	assert_eq(GameState.xp, 4800, "a refused action costs nothing")


func test_letters_need_an_organization() -> void:
	assert_true(_go_to("building"))
	GameState.xp = 1000
	var refused := GameState.campaign_act(CampaignOffice.LETTERS)
	assert_false(bool(refused["ok"]))
	assert_eq(GameState.xp, 1000)


func test_a_closed_office_refuses() -> void:
	assert_true(_go_to("building"))
	GameState.venues_opened = []
	GameState.xp = 1000
	assert_false(bool(GameState.campaign_act(CampaignOffice.FUNDRAISE)["ok"]))


func test_the_other_cycle_locks_the_office_for_a_player_who_does_not_run() -> void:
	var found := false
	for week in range(1, 700):
		GameState.calendar = {"week": week, "phase": "work", "hours": 0}
		if not bool(GameState.election_phase()["player_runs"]) and str(GameState.election_phase()["phase"]) != "building":
			found = true
			break
	assert_true(found, "the data has a cycle the player does not run in")
	assert_eq(GameState.campaign_locked(), "stepped_aside")
	assert_false(GameState.campaign_donate_visible())
	assert_ne(GameState.campaign_hire("CS01"), "")


func test_donate_moves_funds_one_way_and_is_a_district_button() -> void:
	assert_true(_go_to("building"))
	GameState.meta["Funds"] = 60000
	assert_eq(GameState.campaign_donate(10000), "")
	assert_eq(int(GameState.meta["Funds"]), 50000)
	assert_eq(GameState.campaign_fund, 10000)
	assert_ne(GameState.campaign_donate(999999), "", "more than the player has")
	assert_ne(GameState.campaign_donate(0), "")
	GameState.office_location = Offices.CAPITOL
	assert_false(GameState.campaign_donate_visible())
	assert_eq(GameState.campaign_donate(10000), Text.say("campaign.reason.not_district"))


func test_the_donate_steps_come_from_the_rules() -> void:
	assert_eq(GameState.campaign_donate_steps(), [10000, 50000, 100000, 500000] as Array[int])


func test_a_donation_past_the_fund_ceiling_loses_the_overflow() -> void:
	assert_true(_go_to("building"))
	var ceiling := Levers.whole("election_war_chest_limit")
	GameState.campaign_fund = ceiling - 5000
	GameState.meta["Funds"] = 100000
	GameState.campaign_donate(10000)
	assert_eq(GameState.campaign_fund, ceiling)


func test_the_van_is_bought_then_upgraded_from_the_fund() -> void:
	assert_true(_go_to("building"))
	assert_eq(GameState.campaign_van_next_cost(), 500000)
	assert_ne(GameState.campaign_buy_van(), "", "no fund yet")
	GameState.campaign_fund = 5000000
	assert_eq(GameState.campaign_buy_van(), "")
	assert_eq(GameState.campaign_van_tier, 0)
	assert_eq(GameState.campaign_fund, 4500000)
	assert_eq(GameState.campaign_buy_van(), "")
	assert_eq(GameState.campaign_buy_van(), "")
	assert_eq(GameState.campaign_van_tier, 2)
	assert_eq(GameState.campaign_van_next_cost(), -1)
	assert_ne(GameState.campaign_buy_van(), "", "the top tier is the top")


func test_hiring_costs_capital_and_yen_and_a_second_hire_is_refused() -> void:
	assert_true(_go_to("building"))
	GameState.campaign_capital = 300
	GameState.campaign_fund = 1000000
	var id := str(DataDB.campaign_staff[0]["staff_id"])
	assert_eq(GameState.campaign_hire(id), "")
	assert_eq(GameState.campaign_capital, 150)
	assert_eq(GameState.campaign_fund, 700000)
	assert_eq(GameState.campaign_hire(id), Text.say("campaign.reason.already_hired"))
	assert_eq(GameState.campaign_staff_hired.size(), 1)


func test_hiring_is_refused_without_capital() -> void:
	assert_true(_go_to("building"))
	GameState.campaign_fund = 1000000
	var id := str(DataDB.campaign_staff[0]["staff_id"])
	assert_eq(GameState.campaign_hire(id), Text.say("campaign.reason.no_capital"))


func test_an_upgrade_costs_and_raises_the_tier() -> void:
	assert_true(_go_to("building"))
	GameState.campaign_capital = 2000
	GameState.campaign_fund = 5000000
	var id := str(DataDB.campaign_staff[0]["staff_id"])
	assert_eq(GameState.campaign_hire(id), "")
	var tier_before := int(GameState.campaign_member(id)["tier"])
	var why := GameState.campaign_upgrade(id)
	if why.is_empty():
		assert_eq(int(GameState.campaign_member(id)["tier"]), tier_before + 1)
	else:
		assert_eq(why, Text.say("campaign.reason.top_tier"), "only the top tier may refuse here")


func test_the_week_end_pays_wages_from_the_fund_and_resets_the_count() -> void:
	assert_true(_go_to("building"))
	GameState.campaign_capital = 300
	GameState.campaign_fund = 2000000
	var id := str(DataDB.campaign_staff[0]["staff_id"])
	GameState.campaign_hire(id)
	GameState.campaign_actions_week = 2
	var fund_before := GameState.campaign_fund
	var lines := GameState._settle_campaign_week()
	assert_lt(GameState.campaign_fund, fund_before, "a wage left the fund")
	assert_eq(GameState.campaign_actions_week, 0)
	assert_eq(int(GameState.campaign_staff_weeks[id]), 1)
	assert_gt(lines.size(), 0, "the popup hears of the wage")


func test_an_unpaid_week_is_named() -> void:
	assert_true(_go_to("building"))
	GameState.campaign_capital = 300
	GameState.campaign_fund = 300000
	var id := str(DataDB.campaign_staff[0]["staff_id"])
	GameState.campaign_hire(id)
	GameState.campaign_fund = 0
	var lines := GameState._settle_campaign_week()
	var text := "\n".join(lines)
	assert_true(text.contains(str(DataDB.campaign_staff[0]["name"])), "the unpaid staff member is named")


func test_capital_fades_at_the_week_end() -> void:
	GameState.campaign_capital = 1000
	var lines := GameState._settle_campaign_week()
	assert_lt(GameState.campaign_capital, 1000)
	assert_gt(lines.size(), 0)


func test_staff_go_home_after_election_day() -> void:
	var day := int(ElectionCycle.normalized(DataDB.election_cycles)[0]["day"])
	GameState.campaign_staff_hired = [{"staff_id": "CS01", "tier": 0, "loyalty": 60}]
	assert_eq(GameState._campaign_after_election(day - 3, day - 1), [] as Array[String], "not yet")
	assert_eq(GameState._campaign_after_election(day - 3, day + 4).size(), 1, "the line for the new-week popup")
	assert_eq(GameState.campaign_staff_hired.size(), 0)


func test_the_banner_comes_once_with_two_pages_at_the_announcement() -> void:
	assert_true(_go_to("announcement"))
	var due := GameState.campaign_banner_due()
	assert_false(due.is_empty())
	assert_eq(due["pages"], ["announcement", "mustering"])
	GameState.campaign_banner_shown(str(due["key"]))
	assert_true(GameState.campaign_banner_due().is_empty(), "shown once")


func test_a_missed_banner_shows_late_but_only_the_newest() -> void:
	assert_true(_go_to("campaign"))
	var due := GameState.campaign_banner_due()
	assert_eq(due["pages"], ["campaign"])
	GameState.campaign_banner_shown(str(due["key"]))
	assert_eq(GameState.campaign_banners_shown.size(), 2, "the announcement one is marked shown too")


func test_no_banner_for_a_cycle_the_player_does_not_run_in() -> void:
	for week in range(1, 700):
		GameState.calendar = {"week": week, "phase": "work", "hours": 0}
		var info := GameState.election_phase()
		if not str(info["cycle_id"]).is_empty() and not bool(info["player_runs"]):
			assert_true(GameState.campaign_banner_due().is_empty())
			return
	fail_test("no such week found")


func test_election_cycle_helpers() -> void:
	var cycles: Array = DataDB.election_cycles
	var first := ElectionCycle.normalized(cycles)[0] as Dictionary
	var announce := int(first["banners"])
	var info := ElectionCycle.days_until_next_phase(announce - 10, cycles)
	assert_eq(int(info["days"]), 10)
	assert_eq(ElectionCycle.start_of(ElectionCycle.ANNOUNCEMENT, announce + 3, cycles), announce)
	assert_true(ElectionCycle.passed_between(int(first["day"]) - 1, int(first["day"]) + 1, cycles))


func test_the_sprint_is_the_half_again_the_banner_says() -> void:
	assert_eq(float(DataDB.balance.get("campaign_sprint_multiplier")), 1.5, "the Mustering banner text says half again: change the words with the number")


func test_the_new_fields_survive_a_save() -> void:
	GameState.campaign_fund = 123456
	GameState.campaign_capital = 77
	GameState.campaign_van_tier = 1
	GameState.campaign_staff_hired = [{"staff_id": "CS02", "tier": 1, "loyalty": 55}]
	GameState.campaign_banners_shown = ["EC01:announcement"]
	GameState.campaign_howto_seen = true
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	assert_eq(GameState.campaign_fund, 0, "a new run starts clean")
	GameState.load_save(data)
	assert_eq(GameState.campaign_fund, 123456)
	assert_eq(GameState.campaign_capital, 77)
	assert_eq(GameState.campaign_van_tier, 1)
	assert_eq((GameState.campaign_staff_hired[0] as Dictionary)["staff_id"], "CS02")
	assert_eq(GameState.campaign_banners_shown, ["EC01:announcement"])
	assert_true(GameState.campaign_howto_seen)
