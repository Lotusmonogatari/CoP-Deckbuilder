class_name DuesBox
extends RefCounted
## The Office's End of Week Payments box (P9, 2026-11-17; the dues box of 2026-10-28 before it):
## a gold-edged box beside the calendar square with the title, the TOTAL the week's end will
## take (party dues plus staff wages), "Dues … · Wages …" under it, and the Funds on hand.
## Tapping it opens the breakdown (WeekPaymentsView). When Funds will not cover it, the box turns
## the warning red and says who goes unpaid.
##
## Built in code like CalendarSquare, so the Office scene needs no edit. It sits in the Office's
## unused lower space, bottom right. The class keeps its old name so nothing that holds it changes.

const SIZE := Vector2(460, 200)
## Living Office's payments tray is wider: Funds on the left, the payments on the right.
const TRAY_SIZE := Vector2(660, 200)
const WARNING_RED := Color(1.0, 0.45, 0.4)


## The box, empty; refresh() fills it from the run. `on_tap` opens the breakdown.
static func make(on_tap: Callable = Callable()) -> PanelContainer:
	var square := PanelContainer.new()
	square.name = "DuesBox"
	square.custom_minimum_size = SIZE
	square.mouse_filter = Control.MOUSE_FILTER_STOP if on_tap.is_valid() else Control.MOUSE_FILTER_IGNORE
	if on_tap.is_valid():
		square.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
					and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				on_tap.call())
	var box := StyleBoxFlat.new()
	var plate := UiStyle.plate_colour()
	box.bg_color = Color(plate.r, plate.g, plate.b, 0.92)
	# Gold in Living Office and Broadcast; the red of a seal in Woodblock.
	box.border_color = UiStyle.colour("vermilion", CueBanner.EDGE_COLOUR) if UiStyle.current() == UiStyles.WOODBLOCK else CueBanner.EDGE_COLOUR
	box.set_border_width_all(CalendarSquare.EDGE_WIDTH)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(14)
	square.add_theme_stylebox_override("panel", box)
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 2)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Living Office draws this as a bottom tray (P9 review): the Funds on hand on the left and the
	# End of Week Payments on the right. The other styles stack everything in one column.
	var tray := UiStyle.current() == UiStyles.LIVING_OFFICE
	var funds_holder: Control = rows
	if tray:
		square.custom_minimum_size = TRAY_SIZE
		var row := HBoxContainer.new()
		row.name = "Tray"
		row.add_theme_constant_override("separation", 24)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.add_child(row)
		var funds_column := VBoxContainer.new()
		funds_column.name = "FundsColumn"
		funds_column.alignment = BoxContainer.ALIGNMENT_CENTER
		funds_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		funds_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(funds_column)
		row.add_child(rows)
		funds_holder = funds_column
	else:
		square.add_child(rows)
	# Title, the total, its two parts, the Funds on hand, and (only when short) the warning.
	for spec: Array in [["TitleLine", &"SmallLabel"], ["TotalLine", &"HeaderLabel"],
			["PartsLine", &"SmallLabel"], ["FundsLine", &"SmallLabel"], ["ShortLine", &"SmallLabel"]]:
		var label := Label.new()
		label.name = spec[0]
		label.theme_type_variation = spec[1]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		(funds_holder if (tray and spec[0] == "FundsLine") else rows).add_child(label)
	# Bottom right of whatever holds it, growing up and to the left.
	square.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	square.grow_vertical = Control.GROW_DIRECTION_BEGIN
	square.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	return square


## The lines from the run: what the week's end will take, in two parts, and the Funds on hand.
static func refresh(square: PanelContainer) -> void:
	if square == null:
		return
	var preview := GameState.week_end_preview()
	var pay: Dictionary = preview["payments"]
	var dues_total := int((pay["dues"] as Dictionary)["total"])
	(square.find_child("TitleLine", true, false) as Label).text = Text.say("office.week_payments_title")
	(square.find_child("TotalLine", true, false) as Label).text = WeekPaymentsView.yen(int(pay["total"]))
	var parts := Text.say("office.week_payments_parts_none", {"dues": Phrase.with_separators(dues_total)})
	if (pay["wages"] as Array).size() > 0:
		parts = Text.say("office.week_payments_parts", {"dues": Phrase.with_separators(dues_total),
			"wages": Phrase.with_separators(int(pay["wages_total"]))})
	(square.find_child("PartsLine", true, false) as Label).text = parts
	(square.find_child("FundsLine", true, false) as Label).text = Text.say("dues.box_funds",
		{"funds": Phrase.with_separators(int(preview["funds"]["now"]))})
	var short := WeekPaymentsView.short_line(pay)
	var short_label := square.find_child("ShortLine", true, false) as Label
	short_label.text = short
	short_label.visible = not short.is_empty()
	var colour := WARNING_RED if not short.is_empty() else UiStyle.plate_ink()
	for line: String in ["TotalLine", "ShortLine"]:
		(square.find_child(line, true, false) as Label).add_theme_color_override("font_color", colour)


## Compact or full height, the same as the calendar square beside it.
static func set_compact(square: PanelContainer, on: bool) -> void:
	if square == null:
		return
	square.custom_minimum_size.y = CalendarSquare.COMPACT_HEIGHT if on else SIZE.y
	(square.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(8 if on else 14)
