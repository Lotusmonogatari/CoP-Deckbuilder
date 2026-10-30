class_name ImagePanDriver
extends Node
## Real drags on pictures (2026-10-30): dragging bare Office background moves
## it; with Image Scroll on, dragging an event picture moves it and leaves the
## panel's own scrolling (and the Office behind) alone; with it off (switched
## from Administration), the same drag moves nothing. Image Pan
## is switched off and on from Administration too. The player's own settings
## are put back at the end.

## A random event whose picture is drawn and square, so there is picture
## above and below to drag into view.
const EVENT := "EV27"

var _failures: PackedStringArray = []
var _scroll_before := true
var _pan_before := true


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_scroll_before = Layout.image_scroll_enabled
	_pan_before = Layout.image_pan_enabled
	Layout.image_scroll_enabled = true
	Layout.image_pan_enabled = true
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var office := get_tree().current_scene

	var background := office.get_node("%Background") as PlaceholderArt
	var bare := _bare_point(background)
	_expect(bare != Vector2.INF, "the Office has some bare background to press on")
	if bare != Vector2.INF:
		await _drag_at(bare, Vector2(-160, 0))
		_expect(background.offset().x < -40.0 or background.offset().x > 40.0,
			"dragging bare Office background moves it (offset %s)" % background.offset())
	var office_offset := background.offset()

	var picture := await _open_event(office)
	if picture == null:
		return _finish()
	var scroll := _panel_scroll(office)
	var scroll_at := scroll.scroll_vertical if scroll != null else 0
	await _drag(picture, Vector2(0, 160))
	_expect(picture.offset().y > 40.0, "dragging down shows more of the picture (offset %s)" % picture.offset())
	if scroll != null:
		_expect(scroll.scroll_vertical == scroll_at, "the panel did not scroll under the drag")
	_expect(background.offset() == office_offset, "the Office behind the panel did not move")
	_close_event(office)

	await _click(office.find_child("AdministrationButton", true, false))
	var scroll_button := office.find_child("ImageScrollButton", true, false) as Button
	var pan_button := office.find_child("ImagePanButton", true, false) as Button
	_expect(scroll_button != null and pan_button != null, "Administration shows both switches")
	if scroll_button == null or pan_button == null:
		return _finish()
	_expect(scroll_button.text == Text.say("office.image_scroll", {"state": Text.say("settings.on")}),
		"Image Scroll reads On")
	await _click(scroll_button)
	_expect(not Layout.image_scroll_enabled, "tapping Image Scroll turns it off")
	pan_button = office.find_child("ImagePanButton", true, false) as Button
	await _click(pan_button)
	_expect(not Layout.image_pan_enabled, "tapping Image Pan turns it off")
	pan_button = office.find_child("ImagePanButton", true, false) as Button
	_expect(pan_button.text == Text.say("office.image_pan", {"state": Text.say("settings.off")}),
		"Image Pan reads Off")
	(office.get_node("AdministrationMenuPanel") as Overlay).close()

	picture = await _open_event(office)
	if picture != null:
		await _drag(picture, Vector2(0, 160))
		_expect(picture.offset().is_zero_approx(), "with Image Scroll off the picture stays put")
	_finish()


func _open_event(office: Node) -> PlaceholderArt:
	office._present_event(EVENT, true)
	await get_tree().create_timer(0.4).timeout
	var found := office.get_node("EventPanel").find_child("Picture_*", true, false)
	if not (found is PlaceholderArt) or (found as PlaceholderArt).is_placeholder():
		_failures.append("%s's picture is not a drawn picture (%s)" % [EVENT, found])
		return null
	return found as PlaceholderArt


func _close_event(office: Node) -> void:
	(office.get_node("EventPanel") as Overlay).close()


func _panel_scroll(office: Node) -> ScrollContainer:
	var found := office.get_node("EventPanel").find_children("*", "ScrollContainer", true, false)
	return null if found.is_empty() else found[0] as ScrollContainer


## A point on `art` with nothing in front of it that takes the mouse.
func _bare_point(art: PlaceholderArt) -> Vector2:
	var rect := art.get_global_rect()
	for y in range(int(rect.position.y) + 40, int(rect.end.y) - 40, 60):
		for x in range(int(rect.position.x) + 200, int(rect.end.x) - 200, 60):
			if not art._covered_at(Vector2(x, y)):
				return Vector2(x, y)
	return Vector2.INF


func _drag(control: Control, by: Vector2) -> void:
	await get_tree().process_frame
	await _drag_at(control.get_global_rect().get_center(), by)


func _drag_at(point: Vector2, by: Vector2) -> void:
	var start: Vector2 = get_viewport().get_screen_transform() * point
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	press.global_position = start
	Input.parse_input_event(press)
	await get_tree().process_frame
	var steps := 8
	for i in steps:
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		move.relative = by / steps
		move.position = start + by * float(i + 1) / steps
		move.global_position = move.position
		Input.parse_input_event(move)
		await get_tree().process_frame
	var lift := press.duplicate() as InputEventMouseButton
	lift.pressed = false
	lift.position = start + by
	lift.global_position = lift.position
	Input.parse_input_event(lift)
	await get_tree().create_timer(0.2).timeout


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
	await get_tree().create_timer(0.2).timeout


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)


func _finish() -> void:
	Layout.image_scroll_enabled = _scroll_before
	Layout.image_pan_enabled = _pan_before
	Layout._save_settings()
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("IMAGE PAN TEST: PASS")
		get_tree().quit(0)
	else:
		print("IMAGE PAN TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
