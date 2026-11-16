extends GutTest
## The daily staff tasks (Cameron, 2026-11-16): the pure rules, then a day in a
## real run.

const R := "Policy Research Assistant"
const M := "Media Spokesperson"
const D := "District Representative"


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.meta["Funds"] = 1000000
	GameState.staff_recruitment_tier = 2


func _task(id: String) -> Dictionary:
	return StaffTasks.task_for(DataDB.staff_tasks, id)


func _member(id: String, role: String, tier: int = 0, loyalty: int = 50) -> Dictionary:
	return {"staff_id": id, "role": role, "tier": tier, "loyalty": loyalty}


## A pool holding exactly the named tasks, uids T0, T1, ...
func _pool(task_ids: Array) -> Array:
	var pool: Array = []
	for i in task_ids.size():
		var task := _task(str(task_ids[i]))
		pool.append({"uid": "T%d" % i, "task_id": task["task_id"], "target_id": "BO01",
			"target_name": "Test", "title": task["title"], "context": task["context"]})
	return pool


func _eval(pool: Array, plan: Dictionary, members: Array, full_days: Dictionary = {}) -> Dictionary:
	return StaffTasks.evaluate(pool, DataDB.staff_tasks, plan, members, {"blocks": 8, "delegated": {}, "full_days": full_days})


# --- the data ---------------------------------------------------------------

func test_sixty_four_tasks_in_eight_icon_families_of_eight() -> void:
	assert_eq(DataDB.staff_tasks.size(), 64)
	var icons := {}
	for task: Dictionary in DataDB.staff_tasks:
		icons[task["icon"]] = true
	assert_eq(icons.size(), 8)


func test_every_task_has_one_strong_fair_and_poor_role() -> void:
	for task: Dictionary in DataDB.staff_tasks:
		if task["kind"] == "time_off":
			continue
		var roles := [task["strong_role"], task["fair_role"], task["poor_role"]]
		roles.sort()
		assert_eq(roles, [D, M, R], str(task["task_id"]))


func test_each_icon_family_has_one_one_word_name() -> void:
	var names := {}
	for task: Dictionary in DataDB.staff_tasks:
		var word := str(task["family"])
		assert_false(word.is_empty() or word.contains(" "), str(task["task_id"]) + " has a one-word family")
		assert_eq(names.get(task["icon"], word), word, "one name per icon")
		names[task["icon"]] = word
	assert_eq(names["LL02"], "Press")
	assert_eq(names["LL03"], "Analysis")
	assert_eq(names["LL04"], "Meetings")


# --- fit and rewards ---------------------------------------------------------

func test_strong_fair_and_poor_fit() -> void:
	var casework := _task("TK11")
	assert_eq(StaffTasks.fit_of(casework, D), StaffTasks.STRONG)
	assert_eq(StaffTasks.fit_of(casework, R), StaffTasks.FAIR)
	assert_eq(StaffTasks.fit_of(casework, M), StaffTasks.POOR)


func test_a_strong_fit_pays_the_reward_a_poor_fit_the_penalty_a_fair_fit_nothing() -> void:
	var pool := _pool(["TK10", "TK10", "TK10"])
	var strong := _eval(pool, {"D1": ["T0"]}, [_member("D1", D)])
	assert_eq(int(strong["meta"]["Constituency support"]), 2)
	var fair := _eval(pool, {"M1": ["T0"]}, [_member("M1", M)])
	assert_false((fair["meta"] as Dictionary).has("Constituency support"), "fair: no effect")
	var poor := _eval(pool, {"R1": ["T0"]}, [_member("R1", R)])
	assert_eq(int(poor["meta"]["Constituency support"]), -1)


func test_rank_grows_a_strong_reward_but_not_a_penalty() -> void:
	var pool := _pool(["TK05"])
	var tier_two := _eval(pool, {"R1": ["T0"]}, [_member("R1", R, 2)])
	assert_eq(int(tier_two["xp"]), 4, "3 grows by 25% per rank, rounded down: 3 + 1")
	assert_eq(StaffTasks.rank_scaled(-2, "Reputation", 2), -2)
	assert_eq(StaffTasks.rank_scaled(1, "Loyalty", 2), 1, "Loyalty never grows")


func test_a_restless_person_does_strong_work_as_fair() -> void:
	var pool := _pool(["TK10"])
	var result := _eval(pool, {"D1": ["T0"]}, [_member("D1", D, 0, 20)])
	assert_false((result["meta"] as Dictionary).has("Constituency support"))
	assert_eq(str(result["lines"][0]["fit"]), StaffTasks.FAIR)


func test_daily_caps_hold_the_total() -> void:
	# Four strong-fit constituent tasks would be +8, over the cap.
	var pool := _pool(["TK10", "TK10", "TK10", "TK10"])
	var plan := {"D1": ["T0", "T1"], "D2": ["T2", "T3"]}
	var result := _eval(pool, plan, [_member("D1", D), _member("D2", D)])
	assert_eq(int(result["meta"]["Constituency support"]), Levers.whole("staff_tasks_cap_meta"))


func test_standing_goes_to_the_task_target() -> void:
	var pool := _pool(["TK07"])
	var result := _eval(pool, {"D1": ["T0"]}, [_member("D1", D)])
	assert_eq(int(result["standing"]["BO01"]), 3)


# --- the shape of the day ----------------------------------------------------

func test_a_person_with_nothing_to_do_is_idle() -> void:
	var result := _eval(_pool(["TK04"]), {"M1": ["T0"]}, [_member("M1", M), _member("D1", D)])
	assert_eq(int(result["loyalty"]["D1"]), -1, "idle")


func test_a_mostly_used_day_is_healthy_a_full_day_is_neutral() -> void:
	# TK05 is 3 blocks, TK06 is 4, TK01 is 2: five blocks is healthy, eight is full.
	var five := _eval(_pool(["TK01", "TK05"]), {"R1": ["T0", "T1"]}, [_member("R1", R)])
	assert_eq(int(five["used"]["R1"]), 5)
	var full := _eval(_pool(["TK05", "TK06"]), {"R1": ["T0", "T1"]}, [_member("R1", R)])
	assert_eq(int(full["used"]["R1"]), 7)
	var eight := _eval(_pool(["TK06", "TK06"]), {"R1": ["T0", "T1"]}, [_member("R1", R)])
	assert_eq(int(eight["full_days"]["R1"]), 1)


func test_three_full_days_in_a_row_burn_a_person_out() -> void:
	var pool := _pool(["TK06", "TK06"])
	var plan := {"R1": ["T0", "T1"]}
	var third := _eval(pool, plan, [_member("R1", R)], {"R1": 2})
	assert_eq(int(third["full_days"]["R1"]), 3)
	# TK06 is a poor fit for nobody here (strong R): -1 streak, +1 fit twice.
	var calm := _eval(pool, plan, [_member("R1", R)], {"R1": 0})
	assert_lt(int(third["loyalty"]["R1"]), int(calm["loyalty"]["R1"]))


func test_a_task_does_not_fit_when_the_day_is_full() -> void:
	var pool := _pool(["TK06", "TK06", "TK05"])
	var plan := {"R1": ["T0", "T1"]}
	var refusal := StaffTasks.assign_refusal("T2", "R1", pool, DataDB.staff_tasks, plan, {}, 8, false)
	assert_eq(refusal, StaffTasks.REFUSE_BLOCKS)


func test_a_task_given_twice_or_after_confirming_is_refused() -> void:
	var pool := _pool(["TK04"])
	assert_eq(StaffTasks.assign_refusal("T0", "R1", pool, DataDB.staff_tasks, {"M1": ["T0"]}, {}, 8, false), StaffTasks.REFUSE_TAKEN)
	assert_eq(StaffTasks.assign_refusal("T0", "R1", pool, DataDB.staff_tasks, {}, {}, 8, true), StaffTasks.REFUSE_LOCKED)


func test_delegated_work_takes_blocks_from_the_day() -> void:
	var pool := _pool(["TK06"])
	var refusal := StaffTasks.assign_refusal("T0", "R1", pool, DataDB.staff_tasks, {}, {"R1": 5}, 8, false)
	assert_eq(refusal, StaffTasks.REFUSE_BLOCKS, "4 blocks do not fit after 5 are delegated")


# --- time off and due tasks --------------------------------------------------

func test_time_off_gives_loyalty_and_unused_time_off_costs_everyone() -> void:
	var pool := _pool(["TK17", "TK04"])
	var taken := _eval(pool, {"R1": ["T0"]}, [_member("R1", R), _member("D1", D)])
	assert_eq(int(taken["loyalty"]["R1"]), 1, "time off +1; four blocks of eight is neither idle nor healthy enough")
	assert_false(bool(taken["time_off_unused"]))
	var unused := _eval(pool, {"R1": ["T1"]}, [_member("R1", R), _member("D1", D)])
	assert_true(bool(unused["time_off_unused"]))
	assert_lt(int(unused["loyalty"]["D1"]), int(taken["loyalty"]["D1"]), "an unused day off costs everyone")


func test_a_due_task_left_alone_costs_its_penalty() -> void:
	var result := _eval(_pool(["TK11"]), {}, [_member("D1", D)])
	assert_eq((result["undone"] as Array).size(), 1)
	assert_eq(int(result["meta"]["Constituency support"]), -1)


func test_a_due_task_that_was_given_out_costs_nothing() -> void:
	var result := _eval(_pool(["TK11"]), {"D1": ["T0"]}, [_member("D1", D)])
	assert_eq((result["undone"] as Array).size(), 0)


func test_the_lunch_lifts_everyone() -> void:
	var result := _eval(_pool(["TK15"]), {"D1": ["T0"]}, [_member("D1", D), _member("R1", R)])
	assert_eq(int(result["loyalty"]["R1"]), -1 + 1, "idle -1, lunch +1")


# --- the pool ---------------------------------------------------------------

func _targets() -> Dictionary:
	return {"organization": [{"id": "BO01", "name": "A"}], "committee": [{"id": "C", "name": "Committee on X"}],
		"official": [{"id": "OP01", "name": "Minister of Y"}]}


func _draw(seed_value: int, maximum: int = 15, weekend: bool = false, adds: Dictionary = {}, targets: Dictionary = {}) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return StaffTasks.draw_pool(DataDB.staff_tasks, DataDB.staff_task_families, targets if not targets.is_empty() else _targets(),
		maximum, weekend, adds, rng)


func test_a_pool_never_repeats_a_task_and_holds_at_most_one_rest() -> void:
	for seed_value in 30:
		var pool := _draw(seed_value)
		var seen := {}
		var rests := 0
		for entry: Dictionary in pool:
			assert_false(seen.has(entry["task_id"]), "no repeat")
			seen[entry["task_id"]] = true
			if str(_task(str(entry["task_id"]))["family"]) == "Rest":
				rests += 1
		assert_lte(rests, 1)
		assert_gte(pool.size(), 1)


func test_the_same_seed_draws_the_same_pool() -> void:
	assert_eq(_draw(99), _draw(99))


func test_every_family_stays_inside_its_range() -> void:
	for seed_value in 40:
		var counts := {}
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		counts = StaffTasks.roll_quotas(DataDB.staff_task_families, false, {}, rng)
		for row: Dictionary in DataDB.staff_task_families:
			var count := int(counts[row["family"]])
			assert_gte(count, int(row["min"]))
			assert_lte(count, int(row["max"]))


func test_drivers_can_push_a_family_up_to_its_cap_and_no_further() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var counts := StaffTasks.roll_quotas(DataDB.staff_task_families, false, {"Press": 99, "Chores": -99}, rng)
	var press := 0
	for row: Dictionary in DataDB.staff_task_families:
		if row["family"] == "Press":
			press = int(row["cap"])
	assert_eq(int(counts["Press"]), press)
	assert_eq(int(counts["Chores"]), 0, "never below nothing")


func test_a_weekend_day_keeps_a_share_of_each_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var counts := StaffTasks.roll_quotas(DataDB.staff_task_families, true, {}, rng)
	for row: Dictionary in DataDB.staff_task_families:
		assert_lte(int(counts[row["family"]]), int(row["max"]))


func test_the_maximum_trims_the_list_before_it_is_delivered() -> void:
	# Even if every family rolled its most, a maximum of one delivers one.
	for seed_value in 20:
		assert_lte(_draw(seed_value, 1).size(), 1)
		assert_lte(_draw(seed_value, 3).size(), 3)
	assert_eq(_draw(4, 0).size(), 0, "a maximum of nothing delivers nothing")


func test_a_trim_keeps_tasks_in_the_order_they_were_drawn() -> void:
	var pool := _draw(8, 4)
	for i in pool.size():
		assert_eq(pool[i]["uid"], "T%d" % i)


func test_a_kind_with_nobody_to_name_is_not_offered() -> void:
	var nobody := {"organization": [], "committee": [], "official": []}
	for seed_value in 30:
		for entry: Dictionary in _draw(seed_value, 15, false, {"Meetings": 9}, nobody):
			assert_false(["TK07", "TK08", "TK09", "TK40"].has(entry["task_id"]))


func test_the_ramp_sets_the_most_tasks_a_day_by_week() -> void:
	var ramp := DataDB.staff_task_ramp
	assert_eq(StaffTasks.day_maximum(ramp, 0, false), 0, "week 1")
	assert_eq(StaffTasks.day_maximum(ramp, 1, false), 1, "week 2")
	assert_eq(StaffTasks.day_maximum(ramp, 2, false), 2, "week 3")
	assert_eq(StaffTasks.day_maximum(ramp, 3, false), 3, "week 4")
	assert_eq(StaffTasks.day_maximum(ramp, 4, false), 15, "week 5")
	assert_eq(StaffTasks.day_maximum(ramp, 40, false), 15, "every later week")


func test_an_item_or_event_changes_the_maximum_but_never_below_nothing() -> void:
	var ramp := DataDB.staff_task_ramp
	assert_eq(StaffTasks.day_maximum(ramp, 1, false, 2), 3)
	assert_eq(StaffTasks.day_maximum(ramp, 1, false, -5), 0)


func test_a_weekend_keeps_the_ramps_weekend_share() -> void:
	assert_eq(StaffTasks.day_maximum(DataDB.staff_task_ramp, 4, true), 7, "half of 15, rounded down")


func test_names_come_from_the_title_column() -> void:
	var prefixes: Array = DataDB.rules.get("staff_task_official_prefixes", [])
	var marker := str(DataDB.rules.get("staff_task_committee_marker", ""))
	assert_eq(StaffTasks.committee_in("Minister of Finance; Chair of the Committee on Finance", marker), "Committee on Finance")
	assert_eq(StaffTasks.committee_in("Leader of the Keizaijiyuutou", marker), "")
	assert_eq(StaffTasks.official_posts("Minister of Finance; Chair of the Committee on Finance", prefixes), ["Minister of Finance"])
	var assembly := StaffTasks.official_posts("President of the National Assembly; Chair of the Committee on the National Assembly; Speaker of the National Assembly; Leader of the Frontier Party", prefixes)
	assert_eq(assembly, ["President of the National Assembly", "Speaker of the National Assembly"])
	assert_eq(StaffTasks.official_posts("Prime Minister; Leader of the Yezo Heritage Party", prefixes), ["Prime Minister"])
	assert_eq(StaffTasks.official_posts("Chief Political Correspondent", prefixes), [])


func test_the_real_data_names_ministers_and_committees() -> void:
	var targets := GameState._staff_task_targets()
	assert_gt((targets["official"] as Array).size(), 5, "ministers, the prime minister, the speaker")
	assert_gt((targets["committee"] as Array).size(), 5)
	assert_eq((targets["organization"] as Array).size(), 32)


# --- a day in a real run -----------------------------------------------------

func _staffed_run() -> void:
	GameState.calendar["week"] = 9   # past the ramp-up: tasks are delivered
	assert_eq(GameState.hire_staff("SF15"), "")   # a district representative
	assert_eq(GameState.hire_staff("SF08"), "")   # a media spokesperson
	GameState.booster_standing["BO18"] = 50


## Today's tasks, then a fixed set of eight so a test can name them.
func _ensure_fixed() -> void:
	GameState.staff_ensure_day()
	_fix_pool()

func _fix_pool() -> void:
	var ids := ["TK17", "TK11", "TK10", "TK04", "TK05", "TK14", "TK06", "TK01"]
	var pool: Array = []
	for i in ids.size():
		pool.append(StaffTasks._entry(StaffTasks.task_for(DataDB.staff_tasks, ids[i]), i, {}))
	GameState.staff_day_pool = pool



func test_the_first_week_delivers_no_tasks() -> void:
	GameState.calendar["week"] = 0
	GameState.staff_ensure_day()
	assert_eq(GameState.staff_day_pool.size(), 0)


func test_week_two_delivers_one_task_even_with_no_staff() -> void:
	GameState.calendar["week"] = 1
	GameState.staff_ensure_day()
	assert_eq(GameState.staff_day_pool.size(), 1, "tasks arrive whether or not anyone is hired")
	assert_eq(GameState.staff_members().size(), 0)


func test_the_ramp_grows_a_task_a_week() -> void:
	for week in 4:
		GameState.start_new_run("PC01")
		GameState.calendar["week"] = week
		GameState.staff_ensure_day()
		assert_lte(GameState.staff_day_pool.size(), week, "week %d delivers at most %d" % [week + 1, week])


func test_the_pool_is_drawn_once_a_day_and_repeats_on_reopening() -> void:
	_staffed_run()
	GameState.staff_ensure_day()
	var first := GameState.staff_day_pool.duplicate(true)
	assert_gt(first.size(), 0)
	assert_lte(first.size(), 15)
	GameState.staff_ensure_day()
	assert_eq(GameState.staff_day_pool, first)


func test_giving_and_taking_back_a_task() -> void:
	_staffed_run()
	_ensure_fixed()
	var uid := str(GameState.staff_day_pool[0]["uid"])
	assert_eq(GameState.staff_assign(uid, "SF15"), "")
	assert_eq(GameState.staff_assign(uid, "SF08"), "", "moving it to someone else")
	assert_false(GameState.staff_day_plan.has("SF15"))
	GameState.staff_unassign(uid)
	assert_true(GameState.staff_day_plan.is_empty())


func test_confirm_needs_something_assigned_and_locks_the_day() -> void:
	_staffed_run()
	_ensure_fixed()
	assert_ne(GameState.staff_confirm_day(), "", "nothing given out yet")
	GameState.staff_assign(str(GameState.staff_day_pool[0]["uid"]), "SF15")
	assert_eq(GameState.staff_confirm_day(), "")
	assert_eq(GameState.staff_assign(str(GameState.staff_day_pool[1]["uid"]), "SF15"), StaffTasks.REFUSE_LOCKED)


func test_a_confirmed_day_is_applied_when_the_next_day_begins() -> void:
	_staffed_run()
	_ensure_fixed()
	var uid := ""
	for entry: Dictionary in GameState.staff_day_pool:
		if entry["task_id"] == "TK10":   # greet constituents, strong for the district rep
			uid = str(entry["uid"])
	GameState.staff_assign(uid, "SF15")
	GameState.staff_confirm_day()
	var before := int(GameState.meta["Constituency support"])
	var promised := int(GameState.staff_projection()["meta"].get("Constituency support", 0))
	assert_gt(promised, -99)
	GameState.spend_hours(8)
	GameState.staff_day_sync()
	assert_eq(int(GameState.meta["Constituency support"]), before + promised, "what the screen projected is what happens")
	assert_false(GameState.staff_report_pending.is_empty(), "a report waits for the screen")
	assert_eq(GameState.staff_day_key, -1, "the day is over")


func test_a_day_skipped_by_a_long_level_goes_out_of_effect() -> void:
	_staffed_run()
	_ensure_fixed()
	GameState.staff_assign(str(GameState.staff_day_pool[0]["uid"]), "SF15")
	GameState.staff_confirm_day()
	var before := GameState.meta.duplicate()
	GameState.spend_hours(24)   # three days at once
	GameState.staff_day_sync()
	assert_eq(GameState.meta, before, "no rewards or penalties")
	assert_true(GameState.staff_report_pending.is_empty())
	assert_eq(GameState.staff_day_key, -1)


func test_an_unconfirmed_day_costs_only_the_due_tasks_nobody_took() -> void:
	_staffed_run()
	_ensure_fixed()
	# Given out but never confirmed: no rewards, but the Due tasks (TK11 casework,
	# TK14 scheduling) still cost their penalty.
	GameState.staff_assign(_uid_of("TK10"), "SF15")
	var before_constituency := int(GameState.meta["Constituency support"])
	var before_reputation := int(GameState.meta["Reputation"])
	GameState.spend_hours(8)
	GameState.staff_day_sync()
	assert_eq(int(GameState.meta["Constituency support"]), before_constituency - 1, "casework left undone")
	assert_eq(int(GameState.meta["Reputation"]), before_reputation - 1, "scheduling left undone")


func test_a_player_with_no_staff_still_pays_the_due_tasks() -> void:
	GameState.calendar["week"] = 9
	GameState.staff_ensure_day()
	_fix_pool()
	var before := int(GameState.meta["Constituency support"])
	GameState.spend_hours(8)
	GameState.staff_day_sync()
	assert_eq(int(GameState.meta["Constituency support"]), before - 1, "no one did the casework")
	assert_false(GameState.staff_report_pending.is_empty(), "and the player is told")


func test_a_day_with_nothing_due_says_nothing() -> void:
	GameState.calendar["week"] = 9
	GameState.staff_ensure_day()
	GameState.staff_day_pool = _pool(["TK10"])   # no Due task
	GameState.spend_hours(8)
	GameState.staff_day_sync()
	assert_true(GameState.staff_report_pending.is_empty())


func _uid_of(task_id: String) -> String:
	for entry: Dictionary in GameState.staff_day_pool:
		if entry["task_id"] == task_id:
			return str(entry["uid"])
	return ""


func test_task_loyalty_reaches_the_week_end_within_its_cap() -> void:
	_staffed_run()
	GameState.staff_week_tasks["SF15"] = 0
	GameState.staff_day_key = 5
	GameState.staff_day_pool = _pool(["TK10"])
	GameState.staff_day_plan = {"SF15": ["T0"]}
	GameState.staff_day_confirmed = true
	GameState.staff_day_blocks_total = 8
	GameState._staff_resolve_day()
	assert_gt(int(GameState.staff_week_tasks["SF15"]), 0)
	assert_lte(int(GameState.staff_week_tasks["SF15"]), 6)


func test_the_day_state_survives_a_save() -> void:
	_staffed_run()
	_ensure_fixed()
	GameState.staff_assign(str(GameState.staff_day_pool[0]["uid"]), "SF15")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.staff_day_pool.size(), 8)
	assert_eq(GameState.staff_day_plan.size(), 1)
