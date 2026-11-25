class_name StageEvents
extends RefCounted
## The Sapporo Stage's events and performances by date (2026-11-25, Cameron): the Stage Events tab lists what is on by calendar date range, and
## its Performer is who is on stage (an Area Characters VEN ID). A scheduled person (VEN04, VEN05: Days and Months) also performs on their own days.
## A row whose Note begins "DRAFT" is a hidden placeholder. Pure: no screens, no autoloads, no files (the tests prove it).


static func is_draft(event: Dictionary) -> bool:
	var note: Variant = event.get("note")
	return note != null and str(note).strip_edges().to_upper().begins_with("DRAFT")


## The events on `today` (a calendar day number): not drafts, inside their Date From and Date To (a blank end is open).
static func active(events: Array, today: int) -> Array:
	var out: Array = []
	for row: Variant in events:
		var event := row as Dictionary
		if is_draft(event):
			continue
		var from_day := _day(event.get("date_from"))
		var to_day := _day(event.get("date_to"))
		if (from_day < 0 or today >= from_day) and (to_day < 0 or today <= to_day):
			out.append(event)
	return out


## Who is on stage at a venue today: the Performer of each event on, and the scheduled people sited at the venue who are about. Each once.
static func performers(events: Array, today: int, characters: Array, venue: Dictionary, weekday: int, month: int) -> Array:
	var out: Array = []
	var seen := {}
	for event: Dictionary in active(events, today):
		var id := str(event.get("performer", "")) if event.get("performer") != null else ""
		if id.is_empty() or seen.has(id):
			continue
		for person: Variant in characters:
			if str((person as Dictionary).get("character_id", "")) == id:
				seen[id] = true
				out.append(person)
	for person: Variant in AreaCharacters.pool_present(characters, venue, weekday, month):
		var row := person as Dictionary
		if AreaCharacters.is_scheduled(row) and not seen.has(str(row.get("character_id", ""))):
			seen[str(row.get("character_id", ""))] = true
			out.append(row)
	return out


static func _day(raw: Variant) -> int:
	if raw == null or str(raw).strip_edges().is_empty():
		return -1
	return WeekCalendar.parse_date(str(raw))
