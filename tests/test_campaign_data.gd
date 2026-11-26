extends GutTest
## P20 phase A (2026-11-26): the campaign's data and state are in place: VN10 hidden until a scene opens it, its activities, the Balance and Rules
## rows, the Text rows, the new columns, and the run's new fields (saved, reset by a new run, defaults for an older save).

const NEW_BALANCE := ["election_capital_target", "election_capital_fade_percent", "election_war_chest_target", "election_war_chest_limit",
	"election_gain_per_week_mustering", "difficulty_relaxed_election_gain_per_week_mustering", "difficulty_harder_election_gain_per_week_mustering",
	"campaign_sprint_multiplier", "campaign_actions_per_week", "campaign_action_hours", "campaign_action_hours_with_organizer",
	"campaign_fundraise_xp", "campaign_fundraise_yield", "campaign_letters_xp", "campaign_letters_standing", "campaign_mailings_xp",
	"campaign_mailings_standing", "campaign_mailings_district", "campaign_van_speech_cost", "campaign_van_speech_district",
	"campaign_van_speech_penalty", "campaign_van_tier_0_cost", "campaign_van_tier_1_cost", "campaign_van_tier_2_cost",
	"campaign_staff_hire_capital", "campaign_staff_hire_yen", "campaign_fundraiser_multiplier_tier_0", "campaign_fundraiser_multiplier_tier_1",
	"campaign_fundraiser_multiplier_tier_2", "campaign_organizer_letters_bonus", "campaign_organizer_mailings_national",
	"campaign_announcer_voters_bonus", "campaign_announcer_district_bonus", "selection_weight_strength", "selection_weight_alignment",
	"selection_weight_influence", "selection_threshold_list", "selection_threshold_smd", "selection_threshold_safety_net",
	"campaign_moments_per_week_building", "campaign_moments_per_week_late", "poll_every_weeks_building", "poll_every_weeks_late",
	"poll_margin_building", "poll_margin_mustering", "poll_margin_campaign", "poll_margin_final"]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false


func test_every_new_balance_row_is_there_and_the_old_experience_target_is_gone() -> void:
	for key: String in NEW_BALANCE:
		assert_true(DataDB.balance.has(key), key)
	assert_false(DataDB.balance.has("election_experience_target"), "replaced by the capital target")
	assert_eq(float(DataDB.balance["election_war_chest_target"]), 25000000.0)
	assert_eq(float(DataDB.balance["selection_weight_strength"]) + float(DataDB.balance["selection_weight_alignment"]) + float(DataDB.balance["selection_weight_influence"]), 100.0)


func test_the_text_rows_in_the_two_text_values_are_rules_rows() -> void:
	assert_eq(str(DataDB.get_rule("campaign_van_speech_penalty_orgs")), "BO18;BO25")
	assert_eq(str(DataDB.get_rule("campaign_van_voters_org")), "BO18")
	assert_eq(str(DataDB.get_rule("campaign_office_open_date")), "18.11.01")


func test_the_campaign_office_is_a_district_venue_opened_by_a_scene() -> void:
	var venue := GameState.venue_row("VN10")
	assert_eq(venue["name"], "Campaign Office")
	assert_eq(venue["zone"], "District")
	assert_eq(venue["unlock"], "scene")
	var kinds: Array[String] = []
	for activity: Dictionary in DataDB.venue_activities:
		if str(activity["venue_id"]) == "VN10":
			kinds.append(str(activity["kind"]))
	assert_eq(kinds, ["campaign_fundraise", "campaign_letters", "campaign_mailings", "campaign_van"] as Array[String])
	for id: String in ["CM01", "CM02", "CM03", "CM04"]:
		assert_false(GameState.venue_activity(id).is_empty(), id)


func test_the_map_does_not_list_the_campaign_office_until_a_scene_opens_it() -> void:
	var ids := func(list: Array) -> Array:
		return list.map(func(v: Dictionary) -> String: return str(v["venue_id"]))
	assert_false((ids.call(VenueRules.venues_at(DataDB.venues, false)) as Array).has("VN10"), "hidden by default")
	assert_false((ids.call(VenueRules.venues_at(DataDB.venues, false, ["VN99"])) as Array).has("VN10"))
	assert_true((ids.call(VenueRules.venues_at(DataDB.venues, false, ["VN10"])) as Array).has("VN10"), "listed once opened")
	assert_false((ids.call(VenueRules.venues_at(DataDB.venues, true, ["VN10"])) as Array).has("VN10"), "it is a District place, not a Capitol one")
	assert_true((ids.call(VenueRules.venues_at(DataDB.venues, false)) as Array).has("VN09"), "other District places are unaffected")


func test_a_scene_opens_the_venue_for_the_run() -> void:
	GameState.office_location = Offices.DISTRICT
	assert_false(GameState.venue_is_open("VN10"))
	assert_false(GameState.venues_here().any(func(v: Dictionary) -> bool: return str(v["venue_id"]) == "VN10"))
	GameState.open_venue("VN10")
	GameState.open_venue("VN10")
	assert_eq(GameState.venues_opened, ["VN10"], "opening twice changes nothing")
	assert_true(GameState.venue_is_open("VN10"))
	assert_true(GameState.venue_is_open("VN09"), "a venue with no scene lock is always open")
	assert_true(GameState.venues_here().any(func(v: Dictionary) -> bool: return str(v["venue_id"]) == "VN10"))


func test_the_campaign_ledgers_and_opened_venues_are_saved_and_reset_by_a_new_run() -> void:
	GameState.campaign_fund = 2500000
	GameState.campaign_capital = 320
	GameState.open_venue("VN10")
	var saved := GameState.to_save()
	assert_eq([saved["campaign_fund"], saved["campaign_capital"], saved["venues_opened"]], [2500000, 320, ["VN10"]])
	GameState.start_new_run("PC01")
	assert_eq([GameState.campaign_fund, GameState.campaign_capital, GameState.venues_opened], [0, 0, []])
	GameState.load_save(saved)
	assert_eq([GameState.campaign_fund, GameState.campaign_capital, GameState.venues_opened], [2500000, 320, ["VN10"]])


func test_an_older_save_loads_with_empty_campaign_fields() -> void:
	var saved := GameState.to_save()
	for key: String in ["campaign_fund", "campaign_capital", "venues_opened"]:
		saved.erase(key)
	GameState.load_save(saved)
	assert_eq([GameState.campaign_fund, GameState.campaign_capital, GameState.venues_opened], [0, 0, []])


func test_the_new_decision_scene_and_event_choice_columns_are_exported() -> void:
	for key: String in ["card", "weight", "weight_late", "repeat", "cooldown_weeks", "phase", "needs"]:
		assert_true((DataDB.decision_scenes[0] as Dictionary).has(key), "Decision Scenes " + key)
	for key: String in ["campaign_fund_delta", "donate_funds", "lend_weeks", "favor_owed", "needs"]:
		assert_true((DataDB.event_choices[0] as Dictionary).has(key), "Event Choices " + key)


func test_the_phase_names_the_player_sees_are_text_rows() -> void:
	assert_eq(Text.say("campaign.phase.announcement"), "Banners of War Rising")
	assert_eq(Text.say("campaign.phase.mustering"), "Mustering the War Campaign")
	assert_eq(Text.say("campaign.phase.campaign"), "Gladiators of War Unleashed")
	assert_eq(Text.say("campaign.phase.election_day"), "Sengoku no Hi")
	assert_eq(Text.say("selection.outcome.smd_safety_net"), "Selected for your Single-Member District, with a place on the Proportional List")
	assert_eq(Text.say("campaign.office.actions_left", {"used": 1, "limit": 2}), "1 of 2 campaign actions this week")


func test_the_phase_for_today_follows_the_calendar() -> void:
	GameState.calendar = WeekCalendar.fresh()
	assert_eq(GameState.election_phase(), {"cycle_id": "EC01", "phase": "building", "player_runs": true})
