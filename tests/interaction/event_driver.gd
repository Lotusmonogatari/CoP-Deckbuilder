class_name EventDriver
extends Node
## Real clicks through events (2026-10-23): the Events list, arranging the
## walking tour (price and hours paid), choosing, the result and Continue; then
## a random event that reveals a hidden level, which then shows in the list.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 100000
	await _open_office()
	await _walking_tour()
	await _street_question()
	await _gathering_picture()
	print("")
	if _failures.is_empty():
		print("EVENT TEST: PASS")
		get_tree().quit(0)
	else:
		print("EVENT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _screen() -> Node:
	return get_tree().current_scene


func _walking_tour() -> void:
	var button := _screen().find_child("EventsButton", true, false) as Button
	_expect(button != null and button.visible, "the Office has an Events button")
	if button == null:
		return
	button.pressed.emit()
	await get_tree().process_frame
	var list := _screen().get_node("EventsPanel") as Overlay
	_expect(list.visible, "the Events list opens")
	var arrange := list.find_child("Arrange_EV32", true, false) as Button
	_expect(arrange != null and not arrange.disabled, "the sports sponsorship can be arranged")
	var weekend_only := list.find_child("Arrange_EV34", true, false) as Button
	_expect(weekend_only != null and weekend_only.disabled and weekend_only.text == "Weekend only", "the office open day waits for the weekend")
	arrange.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	_expect(int(GameState.meta["Funds"]) == 80000, "the 20,000円 price is paid, got %d" % int(GameState.meta["Funds"]))
	var panel := _screen().get_node("EventPanel") as Overlay
	_expect(panel.visible, "the event screen opens")
	var choice := panel.find_child("EventChoice_A", true, false) as Button
	_expect(choice != null, "it offers its choices")
	_save_shot("event_choices")
	if choice != null:
		choice.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	_expect(int(GameState.calendar["hours"]) == 2, "the event takes 2 hours, got %d" % int(GameState.calendar["hours"]))
	_expect(int(GameState.awareness["district"]) >= 22, "District Awareness rose")
	var done := panel.find_child("EventContinueButton", true, false) as Button
	_expect(done != null, "the result has a Continue button")
	_save_shot("event_result")
	if done != null:
		done.pressed.emit()
	await get_tree().process_frame
	_expect(not panel.visible, "Continue closes the event")


func _street_question() -> void:
	var screen := _screen()
	_expect(not _levels_text(screen).contains("Coastal Defense"), "the coastal bill is hidden before the event")
	screen._present_event("EV17", true)
	await get_tree().process_frame
	var panel := screen.get_node("EventPanel") as Overlay
	var choice := panel.find_child("EventChoice_A", true, false) as Button
	_expect(choice != null, "the street question offers its choices")
	if choice != null:
		choice.pressed.emit()
	await get_tree().process_frame
	var done := panel.find_child("EventContinueButton", true, false) as Button
	if done != null:
		done.pressed.emit()
	await get_tree().process_frame
	_expect(GameState.discovered_levels.has("LV35"), "the event revealed the coastal bill level")
	_expect(_levels_text(screen).contains("Coastal Defense"), "and it now shows in the levels list")


## The dinner and tour popup shows its own picture (a labelled placeholder until
## the art is drawn): DINING, or TOUR.
func _gathering_picture() -> void:
	var screen := _screen()
	screen._show_gathering({"image": "DINING", "message": "A fine evening."})
	await get_tree().process_frame
	var panel := screen.get_node("GatheringPanel") as Overlay
	_expect(panel.visible, "the gathering popup opens")
	_expect(panel.find_child("Picture_DINING", true, false) != null, "it shows the DINING picture")
	_save_shot("event_gathering")
	var done := panel.find_child("GatheringContinueButton", true, false) as Button
	if done != null:
		done.pressed.emit()
	await get_tree().process_frame
	_expect(not panel.visible, "Continue closes it")


func _levels_text(screen: Node) -> String:
	screen._show_levels()
	var panel := screen.get_node("LevelsPanel")
	return _label_text(panel)


func _label_text(root: Node) -> String:
	var text := ""
	if root is Label:
		text += (root as Label).text + " "
	for child in root.get_children():
		text += _label_text(child)
	return text


func _save_shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://shots")
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
