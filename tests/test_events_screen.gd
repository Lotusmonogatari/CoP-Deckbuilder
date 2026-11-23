extends GutTest
## Events on the shared frame (P13, 2026-11-20). Only what can be arranged at the office the player stands at is listed; a
## dated event coming up (a Decision!) is a red banner with no price and no button, never a buy row; an event that cannot be
## arranged shows the rules' own reason in red with a greyed button; and the Coming up tab lists the dated events ahead.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.dated_events_done = []
	# Monday 18.10.08: a week before the Prime Minister's address (18.10.15, parliament opens), so it is coming up.
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""
	GameState.office_location = Offices.CAPITOL


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


# --- the pure reader -------------------------------------------------------------------------------------------------

func test_upcoming_dated_events_are_after_today_within_the_horizon_unplayed_and_in_date_order() -> void:
	var today := WeekCalendar.parse_date("18.10.01")
	var events := [
		{"event_id": "A", "trigger": "Dated", "on_date": "18.10.06"},
		{"event_id": "B", "trigger": "Dated", "on_date": "18.10.03"},
		{"event_id": "C", "trigger": "Dated", "on_date": "18.10.01"},
		{"event_id": "D", "trigger": "Dated", "on_date": "18.09.30"},
		{"event_id": "E", "trigger": "Dated", "on_date": "18.10.20"},
		{"event_id": "F", "trigger": "Buyable", "on_date": "18.10.02"},
		{"event_id": "G", "trigger": "Dated", "on_date": "18.10.02"},
	]
	var found := EventEngine.upcoming_dated(events, today, 7, ["G"])
	var ids: Array[String] = []
	for event: Dictionary in found:
		ids.append(str(event["event_id"]))
	assert_eq(ids, ["B", "A"] as Array[String], "C is today's and D is past (due_dated's), E is too far, F is not dated, G is played")


func test_a_due_event_is_never_also_upcoming() -> void:
	var today := WeekCalendar.parse_date("18.10.08")
	var events := [{"event_id": "A", "trigger": "Dated", "on_date": "18.10.08"}]
	assert_eq(EventEngine.upcoming_dated(events, today, 7, []).size(), 0)
	assert_eq(EventEngine.due_dated(events, today, []).size(), 1)


# --- the model -------------------------------------------------------------------------------------------------------

func test_only_events_that_can_be_arranged_here_are_listed_with_their_reason() -> void:
	for office_name: String in [Offices.CAPITOL, Offices.DISTRICT]:
		GameState.office_location = office_name
		var rows := EventsModel.rows()
		var buyable := GameState.buyable_events()
		assert_eq(rows.size(), buyable.size(), office_name + ": one row for each arrangeable event")
		for i in rows.size():
			var event: Dictionary = buyable[i]
			assert_eq(rows[i]["event_id"], str(event.get("event_id", "")))
			assert_eq(rows[i]["refusal"], GameState.event_refusal(event), "the rules' own reason")
			assert_true(Offices.is_here(event.get("location"), office_name), "belongs at this office or either")
			assert_eq(rows[i]["badge"], TravelText.level_badge(event.get("location")))


func test_the_first_dated_event_is_coming_up_a_week_before_its_date() -> void:
	var coming := EventsModel.coming()
	assert_gt(coming.size(), 0, "EV47 is dated 18.10.15 and today is 18.10.08")
	assert_eq(coming[0]["event_id"], "EV47")
	assert_eq(coming[0]["title"], str(GameState.get_event("EV47").get("title", "")))


# --- the cards -------------------------------------------------------------------------------------------------------

func test_a_decision_banner_has_no_price_and_no_button() -> void:
	var banner := EventsView.decision_banner(OfficeFrameStyles.look(), EventsModel.coming()[0])
	add_child_autofree(banner)
	assert_eq(banner.find_children("*", "Button", true, false).size(), 0, "no button")
	for node: Node in banner.find_children("*", "Label", true, false):
		assert_false((node as Label).text.contains("円"), "no price")
	assert_eq(banner.find_child("CardTitle", true, false).text.to_lower(), Text.say("event.decision_banner").to_lower())


func test_an_event_with_no_reason_can_be_arranged_and_one_with_a_reason_is_greyed_in_red() -> void:
	var look := OfficeFrameStyles.look()
	var arranged: Array[String] = []
	var ok := {"event_id": "EV1", "line": "Thing (2 hours)", "badge": "Capitol", "refusal": "", "node": "Arrange_EV1"}
	var card := EventsView.event_card(look, ok, func(id: String) -> void: arranged.append(id))
	add_child_autofree(card)
	var button := card.find_child("Arrange_EV1", true, false) as Button
	assert_false(button.disabled)
	assert_null(card.find_child("EventRefusal", true, false))
	button.pressed.emit()
	assert_eq(arranged, ["EV1"] as Array[String])
	var no := ok.duplicate()
	no["refusal"] = "Not enough Funds"
	var greyed := EventsView.event_card(look, no, func(id: String) -> void: arranged.append(id))
	add_child_autofree(greyed)
	var b2 := greyed.find_child("Arrange_EV1", true, false) as Button
	assert_true(b2.disabled)
	assert_eq(b2.text, Text.say("event.arrange"))
	var why := greyed.find_child("EventRefusal", true, false) as Label
	assert_eq(why.text, "Not enough Funds")
	assert_eq(why.get_theme_color("font_color"), look["down"])
	assert_eq(arranged.size(), 1, "a greyed button runs nothing")


# --- the screen ------------------------------------------------------------------------------------------------------

func test_the_screen_has_two_tabs_and_the_coming_up_tab_lists_no_buy_rows() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var office := _office()
		await get_tree().process_frame
		office._show_events("here")
		var panel := office.get_node("EventsPanel") as Overlay
		assert_not_null(panel.find_child("FrameTab_here", true, false), style + ": Arrange here")
		assert_not_null(panel.find_child("FrameTab_coming", true, false), style + ": Coming up")
		assert_not_null(panel.find_child("Decision_EV47", true, false), style + ": the banner shows on Arrange here")
		(panel.find_child("FrameTab_coming", true, false) as Button).pressed.emit()
		assert_not_null(panel.find_child("Decision_EV47", true, false), style + ": and on Coming up")
		assert_eq(panel.find_children("Arrange_*", "Button", true, false).size(), 0, style + ": no Arrange button on Coming up")
		office.queue_free()
		await get_tree().process_frame


func test_the_chips_are_where_you_stand_and_the_hours_left() -> void:
	var chips := EventsModel.chips()
	assert_eq(chips[0], TravelText.level_badge(GameState.office_location))
	assert_eq(chips[1], Text.say("office.docket_hours", {"count": GameState.work_hours_left()}))
