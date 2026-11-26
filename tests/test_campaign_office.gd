extends GutTest
## The Campaign Office's actions (P20, 2026-11-26): costs, hours, the weekly limit, the order of effects, the van speech outcomes, the
## Fundraiser yields, lending, the capital ledger and the campaign fund's ceiling.

const BUILDING := "building"
const MUSTERING := "mustering"


func _state(phase: String = BUILDING, staff: Array = [], van_tier: int = 0) -> Dictionary:
	return {"office_open": true, "locked": "", "work_hours_left": 40, "actions_this_week": 0, "phase": phase, "xp": 1000,
		"campaign_fund": 1000000, "van_tier": van_tier, "staff": staff, "date": 100, "penalty_orgs": ["BO18", "BO25"],
		"voters_org": "BO18", "constituency_orgs": ["BO18", "BO25", "BO30"]}


func _member(role: String, tier: int, lent_until: int = -1) -> Dictionary:
	return {"staff_id": "CSX", "role": role, "tier": tier, "lent_until": lent_until}


func _van(tier: int, staff: Array = [], phase: String = BUILDING) -> Dictionary:
	return CampaignOffice.resolve(CampaignOffice.VAN, _state(phase, staff, tier))


func _standing(result: Dictionary, org: String) -> int:
	return int((result["standing"] as Dictionary).get(org, 0))


# --- The van speech (BO18 / BO25 / District) ----------------------------------------------------------------------------------------

func test_van_speech_tier_0_costs_two_with_each_group_and_adds_two_district() -> void:
	var r := _van(0)
	assert_eq([_standing(r, "BO18"), _standing(r, "BO25"), r["district"]], [-2, -2, 2])
	assert_eq(r["fund_spent"], 20000)


func test_van_speech_tier_1_halves_the_penalties() -> void:
	var r := _van(1)
	assert_eq([_standing(r, "BO18"), _standing(r, "BO25"), r["district"]], [-1, -1, 2])


func test_van_speech_tier_2_halves_penalties_and_doubles_rewards() -> void:
	var r := _van(2)
	assert_eq([_standing(r, "BO18"), _standing(r, "BO25"), r["district"]], [-1, -1, 4])


func test_a_tier_1_announcer_adds_one_voters_standing_after_the_multipliers() -> void:
	var r := _van(2, [_member(CampaignOffice.ROLE_ANNOUNCER, 1)])
	assert_eq([_standing(r, "BO18"), _standing(r, "BO25"), r["district"]], [0, -1, 4])


func test_a_tier_2_announcer_also_adds_one_district() -> void:
	var r := _van(2, [_member(CampaignOffice.ROLE_ANNOUNCER, 2)])
	assert_eq([_standing(r, "BO18"), _standing(r, "BO25"), r["district"]], [0, -1, 5])


func test_the_sprint_multiplies_rewards_only() -> void:
	var r := _van(0, [], MUSTERING)
	assert_eq(r["district"], 3, "2 x 1.5")
	assert_eq(_standing(r, "BO18"), -2, "penalties are not multiplied")
	assert_eq(_van(0, [], "announcement")["district"], 3, "the Banners day counts as mustering")
	assert_eq(_van(0, [], "campaign")["district"], 2, "the campaign phase is not the sprint")


func test_a_lent_announcer_gives_no_bonus() -> void:
	var r := _van(2, [_member(CampaignOffice.ROLE_ANNOUNCER, 2, 500)])
	assert_eq([_standing(r, "BO18"), r["district"]], [-1, 4], "lent until day 500, today is day 100")


# --- Fundraising --------------------------------------------------------------------------------------------------------------------

func _yield(staff: Array, phase: String = BUILDING) -> int:
	return int(CampaignOffice.resolve(CampaignOffice.FUNDRAISE, _state(phase, staff))["fund_gain"])


func test_fundraising_yields_with_each_fundraiser_tier() -> void:
	assert_eq(_yield([]), 40000, "no fundraiser: the base yield")
	assert_eq(_yield([_member(CampaignOffice.ROLE_FUNDRAISER, 0)]), 80000)
	assert_eq(_yield([_member(CampaignOffice.ROLE_FUNDRAISER, 1)]), 160000)
	assert_eq(_yield([_member(CampaignOffice.ROLE_FUNDRAISER, 2)]), 320000)


func test_fundraising_in_mustering_is_multiplied_after_the_fundraiser() -> void:
	assert_eq(_yield([_member(CampaignOffice.ROLE_FUNDRAISER, 0)], MUSTERING), 120000, "80,000 x 1.5")
	assert_eq(_yield([_member(CampaignOffice.ROLE_FUNDRAISER, 2)], MUSTERING), 480000)


func test_a_lent_fundraiser_gives_nothing() -> void:
	assert_eq(_yield([_member(CampaignOffice.ROLE_FUNDRAISER, 2, 500)]), 40000)


func test_fundraising_spends_xp_which_becomes_capital() -> void:
	var r := CampaignOffice.resolve(CampaignOffice.FUNDRAISE, _state())
	assert_eq([r["xp_spent"], r["capital_gained"]], [100, 100])


# --- Letters and mailings ------------------------------------------------------------------------------------------------------------

func test_letters_give_three_standing_to_the_chosen_organization() -> void:
	var r := CampaignOffice.resolve(CampaignOffice.LETTERS, _state(), "BO05")
	assert_eq(r["standing"], {"BO05": 3})
	assert_eq([r["xp_spent"], r["capital_gained"]], [60, 60])


func test_letters_in_mustering_round_half_away_from_zero() -> void:
	assert_eq(CampaignOffice.resolve(CampaignOffice.LETTERS, _state(MUSTERING), "BO05")["standing"], {"BO05": 5}, "3 x 1.5 = 4.5 rounds to 5")


func test_a_tier_1_organizer_adds_one_flat_after_everything_else() -> void:
	var organizer := [_member(CampaignOffice.ROLE_ORGANIZER, 1)]
	assert_eq(CampaignOffice.resolve(CampaignOffice.LETTERS, _state(BUILDING, organizer), "BO05")["standing"], {"BO05": 4})
	assert_eq(CampaignOffice.resolve(CampaignOffice.LETTERS, _state(MUSTERING, organizer), "BO05")["standing"], {"BO05": 6}, "5 then +1")


func test_mailings_reach_every_constituency_organization_and_the_district() -> void:
	var r := CampaignOffice.resolve(CampaignOffice.MAILINGS, _state())
	assert_eq(r["standing"], {"BO18": 1, "BO25": 1, "BO30": 1})
	assert_eq([r["district"], r["national"], r["xp_spent"]], [1, 0, 200])


func test_mailings_in_mustering_round_up_to_two() -> void:
	var r := CampaignOffice.resolve(CampaignOffice.MAILINGS, _state(MUSTERING))
	assert_eq(r["standing"]["BO18"], 2, "a positive reward never rounds below 1, and 1.5 rounds to 2")
	assert_eq(r["district"], 2)


func test_a_tier_2_organizer_adds_one_national_awareness_to_mailings() -> void:
	assert_eq(CampaignOffice.resolve(CampaignOffice.MAILINGS, _state(BUILDING, [_member(CampaignOffice.ROLE_ORGANIZER, 1)]))["national"], 0)
	assert_eq(CampaignOffice.resolve(CampaignOffice.MAILINGS, _state(BUILDING, [_member(CampaignOffice.ROLE_ORGANIZER, 2)]))["national"], 1)


# --- Hours ------------------------------------------------------------------------------------------------------------------------

func test_an_action_takes_four_hours_or_two_with_an_organizer_on_letters_and_mailings() -> void:
	var organizer := [_member(CampaignOffice.ROLE_ORGANIZER, 0)]
	assert_eq(CampaignOffice.hours_for(CampaignOffice.LETTERS, _state()), 4)
	assert_eq(CampaignOffice.hours_for(CampaignOffice.LETTERS, _state(BUILDING, organizer)), 2)
	assert_eq(CampaignOffice.hours_for(CampaignOffice.MAILINGS, _state(BUILDING, organizer)), 2)
	assert_eq(CampaignOffice.hours_for(CampaignOffice.FUNDRAISE, _state(BUILDING, organizer)), 4, "only letters and mailings")
	assert_eq(CampaignOffice.hours_for(CampaignOffice.VAN, _state(BUILDING, organizer)), 4)
	assert_eq(CampaignOffice.hours_for(CampaignOffice.LETTERS, _state(BUILDING, [_member(CampaignOffice.ROLE_ORGANIZER, 0, 500)])), 4, "lent")


# --- Can the player act? -------------------------------------------------------------------------------------------------------------

func test_the_weekly_limit_applies_before_the_campaign_and_not_during_it() -> void:
	var state := _state()
	state["actions_this_week"] = 2
	assert_eq(CampaignOffice.can_act(CampaignOffice.LETTERS, state)["reason_key"], "campaign.reason.weekly_limit")
	state["phase"] = MUSTERING
	assert_false(CampaignOffice.can_act(CampaignOffice.LETTERS, state)["ok"], "mustering keeps the limit")
	state["phase"] = "campaign"
	assert_true(CampaignOffice.can_act(CampaignOffice.LETTERS, state)["ok"], "no limit during the campaign")
	state["actions_this_week"] = 20
	assert_true(CampaignOffice.can_act(CampaignOffice.LETTERS, state)["ok"], "only hours limit it")


func test_refusals_come_in_the_order_the_player_should_read_them() -> void:
	var state := _state()
	state["locked"] = "not_selected"
	assert_eq(CampaignOffice.can_act(CampaignOffice.FUNDRAISE, state)["reason_key"], "campaign.office.locked_not_selected")
	state["locked"] = "stepped_aside"
	assert_eq(CampaignOffice.can_act(CampaignOffice.FUNDRAISE, state)["reason_key"], "campaign.office.locked_stepped_aside")
	state = _state()
	state["office_open"] = false
	assert_eq(CampaignOffice.can_act(CampaignOffice.FUNDRAISE, state)["reason_key"], "campaign.reason.office_closed")
	state = _state()
	state["work_hours_left"] = 3
	assert_eq(CampaignOffice.can_act(CampaignOffice.FUNDRAISE, state)["reason_key"], "campaign.reason.no_hours", "a weekend leaves 0 work hours")
	state = _state()
	state["xp"] = 59
	assert_eq(CampaignOffice.can_act(CampaignOffice.LETTERS, state)["reason_key"], "campaign.reason.no_xp")
	state["xp"] = 60
	assert_true(CampaignOffice.can_act(CampaignOffice.LETTERS, state)["ok"])


func test_the_van_speech_needs_a_van_and_the_campaign_fund() -> void:
	var state := _state(BUILDING, [], -1)
	assert_eq(CampaignOffice.can_act(CampaignOffice.VAN, state)["reason_key"], "campaign.reason.no_van")
	state = _state()
	state["campaign_fund"] = 19999
	assert_eq(CampaignOffice.can_act(CampaignOffice.VAN, state)["reason_key"], "campaign.reason.no_fund")
	state["campaign_fund"] = 20000
	assert_true(CampaignOffice.can_act(CampaignOffice.VAN, state)["ok"])
	assert_eq(CampaignOffice.xp_cost(CampaignOffice.VAN), 0, "the van speech costs no XP")


func test_a_message_for_every_refusal_is_a_text_row() -> void:
	for key: String in ["campaign.reason.not_an_action", "campaign.reason.office_closed", "campaign.reason.no_hours", "campaign.reason.weekly_limit",
			"campaign.reason.no_van", "campaign.reason.no_xp", "campaign.reason.no_fund", "campaign.office.locked_not_selected",
			"campaign.office.locked_stepped_aside"]:
		assert_ne(Text.say(key), key, "%s is a Text row" % key)


# --- The ledgers -------------------------------------------------------------------------------------------------------------------

func test_xp_spent_at_the_office_adds_to_capital() -> void:
	assert_eq(CampaignOffice.capital_after_spend(100, 60), 160)
	assert_eq(CampaignOffice.capital_after_spend(100, -5), 100)


func test_capital_fades_five_percent_rounded_down_each_week() -> void:
	assert_eq(CampaignOffice.capital_after_week(3000), 2850)
	assert_eq(CampaignOffice.capital_after_week(100), 95)
	assert_eq(CampaignOffice.capital_after_week(19), 19, "under 20 nothing fades")
	assert_eq(CampaignOffice.capital_after_week(20), 19)
	assert_eq(CampaignOffice.capital_after_week(0), 0)


func test_the_campaign_fund_stops_at_its_ceiling_and_says_how_much_was_lost() -> void:
	assert_eq(CampaignOffice.fund_after_income(1000, 500), {"fund": 1500, "lost": 0})
	assert_eq(CampaignOffice.fund_after_income(99900000, 500000), {"fund": 100000000, "lost": 400000})
	assert_eq(CampaignOffice.fund_after_income(100000000, 1), {"fund": 100000000, "lost": 1})
