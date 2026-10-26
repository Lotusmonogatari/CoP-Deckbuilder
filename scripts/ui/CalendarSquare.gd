class_name CalendarSquare
extends RefCounted
## The Office's small calendar square (2026-10-23, Cameron): the date on the top
## row (YY.MM.DD since 2026-10-26), the hours left today in the middle, and the
## day of the week in English and Japanese on a third row, in a gold-edged box
## (the same gold as the title screen's buttons and the cue banner).
##
## Built in code like OrgChip, so the Office scene needs no edit. The square
## sits in the Office's unused lower space, bottom left.

const SIZE := Vector2(330, 170)
const EDGE_WIDTH := 4


## The square, empty; refresh() fills it from the run.
static func make() -> PanelContainer:
	var square := PanelContainer.new()
	square.name = "CalendarSquare"
	square.custom_minimum_size = SIZE
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	box.border_color = CueBanner.EDGE_COLOUR
	box.set_border_width_all(EDGE_WIDTH)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(14)
	square.add_theme_stylebox_override("panel", box)
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	square.add_child(rows)
	for row_name: String in ["CalendarDate", "CalendarHours", "CalendarWeekday"]:
		var label := Label.new()
		label.name = row_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if row_name != "CalendarDate":
			label.theme_type_variation = &"SmallLabel"
		rows.add_child(label)
	# Bottom left of whatever holds it, growing up and to the right.
	square.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	square.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return square


## The two rows from the run's calendar.
static func refresh(square: PanelContainer) -> void:
	if square == null:
		return
	(square.get_node("Rows/CalendarDate") as Label).text = GameState.calendar_date_text()
	(square.get_node("Rows/CalendarHours") as Label).text = GameState.calendar_hours_text()
	(square.get_node("Rows/CalendarWeekday") as Label).text = GameState.calendar_weekday_text()
