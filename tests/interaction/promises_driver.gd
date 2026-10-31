class_name PromisesDriver
extends Node
## Real clicks through a promise (2026-10-31): an event choice that promises an
## item is taken; the Office shows a Promises button; the panel's Keep button is
## greyed until the item is held; once held, Keep hands it over and the promise
## is gone. The event and item are found from the workbook data.

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
	var item_id := ""
	for choice: Dictionary in DataDB.event_choices:
		for entry: Variant in Commitments.of(choice):
			if entry is Dictionary and str(entry.get("kind", "")) == Promises.PROMISE_ITEM and event_id.is_empty():
				event_id = str(choice["event_id"])
				letter = str(choice["choice"])
				item_id = str(entry["item_id"])
	GameState.inventory.erase(item_id)
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var office := get_tree().current_scene

	office._present_event(event_id, true)
	await get_tree().process_frame
	await _click(office.get_node("EventPanel").find_child("EventChoice_" + letter, true, false))
	_expect(GameState.promises.size() == 1, "the choice made a promise")
	await _click(office.get_node("EventPanel").find_child("EventContinueButton", true, false))
	await get_tree().create_timer(0.4).timeout
	office = get_tree().current_scene
	var button := office.find_child("PromisesButton", true, false) as Button
	_expect(button != null and button.visible, "the Office shows a Promises button")
	if button == null:
		return _finish()
	await _click(button)
	var panel := office.get_node("PromisesPanel") as Overlay
	var keep := panel.find_child("Keep_*", true, false) as Button
	_expect(panel.visible and keep != null and keep.disabled, "Keep is greyed until the item is held")
	panel.close()
	GameState.add_item(item_id)
	await _click(button)
	keep = panel.find_child("Keep_*", true, false) as Button
	_expect(keep != null and not keep.disabled, "with the item held, Keep is available")
	await _click(keep)
	_expect(GameState.promises.is_empty() and GameState.item_count(item_id) == 0, "keeping it hands the item over")
	_finish()


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
		print("PROMISES TEST: PASS")
		get_tree().quit(0)
	else:
		print("PROMISES TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
