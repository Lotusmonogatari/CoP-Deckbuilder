class_name LevelFolder
extends RefCounted
## A level in the Levels list as a manila folder (Living Office, P9, 2026-11-17): the first room's
## picture clipped to the left, then the level's name, how many hours it takes, and its button (or
## the reason it cannot be started). A folder that cannot be started is dimmed.
##
## Draws only. The row it wraps (OfficeScreen._level_row_plain) still decides what the button says and
## whether it works, so the refusal text and the rules are the same in every style.


## Wraps `row` for the style in use: a manila folder (Living Office), a schedule row with a gold hour
## chip (Broadcast) or a print card with a framed picture and a red seal (Woodblock). The row's own
## children (name, hours, button) are the same in every style; only the dressing differs.
static func wrap_for_style(row: Control, level: Dictionary) -> Control:
	match UiStyle.current():
		UiStyles.BROADCAST:
			return _schedule_row(row, level)
		UiStyles.WOODBLOCK:
			return _print_card(row, level)
	return folder(row, level)


## Broadcast: [gold hour chip] [name and button] [picture], on a navy strip with a gold edge.
static func _schedule_row(row: Control, level: Dictionary) -> Control:
	var strip := PanelContainer.new()
	strip.name = "Schedule_" + str(level.get("level_id", ""))
	var plate := UiStyle.plate_colour()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(plate.r, plate.g, plate.b, 0.96)
	box.border_color = UiStyle.colour("gold", Color(0.89, 0.7, 0.25))
	box.border_width_left = 10
	box.set_corner_radius_all(3)
	box.set_content_margin_all(12)
	strip.add_theme_stylebox_override("panel", box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	strip.add_child(line)
	var chip := _chip(row, UiStyle.colour("gold", Color(0.89, 0.7, 0.25)), UiStyle.colour("ground", Color(0.04, 0.07, 0.12)), 0)
	if chip != null:
		line.add_child(chip)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(row)
	line.add_child(_picture_node(level, Vector2(170, 130), 0, Color.TRANSPARENT))
	_dim_if_disabled(strip, row)
	return strip


## Woodblock: a framed picture, then the name, a red hours seal and the button, on a paper card.
static func _print_card(row: Control, level: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "Print_" + str(level.get("level_id", ""))
	var box := StyleBoxFlat.new()
	box.bg_color = UiStyle.colour("paper", Color(0.97, 0.94, 0.88))
	box.border_color = UiStyle.colour("ink", Color(0.11, 0.1, 0.09))
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	card.add_child(line)
	line.add_child(_picture_node(level, Vector2(190, 140), 6, UiStyle.colour("indigo", Color(0.13, 0.19, 0.35))))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(column)
	var seal := _chip(row, UiStyle.colour("vermilion", Color(0.76, 0.23, 0.13)), UiStyle.colour("paper", Color(0.97, 0.94, 0.88)), 1)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	if seal != null:
		seal.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		column.add_child(seal)
		column.move_child(seal, 0)
	_dim_if_disabled(card, row)
	return card


## Takes the row's hours line (its second child) out of the row and puts it in a coloured chip, so
## the words are the same as in the other styles.
static func _chip(row: Control, fill: Color, ink: Color, radius: int, chip_width: float = 130.0) -> Control:
	if row.get_child_count() < 3:
		return null
	var hours := row.get_child(1)
	row.remove_child(hours)
	var chip := PanelContainer.new()
	chip.name = "HoursChip"
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius * 3)
	box.set_content_margin_all(10)
	chip.add_theme_stylebox_override("panel", box)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if hours is Label:
		(hours as Label).add_theme_color_override("font_color", ink)
		(hours as Label).add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		# A minimum width, because the shared wrapping pass (UiKit.wrap_all) turns wrapping back on.
		(hours as Label).custom_minimum_size = Vector2(chip_width, 0)
		(hours as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(hours as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(hours)
	return chip


static func _picture_node(level: Dictionary, size: Vector2, frame: int, frame_colour: Color) -> Control:
	var picture := TextureRect.new()
	picture.name = "LevelPicture"
	picture.texture = _picture(level)
	picture.custom_minimum_size = size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.clip_contents = true
	if frame <= 0:
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return picture
	var framed := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = frame_colour
	box.set_content_margin_all(frame)
	framed.add_theme_stylebox_override("panel", box)
	framed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	framed.add_child(picture)
	return framed


static func _dim_if_disabled(wrapper: Control, row: Control) -> void:
	for child in row.find_children("*", "Button", true, false):
		if (child as Button).disabled:
			wrapper.modulate = Color(1, 1, 1, 0.72)
			return


## Wraps `row` (the name line and the button) in a folder with the level's picture.
static func folder(row: Control, level: Dictionary) -> Control:
	var folder := PanelContainer.new()
	folder.name = "Folder_" + str(level.get("level_id", ""))
	var paper := UiStyle.colour("paper_alt", Color(0.95, 0.89, 0.76))
	var tab := UiStyle.colour("accent", Color(1.0, 0.84, 0.54))
	var box := StyleBoxFlat.new()
	box.bg_color = paper
	box.set_corner_radius_all(14)
	box.border_color = tab
	box.border_width_left = 10
	box.set_content_margin_all(14)
	folder.add_theme_stylebox_override("panel", box)
	# Dark ink on paper for every label inside; the buttons keep their own boxes.
	var ink := UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07))
	var theme := Theme.new()
	theme.set_color("font_color", "Label", ink)
	theme.set_color("font_color", "SmallLabel", ink)
	theme.set_stylebox("normal", "Label", StyleBoxEmpty.new())
	folder.theme = theme

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	folder.add_child(line)
	var picture := TextureRect.new()
	picture.name = "FolderPicture"
	picture.texture = _picture(level)
	picture.custom_minimum_size = Vector2(190, 150)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.clip_contents = true
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(picture)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(row)

	for child in row.find_children("*", "Button", true, false):
		if (child as Button).disabled:
			folder.modulate = Color(1, 1, 1, 0.72)
			break
	return folder


## The picture of the level's first room, or null (a labelled placeholder is not wanted here).
static func _picture(level: Dictionary) -> Texture2D:
	for key: String in ["stage_1", "stage_2", "stage_3"]:
		var stage_id: Variant = level.get(key)
		if stage_id != null and not str(stage_id).is_empty():
			return ArtLoader.background(str(stage_id))
	return null
