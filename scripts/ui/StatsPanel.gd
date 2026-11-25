class_name StatsPanel
extends RefCounted
## The Your Statistics screen in Administration (2026-11-25, Cameron): one card for each section of StatsReport, and an Export
## report button that saves the same numbers as a text file and copies them to the clipboard. One Overlay owned by the Office;
## this class only fills it.

var _panel: Overlay
var _note: Label


func _init(panel: Overlay) -> void:
	_panel = panel


func open() -> void:
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	var blurb := UiKit.line(Text.say("stats.blurb"), "SmallLabel")
	blurb.custom_minimum_size.x = 0.0
	blurb.add_theme_color_override("font_color", look["on_ground_muted"])
	rows.append(blurb)
	var all := _sections()
	for section: Dictionary in all:
		rows.append(_card(section, look))
	rows.append(_export_card(look))
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("stats.title"), "subtitle": "", "chips": [], "rows": rows})
	_panel.open_frame(frame, Text.say("ui.back"))


func _sections() -> Array:
	return StatsReport.sections(GameState.run_stats, GameState.lifetime_gaffes, GameState.stages_lost_to_gaffes,
		GameState.venue_activity_totals)


## A card for one section: its note (the suit played most), then a label and a count on each row.
func _card(section: Dictionary, look: Dictionary) -> PanelContainer:
	var card := OfficeFrameStyles.card(look, str(section["title"]))
	card.name = "StatsCard_" + str(section["id"])
	var column: VBoxContainer = card.get_node("Column")
	if not str(section["note"]).is_empty():
		column.add_child(_wrapped(str(section["note"])))
	var rows: Array = section["rows"]
	if rows.is_empty():
		column.add_child(_wrapped(Text.say("stats.nothing")))
	for row: Array in rows:
		column.add_child(_row(str(row[0]), str(row[1])))
	return card


func _row(label: String, value: String) -> Control:
	var line := HBoxContainer.new()
	line.name = "StatsRow"
	var name_label := _wrapped(label)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	var count := _wrapped(value)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(count)
	return line


func _wrapped(text: String) -> Label:
	var label := UiKit.line(text, "SmallLabel")
	label.custom_minimum_size.x = 0.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## The Export report card: what the button does, the button, and (after a press) where the file went.
func _export_card(look: Dictionary) -> PanelContainer:
	var card := OfficeFrameStyles.card(look, "")
	card.name = "StatsExportCard"
	var column: VBoxContainer = card.get_node("Column")
	column.add_child(_wrapped(Text.say("stats.export_hint")))
	var button := UiKit.action_button(Text.say("stats.export_button"), "", _export, 110.0)
	button.name = "StatsExportButton"
	column.add_child(button)
	_note = _wrapped("")
	_note.name = "StatsExportNote"
	_note.visible = false
	column.add_child(_note)
	return card


func _export() -> void:
	var made := StatsReport.export(StatsReport.text(_sections()), GameState.run_seed)
	var said := Text.say("stats.export_failed")
	if bool(made["ok"]):
		if str(made["where"]) == "downloads":
			said = Text.say("stats.exported_downloads", {"file": str(made["file"])})
		else:
			said = Text.say("stats.exported_app", {"file": str(made["file"])})
	if _note != null:
		_note.text = said
		_note.visible = true
