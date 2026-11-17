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
## The compact square (a short screen or a big text size): 100 px tall, no weekday row.
const COMPACT_HEIGHT := 100.0


## The square, empty; refresh() fills it from the run.
static func make() -> PanelContainer:
	if UiStyle.current() == UiStyles.LIVING_OFFICE:
		return _make_page()
	var square := PanelContainer.new()
	square.name = "CalendarSquare"
	square.custom_minimum_size = SIZE
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	var plate := UiStyle.plate_colour()
	box.bg_color = Color(plate.r, plate.g, plate.b, 0.92)
	# Gold in Living Office and Broadcast; the red of a seal in Woodblock.
	box.border_color = UiStyle.colour("vermilion", CueBanner.EDGE_COLOUR) if UiStyle.current() == UiStyles.WOODBLOCK else CueBanner.EDGE_COLOUR
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


## Living Office draws the calendar as a page-a-day (P9 review): a red header strip with the weekday, the
## date and the hours left on paper, and a curled corner. The same three lines as the square, from the
## same places: GameState.calendar_date_text() and calendar_weekday_text() already follow the equipped
## calendar style, so the page shows Era years (平成30年10月1日, weekday in kanji) or the Ainu form
## (2018.イノミチュㇷ゚.01) exactly as the square does.
static func _make_page() -> PanelContainer:
	var page := PanelContainer.new()
	page.name = "CalendarSquare"
	page.custom_minimum_size = SIZE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := UiStyle.colour("paper", Color(1, 0.97, 0.92))
	var ink := UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07))
	var box := StyleBoxFlat.new()
	box.bg_color = paper
	box.border_color = Color(ink.r, ink.g, ink.b, 0.45)
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(0)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 8
	page.add_theme_stylebox_override("panel", box)
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(rows)
	# The red header strip: the weekday (collapses to a thin strip when there is none, or when compact).
	var header := PanelContainer.new()
	header.name = "CalendarHeader"
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var red := StyleBoxFlat.new()
	red.bg_color = UiStyle.colour("warning", Color(0.7, 0.15, 0.12))
	red.corner_radius_top_left = 8
	red.corner_radius_top_right = 8
	red.content_margin_left = 12.0
	red.content_margin_right = 12.0
	red.content_margin_top = 4.0
	red.content_margin_bottom = 4.0
	header.add_theme_stylebox_override("panel", red)
	header.custom_minimum_size.y = 18.0
	rows.add_child(header)
	var weekday := Label.new()
	weekday.name = "CalendarWeekday"
	weekday.theme_type_variation = &"SmallLabel"
	weekday.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weekday.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weekday.add_theme_color_override("font_color", paper)
	weekday.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	header.add_child(weekday)
	var body := MarginContainer.new()
	body.name = "CalendarBody"
	body.add_theme_constant_override("margin_left", 12)
	body.add_theme_constant_override("margin_right", 12)
	body.add_theme_constant_override("margin_top", 8)
	body.add_theme_constant_override("margin_bottom", 10)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(body)
	var lines := VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(lines)
	for row_name: String in ["CalendarDate", "CalendarHours"]:
		var label := Label.new()
		label.name = row_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # an era or Ainu date can be long
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", ink)
		label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		if row_name != "CalendarDate":
			label.theme_type_variation = &"SmallLabel"
		lines.add_child(label)
	var curl := StyleMarks.make(StyleMarks.Kind.CURL, Color(ink.r, ink.g, ink.b, 0.5), Vector2.ZERO,
		UiStyle.colour("paper_alt", Color(0.95, 0.89, 0.76)))
	curl.name = "PageCurl"
	page.add_child(curl)
	page.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	page.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return page


## The two rows from the run's calendar.
static func refresh(square: PanelContainer) -> void:
	if square == null:
		return
	(square.find_child("CalendarDate", true, false) as Label).text = GameState.calendar_date_text()
	(square.find_child("CalendarHours", true, false) as Label).text = GameState.calendar_hours_text()
	var weekday := square.find_child("CalendarWeekday", true, false) as Label
	weekday.text = GameState.calendar_weekday_text()
	weekday.visible = not weekday.text.is_empty() and not bool(square.get_meta("compact", false))   # the Ainu calendar has two levels only


## Compact or full height (the Office turns it on when the front page does not fit).
static func set_compact(square: PanelContainer, on: bool) -> void:
	if square == null:
		return
	square.set_meta("compact", on)
	square.custom_minimum_size.y = COMPACT_HEIGHT if on else SIZE.y
	# The page has its own margins (a header strip and a body); the square pads itself.
	if not square.has_node("Rows/CalendarHeader"):
		(square.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(8 if on else 14)
	refresh(square)
