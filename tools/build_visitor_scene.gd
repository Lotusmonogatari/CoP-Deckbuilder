@tool
extends SceneTree
## Builds scenes/office_hours/VisitorScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_visitor_scene.gd
##
## Generated for the same reason tools/build_battle_scene.gd is (see its own
## header comment): a .tscn Godot itself writes is guaranteed readable, and
## the result opens and edits normally. Re-running this overwrites any
## editor-made changes.

const OUTPUT_PATH := "res://scenes/office_hours/VisitorScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/VisitorScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"

const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50
const BAND_HEIGHT := 0.6

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "VisitorScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	_add_background()
	var column := _build_frame()
	_add_header(column)
	_add_visitor_row(column)
	_add_question(column)
	_add_choices(column)
	_adopt(_vspacer(), column)
	_add_footer(column)

	_add_outcome_panel()
	_add_notice()

	_save()


func _add_background() -> void:
	var background := Control.new()
	background.name = "Background"
	background.set_script(load(PLACEHOLDER_SCRIPT))
	background.anchor_right = 1.0
	background.anchor_bottom = BAND_HEIGHT
	_adopt(background, _root, true)

	var scrim := ColorRect.new()
	scrim.name = "BackgroundScrim"
	scrim.anchor_right = 1.0
	scrim.anchor_bottom = BAND_HEIGHT
	scrim.color = Color(0.05, 0.05, 0.07, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(scrim, _root)

	var panel := ColorRect.new()
	panel.name = "BackgroundPanel"
	panel.anchor_top = BAND_HEIGHT
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.color = Color(0.05, 0.05, 0.07, 1.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adopt(panel, _root)


func _build_frame() -> VBoxContainer:
	var safe := MarginContainer.new()
	safe.name = "Safe"
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", SIDE_MARGIN)
	safe.add_theme_constant_override("margin_right", SIDE_MARGIN)
	safe.add_theme_constant_override("margin_top", TOP_MARGIN)
	safe.add_theme_constant_override("margin_bottom", BOTTOM_MARGIN)
	_adopt(safe, _root)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 20)
	_adopt(column, safe)
	return column


func _add_header(parent: Control) -> void:
	var header := HBoxContainer.new()
	header.name = "Header"
	_adopt(header, parent)

	var title := HBoxContainer.new()
	title.name = "Title"
	title.add_theme_constant_override("separation", 12)
	_adopt(title, header)

	_adopt(_label("StageName", "Office Hours", "HeaderLabel"), title, true)
	_adopt(_label("StageNameJP", "陳情", "JapaneseAccent"), title, true)

	_adopt(_spacer(), header)
	_adopt(_label("VisitorCaption", "1 of 3"), header, true)


func _add_visitor_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.name = "VisitorRow"
	row.add_theme_constant_override("separation", 20)
	_adopt(row, parent)

	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.set_script(load(PLACEHOLDER_SCRIPT))
	portrait.custom_minimum_size = Vector2(220, 320)
	_adopt(portrait, row, true)

	var details := VBoxContainer.new()
	details.name = "Details"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_adopt(details, row)

	_adopt(_label("VisitorName", "Visitor", "HeaderLabel"), details, true)
	_adopt(_label("VisitorTitle", "Constituent", "SmallLabel"), details, true)


func _add_question(parent: Control) -> void:
	var question := _label("QuestionLabel", "What does the district need most right now?")
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(question, parent, true)


## Four answers, one column — a phone screen is too narrow for a grid, and
## an answer can run long enough to need the wrap room a full-width row gives
## it.
func _add_choices(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.name = "Choices"
	column.add_theme_constant_override("separation", 12)
	_adopt(column, parent)

	for letter in ["A", "B", "C", "D"]:
		var choice := Button.new()
		choice.name = "Choice" + letter
		choice.text = "Choice " + letter
		choice.custom_minimum_size = Vector2(0, 90)
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_adopt(choice, column, true)


func _add_footer(parent: Control) -> void:
	var button := Button.new()
	button.name = "ContinueButton"
	button.text = "Continue"
	button.custom_minimum_size = Vector2(0, 110)
	button.disabled = true
	_adopt(button, parent, true)


func _add_outcome_panel() -> void:
	var panel := _overlay_panel("OutcomePanel", 0.5)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 20)
	column.custom_minimum_size = Vector2(900, 0)
	_adopt(column, panel)

	_adopt(_label("OutcomeTitle", "", "TitleLabel"), column, true)

	var body := _label("OutcomeBody", "")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(body, column, true)

	var close := Button.new()
	close.name = "OutcomeClose"
	close.text = "Close"
	_adopt(close, column, true)


func _add_notice() -> void:
	var notice := _label("Notice", "")
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.anchor_left = 0.5
	notice.anchor_right = 0.5
	notice.offset_left = -400
	notice.offset_right = 400
	notice.offset_top = 220
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	notice.add_theme_constant_override("outline_size", 8)
	notice.hide()
	_adopt(notice, _root, true)


# ---------------------------------------------------------------------------
# Helpers — identical to tools/build_battle_scene.gd's own
# ---------------------------------------------------------------------------

func _adopt(node: Node, parent: Node, unique: bool = false) -> void:
	parent.add_child(node)
	node.owner = _root
	if unique:
		node.unique_name_in_owner = true


func _label(node_name: String, text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


func _vspacer() -> Control:
	var spacer := Control.new()
	spacer.name = "VSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _overlay_panel(node_name: String, dim: float) -> Control:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.08, 0.11, dim + 0.35)
	panel.add_theme_stylebox_override("panel", box)
	_adopt(panel, _root, true)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 120)
	margin.add_theme_constant_override("margin_bottom", 120)
	_adopt(margin, panel)

	# An overlay's content must never be able to push its own buttons off the
	# bottom of the screen. A summary with an unusually long list of what
	# moved could otherwise leave the player looking at a panel with no way
	# out of it.
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_adopt(scroll, margin)

	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_adopt(centre, scroll)
	return centre


func _save() -> void:
	var error := DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Could not create %s: %s" % [OUTPUT_PATH.get_base_dir(), error])
		quit(1)
		return

	var packed := PackedScene.new()
	var pack_result := packed.pack(_root)
	if pack_result != OK:
		push_error("Could not pack the scene: %s" % pack_result)
		quit(1)
		return

	var save_result := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_result != OK:
		push_error("Could not save %s: %s" % [OUTPUT_PATH, save_result])
		quit(1)
		return

	print("Wrote ", OUTPUT_PATH)
	quit()
