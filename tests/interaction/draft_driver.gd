class_name DraftDriver
extends Node
## Draft a Bill, with real clicks (2026-10-19): open it from the Levels list,
## pick a part from each of two organizations, see the bill and its preview,
## draft it (the cost is paid) and land on the Level Intro.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	GameState.start_new_run("PC02")
	GameState.xp = 1000
	GameState.meta["Funds"] = 400000
	GameState.booster_standing["BO05"] = 99
	GameState.booster_standing["BO07"] = 98
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	await _click(get_tree().current_scene.find_child("StartButton", true, false) as Button)
	await get_tree().create_timer(0.3).timeout

	await _click(get_tree().current_scene.find_child("DraftBillButton", true, false) as Button)
	var panel := get_tree().current_scene.find_child("DraftPanel", true, false) as Overlay
	if panel == null or not panel.visible:
		_failures.append("the Draft a Bill panel did not open")
		return _finish()
	var go := get_tree().current_scene.find_child("DraftGoButton", true, false) as Button
	if go == null or not go.disabled:
		_failures.append("Draft this bill should be greyed out with nothing chosen")

	# One part from the Chamber of Commerce, one from the Fisheries Cooperative.
	await _click(get_tree().current_scene.find_child("DraftOrg_BO05", true, false) as Button)
	await _click(get_tree().current_scene.find_child("DraftPart_CB051", true, false) as Button)
	await _click(get_tree().current_scene.find_child("DraftOrgsBack", true, false) as Button)
	await _click(get_tree().current_scene.find_child("DraftOrg_BO07", true, false) as Button)
	await _click(get_tree().current_scene.find_child("DraftPart_CB071", true, false) as Button)
	await _click(get_tree().current_scene.find_child("DraftOrgsBack", true, false) as Button)
	if not _has_prefix(panel, "As things stand the vote runs"):
		_failures.append("the panel did not preview the vote")
	go = get_tree().current_scene.find_child("DraftGoButton", true, false) as Button
	if go == null or go.disabled:
		_failures.append("Draft this bill should be ready with a winnable pair chosen")
		return _finish()
	print("  two parts from two organizations make a bill with a preview")

	var xp_before := GameState.xp
	await _click(go)
	await get_tree().create_timer(0.6).timeout
	if not GameState.is_in_level() or not str(GameState.patron_runtime.get("patron_bill_id", "")).begins_with("PD"):
		_failures.append("Draft this bill did not start the level")
	elif GameState.xp != xp_before - 350:
		_failures.append("drafting did not cost 350 XP")
	elif get_tree().current_scene.scene_file_path != StageRouting.LEVEL_INTRO_SCENE:
		_failures.append("drafting did not open the Level Intro")
	else:
		print("  Draft this bill pays the cost and starts the level at the Level Intro")
	GameState.abandon_level()
	_finish()


func _finish() -> void:
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("DRAFT TEST: PASS")
		get_tree().quit(0)
	else:
		print("DRAFT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _has_prefix(node: Node, prefix: String) -> bool:
	for child in node.find_children("*", "", true, false):
		var text := ""
		if child is Label:
			text = (child as Label).text
		elif child is Button:
			text = (child as Button).text
		if text.begins_with(prefix):
			return true
	return false


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
