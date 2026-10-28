class_name DuesBox
extends RefCounted
## The Office's dues box (2026-10-28, Cameron): two stacked lines in a gold-edged box beside the
## calendar square, "Party Dues: 12,000" over "Office Funds: 80,000", so the player
## can see at a glance what the party will ask for and what is in the till.
##
## Built in code like CalendarSquare, so the Office scene needs no edit. It
## sits in the Office's unused lower space, bottom right.

const SIZE := Vector2(400, 170)


## The box, empty; refresh() fills it from the run.
static func make() -> PanelContainer:
	var square := PanelContainer.new()
	square.name = "DuesBox"
	square.custom_minimum_size = SIZE
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	box.border_color = CueBanner.EDGE_COLOUR
	box.set_border_width_all(CalendarSquare.EDGE_WIDTH)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(14)
	square.add_theme_stylebox_override("panel", box)
	# Two lines on two levels, as the calendar square stacks its rows.
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	square.add_child(rows)
	for row_name: String in ["DuesLine", "FundsLine"]:
		var label := Label.new()
		label.name = row_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(label)
	# Bottom right of whatever holds it, growing up and to the left.
	square.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	square.grow_vertical = Control.GROW_DIRECTION_BEGIN
	square.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	return square


## The line from the run: what the party would ask for today (this week's
## dues plus anything carried over) and the Funds on hand.
static func refresh(square: PanelContainer) -> void:
	if square == null:
		return
	var due := GameState.dues_preview()
	(square.get_node("Rows/DuesLine") as Label).text = Text.say("dues.box_dues",
		{"dues": Phrase.with_separators(int(due["total"]))})
	(square.get_node("Rows/FundsLine") as Label).text = Text.say("dues.box_funds",
		{"funds": Phrase.with_separators(int(due["funds"]))})
