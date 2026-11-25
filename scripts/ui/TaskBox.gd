class_name TaskBox
extends PanelContainer
## The framed place on a staff card (or the Office box) where the tasks and items given to that person are shown.
## It only shows them: a task or an item is given by tapping it and choosing the person in its popup (a tester's phone
## could not drag, so dragging was taken out, 2026-11-25).

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
