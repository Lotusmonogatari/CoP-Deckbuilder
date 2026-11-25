extends GutTest
## The Staff Assignments screen builds from the run without error and says what
## the plan will do (Cameron, 2026-11-16).

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 900000
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 9   # past the ramp-up: tasks are delivered
	for id: String in ["SF04", "SF08", "SF18"]:
		GameState.hire_staff(id)
	GameState.staff_ensure_day()
	_fix_pool()


func _handlers() -> Dictionary:
	return {"popup": func(_uid: String) -> void: pass, "dropped": func(_uid: String, _id: String) -> void: pass,
		"profile": func(_id: String) -> void: pass, "confirm": func() -> void: pass,
		"assign": func(_uid: String, _id: String) -> void: pass, "unassign": func(_uid: String) -> void: pass,
		"item_dropped": func(_item: String, _id: String) -> void: pass,
		"assign_item": func(_item: String, _id: String) -> void: pass, "unassign_item": func(_id: String) -> void: pass}


func _free(nodes: Array[Control]) -> void:
	for node: Control in nodes:
		node.free()


func test_the_first_week_with_no_staff_says_so() -> void:
	GameState.start_new_run("PC01")
	var rows := StaffAssignmentsView.rows(_handlers())
	assert_eq(rows.size(), 2, "no tasks today, and a word about hiring")
	_free(rows)


func test_with_no_staff_the_days_tasks_can_be_read_but_not_given_out() -> void:
	GameState.start_new_run("PC01")
	GameState.calendar["week"] = 9
	GameState.staff_ensure_day()
	_fix_pool()
	var rows := StaffAssignmentsView.rows(_handlers())
	var chips := 0
	var giveable := 0
	for row: Control in rows:
		for chip in row.find_children("Task_*", "TaskChip", true, false):
			chips += 1
			if (chip as TaskChip).giveable:
				giveable += 1
	assert_eq(chips, 8, "the tasks are shown")
	assert_eq(giveable, 0, "but nobody can be given one")
	_free(rows)


func test_the_screen_shows_every_task_and_every_person() -> void:
	var rows := StaffAssignmentsView.rows(_handlers())
	var chips := 0
	var cards := 0
	for row: Control in rows:
		for node in row.find_children("Task_*", "TaskChip", true, false):
			chips += 1
		if row.name.begins_with("StaffCard_"):
			cards += 1
	assert_eq(chips, 8, "all eight tasks wait in the tray")
	assert_eq(cards, 3)
	_free(rows)


func test_a_given_task_moves_from_the_tray_into_the_persons_box() -> void:
	var uid := str(GameState.staff_day_pool[0]["uid"])
	GameState.staff_assign(uid, "SF04")
	var rows := StaffAssignmentsView.rows(_handlers())
	var in_tray := 0
	var in_box := 0
	for row: Control in rows:
		for node in row.find_children("Task_" + uid, "TaskChip", true, false):
			if row.name == "TaskTray":
				in_tray += 1
			elif row.name.begins_with("StaffCard_"):
				in_box += 1
	assert_eq(in_tray, 0)
	assert_eq(in_box, 1)
	_free(rows)


func test_the_workload_bar_has_eight_blocks_and_drains() -> void:
	var bar := StaffAssignmentsView.blocks_bar(3, 8)
	assert_eq(bar.get_child_count(), 8)
	var used := 0
	for block in bar.get_children():
		if (block as ColorRect).color == StaffAssignmentsView.BLOCK_USED:
			used += 1
	assert_eq(used, 3)
	bar.free()


func _find(rows: Array[Control], node_name: String) -> Array:
	var found: Array = []
	for row: Control in rows:
		if row.name == node_name:
			found.append(row)
		found.append_array(row.find_children(node_name, "", true, false))
	return found


func test_the_popup_shows_three_result_blocks_and_one_picture_per_person() -> void:
	var uid := ""
	for entry: Dictionary in GameState.staff_day_pool:
		if entry["task_id"] != "TK17":
			uid = str(entry["uid"])
	var rows := StaffAssignmentsView.popup_rows(uid, _handlers())
	for kind: String in ["strong", "fair", "poor"]:
		assert_eq(_find(rows, "Result_" + kind).size(), 1, kind + " block")
	for id: String in ["SF04", "SF08", "SF18"]:
		assert_eq(_find(rows, "GiveTo_" + id).size(), 1, id + " picture")
	assert_eq(_find(rows, "StaffScroll").size(), 1, "the row scrolls sideways")
	_free(rows)


func test_result_blocks_name_no_staff_role() -> void:
	var uid := str(GameState.staff_day_pool[1]["uid"])
	var rows := StaffAssignmentsView.popup_rows(uid, _handlers())
	for kind: String in ["strong", "fair", "poor"]:
		for block in _find(rows, "Result_" + kind):
			for label in block.find_children("*", "Label", true, false):
				for role in ["Policy Research Assistant", "Media Spokesperson", "District Representative"]:
					assert_false((label as Label).text.contains(role), "no role in the " + kind + " block")
	_free(rows)


func test_no_assignment_is_greyed_until_the_task_is_given() -> void:
	var uid := str(GameState.staff_day_pool[1]["uid"])
	var rows := StaffAssignmentsView.popup_rows(uid, _handlers())
	assert_true((_find(rows, "NoAssignmentButton")[0] as Button).disabled)
	_free(rows)
	GameState.staff_assign(uid, "SF04")
	rows = StaffAssignmentsView.popup_rows(uid, _handlers())
	assert_false((_find(rows, "NoAssignmentButton")[0] as Button).disabled)
	_free(rows)


func test_a_person_with_a_full_day_is_dimmed() -> void:
	GameState.staff_day_delegated["SF04"] = 8
	var uid := ""
	for entry: Dictionary in GameState.staff_day_pool:
		uid = str(entry["uid"])
	var rows := StaffAssignmentsView.popup_rows(uid, _handlers())
	assert_true((_find(rows, "GiveTo_SF04")[0] as Button).disabled)
	assert_false((_find(rows, "GiveTo_SF08")[0] as Button).disabled)
	_free(rows)


func test_the_projection_names_what_would_change() -> void:
	var lines := StaffAssignmentsView.projection_lines(GameState.staff_projection(), GameState.staff_day_pool)
	assert_gt(lines.size(), 0)


func test_confirm_is_greyed_with_a_reason_until_something_is_given_out() -> void:
	var rows := StaffAssignmentsView.rows(_handlers())
	var confirm: Button = null
	for row: Control in rows:
		if row.name == "ConfirmDayButton":
			confirm = row as Button
	assert_not_null(confirm)
	assert_true(confirm.disabled)
	assert_eq(confirm.text, Text.say("assign.nothing_assigned"))
	_free(rows)


func test_the_report_reads_what_each_person_did() -> void:
	var uid := str(GameState.staff_day_pool[1]["uid"])
	GameState.staff_assign(uid, "SF04")
	GameState.staff_confirm_day()
	GameState.spend_hours(8)
	GameState.staff_day_sync()
	var report := GameState.take_staff_report()
	assert_false(report.is_empty())
	var rows := StaffAssignmentsView.report_rows(report)
	assert_gt(rows.size(), 2)
	_free(rows)


## A fixed day for tests that need particular tasks: eight known tasks (TK17 is time off).
func _fix_pool() -> void:
	var ids := ["TK17", "TK11", "TK10", "TK04", "TK05", "TK14", "TK06", "TK01"]
	var pool: Array = []
	for i in ids.size():
		pool.append(StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, ids[i]), i, {}))
	GameState.staff_day_pool = pool
