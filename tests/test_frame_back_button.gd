extends GutTest
## The "‹ Office" control keeps its width after a pop-up card has been open on the same panel (a tester's report, 2026-11-24): the card wraps the
## buttons it borrows, and the Back button used to come back one letter wide and many lines tall, so it could not be seen or tapped.


func _back_of(office: Node) -> Button:
	return (office.get_node("InventoryPanel") as Overlay).find_child("Back", true, false) as Button


func test_back_stays_one_line_after_a_card_then_the_frame_again() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	office._show_marketplace()
	await get_tree().process_frame
	var width_before := _back_of(office).size.x
	assert_gt(width_before, 100.0, "the Back control has its text's width")
	(office.get_node("InventoryPanel") as Overlay).open_card({"tag": "T", "title": "x", "body": [] as Array[Control]}, "Go", "Close")
	await get_tree().process_frame
	office._show_marketplace()
	await get_tree().process_frame
	await get_tree().process_frame
	var back := _back_of(office)
	assert_eq(back.text, Text.say("ui.back_office"))
	assert_gt(back.size.x, 100.0, "still as wide as its text after the card")
	assert_lt(back.size.y, 200.0, "and one line tall, not stacked letter by letter")
