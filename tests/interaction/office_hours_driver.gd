class_name OfficeHoursDriver
extends Node
## Walks a real Office Hours stage with real clicks, then on into whatever
## follows it — LV11 is ST07 (Office Hours) then ST05 (Town Hall) then ST21,
## so this also proves the routing from VisitorScreen back onto BattleScreen
## for the next stage, and that Town Hall's own %QuestionPrompt actually
## shows once there.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/office_hours_test.tscn
##
## Begins the level directly (GameState.begin_level()) rather than clicking
## through the Levels picker first — loop_driver.gd already proves that
## picker works; this proves what opens once you are in.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var expanded := BattleSetup.expand_level(DataDB.get_level("LV11"))
	var runner := LevelRunner.new(expanded)
	if not runner.is_valid():
		_failures.append("LV11 could not start: %s" % ", ".join(Array(runner.problems())))
		_finish()
		return

	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	await _walk()
	_finish()


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("OFFICE HOURS TEST: PASS")
		get_tree().quit(0)
	else:
		print("OFFICE HOURS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var screen := get_tree().current_scene
	if screen == null or screen.name != "VisitorScreen":
		_failures.append("LV11's first stage did not open the Visitor screen")
		return
	print("  ST07 opened the Visitor screen")

	var visited := 0
	while get_tree().current_scene.name == "VisitorScreen" and visited < 6:
		if not await _answer_current_visitor(get_tree().current_scene):
			return
		visited += 1

	if visited == 0:
		_failures.append("no visitor was ever answered")
		return
	print("  answered %d visitor(s)" % visited)

	if get_tree().current_scene.name != "BattleScreen":
		_failures.append("finishing Office Hours did not move on to the next stage")
		return
	print("  moved on to the next stage: %s" % str(get_tree().current_scene.get_node("%StageName").text))

	await get_tree().create_timer(0.3).timeout
	var prompt := get_tree().current_scene.get_node("%QuestionPrompt") as Label
	if prompt == null or not prompt.visible or prompt.text.is_empty():
		_failures.append("Town Hall did not show a current question in %QuestionPrompt")
		return
	print("  Town Hall shows its drawn question: %s" % prompt.text)


## Answers one visitor (always choice A, whatever it costs) and presses
## Continue. Returns false, appending a failure, if anything did not appear
## where it should.
func _answer_current_visitor(screen: Node) -> bool:
	var question: Label = screen.get_node("%QuestionLabel")
	if str(question.text).is_empty():
		_failures.append("a visitor had no question showing")
		return false

	await _click(screen.get_node("%ChoiceA"))
	await get_tree().create_timer(0.2).timeout

	var continue_button: Button = screen.get_node("%ContinueButton")
	if continue_button.disabled:
		_failures.append("answering a visitor did not unlock Continue")
		return false

	await _click(continue_button)
	await get_tree().create_timer(0.3).timeout

	var outcome := screen.get_node("%OutcomePanel") as Control
	if outcome != null and outcome.visible:
		await _click(screen.get_node("%OutcomeClose"))
		await get_tree().create_timer(0.5).timeout
	return true


func _click(control: Control) -> void:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return

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
