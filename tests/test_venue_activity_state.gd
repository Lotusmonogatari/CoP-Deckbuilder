extends GutTest
## Costed venue activities in the run (2026-11-24): the shrine, the shotengai and the Library. Costs, rewards, daily limits that start
## again tomorrow, the shrine's cumulative gifts, the Library's staff hours and the 50-use bonus, and why an activity is refused.

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	GameState.meta["Funds"] = 50000


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL


func _standing(booster_id: String) -> int:
	return int(GameState.booster_standing.get(booster_id, 0))


func _next_day() -> void:
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	GameState.spend_hours(8)   # a workday is 8 hours: the next one begins


func test_cleaning_the_shrine_costs_two_hours_gives_standing_and_is_limited_to_twice_a_day() -> void:
	var before := [_standing("BO20"), _standing("BO19"), _standing("BO15")]
	var done := GameState.do_activity("VA08")
	assert_true(bool(done["ok"]))
	assert_eq(GameState.work_hours_left(), 38, "two hours spent")
	assert_eq([_standing("BO20"), _standing("BO19"), _standing("BO15")], [before[0] + 2, before[1] + 2, before[2] + 2])
	assert_eq((done["effects"] as Array).size(), 3, "the result says what each organization got")
	assert_true(bool(GameState.do_activity("VA08")["ok"]), "the second time today")
	assert_false(bool(GameState.do_activity("VA08")["ok"]), "a third time today is refused")
	assert_eq(GameState.activity_refusal("VA08"), Text.say("venue.refuse_limit"))
	assert_eq(GameState.work_hours_left(), 36, "the refused one cost nothing")


func test_a_daily_limit_starts_again_the_next_day() -> void:
	GameState.do_activity("VA10")
	assert_eq(GameState.activity_left_today("VA10"), 0, "the saisenbako is once a day")
	_next_day()
	assert_eq(GameState.activity_left_today("VA10"), 1, "tomorrow it is open again")


func test_the_saisenbako_costs_1000_yen_and_refuses_with_too_little_funds() -> void:
	GameState.meta["Funds"] = 999
	assert_eq(GameState.activity_refusal("VA10"), Text.say("venue.refuse_funds"))
	GameState.meta["Funds"] = 5000
	assert_true(bool(GameState.do_activity("VA10")["ok"]))
	assert_eq(int(GameState.meta["Funds"]), 4000)
	assert_eq(GameState.work_hours_left(), 40, "it takes no hours")


func test_paying_respects_counts_and_gives_each_gift_once_at_its_count() -> void:
	GameState.meta["Funds"] = 0
	GameState.venue_activity_totals["VA11"] = 4
	var fifth := GameState.do_activity("VA11")
	assert_eq((fifth["gifts"] as Array).size(), 1, "the 5th respect finds money")
	assert_eq(int(GameState.meta["Funds"]), 5000)
	assert_eq(str(fifth["gifts"][0]["text"]), "You found 5,000円.")
	_next_day()
	assert_eq((GameState.do_activity("VA11")["gifts"] as Array).size(), 0, "the 6th respect gives nothing more")
	assert_eq(GameState.activity_times_done("VA11"), 6)


func test_the_30th_respect_gives_a_training_coupon() -> void:
	GameState.venue_activity_totals["VA11"] = 29
	var coupons := GameState.item_count(str(DataDB.get_rule("training_coupon_item", "SH21")))
	var done := GameState.do_activity("VA11")
	assert_eq(str(done["gifts"][0]["text"]), "You found a free rhetoric training session coupon.")
	assert_eq(GameState.item_count(str(DataDB.get_rule("training_coupon_item", "SH21"))), coupons + 1)


func test_the_75th_and_150th_respects_give_standing_and_district_awareness() -> void:
	GameState.venue_activity_totals["VA11"] = 74
	var aware := int(GameState.awareness["district"])
	var standing := _standing("BO20")
	GameState.do_activity("VA11")
	assert_eq(_standing("BO20"), standing + 10)
	assert_eq(int(GameState.awareness["district"]), aware + 10)
	_next_day()
	GameState.venue_activity_totals["VA11"] = 149
	GameState.meta["Funds"] = 0
	aware = int(GameState.awareness["district"])
	standing = _standing("BO20")
	var done := GameState.do_activity("VA11")
	assert_eq(_standing("BO20"), standing + 25)
	assert_eq(int(GameState.awareness["district"]), aware + 25)
	assert_eq(int(GameState.meta["Funds"]), 100000, "and a token of the locals' appreciation")
	assert_eq((done["gifts"] as Array).size(), 1)


func test_the_shotengai_activities_cost_and_give_what_they_say() -> void:
	var aware := int(GameState.awareness["district"])
	GameState.do_activity("VA09")   # flyers
	assert_eq(int(GameState.awareness["district"]), aware + 1)
	assert_eq(GameState.work_hours_left(), 38)
	var voters := _standing("BO18")
	var koenkai := _standing("BO03")
	GameState.do_activity("VA12")   # megaphone
	assert_eq(int(GameState.awareness["district"]), aware + 4)
	assert_eq([_standing("BO18"), _standing("BO03")], [voters - 1, koenkai - 1])
	assert_eq(GameState.work_hours_left(), 35)
	var meal := GameState.do_activity("VA13")
	assert_true(bool(meal["ok"]))
	assert_eq(int(GameState.meta["Funds"]), 35000, "15,000円 for the meal")
	assert_eq(_standing("BO03"), koenkai - 1 + 3)
	assert_eq(GameState.activity_left_today("VA13"), 1, "twice a day")


func test_a_nap_gives_energy_for_the_next_stage_and_reading_gives_staff_hours() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.do_activity("VA14")
	assert_eq(int(GameState.pending_stage_bonuses.get("ENERGY", 0)), 1, "+1 energy next stage")
	assert_eq(GameState.staff_activity_hours_today(), 0)
	GameState.do_activity("VA15")
	assert_eq(GameState.staff_activity_hours_today(), 1, "+1 work hour for all staff today")
	assert_eq(GameState.staff_office_hours(), 1, "the staff day reads it")
	_next_day()
	assert_eq(GameState.staff_activity_hours_today(), 0, "it lasts only today")


func test_reading_gives_a_flat_extra_hour_from_the_51st_use() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.venue_activity_totals["VA15"] = 49
	GameState.do_activity("VA15")   # the 50th
	assert_eq(GameState.staff_activity_hours_today(), 1)
	_next_day()
	GameState.do_activity("VA15")   # the 51st
	assert_eq(GameState.staff_activity_hours_today(), 2, "the bonus begins after 50")


func test_an_activity_is_refused_away_from_its_office_in_a_level_and_when_the_week_is_full() -> void:
	assert_eq(GameState.activity_refusal("VA14"), Text.say("venue.refuse_elsewhere"), "the Library is at the Capitol")
	GameState.office_location = Offices.CAPITOL
	assert_eq(GameState.activity_refusal("VA08"), Text.say("venue.refuse_elsewhere"), "the shrine is at the District office")
	assert_eq(GameState.activity_refusal("VA02"), Text.say("venue.coming_soon"), "Browse the Shelves is still to come")
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.activity_refusal("VA08"), Text.say("venue.refuse_week_full"))
	GameState.calendar = {"week": 2, "phase": "work", "hours": 39}
	assert_eq(GameState.activity_refusal("VA08"), Text.say("venue.refuse_hours"), "one hour left, two needed")


func test_the_use_counts_are_part_of_the_save() -> void:
	for field: String in ["venue_activity_log", "venue_activity_totals", "staff_activity_hours"]:
		assert_true(GameState._SAVED_FIELDS.has(field), field + " is saved with the run")


func test_the_speech_coach_lists_training_and_two_practice_activities() -> void:
	GameState.office_location = Offices.CAPITOL
	var names: Array = GameState.venue_activities_of("VN04").map(func(a: Dictionary) -> String: return str(a["name"]))
	assert_eq(names, ["Rhetoric Training", "Practice your talking points", "Work on your speech timing"])


func test_practising_talking_points_costs_an_hour_and_10000_yen_and_adds_to_the_next_stages_gaffe_limit() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.pending_stage_bonuses = {}
	var done := GameState.do_activity("VA16")
	assert_true(bool(done["ok"]))
	assert_eq(GameState.work_hours_left(), 39)
	assert_eq(int(GameState.meta["Funds"]), 40000, "10,000円 spent")
	assert_eq(int(GameState.pending_stage_bonuses.get("GAFFE_CAP", 0)), 1, "+1 to the gaffe limit for the next stage")
	assert_eq(done["effects"], ["Gaffe limit in your next stage +1"])
	assert_false(bool(GameState.do_activity("VA16")["ok"]), "once a day")


func test_working_on_speech_timing_costs_20000_yen_and_an_hour_and_adds_a_turn_to_the_next_stage() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.pending_stage_bonuses = {}
	var done := GameState.do_activity("VA17")
	assert_true(bool(done["ok"]))
	assert_eq(GameState.work_hours_left(), 39)
	assert_eq(int(GameState.meta["Funds"]), 30000, "20,000円 spent")
	assert_eq(int(GameState.pending_stage_bonuses.get("TURNS", 0)), 1, "+1 turn for the next stage")
	assert_eq(done["effects"], ["Turns in your next stage +1"])
	GameState.meta["Funds"] = 19999
	_next_day()
	assert_eq(GameState.activity_refusal("VA17"), Text.say("venue.refuse_funds"), "too little Funds is refused with the reason")
