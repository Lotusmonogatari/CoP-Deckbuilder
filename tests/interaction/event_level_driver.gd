class_name EventLevelDriver
extends Node
## Real clicks through an event whose choice starts a level (2026-10-31): the
## event shows its duration range; the choice opens the level's briefing
## without taking anything; Back returns to the same event; the choice again
## and Go in takes it and opens the stage. The event and level are found from
## the workbook data, never typed here.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.calendar = WeekCalendar.fresh()
	var event_id := ""
	var letter := ""
	for choice: Dictionary in DataDB.event_choices:
		if not GameState.event_choice_level(choice).is_empty():
			event_id = str(choice["event_id"])
			letter = str(choice["choice"])
			break
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var office := get_tree().current_scene
	var event := GameState.get_event(event_id)
	var hours_before := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())

	office._present_event(event_id, true)
	await get_tree().process_frame
	var panel := office.get_node("EventPanel") as Overlay
	var text := _texts(panel)
	_expect(text.contains(Text.say("event.duration", {"hours": GameState.event_hours_text(event),
		"count": GameState.event_hours_range(event)[1]})), "the event shows its duration range")

	await _click(panel.find_child("EventChoice_" + letter, true, false))
	var briefing := office.get_node("%BriefingPanel") as Overlay
	_expect(briefing.visible, "the choice opens the level's briefing")
	_expect(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()) == hours_before,
		"nothing is taken before Go in")

	await _click(briefing.find_child("Back", true, false))
	await get_tree().create_timer(0.3).timeout
	_expect(panel.visible and not briefing.visible, "Back returns to the event")

	await _click(panel.find_child("EventChoice_" + letter, true, false))
	_expect(briefing.visible, "the choice opens the briefing again")
	await _click(briefing.find_child("Confirm", true, false))
	await get_tree().create_timer(0.8).timeout
	_expect(GameState.is_in_level(), "Go in starts the level")
	_expect(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()) < hours_before
		or EventEngine.hours_of(event) == 0, "and the event's hours are spent")
	_finish()


func _texts(node: Node) -> String:
	var out := ""
	for child in node.find_children("*", "Label", true, false):
		out += (child as Label).text + "\n"
	return out


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
		print("EVENT LEVEL TEST: PASS")
		get_tree().quit(0)
	else:
		print("EVENT LEVEL TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
