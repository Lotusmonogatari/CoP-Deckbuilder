class_name PartyLabel
extends RefCounted
## A party's name in its own colour, on a plate that makes it readable (panel P4, item 4,
## 2026-11-17). The colour is canon and is not touched; a rounded near-white or near-black
## plate (PartyDisplay.plate_for) goes behind the text so it reaches 4.5 to 1.


## Colours `label` with `party`'s colour (a Parties row) and sets it on its plate.
static func apply(label: Label, party: Dictionary) -> void:
	var colour := PartyDisplay.color_for(party)
	label.add_theme_color_override("font_color", colour)
	var plate := StyleBoxFlat.new()
	plate.bg_color = PartyDisplay.plate_for(colour)
	plate.set_corner_radius_all(8)
	plate.content_margin_left = 14.0
	plate.content_margin_right = 14.0
	plate.content_margin_top = 4.0
	plate.content_margin_bottom = 4.0
	label.add_theme_stylebox_override("normal", plate)
