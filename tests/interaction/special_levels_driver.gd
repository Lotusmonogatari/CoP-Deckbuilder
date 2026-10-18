class_name SpecialLevelsDriver
extends Node
## Special Levels, with real clicks (2026-10-18): a special level that has come
## due sits under a "Special Levels" heading at the top of the level list and
## nowhere else; one that is not due yet shows nothing; and one forced in after
## an ordinary level opens a panel whose button starts it.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	GameState.start_new_run("PC02")

	# 1. Armed but not yet due: the level list shows no Special Levels block.
	GameState.special_levels = {"Town Hall": {"armed_at": GameState.time_units}}
	await _open_office()
	await _open_levels()
	var office := get_tree().current_scene
	var panel := office.find_child("LevelsPanel", true, false) as Overlay
	if _has_text(panel, Text.say("office.special_levels_heading")):
		_failures.append("a special level showed before its countdown had run")
	var description := str(SpecialLevels.level_for("Town Hall", DataDB.levels).get("description", ""))
	if _has_text(panel, description):
		_failures.append("the Town Hall level was listed among the ordinary levels")

	# 2. Due: the heading and the level appear, above the first tier heading.
	GameState.time_units = 50
	await _open_office()
	await _open_levels()
	office = get_tree().current_scene
	panel = office.find_child("LevelsPanel", true, false) as Overlay
	if not _has_text(panel, Text.say("office.special_levels_heading")):
		_failures.append("a due special level did not get its heading")
	if not _has_text(panel, description):
		_failures.append("a due special level was not listed")
	else:
		print("  a due special level is listed under Special Levels")
	var order := _texts(panel)
	var special_at := order.find(Text.say("office.special_levels_heading"))
	var tier_at := order.find(Text.say("office.tier_heading", {"tier": 0}))
	if special_at < 0 or (tier_at >= 0 and special_at > tier_at):
		_failures.append("Special Levels is not above the tier lists")

	# 3. Forced in after an ordinary level: a panel with one button starts it.
	GameState.special_forced = true
	await _open_office()
	office = get_tree().current_scene
	var forced := office.find_child("SpecialForcedPanel", true, false) as Overlay
	var go := office.find_child("SpecialForcedGoButton", true, false) as Button
	if forced == null or not forced.visible or go == null:
		_failures.append("the forced special level did not open its panel")
	else:
		print("  a forced special level opens its panel")
		await _click(go)
		await get_tree().create_timer(0.4).timeout
		if not GameState.is_in_level() or str(GameState.level_runner.level.get("level_id", "")) != "LV83":
			_failures.append("the button did not start the Town Hall special level")
		else:
			print("  its button starts the level")

	GameState.abandon_level()
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("SPECIAL LEVELS TEST: PASS")
		get_tree().quit(0)
	else:
		print("SPECIAL LEVELS TEST: FAIL")
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
