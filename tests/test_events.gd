extends GutTest
## Events (2026-10-23): Buyable and Random events, fixed choices, variable
## rewards, a level an event can reveal.

var _meta_before: Dictionary = {}
var _xp_before := 0
var _calendar_before: Dictionary = {}
var _units_before := 0
var _discovered_before: Array = []
var _last_before: Dictionary = {}
var _awareness_before: Dictionary = {}


func before_each() -> void:
	_meta_before = GameState.meta.duplicate()
	_xp_before = GameState.xp
	_calendar_before = GameState.calendar.duplicate()
	_units_before = GameState.time_units
	_discovered_before = GameState.discovered_levels.duplicate()
	_last_before = GameState.event_last_at.duplicate()
	_awareness_before = GameState.awareness.duplicate()
	GameState.calendar = WeekCalendar.fresh()
	GameState.event_last_at = {}
	GameState.discovered_levels = []
	GameState.meta["Funds"] = 200000


func after_each() -> void:
	GameState.meta = _meta_before
	GameState.xp = _xp_before
	GameState.calendar = _calendar_before
	GameState.time_units = _units_before
	GameState.discovered_levels.assign(_discovered_before)
	GameState.event_last_at = _last_before
	GameState.awareness = _awareness_before


func _ctx(over: Dictionary = {}) -> Dictionary:
	var base := {"weekend": false, "week_full": false, "hours_left": 40, "funds": 100000, "xp": 0,
		"now": 100, "last_at": {}, "default_cooldown": 24, "district": 30, "national": 30}
	base.merge(over, true)
	return base


func test_the_tabs_ship_events_with_choices() -> void:
	assert_gte(DataDB.events.size(), 12)
	for event: Dictionary in DataDB.events:
		var found := EventEngine.choices_for(DataDB.event_choices, str(event["event_id"]))
		assert_gt(found.size(), 1, "%s has choices" % event["event_id"])


func test_choices_come_back_in_letter_order() -> void:
	var letters: Array = []
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, "EV32"):
		letters.append(str(row["choice"]))
	assert_eq(letters, ["A", "B", "C"])


func test_weekday_and_weekend_availability() -> void:
	var weekday := {"event_id": "X", "available": "Weekday", "hours": 2}
	var weekend := {"event_id": "Y", "available": "Weekend", "hours": 2}
	assert_eq(EventEngine.refusal(weekday, _ctx()), "")
	assert_eq(EventEngine.refusal(weekday, _ctx({"weekend": true, "hours_left": 8})), EventEngine.REFUSE_WEEKDAY)
	assert_eq(EventEngine.refusal(weekend, _ctx()), EventEngine.REFUSE_WEEKEND)
	assert_eq(EventEngine.refusal(weekend, _ctx({"weekend": true, "hours_left": 8})), "")


func test_a_weekend_event_must_fit_in_the_hours_left() -> void:
	var tour := {"event_id": "X", "available": "Both", "hours": 4}
	assert_eq(EventEngine.refusal(tour, _ctx({"weekend": true, "hours_left": 3})), EventEngine.REFUSE_HOURS)
	assert_eq(EventEngine.refusal(tour, _ctx({"hours_left": 1})), "", "weekdays let the extra hours spill")


func test_a_finished_work_week_refuses_everything() -> void:
	var tour := {"event_id": "X", "available": "Both", "hours": 1}
	assert_eq(EventEngine.refusal(tour, _ctx({"week_full": true})), EventEngine.REFUSE_WEEK_OVER)


func test_price_and_cooldown_refuse() -> void:
	var paid := {"event_id": "X", "available": "Both", "hours": 1, "cost_funds": 50000, "cost_xp": 10}
	assert_eq(EventEngine.refusal(paid, _ctx({"funds": 1000})), EventEngine.REFUSE_FUNDS)
	assert_eq(EventEngine.refusal(paid, _ctx({"xp": 0})), EventEngine.REFUSE_XP)
	assert_eq(EventEngine.refusal(paid, _ctx({"xp": 10})), "")
	assert_eq(EventEngine.refusal(paid, _ctx({"xp": 10, "last_at": {"X": 90}})), EventEngine.REFUSE_COOLDOWN)
	assert_eq(EventEngine.refusal(paid, _ctx({"xp": 10, "last_at": {"X": 70}})), "", "24 hours later")


func test_random_events_wait_for_enough_awareness() -> void:
	var events := [{"event_id": "R1", "trigger": "Random", "available": "Both", "weight": 5, "min_national_awareness": 20},
		{"event_id": "B1", "trigger": "Buyable", "available": "Both", "weight": 5}]
	assert_eq(EventEngine.eligible_random(events, _ctx({"national": 10})).size(), 0)
	assert_eq(EventEngine.eligible_random(events, _ctx({"national": 20})).size(), 1, "never a Buyable event")


func test_a_weighted_pick_follows_the_roll() -> void:
	var events := [{"event_id": "A", "weight": 1}, {"event_id": "B", "weight": 3}]
	assert_eq(str(EventEngine.pick_weighted(events, 0.1)["event_id"]), "A")
	assert_eq(str(EventEngine.pick_weighted(events, 0.5)["event_id"]), "B")
	assert_eq(EventEngine.pick_weighted([], 0.5), {})


func test_arranging_an_event_charges_its_price() -> void:
	assert_true(GameState.start_event("EV32"))
	assert_eq(int(GameState.meta["Funds"]), 180000)
	GameState.meta["Funds"] = 100
	assert_false(GameState.start_event("EV32"), "cannot afford it")
	assert_eq(int(GameState.meta["Funds"]), 100)


func test_a_choice_applies_its_rewards_and_spends_the_hours() -> void:
	GameState.awareness = {"district": 20, "national": 10}
	var result := GameState.apply_event_choice("EV32", "A")
	assert_true(result["ok"])
	assert_eq(int(GameState.calendar["hours"]), 2)
	assert_gte(int(GameState.awareness["district"]), 22)
	assert_lte(int(GameState.awareness["district"]), 23)
	assert_gt((result["lines"] as Array).size(), 0)
	assert_true(GameState.event_last_at.has("EV32"))


func test_a_choice_with_a_price_needs_the_money() -> void:
	GameState.meta["Funds"] = 1000
	assert_false(GameState.apply_event_choice("EV31", "C")["ok"], "the whole week of spots costs 10,000")
	assert_eq(int(GameState.calendar["hours"]), 0, "nothing happened")
	GameState.meta["Funds"] = 15000
	assert_true(GameState.apply_event_choice("EV31", "C")["ok"])


func test_a_choice_can_reveal_a_level_that_stays_hidden_until_then() -> void:
	var level := DataDB.get_level("LV34")
	assert_false(GameState.is_level_discovered(level), "LV34 needs discovering")
	var result := GameState.apply_event_choice("EV12", "A")
	assert_ne(str(result["revealed"]), "")
	assert_true(GameState.is_level_discovered(level))
	assert_true(GameState.discovered_levels.has("LV34"))


func test_ordinary_levels_are_always_discovered() -> void:
	assert_true(GameState.is_level_discovered(DataDB.get_level("LV01")))


func test_a_quiet_roll_consumes_the_chance() -> void:
	DataDB.balance["event_random_chance_percent"] = 0
	GameState.event_roll_due = true
	assert_eq(GameState.roll_random_event(), "")
	assert_false(GameState.event_roll_due)
	DataDB.balance["event_random_chance_percent"] = 35


func test_events_are_saved_with_the_run() -> void:
	GameState.discovered_levels = ["LV34"]
	GameState.event_last_at = {"EV32": 12}
	var saved := GameState.to_save()
	assert_eq((saved["discovered_levels"] as Array), ["LV34"])
	assert_eq(int((saved["event_last_at"] as Dictionary)["EV32"]), 12)
