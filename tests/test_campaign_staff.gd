extends GutTest
## Campaign staff (P20, 2026-11-26): prices that double, the available rule, the hiring window around Election Day, wages from yen only, lending
## and Loyalty.

func _row(staff_id: String) -> Dictionary:
	for row: Dictionary in DataDB.campaign_staff:
		if str(row["staff_id"]) == staff_id:
			return row
	return {}


func _d(text: String) -> int:
	return WeekCalendar.parse_date(text)


func test_the_six_placeholder_staff_are_in_the_data() -> void:
	assert_eq(DataDB.campaign_staff.size(), 6)
	assert_eq(_row("CS01")["role"], "Campaign Organizer")
	assert_eq(_row("CS04")["name"], "Umina Kota")
	assert_eq([CampaignStaff.highest_tier(_row("CS01")), CampaignStaff.highest_tier(_row("CS02"))], [1, 2])


func test_hire_and_upgrade_prices_double_each_step() -> void:
	assert_eq(CampaignStaff.hire_cost(), {"capital": 150, "yen": 300000})
	assert_eq(CampaignStaff.upgrade_cost(0), {"capital": 300, "yen": 600000})
	assert_eq(CampaignStaff.upgrade_cost(1), {"capital": 600, "yen": 1200000})
	assert_eq(CampaignStaff.upgrade_cost(2), {}, "nothing above tier 2")


func test_an_office_row_needs_the_office_and_a_chain_row_needs_its_scene() -> void:
	assert_false(CampaignStaff.available(_row("CS01"), false, []))
	assert_true(CampaignStaff.available(_row("CS01"), true, []))
	assert_false(CampaignStaff.available(_row("CS02"), true, []), "a chain candidate waits for the scene that finds them")
	assert_true(CampaignStaff.available(_row("CS02"), true, ["CS02"]))


func test_hiring_is_allowed_until_election_day_and_again_from_january() -> void:
	var cycles := DataDB.election_cycles
	assert_false(CampaignStaff.can_hire_on(_d("18.12.01"), cycles, false), "the office is not open")
	assert_true(CampaignStaff.can_hire_on(_d("18.12.01"), cycles, true))
	assert_true(CampaignStaff.can_hire_on(_d("21.12.12"), cycles, true), "Election Day itself")
	assert_false(CampaignStaff.can_hire_on(_d("21.12.13"), cycles, true))
	assert_false(CampaignStaff.can_hire_on(_d("21.12.31"), cycles, true))
	assert_true(CampaignStaff.can_hire_on(_d("22.01.01"), cycles, true))


func test_a_new_hire_starts_at_the_rows_starting_tier_with_the_yen_paid() -> void:
	var member := CampaignStaff.hire(_row("CS03"))
	assert_eq([member["staff_id"], member["tier"], member["invested_yen"], member["lent_until"]], ["CS03", 0, 300000, -1])
	assert_eq(member["loyalty"], Levers.whole("staff_loyalty_start"))


func test_an_upgrade_adds_a_tier_and_the_yen_and_stops_at_the_rows_top() -> void:
	var member := CampaignStaff.hire(_row("CS01"))   # highest tier 1
	var up := CampaignStaff.upgraded(member, _row("CS01"))
	assert_eq([up["tier"], up["invested_yen"]], [1, 900000])
	assert_eq(CampaignStaff.upgraded(up, _row("CS01")), up, "CS01 tops out at tier 1")
	var chain := CampaignStaff.upgraded(CampaignStaff.upgraded(CampaignStaff.hire(_row("CS02")), _row("CS02")), _row("CS02"))
	assert_eq([chain["tier"], chain["invested_yen"]], [2, 2100000], "CS02 reaches tier 2: 300k + 600k + 1.2M")


func test_wages_count_the_yen_invested_and_never_the_capital() -> void:
	var member := CampaignStaff.hire(_row("CS01"))
	assert_eq(CampaignStaff.wage_for(member), 30000, "10% of 300,000")
	member["capital_paid"] = 99999   # a stray field changes nothing
	assert_eq(CampaignStaff.wage_for(member), 30000)
	assert_eq(CampaignStaff.wage_for(CampaignStaff.upgraded(member, _row("CS01"))), 90000, "10% of 900,000")


func test_wages_come_out_of_the_campaign_fund_and_a_lent_member_is_still_paid() -> void:
	var lent := CampaignStaff.lent(CampaignStaff.hire(_row("CS01")), 100, 2)
	var plain := CampaignStaff.hire(_row("CS03"))
	var paid := CampaignStaff.settle_week([lent, plain], 100000)
	assert_eq(paid["spent"], 60000)
	assert_eq(paid["missed"], [])
	var short := CampaignStaff.settle_week([lent, plain], 40000)
	assert_eq(short["paid"], ["CS01"], "in the order given")
	assert_eq(short["missed"], ["CS03"])


func test_a_missed_wage_follows_the_regular_staff_loyalty_rules() -> void:
	var member := CampaignStaff.upgraded(CampaignStaff.hire(_row("CS02")), _row("CS02"))
	member["loyalty"] = Levers.whole("staff_loyalty_rank_loss_below") - 1
	var after := CampaignStaff.after_week(member, true, _row("CS02"))
	assert_true(after["rank_lost"])
	member["tier"] = 0
	assert_false(CampaignStaff.after_week(member, true, _row("CS02"))["rank_lost"], "never below the rank they were hired at")
	assert_false(CampaignStaff.after_week(member, false, _row("CS02"))["rank_lost"])


func test_lending_lasts_whole_weeks_and_a_lent_member_is_not_free() -> void:
	var member := CampaignStaff.hire(_row("CS05"))
	var gone := CampaignStaff.lent(member, 100, 2)
	assert_eq(gone["lent_until"], 114)
	assert_true(CampaignStaff.is_lent(gone, 113))
	assert_false(CampaignStaff.is_lent(gone, 114), "back on the day it ends")
	assert_false(CampaignStaff.is_lent(member, 100))


func test_the_free_member_with_the_highest_tier_is_chosen_and_ties_go_by_id() -> void:
	var low := CampaignStaff.hire(_row("CS03"))
	var high := CampaignStaff.upgraded(CampaignStaff.hire(_row("CS04")), _row("CS04"))
	var tied := CampaignStaff.upgraded(CampaignStaff.hire(_row("CS01")), _row("CS01"))
	assert_eq(CampaignStaff.best_free([low, high], 100)["staff_id"], "CS04")
	assert_eq(CampaignStaff.best_free([high, tied], 100)["staff_id"], "CS01", "equal tiers: the lower ID")
	assert_eq(CampaignStaff.best_free([CampaignStaff.lent(high, 100, 1), low], 100)["staff_id"], "CS03", "the lent one is skipped")
	assert_eq(CampaignStaff.best_free([], 100), {})


func test_everyone_leaves_after_election_day_and_a_chain_candidate_stays_unlocked() -> void:
	assert_eq(CampaignStaff.after_leaving([CampaignStaff.hire(_row("CS01")), CampaignStaff.hire(_row("CS02"))]), [])
	var unlocked := ["CS02"]
	assert_true(CampaignStaff.available(_row("CS02"), true, unlocked), "still found after they left")
	var again := CampaignStaff.hire(_row("CS02"))
	assert_eq([again["tier"], again["invested_yen"]], [0, 300000], "rehired from tier 0 at the hire price")
