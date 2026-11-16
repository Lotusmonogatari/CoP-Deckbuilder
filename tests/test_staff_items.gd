extends GutTest
## Coffee and tea for staff (Cameron, 2026-11-16): items dragged into a person's
## box add hours to their day; one item each; used up when the day is confirmed.

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 900000
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 9   # past the ramp-up: tasks are delivered
	GameState.hire_staff("SF04")
	GameState.hire_staff("SF15")
	GameState.inventory = {"SH04": 2, "SH15": 1}
	GameState.staff_ensure_day()
	_fix_pool()


func test_the_shop_names_the_hours_each_item_adds() -> void:
	assert_eq(GameState.staff_item_hours("SH04"), 1, "coffee")
	assert_eq(GameState.staff_item_hours("SH05"), 1, "tea")
	assert_eq(GameState.staff_item_hours("SH15"), 2, "kaiju-sized coffee")
	assert_eq(GameState.staff_item_hours("SH17"), 2, "kaiju-sized tea")
	assert_eq(GameState.staff_item_hours("SH21"), 0, "anything else is not a staff item")


func test_only_held_staff_items_are_offered() -> void:
	var ids: Array = []
	for entry: Dictionary in GameState.staff_usable_items():
		ids.append(entry["item_id"])
	assert_eq(ids.size(), 2)
	assert_true(ids.has("SH04") and ids.has("SH15"))


func test_an_item_adds_hours_to_that_persons_day_only() -> void:
	assert_eq(GameState.staff_day_hours("SF04"), 8)
	assert_eq(GameState.staff_assign_item("SH15", "SF04"), "")
	assert_eq(GameState.staff_day_hours("SF04"), 10)
	assert_eq(GameState.staff_day_hours("SF15"), 8)


func test_a_longer_day_fits_more_tasks() -> void:
	var pool := GameState.staff_day_pool
	GameState.staff_day_pool = [{"uid": "T0", "task_id": "TK06", "target_id": "", "target_name": "", "title": "", "context": ""},
		{"uid": "T1", "task_id": "TK06", "target_id": "", "target_name": "", "title": "", "context": ""},
		{"uid": "T2", "task_id": "TK01", "target_id": "", "target_name": "", "title": "", "context": ""}]
	assert_eq(GameState.staff_assign("T0", "SF04"), "")
	assert_eq(GameState.staff_assign("T1", "SF04"), "")
	assert_eq(GameState.staff_assign("T2", "SF04"), StaffTasks.REFUSE_BLOCKS, "8 hours are used")
	GameState.staff_assign_item("SH15", "SF04")
	assert_eq(GameState.staff_assign("T2", "SF04"), "", "two more hours fit now")
	GameState.staff_day_pool = pool


func test_one_item_each_a_second_replaces_the_first() -> void:
	GameState.staff_assign_item("SH04", "SF04")
	assert_eq(GameState.staff_item_refusal("SH04", "SF04"), StaffTasks.REFUSE_ITEM_HAVE, "the same item twice is refused")
	assert_eq(GameState.staff_assign_item("SH15", "SF04"), "", "a different one replaces it")
	assert_eq(GameState.staff_day_items["SF04"], "SH15")


func test_you_cannot_give_more_than_you_hold() -> void:
	assert_eq(GameState.staff_assign_item("SH15", "SF04"), "")
	assert_eq(GameState.staff_item_refusal("SH15", "SF15"), StaffTasks.REFUSE_ITEM_NONE, "only one kaiju-sized coffee")
	assert_eq(GameState.staff_assign_item("SH04", "SF15"), "")


func test_taking_an_item_back_costs_nothing() -> void:
	GameState.staff_assign_item("SH04", "SF04")
	GameState.staff_unassign_item("SF04")
	assert_false(GameState.staff_day_items.has("SF04"))
	assert_eq(GameState.item_count("SH04"), 2)


func test_confirming_uses_the_items_up() -> void:
	GameState.staff_assign_item("SH04", "SF04")
	GameState.staff_assign_item("SH15", "SF15")
	GameState.staff_assign(str(GameState.staff_day_pool[0]["uid"]), "SF04")
	assert_eq(GameState.staff_confirm_day(), "")
	assert_eq(GameState.item_count("SH04"), 1)
	assert_eq(GameState.item_count("SH15"), 0)
	assert_eq(GameState.staff_assign_item("SH04", "SF15"), StaffTasks.REFUSE_LOCKED)


func test_a_long_day_still_counts_as_full_only_at_its_own_length() -> void:
	# Ten hours of work on a ten-hour day is a full day, not an eight-hour overrun.
	var tasks := DataDB.staff_tasks
	var pool := [{"uid": "T0", "task_id": "TK06", "target_id": ""}, {"uid": "T1", "task_id": "TK06", "target_id": ""},
		{"uid": "T2", "task_id": "TK01", "target_id": ""}]
	var members := [{"staff_id": "SF04", "role": "Policy Research Assistant", "tier": 0, "loyalty": 60}]
	var result := StaffTasks.evaluate(pool, tasks, {"SF04": ["T0", "T1", "T2"]}, members,
		{"blocks": 8, "delegated": {}, "full_days": {}, "bonus": {"SF04": 2}})
	assert_eq(int(result["used"]["SF04"]), 10)
	assert_eq(int(result["full_days"]["SF04"]), 1)


func test_the_screen_has_an_items_section_and_the_popup_offers_the_staff() -> void:
	var handlers := {"popup": func(_u: String) -> void: pass, "dropped": func(_u: String, _i: String) -> void: pass,
		"profile": func(_i: String) -> void: pass, "confirm": func() -> void: pass,
		"assign": func(_u: String, _i: String) -> void: pass, "unassign": func(_u: String) -> void: pass,
		"item_dropped": func(_i: String, _s: String) -> void: pass,
		"assign_item": func(_i: String, _s: String) -> void: pass, "unassign_item": func(_s: String) -> void: pass}
	var rows := StaffAssignmentsView.rows(handlers)
	var chips := 0
	for row: Control in rows:
		for chip in row.find_children("Item_*", "TaskChip", true, false):
			chips += 1
	assert_eq(chips, 2, "coffee and the kaiju-sized coffee")
	for row: Control in rows:
		row.free()
	var popup := StaffAssignmentsView.item_popup_rows("SH04", handlers)
	var tiles := 0
	for row: Control in popup:
		tiles += row.find_children("GiveTo_*", "Button", true, false).size()
	assert_eq(tiles, 2)
	for row: Control in popup:
		row.free()


## A fixed day for tests that need particular tasks: eight known tasks (TK17 is time off).
func _fix_pool() -> void:
	var ids := ["TK17", "TK11", "TK10", "TK04", "TK05", "TK14", "TK06", "TK01"]
	var pool: Array = []
	for i in ids.size():
		pool.append(StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, ids[i]), i, {}))
	GameState.staff_day_pool = pool
