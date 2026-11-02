extends GutTest
## A bill's name worked into a sentence (BillName.gd, 2026-11-02, Cameron:
## "The case for the A bill to cap ..." read wrong for a drafted bill).

const DRAFTED := "A bill to cap the monthly cost of a commuter pass and run late-night commuter trains"


func test_a_named_bill_reads_after_the() -> void:
	assert_eq(BillName.phrase("Hokkaido Shinkansen Acceleration Act"), "the Hokkaido Shinkansen Acceleration Act")
	assert_eq(BillName.sentence_start("Hokkaido Shinkansen Acceleration Act"), "The Hokkaido Shinkansen Acceleration Act")


func test_a_drafted_bill_reads_as_this_bill() -> void:
	assert_eq(BillName.phrase(DRAFTED),
		"this bill to cap the monthly cost of a commuter pass and run late-night commuter trains")
	assert_eq(BillName.sentence_start("An act to fund rural clinics"), "This act to fund rural clinics")


func test_a_name_that_starts_with_the_gets_no_second_one() -> void:
	assert_eq(BillName.phrase("The Public Broadcasting Independence Act"), "the Public Broadcasting Independence Act")


func test_the_short_form() -> void:
	assert_eq(BillName.short("Carbon Levy Act", 0), "the Act")
	assert_eq(BillName.short("Carbon Levy Act", 1), "the bill")
	assert_eq(BillName.short("Yezo–EU Economic Partnership Agreement", 0), "the Agreement")
	assert_eq(BillName.short(DRAFTED, 0), "the bill")


func test_a_reply_line_never_says_the_a_bill() -> void:
	# Every name a bill can have, every way {bill} can be filled.
	var names: Array[String] = [DRAFTED]
	for bill_id: Variant in DataDB.floor_votes:
		names.append(str((DataDB.floor_votes[bill_id] as Dictionary).get("bill_name", "")))
	for name in names:
		for index in [0, 1, 24, 50, 99, 100, 101, 250]:
			var phrase := BillName.phrase(name) if (index % 100) < 25 else BillName.short(name, index / 100)
			for bad in ["the A ", "the An ", "the The ", "The A ", "The An "]:
				assert_false(phrase.begins_with(bad) or (" " + phrase).contains(" " + bad),
					"'%s' (%s) reads '%s'" % [name, index, phrase])


func test_no_text_says_the_a_something() -> void:
	for path: String in DirAccess.get_files_at("res://data"):
		if not path.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + path))
		var found: Array = []
		_strings(parsed, found)
		var bad := RegEx.create_from_string("\\b[Tt]he (A|An|The) [a-z]")
		for text: String in found:
			assert_null(bad.search(text), "%s: '%s'" % [path, text.left(100)])


func _strings(node: Variant, out: Array) -> void:
	if node is Dictionary:
		for value: Variant in (node as Dictionary).values():
			_strings(value, out)
	elif node is Array:
		for value: Variant in node:
			_strings(value, out)
	elif node is String:
		out.append(node)
