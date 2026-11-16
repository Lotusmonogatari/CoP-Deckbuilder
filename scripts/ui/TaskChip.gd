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

var uid := ""
var draggable := true
var _press_at := Vector2.ZERO
var _pressing := false
var _dragged := false
var _icon_id := ""


## `compact` is the small icon-only version shown inside a person's box.
func setup(task_uid: String, title: String, icon_id: String, blocks: int, frame: Color,
		compact: bool, can_drag: bool) -> void:
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
	if compact:
		custom_minimum_size = Vector2(104, 0)
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
	var preview := PlaceholderArt.new()
	preview.kind = PlaceholderArt.Kind.ICON
	preview.art_id = _icon_id
	preview.custom_minimum_size = Vector2(88, 88)
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	return {"uid": uid}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_pressing = false
