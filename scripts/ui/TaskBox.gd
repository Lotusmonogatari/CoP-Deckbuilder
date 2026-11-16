class_name TaskBox
extends PanelContainer
## The place on a staff card where task chips are dropped. Accepts a dragged
## task when GameState says it fits the person's day. Cameron, 2026-11-16.

signal dropped(uid: String, staff_id: String)
## An item for staff (coffee, tea) was dropped here.
signal item_dropped(item_id: String, staff_id: String)

var staff_id := ""


func setup(id: String) -> void:
	staff_id = id
	name = "TaskBox_" + id
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.35)
	box.border_color = Color(0.78, 0.64, 0.29, 0.55)
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(8)
	add_theme_stylebox_override("panel", box)
	custom_minimum_size = Vector2(0, 100)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and (data as Dictionary).has("item"):
		return GameState.staff_item_refusal(str((data as Dictionary)["item"]), staff_id).is_empty()
	if not (data is Dictionary) or not (data as Dictionary).has("uid") or staff_id == GameState.OFFICE_BOX:
		return false
	var uid := str((data as Dictionary)["uid"])
	var refusal := GameState.staff_assign_refusal(uid, staff_id)
	if refusal == StaffTasks.REFUSE_TAKEN:
		# Moving it between people is allowed; dropping it where it already is is not.
		return not (GameState.staff_day_plan.get(staff_id, []) as Array).has(uid)
	return refusal.is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if (data as Dictionary).has("item"):
		item_dropped.emit(str((data as Dictionary)["item"]), staff_id)
		return
	dropped.emit(str((data as Dictionary)["uid"]), staff_id)
