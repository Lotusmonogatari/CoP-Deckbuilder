extends Node
## Throwaway screenshot driver for the Staff Assignments screen (2026-11-16).
## xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . audit/tests/shot_staff.tscn

var out_dir := OS.get_environment("SHOT_DIR") if OS.has_environment("SHOT_DIR") else "/tmp/claude-0/shots"


func _ready() -> void:
	_run.call_deferred()


func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])


var _office_node: Node


func _office() -> Node:
	return _office_node


func _scroll_to(panel: Overlay, y: int) -> void:
	var scroll := panel.find_child("Scroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = y
	await get_tree().process_frame


func _task_uid(task_id: String) -> String:
	for entry: Dictionary in GameState.staff_day_pool:
		if str(entry["task_id"]) == task_id:
			return str(entry["uid"])
	return ""


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 900000
	GameState.meta["Reputation"] = 50
	GameState.staff_recruitment_tier = 2
	for id: String in ["SF04", "SF08", "SF18"]:
		GameState.hire_staff(id)
	GameState.staff_loyalty["SF04"] = 62
	GameState.staff_loyalty["SF08"] = 28
	GameState.staff_loyalty["SF18"] = 85
	for org: String in ["BO16", "BO21", "BO17", "BO08", "BO26", "BO18", "BO06", "BO27"]:
		GameState.booster_standing[org] = 70
	_office_node = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child(_office_node)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	var office := _office()
	# A fixed pool that shows every kind of task, so the shots are not luck.
	GameState.staff_ensure_day()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var wanted := ["TK17", "TK11", "TK10", "TK04", "TK05", "TK07", "TK09", "TK14"]
	var pool: Array[Dictionary] = []
	var targets := GameState._staff_task_targets()
	for i in wanted.size():
		var task := StaffTasks.task_for(DataDB.staff_tasks, wanted[i])
		var named: Dictionary = {}
		if task["kind"] != "plain" and task["kind"] != "time_off":
			named = (targets[task["kind"]] as Array)[0]
		pool.append(StaffTasks._entry(task, i, named))
	GameState.staff_day_pool = pool
	GameState.staff_day_plan = {}

	office._show_staff_assignments()
	await _shot("1_assignments_start")

	var assign: Overlay = office.get_node("AssignmentsPanel")
	await _scroll_to(assign, 520)
	await _shot("1b_assignments_cards")

	# Give out tasks: strong, fair and poor fits, and a time off.
	GameState.staff_assign(_task_uid("TK04"), "SF08")    # review the news: strong for media (restless -> fair)
	GameState.staff_assign(_task_uid("TK05"), "SF04")    # whitepaper: strong for research
	GameState.staff_assign(_task_uid("TK10"), "SF18")    # greet constituents: strong for district
	GameState.staff_assign(_task_uid("TK11"), "SF08")    # casework: poor for media
	GameState.staff_assign(_task_uid("TK17"), "SF04")    # time off
	office._show_staff_assignments()
	await _scroll_to(assign, 0)
	await _shot("2_assignments_given")
	await _scroll_to(assign, 560)
	await _shot("2b_assignments_cards_given")
	await _scroll_to(assign, 5000)
	await _shot("2c_assignments_projection")

	office._on_task_tapped(_task_uid("TK11"))
	await _shot("3_popup_casework")
	var popup: Overlay = office.get_node("TaskPopupPanel")
	await _scroll_to(popup, 700)
	await _shot("3b_popup_casework_people")
	popup.close()
	office._on_task_tapped(_task_uid("TK07"))
	await _shot("4_popup_org_meeting")
	popup.close()

	# Confirm, let the day pass, and show the report.
	GameState.staff_confirm_day()
	office._show_staff_assignments()
	await _scroll_to(assign, 5000)
	await _shot("5_confirmed")
	assign.close()
	GameState.spend_hours(8)
	office._build()
	await _shot("6_day_report")
	await _scroll_to(office.get_node("StaffReportPanel"), 600)
	await _shot("6b_day_report_totals")
	get_tree().quit(0)
