class_name VisitLayout
extends RefCounted
## The layout shared by Office Hours, the member visit and the lobbyist trade
## (Cameron's sketches, 2026-11-07; shared with the visit and the trade
## 2026-11-13): the person's picture is big and centered, filling the office
## window, with the name box over its top left corner; the question and the
## choices sit below the window in the plain panel, and the spoken line pops
## up over them. The scene is the same for all three, so one function lays it
## out.

## The name box and the picture beside it.
const NAME_BOX_WIDTH := 260.0
const PICTURE_WIDTH := 760.0


## Lays `screen` out. `name_label` is the person's name (its parent box is
## floated over the picture), `portrait` the picture, `background` the room
## window and `banner` the spoken-line layer (may be null).
##
## `fit_to_content` (the lobbyist trade, 2026-11-13) makes the picture take
## exactly the height the rest of the screen leaves it, and moves the room
## picture's lower edge up to meet it, so a screen with more lines (a leverage
## bar, a Walk away button) still shows everything. The picture may then be
## shorter than in Office Hours; the name box simply sits over its corner.
static func fit(screen: Control, name_label: Label, portrait: Control,
		background: Control, continue_button: Control, banner: CueBanner,
		fit_to_content: bool = false) -> void:
	if not screen.is_inside_tree():
		return
	var header := screen.get_node("Safe/Column/Header") as Control
	var column := screen.get_node("Safe/Column") as VBoxContainer
	var gap := float(column.get_theme_constant("separation"))
	var top := screen.get_global_rect().position.y
	var screen_height := screen.get_viewport_rect().size.y
	var row_top := header.get_global_rect().end.y - top + gap
	# The window's bottom edge comes from its own anchor, not a measured
	# rectangle, so it is right even before the first layout pass has run.
	var window_bottom := background.anchor_bottom * screen_height
	var picture_bottom := window_bottom - gap
	if fit_to_content:
		picture_bottom = row_top + _room_for_picture(screen, column, portrait, row_top, gap, screen_height)
		window_bottom = picture_bottom + gap
		_move_window_edge(screen, background, window_bottom / screen_height)

	# The name box leaves the row and floats over the picture's top left corner.
	var details := name_label.get_parent() as Control
	if details.get_parent() != screen:
		details.reparent(screen, false)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.custom_minimum_size.x = NAME_BOX_WIDTH
	details.size = Vector2(NAME_BOX_WIDTH, 0.0)
	details.position = Vector2(column.get_global_rect().position.x - screen.get_global_rect().position.x, row_top)

	portrait.custom_minimum_size = Vector2(PICTURE_WIDTH, maxf(picture_bottom - row_top, 300.0))
	portrait.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER

	# The question starts right under the window; no spacer is needed.
	var band_gap := column.get_node_or_null("BandGap") as Control
	if band_gap != null:
		band_gap.custom_minimum_size.y = 0.0

	# The spoken line pops up over the choices: centered between the bottom of
	# the window and the top of Continue.
	var safe := screen.get_node("Safe") as MarginContainer
	var choices_bottom := screen_height - float(safe.get_theme_constant("margin_bottom")) \
		- continue_button.custom_minimum_size.y
	if banner != null and choices_bottom > window_bottom:
		banner.set_centre((window_bottom + choices_bottom) / 2.0 / screen_height)


## The height the picture can have: everything under the header and the
## picture row (their own minimum heights and the gaps) comes off what is left
## of the screen, never below a small floor and never above the usual height.
static func _room_for_picture(screen: Control, column: Control, portrait: Control,
		row_top: float, gap: float, screen_height: float) -> float:
	var row := portrait.get_parent() as Control
	var below := 0.0
	var seen_row := false
	for child: Node in column.get_children():
		if child == row:
			seen_row = true
			continue
		if seen_row and child is Control and (child as Control).visible:
			below += (child as Control).get_combined_minimum_size().y + gap
	var safe := screen.get_node("Safe") as MarginContainer
	var bottom := screen_height - float(safe.get_theme_constant("margin_bottom"))
	return clampf(bottom - row_top - below, 260.0, screen_height)


## Moves the room picture's lower edge, its dimming layer and the plain panel's
## upper edge to the same place (a share of the screen's height).
static func _move_window_edge(screen: Control, background: Control, share: float) -> void:
	background.anchor_bottom = share
	var scrim := screen.get_node_or_null("BackgroundScrim") as Control
	if scrim != null:
		scrim.anchor_bottom = share
	var panel := screen.get_node_or_null("BackgroundPanel") as Control
	if panel != null:
		panel.anchor_top = share
