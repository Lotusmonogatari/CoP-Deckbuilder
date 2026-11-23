extends GutTest
## Decision! scenes (2026-11-21, phase 1): the Decision Scenes tab, its pure rules and how a scene dresses its event.

var _dated_before: Array = []


func before_each() -> void:
	_dated_before = GameState.dated_events_done.duplicate()


func after_each() -> void:
	GameState.dated_events_done.assign(_dated_before)


func _scene(over: Dictionary = {}) -> Dictionary:
	var base := {"scene_id": "DS99", "event_id": "EV99", "kind": "Mandatory", "office": "Capitol", "speaker": "OP10",
		"second_speaker": null, "speaker_face": "attacking", "scene_picture": ["DEC_EV99_1", "DEC_EV99_2"]}
	base.merge(over, true)
	return base


func test_finds_a_scene_by_event_and_by_id() -> void:
	var scenes := [_scene()]
	assert_eq(DecisionScenes.of_event(scenes, "EV99").get("scene_id"), "DS99")
	assert_eq(DecisionScenes.find(scenes, "DS99").get("event_id"), "EV99")
	assert_true(DecisionScenes.of_event(scenes, "EV01").is_empty(), "an event that is not a scene")
	assert_true(DecisionScenes.find(scenes, "DS00").is_empty())


func test_kind_decides_mandatory() -> void:
	assert_true(DecisionScenes.is_mandatory(_scene()))
	assert_false(DecisionScenes.is_mandatory(_scene({"kind": "Optional"})))
	assert_true(DecisionScenes.is_mandatory({}), "a blank Kind is Mandatory")


func test_speakers_face_office_and_pictures_read_blanks_safely() -> void:
	assert_eq(DecisionScenes.speaker_ids(_scene({"second_speaker": "SF01"})), ["OP10", "SF01"])
	assert_eq(DecisionScenes.speaker_ids(_scene({"speaker": null})), [], "no speaker")
	assert_eq(DecisionScenes.face(_scene()), "attacking")
	assert_eq(DecisionScenes.face(_scene({"speaker_face": null})), "neutral")
	assert_eq(DecisionScenes.face(_scene({"speaker_face": "smiling"})), "neutral", "an unknown face is neutral")
	assert_eq(DecisionScenes.office(_scene({"office": null})), "Either")
	assert_eq(DecisionScenes.pictures(_scene()), ["DEC_EV99_1", "DEC_EV99_2"])
	assert_eq(DecisionScenes.pictures(_scene({"scene_picture": null})), [])


func test_person_kind_by_prefix() -> void:
	assert_eq(DecisionScenes.person_kind("OP10"), "opponent")
	assert_eq(DecisionScenes.person_kind("SF01"), "staff")
	assert_eq(DecisionScenes.person_kind("VI03"), "visitor")
	assert_eq(DecisionScenes.person_kind("XX1"), "")


func test_the_pilot_scene_is_the_prime_ministers_address() -> void:
	var scene := GameState.decision_scene_of("EV47")
	assert_eq(str(scene.get("scene_id")), "DS01")
	assert_true(DecisionScenes.is_mandatory(scene))
	assert_eq(DecisionScenes.office(scene), "Capitol")
	assert_true(GameState.decision_scene_of("EV31").is_empty(), "an ordinary event is not a scene")


func test_the_scene_names_its_speaker_and_office() -> void:
	assert_eq(str(GameState.event_speaker("EV47").get("opp_id")), "OP10")
	var speakers := GameState.event_speakers("EV47")
	assert_eq(speakers.size(), 1)
	assert_eq(str((speakers[0] as Dictionary).get("id")), "OP10")
	assert_eq((speakers[0] as Dictionary).get("face"), "neutral")
	assert_eq(GameState.event_office(GameState.get_event("EV47")), Offices.CAPITOL)
	assert_true(GameState.event_speakers("EV31").is_empty(), "no scene and no speaker title")


func test_a_scene_fires_once() -> void:
	GameState.dated_events_done = []
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	assert_eq(GameState.due_dated_event(), "EV47")
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	GameState.calendar = {"week": 30, "phase": "work", "hours": 0}
	assert_ne(GameState.due_dated_event(), "EV47", "never again, however late (the CPTPP scenes are due by then, which is fine)")


func test_every_scene_row_is_consistent() -> void:
	# The exporter checks this too; this keeps the loaded data honest at run time.
	for scene: Dictionary in DataDB.decision_scenes:
		var event := GameState.get_event(str(scene.get("event_id", "")))
		assert_false(event.is_empty(), "%s names a real event" % scene.get("scene_id"))
		assert_eq(str(event.get("on_date", "")), str(scene.get("opens", "")), "%s opens on its event's date" % scene.get("scene_id"))


# --- Follow-ups (phase 2) --------------------------------------------------------------------------------------------------------

func _follow(id: String, follows: String, delay: int, follow_if: Array = []) -> Dictionary:
	return _scene({"scene_id": id, "event_id": "E_" + id, "follows": follows, "delay": delay, "follow_if": follow_if})


func test_a_follow_up_counts_its_delay_from_the_day_the_earlier_scene_was_answered() -> void:
	var scenes := [_scene({"scene_id": "DS10"}), _follow("DS11", "DS10", 3)]
	assert_true(DecisionScenes.is_follow_up(scenes[1]))
	assert_false(DecisionScenes.is_follow_up(scenes[0]))
	assert_eq(DecisionScenes.due_day(scenes[1], {}), -1, "not before the earlier scene is answered")
	var log := {"DS10": {"day": 100, "choice": "A"}}
	assert_eq(DecisionScenes.due_day(scenes[1], log), 103)
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 102).size(), 0, "two days in")
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 103).size(), 1, "on the day")
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 140).size(), 1, "still due when late")
	log["DS11"] = {"day": 104, "choice": "A"}
	assert_eq(DecisionScenes.due_follow_ups(scenes, log, 140).size(), 0, "once answered, never again")


func test_follow_if_branches_on_the_choice_made() -> void:
	var scenes := [_scene({"scene_id": "DS10"}), _follow("DS11", "DS10", 1, ["A"]), _follow("DS12", "DS10", 2, ["B", "C"]),
		_follow("DS13", "DS10", 1)]
	var log := {"DS10": {"day": 10, "choice": "B"}}
	var ids: Array = []
	for scene: Dictionary in DecisionScenes.due_follow_ups(scenes, log, 20):
		ids.append(scene["scene_id"])
	assert_eq(ids, ["DS13", "DS12"], "B leads to DS12 and the any-choice DS13, earliest first; not DS11")
	assert_eq(DecisionScenes.follow_if(scenes[2]), ["B", "C"])
	assert_eq(DecisionScenes.follow_if(scenes[3]), [])


func test_upcoming_follow_ups_are_those_still_waiting_inside_the_window() -> void:
	var scenes := [_scene({"scene_id": "DS10"}), _follow("DS11", "DS10", 3), _follow("DS12", "DS10", 30)]
	var log := {"DS10": {"day": 100, "choice": "A"}}
	assert_eq(DecisionScenes.upcoming_follow_ups(scenes, log, 100, 7).size(), 1, "DS11 only: DS12 is 30 days out")
	assert_eq(DecisionScenes.upcoming_follow_ups(scenes, log, 103, 7).size(), 0, "due today is due, not upcoming")


func test_descendants_count_down_every_branch_and_survive_a_loop() -> void:
	var scenes := [_scene({"scene_id": "DS10"}), _follow("DS11", "DS10", 1), _follow("DS12", "DS10", 1), _follow("DS13", "DS11", 1)]
	assert_eq(DecisionScenes.descendant_count(scenes, "DS10"), 3)
	assert_eq(DecisionScenes.descendant_count(scenes, "DS11"), 1)
	var loop := [_follow("DS20", "DS21", 1), _follow("DS21", "DS20", 1)]
	assert_eq(DecisionScenes.descendant_count(loop, "DS20"), 1, "a loop is cut off")
	assert_eq(DecisionScenes.MAX_FOLLOW_UPS, 5)


func _with_follow_up(over: Dictionary) -> void:
	# A throwaway follow-up event with one choice, hung under the pilot scene; undone in _drop_follow_up().
	var choice := {}
	for row: Dictionary in DataDB.event_choices:
		if str(row.get("event_id")) == "EV47" and str(row.get("choice")) == "B":
			choice = row.duplicate()
	choice["event_id"] = "EV_TEST_F"
	choice["choice"] = "A"
	DataDB.event_choices.append(choice)
	DataDB.events.append({"event_id": "EV_TEST_F", "title": "Test follow-up", "flavor": "x", "trigger": "Followup", "available": "Both",
		"hours": 0, "location": "Capitol"})
	var row := {"scene_id": "DS_TEST_F", "event_id": "EV_TEST_F", "kind": "Mandatory", "office": "Capitol", "follows": "DS01",
		"delay": 3, "follow_if": ["A"]}
	row.merge(over, true)
	DataDB.decision_scenes.append(row)


func _drop_follow_up() -> void:
	DataDB.decision_scenes = DataDB.decision_scenes.filter(func(s: Dictionary) -> bool: return str(s.get("scene_id")) != "DS_TEST_F")
	DataDB.events = DataDB.events.filter(func(e: Dictionary) -> bool: return str(e.get("event_id")) != "EV_TEST_F")
	DataDB.event_choices = DataDB.event_choices.filter(func(c: Dictionary) -> bool: return str(c.get("event_id")) != "EV_TEST_F")
	GameState.decision_log = {}


func test_answering_a_scene_logs_the_day_and_the_choice_and_its_follow_up_comes_due() -> void:
	_with_follow_up({})
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	var day := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	assert_eq(GameState.due_dated_event(), "EV47")
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	assert_eq(int((GameState.decision_log["DS01"] as Dictionary)["day"]), day)
	assert_eq((GameState.decision_log["DS01"] as Dictionary)["choice"], "A")
	assert_eq(GameState.due_dated_event(), "", "its delay is still running")
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40 * 3}
	var later := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	if later >= day + 3:
		assert_eq(GameState.due_dated_event(), "EV_TEST_F", "three days on")
	else:
		GameState.decision_log["DS01"]["day"] = later - 3
		assert_eq(GameState.due_dated_event(), "EV_TEST_F", "three days on")
	assert_true(GameState.apply_event_choice("EV_TEST_F", "A")["ok"])
	assert_eq(GameState.due_dated_event(), "", "fires once")
	assert_true((GameState.to_save()["decision_log"] as Dictionary).has("DS_TEST_F"), "saved")
	_drop_follow_up()


func test_a_choice_outside_follow_if_never_brings_the_follow_up() -> void:
	_with_follow_up({})
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	assert_true(GameState.apply_event_choice("EV47", "B")["ok"])
	GameState.decision_log["DS01"]["day"] = 0
	assert_eq(GameState.due_dated_event(), "", "Follow If is A and the choice was B")
	_drop_follow_up()


func test_a_follow_up_wears_the_decision_tag_and_its_office_moves_you() -> void:
	_with_follow_up({"office": "District"})
	var event := GameState.get_event("EV_TEST_F")
	assert_eq(GameState.event_office(event), Offices.DISTRICT, "the scene's office, not the event's location")
	_drop_follow_up()


# --- Activations (phase 3) -------------------------------------------------------------------------------------------------------

func test_activates_cells_parse_into_kind_id_and_choice_limits() -> void:
	var entries := DecisionScenes.parse_activates("level:LV98@A; vote:BI01 ;event:EV31@b,c; nonsense; stage:")
	assert_eq(entries.size(), 3, "a piece that is not kind:ID is skipped")
	assert_eq(entries[0], {"kind": "level", "id": "LV98", "letters": ["A"]})
	assert_eq(entries[1], {"kind": "vote", "id": "BI01", "letters": []})
	assert_eq(entries[2]["letters"], ["B", "C"], "letters are upper-cased")
	assert_eq(DecisionScenes.parse_activates(null), [])
	var scene := {"activates": "level:LV98@A; vote:BI01; event:EV31@B,C"}
	assert_eq(DecisionScenes.activations_for(scene, "A").size(), 2, "A: the level and the any-choice vote")
	assert_eq(DecisionScenes.activations_for(scene, "B").size(), 2, "B: the vote and the event")
	assert_eq(DecisionScenes.activations_for(scene, "D").size(), 1, "D: only the any-choice vote")


func test_stage_and_vote_activations_become_a_one_stage_level() -> void:
	var level := DecisionScenes.ad_hoc_level("vote", "BI01", "A vote", "Capitol")
	assert_eq(level["level_id"], "DSL_vote_BI01")
	assert_eq(level["stage_1"], "BI01")
	assert_eq(level["location"], "Capitol")
	assert_true(DecisionScenes.is_ad_hoc_level_id(level["level_id"]))
	assert_false(DecisionScenes.is_ad_hoc_level_id("LV01"))


func _give_ds01(activates: String) -> Variant:
	var scene := GameState.decision_scene_of("EV47")
	var before: Variant = scene.get("activates")
	scene["activates"] = activates
	return before


func test_answering_a_scene_starts_what_it_activates() -> void:
	var before: Variant = _give_ds01("unlock:LV98; event:EV31; vote:BI01@A; stage:ST271@B")
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.pending_activations = []
	GameState.scheduled_events = []
	GameState.discovered_levels = []
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	var result := GameState.apply_event_choice("EV47", "A")
	assert_true(result["ok"])
	assert_true(GameState.discovered_levels.has("LV98"), "the unlock is applied at once")
	assert_eq(GameState.scheduled_events.size(), 1, "the event is queued")
	assert_eq(GameState.scheduled_events[0]["event_id"], "EV31")
	assert_eq(GameState.pending_activations.size(), 1, "only the A-limited vote waits; the B stage does not")
	assert_eq(GameState.pending_activations[0]["kind"], "vote")
	var lines: String = "\n".join(PackedStringArray(result["lines"]))
	assert_true(lines.contains("Next:"), "the result card says a vote is ready")
	GameState.scene_decision_scene_restore("EV47", before)


func test_a_pending_vote_becomes_a_runnable_level_and_leaves_when_begun() -> void:
	var before: Variant = _give_ds01("vote:BI01")
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.pending_activations = []
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	var next := GameState.next_activation()
	assert_eq(next["kind"], "vote")
	var level: Dictionary = next["level"]
	assert_eq(level["level_id"], "DSL_vote_BI01")
	assert_true(DataDB.is_runtime_level("DSL_vote_BI01"), "the briefing and runner can find it by id")
	var runner := LevelRunner.new(BattleSetup.expand_level(level))
	assert_true(runner.is_valid(), "a vote on its own is a playable level: %s" % str(runner.problems()))
	GameState.finish_activation("DSL_vote_BI01")
	assert_true(GameState.pending_activations.is_empty(), "begun, so no longer waiting")
	assert_eq(GameState.scene_runtime["level"]["level_id"], "DSL_vote_BI01", "kept for a mid-level save")
	assert_true((GameState.to_save()["scene_runtime"] as Dictionary).has("level"))
	GameState.end_level()
	assert_true(GameState.scene_runtime.is_empty(), "cleared with the level")
	GameState.scene_decision_scene_restore("EV47", before)
	DataDB.clear_runtime()


func test_a_pending_existing_level_is_offered_as_itself() -> void:
	var before: Variant = _give_ds01("level:LV98")
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.pending_activations = []
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	assert_eq(str(GameState.next_activation()["level"]["level_id"]), "LV98")
	GameState.finish_activation("LV98")
	assert_true(GameState.next_activation().is_empty())
	GameState.scene_decision_scene_restore("EV47", before)


func test_a_scene_started_vote_can_be_played_to_its_end() -> void:
	var before: Variant = _give_ds01("vote:BI01")
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.pending_activations = []
	GameState.levels_cleared = {}
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	var level: Dictionary = GameState.next_activation()["level"]
	GameState.finish_activation(str(level["level_id"]))
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(level)))
	assert_true(GameState.is_in_level())
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 0)
	assert_false(GameState.levels_cleared.has("DSL_vote_BI01"), "a scene's one-stage level is not a cleared level of its own")
	GameState.end_level()
	GameState.scene_decision_scene_restore("EV47", before)
	DataDB.clear_runtime()


# --- Optional scenes (phase 4) ---------------------------------------------------------------------------------------------------

func _optional(over: Dictionary = {}) -> Dictionary:
	var base := {"scene_id": "DS30", "event_id": "E_DS30", "kind": "Optional", "office": "Capitol", "opens": "18.10.15", "closes": "18.10.19",
		"follows": null, "delay": null, "follow_if": null}
	base.merge(over, true)
	return base


func test_an_optional_scene_window_runs_from_opens_to_closes() -> void:
	var scene := _optional()
	var opens := WeekCalendar.parse_date("18.10.15")
	var closes := WeekCalendar.parse_date("18.10.19")
	assert_true(DecisionScenes.is_optional(scene))
	assert_eq(DecisionScenes.window(scene, {}), [opens, closes])
	assert_eq(DecisionScenes.open_now([scene], {}, opens - 1).size(), 0, "not yet")
	assert_eq(DecisionScenes.open_now([scene], {}, opens).size(), 1, "the first day")
	assert_eq(DecisionScenes.open_now([scene], {}, closes).size(), 1, "the last day")
	assert_eq(DecisionScenes.open_now([scene], {}, closes + 1).size(), 0, "closed")
	assert_eq(DecisionScenes.days_left(scene, {}, opens), 5, "five days counting today")
	assert_eq(DecisionScenes.days_left(scene, {}, closes), 1, "the last day")
	assert_eq(DecisionScenes.days_left(scene, {}, closes + 1), 0)
	assert_eq(DecisionScenes.optional_upcoming([scene], {}, opens - 3, 7).size(), 1, "opens within the window of days ahead")
	assert_eq(DecisionScenes.optional_upcoming([scene], {}, opens, 7).size(), 0, "already open is not upcoming")


func test_an_answered_optional_scene_is_neither_open_nor_lapsed() -> void:
	var scene := _optional()
	var log := {"DS30": {"day": WeekCalendar.parse_date("18.10.16"), "choice": "A"}}
	assert_eq(DecisionScenes.open_now([scene], log, WeekCalendar.parse_date("18.10.17")).size(), 0)
	assert_eq(DecisionScenes.lapsed([scene], log, WeekCalendar.parse_date("18.10.27")).size(), 0)


func test_an_unopened_optional_scene_lapses_after_closes() -> void:
	var scene := _optional()
	var closes := WeekCalendar.parse_date("18.10.19")
	assert_eq(DecisionScenes.lapsed([scene], {}, closes).size(), 0, "still open on its last day")
	assert_eq(DecisionScenes.lapsed([scene], {}, closes + 1).size(), 1)
	assert_eq(DecisionScenes.lapsed([_scene()], {}, closes + 1).size(), 0, "a Mandatory scene never lapses")


func test_an_optional_follow_up_opens_from_its_delay_and_never_by_itself() -> void:
	var parent := _scene({"scene_id": "DS10"})
	var child := _optional({"scene_id": "DS31", "follows": "DS10", "opens": null, "delay": 2, "closes": "18.11.06"})
	var log := {"DS10": {"day": WeekCalendar.parse_date("18.10.17"), "choice": "A"}}
	assert_eq(DecisionScenes.window(child, log)[0], WeekCalendar.parse_date("18.10.19"))
	assert_eq(DecisionScenes.window(child, {}), [-1, -1], "no window until the earlier scene is answered")
	assert_eq(DecisionScenes.due_follow_ups([parent, child], log, WeekCalendar.parse_date("18.10.27")).size(), 0, "not a self-opening follow-up")
	assert_eq(DecisionScenes.open_now([parent, child], log, WeekCalendar.parse_date("18.10.27")).size(), 1)


func test_the_reserved_choice_is_never_offered_but_can_be_found() -> void:
	var rows := [{"event_id": "E1", "choice": "A"}, {"event_id": "E1", "choice": "L"}, {"event_id": "E1", "choice": "B"}]
	assert_eq(EventEngine.choices_for(rows, "E1").size(), 2, "L is not a button")
	assert_eq(EventEngine.lapse_choice(rows, "E1")["choice"], "L")
	assert_true(EventEngine.lapse_choice(rows, "E2").is_empty())


func _with_optional(closes: String, penalty_funds: int) -> void:
	# A throwaway Optional scene on a throwaway event with a choice A and a lapse penalty L (Funds).
	DataDB.events.append({"event_id": "EV_TEST_O", "title": "Test optional", "flavor": "x", "trigger": "Dated", "available": "Both",
		"hours": 2, "location": "Capitol", "on_date": "18.10.15"})
	DataDB.event_choices.append({"event_id": "EV_TEST_O", "choice": "A", "choice_text": "Go", "result_text": "You went."})
	DataDB.event_choices.append({"event_id": "EV_TEST_O", "choice": "L", "choice_text": "(lapse)", "result_text": "It passed without you.",
		"funds_delta": {"min": -penalty_funds, "max": -penalty_funds}})
	DataDB.decision_scenes.append({"scene_id": "DS_TEST_O", "event_id": "EV_TEST_O", "kind": "Optional", "opens": "18.10.15",
		"closes": closes, "office": "Capitol"})


func _drop_optional() -> void:
	DataDB.decision_scenes = DataDB.decision_scenes.filter(func(s: Dictionary) -> bool: return str(s.get("scene_id")) != "DS_TEST_O")
	DataDB.events = DataDB.events.filter(func(e: Dictionary) -> bool: return str(e.get("event_id")) != "EV_TEST_O")
	DataDB.event_choices = DataDB.event_choices.filter(func(c: Dictionary) -> bool: return str(c.get("event_id")) != "EV_TEST_O")
	GameState.decision_log = {}
	GameState.dated_events_done = []


func test_an_optional_scene_never_opens_by_itself_and_is_listed_where_you_can_open_it() -> void:
	_with_optional("18.10.19", 500)
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}   # Monday 18.10.15
	assert_eq(GameState.due_dated_event(), "EV47", "the Mandatory address, never the Optional one")
	GameState.dated_events_done.append("EV47")
	assert_eq(GameState.due_dated_event(), "", "an Optional scene waits for the player")
	var rows := GameState.optional_scenes_open()
	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["refusal"], "", "at its own office it can be opened")
	GameState.office_location = Offices.DISTRICT
	assert_ne(GameState.optional_scenes_open()[0]["refusal"], "", "elsewhere it says why not")
	assert_ne(GameState.optional_scene_refusal("EV_TEST_O"), "")
	GameState.office_location = Offices.CAPITOL
	assert_eq(GameState.optional_scene_refusal("EV_TEST_O"), "")
	assert_true(GameState.apply_event_choice("EV_TEST_O", "A")["ok"])
	assert_eq(GameState.optional_scenes_open().size(), 0, "answered: fires once")
	_drop_optional()


func test_a_lapsed_optional_scene_applies_its_penalty_once() -> void:
	_with_optional("18.10.16", 500)
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.meta["Funds"] = 10000
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}   # past 18.10.16
	var funds_before := int(GameState.meta["Funds"])
	var hours_before := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())
	var told := GameState.apply_scene_lapses()
	assert_eq(told.size(), 1, "one scene lapsed")
	assert_eq(told[0]["result_text"], "It passed without you.")
	assert_eq(int(GameState.meta["Funds"]), funds_before - 500, "the penalty is charged")
	assert_eq(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()), hours_before, "a lapse spends no hours")
	assert_eq((GameState.decision_log["DS_TEST_O"] as Dictionary)["choice"], "L")
	assert_eq(GameState.apply_scene_lapses().size(), 0, "fires once")
	_drop_optional()


func test_a_lapse_with_no_penalty_row_is_remembered_quietly() -> void:
	_with_optional("18.10.16", 0)
	DataDB.event_choices = DataDB.event_choices.filter(func(c: Dictionary) -> bool: return not (str(c.get("event_id")) == "EV_TEST_O" and str(c.get("choice")) == "L"))
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}
	assert_eq(GameState.apply_scene_lapses().size(), 0, "nothing to tell")
	assert_true(GameState.decision_log.has("DS_TEST_O"), "but it is not checked again")
	_drop_optional()
