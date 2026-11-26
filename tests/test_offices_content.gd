extends GutTest
## Two offices, slice 3 (2026-11-20): events, follow-ups, promises, notices, the ticker and visitors belong to an
## office, and the data is tagged.

func before_each() -> void:
	GameState.start_new_run("PC04")
	GameState.calendar = WeekCalendar.fresh()
	GameState.office_location = Offices.CAPITOL
	GameState.promises = []
	GameState.scheduled_events = []


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL
	GameState.promises = []
	GameState.scheduled_events = []


func _context(office: String) -> Dictionary:
	var ctx := GameState.event_context()
	ctx["office"] = office
	ctx["district"] = 100   # known enough for every event
	ctx["national"] = 100
	ctx["dues_owed"] = 1
	return ctx


# --- the data -------------------------------------------------------------------------

func test_the_events_are_tagged() -> void:
	var counts := {"Capitol": 0, "District": 0, "Either": 0}
	for event: Dictionary in DataDB.events:
		counts[Offices.normalize(event.get("location"))] += 1
		assert_true(event.get("location") != null, "%s has a Location" % event["event_id"])
	assert_eq(counts, {"Capitol": 38, "District": 66, "Either": 23}, "the 17 tagged Either and the six train encounters; nine CPTPP scene events (P15) add seven Capitol and two District; fifteen campaign events (P20) add three Capitol and twelve District")
	for n in range(95, 105):
		assert_eq(Offices.normalize(GameState.get_event("EV%d" % n).get("location")), Offices.CAPITOL, "EV%d is a Capitol event" % n)


func test_the_visitors_and_notices_are_tagged() -> void:
	var visitors := {"Capitol": 0, "District": 0, "Either": 0}
	for visitor: Dictionary in DataDB.visitors:
		visitors[Offices.normalize(visitor.get("location"))] += 1
	assert_eq(visitors, {"Capitol": 27, "District": 133, "Either": 16})   # VI175 and VI176, the new party whips (P15)
	var greeting: Dictionary = {}
	for row: Dictionary in DataDB.office_notices:
		if str(row["notice_id"]) == "ON01":
			greeting = row
	assert_eq(Offices.normalize(greeting.get("location")), Offices.DISTRICT, "the District Representative's greeting moves to the District office")


# --- events ---------------------------------------------------------------------------

func test_each_office_draws_only_its_own_events() -> void:
	var capitol := EventEngine.eligible_random(DataDB.events, _context(Offices.CAPITOL))
	var district := EventEngine.eligible_random(DataDB.events, _context(Offices.DISTRICT))
	assert_gt(capitol.size(), 5, "the Capitol has events to draw")
	assert_gt(district.size(), capitol.size(), "the District has more (52 against 28)")
	for event: Dictionary in capitol:
		assert_ne(Offices.normalize(event.get("location")), Offices.DISTRICT, "%s at the Capitol" % event["event_id"])
	for event: Dictionary in district:
		assert_ne(Offices.normalize(event.get("location")), Offices.CAPITOL, "%s at the District office" % event["event_id"])


func test_a_follow_up_waits_for_its_office() -> void:
	var district_event := ""
	for event: Dictionary in DataDB.events:
		if str(event.get("trigger", "")) == "Followup" and Offices.normalize(event.get("location")) == Offices.DISTRICT:
			district_event = str(event["event_id"])
			break
	assert_false(district_event.is_empty(), "the data has a District follow-up")
	GameState.scheduled_events = [{"event_id": district_event, "due_at": 0}]
	assert_eq(GameState.take_due_followup(), "", "not at the Capitol")
	assert_eq(GameState.scheduled_events.size(), 1, "it is still waiting")
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.take_due_followup(), district_event, "it arrives on arrival")


# --- promises -------------------------------------------------------------------------

func test_a_promise_is_kept_at_the_office_of_its_choice() -> void:
	var entry := {"kind": Promises.PROMISE_HOURS, "amount": 2}
	var made := Promises.make(entry, 0, 48, "BO01", "x", 1, "District")
	assert_eq(made["location"], Offices.DISTRICT)
	assert_eq(Promises.keep_refusal(made, {}, 40, 0, Offices.CAPITOL), "office")
	assert_eq(Promises.keep_refusal(made, {}, 40, 0, Offices.DISTRICT), "")
	assert_eq(Promises.keep_refusal(made, {}, 40), "", "no office asked: as before")
	var either := Promises.make(entry, 0, 48, "BO01", "x", 2, "")
	assert_eq(either["location"], Offices.EITHER)
	assert_eq(Promises.keep_refusal(either, {}, 40, 0, Offices.CAPITOL), "")
	assert_eq(Promises.keep_refusal({"kind": Promises.PROMISE_HOURS, "hours": 2}, {}, 40, 0, Offices.CAPITOL), "", "an old save's promise has none")


func test_a_promise_made_now_takes_the_office_the_player_is_at() -> void:
	GameState.office_location = Offices.DISTRICT
	GameState.pay_commitments([{"kind": Promises.PROMISE_HOURS, "amount": 2}], "A visit", "BO01")
	assert_eq(GameState.promises.size(), 1)
	assert_eq(GameState.promises[0]["location"], Offices.DISTRICT)
	GameState.promises = []
	GameState.pay_commitments([{"kind": Promises.PROMISE_HOURS, "amount": 2}], "An event", "BO01", {}, "Capitol")
	assert_eq(GameState.promises[0]["location"], Offices.CAPITOL, "the choice's own Location wins")


func test_the_keep_button_says_where_the_promise_is_kept() -> void:
	GameState.office_location = Offices.DISTRICT
	GameState.pay_commitments([{"kind": Promises.PROMISE_HOURS, "amount": 2}], "A visit", "BO01")
	GameState.office_location = Offices.CAPITOL
	assert_eq(GameState.promise_keep_refusal(GameState.promises[0]), Text.say("promises.refuse_elsewhere", {"place": "Noheji"}))
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.promise_keep_refusal(GameState.promises[0]), "")


# --- notices, the ticker and visitors ------------------------------------------------------

func test_a_notice_and_a_ticker_line_can_belong_to_one_office() -> void:
	var rows := [{"slot": "a", "condition_type": "always", "text_en": "Here", "location": "District"},
		{"slot": "b", "condition_type": "always", "text_en": "Everywhere"}]
	assert_eq(OfficeNotices.resolve(rows, {}, {}, [], {"office": "Capitol"}), ["Everywhere"] as Array[String])
	assert_eq(OfficeNotices.resolve(rows, {}, {}, [], {"office": "District"}), ["Here", "Everywhere"] as Array[String])
	assert_eq(OfficeTicker.eligible_lines(rows, {}, {}, "", {"office": "Capitol"}), ["Everywhere"] as Array[String])
	assert_eq(OfficeTicker.eligible_lines(rows, {}, {}, "", {"office": "District"}), ["Here", "Everywhere"] as Array[String])
	assert_eq(OfficeNotices.resolve(rows, {}, {}, [], {}), ["Here", "Everywhere"] as Array[String], "no office asked: all of them, as before")


func test_the_visitors_who_come_depend_on_the_office() -> void:
	var district_only := ""
	var capitol_only := ""
	for visitor: Dictionary in DataDB.visitors:
		if (visitor.get("stages", []) as Array).has("ST07"):
			var office := Offices.normalize(visitor.get("location"))
			if office == Offices.DISTRICT and district_only.is_empty():
				district_only = str(visitor["visitor_id"])
			if office == Offices.CAPITOL and capitol_only.is_empty():
				capitol_only = str(visitor["visitor_id"])
	assert_false(district_only.is_empty() or capitol_only.is_empty(), "the Office Hours room has visitors of both kinds")
	var all := BattleSetup.eligible_visitors("ST07")
	GameState.office_location = Offices.CAPITOL
	var at_capitol := BattleSetup.prefer_here(all, 3).map(func(v: Dictionary) -> String: return str(v["visitor_id"]))
	assert_true(at_capitol.has(capitol_only))
	assert_false(at_capitol.has(district_only), "a constituent does not visit the Capitol")
	GameState.office_location = Offices.DISTRICT
	var at_district := BattleSetup.prefer_here(all, 3).map(func(v: Dictionary) -> String: return str(v["visitor_id"]))
	assert_true(at_district.has(district_only))
	assert_false(at_district.has(capitol_only), "a fellow member does not visit the District office")


func test_a_room_is_filled_out_when_few_visitors_belong_to_the_office() -> void:
	# A room that seats ten must still seat ten, even if only a few of its visitors belong to this office.
	var pool: Array = []
	for i in 12:
		pool.append({"visitor_id": "V%d" % i, "location": "District" if i > 0 else "Capitol"})
	GameState.office_location = Offices.CAPITOL
	var drawn := BattleSetup.prefer_here(pool, 10)
	assert_eq(drawn.size(), 10, "filled out to the number wanted")
	assert_eq(drawn[0]["visitor_id"], "V0", "the one that belongs here is in it")
