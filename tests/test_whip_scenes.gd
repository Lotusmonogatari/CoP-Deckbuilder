extends GutTest
## The CPTPP Decision! sequence (P15, 2026-11-23): the chain's data, the whips, the lock on the votes, a level that must not run
## over a Decision!, and the staff's after-hours trip. The pure rules are in test_whip_pick.gd and test_decision_clash.gd.

var _saved_log: Dictionary = {}
var _saved_calendar: Dictionary = {}


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	_saved_log = GameState.decision_log.duplicate(true)
	_saved_calendar = GameState.calendar.duplicate()
	GameState.dated_events_done = ["EV47", "EV111"]   # the opening address and the motion are behind us
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}}
	GameState.pending_activations = []
	GameState.whip_picks = {}
	GameState.whip_locks = {}
	GameState.office_location = Offices.CAPITOL


func after_each() -> void:
	GameState.decision_log = _saved_log
	GameState.calendar = _saved_calendar
	GameState.office_location = Offices.CAPITOL


func _day(text: String) -> int:
	return WeekCalendar.parse_date(text)


# --- the data --------------------------------------------------------------------------------------------------------------------

func test_the_chain_has_eight_follow_ups_and_every_vote_falls_by_the_deadline() -> void:
	var scenes := DataDB.decision_scenes
	var root := DecisionScenes.find(scenes, "DS02")
	assert_eq(DecisionScenes.descendant_count(scenes, "DS02"), 8)
	assert_eq(DecisionScenes.max_follow_ups(root), 8, "approved by Cameron")
	var days := DecisionScenes.chain_days(scenes, "DS02")
	var deadline := _day("18.10.30")
	for scene_id: String in days:
		if not DecisionScenes.vote_bill(DecisionScenes.find(scenes, scene_id)).is_empty():
			assert_lt(int(days[scene_id]), deadline, "%s is a vote before Tuesday 18.10.30" % scene_id)
	assert_eq(days["DS08"], days["DS09"], "the amendment and the final vote are the same day")
	assert_eq(days["DS08"], _day("18.10.29"))


func test_the_two_votes_and_their_scenes_name_each_other() -> void:
	assert_eq(DecisionScenes.vote_bill(DecisionScenes.find(DataDB.decision_scenes, "DS08")), "BI51")
	assert_eq(DecisionScenes.vote_bill(DecisionScenes.find(DataDB.decision_scenes, "DS09")), "BI52")
	assert_eq(str(DataDB.floor_votes["BI51"].get("decision_scene")), "DS08")
	assert_eq(str(DataDB.floor_votes["BI52"].get("decision_scene")), "DS09")


func test_the_votes_are_the_story_votes_sheets_with_absent_counted_as_abstain() -> void:
	for pair: Array in [["BI51", 34, 58, 9], ["BI52", 63, 29, 9]]:
		var yes := 0
		var no := 0
		var abstain := 0
		for position: Dictionary in DataDB.floor_votes[str(pair[0])]["positions"]:
			yes += int(position["votes_yes"])
			no += int(position["votes_no"])
			abstain += int(position["votes_abstain"])
		assert_eq([yes, no, abstain], [pair[1], pair[2], pair[3]], str(pair[0]))
	assert_lt(34, 51, "the amendment fails")
	assert_gte(63, 51, "the final passes")


func test_the_whip_bands_cover_zero_to_one_hundred_and_every_party_has_whips() -> void:
	assert_true(WhipPick.bands_cover(DataDB.rules.get("whip_bands", {})))
	for party: Dictionary in DataDB.parties:
		for key: String in ["assistant_whip_opp_id", "deputy_whip_opp_id", "chief_whip_opp_id", "leader_opp_id"]:
			assert_false(DataDB.get_opponent(str(party.get(key, ""))).is_empty(), "%s %s" % [party["party_id"], key])


func test_the_whip_stage_is_a_short_survival_fight_over_resolve() -> void:
	var stage := DataDB.get_stage(str(DataDB.get_rule("whip_stage", "")))
	assert_eq(stage["name_en"], "Whipped into Line")
	assert_eq(stage["bar_unit"], "Resolve")
	assert_eq(BarModel.for_stage(stage), BarModel.Model.SURVIVAL)
	assert_eq([int(stage["player_start"]), int(stage["win_threshold"]), int(stage["turn_limit"])], [12, 1, 3])
	assert_eq([stage["energy_mode"], int(stage["energy_pool"])], ["pool", 6], "6 energy for the whole stage, never refilled")
	assert_eq([int(stage["threshold_rise_min"]), int(stage["threshold_rise_max"])], [0, 0], "the line never rises")
	assert_eq([int(stage["win_delta_reputation"]), int(stage["win_delta_party_support"])], [1, -2])
	assert_eq([int(stage["loss_delta_party_support"]), int(stage["loss_delta_jiban"])], [1, -1])
	assert_eq(int(stage["time_units"]), 1, "one hour")


# --- who whips -------------------------------------------------------------------------------------------------------------------

func test_a_party_whip_is_picked_once_and_wears_the_players_party() -> void:
	var scene := DecisionScenes.find(DataDB.decision_scenes, "DS07")
	assert_true(DecisionScenes.whip_is_banded(scene))
	GameState.whip_picks = {"DS07": "OP133"}
	assert_eq(GameState.whip_pick_for(scene), "OP133", "kept, so the card, the stage and a reload agree")
	var speaker := GameState.event_speaker("EV116")
	assert_eq(speaker["opp_id"], "OP133")
	assert_eq(speaker["party"], str(DataDB.player.get("party", "")), "the blank party takes the player's own")
	assert_true(((GameState.to_save()["whip_picks"]) as Dictionary).has("DS07"), "saved")


func test_the_minister_of_agriculture_whips_every_player_by_name() -> void:
	var scene := DecisionScenes.find(DataDB.decision_scenes, "DS05")
	assert_false(DecisionScenes.whip_is_banded(scene))
	assert_eq(GameState.whip_pick_for(scene), "OP29")
	assert_eq(GameState.whip_line(scene), WhipPick.YES, "she asks Aye on the amendment")
	var final_scene := DecisionScenes.find(DataDB.decision_scenes, "DS06")
	assert_eq(GameState.whip_line(final_scene), WhipPick.NO, "and Nay on the final vote")


func test_a_party_with_no_line_is_never_whipped_and_the_scene_is_marked_done() -> void:
	var bill: Dictionary = DataDB.floor_votes["BI52"]
	var own := GameState.own_party_id()
	var saved := ""
	for position: Dictionary in bill["positions"]:
		if str(position["party_id"]) == own:
			saved = str(position["disposition"])
			position["disposition"] = "Neutral"
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}, "DS02": {"day": _day("18.10.22"), "choice": "A"}}
	GameState.calendar = {"week": 3, "phase": "work", "hours": 8 * 4}   # Friday 18.10.26
	assert_eq(GameState.due_dated_event(), "EV114", "DS05, Resu's ask, still comes (the party's line is not hers)")
	GameState.decision_log["DS05"] = {"day": _day("18.10.25"), "choice": "A"}
	GameState.decision_log["DS06"] = {"day": _day("18.10.25"), "choice": "A"}
	assert_eq(GameState.due_dated_event(), "", "the party whip's scene is skipped")
	assert_eq((GameState.decision_log["DS07"] as Dictionary)["choice"], GameState.WHIP_SKIPPED_LETTER)
	for position: Dictionary in bill["positions"]:
		if str(position["party_id"]) == own:
			position["disposition"] = saved


# --- the fight and the lock --------------------------------------------------------------------------------------------------------

func test_pushing_back_starts_the_fight_with_that_whip_over_that_bill() -> void:
	GameState.whip_picks = {"DS07": "OP133"}
	var scene := DecisionScenes.find(DataDB.decision_scenes, "DS07")
	assert_eq(GameState.apply_event_choice("EV116", "A")["ok"], true)
	assert_true(GameState.pending_activations.is_empty(), "siding with the party starts no fight")
	GameState.decision_log.erase("DS07")
	assert_eq(GameState.apply_event_choice("EV116", "C")["ok"], true)
	assert_eq(GameState.pending_activations.size(), 1)
	var next := GameState.next_activation()
	var level: Dictionary = next["level"]
	assert_eq(level["opponent_pin"], "OP133")
	assert_eq(level["whip_bill"], "BI52")
	var stage := BattleSetup.build_stage_for_slot(str(level["level_id"]), "ST290", 1)
	assert_eq(str((stage["opponents"] as Array)[0]["opp_id"]), "OP133")
	assert_eq(stage["bill_id"], "BI52", "the lines written for the CPTPP reach the fight")
	assert_true(scene.has("scene_id"))


func test_losing_the_fight_locks_the_vote_and_winning_does_not() -> void:
	var whip := {"opp_id": "OP29", "bill": "BI51", "line": "Yes", "scene_id": "DS05"}
	assert_true(GameState._record_whip_result({"whip": whip}, LevelRunner.WON).is_empty())
	assert_eq(GameState.vote_lock("BI51")["state"], "free")
	var state := GameState._record_whip_result({"whip": whip}, LevelRunner.LOST)
	assert_eq(state["state"], "locked")
	assert_eq(GameState.vote_lock("BI51")["allowed"], ["Yes"])
	assert_eq(GameState.vote_lock("BI52")["state"], "free", "the other vote is untouched")
	assert_eq(GameState.pending_trigger_alerts.back()["kind"], "whip_lost")
	assert_eq((GameState.to_save()["whip_locks"] as Dictionary).keys(), ["BI51"], "saved")


func test_losing_to_both_whips_on_the_final_vote_forces_an_abstention() -> void:
	var resu := {"opp_id": "OP29", "bill": "BI52", "line": "No", "scene_id": "DS06"}
	var party := {"opp_id": "OP133", "bill": "BI52", "line": "Yes", "scene_id": "DS07"}
	GameState._record_whip_result({"whip": resu}, LevelRunner.LOST)
	assert_eq(GameState.vote_lock("BI52")["allowed"], ["No"], "one lost fight holds the vote to what that whip asked")
	var state := GameState._record_whip_result({"whip": party}, LevelRunner.LOST)
	assert_eq(state["state"], "abstain")
	assert_eq(GameState.vote_lock("BI52")["allowed"], ["Abstain"])
	assert_eq(GameState.pending_trigger_alerts.back()["edge"], "abstain")


func test_a_follow_up_waits_for_the_fight_its_earlier_scene_started() -> void:
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}, "DS02": {"day": _day("18.10.22"), "choice": "A"}}
	GameState.calendar = {"week": 3, "phase": "work", "hours": 8 * 3}   # Thursday 18.10.25
	assert_eq(GameState.due_dated_event(), "EV114")
	assert_true(GameState.apply_event_choice("EV114", "B")["ok"], "Resu, on the amendment: push back")
	assert_eq(GameState.pending_activations.size(), 1)
	assert_ne(GameState.due_dated_event(), "EV115", "DS06 waits until the amendment fight has been played")
	GameState.pending_activations = []
	assert_eq(GameState.due_dated_event(), "EV115")


# --- a level must not run over a Decision!; the after-hours trip -----------------------------------------------------------------

func test_a_level_that_would_run_into_resus_day_is_refused_with_the_day() -> void:
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}, "DS02": {"day": _day("18.10.22"), "choice": "A"}}
	GameState.calendar = {"week": 3, "phase": "work", "hours": 0}   # Monday 18.10.22; DS05 is Thursday
	assert_eq(GameState.decision_clash_refusal(24), "", "24 hours end the evening before")
	assert_true(GameState.decision_clash_refusal(25).contains("Thursday"))


func test_an_optional_scene_asks_before_a_level_that_outlasts_its_window() -> void:
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}, "DS02": {"day": _day("18.10.22"), "choice": "A"}}
	GameState.calendar = {"week": 3, "phase": "work", "hours": 0}
	assert_true(GameState.optional_decision_clash(8).is_empty(), "a short level ends before the window closes")
	assert_true(GameState.optional_decision_clash(40).is_empty(), "a window closing on the Friday is never outlasted inside the week")
	# A window that closes mid-week can be outlasted: DS03 closing on the Wednesday and a 32-hour level from Monday.
	var scene := DecisionScenes.find(DataDB.decision_scenes, "DS03")
	var saved: Variant = scene["closes"]
	scene["closes"] = "18.10.24"
	var clash := GameState.optional_decision_clash(32)
	scene["closes"] = saved
	assert_false(clash.is_empty())
	assert_eq(clash["closes"], "18.10.24")


func test_the_staff_bring_the_player_back_after_hours_for_a_mandatory_scene() -> void:
	GameState.office_location = Offices.DISTRICT
	GameState.xp = 250
	assert_true(GameState.arrive_for_event(GameState.get_event("EV114")))
	assert_eq(GameState.xp, 150, "100 XP, the cap")
	assert_eq(int(GameState.last_evening_trip["xp"]), 100)
	assert_eq(GameState.office_location, Offices.CAPITOL)
	GameState.office_location = Offices.DISTRICT
	GameState.xp = 60
	assert_true(GameState.arrive_for_event(GameState.get_event("EV114")))
	assert_eq(GameState.xp, 0, "all the XP there was")
	assert_eq(int(GameState.last_evening_trip["xp"]), 60)


func test_an_ordinary_dated_event_costs_no_xp() -> void:
	GameState.office_location = Offices.DISTRICT
	GameState.xp = 250
	var ordinary := {"event_id": "EV_NOT_A_SCENE", "location": "Capitol"}
	assert_true(GameState.arrive_for_event(ordinary))
	assert_eq(GameState.xp, 250)
	assert_true(GameState.last_evening_trip.is_empty())
