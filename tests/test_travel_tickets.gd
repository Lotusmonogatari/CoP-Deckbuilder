extends GutTest
## Two offices, slice 4 (2026-11-20): the three tickets, the modes a player can use, what a ticket does when used, and
## the encounters on the train.

var _saved_one_in: Variant


func before_each() -> void:
	GameState.start_new_run("PC04")
	GameState.calendar = WeekCalendar.fresh()
	GameState.office_location = Offices.CAPITOL
	GameState.level_travel = {}
	GameState.inventory = {}
	GameState.travel_encounter = ""
	_saved_one_in = DataDB.balance.get("travel_encounter_one_in")


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.inventory = {}
	DataDB.balance["travel_encounter_one_in"] = _saved_one_in


func test_each_protagonist_is_sold_the_right_tickets() -> void:
	assert_eq(GameState.travel_item_id(Travel.TICKET), "SH42", "the paid train ticket is sold to everyone")
	assert_eq(GameState.travel_item_id(Travel.PLANE), "SH44", "PC04 flies")
	assert_eq(GameState.travel_item_id(Travel.CAR), "", "and has no private car")
	GameState.start_new_run("PC01")
	assert_eq(GameState.travel_item_id(Travel.CAR), "SH43")
	assert_eq(GameState.travel_item_id(Travel.PLANE), "")


func test_the_modes_are_the_pass_and_whatever_tickets_are_held() -> void:
	assert_eq(GameState.travel_modes(), [Travel.PASS] as Array[String])
	GameState.add_item("SH42")
	GameState.add_item("SH44")
	assert_eq(GameState.travel_modes(), [Travel.PASS, Travel.TICKET, Travel.PLANE] as Array[String])


func test_a_paid_ticket_has_the_trains_hours_and_pleases_the_commuter_committee_alone() -> void:
	GameState.add_item("SH42")
	var before := int(GameState.booster_standing.get("BO14", 0))
	var taxpayers := int(GameState.booster_standing.get("BO23", 0))
	var chamber := int(GameState.booster_standing.get("BO05", 0))
	var left := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())
	assert_true(GameState.travel(Travel.TICKET))
	assert_eq(GameState.item_count("SH42"), 0, "the ticket is handed over")
	assert_eq(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()), left - 7, "the same seven hours as the pass")
	assert_eq(int(GameState.booster_standing.get("BO14", 0)), before + 1, "+1 with the Commuter Committee (P17, 2026-11-24)")
	assert_eq(int(GameState.booster_standing.get("BO23", 0)), taxpayers, "no change with the Taxpayers' Alliance any more")
	assert_eq(int(GameState.booster_standing.get("BO05", 0)), chamber, "or the Chamber of Commerce")
	assert_eq(GameState.office_location, Offices.DISTRICT)


func test_a_ticket_mode_is_refused_when_none_is_held() -> void:
	assert_eq(GameState.travel_refusal(Travel.PLANE), Text.say("travel.refuse_no_ticket", {"mode": "plane ticket"}))
	assert_false(GameState.travel(Travel.PLANE))
	assert_eq(GameState.office_location, Offices.CAPITOL)


func test_a_plane_takes_two_hours_from_noheji() -> void:
	GameState.add_item("SH44")
	var left := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())
	assert_true(GameState.travel(Travel.PLANE))
	assert_eq(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()), left - 2)
	assert_eq(GameState.item_count("SH44"), 0)


func test_a_mixed_level_uses_one_ticket_for_each_trip() -> void:
	var level := DataDB.get_level("LV10")   # 27 hours, two trips: out and back
	GameState.add_item("SH44")
	assert_eq(GameState.level_travel_refusal(level, Travel.PLANE), Text.say("briefing.refuse_tickets", {"count": 2, "mode": "plane ticket"}), "one ticket is not enough for two trips")
	assert_eq(GameState.level_travel_refusal(level, Travel.PASS), "")
	GameState.add_item("SH44")
	assert_eq(GameState.level_travel_refusal(level, Travel.PLANE), "")
	var options := GameState.level_travel_options(level)
	assert_eq(options.map(func(o: Dictionary) -> String: return o["mode"]), ["train", "plane"])
	assert_eq(options[0]["hours"], 14)
	assert_eq(options[1]["hours"], 4)
	GameState.pay_level_travel(level, Travel.PLANE)
	assert_eq(GameState.item_count("SH44"), 0, "two trips, two tickets")
	assert_eq(GameState.level_calendar_refusal(level, Travel.PLANE), "", "LV10 fits the week by plane (31 hours)")


func test_the_marketplace_sells_a_ticket_only_to_who_it_is_for() -> void:
	assert_true(GameState.item_offered(DataDB.get_shop_item("SH42")))
	assert_true(GameState.item_offered(DataDB.get_shop_item("SH44")))
	assert_false(GameState.item_offered(DataDB.get_shop_item("SH43")))


# --- encounters -------------------------------------------------------------------------

func test_there_are_six_train_encounters_with_a_free_choice_each() -> void:
	var pool := EventEngine.train_events(DataDB.events)
	assert_eq(pool.size(), 6)
	for event: Dictionary in pool:
		var choices := EventEngine.choices_for(DataDB.event_choices, str(event["event_id"]))
		assert_eq(choices.size(), 3, "%s has three choices" % event["event_id"])
		var free := false
		for choice: Dictionary in choices:
			free = free or (choice.get("rewards") == null and choice.get("funds_cost") == null)
		assert_true(free, "%s has a choice that costs and gives nothing" % event["event_id"])
		assert_eq(Offices.normalize(event.get("location")), Offices.EITHER)


func test_an_encounter_happens_by_pass_or_ticket_but_never_by_car_or_plane() -> void:
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	DataDB.balance["travel_encounter_one_in"] = 1
	var found := GameState.roll_travel_encounter(Travel.PASS)
	assert_eq(str(GameState.get_event(found).get("trigger", "")), "Train", "one in one: always")
	assert_ne(GameState.roll_travel_encounter(Travel.TICKET), "")
	assert_eq(GameState.roll_travel_encounter(Travel.PLANE), "", "a plane skips it")
	assert_eq(GameState.roll_travel_encounter(Travel.CAR), "", "and so does a car")
	DataDB.balance["travel_encounter_one_in"] = 0
	assert_eq(GameState.roll_travel_encounter(Travel.PASS), "", "switched off")
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")


func test_a_trip_that_brings_an_encounter_keeps_it_until_it_is_shown() -> void:
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	DataDB.balance["travel_encounter_one_in"] = 1
	assert_true(GameState.travel(Travel.PASS))
	var encounter := GameState.take_travel_encounter()
	assert_ne(encounter, "")
	assert_eq(GameState.take_travel_encounter(), "", "said once")
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")


func test_the_encounter_rate_is_one_trip_in_eight() -> void:
	assert_eq(Levers.whole("travel_encounter_one_in"), 8)


func test_only_pc04_starts_with_plane_tickets() -> void:
	# Cameron, 2026-11-20: PC04 (Noheji, seven hours by rail) starts with four plane tickets; nobody else gets a ticket.
	GameState.start_new_run("PC04")
	assert_eq(GameState.item_count("SH44"), 4, "PC04 starts with four plane tickets")
	assert_eq(GameState.travel_tickets(Travel.PLANE), 4, "and they count as tickets for the trip")
	for pid: String in ["PC02", "PC03", "PC01"]:
		GameState.start_new_run(pid)
		for item: String in ["SH42", "SH43", "SH44"]:
			assert_eq(GameState.item_count(item), 0, "%s starts with no %s" % [pid, item])
	GameState.start_new_run("PC04")
