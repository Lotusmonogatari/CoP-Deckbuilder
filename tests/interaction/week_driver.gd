class_name WeekDriver
extends Node
## Real clicks through the week (2026-10-23): the calendar square on Monday,
## the Friday "End the Work Week" button and its confirm panel, the optional
## weekend, "Pay Party Dues and Go Home", and the new-week popup. Also that a
## weekend level list refuses ordinary levels and a full work week offers the
## weekend or home.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	await _open_office()
	_check_monday()
	await _friday_flow()
	await _week_over_flow()
	await _short_on_funds_flow()
	print("")
	if _failures.is_empty():
		print("WEEK TEST: PASS")
		get_tree().quit(0)
	else:
		print("WEEK TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _open_office() -> void:
	GameState.awaiting_new_game = false
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _screen() -> Node:
	return get_tree().current_scene


func _check_monday() -> void:
	var date := _screen().find_child("CalendarDate", true, false) as Label
	var hours := _screen().find_child("CalendarHours", true, false) as Label
	_expect(date != null and date.text == "18.10.01", "calendar date starts at 18.10.01, got %s" % (date.text if date else "none"))
	_expect(hours != null and hours.text == "8 Work Hours", "bottom row reads 8 Work Hours, got %s" % (hours.text if hours else "none"))
	var button := _screen().find_child("WeekButton", true, false) as Button
	_expect(button != null and not button.visible, "no week button on a Monday")


func _friday_flow() -> void:
	GameState.calendar = {"week": 0, "phase": "work", "hours": 34}
	GameState.meta["Funds"] = 100000
	GameState.meta["Party support"] = 40
	await _open_office()
	var button := _screen().find_child("WeekButton", true, false) as Button
	_expect(button != null and button.visible and button.text == "End the Work Week", "Friday shows End the Work Week")
	if button == null:
		return
	button.pressed.emit()
	await get_tree().process_frame
	var confirm := _screen().get_node("WeekConfirmPanel") as Overlay
	_expect(confirm.visible, "ending the week asks first")
	var yes := _find_button(confirm, "End the Work Week")
	_expect(yes != null, "the confirm panel has its button")
	if yes != null:
		yes.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	_expect(GameState.in_weekend(), "the weekend begins")
	_expect(GameState.time_units == 6, "the 6 unused work hours still pass, got %d" % GameState.time_units)
	var date := _screen().find_child("CalendarDate", true, false) as Label
	_expect(date.text == "18.10.06", "Saturday is 18.10.06, got %s" % date.text)
	_expect((_screen().find_child("CalendarHours", true, false) as Label).text == "4 Weekend Hours", "weekend hours row")
	_expect(GameState.level_calendar_refusal(DataDB.get_level("LV01")) == "Not a weekend level", "ordinary levels wait for the work week")
	_expect(GameState.level_calendar_refusal(DataDB.get_level("LV83")) == "", "the Town Hall special level is weekend-OK")
	_save_shot("week_weekend")
	button = _screen().find_child("WeekButton", true, false) as Button
	_expect(button.visible and button.text == "Pay Party Dues and Go Home", "weekend button reads Pay Party Dues and Go Home")
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var popup := _screen().get_node("NewWeekPanel") as Overlay
	_expect(popup.visible, "a popup announces the new week")
	_expect(_label_text(popup).contains("18.10.08"), "the popup names the new date")
	_expect(_label_text(popup).contains("Party dues paid: 50,000"), "the popup reports the dues paid, got: %s" % _label_text(popup))
	_expect(int(GameState.meta["Funds"]) == 50000, "50,000 of PC01's 100,000 went to the party, got %d" % int(GameState.meta["Funds"]))
	_expect(not GameState.in_weekend() and int(GameState.calendar["week"]) == 1, "back to a work week")
	_save_shot("week_new")
	var go := _find_button(popup, "Start the Week")
	if go != null:
		go.pressed.emit()
	await get_tree().process_frame
	_expect((_screen().find_child("CalendarDate", true, false) as Label).text == "18.10.08", "the square shows Monday 18.10.08")


func _week_over_flow() -> void:
	GameState.calendar = {"week": 1, "phase": "work", "hours": 40}
	await _open_office()
	var panel := _screen().get_node("WeekOverPanel") as Overlay
	_expect(panel.visible, "a full work week offers the weekend or home")
	var weekend := _find_button(panel, "Work the Weekend")
	_expect(weekend != null and _find_button(panel, "Pay Party Dues and Go Home") != null, "both choices are there")
	if weekend != null:
		weekend.pressed.emit()
	await get_tree().process_frame
	_expect(GameState.in_weekend(), "choosing the weekend starts it")
	_save_shot("week_weekend2")


## Too little Funds at the week end: the popup says so and the balance rolls over.
func _short_on_funds_flow() -> void:
	GameState.calendar = {"week": 2, "phase": "weekend", "hours": 4}
	GameState.meta["Funds"] = 20000
	GameState.meta["Party support"] = 40
	GameState.dues_balance = 0
	GameState.week_funds_earned = 0
	await _open_office()
	var label := _screen().find_child("DuesLabel", true, false) as Label
	_expect(label != null and label.visible and label.text.contains("50,000"), "the dues line shows what is owed")
	var button := _screen().find_child("WeekButton", true, false) as Button
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var popup := _screen().get_node("NewWeekPanel") as Overlay
	var text := _label_text(popup)
	_expect(text.contains("30,000円 rolls over"), "the popup says what rolls over, got: %s" % text)
	_expect(text.contains("furious"), "and that the party is displeased")
	_expect(GameState.dues_balance == 30000, "the balance is carried")
	_save_shot("week_overdue")


func _find_button(root: Node, text: String) -> Button:
	if root is Button and (root as Button).text == text and (root as Button).visible:
		return root as Button
	for child in root.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


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
