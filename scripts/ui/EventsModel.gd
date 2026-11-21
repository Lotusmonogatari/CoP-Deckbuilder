class_name EventsModel
extends RefCounted
## What the Events screen shows (P13, 2026-11-20), as plain data: the events that can be arranged at the office the player
## stands at (GameState.buyable_events already filters by office), each with where it belongs, what it costs, how long it
## takes and, when it cannot be arranged now, the rules' own reason; and the dated events coming up. It asks the same
## questions the old list asked and says nothing it did not; EventsView only draws it.


## The events to arrange here, in workbook order.
static func rows() -> Array:
	var out: Array = []
	for event: Dictionary in GameState.buyable_events():
		var cost: Variant = event.get("cost_funds")
		var hours := GameState.event_hours_text(event)
		var top := GameState.event_hours_range(event)[1]
		var line := Text.say("event.row", {"title": str(event.get("title", "")), "hours": hours, "count": top, "cost": int(cost)}) \
			if cost != null and int(cost) > 0 \
			else Text.say("event.row_free", {"title": str(event.get("title", "")), "hours": hours, "count": top})
		out.append({"event_id": str(event.get("event_id", "")), "title": str(event.get("title", "")), "line": line,
			"badge": TravelText.level_badge(event.get("location")), "refusal": GameState.event_refusal(event),
			"node": "Arrange_" + str(event.get("event_id", ""))})
	return out


## The Optional Decision! scenes open today, as plain data for EventsView.optional_card: title, flavor, the time-left line, the
## office badge and the reason in red when the player is not at the scene's office.
static func optional_rows() -> Array:
	var out: Array = []
	for entry: Dictionary in GameState.optional_scenes_open():
		var event: Dictionary = entry["event"]
		var left := int(entry["days_left"])
		var flavor: Variant = event.get("flavor")
		out.append({"event_id": str(event.get("event_id", "")), "title": str(event.get("title", "")),
			"meta": Text.say("event.optional_meta_one") if left <= 1 else Text.say("event.optional_meta", {"days": left}),
			"flavor": "" if flavor == null else str(flavor), "badge": TravelText.level_badge(GameState.event_office(event)),
			"refusal": str(entry["refusal"]), "node": "OpenOptional_" + str(event.get("event_id", ""))})
	return out


## The dated events coming up: day, office, hours, title and a line about it (its own flavor text, or that the staff will
## move the player there when it is at the other office).
static func coming() -> Array:
	var today := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	var out: Array = []
	# An Optional scene is never "coming up" as a Decision!: it has its own entry below and never moves the player.
	var optional_events: Array[String] = []
	for scene: Dictionary in DataDB.decision_scenes:
		if DecisionScenes.is_optional(scene):
			optional_events.append(str(scene.get("event_id", "")))
	var skip: Array[String] = GameState.dated_events_done.duplicate()
	skip.append_array(optional_events)
	for event: Dictionary in EventEngine.upcoming_dated(DataDB.events, today, Levers.whole("events_coming_up_days"), skip):
		var when := WeekCalendar.parse_date(str(event.get("on_date", "")))
		var tag := GameState.event_office(event)
		var line := ""
		if tag != Offices.normalize(GameState.office_location) and tag != Offices.EITHER:
			line = Text.say("event.decision_moves_you", {"place": TravelText.place_name(tag)})
		var flavor: Variant = event.get("flavor")
		out.append({"event_id": str(event.get("event_id", "")), "title": str(event.get("title", "")),
			"meta": Text.say("event.coming_meta", {"day": _weekday(when), "office": TravelText.level_badge(GameState.event_office(event)),
				"hours": GameState.event_hours_text(event)}),
			"flavor": "" if flavor == null else str(flavor), "moves": line})
	# Follow-up scenes whose earlier scene is answered and whose Delay is still running (Decision! scenes, phase 2).
	for scene: Dictionary in DecisionScenes.upcoming_follow_ups(DataDB.decision_scenes, GameState.decision_log, today, Levers.whole("events_coming_up_days")):
		var event := GameState.get_event(str(scene.get("event_id", "")))
		if event.is_empty():
			continue
		var tag := GameState.event_office(event)
		var flavor: Variant = event.get("flavor")
		out.append({"event_id": str(event.get("event_id", "")), "title": str(event.get("title", "")),
			"meta": Text.say("event.coming_meta", {"day": _weekday(DecisionScenes.due_day(scene, GameState.decision_log)),
				"office": TravelText.level_badge(tag), "hours": GameState.event_hours_text(event)}),
			"flavor": "" if flavor == null else str(flavor),
			"moves": Text.say("event.decision_moves_you", {"place": TravelText.place_name(tag)}) \
				if tag != Offices.normalize(GameState.office_location) and tag != Offices.EITHER else ""})
	# Optional scenes whose window opens soon (phase 4): when they open, and that they never move you.
	for scene: Dictionary in DecisionScenes.optional_upcoming(DataDB.decision_scenes, GameState.decision_log, today, Levers.whole("events_coming_up_days")):
		var event := GameState.get_event(str(scene.get("event_id", "")))
		if event.is_empty():
			continue
		var opens := DecisionScenes.window(scene, GameState.decision_log)[0]
		var flavor: Variant = event.get("flavor")
		out.append({"event_id": str(event.get("event_id", "")), "title": str(event.get("title", "")),
			"meta": Text.say("event.optional_coming_meta", {"day": _weekday(opens)}),
			"flavor": "" if flavor == null else str(flavor), "moves": ""})
	return out


## The meta line of an event's pop-up card: the day (the event's own date when it has one, else today), the office it is at
## and the hours it takes ("Monday · District · 2 h").
static func pop_meta(event: Dictionary) -> String:
	var day := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	if str(event.get("trigger", "")) == "Dated":
		var dated := WeekCalendar.parse_date(str(event.get("on_date", "")))
		if dated >= 0:
			day = dated
	return Text.say("event.coming_meta", {"day": _weekday(day), "office": TravelText.level_badge(GameState.event_office(event)),
		"hours": GameState.event_hours_text(event)})


## The weekday of a day number ("Monday"), from the calendar's own rows.
static func weekday_name(number: int) -> String:
	return _weekday(number)


static func _weekday(number: int) -> String:
	var names := [Text.say("calendar.weekday_sun"), Text.say("calendar.weekday_mon"), Text.say("calendar.weekday_tue"),
		Text.say("calendar.weekday_wed"), Text.say("calendar.weekday_thu"), Text.say("calendar.weekday_fri"),
		Text.say("calendar.weekday_sat")]
	return str(names[posmod(number + 4, 7)])


## The chips: where the player stands and the hours left this week.
static func chips() -> Array[String]:
	return [TravelText.level_badge(GameState.office_location), Text.say("office.docket_hours", {"count": GameState.work_hours_left()})]
