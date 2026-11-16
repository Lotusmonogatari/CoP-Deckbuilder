extends GutTest
## The Staff Assignments screen builds from the run without error and says what
## the plan will do (Cameron, 2026-11-16).

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 900000
	GameState.staff_recruitment_tier = 2
	for id: String in ["SF04", "SF08", "SF18"]:
		GameState.hire_staff(id)
	GameState.staff_ensure_day()


func _handlers() -> Dictionary:
	return {"popup": func(_uid: String) -> void: pass, "dropped": func(_uid: String, _id: String) -> void: pass,
		"profile": func(_id: String) -> void: pass, "confirm": func() -> void: pass,
		"assign": func(_uid: String, _id: String) -> void: pass, "unassign": func(_uid: String) -> void: pass}


func _free(nodes: Array[Control]) -> void:
	for node: Control in nodes:
		node.free()


func test_no_staff_says_to_hire_some() -> void:
	GameState.start_new_run("PC01")
	var rows := StaffAssignmentsView.rows(_handlers())
	assert_eq(rows.size(), 1)
	_free(rows)


func test_the_screen_shows_every_task_and_every_person() -> void:
	var rows := StaffAssignmentsView.rows(_handlers())
	var chips := 0
	var cards := 0
	for row: Control in rows:
		for node in row.find_children("*", "TaskChip", true, false):
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


func test_the_popup_lists_every_fit_and_who_can_take_it() -> void:
	var uid := str(GameState.staff_day_pool[1]["uid"])
	var rows := StaffAssignmentsView.popup_rows(uid, _handlers())
	var gives := 0
	for row: Control in rows:
		if row.name.begins_with("GiveTo_"):
			gives += 1
	assert_eq(gives, 3)
	_free(rows)


func test_a_full_day_greys_out_who_can_take_a_task() -> void:
	GameState.staff_day_delegated["SF04"] = 8
	var uid := ""
	for entry: Dictionary in GameState.staff_day_pool:
		uid = str(entry["uid"])
	var rows := StaffAssignmentsView.popup_rows(uid, _handlers())
	for row: Control in rows:
		if row.name == "GiveTo_SF04":
			assert_true((row as Button).disabled)
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
