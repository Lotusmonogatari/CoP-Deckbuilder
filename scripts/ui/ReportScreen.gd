class_name ReportScreen
extends CanvasLayer
## The problem report, as the tester sees it (2026-11-19). It sits above every screen, so it can open
## from anywhere, and works in steps:
##
##   OFFER   after a crash only: "The game closed unexpectedly last time. Save a report?"
##   CIRCLE  the screen as it was, frozen; draw a circle round the problem (or skip), then Next
##   FORM    what kind of problem, an optional note, and a plain list of what the report holds
##   DONE    "Report saved": the text is on the clipboard, the files are where the phone allows
##
## Nothing is saved or copied until the tester presses Save the report; Cancel at any step leaves
## everything as it was. The report itself is made by Reporter.save_report().
##
## All words are Text rows (report.*). Buttons are 130 px tall.

signal closed

const BUTTON_HEIGHT := 130.0
const BACKDROP := Color(0.07, 0.08, 0.11, 1.0)
const SCRIM := Color(0.0, 0.0, 0.0, 0.62)
const GOLD := Color(0.89, 0.7, 0.25, 1.0)
const PLATE := Color(0.07, 0.08, 0.11, 0.86)
const MIN_STROKE_POINTS := 8
const THUMBNAIL_HEIGHT := 420.0
const NOTE_HEIGHT := 220.0
const COLUMN_WIDTH := 880.0

var _source := ""
var _image: Image
var _boxes: Array = []
var _previous: Dictionary = {}
var _marked: Image
var _circled: Array = []
var _kind := ""
var _result: Dictionary = {}

var _root: Control
var _canvas: DrawingCanvas
var _next: Button
var _undo: Button
var _plate: Control
var _note: TextEdit
var _kind_group := ButtonGroup.new()
var _was_paused := false


## Draws the tester's strokes. Plain mouse events: a finger arrives as an emulated click.
class DrawingCanvas extends Control:
	signal started
	signal changed

	var strokes: Array = []
	var _current := PackedVector2Array()
	var _drawing := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		# Anchors AND offsets: set after the node is in the tree, anchors alone left it zero-sized.
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if (event as InputEventMouseButton).pressed:
				_drawing = true
				_current = PackedVector2Array([(event as InputEventMouseButton).position])
				started.emit()
			elif _drawing:
				_drawing = false
				_finish()
		elif event is InputEventMouseMotion and _drawing:
			var at := (event as InputEventMouseMotion).position
			if _current.is_empty() or at.distance_to(_current[_current.size() - 1]) >= 4.0:
				_current.append(at)
				queue_redraw()

	func _finish() -> void:
		if _current.size() >= ReportScreen.MIN_STROKE_POINTS:
			strokes.append(_current)
			changed.emit()
		_current = PackedVector2Array()
		queue_redraw()

	func undo() -> void:
		if not strokes.is_empty():
			strokes.pop_back()
			changed.emit()
			queue_redraw()

	func _draw() -> void:
		var all: Array = strokes.duplicate()
		if _drawing:
			all.append(_current)
		for stroke: Variant in all:
			var points := stroke as PackedVector2Array
			if points.size() >= 2:
				draw_polyline(points, StrokePaint.OUTLINE, StrokePaint.OUTLINE_RADIUS * 2.0, true)
				draw_polyline(points, StrokePaint.INK, StrokePaint.INK_RADIUS * 2.0, true)


## `source` is "touch", "volume" or "crash". `image` is the frozen screen (null for a crash report);
## `boxes` are the screen's controls (ControlProbe); `previous` is the last session's black box.
func setup(source: String, image: Image, boxes: Array, previous: Dictionary) -> void:
	_source = source
	_image = image
	_boxes = boxes
	_previous = previous
	if source == "crash":
		_kind = "crash"


func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The game underneath stands still while a report is made: its own drag handling (a page that scrolls
	# when dragged) would otherwise take the finger that is drawing the circle.
	_was_paused = get_tree().paused
	get_tree().paused = true
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	if _source == "crash":
		_show_offer()
	elif _image != null:
		_show_circle()
	else:
		_show_form()


func _exit_tree() -> void:
	get_tree().paused = _was_paused


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Building blocks

func _reset_step() -> void:
	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	_canvas = null
	_next = null
	_undo = null
	_plate = null
	_note = null


func _backdrop(colour: Color) -> void:
	var fill := ColorRect.new()
	fill.color = colour
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(fill)


## A full-screen margin named "Safe", so Layout keeps it clear of the notch and the home bar.
func _safe_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "Safe"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	_root.add_child(margin)
	return margin


func _button(button_name: String, text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_press)
	return button


func _line(text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


func _ignore_mouse(nodes: Array) -> void:
	for node: Variant in nodes:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


# ---------------------------------------------------------------------------
# Step: offer (after a crash)

func _show_offer() -> void:
	_reset_step()
	_backdrop(SCRIM)
	var margin := _safe_margin()
	var centre := CenterContainer.new()
	margin.add_child(centre)
	var panel := PanelContainer.new()
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = BACKDROP
	panel_box.border_color = GOLD
	panel_box.set_border_width_all(4)
	panel_box.set_corner_radius_all(10)
	panel_box.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", panel_box)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	column.add_child(_line(Text.say("report.crash_title"), "HeaderLabel"))
	column.add_child(_line(Text.say("report.crash_body")))
	column.add_child(_button("ReportOfferYes", Text.say("report.crash_yes"), _show_form))
	column.add_child(_button("ReportOfferNo", Text.say("report.crash_no"), _close))


# ---------------------------------------------------------------------------
# Step: circle the problem

func _show_circle() -> void:
	_reset_step()
	var shot := TextureRect.new()
	shot.name = "Shot"
	shot.texture = ImageTexture.create_from_image(_image)
	shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shot.stretch_mode = TextureRect.STRETCH_SCALE
	shot.set_anchors_preset(Control.PRESET_FULL_RECT)
	shot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shot)
	_canvas = DrawingCanvas.new()
	_canvas.name = "Canvas"
	_canvas.started.connect(_on_drawing_started)
	_canvas.changed.connect(_on_strokes_changed)
	_root.add_child(_canvas)
	# A gold frame says "this is a frozen picture, not the live game".
	var frame := Panel.new()
	var frame_box := StyleBoxFlat.new()
	frame_box.bg_color = Color(0, 0, 0, 0)
	frame_box.border_color = GOLD
	frame_box.set_border_width_all(8)
	frame.add_theme_stylebox_override("panel", frame_box)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(frame)
	var margin := _safe_margin()
	var column := VBoxContainer.new()
	margin.add_child(column)
	var plate := PanelContainer.new()
	plate.name = "Instruction"
	var plate_box := StyleBoxFlat.new()
	plate_box.bg_color = PLATE
	plate_box.set_corner_radius_all(14)
	plate_box.set_content_margin_all(22)
	plate.add_theme_stylebox_override("panel", plate_box)
	plate.add_child(_line(Text.say("report.circle_help")))
	column.add_child(plate)
	_plate = plate
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	row.add_child(_button("ReportCancel", Text.say("report.cancel"), _close))
	row.add_child(_button("ReportSkip", Text.say("report.skip"), _show_form))
	_undo = _button("ReportUndo", Text.say("report.undo"), _on_undo)
	_undo.disabled = true
	row.add_child(_undo)
	_next = _button("ReportNext", Text.say("report.next"), _on_next)
	_next.disabled = true
	row.add_child(_next)
	# Only the buttons and the drawing surface take touches; everything laid over the picture lets
	# a finger through to the surface beneath.
	_ignore_mouse([margin, column, plate, spacer, row])
	for child in plate.get_children():
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_drawing_started() -> void:
	# Once a finger is down the instruction has done its job and stops covering the picture.
	if _plate != null:
		_plate.visible = false


func _on_strokes_changed() -> void:
	var drawn := _canvas != null and not _canvas.strokes.is_empty()
	if _next != null:
		_next.disabled = not drawn
	if _undo != null:
		_undo.disabled = not drawn
	if _plate != null and not drawn:
		_plate.visible = true


func _on_undo() -> void:
	if _canvas != null:
		_canvas.undo()


func _on_next() -> void:
	if _canvas == null or _canvas.strokes.is_empty():
		return
	var strokes := _canvas.strokes.duplicate()
	var marked := _image.duplicate() as Image
	var scale := float(marked.get_width()) / maxf(get_viewport().get_visible_rect().size.x, 1.0)
	_marked = StrokePaint.paint(marked, strokes, scale)
	_circled = circled_lines(_boxes, strokes)
	_show_form()


## What the report says was circled, in words a developer can find the control from.
static func circled_lines(boxes: Array, strokes: Array) -> Array:
	var lines: Array = []
	var area := StrokePaint.bounds(strokes)
	if strokes.is_empty():
		return lines
	var centre := area.get_center()
	lines.append("Circle centred at (%d, %d), %d x %d pixels" % [int(centre.x), int(centre.y), int(area.size.x), int(area.size.y)])
	var named: Dictionary = {}
	var under := LayoutWatch.under_point(boxes, centre)
	for index in mini(under.size(), 3):
		var box: Dictionary = under[index]
		named[str(box["path"])] = true
		lines.append("Under the centre: %s" % LayoutWatch.describe(box))
	var inside := LayoutWatch.inside_area(boxes, area)
	var shown := 0
	for box: Dictionary in inside:
		if shown >= 6:
			break
		if named.has(str(box["path"])):
			continue
		shown += 1
		lines.append("Inside the circle: %s" % LayoutWatch.describe(box))
	return lines


# ---------------------------------------------------------------------------
# Step: the form

func _show_form() -> void:
	_reset_step()
	_backdrop(BACKDROP)
	var margin := _safe_margin()
	var scroll := ScrollContainer.new()
	scroll.name = "FormScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	column.add_child(_line(Text.say("report.form_title"), "HeaderLabel"))
	var picture := _marked if _marked != null else _image
	if picture != null:
		var thumb := TextureRect.new()
		thumb.name = "Thumbnail"
		thumb.texture = ImageTexture.create_from_image(picture)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.custom_minimum_size = Vector2(0, THUMBNAIL_HEIGHT)
		column.add_child(thumb)
	column.add_child(_line(Text.say("report.kind_heading")))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 12)
	chips.add_theme_constant_override("v_separation", 12)
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(chips)
	for id: String in ReportCard.KINDS:
		if id == "crash" and _source != "crash":
			continue
		var chip := Button.new()
		chip.name = "ReportKind_" + id
		chip.text = _kind_text(id)
		chip.toggle_mode = true
		chip.button_group = _kind_group
		chip.custom_minimum_size = Vector2(0, 110)
		chip.button_pressed = (id == _kind)
		_style_chosen(chip)
		chip.pressed.connect(_on_kind.bind(id))
		chips.add_child(chip)
	_note = TextEdit.new()
	_note.name = "ReportNote"
	_note.placeholder_text = Text.say("report.note_placeholder")
	_note.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_note.custom_minimum_size = Vector2(0, NOTE_HEIGHT)
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_note)
	column.add_child(_line(Text.say("report.includes"), "SmallLabel"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	row.add_child(_button("ReportCancel", Text.say("report.cancel"), _close))
	row.add_child(_button("ReportSave", Text.say("report.save"), _on_save))


## The chosen kind is filled gold with dark writing, so which one is picked reads at a glance.
func _style_chosen(chip: Button) -> void:
	var gold := StyleBoxFlat.new()
	gold.bg_color = GOLD
	gold.border_color = Color.WHITE
	gold.set_border_width_all(3)
	gold.set_corner_radius_all(6)
	gold.set_content_margin_all(14)
	for state: String in ["pressed", "hover_pressed"]:
		chip.add_theme_stylebox_override(state, gold)
	for colour: String in ["font_pressed_color", "font_hover_pressed_color"]:
		chip.add_theme_color_override(colour, Color(0.1, 0.08, 0.05))


func _on_kind(id: String) -> void:
	_kind = id


## One literal key per kind, so the exporter can check each.
func _kind_text(id: String) -> String:
	match id:
		"looks": return Text.say("report.kind_looks")
		"broken": return Text.say("report.kind_broken")
		"wording": return Text.say("report.kind_wording")
		"balance": return Text.say("report.kind_balance")
		"idea": return Text.say("report.kind_idea")
	return Text.say("report.kind_crash")


func _on_save() -> void:
	var note := _note.text if _note != null else ""
	_result = Reporter.save_report({"kind": _kind, "note": note, "source": _source, "image": _image,
		"marked": _marked, "circled": _circled, "previous": _previous})
	_show_done()


# ---------------------------------------------------------------------------
# Step: done

func _show_done() -> void:
	_reset_step()
	_backdrop(BACKDROP)
	var margin := _safe_margin()
	var centre := CenterContainer.new()
	margin.add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	centre.add_child(column)
	column.add_child(_line(Text.say("report.saved_title"), "HeaderLabel"))
	column.add_child(_line(Text.say("report.saved_copied")))
	column.add_child(_line(_where_line()))
	var again := _button("ReportCopyAgain", Text.say("report.copy_again"), _copy_again)
	again.pressed.connect(func() -> void: again.text = Text.say("report.copied_again"))
	column.add_child(again)
	column.add_child(_button("ReportDone", Text.say("report.done"), _close))


func _where_line() -> String:
	var shared := str(_result.get("shared", ""))
	if not shared.is_empty():
		return Text.say("report.saved_shared", {"where": shared})
	var folder := str(_result.get("folder", ""))
	if not folder.is_empty():
		return Text.say("report.saved_file", {"where": folder})
	return Text.say("report.saved_nofile")


func _copy_again() -> void:
	DisplayServer.clipboard_set(str(_result.get("text", "")))


func _close() -> void:
	closed.emit()
