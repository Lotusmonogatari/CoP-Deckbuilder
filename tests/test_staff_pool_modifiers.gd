extends GutTest
## Drivers, person items, gift tastes, the Office box and event changes to the
## task pool (Cameron, 2026-11-16, expansion phases 3 to 5).

const R := "Policy Research Assistant"


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 900000
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 9


func _driver(id: String) -> Dictionary:
	for row: Dictionary in DataDB.staff_task_drivers:
		if row["driver_id"] == id:
			return row
	return {}


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _hire(ids: Array) -> void:
	for id: String in ids:
		assert_eq(GameState.hire_staff(id), "", "hired " + id)


# --- drivers ------------------------------------------------------------------

func test_the_drivers_tab_is_valid_data() -> void:
	assert_gte(DataDB.staff_task_drivers.size(), 10)


func test_a_driver_fires_by_its_test() -> void:
	assert_eq(StaffPoolModifiers.times(_driver("DR01"), {"dues_owed": 0}), 0)
	assert_eq(StaffPoolModifiers.times(_driver("DR01"), {"dues_owed": 50000}), 1)
	assert_eq(StaffPoolModifiers.times(_driver("DR03"), {"district_awareness": 25}), 1, "at most 25")
	assert_eq(StaffPoolModifiers.times(_driver("DR03"), {"district_awareness": 26}), 0)
	assert_eq(StaffPoolModifiers.times(_driver("DR12"), {"weekday": 1}), 1, "Monday")
	assert_eq(StaffPoolModifiers.times(_driver("DR12"), {"weekday": 2}), 0)


func test_a_per_driver_fires_once_for_every_so_many() -> void:
	assert_eq(StaffPoolModifiers.times(_driver("DR02"), {"open_promises": 5}), 2, "per 2 promises")
	assert_eq(StaffPoolModifiers.times(_driver("DR02"), {"open_promises": 1}), 0)


func test_a_variable_that_does_not_apply_never_fires() -> void:
	assert_eq(StaffPoolModifiers.times(_driver("DR11"), {"avg_staff_loyalty": -1}), 0, "no staff, no sour office")
	assert_eq(StaffPoolModifiers.times(_driver("DR11"), {"avg_staff_loyalty": 20}), 1)


func test_drivers_add_tasks_and_give_their_reasons() -> void:
	var result := StaffPoolModifiers.from_drivers(DataDB.staff_task_drivers, {"dues_owed": 1, "reputation": 20}, _rng())
	assert_gt(int(result["adds"].get("Administration", 0)), 0)
	assert_gt(int(result["adds"].get("Press", 0)), 0)
	assert_eq((result["reasons"] as Array).size(), 2)
	assert_ne(str(result["reasons"][0]["note"]), "")


func test_a_drivers_total_is_held_to_its_cap() -> void:
	var result := StaffPoolModifiers.from_drivers([_driver("DR02")], {"open_promises": 40}, _rng())
	assert_lte(int(result["adds"]["Correspondence"]), int(_driver("DR02")["cap"]))


func test_a_max_driver_changes_the_days_maximum() -> void:
	var driver := {"variable": "dues_owed", "test": "Is true", "family": "MAX", "add_min": 2, "add_max": 2, "cap": 0, "note": "x"}
	var result := StaffPoolModifiers.from_drivers([driver], {"dues_owed": 5}, _rng())
	assert_eq(int(result["max_delta"]), 2)


func test_unpaid_dues_raise_administration_in_a_real_pool() -> void:
	GameState.dues_balance = 80000
	GameState.staff_ensure_day()
	var found := false
	for reason: Dictionary in GameState.staff_day_reasons:
		if reason["family"] == "Administration":
			found = true
	assert_true(found, "the dues driver is named as a reason")
	assert_eq(GameState.staff_day_max, 15)


# --- mods from items and events ------------------------------------------------

func test_a_change_lasts_its_draws_then_goes() -> void:
	var mods := [{"family": "Press", "amount": 2, "draws_left": 2, "label": "Item"}]
	assert_eq(int(StaffPoolModifiers.from_mods(mods)["adds"]["Press"]), 2)
	mods = StaffPoolModifiers.after_draw(mods)
	assert_eq(int(mods[0]["draws_left"]), 1)
	mods = StaffPoolModifiers.after_draw(mods)
	assert_true(mods.is_empty(), "used up")


func test_a_change_reaches_the_next_pool_only_once() -> void:
	GameState.staff_add_pool_change("Press", 3, 1, "Test")
	GameState.staff_ensure_day()
	var named := false
	for reason: Dictionary in GameState.staff_day_reasons:
		if reason["note"] == "Test" and reason["family"] == "Press":
			named = true
	assert_true(named, "the change is named as a reason")
	assert_true(GameState.staff_pool_mods.is_empty(), "a one-day change is spent by the draw")


func test_a_change_to_the_maximum_changes_it() -> void:
	GameState.staff_add_pool_change("MAX", -10, 1, "Triage")
	GameState.staff_ensure_day()
	assert_eq(GameState.staff_day_max, 5)
	assert_lte(GameState.staff_day_pool.size(), 5)


func test_an_event_choice_can_change_the_next_pool() -> void:
	GameState.apply_event_choice("EV84", "A")
	assert_eq(GameState.staff_pool_mods.size(), 1)
	assert_eq(GameState.staff_pool_mods[0]["family"], "Meetings")


# --- items ------------------------------------------------------------------------

func test_every_staff_item_in_the_shop_is_valid() -> void:
	var effects := {}
	for item: Dictionary in DataDB.shop:
		var info := GameState.staff_item_info(str(item["item_id"]))
		if not str(info["effect"]).is_empty():
			effects[info["effect"]] = true
	for effect in ["HOURS", "HOURS_ALL", "QUIET", "GIFT", "ADD_TASKS", "CLEAR_TASKS", "RESHUFFLE", "DOUBLE_BEST", "NO_PENALTY"]:
		assert_true(effects.has(effect), effect + " has an item")


func test_a_person_item_goes_to_a_person_and_an_office_item_to_the_box() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH41": 1, "SH15": 1}
	GameState.staff_ensure_day()
	assert_eq(GameState.staff_item_refusal("SH41", "SF04"), "")
	assert_eq(GameState.staff_item_refusal("SH41", GameState.OFFICE_BOX), StaffTasks.REFUSE_ITEM_SLOT)
	assert_eq(GameState.staff_item_refusal("SH15", "SF04"), StaffTasks.REFUSE_ITEM_SLOT)
	assert_eq(GameState.staff_item_refusal("SH15", GameState.OFFICE_BOX), "")


func _eval_with(items: Dictionary, task_ids: Array, tier: int = 0, loyalty: int = 60, role: String = R, left_out: Array = []) -> Dictionary:
	if GameState.hired_member("SF04").is_empty():
		_hire(["SF04"])
	GameState.staff_loyalty["SF04"] = loyalty
	var pool: Array = []
	for i in task_ids.size():
		pool.append(StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, task_ids[i]), i, {}))
	var plan := {"SF04": []}
	for i in task_ids.size():
		(plan["SF04"] as Array).append("T%d" % i)
	for extra in left_out:   # work in the pool nobody is given
		pool.append(StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, extra), pool.size(), {}))
	GameState.staff_day_items = items
	var info := GameState._staff_day_info()
	return StaffTasks.evaluate(pool, DataDB.staff_tasks, plan,
		[{"staff_id": "SF04", "role": role, "tier": tier, "loyalty": loyalty}], info)


func test_lunch_delivery_zeroes_the_weak_fit_penalties() -> void:
	# TK10 (greet constituents) is a poor fit for a researcher.
	var without := _eval_with({}, ["TK10"])
	assert_eq(int(without["meta"]["Constituency support"]), -1)
	var lunch := _eval_with({"SF04": "SH41"}, ["TK10"])
	assert_eq(int(lunch["meta"].get("Constituency support", 0)), 0, "no penalty")
	assert_gt(int(lunch["loyalty"]["SF04"]), int(without["loyalty"]["SF04"]), "no Loyalty lost for the weak fit")


func test_flex_work_doubles_the_best_paying_task_and_adds_two_loyalty() -> void:
	var plain := _eval_with({}, ["TK36"])   # Funds +3,000 for a researcher
	assert_eq(int(plain["meta"]["Funds"]), 3000)
	var flex := _eval_with({"SF04": "SH38"}, ["TK36"])
	assert_eq(int(flex["meta"]["Funds"]), 6000)
	assert_eq(int(flex["loyalty"]["SF04"]), int(plain["loyalty"]["SF04"]) + 2)


func test_flex_work_doubles_only_one_task() -> void:
	var plain := _eval_with({}, ["TK36", "TK36"])
	var pay_one := int(_eval_with({}, ["TK36"])["meta"]["Funds"])
	var flex := _eval_with({"SF04": "SH38"}, ["TK36", "TK36"])
	assert_eq(int(flex["meta"]["Funds"]), int(plain["meta"]["Funds"]) + pay_one)


func test_a_commendation_gift_stops_idle_loyalty_loss() -> void:
	var idle := _eval_with({}, [], 0, 60, R, ["TK04"])
	assert_eq(int(idle["loyalty"]["SF04"]), -1)
	var quiet := _eval_with({"SF04": "SH40"}, [], 0, 60, R, ["TK04"])
	assert_eq(int(quiet["loyalty"]["SF04"]), 0)


func test_a_kaiju_item_in_the_office_box_spends_one_use_a_confirmed_day() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH15": 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, "TK04"), 0, {})]
	assert_eq(GameState.staff_assign_item("SH15", GameState.OFFICE_BOX), "")
	assert_eq(GameState.staff_assign("T0", "SF04"), "")
	assert_eq(GameState.staff_confirm_day(), "")
	assert_eq(GameState.item_count("SH15"), 1, "still held, one use left")
	assert_eq(GameState.item_uses_left("SH15"), 1)
	assert_eq(GameState.staff_office_item, "")


func test_an_item_in_the_office_box_can_be_taken_back_for_free() -> void:
	GameState.inventory = {"SH15": 1}
	GameState.staff_ensure_day()
	GameState.staff_assign_item("SH15", GameState.OFFICE_BOX)
	GameState.staff_unassign_item(GameState.OFFICE_BOX)
	assert_eq(GameState.staff_office_item, "")
	assert_eq(GameState.item_count("SH15"), 1)
	assert_eq(GameState.item_uses_left("SH15"), 2)


# --- gifts -------------------------------------------------------------------------

func test_every_staff_member_has_a_taste() -> void:
	for row: Dictionary in DataDB.staff:
		var taste := GameState.staff_gift_taste(str(row["staff_id"]))
		assert_gt((taste["likes"] as Array).size(), 0, str(row["staff_id"]) + " likes something")
		assert_gt((taste["dislikes"] as Array).size(), 0)
		for liked: Variant in taste["likes"]:
			assert_false((taste["dislikes"] as Array).has(liked), "no gift both liked and disliked")


func test_a_liked_gift_pleases_more_than_a_neutral_one_and_a_disliked_one_costs() -> void:
	var taste := GameState.staff_gift_taste("SF04")
	var liked := str(taste["likes"][0])
	var disliked := str(taste["dislikes"][0])
	var neutral := ""
	for gift in ["SH25", "SH26", "SH27", "SH28", "SH29", "SH30", "SH31", "SH32", "SH33"]:
		if not (taste["likes"] as Array).has(gift) and not (taste["dislikes"] as Array).has(gift):
			neutral = gift
	assert_gt(GameState.staff_gift_loyalty("SF04", liked), GameState.staff_gift_loyalty("SF04", neutral))
	assert_lt(GameState.staff_gift_loyalty("SF04", disliked), 0)


func test_confirming_hands_the_gift_over_and_the_taste_becomes_known() -> void:
	_hire(["SF04"])
	var liked := str(GameState.staff_gift_taste("SF04")["likes"][0])
	GameState.inventory = {liked: 1}
	GameState.staff_ensure_day()
	GameState.staff_day_pool = [StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, "TK04"), 0, {})]
	GameState.staff_assign("T0", "SF04")
	assert_false(bool(GameState.staff_taste_known.get("SF04", false)))
	var before := GameState.staff_loyalty_of("SF04")
	GameState.staff_assign_item(liked, "SF04")
	GameState.staff_confirm_day()
	assert_eq(GameState.staff_loyalty_of("SF04"), before + GameState.staff_gift_loyalty("SF04", liked))
	assert_true(bool(GameState.staff_taste_known["SF04"]))
	assert_eq(GameState.item_count(liked), 0)
	assert_eq(GameState.staff_gift_notes.size(), 1)


func test_an_item_in_the_office_box_does_not_get_a_person() -> void:
	_hire(["SF04"])
	GameState.inventory = {"SH15": 1}
	GameState.staff_ensure_day()
	assert_eq(GameState.staff_assign("T0", GameState.OFFICE_BOX), StaffTasks.REFUSE_UNKNOWN, "a task cannot go in the Office box")
