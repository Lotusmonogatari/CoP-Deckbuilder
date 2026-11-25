extends GutTest
## Event text about unnamed people is genderless (Cameron's playtest note, 2026-11-25): "Unless a text is tied to a specific character the text
## needs to be genderless." So no he, she, him, her, his, man, girl and the like in event rows, except in the events about a named character,
## whose gender is theirs: Hanako Okuda (EV74), Ayako Kudo (EV81) and Minister Resu (EV114, EV115). A new event about a named person is added to
## NAMED below; anything else that needs a pronoun should say "they" or the person's role.

const NAMED := ["EV74", "EV81", "EV114", "EV115"]
const FORBIDDEN := "\\b(he|she|his|him|himself|herself|her|hers|man|men|woman|women|boy|girl|gentleman|lady|madam|wife|husband|grandson|granddaughter|grandmother|grandfather)\\b"


func test_event_text_about_unnamed_people_has_no_gendered_words() -> void:
	var rx := RegEx.create_from_string("(?i)" + FORBIDDEN)
	var bad: Array[String] = []
	for table: Array in [DataDB.events, DataDB.event_choices, DataDB.event_options]:
		for row: Dictionary in table:
			var event_id := str(row.get("event_id", ""))
			if NAMED.has(event_id):
				continue
			for field: String in ["title", "flavor", "choice_text", "result_text", "promise_kept_text", "decline_text"]:
				var text: Variant = row.get(field)
				if text != null and rx.search(str(text)) != null:
					bad.append("%s %s: %s" % [event_id, field, str(text).left(70)])
	# The same rule for the Office notices and the venue lines (the people in them are not named either).
	for row: Dictionary in DataDB.office_notices:
		if rx.search(str(row.get("text_en", ""))) != null:
			bad.append("%s: %s" % [row.get("notice_id"), str(row.get("text_en", "")).left(70)])
	for row: Dictionary in DataDB.venue_lines:
		var speaker := str(row.get("speaker", "")) if row.get("speaker") != null else ""
		if not speaker.is_empty() and speaker != "area":
			continue   # a line spoken by a named person is tied to that character
		var line_text := str(row.get("text", ""))
		if line_text.contains("women-only"):
			continue   # a train car's rule (the women-only car), not a person
		if rx.search(line_text) != null:
			bad.append("%s: %s" % [row.get("line_id"), str(row.get("text", "")).left(70)])
	assert_eq(bad, [], "gendered words in text about an unnamed person (say 'they' or the person's role)")
