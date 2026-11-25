extends GutTest
## Staff tasks and items are given by tapping the card and choosing the person in its popup (2026-11-25): a tester's phone could
## not drag, so a card is no longer draggable at all, and a tap on it must open the popup.


func _tap(chip: TaskChip) -> void:
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.global_position = Vector2(20, 20)
		chip._gui_input(click)


func test_a_task_card_has_nothing_to_drag() -> void:
	var chip := TaskChip.new()
	chip.setup("T0", "Review the news", "LL02", 1, Color.GOLD, false, true, "")
	add_child_autofree(chip)
	assert_false(chip.has_method("_get_drag_data"), "dragging is gone")
	assert_false(chip.has_method("drag_preview"))


func test_an_item_card_has_nothing_to_drag() -> void:
	var chip := TaskChip.new()
	chip.setup_item("SH04", "Coffee", "coffee", "+1 hour", Color.WHITE, false, true)
	add_child_autofree(chip)
	assert_false(chip.has_method("_get_drag_data"))


func test_tapping_a_task_or_an_item_says_so() -> void:
	var task := TaskChip.new()
	task.setup("T0", "Review the news", "LL02", 1, Color.GOLD, false, true, "")
	add_child_autofree(task)
	watch_signals(task)
	_tap(task)
	assert_signal_emitted_with_parameters(task, "tapped", ["T0"])
	var item := TaskChip.new()
	item.setup_item("SH04", "Coffee", "coffee", "+1 hour", Color.WHITE, false, true)
	add_child_autofree(item)
	watch_signals(item)
	_tap(item)
	assert_signal_emitted_with_parameters(item, "tapped", ["ITEM:SH04"])


func test_a_task_box_only_shows_what_it_holds() -> void:
	var box := TaskBox.new()
	box.setup("ST01")
	add_child_autofree(box)
	assert_false(box.has_method("_can_drop_data"), "nothing is dropped into it")
	assert_false(box.has_signal("dropped"))


func test_a_gift_shows_the_person_beside_the_gift_with_its_words() -> void:
	var scene := StaffAssignmentsView.gift_scene({"staff_id": "ST01", "item_id": "SH04", "text": "You hand Coffee to Someone. Someone loves it. Loyalty +4."})
	add_child_autofree(scene)
	assert_not_null(scene.find_child("GiftPerson", true, false), "the person")
	assert_not_null(scene.find_child("GiftPicture", true, false), "the gift beside them")
	assert_eq((scene.find_child("GiftText", true, false) as Label).text, "You hand Coffee to Someone. Someone loves it. Loyalty +4.")
