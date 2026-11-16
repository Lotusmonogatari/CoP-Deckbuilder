class_name TaskChip
extends PanelContainer
## One daily staff task as a small card: its icon family picture (a labelled
## LL## placeholder until it is drawn), its title and its block cost. It can be
## dragged into a person's TaskBox, or tapped to read about it. The coloured
## frame shows how well the person it was given to fits it (gold strong, grey
## fair, red poor); a task not yet given has a plain frame.
## Cameron, 2026-11-16 (design/proposals/STAFF_ASSIGNMENTS_2026-11-16.md).

## A press that barely moved and let go: the player wants to read it.
signal tapped(uid: String)

const TAP_SLOP := 24.0
const ITEM_PREFIX := "ITEM:"

var uid := ""
var draggable := true
var _press_at := Vector2.ZERO
var _pressing := false
var _dragged := false
var _icon_id := ""
## What is dragged: a task's uid, or an item ({"item": item_id}). Set by setup_item().
var payload: Dictionary = {}
var _item_texture: Texture2D


## `compact` is the small icon-only version shown inside a person's box.
func setup(task_uid: String, title: String, icon_id: String, blocks: int, frame: Color,
		compact: bool, can_drag: bool, caption: String = "") -> void:
	uid = task_uid
	draggable = can_drag
	_icon_id = icon_id
	name = "Task_" + task_uid
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The list this sits in scrolls by dragging; a press on a chip is the chip's own.
	add_to_group("drag_claimers")
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.13, 0.15, 0.2, 0.95)
	box.border_color = frame
	box.set_border_width_all(4)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(6)
	add_theme_stylebox_override("panel", box)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	var art := PlaceholderArt.new()
	art.kind = PlaceholderArt.Kind.ICON
	art.art_id = icon_id
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(88, 88) if compact else Vector2(110, 110)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(art)
	tooltip_text = title
	if compact:
		custom_minimum_size = Vector2(190, 0)
		# The family is named in words under the icon.
		if not caption.is_empty():
			var fit_label := Label.new()
			fit_label.text = caption
			fit_label.theme_type_variation = "SmallLabel"
			fit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(fit_label)
		return
	custom_minimum_size = Vector2(190, 0)
	var label := Label.new()
	label.text = title
	label.theme_type_variation = "SmallLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(170, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	var cost := Label.new()
	cost.text = Text.say("assign.blocks_one") if blocks == 1 else Text.say("assign.blocks_short", {"count": blocks})
	cost.theme_type_variation = "SmallLabel"
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.modulate = Color(1, 1, 1, 0.7)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cost)


## An item for staff (coffee, tea) as a card: its picture, name and the hours it
## adds, and how many are held. `compact` is the small version inside a person's
## box. Dragged into a box it carries {"item": item_id}; tapped it opens its popup
## (the uid is "ITEM:" and the item id, so one tap handler tells them apart).
func setup_item(item_id: String, title: String, icon_name: String, caption: String, frame: Color,
		compact: bool, can_drag: bool) -> void:
	uid = ITEM_PREFIX + item_id
	payload = {"item": item_id}
	draggable = can_drag
	_item_texture = ArtLoader.item_icon(icon_name)
	name = "Item_" + item_id
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("drag_claimers")
	tooltip_text = title
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.13, 0.15, 0.2, 0.95)
	box.border_color = frame
	box.set_border_width_all(4)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(6)
	add_theme_stylebox_override("panel", box)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	var picture := TextureRect.new()
	picture.texture = _item_texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2(88, 88) if compact else Vector2(110, 110)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(picture)
	custom_minimum_size = Vector2(130 if compact else 190, 0)
	if not compact:
		var label := Label.new()
		label.text = title
		label.theme_type_variation = "SmallLabel"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(170, 0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	var note := Label.new()
	note.text = caption
	note.theme_type_variation = "SmallLabel"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.modulate = Color(1, 1, 1, 0.8)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(note)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.pressed:
			_pressing = true
			_dragged = false
			_press_at = button.global_position
		else:
			var was_tap := _pressing and not _dragged and button.global_position.distance_to(_press_at) < TAP_SLOP
			_pressing = false
			if was_tap:
				tapped.emit(uid)
				accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	_dragged = true
	var preview: Control
	if payload.is_empty():
		var art := PlaceholderArt.new()
		art.kind = PlaceholderArt.Kind.ICON
		art.art_id = _icon_id
		preview = art
	else:
		var picture := TextureRect.new()
		picture.texture = _item_texture
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview = picture
	preview.custom_minimum_size = Vector2(88, 88)
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	return payload if not payload.is_empty() else {"uid": uid}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_pressing = false
