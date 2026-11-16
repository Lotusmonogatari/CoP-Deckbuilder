extends GutTest
## Event delegation (Cameron, 2026-11-16): a choice that hands the job to a staff
## role asks who goes; how well they suit it sets the result.

const R := "Policy Research Assistant"


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 900000
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 9   # past the ramp-up: tasks are delivered
	assert_eq(GameState.hire_staff("SF04"), "")   # a researcher
	assert_eq(GameState.hire_staff("SF15"), "")   # a district representative
	GameState.staff_loyalty["SF04"] = 60
	GameState.staff_loyalty["SF15"] = 60
	GameState.booster_standing["BO23"] = 50
	GameState.staff_ensure_day()
	_fix_pool()


func _choice(event_id: String, letter: String) -> Dictionary:
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
		if str(row["choice"]) == letter:
			return row
	return {}


func test_the_existing_send_a_staff_member_choices_name_a_role() -> void:
	var named := 0
	for row: Dictionary in DataDB.event_choices:
		if StaffDelegation.is_delegation(str(row["choice_text"]), DataDB.rules.get("staff_delegation_phrases", [])):
			assert_ne(GameState.event_delegate_role(row), "", "%s %s names a role" % [row["event_id"], row["choice"]])
			named += 1
	assert_eq(named, 42)


func test_a_delegating_choice_needs_a_named_person() -> void:
	assert_false(bool(GameState.apply_event_choice("EV83", "B").get("ok", false)))


func test_the_right_role_gets_the_whole_result_and_a_little_loyalty() -> void:
	GameState.staff_week_tasks = {}
	var before := int(GameState.booster_standing["BO23"])
	var result := GameState.apply_event_choice("EV83", "B", "SF04")
	assert_true(bool(result["ok"]))
	assert_eq(int(GameState.booster_standing["BO23"]), before + 1)
	assert_eq(int(GameState.staff_week_tasks["SF04"]), 1)


func test_another_role_earns_half_the_gains_rounded_down() -> void:
	var before := int(GameState.booster_standing["BO23"])
	var result := GameState.apply_event_choice("EV83", "B", "SF15")
	assert_true(bool(result["ok"]))
	assert_eq(int(GameState.booster_standing["BO23"]), before, "half of +1 rounds down to nothing")


func test_a_restless_researcher_counts_as_a_fair_fit() -> void:
	GameState.staff_loyalty["SF04"] = 20
	var fit := StaffTasks.delegate_fit(R, R, 20)
	assert_eq(fit, StaffTasks.FAIR)


func test_a_person_about_to_leave_earns_nothing() -> void:
	assert_eq(StaffTasks.delegate_fit(R, "District Representative", 10), StaffTasks.POOR)
	assert_eq(StaffTasks.delegate_gain(5, StaffTasks.POOR), 0)
	assert_eq(StaffTasks.delegate_gain(-3, StaffTasks.POOR), -3, "a loss is never softened")
	assert_eq(StaffTasks.delegate_gain(5, StaffTasks.FAIR), 2)


func test_it_takes_blocks_from_their_day() -> void:
	var left := GameState.staff_blocks_left("SF04")
	GameState.apply_event_choice("EV83", "B", "SF04")
	assert_eq(GameState.staff_blocks_left("SF04"), left - 1)


func test_nobody_with_no_blocks_left_can_take_it() -> void:
	GameState.staff_day_delegated["SF04"] = 8
	GameState.staff_day_delegated["SF15"] = 8
	var event := GameState.get_event("EV83")
	assert_ne(GameState.event_delegate_refusal(event, _choice("EV83", "B")), "")
	assert_false(bool(GameState.apply_event_choice("EV83", "B", "SF04").get("ok", false)))


func test_with_no_staff_the_choice_is_refused() -> void:
	GameState.start_new_run("PC01")
	assert_ne(GameState.event_delegate_refusal(GameState.get_event("EV83"), _choice("EV83", "B")), "")


func test_delegated_hours_are_halved_and_the_work_is_booked_for_the_day() -> void:
	# EV02 takes 1 hour: delegated, the player pays none of it.
	var before := int(GameState.calendar["hours"])
	GameState.apply_event_choice("EV83", "B", "SF04")
	assert_eq(int(GameState.calendar["hours"]), before, "1 hour halved rounds down to 0")
	assert_eq(int(GameState.staff_day_delegated["SF04"]), 1)


func test_a_delegated_day_still_resolves_with_the_blocks_counted() -> void:
	# The delegated block means the person was not idle: no idle penalty.
	GameState.apply_event_choice("EV83", "B", "SF04")
	var plan := {"SF15": []}
	var result := StaffTasks.evaluate(GameState.staff_day_pool, DataDB.staff_tasks, plan,
		GameState._staff_eval_members(), GameState._staff_day_info())
	assert_eq(int(result["used"]["SF04"]), 1)


## A fixed day for tests that need particular tasks: eight known tasks (TK17 is time off).
func _fix_pool() -> void:
	var ids := ["TK17", "TK11", "TK10", "TK04", "TK05", "TK14", "TK06", "TK01"]
	var pool: Array = []
	for i in ids.size():
		pool.append(StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, ids[i]), i, {}))
	GameState.staff_day_pool = pool
