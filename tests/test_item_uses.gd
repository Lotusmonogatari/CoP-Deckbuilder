extends GutTest
## Items with a number of uses, and the six office-supply items (Cameron,
## 2026-11-16): spending a use, wearing out, saving, and what each new item does.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 900000
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 9


func _hire(ids: Array) -> void:
	for id: String in ids:
		assert_eq(GameState.hire_staff(id), "", "hired " + id)


func _task(id: String, index: int) -> Dictionary:
	return StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, id), index, {})


# --- the pure rules ---------------------------------------------------------------

func test_a_blank_uses_cell_means_one_use() -> void:
	assert_eq(ItemUses.full_uses({}), 1)
	assert_eq(ItemUses.full_uses({"uses": null}), 1)
	assert_eq(ItemUses.full_uses({"uses": 3}), 3)


func test_normalize_pads_trims_and_repairs() -> void:
	assert_eq(ItemUses.normalize(null, 2, 3), [3, 3] as Array[int])
	assert_eq(ItemUses.normalize([1], 3, 3), [1, 3, 3] as Array[int])
	assert_eq(ItemUses.normalize([3, 1, 2], 2, 3), [1, 2] as Array[int], "the fullest copy is the one dropped")
	assert_eq(ItemUses.normalize([0, 9, "x"], 2, 3), [1, 3] as Array[int])


func test_a_use_comes_off_the_most_used_copy_first() -> void:
	var result := ItemUses.spend([1, 3] as Array[int])
	assert_true(bool(result["worn_out"]))
	assert_eq(result["copies"], [3] as Array[int])
	var next := ItemUses.spend([2, 3] as Array[int])
	assert_false(bool(next["worn_out"]))
	assert_eq(next["copies"], [1, 3] as Array[int])


func test_handing_an_item_over_removes_the_most_used_whole_copy() -> void:
	assert_eq(ItemUses.remove_copy([1, 3] as Array[int]), [3] as Array[int])


# --- the run's items ---------------------------------------------------------------

func test_the_new_items_are_in_the_shop_with_their_uses() -> void:
	var expect := {"SH15": 2, "SH17": 2, "SH36": 3, "SH37": 3, "SH38": 3, "SH39": 1, "SH40": 1, "SH41": 1}
	for id: String in expect:
		assert_eq(ItemUses.full_uses(DataDB.get_shop_item(id)), expect[id], id)
	assert_true(DataDB.get_shop_item("SH42").is_empty(), "the old drafts are gone")


func test_a_bought_copy_starts_with_full_uses_and_wears_out() -> void:
	GameState.inventory = {}
	assert_eq(GameState.add_item("SH36", 1), 1)
	assert_eq(GameState.item_copies("SH36"), [3] as Array[int])
	GameState._spend_use("SH36")
	GameState._spend_use("SH36")
	assert_eq(GameState.item_uses_left("SH36"), 1)
	assert_eq(GameState.item_count("SH36"), 1)
	GameState.staff_use_notes = []
	assert_true(GameState._spend_use("SH36"))
	assert_eq(GameState.item_count("SH36"), 0)
	assert_eq(GameState.staff_use_notes.size(), 1, "a line says it wore out")
	assert_false(GameState.item_uses.has("SH36"))


func test_a_second_copy_is_opened_after_the_first_is_finished() -> void:
	GameState.inventory = {}
	GameState.add_item("SH36", 1)
	GameState._spend_use("SH36")
	GameState.add_item("SH36", 1)
	assert_eq(GameState.item_copies("SH36"), [2, 3] as Array[int])
	GameState._spend_use("SH36")
	assert_eq(GameState.item_copies("SH36"), [1, 3] as Array[int])


func test_giving_an_item_away_takes_a_whole_copy() -> void:
	GameState.inventory = {}
	GameState.add_item("SH36", 2)
	GameState._spend_use("SH36")
	GameState._take_item("SH36")
	assert_eq(GameState.item_count("SH36"), 1)
	assert_eq(GameState.item_copies("SH36"), [3] as Array[int])


func test_an_item_written_straight_into_the_inventory_has_full_uses() -> void:
	GameState.inventory = {"SH37": 2}
	GameState.item_uses = {}
	assert_eq(GameState.item_copies("SH37"), [3, 3] as Array[int])


func test_uses_survive_a_save_and_an_old_save_gets_full_uses() -> void:
	GameState.inventory = {}
	GameState.add_item("SH38", 1)
	GameState._spend_use("SH38")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(JSON.parse_string(JSON.stringify(saved)))
	assert_eq(GameState.item_copies("SH38"), [2] as Array[int])
	var old: Dictionary = JSON.parse_string(JSON.stringify(saved))
	old.erase("item_uses")
	GameState.start_new_run("PC01")
	GameState.load_save(old)
	assert_eq(GameState.item_copies("SH38"), [3] as Array[int])


func test_a_kaiju_item_gives_an_hour_for_two_confirmed_days() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH15": 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [_task("TK04", 0)]
	var base := GameState.staff_day_hours("SF04")
	GameState.staff_assign_item("SH15", GameState.OFFICE_BOX)
	assert_eq(GameState.staff_day_hours("SF04"), base + 1)
	GameState.staff_assign("T0", "SF04")
	GameState.staff_confirm_day()
	assert_eq(GameState.item_uses_left("SH15"), 1)
	# the next day: the item is still held, and the second use is the last
	GameState.staff_day_key = -1
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [_task("TK04", 0)]
	assert_eq(GameState.staff_item_refusal("SH15", GameState.OFFICE_BOX), "")
	GameState.staff_assign_item("SH15", GameState.OFFICE_BOX)
	GameState.staff_assign("T0", "SF04")
	GameState.staff_confirm_day()
	assert_eq(GameState.item_count("SH15"), 0, "worn out after two days")


# --- the Printer, the Shredder, the Priority Inbox --------------------------------

func test_the_printer_adds_three_tasks_past_the_maximum() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH36": 1}
	GameState.staff_ensure_day()
	var before := GameState.staff_day_pool.size()
	assert_eq(GameState.staff_item_refusal("SH36", GameState.OFFICE_BOX), "")
	assert_eq(GameState.staff_assign_item("SH36", GameState.OFFICE_BOX), "")
	assert_eq(GameState.staff_day_pool.size(), before + 3)
	assert_eq(GameState.staff_office_item, "", "it acts at once, nothing sits in the box")
	assert_eq(GameState.item_uses_left("SH36"), 2)
	var uids := {}
	for entry: Dictionary in GameState.staff_day_pool:
		assert_false(uids.has(entry["uid"]), "every uid is its own")
		uids[entry["uid"]] = true
	assert_eq(GameState.staff_use_notes.size(), 1)


func test_the_shredder_clears_only_untaken_tasks_that_are_not_due() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH37": 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [_task("TK04", 0), _task("TK36", 1), _task("TK10", 2), _task("TK03", 3), _task("TK05", 4)]
	GameState.staff_day_plan = {"SF04": ["T0"]}
	var due_uids: Array[String] = []
	for entry: Dictionary in GameState.staff_day_pool:
		if not StaffTasks.parse_effects(StaffTasks.task_for(DataDB.staff_tasks, str(entry["task_id"])).get("due_penalty")).is_empty():
			due_uids.append(str(entry["uid"]))
	var eligible := StaffTasks.clearable(GameState.staff_day_pool, DataDB.staff_tasks, GameState.staff_day_plan).size()
	GameState.staff_assign_item("SH37", GameState.OFFICE_BOX)
	assert_eq(GameState.staff_day_pool.size(), 5 - mini(3, eligible))
	var left_uids: Array[String] = []
	for entry: Dictionary in GameState.staff_day_pool:
		left_uids.append(str(entry["uid"]))
	assert_true(left_uids.has("T0"), "a task already given to someone stays")
	for uid in due_uids:
		assert_true(left_uids.has(uid), "a Due task stays")


func test_the_shredder_refuses_when_nothing_qualifies() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH37": 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [_task("TK04", 0)]
	GameState.staff_day_plan = {"SF04": ["T0"]}
	assert_eq(GameState.staff_item_refusal("SH37", GameState.OFFICE_BOX), StaffTasks.REFUSE_NOTHING)
	assert_eq(GameState.item_count("SH37"), 1)


func test_the_priority_inbox_redraws_the_day_and_clears_the_plan() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH39": 1}
	GameState.staff_ensure_day()
	var first := GameState.staff_day_pool.duplicate(true)
	GameState.staff_assign(str(first[0]["uid"]), "SF04")
	assert_false(GameState.staff_day_plan.is_empty())
	assert_eq(GameState.staff_assign_item("SH39", GameState.OFFICE_BOX), "")
	assert_true(GameState.staff_day_plan.is_empty(), "the plan is cleared")
	assert_lte(GameState.staff_day_pool.size(), GameState.staff_day_max)
	assert_ne(JSON.stringify(first), JSON.stringify(GameState.staff_day_pool), "a new draw")
	assert_eq(GameState.item_count("SH39"), 0, "one use, thrown away")


func test_an_instant_item_is_refused_once_the_day_is_confirmed() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH36": 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [_task("TK04", 0)]
	GameState.staff_assign("T0", "SF04")
	GameState.staff_confirm_day()
	assert_eq(GameState.staff_item_refusal("SH36", GameState.OFFICE_BOX), StaffTasks.REFUSE_LOCKED)


func test_a_person_item_spends_a_use_at_confirm_not_when_placed() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH38": 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [_task("TK36", 0)]
	GameState.staff_assign("T0", "SF04")
	GameState.staff_assign_item("SH38", "SF04")
	assert_eq(GameState.item_uses_left("SH38"), 3)
	GameState.staff_confirm_day()
	assert_eq(GameState.item_uses_left("SH38"), 2)
	assert_eq(GameState.item_count("SH38"), 1)


func test_the_item_card_says_how_many_uses_are_left() -> void:
	GameState.inventory = {"SH38": 1}
	var caption := StaffAssignmentsView.item_caption({"effect": "DOUBLE_BEST", "uses": 3, "uses_left": 2, "value": 2}, 1)
	assert_string_contains(caption, "2 uses left")
	var one := StaffAssignmentsView.item_caption({"effect": "QUIET", "uses": 3, "uses_left": 1}, 1)
	assert_string_contains(one, "1 use left")
