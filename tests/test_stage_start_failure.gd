extends GutTest
## A stage that cannot start must offer a way out (review 2026-10-14).


func test_the_notice_shows_the_reason_and_a_leave_button() -> void:
	var screen := Control.new()
	add_child_autofree(screen)
	var cover := StageStartFailure.show_on(screen, "Because reasons.")
	assert_eq(cover.get_parent(), screen)
	var leave := cover.find_child("LeaveButton", true, false) as Button
	assert_not_null(leave)
	assert_eq(leave.text, Text.say("stage.cannot_start_leave"))
	var texts: Array = []
	for label in cover.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	assert_true("Because reasons." in texts)
