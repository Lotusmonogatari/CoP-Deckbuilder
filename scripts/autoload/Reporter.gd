extends Node
## The problem reporter (2026-11-19, Cameron): a way for a tester to send back what went wrong
## together with what the game was doing, without anyone having to describe it.
##
## TWO WAYS TO OPEN IT, from any screen
##   - hold three fingers on the screen for two seconds (a ring fills while you hold)
##   - hold both volume buttons for two seconds (Android phones; iOS does not pass those buttons on)
## Both numbers are Balance rows ("Report: Hold Fingers", "Report: Hold Seconds").
##
## WHAT IT KEEPS, always, in memory and in a small file (user://reporter/blackbox.json)
##   - the last 60 things the player did: screens shown, buttons pressed, taps
##   - the script and engine errors the game noticed
##   - layout faults found by LayoutWatch (a button outside the group that holds it, off the screen,
##     or on top of another button), checked a moment after each screen and button press
## If the game stops without closing properly (a crash, the battery, a freeze and a kill) the next
## start notices and offers to send a report about it.
##
## WHAT A REPORT HOLDS: a picture of the screen (optionally circled), the screen, display style, text
## size and phone model, the run's week, hours and Funds, the black box, and a copy of the save so the
## problem can be reproduced. No name, email or device identifier. The game makes no network call:
## the report is copied to the clipboard as text and written to a zip the tester can send.
##
## The screen it opens is ReportScreen. Switch the whole thing off with Balance "Report: Enabled".

const ROOT_DIR := "user://reporter"
const REPORT_DIR := "user://reports"
## Written in two parts so the exporter's Text-key check does not take a file name for a key.
const SESSION_FILE := "session" + ".json"
const BLACKBOX_FILE := "blackbox" + ".json"
const WRITE_EVERY := 5.0
## A screen gets this long to settle (the Office re-fits itself over a few frames) before it is checked.
const SETTLE_SECONDS := 1.5
const RESCAN_SECONDS := 1.0
const ERROR_TOAST_GAP := 60.0
const MAX_ERRORS := 20
## How soon after the game starts the "it closed unexpectedly last time" offer may appear.
const CRASH_OFFER_AFTER := 2.0
const VOLUME_KEYS: Array[int] = [KEY_VOLUMEUP, KEY_VOLUMEDOWN]


## The engine tells this object about every error it prints, from whatever thread it happens on.
## It only queues them; the Reporter reads the queue on the main thread.
class ErrorCatcher extends Logger:
	var _mutex := Mutex.new()
	var _queue: Array = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != Logger.ERROR_TYPE_ERROR and error_type != Logger.ERROR_TYPE_SCRIPT:
			return
		var where := "%s:%d (%s)" % [file, line, function]
		for trace: ScriptBacktrace in script_backtraces:
			if trace != null and trace.get_frame_count() > 0:
				where = "%s:%d (%s)" % [trace.get_frame_file(0), trace.get_frame_line(0), trace.get_frame_function(0)]
				break
		_mutex.lock()
		if _queue.size() < 50:
			_queue.append({"text": rationale if not rationale.is_empty() else code, "where": where,
				"script": error_type == Logger.ERROR_TYPE_SCRIPT})
		_mutex.unlock()

	func take() -> Array:
		_mutex.lock()
		var out := _queue.duplicate()
		_queue.clear()
		_mutex.unlock()
		return out


var enabled := true
## False in test runs, so nothing is written to the player's real folder; a test of the files points
## `root_dir` and `report_dir` at a scratch folder and turns this on.
var persist := true
var root_dir := ROOT_DIR
var report_dir := REPORT_DIR
## Whether a saved report's zip is also copied to the phone's Downloads folder (a test turns it off).
var copy_to_downloads := true

var log := ActionLog.new()
## Errors noticed this session: { "at", "text", "where", "count" }.
var errors: Array = []
var uptime := 0.0
## True when the last session ended without closing properly; `previous` is its black box.
var crashed_last_time := false
var previous: Dictionary = {}

var _catcher := ErrorCatcher.new()
var _touch := HoldGesture.new(3, 2.0)
var _volume := HoldGesture.new(2, 2.0)
var _touch_points: Dictionary = {}
var _ring: ReportHoldRing
var _screen: ReportScreen
var _opening := false
var _crash_offered := false
var _dirty := false
var _since_write := 0.0
var _scene_name := ""
var _scan_at := -1.0
var _candidates: Dictionary = {}
var _layout_seen: Dictionary = {}
var _last_toast := -1000.0
var _facts_snapshot: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = int(DataDB.balance.get("report_enabled", 1)) != 0
	var seconds := float(DataDB.balance.get("report_hold_seconds", 2))
	_touch = HoldGesture.new(int(DataDB.balance.get("report_hold_fingers", 3)), seconds)
	_volume = HoldGesture.new(VOLUME_KEYS.size(), seconds)
	log = ActionLog.new(int(DataDB.balance.get("report_action_log_length", 60)))
	persist = SaveManager.enabled
	if not enabled:
		set_process(false)
		set_process_input(false)
		return
	if persist:
		_open_session()
	OS.add_logger(_catcher)
	get_tree().node_added.connect(_on_node_added)
	var layer := CanvasLayer.new()
	layer.name = "ReportHoldLayer"
	layer.layer = 140
	add_child(layer)
	_ring = ReportHoldRing.new()
	_ring.name = "HoldRing"
	layer.add_child(_ring)


# ---------------------------------------------------------------------------
# The black box: what is recorded

func _on_node_added(node: Node) -> void:
	# A button taken out of a panel and put back arrives here again: hook it once.
	if node is BaseButton and not node.has_meta(&"reporter_hooked"):
		node.set_meta(&"reporter_hooked", true)
		(node as BaseButton).pressed.connect(_on_pressed.bind(node))


func _on_pressed(button: Variant) -> void:
	if not is_instance_valid(button):
		return
	var text := str(button.get("text")) if "text" in button else ""
	text = text.replace("\n", " ").strip_edges().substr(0, 36)
	record("press", "%s%s" % [(button as Node).name, " '%s'" % text if not text.is_empty() else ""])
	# A press often changes the screen: look again, a moment later, at how it is laid out.
	_scan_at = maxf(_scan_at, uptime + SETTLE_SECONDS * 0.5)


func record(kind: String, text: String) -> void:
	log.add(uptime, kind, text)
	_dirty = true


func _note_error(item: Dictionary) -> void:
	if not errors.is_empty():
		var last: Dictionary = errors[errors.size() - 1]
		if str(last["text"]) == str(item["text"]) and str(last["where"]) == str(item["where"]):
			last["count"] = int(last["count"]) + 1
			last["at"] = uptime
			return
	errors.append({"at": uptime, "text": str(item["text"]), "where": str(item["where"]), "count": 1})
	while errors.size() > MAX_ERRORS:
		errors.pop_front()
	record("error", str(item["text"]).substr(0, 120))
	# A script error aborts whatever was running; say so, but never more than once a minute.
	if bool(item.get("script", false)) and uptime - _last_toast > ERROR_TOAST_GAP and _screen == null:
		_last_toast = uptime
		Layout.flash(Text.say("report.error_noticed", {"fingers": _touch.needed}))


func _check_scene() -> void:
	var scene := get_tree().current_scene
	var now_name := "" if scene == null else str(scene.name)
	if now_name != _scene_name:
		_scene_name = now_name
		if not now_name.is_empty():
			record("screen", now_name)
			_layout_seen.clear()
			_candidates.clear()
			_scan_at = uptime + SETTLE_SECONDS


## Looks at how the screen is laid out. A fault is written to the black box only when two looks, a
## second apart, both find it, so a button that is merely sliding in is not reported.
func _scan_layout() -> void:
	if int(DataDB.balance.get("report_layout_watch", 1)) == 0 or get_tree().current_scene == null:
		return
	var found: Dictionary = {}
	for fault: Dictionary in current_layout_faults():
		found["%s|%s" % [fault["what"], fault["path"]]] = fault
	var confirmed := false
	for key: String in found:
		if _candidates.has(key) and not _layout_seen.has(key):
			_layout_seen[key] = true
			record("layout", str((found[key] as Dictionary)["detail"]))
		elif not _candidates.has(key):
			confirmed = true
	_candidates = found
	if confirmed:
		_scan_at = uptime + RESCAN_SECONDS


## The layout faults on the screen showing right now (LayoutWatch over what ControlProbe collects).
func current_layout_faults() -> Array[Dictionary]:
	var boxes := ControlProbe.collect(get_tree().current_scene)
	return LayoutWatch.problems(boxes, get_viewport().get_visible_rect())


# ---------------------------------------------------------------------------
# Frame by frame

func _process(delta: float) -> void:
	uptime += delta
	for item: Dictionary in _catcher.take():
		_note_error(item)
	_check_scene()
	if _scan_at >= 0.0 and uptime >= _scan_at:
		_scan_at = -1.0
		_scan_layout()
	_watch_gestures(delta)
	if _dirty and persist:
		_since_write += delta
		if _since_write >= WRITE_EVERY:
			_write_blackbox()
	if crashed_last_time and not _crash_offered and uptime >= CRASH_OFFER_AFTER and _screen == null and not _opening:
		_crash_offered = true
		open_report("crash")


func _watch_gestures(delta: float) -> void:
	if _screen != null or _opening:
		_ring.hide_ring()
		return
	var touched := _touch.tick(delta)
	var pressed := _volume.tick(delta)
	var progress := maxf(_touch.progress(), _volume.progress())
	if progress > 0.0 and progress < 1.0:
		var at := get_viewport().get_visible_rect().size * 0.5
		if _touch.progress() >= _volume.progress() and not _touch_points.is_empty():
			at = _touch_centre()
		_ring.show_progress(progress, at, Text.say("report.holding"))
	else:
		_ring.hide_ring()
	if touched:
		open_report("touch")
	elif pressed:
		open_report("volume")


func _touch_centre() -> Vector2:
	var total := Vector2.ZERO
	for point: Vector2 in _touch_points.values():
		total += point
	return total / float(_touch_points.size())


func _input(event: InputEvent) -> void:
	if _screen != null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch.press(touch.index)
			_touch_points[touch.index] = touch.position
			record("tap", "(%d, %d)" % [int(touch.position.x), int(touch.position.y)])
		else:
			_touch.release(touch.index)
			_touch_points.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touch_points.has(drag.index):
			_touch_points[drag.index] = drag.position
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		# A touch also arrives as an emulated click; the touch itself is already recorded.
		if click.pressed and click.device != InputEvent.DEVICE_ID_EMULATION and click.button_index == MOUSE_BUTTON_LEFT:
			record("tap", "(%d, %d)" % [int(click.position.x), int(click.position.y)])
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.echo:
			return
		for code: int in [key.keycode, key.physical_keycode]:
			if code in VOLUME_KEYS:
				if key.pressed:
					_volume.press(code)
				else:
					_volume.release(code)
				break


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			# Sent to the background or closed on purpose: not a crash, even if the phone then kills it.
			_touch.reset()
			_volume.reset()
			_touch_points.clear()
			if persist and enabled:
				_write_blackbox()
				_write_session(true)
		NOTIFICATION_APPLICATION_RESUMED:
			if persist and enabled:
				_write_session(false)


# ---------------------------------------------------------------------------
# Opening a report

## Opens the report screen. `source` is "touch", "volume" or "crash" (the offer after an unclean stop).
func open_report(source: String) -> void:
	if not enabled or _screen != null or _opening:
		return
	_opening = true
	_touch.reset()
	_volume.reset()
	_touch_points.clear()
	_ring.hide_ring()
	var image: Image = null
	var boxes: Array = []
	if source != "crash":
		# One frame without the ring, so the picture is the screen as the tester saw it.
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		image = get_viewport().get_texture().get_image()
		if image != null and image.is_empty():
			image = null
		boxes = ControlProbe.collect(get_tree().current_scene)
	_screen = ReportScreen.new()
	_screen.name = "ReportScreen"
	_screen.setup(source, image, boxes, previous if source == "crash" else {})
	_screen.closed.connect(_on_screen_closed)
	add_child(_screen)
	_opening = false


func _on_screen_closed() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null


## True while the report screen is showing.
func is_open() -> bool:
	return _screen != null or _opening


## The lines the Administration menu shows so testers know the gestures exist.
func hint_lines() -> Array[String]:
	var lines: Array[String] = []
	if not enabled:
		return lines
	var seconds := _seconds_text()
	lines.append(Text.say("report.hold_hint", {"fingers": _touch.needed, "seconds": seconds}))
	if OS.get_name() == "Android":
		lines.append(Text.say("report.hold_hint_volume", {"seconds": seconds}))
	return lines


func _seconds_text() -> String:
	var seconds := _touch.seconds
	return str(int(seconds)) if is_equal_approx(seconds, round(seconds)) else str(snappedf(seconds, 0.1))


# ---------------------------------------------------------------------------
# Making the report

## What the report says about where the game is, as ReportCard wants it.
func gather_facts() -> Dictionary:
	var scene := get_tree().current_scene
	var window := Vector2(get_viewport().get_visible_rect().size)
	var facts := {
		"build": str(ProjectSettings.get_setting("application/config/version", "")),
		"platform": OS.get_name(),
		"model": OS.get_model_name(),
		"screen": "%dx%d (window %dx%d)" % [int(window.x), int(window.y), DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"safe": "left %d, top %d, right %d, bottom %d" % [int(Layout.insets["left"]), int(Layout.insets["top"]), int(Layout.insets["right"]), int(Layout.insets["bottom"])],
		"scene": "%s (%s)" % [scene.name, scene.scene_file_path] if scene != null else "",
		"style": UiStyle.current(),
		"text_size": Layout.text_size_setting,
		"run": _run_facts(),
	}
	return facts


func _run_facts() -> Dictionary:
	var run := {}
	if GameState.protagonist_id.is_empty():
		return run
	run["Protagonist"] = GameState.protagonist_id
	run["Difficulty"] = GameState.difficulty
	run["Week"] = int(GameState.calendar.get("week", 0))
	run["Work hours left"] = GameState.work_hours_left()
	for key: Variant in GameState.meta.keys():
		run[str(key)] = GameState.meta[key]
	run["XP"] = GameState.xp
	run["Open promises"] = GameState.promises.size()
	if GameState.is_in_level():
		var runner := GameState.level_runner
		run["Level"] = str(runner.level.get("level_id", ""))
		run["Stage"] = "%d of %d (%s)" % [runner.index + 1, runner.stage_count(), str(runner.current_stage().get("stage_id", ""))]
	else:
		run["Level"] = "none in progress"
	return run


## The save as text in the same form SaveManager writes it, or "" when no run exists.
func save_text() -> String:
	if GameState.protagonist_id.is_empty():
		return ""
	return JSON.stringify({
		"version": SaveManager.VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"run": JSON.from_native(GameState.to_save()),
	})


## Builds the report from what the tester chose, copies its text and writes the files.
## `request`: kind, note, source, image (Image or null), marked (Image or null), circled (lines),
## previous (the last session's black box, for a "crash" report).
## Returns { "ok": bool, "text": String, "folder": String, "zip": String, "shared": String }.
func save_report(request: Dictionary) -> Dictionary:
	var previous_box: Dictionary = request.get("previous", {}) as Dictionary
	var from_last_session := not previous_box.is_empty()
	var card := gather_facts()
	if from_last_session:
		card["scene"] = str((previous_box.get("facts", {}) as Dictionary).get("scene", ""))
		card["run"] = (previous_box.get("facts", {}) as Dictionary).get("run", {})
	card["kind"] = str(request.get("kind", ""))
	card["note"] = str(request.get("note", ""))
	card["source"] = str(request.get("source", ""))
	card["made_at"] = Time.get_datetime_string_from_system()
	card["circled"] = request.get("circled", [])
	card["previous_session"] = from_last_session
	var layout_lines: Array = []
	if not from_last_session:
		for fault: Dictionary in current_layout_faults():
			layout_lines.append(str(fault["detail"]))
	card["layout"] = layout_lines
	if from_last_session:
		var old_log := ActionLog.from_array(previous_box.get("entries", []) as Array, log.capacity)
		card["actions"] = old_log.lines(float(previous_box.get("uptime", 0.0)))
		card["errors"] = _error_lines(previous_box.get("errors", []) as Array, float(previous_box.get("uptime", 0.0)))
	else:
		card["actions"] = log.lines(uptime)
		card["errors"] = _error_lines(errors, uptime)
	var save := _save_for_report(from_last_session)
	var blob := ""
	if save.is_empty():
		card["save_note"] = "(no run was in progress, so no save is included)"
	else:
		blob = ReportCard.pack_blob(save)
		var most := int(DataDB.balance.get("report_max_paste_characters", 120000))
		if blob.length() > most:
			blob = ""
			card["save_note"] = "(the save is too large to paste; it is in save.json inside the zip)"
	var text := ReportCard.to_text(card, blob)
	DisplayServer.clipboard_set(text)
	var result := {"ok": false, "text": text, "folder": "", "zip": "", "shared": ""}
	if persist:
		var written := ReportFiles.write(report_dir, _report_id(), {"text": text, "save_text": save,
			"screenshot": request.get("image"), "marked": request.get("marked")},
			int(DataDB.balance.get("report_max_saved", 10)), copy_to_downloads)
		result.merge(written, true)
	return result


## The run to attach: the live one, or for a crash the last autosave (the live run is a new session).
func _save_for_report(from_last_session: bool) -> String:
	if not from_last_session:
		return save_text()
	if FileAccess.file_exists(SaveManager.save_path):
		return FileAccess.get_file_as_string(SaveManager.save_path)
	return ""


static func _error_lines(items: Array, now: float) -> Array:
	var lines: Array = []
	for item: Variant in items:
		if not (item is Dictionary):
			continue
		var entry := item as Dictionary
		var times := int(entry.get("count", 1))
		lines.append("%s: %s [%s]%s" % [ActionLog.ago(now - float(entry.get("at", 0.0))), str(entry.get("text", "")),
			str(entry.get("where", "")), " (x%d)" % times if times > 1 else ""])
	return lines


func _report_id() -> String:
	var stamp := Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")
	return "%s-%03d" % [stamp, Time.get_ticks_msec() % 1000]


# ---------------------------------------------------------------------------
# Between sessions: the clean-stop flag and the black box on disk

func _open_session() -> void:
	DirAccess.make_dir_recursive_absolute(root_dir)
	var old: Variant = _read_json(root_dir.path_join(SESSION_FILE))
	if old is Dictionary and not bool((old as Dictionary).get("clean", true)):
		var box: Variant = _read_json(root_dir.path_join(BLACKBOX_FILE))
		if box is Dictionary and not ((box as Dictionary).get("entries", []) as Array).is_empty():
			crashed_last_time = true
			previous = box as Dictionary
	_write_session(false)


func _write_session(clean: bool) -> void:
	_write_json(root_dir.path_join(SESSION_FILE), {"clean": clean, "build": str(ProjectSettings.get_setting("application/config/version", "")),
		"at": Time.get_datetime_string_from_system()})


func _write_blackbox() -> void:
	_since_write = 0.0
	_dirty = false
	_facts_snapshot = gather_facts()
	_write_json(root_dir.path_join(BLACKBOX_FILE), {"saved_at": Time.get_datetime_string_from_system(), "uptime": uptime,
		"entries": log.to_array(), "errors": errors, "facts": _facts_snapshot})


static func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
