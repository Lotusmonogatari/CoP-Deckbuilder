class_name IconPlate
extends RefCounted
## A light plate under a row of small icons that would otherwise sit on dark rows (panel P4,
## item 4): the stage Details' Scrutiny, Pleased and Annoyed organization icons.

const PLATE := Color(0.94, 0.93, 0.90)


## `inner` inside a rounded light plate; returns the plate.
static func wrap(inner: Control) -> PanelContainer:
	var plate := PanelContainer.new()
	plate.name = "IconPlate"
	var box := StyleBoxFlat.new()
	box.bg_color = PLATE
	box.set_corner_radius_all(12)
	box.set_content_margin_all(10)
	plate.add_theme_stylebox_override("panel", box)
	plate.add_child(inner)
	return plate
