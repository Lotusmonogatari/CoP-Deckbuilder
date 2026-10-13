extends GutTest
## Long text in a panel wraps instead of running off the screen (2026-10-14):
## a title like "Host a District Walking Tour for a Constituency" used to widen
## the whole panel past the screen and bring up a sideways scrollbar.

const LONG := "Host a District Walking Tour for a Constituency and Several More Words To Be Certain"


func test_a_long_heading_label_and_button_never_widen_the_panel() -> void:
	var host := Control.new()
	host.size = Vector2(1080, 2340)
	add_child_autofree(host)
	var overlay := Overlay.new()
	host.add_child(overlay)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var label := Label.new()
	label.text = LONG + " " + LONG
	var button := Button.new()
	button.text = LONG + " " + LONG
	var row := HBoxContainer.new()
	var in_row := Label.new()
	in_row.text = LONG + " " + LONG
	row.add_child(in_row)
	var rows: Array[Control] = [label, button, row]
	overlay.open(LONG + " " + LONG, rows)
	await wait_frames(3)

	var scroll: ScrollContainer = overlay.find_child("Scroll", true, false)
	assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
	var column: Control = overlay.find_child("Column", true, false)
	assert_lte(column.size.x, 1000.5, "the column stays inside the screen")
	for text_node: Control in [label, button, in_row]:
		assert_lte(text_node.get_global_rect().end.x, 1080.0, "text stays on screen")
