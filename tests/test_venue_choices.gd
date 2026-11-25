extends GutTest
## Seats and meals at the Cafeteria, and Catch Up on Paperwork (2026-11-25): the seeded draw of three seats, the chance of an extra, a pool settled
## to one group, what a seat and a meal give, the lunch in the run (the hour, the party's opinion, the extra, reload-safety) and the screens.

var _real_choices: Array


func before_each() -> void:
	_real_choices = DataDB.venue_choices


func after_each() -> void:
	DataDB.venue_choices = _real_choices


func _pool(count: int) -> Array:
	var rows: Array = []
	for i in count:
		rows.append({"choice_id": "S%d" % i, "venue_id": "VN01", "step": "seat", "weight": null})
	return rows


func _fresh_run() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}


# --- Rules --------------------------------------------------------------------------------------------------------------------------

func test_the_three_seats_are_different_and_the_same_for_the_same_seed() -> void:
	var pool := _pool(11)
	var first := VenueChoices.draw(pool, 3, 42)
	assert_eq(first.size(), 3)
	assert_eq(first.map(func(r: Dictionary) -> String: return str(r["choice_id"])), VenueChoices.draw(pool, 3, 42).map(func(r: Dictionary) -> String: return str(r["choice_id"])))
	var ids := {}
	for row: Dictionary in first:
		ids[str(row["choice_id"])] = true
	assert_eq(ids.size(), 3, "no seat twice")
	assert_eq(VenueChoices.draw(_pool(2), 3, 1).size(), 2, "a short pool gives what it has")


func test_over_many_seeds_every_seat_comes_up_and_a_heavier_seat_comes_up_more() -> void:
	var pool := _pool(5)
	(pool[0] as Dictionary)["weight"] = 6
	var seen := {}
	for seed_value in range(400):
		for row: Dictionary in VenueChoices.draw(pool, 3, seed_value):
			seen[str(row["choice_id"])] = int(seen.get(str(row["choice_id"]), 0)) + 1
	assert_eq(seen.size(), 5)
	assert_gt(int(seen["S0"]), int(seen["S1"]), "weight 6 beats weight 1")


func test_a_one_in_n_chance_comes_up_about_one_time_in_n_and_never_without_one() -> void:
	var hits := 0
	for seed_value in range(2000):
		if VenueChoices.hits(10, seed_value):
			hits += 1
	assert_between(hits, 120, 290, "about 1 in 10 (%d of 2000)" % hits)
	assert_false(VenueChoices.hits(null, 5))
	assert_false(VenueChoices.hits(0, 5))
	assert_true(VenueChoices.hits(1, 5), "1 in 1 is certain")


func test_a_pool_is_settled_to_one_member_from_a_seed() -> void:
	var entries := [{"target_pool": ["BO28", "BO29"], "delta": 1}, {"target": "BO10", "delta": 1}]
	var seen := {}
	for seed_value in range(60):
		var settled := VenueChoices.settle_pools(entries, seed_value)
		assert_eq(settled.size(), 2)
		assert_false((settled[0] as Dictionary).has("target_pool"))
		seen[str((settled[0] as Dictionary)["target"])] = true
		assert_eq(str((settled[1] as Dictionary)["target"]), "BO10")
		assert_eq(settled, VenueChoices.settle_pools(entries, seed_value), "same seed, same pick")
	assert_eq(seen.keys().size(), 2, "both groups come up over many seeds")
	assert_eq(VenueChoices.settle_pools(null, 1), [])


func test_rows_for_and_names() -> void:
	var rows := [{"venue_id": "VN01", "step": "seat"}, {"venue_id": "VN01", "step": "meal"}, {"venue_id": "VN03", "step": "seat"}]
	assert_eq(VenueChoices.rows_for(rows, "VN01", "seat").size(), 1)
	assert_true(VenueChoices.has_choices(rows, "VN03"))
	assert_false(VenueChoices.has_choices(rows, "VN08"))
	assert_eq(VenueChoices.display_name("A {party} member's table", "Frontier Party"), "A Frontier Party member's table")


# --- The shipped rows ---------------------------------------------------------------------------------------------------------------

func test_the_cafeteria_has_eleven_seats_and_ten_meals_each_meal_with_a_one_in_ten_extra_or_none() -> void:
	assert_eq(VenueChoices.rows_for(DataDB.venue_choices, "VN01", "seat").size(), 11, "six party tables, the mixed table, young staffers, a member and a staffer, older staffers, anywhere open")
	var meals := VenueChoices.rows_for(DataDB.venue_choices, "VN01", "meal")
	assert_eq(meals.size(), 10)
	for meal: Dictionary in meals:
		if meal.get("extra_rewards") != null:
			assert_eq(int(meal["chance"]), 10, "%s: one in ten" % meal["name"])
	var party_seats := VenueChoices.rows_for(DataDB.venue_choices, "VN01", "seat").filter(func(r: Dictionary) -> bool: return r.get("party") != null)
	assert_eq(party_seats.size(), 6)
	for seat: Dictionary in party_seats:
		assert_eq(int(seat["party_opinion"]), 1, "a party's member at the table: +1 to that party's opinion")


func test_the_sito_dumplings_give_one_of_the_two_ainu_groups_on_the_extra() -> void:
	for meal: Dictionary in VenueChoices.rows_for(DataDB.venue_choices, "VN01", "meal"):
		if str(meal["name"]) == "Sito dumplings":
			assert_eq(((meal["extra_rewards"] as Array)[0] as Dictionary)["target_pool"], ["BO28", "BO29"])
			return
	fail_test("no Sito dumplings")


# --- In the run ---------------------------------------------------------------------------------------------------------------------

func test_the_three_seats_stay_the_same_until_a_lunch_is_taken() -> void:
	_fresh_run()
	var first := GameState.seat_options("VN01").map(func(r: Dictionary) -> String: return str(r["choice_id"]))
	assert_eq(first.size(), 3)
	assert_eq(first, GameState.seat_options("VN01").map(func(r: Dictionary) -> String: return str(r["choice_id"])), "stable while you decide")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(first, GameState.seat_options("VN01").map(func(r: Dictionary) -> String: return str(r["choice_id"])), "and after a reload")


func test_a_party_table_takes_an_hour_and_adds_a_point_to_that_partys_opinion() -> void:
	_fresh_run()
	var own := str(DataDB.player.get("party", ""))
	var seat := {}
	for row: Dictionary in VenueChoices.rows_for(DataDB.venue_choices, "VN01", "seat"):
		if row.get("party") != null and str(DataDB.get_party_by_id(str(row["party"])).get("name", "")) != own:
			seat = row
			break
	var party_name := str(DataDB.get_party_by_id(str(seat["party"])).get("name", ""))
	# Put that table on offer by making it the only one the draw can pick from.
	DataDB.venue_choices = DataDB.venue_choices.filter(func(r: Dictionary) -> bool: return str(r.get("step")) == "meal" or str(r["choice_id"]) in [str(seat["choice_id"])])
	DataDB.venue_choices.append_array(_pool(0))
	var meals := GameState.meal_options("VN01")
	var plain := meals.filter(func(r: Dictionary) -> bool: return r.get("extra_rewards") == null)[0] as Dictionary
	var before := int(GameState.party_standing.get(party_name, 50))
	var hours := GameState.work_hours_left()
	var done := GameState.do_choice_visit("VN01", str(seat["choice_id"]), str(plain["choice_id"]))
	assert_true(bool(done["ok"]), str(done.get("reason", "")))
	assert_eq(GameState.work_hours_left(), hours - 1, "the visit's hour")
	assert_eq(int(GameState.party_standing.get(party_name, 50)), before + 1, "+1 to %s's opinion" % party_name)
	assert_eq(GameState.venue_choice_rolls, 1)
	assert_true((done["effects"] as Array).any(func(line: String) -> bool: return line.contains(party_name)), "the result says so")


func test_a_seat_that_is_not_on_offer_is_refused_and_nothing_is_spent() -> void:
	_fresh_run()
	var offered := GameState.seat_options("VN01").map(func(r: Dictionary) -> String: return str(r["choice_id"]))
	var other := ""
	for row: Dictionary in VenueChoices.rows_for(DataDB.venue_choices, "VN01", "seat"):
		if not offered.has(str(row["choice_id"])):
			other = str(row["choice_id"])
			break
	var meal := str(GameState.meal_options("VN01")[0]["choice_id"])
	var hours := GameState.work_hours_left()
	assert_false(bool(GameState.do_choice_visit("VN01", other, meal)["ok"]))
	assert_eq(GameState.work_hours_left(), hours)


func test_a_certain_extra_lands_and_the_same_lunch_gives_the_same_luck_after_a_reload() -> void:
	_fresh_run()
	var meal := {}
	for row: Dictionary in VenueChoices.rows_for(DataDB.venue_choices, "VN01", "meal"):
		if str(row["name"]) == "Sito dumplings":
			meal = row.duplicate(true)
	meal["chance"] = 1   # certain, for the test
	DataDB.venue_choices = DataDB.venue_choices.map(func(r: Dictionary) -> Dictionary: return meal if str(r["choice_id"]) == str(meal["choice_id"]) else r)
	var seat := str(GameState.seat_options("VN01")[0]["choice_id"])
	var saved := GameState.to_save()
	var ainu_before := [int(GameState.booster_standing.get("BO28", 0)), int(GameState.booster_standing.get("BO29", 0))]
	var first := GameState.do_choice_visit("VN01", seat, str(meal["choice_id"]))
	var gained: Array = [int(GameState.booster_standing.get("BO28", 0)) - ainu_before[0], int(GameState.booster_standing.get("BO29", 0)) - ainu_before[1]]
	assert_eq(gained[0] + gained[1], 1, "one of the two Ainu groups gets the point")
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	var again := GameState.do_choice_visit("VN01", seat, str(meal["choice_id"]))
	assert_eq(again["effects"], first["effects"], "the same lunch, the same luck")


func test_the_extra_is_told_before_the_choice_with_its_odds() -> void:
	_fresh_run()
	for row: Dictionary in VenueChoices.rows_for(DataDB.venue_choices, "VN01", "meal"):
		if str(row["name"]) == "Sito dumplings":
			var line := GameState.chance_line(row)
			assert_true(line.begins_with("1 in 10: "), line)
			assert_true(line.contains("Ainu Community Council or Ainu Language and Culture Foundation"), line)
			return
	fail_test("no Sito dumplings")


func test_catch_up_on_paperwork_takes_one_hour_anywhere_and_has_a_one_in_ten_extra() -> void:
	_fresh_run()
	var activity := GameState.office_activity()
	assert_eq(str(activity["activity_id"]), "VA19")
	assert_eq(int(activity["chance"]), 10)
	assert_eq(GameState.activity_refusal("VA19"), "", "available at the Capitol office")
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.activity_refusal("VA19"), "", "and at the District office")
	var hours := GameState.work_hours_left()
	assert_true(bool(GameState.do_activity("VA19")["ok"]))
	assert_eq(GameState.work_hours_left(), hours - 1, "one hour and no walking")
	assert_true(GameState.chance_line(activity).begins_with("1 in 10: Party Headquarters, Party Faction"), GameState.chance_line(activity))
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}
	assert_ne(GameState.activity_refusal("VA19"), "", "greyed with a reason when the week is full")


func test_a_certain_paperwork_extra_adds_one_point_to_one_of_the_listed_groups() -> void:
	_fresh_run()
	var activity := GameState.office_activity()
	var saved_chance: Variant = activity["chance"]
	activity["chance"] = 1
	var pool := ["BO01", "BO02", "BO31", "BO32", "BO17"]
	var before := {}
	for id: String in pool:
		before[id] = int(GameState.booster_standing.get(id, 0))
	assert_true(bool(GameState.do_activity("VA19")["ok"]))
	var total := 0
	for id: String in pool:
		total += int(GameState.booster_standing.get(id, 0)) - int(before[id])
	activity["chance"] = saved_chance
	assert_eq(total, 1, "exactly one point, with one of the five")


# --- The screens --------------------------------------------------------------------------------------------------------------------

func test_eat_with_colleagues_asks_for_a_seat_then_a_meal_then_listens_in() -> void:
	_fresh_run()
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	office._venues._on_activity("VN01")
	await get_tree().process_frame
	var venue := office.get_node("VenuePanel") as Overlay
	assert_eq(venue.find_children("Choice_*", "PanelContainer", true, false).size(), 3, "three seats")
	var hours := GameState.work_hours_left()
	assert_eq(hours, 40, "nothing is spent before the meal is ordered")
	var seat_button := venue.find_children("Pick_*", "Button", true, false)[0] as Button
	seat_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(venue.find_children("Choice_*", "PanelContainer", true, false).size(), 10, "ten meals")
	(venue.find_children("Pick_*", "Button", true, false)[0] as Button).pressed.emit()
	await get_tree().process_frame
	assert_eq(GameState.work_hours_left(), 39, "the hour is taken when the meal is ordered")
	var result := office.get_node("VenueResultPanel") as Overlay
	assert_true(result.visible and result.find_child("Back", true, false) != null, "the lunch result card")
	(result.find_child("Back", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_true((office.get_node("VenueLinePanel") as Overlay).visible, "Listen in opens the conversation")


func test_the_paperwork_button_shares_a_row_with_step_out_and_asks_before_it_does() -> void:
	_fresh_run()
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	var button := office.find_child("PaperworkButton", true, false) as Button
	assert_not_null(button)
	assert_eq(button.get_parent(), (office.find_child("StepOutButton", true, false) as Button).get_parent(), "beside Step out")
	assert_eq(button.text, "Catch Up on Paperwork · 1 h")
	button.pressed.emit()
	await get_tree().process_frame
	var card := office.get_node("PaperworkPanel") as Overlay
	assert_true(card.visible, "it asks first: the cost and the odds")
	assert_eq(GameState.work_hours_left(), 40, "nothing spent yet")
	card.confirmed.emit()
	await get_tree().process_frame
	assert_eq(GameState.work_hours_left(), 39)
