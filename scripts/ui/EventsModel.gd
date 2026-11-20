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


## The dated events coming up: day, office, hours, title and a line about it (its own flavor text, or that the staff will
## move the player there when it is at the other office).
static func coming() -> Array:
	var today := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	var out: Array = []
	for event: Dictionary in EventEngine.upcoming_dated(DataDB.events, today, Levers.whole("events_coming_up_days"), GameState.dated_events_done):
		var when := WeekCalendar.parse_date(str(event.get("on_date", "")))
		var tag := Offices.normalize(event.get("location"))
		var line := ""
		if tag != Offices.normalize(GameState.office_location) and tag != Offices.EITHER:
			line = Text.say("event.decision_moves_you", {"place": TravelText.place_name(tag)})
		var flavor: Variant = event.get("flavor")
		out.append({"event_id": str(event.get("event_id", "")), "title": str(event.get("title", "")),
			"meta": Text.say("event.coming_meta", {"day": _weekday(when), "office": TravelText.level_badge(event.get("location")),
				"hours": GameState.event_hours_text(event)}),
			"flavor": "" if flavor == null else str(flavor), "moves": line})
	return out


## The meta line of an event's pop-up card: the day (the event's own date when it has one, else today), the office it is at
## and the hours it takes ("Monday · District · 2 h").
static func pop_meta(event: Dictionary) -> String:
	var day := WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())
	if str(event.get("trigger", "")) == "Dated":
		var dated := WeekCalendar.parse_date(str(event.get("on_date", "")))
		if dated >= 0:
			day = dated
	return Text.say("event.coming_meta", {"day": _weekday(day), "office": TravelText.level_badge(event.get("location")),
		"hours": GameState.event_hours_text(event)})


## The weekday of a day number ("Monday"), from the calendar's own rows.
static func _weekday(number: int) -> String:
	var names := [Text.say("calendar.weekday_sun"), Text.say("calendar.weekday_mon"), Text.say("calendar.weekday_tue"),
		Text.say("calendar.weekday_wed"), Text.say("calendar.weekday_thu"), Text.say("calendar.weekday_fri"),
		Text.say("calendar.weekday_sat")]
	return str(names[posmod(number + 4, 7)])


## The chips: where the player stands and the hours left this week.
static func chips() -> Array[String]:
	return [TravelText.level_badge(GameState.office_location), Text.say("office.docket_hours", {"count": GameState.work_hours_left()})]
