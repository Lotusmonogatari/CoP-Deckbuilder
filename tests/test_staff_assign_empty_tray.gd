extends GutTest
## Staff Assignments with every task given out (a tester's report, 2026-11-24): the message "Every task has been given out." must have a
## real width, not stack one letter per line inside the chip flow.


func test_the_empty_tray_message_is_a_wrapping_line_with_room_to_be_read() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.staff_day_pool = []
	var tray := StaffAssignmentsView._tray({}, {})
	add_child_autofree(tray)
	tray.size = Vector2(900, 0)
	await get_tree().process_frame
	assert_eq(tray.name, "TaskTray")
	var label := tray.get_child(0) as Label
	assert_eq(label.text, Text.say("assign.tray_empty"))
	assert_false(tray is HFlowContainer, "the message is not inside the chip flow")
	assert_gt(label.size.x, 300.0, "wide enough to read, not a letter wide")
