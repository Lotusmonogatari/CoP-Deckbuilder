class_name VenueDriver
extends Node
## Real clicks through the Capitol venues (P16, 2026-11-23): Capitol Office -> Step out -> Cafeteria -> Eat with Colleagues (one hour
## taken) -> Keep listening to the eighth line -> the dry line, greyed "Come back tomorrow". A forced rhetoric tip (a test seed puts it
## third in the day's set) then shows on the Levels list's Tips count, in the Tips you hold pop-up and on the briefing's room.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
	GameState.dated_events_done = ["EV47"]
	GameState.held_tips = []
	# A level on offer here with a room that has a Favored Suit: the tip's target.
	var picked := {}
	for level: Dictionary in GameState.levels_on_offer():
		# A level with at least two rooms lists them in its briefing's timeline, where the tip mark shows.
		var revealed: Array[String] = []
		for expanded_stage: Dictionary in BattleSetup.expand_level(level).get("stages", []):
			if LevelBriefing.is_revealed(expanded_stage):
				revealed.append(str(expanded_stage.get("stage_id", "")))
		if revealed.size() < 2:
			continue
		for slot in range(1, 11):
			var raw: Variant = level.get("stage_%d" % slot)
			var stage := DataDB.get_stage("" if raw == null else str(raw))
			if not stage.is_empty() and stage.get("favored_suit") != null and str(stage["favored_suit"]) != "—" \
					and str(stage.get("mode", "")) == "Combat" and picked.is_empty() and revealed.has(str(stage.get("stage_id", ""))):
				picked = {"level": level, "stage": stage}
	_expect(not picked.is_empty(), "a level on offer has a room with a Favored Suit")
	if picked.is_empty():
		_finish()
		return
	var stage_id := str((picked["stage"] as Dictionary)["stage_id"])
	var suit := str((picked["stage"] as Dictionary)["favored_suit"])
	var entry := GameState.venue_day("VN01")
	var dealt: Array = entry["dealt"]
	dealt[2] = {"line_id": "VL081", "hint": {"kind": "stage_suit", "target": stage_id, "suit": suit,
		"text_key": "hint.stage_suit.%s_1" % VenueLines.suit_key_of(suit)}}
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	await _open_office()
	var office := get_tree().current_scene
	_expect(office.find_child("StepOutButton", true, false) != null and (office.find_child("StepOutButton", true, false) as Button).visible,
		"Step out shows at the Capitol")
	var hours := GameState.work_hours_left()
	await _click(office.find_child("StepOutButton", true, false))
	var map := office.get_node("VenueMapPanel") as Overlay
	_expect(map.visible, "Step out opens the place map")
	_expect((map.find_child("Venue_VN02", true, false) as Button).disabled, "the Library is greyed: Coming soon")
	_expect(not (map.find_child("Venue_VN01", true, false) as Button).disabled, "the Cafeteria is open")
	await _click(map.find_child("Venue_VN01", true, false))
	var venue := office.get_node("VenuePanel") as Overlay
	_expect(venue.visible, "the Cafeteria's screen opens")
	await _click(venue.find_child("Activity_VN01", true, false))
	_expect(GameState.work_hours_left() == hours - 1, "Eat with Colleagues takes one hour")
	var line := office.get_node("VenueLinePanel") as Overlay
	_expect(line.visible and _texts(line).contains("Line 1 of 8 today"), "the first line is up")
	for number in range(2, 9):
		await _click(line.find_child("Confirm", true, false))
		_expect(_texts(line).contains("Line %d of 8 today" % number), "Keep listening shows line %d" % number)
		if number == 3:
			_expect(line.find_child("TipBox", true, false) != null, "the third line is the tip, in its tip box")
	_expect(GameState.work_hours_left() == hours - 1, "Keep listening cost nothing")
	await _click(line.find_child("Confirm", true, false))
	var confirm := line.find_child("Confirm", true, false) as Button
	_expect(bool(GameState.venue_days["VN01"]["dry"]), "the ninth is the dry line")
	_expect(confirm != null and confirm.disabled and confirm.text == Text.say("venue.come_back"), "Keep listening is greyed: Come back tomorrow")
	# Out, and to the Levels list.
	await _click(line.find_child("Back", true, false))
	await _click((office.get_node("VenuePanel") as Overlay).find_child("Back", true, false))
	await _click((office.get_node("VenueMapPanel") as Overlay).find_child("Back", true, false))
	var held := GameState.tips_held().size()
	_expect(held >= 1, "the tip is held (%d: the day's other hints are held too)" % held)
	await _click(office.get_node("%StartButton"))
	var levels := office.get_node("%LevelsPanel") as Overlay
	var tips_button := levels.find_child("TipsButton", true, false) as Button
	_expect(tips_button != null and tips_button.text.contains(str(held)), "the Levels list's Tips button counts %d" % held)
	_expect(levels.find_child("TipBadge", true, false) != null, "the level with the tipped room says so")
	await _click(tips_button)
	var tips := office.get_node("TipsPanel") as Overlay
	_expect(tips.visible and tips.find_child("TipRow_" + stage_id, true, false) != null, "the Tips you hold pop-up lists it")
	await _click(tips.find_child("Back", true, false))
	var level_box := levels.find_child("Level_" + str((picked["level"] as Dictionary)["level_id"]), true, false)
	var look := level_box.find_children("*", "Button", true, false) if level_box != null else []
	_expect(not look.is_empty(), "the tipped level is on the list")
	if not look.is_empty():
		await _click(look[look.size() - 1])
		await get_tree().create_timer(0.5).timeout
		var briefing := office.get_node("%BriefingPanel") as Overlay
		_expect(briefing.visible and briefing.find_child("TipMark_" + stage_id, true, false) != null, "the briefing marks the tipped room")
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
		print("VENUE TEST: PASS")
		get_tree().quit(0)
	else:
		print("VENUE TEST: FAIL")
		for failure: String in _failures:
			print("  X " + failure)
		get_tree().quit(1)
