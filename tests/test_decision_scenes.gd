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
