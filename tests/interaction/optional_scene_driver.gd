class_name OptionalSceneDriver
extends Node
## Real clicks through an Optional Decision! scene (2026-11-21, phase 4): it does not open by itself, the Events screen lists it with
## its days left and an Open it button, a greyed button with a reason shows at the other office, opening shows the card with the
## Optional note, and a choice answers it once. A second scene is left to lapse: the Office tells the player once. The scenes are
## added to the loaded data here; the workbook is not changed.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}   # Monday 18.10.15
	GameState.office_location = Offices.CAPITOL
	GameState.dated_events_done = ["EV47"]
	GameState.decision_log = {}
	_add_scene("O1", "18.10.15", "18.10.19", "Capitol")
	_add_scene("O2", "18.10.01", "18.10.05", "Capitol")   # closed before today: lapses
	GameState.meta["Funds"] = 10000
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	await _open_office()
	var office := get_tree().current_scene
	var panel := office.get_node("EventPanel") as Overlay
	_expect(panel.visible and _texts(panel).contains("Missed decisions"), "the lapsed scene is told on opening the Office")
	_expect(int(GameState.meta["Funds"]) == 9500, "its penalty was charged")
	await _click(panel.find_child("LapseContinueButton", true, false))
	_expect(not panel.visible, "Continue closes it")
	_expect(GameState.decision_log.has("DS_O2"), "and it will not be told again")

	office._show_events_list()
	await get_tree().create_timer(0.4).timeout
	var open_button := office.find_child("OpenOptional_EV_O1", true, false) as Button
	_expect(open_button != null, "the Events screen lists the Optional scene")
	_expect(open_button != null and not open_button.disabled, "and it can be opened at its own office")
	_expect(_texts(office).contains("Optional · 5 days left"), "with its days left")
	await _click(open_button)
	await get_tree().create_timer(0.4).timeout
	_expect(panel.visible and _texts(panel).contains("Optional. You chose to open this one."), "opening shows the card with the Optional note")
	await _click(panel.find_child("EventChoice_A", true, false))
	_expect(GameState.decision_log.has("DS_O1"), "answering records it")
	_expect(GameState.optional_scenes_open().is_empty(), "it does not come back")
	_drop()
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	_finish()


func _add_scene(tag: String, opens: String, closes: String, office: String) -> void:
	DataDB.events.append({"event_id": "EV_" + tag, "title": "Optional " + tag, "flavor": "A test.", "trigger": "Dated", "available": "Both",
		"hours": 1, "location": office, "on_date": opens})
	DataDB.event_choices.append({"event_id": "EV_" + tag, "choice": "A", "choice_text": "Do it", "result_text": "Done."})
	DataDB.event_choices.append({"event_id": "EV_" + tag, "choice": "L", "choice_text": "(lapse)", "result_text": "It passed.",
		"funds_delta": {"min": -500, "max": -500}})
	DataDB.decision_scenes.append({"scene_id": "DS_" + tag, "event_id": "EV_" + tag, "kind": "Optional", "opens": opens,
		"closes": closes, "office": office})


func _drop() -> void:
	DataDB.decision_scenes = DataDB.decision_scenes.filter(func(s: Dictionary) -> bool: return not str(s.get("scene_id")).begins_with("DS_O"))
	DataDB.events = DataDB.events.filter(func(e: Dictionary) -> bool: return not str(e.get("event_id")).begins_with("EV_O"))
	DataDB.event_choices = DataDB.event_choices.filter(func(c: Dictionary) -> bool: return not str(c.get("event_id")).begins_with("EV_O"))


func _texts(node: Node) -> String:
	var out := ""
	for child in node.find_children("*", "Label", true, false):
		out += (child as Label).text + "\n"
	return out


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _click(control: Variant) -> void:
	if not (control is Control):
		_failures.append("a control this test needed does not exist")
		return
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * (control as Control).get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)


func _finish() -> void:
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("OPTIONAL SCENE TEST: PASS")
		get_tree().quit(0)
	else:
		print("OPTIONAL SCENE TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
