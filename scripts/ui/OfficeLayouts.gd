class_name OfficeLayouts
extends RefCounted
## The Office's arrangement in Broadcast and Woodblock (P9, 2026-11-17), the counterpart of
## RoomObjects for Living Office. The same buttons are moved into a grid and restyled; nothing is
## added or renamed, so every destination, count and refusal reads the same in every style.
##
##   Broadcast: the Start button is a gold slanted bar; Events, Promises, Office Management and
##   Marketplace are a 2 x 2 grid of navy tiles; Reputation and Results is a wide bar with
##   Administration beside it.
##   Woodblock: the Start button is an indigo plank; the six destinations are a 3 x 2 grid of
##   paper plaques with indigo tops.
##
## Draws and arranges only. Heights are at least 122 px (44 pt).

const TILE_HEIGHT := 122.0
const GRID_NAME := "StyleTiles"


## `buttons`: events, promises, staff, marketplace, results, admin, start.
static func install(office: Control, buttons: Dictionary) -> void:
	var style := UiStyle.current()
	if style == UiStyles.LIVING_OFFICE or office.has_node(GRID_NAME):
		return
	var start: Button = buttons["start"]
	var column := start.get_parent()
	if column == null:
		return
	var grid := GridContainer.new()
	grid.name = GRID_NAME
	grid.columns = 2 if style == UiStyles.BROADCAST else 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(grid)
	column.move_child(grid, start.get_index() + 1)
	var order: Array = ["events", "promises", "staff", "marketplace"] if style == UiStyles.BROADCAST \
		else ["events", "promises", "staff", "marketplace", "results", "admin"]
	for key: String in order:
		var button: Button = buttons.get(key)
		if button != null:
			_into(button, grid, style)
	if style == UiStyles.BROADCAST:
		# Reputation and Results is a wide bar with Administration beside it.
		var bar := HBoxContainer.new()
		bar.name = "ResultsBar"
		bar.add_theme_constant_override("separation", 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(bar)
		column.move_child(bar, grid.get_index() + 1)
		for key: String in ["results", "admin"]:
			var button: Button = buttons.get(key)
			if button != null:
				_into(button, bar, style)
		var admin: Button = buttons.get("admin")
		if admin != null:
			admin.size_flags_horizontal = 0
			admin.custom_minimum_size.x = 300.0
	_style_start(start, style)


static func _into(button: Button, parent: Control, style: String) -> void:
	var was_unique := button.unique_name_in_owner
	var office: Node = button.owner
	if button.get_parent() != null:
		button.get_parent().remove_child(button)
	parent.add_child(button)
	if was_unique and office != null:
		button.owner = office
		button.unique_name_in_owner = true
	# A button that was pinned to a corner (Promises) is an ordinary tile now.
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, TILE_HEIGHT)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var plate := UiStyle.plate_colour()
	var box := StyleBoxFlat.new()
	if style == UiStyles.BROADCAST:
		box.bg_color = Color(plate.r, plate.g, plate.b, 0.96)
		box.border_color = UiStyle.colour("gold", Color(0.89, 0.7, 0.25))
		box.border_width_left = 10
		box.set_corner_radius_all(3)
	else:
		box.bg_color = Color(plate.r, plate.g, plate.b, 0.97)
		box.border_color = UiStyle.colour("indigo", Color(0.13, 0.19, 0.35))
		box.set_border_width_all(3)
		box.border_width_top = 16
		box.set_corner_radius_all(2)
	box.set_content_margin_all(14)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, box)


static func _style_start(start: Button, style: String) -> void:
	var box := StyleBoxFlat.new()
	var ink: Color
	if style == UiStyles.BROADCAST:
		box.bg_color = UiStyle.colour("gold", Color(0.89, 0.7, 0.25))
		box.skew = Vector2(SlantBar.SLANT, 0.0)
		box.set_corner_radius_all(2)
		ink = UiStyle.colour("ground", Color(0.04, 0.07, 0.12))
	else:
		box.bg_color = UiStyle.colour("indigo", Color(0.13, 0.19, 0.35))
		box.border_color = UiStyle.colour("vermilion", Color(0.76, 0.23, 0.13))
		box.border_width_right = 22
		box.set_corner_radius_all(2)
		ink = UiStyle.colour("paper", Color(0.97, 0.94, 0.88))
	box.set_content_margin_all(18)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		start.add_theme_stylebox_override(state, box)
	var dim := box.duplicate() as StyleBoxFlat
	dim.bg_color = Color(box.bg_color.r, box.bg_color.g, box.bg_color.b, 0.55)
	start.add_theme_stylebox_override("disabled", dim)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		start.add_theme_color_override(colour, ink)
	start.add_theme_color_override("font_disabled_color", Color(ink.r, ink.g, ink.b, 0.75))
