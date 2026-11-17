extends GutTest
## End of Week Payments (P9, 2026-11-17): the breakdown is the settlement, line for line,
## including raised pay and a shortfall. It is the same functions the week end calls.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 6
	GameState.week_funds_earned = 80000
	GameState.meta["Party support"] = 55
	for id: String in ["SF04", "SF08"]:
		GameState.hire_staff(id)


func test_the_total_is_dues_plus_every_wage() -> void:
	GameState.meta["Funds"] = 900000
	var pay: Dictionary = GameState.week_end_preview()["payments"]
	var wages := 0
	for line: Dictionary in pay["wages"]:
		wages += int(line["wage"])
	assert_eq(int(pay["wages_total"]), wages)
	assert_eq(int(pay["total"]), int((pay["dues"] as Dictionary)["total"]) + wages)
	assert_eq(int(pay["short_by"]), 0, "nothing is short with 900,000")
	assert_true((pay["unpaid"] as Array).is_empty())


func test_raised_pay_shows_on_that_persons_line_and_is_charged() -> void:
	GameState.meta["Funds"] = 900000
	GameState.staff_raise_pay["SF04"] = true
	var pay: Dictionary = GameState.week_end_preview()["payments"]
	var raised := 0
	for line: Dictionary in pay["wages"]:
		if str(line["staff_id"]) == "SF04":
			assert_true(bool(line["raised"]))
			assert_eq(int(line["wage"]), GameState.staff_wage_of("SF04"))
			raised += 1
		else:
			assert_false(bool(line["raised"]))
	assert_eq(raised, 1)
	var before := int(GameState.meta["Funds"])
	GameState.go_home()
	assert_eq(before - int(GameState.meta["Funds"]),
		int((pay["dues"] as Dictionary)["paid"]) + int(pay["wages_paid"]), "the charge is the preview")


func test_a_shortfall_names_who_goes_unpaid_and_matches_the_settlement() -> void:
	GameState.staff_raise_pay["SF04"] = true
	var dues_total := int(GameState.week_end_preview()["dues"]["total"])
	# Enough for the dues but not the (raised) wage.
	GameState.meta["Funds"] = dues_total + 500
	var pay: Dictionary = GameState.week_end_preview()["payments"]
	assert_gt(int(pay["short_by"]), 0)
	var unpaid_names: Array = pay["unpaid"]
	assert_gt(unpaid_names.size(), 0, "somebody's wage will be missed")
	var expected_missed: Array[String] = []
	for line: Dictionary in pay["wages"]:
		if not bool(line["paid"]):
			expected_missed.append(str(line["staff_id"]))
	GameState.go_home()
	var report: Dictionary = GameState.staff_last_week
	assert_gt(expected_missed.size(), 0)
	for id: String in expected_missed:
		assert_false(bool((report.get(id, {}) as Dictionary).get("paid", true)), "%s: the preview said what the week end did" % id)
	assert_eq(int(GameState.meta["Funds"]), int((pay["funds"] as Dictionary)["after"]), "Funds after")


func test_unpaid_dues_are_flagged_and_wages_follow_pay_order() -> void:
	GameState.meta["Funds"] = 1000
	var pay: Dictionary = GameState.week_end_preview()["payments"]
	assert_true(bool(pay["unpaid_dues"]))
	assert_eq((pay["unpaid"] as Array).size(), (pay["wages"] as Array).size(), "no Funds left for any wage")


func test_no_staff_means_the_total_is_the_dues() -> void:
	var pay := WeekPayments.build(50000, 0, 900000, 0, [])
	assert_eq(int(pay["total"]), 50000)
	assert_eq(int(pay["wages_total"]), 0)
	assert_eq((pay["wages"] as Array).size(), 0)


func test_the_pure_function_pays_primary_first_and_never_part_pays() -> void:
	var staff := [
		{"staff_id": "A", "name": "A", "primary": false, "loyalty": 10, "wage": 40000, "raised": false},
		{"staff_id": "B", "name": "B", "primary": true, "loyalty": 90, "wage": 40000, "raised": true},
	]
	var pay := WeekPayments.build(50000, 0, 95000, 0, staff)
	assert_eq(str((pay["wages"] as Array)[0]["staff_id"]), "B", "primary first")
	assert_true(bool((pay["wages"] as Array)[0]["paid"]))
	assert_false(bool((pay["wages"] as Array)[1]["paid"]), "45,000 left cannot cover 40,000 twice")
	assert_eq(pay["unpaid"], ["A"])
	assert_eq(int((pay["funds"] as Dictionary)["after"]), 5000)
