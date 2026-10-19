class_name VisitDriver
extends Node
## Walks a real member visit with real clicks (influence building step B,
## 2026-10-19): a Flagship patron level from the Request on, the offer, the
## researcher's briefing, three questions, the rapport that opens the fight,
## and the fight screen it hands over to. Then a second visit, skipped.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("VISIT TEST: PASS")
		get_tree().quit(0)
	else:
		print("VISIT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _start_flagship() -> bool:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.booster_standing["BO05"] = 75
	GameState.patron_requests["PB051"] = {"status": PatronRequests.PASSED, "components": ["CB051", "CB052"], "amended": false, "tries": 0}
	if not GameState.start_patron_level("PB052"):
		_fail("the Flagship level would not start")
		return false
	while str(GameState.level_runner.current_stage().get("stage_id", "")) != MpVisit.VISIT_STAGE:
		GameState.finish_stage(LevelRunner.WON)
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	return true


func _run() -> void:
	# A rank 2 researcher is hired, so the briefing plays.
	if not await _start_flagship():
		_finish()
		return
	GameState.staff_hired["Policy Research Assistant"] = {"staff_id": "SF02", "tier": 2}
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var screen := get_tree().current_scene
	if screen == null or screen.name != "VisitScreen":
		_fail("the visit stage did not open the visit screen (opened %s)" % (screen.name if screen else "nothing"))
		_finish()
		return
	print("  opened the visit screen")

	var visit := GameState.current_visit()
	var question: Label = screen.get_node("%QuestionLabel")
	if not str(question.text).contains(str(visit["member_name"])):
		_fail("the offer does not name the member: '%s'" % question.text)
	var banner: Node = screen.get_node("CueBanner")
	if banner == null:
		_fail("no cue banner for the researcher's briefing")
	print("  offer: %s" % str(question.text).left(70))

	if screen.briefing_text().is_empty():
		_fail("a rank 2 researcher should brief the player")
	else:
		print("  briefing: %s" % screen.briefing_text().left(80))

	# The researcher's line sits across the middle until it is tapped away
	# (the cue banner's own rule), so clear it before the first real click.
	banner.clear()
	await get_tree().process_frame

	# Take the visit, answer three questions.
	if not await _click(screen.get_node("%ChoiceA")):
		_finish()
		return
	for number in range(3):
		if not str(screen.get_node("%VisitorCaption").text).contains(str(number + 1)):
			_fail("question %d caption reads '%s'" % [number + 1, screen.get_node("%VisitorCaption").text])
		var shown := 0
		for letter in ["A", "B", "C", "D"]:
			if screen.get_node("%Choice" + letter).visible:
				shown += 1
		if shown != 4:
			_fail("question %d shows %d choices, not 4" % [number + 1, shown])
		if not await _click(screen.get_node("%ChoiceA")):
			_finish()
			return
		banner.clear()
		await get_tree().process_frame
		if screen.get_node("%ContinueButton").disabled:
			_fail("Continue stayed locked after answering")
		if not await _click(screen.get_node("%ContinueButton")):
			_finish()
			return
	var rapport := int(visit.get("rapport", 99))
	if rapport < -3 or rapport > 3:
		_fail("rapport %d is outside -3 to 3" % rapport)
	print("  rapport after three answers: %+d" % rapport)

	var outcome_panel: PanelContainer = screen.get_node("%OutcomePanel")
	if not outcome_panel.visible:
		_fail("the visit's summary did not open")
		_finish()
		return
	print("  summary: %s" % str(screen.get_node("%OutcomeBody").text).left(80))
	if not await _click(screen.get_node("%OutcomeClose")):
		_finish()
		return
	await get_tree().create_timer(0.5).timeout

	var next := get_tree().current_scene
	if next == null or next.name != "BattleScreen":
		_fail("after the visit the fight did not open (opened %s)" % (next.name if next else "nothing"))
		_finish()
		return
	var fight_stage := GameState.level_runner.current_stage()
	if str(fight_stage.get("stage_id", "")) != MpVisit.FIGHT_STAGE:
		_fail("the stage after the visit is %s, not the fight" % fight_stage.get("stage_id"))
	elif str((fight_stage["opponents"] as Array)[0]["opp_id"]) != str(visit["opp_id"]):
		_fail("the fight is not against the visiting member")
	else:
		print("  the fight against %s opened" % str(visit["member_name"]))

	# A second level, this time skipped and without a researcher.
	GameState.staff_hired.erase("Policy Research Assistant")
	GameState.abandon_level()
	if not await _start_flagship():
		_finish()
		return
	screen = get_tree().current_scene
	if not screen.briefing_text().is_empty():
		_fail("no researcher is hired, yet there was a briefing")
	else:
		print("  no researcher, no briefing")
	if not await _click(screen.get_node("%ChoiceB")):
		_finish()
		return
	await get_tree().create_timer(0.5).timeout
	if str(GameState.level_runner.current_stage().get("stage_id", "")) == MpVisit.VISIT_STAGE \
			or str(GameState.level_runner.current_stage().get("stage_id", "")) == MpVisit.FIGHT_STAGE:
		_fail("skipping left the player on %s" % GameState.level_runner.current_stage().get("stage_id"))
	elif not BillAssist.is_empty(GameState.bill_assist):
		_fail("a skipped visit earned seats")
	else:
		print("  skipped: moved straight on to %s" % GameState.level_runner.current_stage().get("stage_id"))
	_finish()


func _click(control: Control) -> bool:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_fail("%s has no size, so nothing could click it" % control.name)
		return false
	var where: Vector2 = get_viewport().get_screen_transform() * rect.get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
	return true
