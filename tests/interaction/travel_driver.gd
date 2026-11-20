class_name TravelDriver
extends Node
## Two offices, slice 1 (2026-11-20): the Office as a player uses it. The trip button states where it goes, how long
## and by what before it is pressed; the popup states the cost again; a trip spends the hours, changes the office
## picture and the level list (a level is listed only at its own office); a trip that cannot be taken says why.

const STYLES := [UiStyles.LIVING_OFFICE, UiStyles.BROADCAST, UiStyles.WOODBLOCK]

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	for style: String in STYLES:
		UiStyle.trying = style
		UiStyle.sync()
		GameState.start_new_run("PC01")
		GameState.awaiting_new_game = false
		GameState.calendar = WeekCalendar.fresh()
		await _open_office()
		await _trip(style)
	UiStyle.trying = ""
	UiStyle.sync()
	print("")
	if _failures.is_empty():
		print("TRAVEL TEST: PASS")
		get_tree().quit(0)
	else:
		print("TRAVEL TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _screen() -> Node:
	return get_tree().current_scene


func _texts(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for label: Node in node.find_children("*", "Label", true, false):
		out.append((label as Label).text)
	for button: Node in node.find_children("*", "Button", true, false):
		out.append((button as Button).text)
	return out


func _levels_panel() -> Overlay:
	_screen().call("_show_levels")
	await get_tree().create_timer(0.4).timeout
	return _screen().get_node("%LevelsPanel") as Overlay


func _left() -> int:
	return WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())


func _trip(style: String) -> void:
	var where := "in %s: " % style
	var office := _screen()
	var button := office.find_child("TravelButton", true, false) as Button
	_expect(button != null, where + "the Office has a trip button")
	if button == null:
		return
	_expect(button.text == "To Noheji · 7 h · Rail pass" and not button.disabled, where + "the trip button says where, how long and how (%s)" % button.text)
	_expect(button.size.y >= 100.0 and button.get_global_rect().end.x <= 1081.0, where + "it is big enough and on screen")
	var report := office.get_node("%Report") as Label
	_expect(report.text.begins_with("You are at the Capitol."), where + "the Office says where you are (%s)" % report.text)

	# At the Capitol: Capitol and Either levels are listed, District levels are not.
	var levels := await _levels_panel()
	var seen := _texts(levels)
	_expect(seen.has("Hearing at the Committee on the Environment"), where + "a Capitol level is listed at the Capitol")
	_expect(seen.has("Meeting Lobbyists"), where + "an Either level is listed at the Capitol")
	_expect(not seen.has("Talking with Constituents"), where + "a District level is not listed at the Capitol")
	levels.close()
	await get_tree().process_frame

	# The popup says the cost before the trip is taken.
	button.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	var panel := office.get_node("TravelPanel") as Overlay
	var words := _texts(panel)
	_expect(panel.visible, where + "the trip popup opens")
	_expect(words.has("Go to Noheji: 7 h by rail pass. Free on the member's rail pass."), where + "it states the trip (%s)" % [words])
	_expect(words.has("You will have 33 h left this week."), where + "and what is left")
	_expect(GameState.office_location == Offices.CAPITOL and _left() == 40, where + "nothing is spent until the trip is taken")
	var stay := _find_button(panel, "Stay here")
	_expect(stay != null, where + "there is a way to stay")
	if stay != null:
		stay.pressed.emit()
		await get_tree().process_frame
		_expect(not panel.visible and GameState.office_location == Offices.CAPITOL, where + "staying changes nothing")

	# Take it.
	button.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	var go := _find_button(panel, "Take the trip")
	_expect(go != null, where + "the popup has the button that takes the trip")
	if go == null:
		return
	go.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	_expect(GameState.office_location == Offices.DISTRICT, where + "the player is at the District office")
	_expect(_left() == 33, where + "seven hours were spent (%d left)" % _left())
	_expect(button.text == "To the Capitol · 7 h · Rail pass", where + "the button now goes back (%s)" % button.text)
	_expect(report.text.begins_with("You are at your District office in Noheji."), where + "the Office says so (%s)" % report.text)
	var background: Variant = office.get("_background")
	_expect(background != null and str(background.art_id) == "DISTRICT_OFFICE_PC01", where + "the District office picture (a labelled placeholder until it is drawn)")

	# At the District: the lists swap.
	levels = await _levels_panel()
	seen = _texts(levels)
	_expect(seen.has("Talking with Constituents"), where + "a District level is listed at the District office")
	_expect(seen.has("Meeting Lobbyists"), where + "an Either level is listed there too")
	_expect(not seen.has("Hearing at the Committee on the Environment"), where + "a Capitol level is not")
	levels.close()
	await get_tree().process_frame

	# A trip that cannot be taken says why (Information Standard 2).
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": 36}
	office.call("_refresh_calendar")
	_expect(button.disabled and button.text == "The trip takes 7 h and the week has less left.", where + "too few hours: greyed, with the reason (%s)" % button.text)
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WEEKEND, "hours": 0}
	office.call("_refresh_calendar")
	_expect(button.disabled and button.text == "No travel at the weekend.", where + "at the weekend: greyed, with the reason (%s)" % button.text)
	GameState.calendar = WeekCalendar.fresh()
	GameState.office_location = Offices.CAPITOL


func _find_button(node: Node, text: String) -> Button:
	for button: Node in node.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			return button as Button
	return null
