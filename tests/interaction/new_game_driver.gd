class_name NewGameDriver
extends Node
## Choosing who to play, with real clicks.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/new_game_test.tscn
##
##   First launch (no save) → the Office opens on the New Game screen
##   Tap "Play as" for PC03 → the run is PC03's, the Office says their name
##   Office Management → New game → Start over → the picker again
##   Tap "Play as" for PC02 → a fresh run as PC02
##
## SaveManager is off in test runs, so this never touches a real save.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.awaiting_new_game = true
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().create_timer(0.8).timeout
	await _walk()

	print("")
	if _failures.is_empty():
		print("NEW GAME TEST: PASS")
		get_tree().quit(0)
	else:
		print("NEW GAME TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var office := get_tree().current_scene
	var panel := office.get_node("NewGamePanel") as Overlay
	if not panel.visible:
		_failures.append("the first launch did not open the New Game screen")
		return
	print("  the first launch opens the New Game screen")

	if not await _choose(panel, "PC03"):
		return
	var name := str(DataDB.get_protagonist("PC03").get("name_en"))
	if GameState.protagonist_id != "PC03" or not (office.get_node("%Title") as Label).text.contains(name):
		_failures.append("choosing PC03 did not make the run and the Office theirs")
		return
	print("  choosing a protagonist starts the run as them")

	GameState.xp = 77
	await _click(office.get_node("%ManagementButton"))
	var management := office.get_node("%ManagementPanel") as Overlay
	var new_game := _button_with_text(management, Text.say("office.new_game"))
	if new_game == null:
		_failures.append("Office Management has no New game button")
		return
	await _click(new_game)
	var confirm := panel.find_child("Confirm", true, false) as Button
	if not panel.visible or confirm == null or not confirm.visible:
		_failures.append("New game did not ask before starting over")
		return
	if GameState.xp != 77:
		_failures.append("New game threw the run away before it was confirmed")
		return
	await _click(confirm)
	await get_tree().create_timer(0.3).timeout
	if not await _choose(panel, "PC02"):
		return
	if GameState.protagonist_id != "PC02" or GameState.xp != 0:
		_failures.append("starting over did not begin a fresh run as PC02")
		return
	print("  New game asks first, then starts a fresh run")


func _choose(panel: Overlay, player_id: String) -> bool:
	await get_tree().create_timer(0.2).timeout
	var row := panel.find_child("Protagonist_" + player_id, true, false)
	if row == null:
		_failures.append("the New Game screen does not list %s" % player_id)
		return false
	await _click(row.find_child("Choose", true, false) as Control)
	if panel.visible:
		_failures.append("choosing %s did not close the New Game screen" % player_id)
		return false
	return true


func _button_with_text(root: Node, text: String) -> Control:
	for node in root.find_children("", "Button", true, false):
		if (node as Button).text == text:
			return node as Control
	return null


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	var parent := control.get_parent()
	while parent != null and not (parent is ScrollContainer):
		parent = parent.get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).ensure_control_visible(control)
		await get_tree().process_frame
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
