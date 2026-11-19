extends Node
## The problem report, with real input (2026-11-19, Cameron): both ways to open it, circling a problem,
## the form, what the saved report holds, the files it writes, the black box and the offer after a crash.
##
##     xvfb-run .tools/godot --path . tests/interaction/report_test.tscn
##
## Fingers are InputEventScreenTouch events and the volume buttons are key events, held for the real
## two seconds. Files go to a scratch folder, never the player's own.

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
const SCRATCH := "user://report_test"

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
	_clear_scratch()
	Reporter.persist = true
	Reporter.root_dir = SCRATCH + "/box"
	Reporter.report_dir = SCRATCH + "/reports"
	Reporter.copy_to_downloads = false
	await _office("woodblock")
	await _check_black_box()
	await _check_gestures_that_must_not_open()
	await _check_touch_report()
	await _check_volume_report()
	await _check_crash_offer()
	await _check_layout_watch()
	_clear_scratch()
	if _failures.is_empty():
		print("REPORT TEST: PASS")
		get_tree().quit(0)
	else:
		print("REPORT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


# --------------------------------------------------------------------------- setup

func _office(style: String) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.calendar = WeekCalendar.fresh()
	GameState.promises.clear()
	GameState.promises.append({"id": "P1", "kind": Promises.PROMISE_ITEM, "item_id": "SH01", "hours": 0,
		"funds": 0, "due_at": 100000, "made_at": 0, "for_org": "", "source": "test"})
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		GameState.owned_cosmetic_packages.append(str(package["package_id"]))
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()
	get_tree().change_scene_to_file(OFFICE)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout


# --------------------------------------------------------------------------- the black box

func _check_black_box() -> void:
	var button := get_tree().current_scene.find_child("EventsButton", true, false) as Button
	await _click(button)
	await get_tree().create_timer(0.3).timeout
	_expect(str(Reporter.log.last_of("press").get("text", "")).begins_with("EventsButton"), "a button press goes into the black box")
	_expect(not Reporter.log.last_of("screen").is_empty(), "the screen showing goes into the black box")
	var panel := get_tree().current_scene.get_node("EventsPanel") as Overlay
	if panel.visible:
		panel.close()
	push_error("report test: a deliberate error")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(Reporter.errors.any(func(item: Dictionary) -> bool: return str(item["text"]).contains("a deliberate error")),
		"an error the engine prints is noticed")
	_expect(not Reporter.log.last_of("error").is_empty(), "and goes into the black box")


# --------------------------------------------------------------------------- gestures

func _check_gestures_that_must_not_open() -> void:
	# Two fingers, however long, are not the gesture.
	_touch(0, true, Vector2(300, 700))
	_touch(1, true, Vector2(500, 700))
	await get_tree().create_timer(2.4).timeout
	_expect(not Reporter.is_open(), "two fingers do not open the report")
	_touch(0, false, Vector2(300, 700))
	_touch(1, false, Vector2(500, 700))
	# Three fingers let go early.
	for index in 3:
		_touch(index, true, Vector2(300 + index * 200, 700))
	await get_tree().create_timer(1.2).timeout
	_expect(_ring().visible, "a ring shows while the three fingers are held")
	for index in 3:
		_touch(index, false, Vector2(300 + index * 200, 700))
	await get_tree().create_timer(1.5).timeout
	_expect(not Reporter.is_open(), "three fingers let go before two seconds do not open the report")
	_expect(not _ring().visible, "and the ring is gone")
	# One volume button.
	_key(KEY_VOLUMEUP, true)
	await get_tree().create_timer(2.4).timeout
	_key(KEY_VOLUMEUP, false)
	_expect(not Reporter.is_open(), "one volume button does not open the report")


func _check_touch_report() -> void:
	for index in 3:
		_touch(index, true, Vector2(300 + index * 200, 700))
	await get_tree().create_timer(2.5).timeout
	for index in 3:
		_touch(index, false, Vector2(300 + index * 200, 700))
	await get_tree().create_timer(0.5).timeout
	_expect(Reporter.is_open(), "three fingers held for two seconds open the report")
	# Where to circle is read now, after the report froze the screen: the page may still have been
	# settling during the two-second hold (a loaded machine takes longer), and the picture is the frozen one.
	var promises := get_tree().current_scene.find_child("PromisesButton", true, false) as Button
	var target := promises.get_global_rect().get_center()
	var screen := Reporter.get_node_or_null("ReportScreen")
	if screen == null:
		_failures.append("no report screen")
		return
	_expect(screen.find_child("Shot", true, false) != null, "the first step shows the frozen screen")
	_expect(get_tree().paused, "the game stands still under it")
	var next := screen.find_child("ReportNext", true, false) as Button
	_expect(next != null and next.disabled, "Next waits for a circle")
	# Circle the Promises button with a finger.
	await _draw_circle(target, 90.0)
	await get_tree().create_timer(0.2).timeout
	next = screen.find_child("ReportNext", true, false) as Button
	_expect(next != null and not next.disabled, "drawing a circle turns Next on")
	await _click(next)
	await get_tree().create_timer(0.3).timeout
	_expect(screen.find_child("Thumbnail", true, false) != null, "the form shows the marked picture")
	var chip := screen.find_child("ReportKind_looks", true, false) as Button
	await _click(chip)
	var note := screen.find_child("ReportNote", true, false) as TextEdit
	note.text = "The Promises tile is in the wrong place"
	await _click(screen.find_child("ReportSave", true, false))
	await get_tree().create_timer(0.6).timeout
	var report := DisplayServer.clipboard_get()
	for part: String in ["Kind: looks", "Opened by: touch", "The Promises tile is in the wrong place", "OfficeScreen", "woodblock",
			"Under the centre: PromisesButton", "BEGIN SAVE", "Last actions"]:
		_expect(report.contains(part), "the copied report holds '%s'" % part)
	var saved := ReportCard.unpack_blob(ReportCard.find_blob(report))
	var parsed: Variant = JSON.parse_string(saved)
	_expect(parsed is Dictionary and (parsed as Dictionary).has("run"), "the save inside the report decodes to a run")
	_expect(screen.find_child("ReportDone", true, false) != null, "the last step offers Done")
	_expect(_label_texts(screen).any(func(text: String) -> bool: return text.contains(SCRATCH.get_file()) or text.contains("reports")),
		"it says where the files are")
	_check_files()
	await _click(screen.find_child("ReportDone", true, false))
	await get_tree().create_timer(0.3).timeout
	_expect(not Reporter.is_open(), "Done closes the report")
	_expect(not get_tree().paused, "and the game carries on")


func _check_files() -> void:
	var folders := DirAccess.get_directories_at(SCRATCH + "/reports")
	_expect(folders.size() == 1, "one report folder was written")
	if folders.is_empty():
		return
	var folder := SCRATCH + "/reports/" + folders[0]
	for file: String in ["report.md", "save.json", "screen.png", "marked.png"]:
		_expect(FileAccess.file_exists(folder + "/" + file), "the report folder holds " + file)
	var zip_path := SCRATCH + "/reports/%s.zip" % folders[0]
	_expect(FileAccess.file_exists(zip_path), "and a zip of it")
	var reader := ZIPReader.new()
	if reader.open(zip_path) == OK:
		var inside := reader.get_files()
		_expect(inside.has("report.md") and inside.has("marked.png") and inside.has("save.json"), "the zip holds the same files")
		reader.close()
	var marked := Image.load_from_file(ProjectSettings.globalize_path(folder + "/marked.png"))
	var plain := Image.load_from_file(ProjectSettings.globalize_path(folder + "/screen.png"))
	_expect(marked != null and plain != null and marked.get_size() == plain.get_size(), "the two pictures are the same size")
	if marked != null and plain != null:
		var differing := 0
		for step in range(0, marked.get_width() * marked.get_height(), 997):
			var at := Vector2i(step % marked.get_width(), step / marked.get_width())
			if marked.get_pixelv(at) != plain.get_pixelv(at):
				differing += 1
		_expect(differing > 0, "the marked picture really shows the circle")


func _check_volume_report() -> void:
	_key(KEY_VOLUMEUP, true)
	_key(KEY_VOLUMEDOWN, true)
	await get_tree().create_timer(2.5).timeout
	_key(KEY_VOLUMEUP, false)
	_key(KEY_VOLUMEDOWN, false)
	await get_tree().create_timer(0.5).timeout
	_expect(Reporter.is_open(), "both volume buttons held for two seconds open the report")
	var screen := Reporter.get_node_or_null("ReportScreen")
	if screen == null:
		return
	# Skip the circle, then cancel: nothing is saved.
	var before := DirAccess.get_directories_at(SCRATCH + "/reports").size()
	await _click(screen.find_child("ReportSkip", true, false))
	await get_tree().create_timer(0.3).timeout
	_expect(screen.find_child("ReportSave", true, false) != null, "Skip goes straight to the form")
	await _click(screen.find_child("ReportCancel", true, false))
	await get_tree().create_timer(0.3).timeout
	_expect(not Reporter.is_open(), "Cancel closes the report")
	_expect(DirAccess.get_directories_at(SCRATCH + "/reports").size() == before, "and saves nothing")


# --------------------------------------------------------------------------- after a crash

func _check_crash_offer() -> void:
	DirAccess.make_dir_recursive_absolute(SCRATCH + "/box")
	var box := {"saved_at": "x", "uptime": 90.0, "entries": [
		{"at": 10.0, "kind": "screen", "text": "OfficeScreen", "count": 1},
		{"at": 80.0, "kind": "press", "text": "StartButton 'Choose a level'", "count": 1}],
		"errors": [{"at": 85.0, "text": "Invalid access to a property", "where": "res://scripts/ui/X.gd:12 (f)", "count": 1}],
		"facts": {"scene": "BattleScreen", "run": {"Week": 2}}}
	var file := FileAccess.open(SCRATCH + "/box/blackbox.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(box))
	file.close()
	file = FileAccess.open(SCRATCH + "/box/session.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"clean": false}))
	file.close()
	Reporter._open_session()
	_expect(Reporter.crashed_last_time, "a session that did not close cleanly is noticed on the next start")
	Reporter._crash_offered = true
	Reporter.open_report("crash")
	await get_tree().create_timer(0.4).timeout
	var screen := Reporter.get_node_or_null("ReportScreen")
	_expect(screen != null and screen.find_child("ReportOfferYes", true, false) != null, "the offer appears")
	if screen == null:
		return
	await _click(screen.find_child("ReportOfferYes", true, false))
	await get_tree().create_timer(0.3).timeout
	var chip := screen.find_child("ReportKind_crash", true, false) as Button
	_expect(chip != null and chip.button_pressed, "the form starts on 'The game closed or froze'")
	await _click(screen.find_child("ReportSave", true, false))
	await get_tree().create_timer(0.5).timeout
	var report := DisplayServer.clipboard_get()
	for part: String in ["BEFORE this one", "StartButton 'Choose a level'", "Invalid access to a property", "BattleScreen"]:
		_expect(report.contains(part), "the crash report holds '%s'" % part)
	await _click(screen.find_child("ReportDone", true, false))
	await get_tree().create_timer(0.3).timeout
	Reporter.crashed_last_time = false
	Reporter.previous = {}


# --------------------------------------------------------------------------- the layout watch

func _check_layout_watch() -> void:
	for style: String in UiStyles.ALL:
		await _office(style)
		await get_tree().create_timer(0.5).timeout
		var faults := Reporter.current_layout_faults()
		_expect(faults.is_empty(), "%s: the Office has no layout faults (%s)" % [style, _faults_text(faults)])
	# The 2026-11-18 bug, made again by hand: the watch must name it.
	await _office("woodblock")
	var promises := get_tree().current_scene.find_child("PromisesButton", true, false) as Button
	promises.offset_bottom = -170.0   # the stale write the Office used to make; no re-sort followed it
	var found := Reporter.current_layout_faults()
	_expect(found.any(func(fault: Dictionary) -> bool: return fault["what"] == "outside_group" and str(fault["path"]).ends_with("PromisesButton")),
		"a Promises tile pushed out of its grid is found (%s)" % _faults_text(found))


func _faults_text(faults: Array) -> String:
	var parts: PackedStringArray = []
	for fault: Dictionary in faults:
		parts.append(str(fault["detail"]))
	return "; ".join(parts)


# --------------------------------------------------------------------------- input helpers

func _ring() -> Control:
	return Reporter.get_node("ReportHoldLayer/HoldRing") as Control


## A finger at a point in screen units (1080 x 2340), converted to the window's own pixels. The test fingers
## rest on the portrait picture, where no button is: a finger also arrives as a click, and one on a button
## would press it.
func _touch(index: int, pressed: bool, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = get_viewport().get_screen_transform() * at
	Input.parse_input_event(event)


func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code as Key
	event.physical_keycode = code as Key
	event.pressed = pressed
	Input.parse_input_event(event)


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
	await get_tree().create_timer(0.15).timeout


## A finger going round a circle: press, move, release.
func _draw_circle(centre: Vector2, radius: float) -> void:
	var transform := get_viewport().get_screen_transform()
	var steps := 28
	for step in steps + 1:
		var angle := TAU * float(step) / float(steps)
		var at: Vector2 = transform * (centre + Vector2(cos(angle), sin(angle)) * radius)
		if step == 0:
			var down := InputEventMouseButton.new()
			down.button_index = MOUSE_BUTTON_LEFT
			down.pressed = true
			down.position = at
			down.global_position = at
			Input.parse_input_event(down)
		else:
			var move := InputEventMouseMotion.new()
			move.position = at
			move.global_position = at
			move.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(move)
		await get_tree().process_frame
	var end: Vector2 = transform * (centre + Vector2(radius, 0.0))
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = end
	up.global_position = end
	Input.parse_input_event(up)
	await get_tree().process_frame


func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


func _clear_scratch() -> void:
	_remove_tree(SCRATCH)


func _remove_tree(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + file)
	for folder in DirAccess.get_directories_at(path):
		_remove_tree(path + "/" + folder)
	DirAccess.remove_absolute(path)


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)
