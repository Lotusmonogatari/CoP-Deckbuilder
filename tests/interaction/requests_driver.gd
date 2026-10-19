class_name RequestsDriver
extends Node
## Patron requests, with real clicks (2026-10-19): an organization whose
## standing is high enough asks the player to carry a bill, but only once its
## countdown has run; the Request panel shows the bill, the vote and the
## answers; Amend swaps a part; Decline costs standing and removes the request;
## Accept starts the level at the Level Intro.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	GameState.start_new_run("PC02")
	GameState.booster_standing["BO05"] = 55
	GameState.time_units = 0

	# 1. Due but the countdown has not run: no Requests block.
	await _open_office()
	await _open_levels()
	var panel := get_tree().current_scene.find_child("LevelsPanel", true, false) as Overlay
	if _has_text(panel, Text.say("office.requests_heading")):
		_failures.append("a request showed before its countdown had run")

	# 2. After the countdown: the heading and the request button appear.
	GameState.time_units += int(DataDB.balance.get("special_level_delay", 5)) + 1
	await _open_office()
	await _open_levels()
	panel = get_tree().current_scene.find_child("LevelsPanel", true, false) as Overlay
	if not _has_text(panel, Text.say("office.requests_heading")):
		_failures.append("a due request did not get its heading")
	var button := get_tree().current_scene.find_child("Request_PB051", true, false) as Button
	if button == null:
		_failures.append("the Chamber of Commerce Favor request was not listed")
		return _finish()
	print("  a due request is listed under Requests")

	# 3. The panel shows the bill and the three answers.
	await _click(button)
	var request := get_tree().current_scene.find_child("RequestPanel", true, false) as Overlay
	if request == null or not request.visible:
		_failures.append("the Request panel did not open")
		return _finish()
	if not _has_prefix(request, "As things stand the vote runs"):
		_failures.append("the Request panel did not show the default vote")
	var amend := _first_named(request, "RequestAmend_")
	var accept := get_tree().current_scene.find_child("RequestAcceptButton", true, false) as Button
	var decline := get_tree().current_scene.find_child("RequestDeclineButton", true, false) as Button
	if accept == null or decline == null or amend == null:
		_failures.append("the Request panel is missing Accept, Amend or Decline")
		return _finish()
	print("  the Request panel shows the vote and its answers")

	# 4. Amend previews a swap with a way back.
	await _click(amend)
	if get_tree().current_scene.find_child("RequestAmendUndoButton", true, false) == null:
		_failures.append("amending did not offer a way back")
	else:
		print("  Amend previews the swap")

	# 5. Decline costs standing and removes the request.
	var before := int(GameState.booster_standing.get("BO05", 0))
	decline = get_tree().current_scene.find_child("RequestDeclineButton", true, false) as Button
	await _click(decline)
	var cost := int(DataDB.balance.get("patron_favor_decline_cost", 5))
	if int(GameState.booster_standing.get("BO05", 0)) != before - cost:
		_failures.append("declining did not cost %d standing" % cost)
	if GameState.patron_requests_shown().has("PB051"):
		_failures.append("a declined request was still shown")
	else:
		print("  Decline costs standing and removes the request")

	# 6. Accept (a different organization's request) starts the level.
	GameState.booster_standing["BO07"] = 55
	GameState.arm_patron_requests()
	GameState.time_units += 20
	await _open_office()
	await _open_levels()
	var second := get_tree().current_scene.find_child("Request_PB071", true, false) as Button
	await _click(second)
	accept = get_tree().current_scene.find_child("RequestAcceptButton", true, false) as Button
	await _click(accept)
	await get_tree().create_timer(0.6).timeout
	if not GameState.is_in_level() or str(GameState.patron_runtime.get("patron_bill_id", "")) != "PB071":
		_failures.append("Accept did not start the patron level")
	elif get_tree().current_scene.scene_file_path != StageRouting.LEVEL_INTRO_SCENE:
		_failures.append("Accept did not open the Level Intro")
	else:
		print("  Accept starts the level at the Level Intro")

	GameState.abandon_level()
	_finish()


func _finish() -> void:
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("REQUESTS TEST: PASS")
		get_tree().quit(0)
	else:
		print("REQUESTS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _open_office() -> void:
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _open_levels() -> void:
	var start := get_tree().current_scene.find_child("StartButton", true, false) as Button
	await _click(start)
	await get_tree().create_timer(0.3).timeout


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child in node.find_children("*", "", true, false):
		if child is Label:
			found.append((child as Label).text)
		elif child is Button:
			found.append((child as Button).text)
	return found


func _has_text(node: Node, text: String) -> bool:
	return not text.is_empty() and _texts(node).has(text)


func _has_prefix(node: Node, prefix: String) -> bool:
	for text: String in _texts(node):
		if text.begins_with(prefix):
			return true
	return false


func _first_named(node: Node, prefix: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if String(child.name).begins_with(prefix):
			return child as Button
	return null


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
