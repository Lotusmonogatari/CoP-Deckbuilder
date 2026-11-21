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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
	assert_eq(GameState.due_dated_event(), "EV47")
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	GameState.calendar = {"week": 30, "phase": "work", "hours": 0}
	assert_eq(GameState.due_dated_event(), "", "never again, however late")


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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
	var day := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	assert_eq(GameState.due_dated_event(), "EV47")
	assert_true(GameState.apply_event_choice("EV47", "A")["ok"])
	assert_eq(int((GameState.decision_log["DS01"] as Dictionary)["day"]), day)
	assert_eq((GameState.decision_log["DS01"] as Dictionary)["choice"], "A")
	assert_eq(GameState.due_dated_event(), "", "its delay is still running")
	GameState.calendar = {"week": 1, "phase": "work", "hours": 40 * 3}
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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
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
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
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
