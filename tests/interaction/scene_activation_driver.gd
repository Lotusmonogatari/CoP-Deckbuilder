class_name SceneActivationDriver
extends Node
## Real clicks through a Decision! scene that starts a vote (2026-11-21, phase 3): the Prime Minister's address is answered, its
## result card says a vote is ready, Continue opens that vote's briefing, Back leaves it waiting, the next Office open offers it
## again and Go in begins a one-stage level whose stage is the named bill's Floor Vote. The scene's Activates cell is set here
## in memory; the workbook is not changed.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	GameState.office_location = Offices.CAPITOL
	GameState.dated_events_done = []
	GameState.decision_log = {}
	GameState.pending_activations = []
	var bill_id := str(DataDB.floor_votes.keys()[0])
	var scene := GameState.decision_scene_of("EV47")
	scene["activates"] = "vote:" + bill_id
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	await _open_office()
	var office := get_tree().current_scene
	var panel := office.get_node("EventPanel") as Overlay
	_expect(panel.visible, "the address opens by itself")
	await _click(panel.find_child("EventChoice_A", true, false))
	_expect(_texts(panel).contains("Next:"), "the result says a vote is ready")
	_expect(GameState.pending_activations.size() == 1, "the vote waits")
	await _click(panel.find_child("EventContinueButton", true, false))
	await get_tree().create_timer(0.4).timeout
	var briefing := office.get_node("%BriefingPanel") as Overlay
	_expect(briefing.visible, "Continue opens the vote's briefing")
	await _click(briefing.find_child("Back", true, false))
	await get_tree().create_timer(0.3).timeout
	_expect(GameState.pending_activations.size() == 1, "Back leaves it waiting")
	_expect(not GameState.is_in_level(), "nothing has begun")

	await _open_office()
	office = get_tree().current_scene
	briefing = office.get_node("%BriefingPanel") as Overlay
	_expect(briefing.visible, "the next Office open offers it again")
	await _click(briefing.find_child("Confirm", true, false))
	await get_tree().create_timer(0.8).timeout
	_expect(GameState.is_in_level(), "Go in begins it")
	_expect(GameState.pending_activations.is_empty(), "and it no longer waits")
	_expect(GameState.level_runner != null and str(GameState.level_runner.current_stage().get("mode", "")) == "Vote",
		"its one stage is a Floor Vote")
	_expect(GameState.level_runner.stage_count() == 1, "and it is the only stage")
	scene["activates"] = null
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	_finish()


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
		print("SCENE ACTIVATION TEST: PASS")
		get_tree().quit(0)
	else:
		print("SCENE ACTIVATION TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
