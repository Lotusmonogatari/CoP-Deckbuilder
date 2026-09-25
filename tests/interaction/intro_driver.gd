class_name IntroDriver
extends Node
## Walks the Intro (title) screen with real clicks: no save on disk
## (Continue disabled, New Game opens the picker directly), and a save on
## disk (Continue loads it into the Office, New Game warns first).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/intro_test.tscn
##
## SaveManager never auto-loads or autosaves in a test run (enabled is
## false), so this writes and deletes its own save file directly
## (SaveManager.save_game()/delete_save()) rather than depending on a real
## player's — the same isolation every interaction test already gets from
## that same flag, just used on purpose here instead of relied on.

const INTRO_SCENE := "res://scenes/menus/IntroScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()

	await _walk_with_no_save()
	await _walk_with_a_save()

	SaveManager.delete_save()

	print("")
	if _failures.is_empty():
		print("INTRO TEST: PASS")
		get_tree().quit(0)
	else:
		print("INTRO TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk_with_no_save() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var intro := get_tree().current_scene
	if intro == null or intro.name != "IntroScreen":
		_failures.append("the game did not start on the Intro screen")
		return
	print("  started on the Intro screen")

	var continue_button := intro.get_node("%ContinueButton") as Button
	if not continue_button.disabled:
		_failures.append("Continue was enabled with no save on disk")
		return
	print("  Continue is disabled with no save on disk")

	await _click(intro.get_node("%NewGameButton") as Control)
	await get_tree().create_timer(0.4).timeout

	if get_tree().current_scene.name != "OfficeScreen":
		_failures.append("New Game (no save) did not open the Office")
		return
	var office := get_tree().current_scene
	var panel := office.get_node("NewGamePanel") as Overlay
	if not panel.visible:
		_failures.append("New Game (no save) did not open the protagonist picker")
		return
	print("  New Game (no save) opened the picker directly, with no warning")

	var row := panel.find_child("Protagonist_PC03", true, false)
	if row == null:
		_failures.append("the picker does not list PC03")
		return
	await _click(row.find_child("Choose", true, false) as Control)
	await get_tree().create_timer(0.2).timeout

	if GameState.protagonist_id != "PC03":
		_failures.append("choosing PC03 did not start the run as them")
		return
	print("  chose a protagonist and started the run")

	# A real save on disk for the second half of this walk. SaveManager
	# itself never autosaves in a test run, so this writes it directly.
	SaveManager.save_game()


func _walk_with_a_save() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var intro := get_tree().current_scene
	var continue_button := intro.get_node("%ContinueButton") as Button
	if continue_button.disabled:
		_failures.append("Continue was disabled with a save on disk")
		return
	print("  Continue is enabled with a save on disk")

	# Whoever is "in play" right now becomes someone else, so reading PC03
	# back is only possible if Continue actually loads the file — not just
	# whatever GameState already happens to hold from a moment ago.
	GameState.start_new_run("PC01")

	await _click(intro.get_node("%NewGameButton") as Control)
	await get_tree().create_timer(0.3).timeout
	var warning := intro.get_node("OverwriteWarning") as Overlay
	if warning == null or not warning.visible:
		_failures.append("New Game with a save on disk did not warn first")
		return
	print("  New Game with a save on disk warns before starting over")

	await _click(warning.find_child("Back", true, false) as Control)
	await get_tree().create_timer(0.2).timeout
	if get_tree().current_scene.name != "IntroScreen":
		_failures.append("backing out of the warning left the Intro screen")
		return
	print("  backing out of the warning leaves the save untouched")

	await _click(intro.get_node("%ContinueButton") as Control)
	await get_tree().create_timer(0.4).timeout

	if get_tree().current_scene.name != "OfficeScreen":
		_failures.append("Continue did not open the Office")
		return
	if GameState.protagonist_id != "PC03":
		_failures.append("Continue did not load the saved run (got %s, wanted PC03)"
			% GameState.protagonist_id)
		return
	print("  Continue loaded the save and opened the Office as PC03")


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
