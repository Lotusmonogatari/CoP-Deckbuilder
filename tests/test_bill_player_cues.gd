extends GutTest
## The lines the player speaks in a bill level (2026-10-20): fifteen per style and
## lean, no repeats inside a pool, short, and different between the leans
## (except Duplicitous, whose double meaning is deliberate).


func _lines(bill: String, suit: String, stance: String) -> Array:
	var out: Array = []
	for line: Dictionary in DataDB.get_bill_player_cue_lines(bill, suit, "", stance):
		out.append(str(line["text"]))
	return out


func test_every_bill_style_and_lean_has_fifteen_distinct_short_lines() -> void:
	for bill_id: String in DataDB.floor_votes.keys():
		if not bill_id.begins_with("BI"):
			continue
		for suit: String in ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]:
			for stance: String in ["Support", "Oppose"]:
				var lines := _lines(bill_id, suit, stance)
				assert_eq(lines.size(), 15, "%s %s %s" % [bill_id, suit, stance])
				var seen := {}
				for text: String in lines:
					assert_false(seen.has(text), "repeat in %s %s %s: %s" % [bill_id, suit, stance, text])
					seen[text] = true
					assert_lte(text.split(" ").size(), 20, text)
					assert_false((" " + text.to_lower() + " ").contains(" still "), text)


func test_the_two_leans_do_not_share_lines_outside_duplicitous() -> void:
	for bill_id: String in DataDB.floor_votes.keys():
		if not bill_id.begins_with("BI"):
			continue
		for suit: String in ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive"]:
			var support := _lines(bill_id, suit, "Support")
			for text: String in _lines(bill_id, suit, "Oppose"):
				assert_false(support.has(text), "%s %s shares: %s" % [bill_id, suit, text])
