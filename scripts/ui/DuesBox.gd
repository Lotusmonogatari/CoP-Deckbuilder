class_name DuesBox
extends RefCounted
## The Office's dues box (2026-10-28, Cameron): one gold-edged line beside the
## calendar square, "Party Dues: 12,000 / Office Funds: 80,000", so the player
## can see at a glance what the party will ask for and what is in the till.
##
## Built in code like CalendarSquare, so the Office scene needs no edit. It
## sits in the Office's unused lower space, bottom right.

const SIZE := Vector2(560, 170)


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
	var label := Label.new()
	label.name = "DuesFundsLine"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	square.add_child(label)
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
	(square.get_node("DuesFundsLine") as Label).text = Text.say("dues.box", {
		"dues": Phrase.with_separators(int(due["total"])),
		"funds": Phrase.with_separators(int(due["funds"]))})
