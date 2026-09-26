@tool
extends SceneTree
## Builds scenes/office_hours/FloorVoteScreen.tscn.
##
## Run it with:
##     .tools/godot --headless --path . --script tools/build_floor_vote_scene.gd
##
## Same reason tools/build_visitor_scene.gd is generated rather than hand-
## written (see its own header comment): a .tscn Godot itself writes is
## guaranteed readable. Re-running this overwrites any editor-made changes.

const OUTPUT_PATH := "res://scenes/office_hours/FloorVoteScreen.tscn"
const SCREEN_SCRIPT := "res://scripts/ui/FloorVoteScreen.gd"
const PLACEHOLDER_SCRIPT := "res://scripts/ui/PlaceholderArt.gd"
const VOTE_BAR_SCRIPT := "res://scripts/ui/PartyVoteBar.gd"

const SIDE_MARGIN := 40
const TOP_MARGIN := 70
const BOTTOM_MARGIN := 50
const BAND_HEIGHT := 0.6
const PARTY_COUNT := 6

var _root: Control


func _init() -> void:
	_root = Control.new()
	_root.name = "FloorVoteScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_script(load(SCREEN_SCRIPT))

	_add_background()
	var column := _build_frame()
	_add_header(column)
	_add_party_row(column)
	_add_scroll(column)
	_add_choices(column)

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

	_adopt(_label("StageName", "National Assembly Floor Voting", "HeaderLabel"), title, true)
	_adopt(_label("StageNameJP", "本会議採決", "JapaneseAccent"), title, true)


## Six party cards, one per real party, shown all at once — every party's
## own disposition is already decided before the player votes, unlike a
## visitor's response which waits on a choice.
func _add_party_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.name = "PartyRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.unique_name_in_owner = true
	_adopt(row, parent)

	for index in PARTY_COUNT:
		var card := VBoxContainer.new()
		card.name = "Card%d" % index
		card.add_theme_constant_override("separation", 4)
		row.add_child(card)
		card.owner = _root

		var portrait := Control.new()
		portrait.name = "Portrait"
		portrait.set_script(load(PLACEHOLDER_SCRIPT))
		portrait.custom_minimum_size = Vector2(100, 130)
		card.add_child(portrait)
		portrait.owner = _root

		var swatch := ColorRect.new()
		swatch.name = "Swatch"
		swatch.custom_minimum_size = Vector2(0, 6)
		card.add_child(swatch)
		swatch.owner = _root

		var name_label := Label.new()
		name_label.name = "Name"
		name_label.theme_type_variation = "SmallLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(name_label)
		name_label.owner = _root

		var cue_label := Label.new()
		cue_label.name = "Cue"
		cue_label.theme_type_variation = "SmallLabel"
		cue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cue_label.custom_minimum_size = Vector2(100, 0)
		card.add_child(cue_label)
		cue_label.owner = _root


func _add_scroll(parent: Control) -> void:
	var scroll_area := Control.new()
	scroll_area.name = "ScrollArea"
	scroll_area.custom_minimum_size = Vector2(0, 240)
	scroll_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_adopt(scroll_area, parent)

	var scroll_art := Control.new()
	scroll_art.name = "ScrollArt"
	scroll_art.set_script(load(PLACEHOLDER_SCRIPT))
	scroll_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_adopt(scroll_art, scroll_area)

	var margin := MarginContainer.new()
	margin.name = "TextMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	_adopt(margin, scroll_area)

	var bill_text := _label("BillText", "The bill's own description goes here.")
	bill_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bill_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_adopt(bill_text, margin, true)


func _add_choices(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.name = "Choices"
	row.add_theme_constant_override("separation", 16)
	_adopt(row, parent)

	for entry in [["VoteYes", "Vote Yes"], ["VoteNo", "Vote No"], ["VoteAbstain", "Abstain"]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		button.custom_minimum_size = Vector2(0, 100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_adopt(button, row, true)


func _add_outcome_panel() -> void:
	var panel := _overlay_panel("OutcomePanel", 0.5)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 16)
	column.custom_minimum_size = Vector2(900, 0)
	_adopt(column, panel)

	_adopt(_label("OutcomeTitle", "", "TitleLabel"), column, true)

	var body := _label("OutcomeBody", "")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adopt(body, column, true)

	for entry in [["BarYes", "Yes"], ["BarNo", "No"], ["BarAbstain", "Abstain"]]:
		var row := VBoxContainer.new()
		row.name = entry[0] + "Row"
		row.add_theme_constant_override("separation", 4)
		_adopt(row, column)

		_adopt(_label(entry[0] + "Label", str(entry[1]), "SmallLabel"), row, false)

		var bar := Control.new()
		bar.name = entry[0]
		bar.set_script(load(VOTE_BAR_SCRIPT))
		bar.custom_minimum_size = Vector2(0, 40)
		_adopt(bar, row, true)

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
# Helpers — identical to tools/build_visitor_scene.gd's own
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
