extends GutTest
## Campaign polls (P20, 2026-11-26): the schedule, the reading that always holds the truth, the outlook and the movers.

func _d(text: String) -> int:
	return WeekCalendar.parse_date(text)


func _due(date: String, last: String, opened: String = "18.11.01") -> bool:
	return CampaignPolls.due(_d(date), _d(last) if not last.is_empty() else -1, _d(opened), DataDB.election_cycles)


# --- The schedule -------------------------------------------------------------------------------------------------------------------

func test_no_poll_before_the_office_opens() -> void:
	assert_false(CampaignPolls.due(_d("18.10.29"), -1, -1, DataDB.election_cycles), "the office is not open (a Monday)")
	assert_false(_due("18.10.29", "", "18.11.01"), "before the opening day")


func test_the_first_poll_is_the_first_monday_after_the_office_opens() -> void:
	assert_false(_due("18.11.02", ""), "a Friday")
	assert_false(_due("18.11.01", ""), "the opening day itself")
	assert_true(_due("18.11.05", ""), "the first Monday after 18.11.01")


func test_building_polls_come_every_four_weeks_on_mondays() -> void:
	assert_false(_due("18.11.12", "18.11.05"), "one week later")
	assert_false(_due("18.11.26", "18.11.05"), "three weeks later")
	assert_true(_due("18.12.03", "18.11.05"), "four weeks later")
	assert_false(_due("18.12.04", "18.11.05"), "a Tuesday")


func test_mustering_and_campaign_polls_come_every_two_weeks() -> void:
	assert_false(_due("21.10.11", "21.10.04"), "a week after the last poll")
	assert_true(_due("21.10.18", "21.10.04"), "two weeks after, in mustering")
	assert_true(_due("21.12.06", "21.11.22"), "two weeks after, in the campaign")
	assert_false(_due("21.12.06", "21.11.29"), "only a week after")


func test_a_final_poll_on_the_last_workday_before_election_day() -> void:
	var day := CampaignPolls.final_poll_day(_d("21.12.12"))
	assert_eq(WeekCalendar.date_label(day), "21.12.10", "21.12.12 is a Sunday: the Friday before")
	assert_true(_due("21.12.10", "21.12.06"), "even a few days after the last poll")
	assert_false(CampaignPolls.due(day, day, _d("18.11.01"), DataDB.election_cycles), "not twice on the same day")
	assert_false(_due("21.12.12", ""), "none on Election Day")
	for election in ["21.12.12", "24.12.08", "27.12.12"]:
		var last := CampaignPolls.final_poll_day(_d(election))
		assert_lt(last, _d(election))
		assert_lte(_d(election) - last, 3, "no more than a weekend back")
		var weekday := posmod(last + 4, 7)
		assert_true(weekday >= 1 and weekday <= 5, "a workday")


func test_no_polls_in_the_cycle_the_player_steps_aside_from() -> void:
	assert_false(_due("27.10.18", "27.10.04"), "a mustering Monday in EC03")
	assert_false(CampaignPolls.due(CampaignPolls.final_poll_day(_d("27.12.12")), -1, _d("18.11.01"), DataDB.election_cycles))


# --- The reading --------------------------------------------------------------------------------------------------------------------

func test_the_margin_depends_on_the_phase_and_the_final_poll_has_its_own() -> void:
	assert_eq(CampaignPolls.margin("building", false), 8)
	assert_eq(CampaignPolls.margin("mustering", false), 5)
	assert_eq(CampaignPolls.margin("announcement", false), 5)
	assert_eq(CampaignPolls.margin("campaign", false), 3)
	assert_eq(CampaignPolls.margin("campaign", true), 2)


func test_the_range_always_holds_the_true_value() -> void:
	for phase: String in ["building", "mustering", "campaign"]:
		for strength in [0.0, 0.4, 3.0, 17.5, 50.0, 82.3, 99.6, 100.0]:
			for date in range(18000, 18040):
				var reading := CampaignPolls.reading(strength, phase, false, 1234, date)
				assert_lte(float(reading["low"]), strength, "%s %.1f day %d" % [phase, strength, date])
				assert_gte(float(reading["high"]), strength)
				assert_true(int(reading["low"]) >= 0 and int(reading["high"]) <= 100, "clamped to 0-100")


func test_the_same_inputs_give_the_same_reading_and_another_seed_or_day_can_differ() -> void:
	var one := CampaignPolls.reading(40.0, "building", false, 777, 18500)
	assert_eq(one, CampaignPolls.reading(40.0, "building", false, 777, 18500))
	var seen := {}
	for date in range(18500, 18530):
		seen[str(CampaignPolls.reading(40.0, "building", false, 777, date))] = true
	assert_gt(seen.size(), 1, "the offset moves with the date")


func test_the_range_is_never_wider_than_twice_the_margin_plus_a_point() -> void:
	for date in range(18000, 18060):
		var r := CampaignPolls.reading(50.0, "campaign", false, 9, date)
		assert_lte(int(r["high"]) - int(r["low"]), 2 * 3 + 2)


# --- Outlook, movers, source ----------------------------------------------------------------------------------------------------------

func test_the_outlook_says_one_outcome_when_the_range_stays_in_one_band() -> void:
	var inputs := {"alignment": 50, "party_support": 50, "committee_standing": 50}   # score = strength / 2 + 25
	assert_eq(CampaignPolls.outlook({"low": 70, "high": 72}, inputs), {"likely": "smd", "could_be": ""})


func test_the_outlook_adds_a_second_outcome_when_the_range_crosses_a_threshold() -> void:
	var inputs := {"alignment": 50, "party_support": 50, "committee_standing": 50}
	var crossing := CampaignPolls.outlook({"low": 66, "high": 74}, inputs)   # scores 58 .. 62 around the 60 line
	assert_eq(crossing["likely"], "smd", "the middle (70) scores 60")
	assert_eq(crossing["could_be"], "list")
	var high_side := CampaignPolls.outlook({"low": 68, "high": 76}, inputs)   # mid 72 -> 61; low 59 -> list; hmm
	assert_eq(high_side["likely"], "smd")


func test_movers_name_the_input_that_rose_most_and_the_one_that_fell_most() -> void:
	var before := [{"id": "district", "points": 5.0, "max": 15.0}, {"id": "national", "points": 5.0, "max": 15.0}, {"id": "party", "points": 5.0, "max": 10.0}]
	var after := [{"id": "district", "points": 8.0, "max": 15.0}, {"id": "national", "points": 4.0, "max": 15.0}, {"id": "party", "points": 5.5, "max": 10.0}]
	assert_eq(CampaignPolls.movers(before, after), {"up": "poll.up.district", "down": "poll.down.national"})


func test_movers_break_ties_by_input_order_and_say_nothing_when_nothing_moved() -> void:
	var before := [{"id": "district", "points": 5.0}, {"id": "national", "points": 5.0}]
	var tied := [{"id": "district", "points": 7.0}, {"id": "national", "points": 7.0}]
	assert_eq(CampaignPolls.movers(before, tied)["up"], "poll.up.district")
	assert_eq(CampaignPolls.movers(before, before), {"up": "", "down": ""})


func test_the_source_is_internal_while_far_off_then_the_three_outlets_in_turn() -> void:
	assert_eq(CampaignPolls.source("building", 0), "poll.source.internal")
	assert_eq(CampaignPolls.source("mustering", 0), "poll.source.pr01")
	assert_eq(CampaignPolls.source("campaign", 1), "poll.source.pr02")
	assert_eq(CampaignPolls.source("campaign", 2), "poll.source.pr03")
	assert_eq(CampaignPolls.source("campaign", 3), "poll.source.pr01")
