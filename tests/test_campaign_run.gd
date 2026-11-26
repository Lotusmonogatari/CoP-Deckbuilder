extends GutTest
## P20 phase D (2026-11-26, Cameron): selection, polls, Election Day and the end of the run, and a scripted run from the opening of Parliament to
## Sengoku no Hi of the first cycle (21.12.12) that plays the campaign the way a player would and prints how it ended.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT
	GameState.meta["Funds"] = 5000000


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL


func _cycles() -> Array:
	return ElectionCycle.normalized(DataDB.election_cycles)


func _go_to_day(day: int) -> void:
	for week in range(1, 700):
		for phase: String in ["work", "weekend"]:
			for hours in [0, 8, 16, 24, 32]:
				GameState.calendar = {"week": week, "phase": phase, "hours": hours}
				if GameState.campaign_today() == day:
					return
	fail_test("no calendar state reaches day %d" % day)


func test_the_selection_card_is_owed_from_campaign_open_for_a_cycle_the_player_runs() -> void:
	var first: Dictionary = _cycles()[0]
	assert_eq(ElectionCycle.selection_owed(int(first["open"]) - 1, DataDB.election_cycles, []), {})
	assert_eq(str(ElectionCycle.selection_owed(int(first["open"]), DataDB.election_cycles, [])["id"]), "EC01")
	assert_eq(str(ElectionCycle.selection_owed(int(first["day"]), DataDB.election_cycles, [])["id"]), "EC01", "still owed on Election Day")
	assert_eq(str(ElectionCycle.selection_owed(int(first["open"]), DataDB.election_cycles, ["EC01"]).get("id", "")), "", "once given it is not owed again")
	var third: Dictionary = _cycles()[2]
	assert_eq(ElectionCycle.selection_owed(int(third["open"]), DataDB.election_cycles, ["EC01", "EC02"]), {}, "no card in the cycle the player does not run in")


func test_election_owed_lists_each_election_day_once() -> void:
	var first: Dictionary = _cycles()[0]
	assert_eq(ElectionCycle.election_owed(int(first["day"]) - 1, DataDB.election_cycles, []), {})
	assert_eq(str(ElectionCycle.election_owed(int(first["day"]), DataDB.election_cycles, [])["id"]), "EC01")
	assert_eq(str(ElectionCycle.election_owed(int(first["day"]) + 1100, DataDB.election_cycles, ["EC01"])["id"]), "EC02")


func test_the_election_outcome_stub_seats_a_selected_player_and_records_the_cycle() -> void:
	var record := ElectionOutcome.resolve("EC01", {"outcome": Selection.SMD}, 61.0)
	assert_true(bool(record["seated"]))
	assert_eq(str(record["cycle_id"]), "EC01")
	assert_false(bool(ElectionOutcome.resolve("EC01", {"outcome": Selection.NOT_SELECTED}, 5.0)["seated"]))


func test_not_selected_closes_the_office_sends_the_staff_home_and_ends_the_run_on_election_day() -> void:
	var cycle: Dictionary = _cycles()[0]
	GameState.open_venue("VN10")
	GameState.campaign_staff_hired = [CampaignStaff.hire(DataDB.campaign_staff[0])]
	_go_to_day(int(cycle["open"]))
	GameState.election_strength = 0.0
	GameState.meta["Party support"] = 0
	GameState.booster_standing["BO32"] = 0
	var due := GameState.selection_due()
	assert_eq(str(due["id"]), "EC01")
	var result := GameState.take_selection(due)
	assert_eq(str(result["outcome"]), Selection.NOT_SELECTED)
	assert_eq(GameState.campaign_locked(), "not_selected")
	assert_eq(GameState.campaign_staff_hired.size(), 0, "the staff have gone home")
	assert_ne(GameState.campaign_refusal(CampaignOffice.FUNDRAISE), "")
	assert_eq(GameState.selection_due(), {}, "the card is shown once")
	_go_to_day(int(cycle["day"]))
	var election := GameState.election_due()
	assert_eq(str(election["kind"]), "not_selected")
	GameState.end_run()
	assert_true(GameState.awaiting_new_game, "the run is over")


func test_a_selected_player_is_seated_and_the_election_is_settled_once() -> void:
	var cycle: Dictionary = _cycles()[0]
	GameState.open_venue("VN10")
	_go_to_day(int(cycle["open"]))
	GameState.election_strength = 100.0
	GameState.meta["Party support"] = 100
	GameState.booster_standing["BO32"] = 100
	var result := GameState.take_selection(GameState.selection_due())
	assert_ne(str(result["outcome"]), Selection.NOT_SELECTED)
	_go_to_day(int(cycle["day"]))
	var due := GameState.election_due()
	assert_eq(str(due["kind"]), "seated")
	var record := GameState.settle_election(due)
	assert_true(bool(record["seated"]))
	assert_eq(GameState.election_due(), {}, "settled once")


func test_the_cycle_the_player_does_not_run_in_ends_the_run_on_its_election_day() -> void:
	var third: Dictionary = _cycles()[2]
	GameState.election_results = [{"cycle_id": "EC01"}, {"cycle_id": "EC02"}]
	GameState.selection_results = [{"cycle_id": "EC01", "outcome": "smd"}, {"cycle_id": "EC02", "outcome": "smd"}]
	_go_to_day(int(third["day"]))
	assert_eq(str(GameState.election_due()["kind"]), "stepped_aside")
	assert_eq(GameState.selection_due(), {}, "no selection card")
	assert_false(GameState.poll_due(), "no polls")
	assert_eq(GameState.campaign_banner_due(), {}, "no banners; the scene DS25 stands in for them")


func test_the_office_is_open_to_build_until_the_banners_of_a_cycle_the_player_does_not_run_in() -> void:
	var third: Dictionary = _cycles()[2]
	_go_to_day(int(third["banners"]) - 7)
	assert_eq(GameState.campaign_locked(), "", "the building phase before it is not locked")
	_go_to_day(int(third["banners"]) + 1)
	assert_eq(GameState.campaign_locked(), "stepped_aside")


func test_ds25_stepping_aside_is_a_mandatory_scene_on_the_banners_date() -> void:
	var scene := GameState.decision_scene_of("EV134")
	assert_eq(str(scene["scene_id"]), "DS25")
	assert_eq(str(scene["opens"]), "27.10.11")
	assert_eq(int(_cycles()[2]["banners"]), WeekCalendar.parse_date("27.10.11"))


func test_polls_come_every_four_weeks_while_building_then_every_two_and_a_final_one() -> void:
	var cycle: Dictionary = _cycles()[0]
	GameState.open_venue("VN10")
	var opened := GameState.campaign_office_day()
	assert_gte(opened, 0)
	var seen: Array[int] = []
	for day in range(opened, int(cycle["day"]) + 1):
		if CampaignPolls.due(day, seen[seen.size() - 1] if not seen.is_empty() else -1, opened, DataDB.election_cycles):
			seen.append(day)
	assert_gt(seen.size(), 10, "a poll about every month and then every fortnight")
	assert_eq(seen[seen.size() - 1], CampaignPolls.final_poll_day(int(cycle["day"])), "the last is the final poll")
	for i in range(1, seen.size() - 1):
		var gap := seen[i] - seen[i - 1]
		assert_true(gap == 14 or gap == 28, "gaps are two or four weeks (%d)" % gap)


func test_a_poll_is_kept_and_says_where_the_strength_moved() -> void:
	GameState.open_venue("VN10")
	var cycle: Dictionary = _cycles()[0]
	_go_to_day(int(cycle["banners"]) - 30)
	GameState.election_strength = 40.0
	var first := GameState.take_poll()
	assert_eq(first["previous_mid"], -1.0)
	assert_true(float(first["low"]) <= 40.0 and float(first["high"]) >= 40.0, "the true strength is inside the range")
	GameState.campaign_capital = 800
	var second := GameState.take_poll()
	assert_eq(GameState.campaign_polls.size(), 2)
	assert_ne(str(second["up"]), "", "the capital that was added is named as what rose")


func test_the_new_state_survives_a_save() -> void:
	GameState.selection_results = [{"cycle_id": "EC01", "score": 61, "outcome": "smd"}]
	GameState.campaign_polls = [{"date": 5, "low": 40, "high": 52}]
	GameState.campaign_last_poll = 5
	GameState.campaign_office_opened_on = 3
	GameState.election_results = [{"cycle_id": "EC01", "kind": "seated", "seated": true}]
	var data := GameState.to_save()
	GameState.start_new_run("PC01")
	assert_eq(GameState.selection_results, [])
	GameState.load_save(data)
	assert_eq(str(GameState.selection_of("EC01")["outcome"]), "smd")
	assert_eq(GameState.campaign_last_poll, 5)
	assert_eq(GameState.campaign_office_opened_on, 3)
	assert_eq(GameState.election_results.size(), 1)


## The scripted run: from Monday 18.10.15 to the day after Sengoku no Hi 21.12.12, a player who opens the office on 18.11.01, hires the three
## office staff, takes campaign actions every week and plays the cards the way the Office would. `strong` also holds Party support, standing with
## the committee, awareness and Constituency support high each week (what a player who wins rooms would have). Returns what happened.
func _scripted_run(strong: bool) -> Dictionary:
	var cycle: Dictionary = _cycles()[0]
	var polls := 0
	var selection := {}
	var election := {}
	GameState.dated_events_done = ["EV47"]
	var guard := 0
	while GameState.campaign_today() <= int(cycle["day"]) + 1 and guard < 400:
		guard += 1
		var today := GameState.campaign_today()
		if today >= WeekCalendar.parse_date("18.11.01"):
			GameState.open_venue("VN10")
		if strong:
			GameState.meta["Party support"] = 90
			GameState.meta["Constituency support"] = 75
			GameState.booster_standing["BO32"] = 80
			GameState.awareness["district"] = 70
			GameState.awareness["national"] = 60
		else:
			GameState.meta["Party support"] = 70
		var owed := GameState.selection_due()
		if not owed.is_empty():
			selection = GameState.take_selection(owed)
		var election_due := GameState.election_due()
		if not election_due.is_empty() and str(election_due["kind"]) == "seated":
			election = GameState.settle_election(election_due)
		if GameState.poll_due():
			GameState.take_poll()
			polls += 1
		if GameState.campaign_office_open() and GameState.campaign_locked().is_empty() and not GameState.is_in_level():
			GameState.xp = 3000
			GameState.meta["Funds"] = 5000000
			for id: String in ["CS01", "CS03", "CS05"]:
				if GameState.campaign_member(id).is_empty() and GameState.campaign_hire_refusal(id).is_empty():
					GameState.campaign_hire(id)
				elif GameState.campaign_member(id).is_empty() and GameState.campaign_fund < 300000:
					GameState.campaign_donate(100000)
			for step in 4:
				if GameState.campaign_fund < 600000:
					GameState.campaign_donate(100000)
				var done := GameState.campaign_act(CampaignOffice.FUNDRAISE)
				if not bool(done["ok"]):
					done = GameState.campaign_act(CampaignOffice.MAILINGS)
				if not bool(done["ok"]):
					break
		GameState.go_home()
	return {"guard": guard, "polls": polls, "selection": selection, "election": election, "strength": GameState.election_strength}


func _describe(label: String, run: Dictionary) -> void:
	var selection: Dictionary = run["selection"]
	print("SCRIPTED RUN (%s): polls %d, strength %d, alignment %d, score %d, outcome %s, seated %s" % [label, int(run["polls"]), roundi(float(run["strength"])),
		roundi(float(selection.get("alignment", 0))), int(selection.get("score", 0)), str(selection.get("outcome", "")), str((run["election"] as Dictionary).get("seated", false))])


func test_a_steady_scripted_run_reaches_sengoku_no_hi() -> void:
	var run := _scripted_run(false)
	assert_lt(int(run["guard"]), 400, "the run reached the end of the first cycle")
	assert_gt(int(run["polls"]), 10, "polls came all through")
	assert_false((run["selection"] as Dictionary).is_empty(), "the selection card came on or after Campaign Open")
	_describe("steady", run)


func test_a_strong_scripted_run_is_selected_and_seated() -> void:
	var run := _scripted_run(true)
	_describe("strong", run)
	assert_ne(str((run["selection"] as Dictionary).get("outcome", "")), Selection.NOT_SELECTED, "a player with strong standing is selected")
	assert_true(bool((run["election"] as Dictionary).get("seated", false)), "and seated on Sengoku no Hi")
