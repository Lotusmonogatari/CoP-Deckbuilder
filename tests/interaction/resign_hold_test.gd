extends Node
## Hold to resign, with real mouse input on the real Office (2026-11-19, Cameron): a tap does nothing; a
## hold that is let go early darkens the screen from the edges and then lightens it again, resigning nothing;
## holding the full five seconds resigns.
##
##     xvfb-run .tools/godot --path . tests/interaction/resign_hold_test.tscn

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _run() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	# Low enough on all three for the Resign button to appear.
	GameState.meta["Reputation"] = 5
	GameState.meta["Party support"] = 10
	GameState.meta["Constituency support"] = 10
	get_tree().change_scene_to_file(OFFICE)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var office := get_tree().current_scene
	office.call("_show_reputation_menu")
	await get_tree().create_timer(0.6).timeout
	var button := office.find_child("ResignButton", true, false) as Button
	_expect(button != null and button.is_visible_in_tree(), "the Resign button is in the menu")
	if button == null:
		return _finish()
	_expect(button.text.contains("hold"), "the button says to hold (%s)" % button.text)
	var hold := button.get_node("ResignHold") as ResignHold
	var veil_layer := hold.get_node("ResignVeil") as CanvasLayer
	var veil := veil_layer.get_child(0) as ColorRect
	_expect(veil_layer.layer > 100 and veil.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the veil is above every panel and never takes a touch")
	var at := button.get_global_rect().get_center()
	var corner_before := await _corner_brightness()

	# 1. A tap: nothing happens.
	await _press(at)
	await get_tree().create_timer(0.15).timeout
	await _release(at)
	await get_tree().create_timer(0.6).timeout
	_expect(get_tree().current_scene == office and not GameState.awaiting_new_game, "a tap does not resign")
	_expect(not veil.visible, "and the screen is not left dark")

	# 2. Held for half the time, then let go: dark at the edges, then light again, nothing resigned.
	await _press(at)
	await get_tree().create_timer(2.5).timeout
	_expect(absf(hold.progress() - 0.5) < 0.15, "half way through the hold it is about 50%% (%.2f)" % hold.progress())
	_expect(veil.visible, "the veil shows during the hold")
	var corner_during := await _corner_brightness()
	_expect(corner_during < corner_before * 0.5, "the corners have gone dark by half way (%.3f of %.3f)" % [corner_during, corner_before])
	var middle_during := await _middle_brightness()
	await _release(at)
	await get_tree().create_timer(0.8).timeout
	_expect(not veil.visible and not hold.is_holding(), "letting go lightens the screen again")
	_expect(get_tree().current_scene == office and not GameState.awaiting_new_game, "and resigns nothing")
	_expect(middle_during > 0.0, "the middle of the screen was still showing at half way")

	# 3. Held the whole time: resigns, and not a moment before.
	await _press(at)
	await get_tree().create_timer(4.4).timeout
	_expect(get_tree().current_scene == office and not GameState.awaiting_new_game, "4.4 seconds in, nothing has happened yet")
	await get_tree().create_timer(1.6).timeout
	_expect(GameState.awaiting_new_game, "held for the full time, the run is over")
	await get_tree().process_frame
	_expect(get_tree().current_scene != office and str(get_tree().current_scene.scene_file_path).ends_with("ResignScreen.tscn"), "and the Resign screen is showing")
	await _release(at)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("RESIGN HOLD TEST: PASS")
		get_tree().quit(0)
	else:
		print("RESIGN HOLD TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


## The brightest channel of a pixel in the screen's top-left corner, for "has the edge gone dark".
func _corner_brightness() -> float:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var colour := image.get_pixel(1, 1)
	return maxf(colour.r, maxf(colour.g, colour.b))


func _middle_brightness() -> float:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var colour := image.get_pixel(image.get_width() / 2, image.get_height() / 2)
	return maxf(colour.r, maxf(colour.g, colour.b))


func _event(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = get_viewport().get_screen_transform() * at
	e.global_position = e.position
	return e


func _press(at: Vector2) -> void:
	Input.parse_input_event(_event(true, at))
	await get_tree().process_frame


func _release(at: Vector2) -> void:
	Input.parse_input_event(_event(false, at))
	await get_tree().process_frame


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)
