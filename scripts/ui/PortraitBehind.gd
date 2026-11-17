class_name PortraitBehind
extends Node
## A character picture that keeps its drawn size when the screen is short (panel P3,
## 2026-11-17, Cameron: "don't minimize the character images; if the screen must compact,
## put the image behind the text").
##
## The picture is lifted out of the screen's column and drawn behind it, and a plain slot of
## the picture's own minimum height takes its place in the column. The picture follows the
## slot's top edge and is never smaller than `full_height`; when the column squeezes the
## slot, the text beneath simply lies over the lower part of the picture (each text block
## carries its own translucent plate). With room to spare the slot is as tall as the
## picture and nothing looks different.
##
##     var behind := PortraitBehind.attach(self, %Portrait, $Safe)
##     behind.slot.custom_minimum_size.y = 240.0     # the column may now squeeze the slot

var portrait: Control
var slot: Control
var full_height := 0.0


## Lifts `portrait` out of its container, behind `safe` (the screen's content), and leaves a
## slot with its layout properties in its place.
static func attach(screen: Control, picture: Control, safe: Control) -> PortraitBehind:
	var helper := PortraitBehind.new()
	helper.name = "PortraitBehind"
	helper.portrait = picture
	helper.full_height = picture.custom_minimum_size.y
	var slot_box := Control.new()
	slot_box.name = "PortraitSlot"
	slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_box.custom_minimum_size = picture.custom_minimum_size
	slot_box.size_flags_horizontal = picture.size_flags_horizontal
	slot_box.size_flags_vertical = picture.size_flags_vertical
	slot_box.size_flags_stretch_ratio = picture.size_flags_stretch_ratio
	var parent := picture.get_parent()
	var index := picture.get_index()
	parent.add_child(slot_box)
	parent.move_child(slot_box, index)
	helper.slot = slot_box
	picture.reparent(screen, false)
	screen.move_child(picture, safe.get_index())
	picture.set_anchors_preset(Control.PRESET_TOP_LEFT)
	picture.custom_minimum_size = Vector2.ZERO
	screen.add_child(helper)
	return helper


func _process(_delta: float) -> void:
	if portrait == null or slot == null:
		return
	slot.visible = portrait.visible
	if slot.size.x <= 0.0:
		return
	portrait.global_position = slot.global_position
	portrait.size = Vector2(slot.size.x, maxf(slot.size.y, full_height))
