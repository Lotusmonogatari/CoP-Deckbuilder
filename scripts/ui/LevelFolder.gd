class_name LevelFolder
extends RefCounted
## A level in the Levels list as a manila folder (Living Office, P9, 2026-11-17): the first room's
## picture clipped to the left, then the level's name, how many hours it takes, and its button (or
## the reason it cannot be started). A folder that cannot be started is dimmed.
##
## Draws only. The row it wraps (OfficeScreen._level_row_plain) still decides what the button says and
## whether it works, so the refusal text and the rules are the same in every style.


## Wraps `row` (the name line and the button) in a folder with the level's picture.
static func wrap(row: Control, level: Dictionary) -> Control:
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
