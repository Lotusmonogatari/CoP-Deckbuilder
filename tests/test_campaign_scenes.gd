extends GutTest
## P20 phase C (2026-11-26, Cameron): Campaign Moment! scenes in the run. DS11 opens the office, a Random scene is drawn once a day and stays until
## answered, a colleague speaks and is remembered, a choice's fund cost greys it, lending and favors, the challenge chain, and the save.


var _random_events_off := false


func before_each() -> void:
	# The check scripts switch random events off for the click tests; the draw under test is not one of them.
	_random_events_off = OS.has_environment("COP_NO_RANDOM_EVENTS")
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL
	if _random_events_off:
		OS.set_environment("COP_NO_RANDOM_EVENTS", "1")


## Puts the calendar on a Monday with the given hours into the week, in the first week whose Monday is in `phase`.
func _go_to(phase: String) -> bool:
	for week in range(1, 400):
		GameState.calendar = {"week": week, "phase": "work", "hours": 0}
		if str(GameState.election_phase()["phase"]) == phase and bool(GameState.election_phase()["player_runs"]):
			return true
	return false


## Puts the calendar on a date ("YY.MM.DD") by trying each week and each working day.
func _go_to_date(label: String) -> void:
	for week in range(1, 60):
		for hours in [0, 8, 16, 24, 32]:
			GameState.calendar = {"week": week, "phase": "work", "hours": hours}
			if WeekCalendar.date_label(GameState.campaign_today()) == label:
				return


## The first opponent of the player's own party that is not a leader or whip, standing in for a drawn colleague.
func _colleague() -> String:
	var party := DataDB.get_party(str(DataDB.player.get("party", "")))
	return CampaignMoments.pick_colleague(DataDB.opponents, party, 0.0)


func _scene_of(event_id: String) -> Dictionary:
	return GameState.decision_scene_of(event_id)


func test_ds11_is_mandatory_on_18_11_01_and_opens_the_office() -> void:
	var scene := _scene_of("EV120")
	assert_eq(str(scene["scene_id"]), "DS11")
	assert_eq(str(scene["card"]), "Campaign")
	_go_to_date("18.11.01")
	assert_eq(WeekCalendar.date_label(GameState.campaign_today()), "18.11.01")
	# The earlier dated scenes (the opening address, the CPTPP motion) are behind the player.
	for event: Dictionary in DataDB.events:
		if str(event.get("trigger", "")) == "Dated" and str(event["event_id"]) != "EV120":
			GameState.dated_events_done.append(str(event["event_id"]))
	assert_eq(GameState.due_dated_event(), "EV120")
	assert_false(GameState.campaign_office_open())
	var done := GameState.apply_event_choice("EV120", "A")
	assert_true(bool(done["ok"]))
	assert_true(GameState.campaign_office_open(), "Activates venue:VN10 opens the Campaign Office")


func test_ds11_choice_b_donates_your_own_funds() -> void:
	_go_to_date("18.11.01")
	GameState.meta["Funds"] = 80000
	var done := GameState.apply_event_choice("EV120", "B")
	assert_true(bool(done["ok"]))
	assert_eq(int(GameState.meta["Funds"]), 30000)
	assert_eq(GameState.campaign_fund, 50000)


func test_a_random_scene_is_drawn_once_a_day_and_stays_until_answered() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	var first := GameState.campaign_moment_due()
	assert_ne(first, "", "a scene is drawn")
	assert_eq(GameState.campaign_moment_due(), first, "asking again gives the same scene")
	var scene := _scene_of(first)
	assert_true(CampaignMoments.is_random(scene))
	var choices := EventEngine.choices_for(DataDB.event_choices, first)
	GameState.meta["Funds"] = 1000000
	GameState.campaign_fund = 1000000
	var letter := str(choices[choices.size() - 1]["choice"])   # the last choice is the one that costs nothing in these scenes
	assert_true(bool(GameState.apply_event_choice(first, letter)["ok"]))
	assert_eq(GameState.campaign_moment_open, "")
	assert_eq(GameState.campaign_moments_week, 1)
	assert_true(GameState.scene_cooldowns.has(str(scene["scene_id"])))
	assert_eq(GameState.campaign_moment_due(), "", "the building phase allows one a week, and one a day is drawn at most")


func test_no_draw_before_the_office_opens_or_in_a_level() -> void:
	assert_true(_go_to("building"))
	assert_eq(GameState.campaign_moment_due(), "", "the office is not open")
	GameState.open_venue("VN10")
	GameState.level_runner = null
	assert_ne(GameState.campaign_moment_due(), "")


func test_the_same_seed_draws_the_same_scene() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	var first := GameState.campaign_moment_due()
	GameState.campaign_moment_open = ""
	GameState.campaign_draw_day = -1
	assert_eq(GameState.campaign_moment_due(), first, "a reload draws the same scene")


func test_a_colleague_speaks_is_remembered_and_fills_the_text() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	GameState.office_location = Offices.CAPITOL
	GameState.scene_colleagues["DS22"] = _colleague()
	var party := DataDB.get_party(str(DataDB.player.get("party", "")))
	var expected := str(DataDB.get_opponent(_colleague()).get("name", ""))
	assert_ne(expected, "", "the party has a colleague to draw")
	var speakers := GameState.event_speakers("EV131")
	assert_eq(str(speakers[0]["id"]), _colleague())
	assert_eq(GameState.fill_scene_text("EV131", "{colleague} asks."), "%s asks." % expected)
	assert_false(party.is_empty())


func test_a_fund_cost_greys_the_choice_and_the_effects_apply() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	GameState.scene_colleagues["DS22"] = _colleague()
	var choice := {}
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, "EV131"):
		if str(row["choice"]) == "A":
			choice = row
	GameState.campaign_fund = 50000
	assert_eq(GameState.campaign_choice_refusal(choice), Text.say("campaign.reason.no_fund"))
	GameState.campaign_fund = 400000
	var party_before := int(GameState.meta["Party support"])
	assert_eq(GameState.campaign_choice_refusal(choice), "")
	var done := GameState.apply_event_choice("EV131", "A")
	assert_true(bool(done["ok"]))
	assert_eq(GameState.campaign_fund, 300000)
	assert_eq(int(GameState.meta["Party support"]), party_before + 2)
	assert_eq(GameState.campaign_favors.size(), 1, "a favor is owed")
	assert_eq(str(GameState.campaign_favors[0]["colleague_id"]), _colleague())


func test_a_choice_that_needs_free_staff_is_hidden_without_them() -> void:
	var choice := {}
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, "EV132"):
		if str(row["choice"]) == "B":
			choice = row
	assert_false(GameState.choice_visible(choice))
	GameState.campaign_staff_hired = [CampaignStaff.hire(DataDB.campaign_staff[0])]
	assert_true(GameState.choice_visible(choice))


func test_lending_a_staffer_turns_their_effects_off_for_the_weeks() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	GameState.scene_colleagues["DS24"] = _colleague()
	GameState.campaign_staff_hired = [CampaignStaff.hire(DataDB.campaign_staff[0])]
	var done := GameState.apply_event_choice("EV133", "B")
	assert_true(bool(done["ok"]))
	var member := GameState.campaign_member(str(DataDB.campaign_staff[0]["staff_id"]))
	assert_true(CampaignStaff.is_lent(member, GameState.campaign_today()))
	assert_eq(int(member["lent_until"]), GameState.campaign_today() + 14)
	assert_ne(GameState.campaign_choice_refusal({"lend_weeks": 1}), "", "nobody else is free to lend")


func test_the_chain_a_challenge_decides() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	GameState.xp = 5000
	var today := GameState.campaign_today()
	GameState.decision_log["DS15"] = {"day": today, "choice": "A"}
	assert_true(bool(GameState.apply_event_choice("EV125", "A")["ok"]), "Accept starts the challenge")
	assert_eq(GameState.campaign_challenges.size(), 1)
	assert_eq(str(GameState.campaign_challenges[0]["activity"]), "CM01")
	GameState.campaign_actions_week = 0
	for step in 3:
		GameState.campaign_actions_week = 0
		GameState.calendar = {"week": GameState.calendar["week"], "phase": "work", "hours": 0}
		assert_true(bool(GameState.campaign_act(CampaignOffice.FUNDRAISE)["ok"]))
	assert_eq(int(GameState.campaign_challenges[0]["done"]), 3)
	assert_eq(GameState.challenge_outcomes().get("DS16"), "challenge_met")


func test_staff_found_by_a_chain_become_available() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	GameState.decision_log["DS13"] = {"day": GameState.campaign_today(), "choice": "A"}
	assert_true(bool(GameState.apply_event_choice("EV123", "A")["ok"]))
	assert_true(GameState.campaign_staff_unlocked.has("CS02"), "Dan can be hired now")


func test_the_new_state_survives_a_save() -> void:
	GameState.campaign_moments_week = 1
	GameState.campaign_moment_open = "DS22"
	GameState.scene_cooldowns = {"DS22": 5000}
	GameState.scene_colleagues = {"DS22": _colleague()}
	GameState.campaign_challenges = [{"scene_id": "DS16", "activity": "CM01", "count": 3, "days": 14, "start": 10, "done": 1}]
	GameState.campaign_favors = [{"colleague_id": _colleague(), "scene_id": "DS22", "date": 5000}]
	GameState.van_speech_done = true
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	assert_eq(GameState.campaign_moment_open, "")
	GameState.load_save(data)
	assert_eq(GameState.campaign_moments_week, 1)
	assert_eq(GameState.campaign_moment_open, "DS22")
	assert_eq(GameState.scene_cooldowns, {"DS22": 5000})
	assert_eq(GameState.scene_colleagues, {"DS22": _colleague()})
	assert_eq(int(GameState.campaign_challenges[0]["done"]), 1)
	assert_eq(GameState.campaign_favors.size(), 1)
	assert_true(GameState.van_speech_done)


func test_a_van_speech_marks_van_speech_done() -> void:
	assert_true(_go_to("building"))
	GameState.open_venue("VN10")
	GameState.xp = 5000
	GameState.campaign_fund = 5000000
	GameState.campaign_van_tier = 0
	assert_false(GameState.van_speech_done)
	assert_true(bool(GameState.campaign_act(CampaignOffice.VAN)["ok"]))
	assert_true(GameState.van_speech_done)
