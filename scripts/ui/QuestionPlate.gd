class_name QuestionPlate
extends RefCounted
## A plate behind the question a visitor, member or lobbyist asks (2026-11-18). The question sits on the
## plain lower panel, which is light in Living Office and Broadcast while their text is light too: it
## measured 1.0 to 1.2 to 1 (invisible). The style's own plate colour and ink put it back at full contrast,
## the same plate every other line of text on a picture uses.


static func apply(label: Label) -> void:
	var plate := UiStyle.plate_colour()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(plate.r, plate.g, plate.b, 0.94)
	box.set_corner_radius_all(14)
	box.content_margin_left = 18.0
	box.content_margin_right = 18.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	label.add_theme_stylebox_override("normal", box)
	label.add_theme_color_override("font_color", UiStyle.plate_ink())
