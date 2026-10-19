extends GutTest
## Patron Bills steps 5 and 6 (2026-10-19): every bill component carries its
## own content, found through a bill composed from it, and every line is short
## and free of clock words.

const SUITS := ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]
const CLOCK_WORDS := ["always", "never", "again", "already", "still", "soon", "later", "yet", "ever",
	"currently", "recently"]


func after_each() -> void:
	DataDB.clear_runtime()


func _register(cid: String) -> String:
	DataDB.register_runtime_bill({"bill_id": "TEST_" + cid, "bill_name": "Test"}, [cid])
	return "TEST_" + cid


func test_every_component_has_eight_questions_and_a_theme_that_pleases_its_owner() -> void:
	for component: Dictionary in DataDB.bill_components:
		var cid := str(component["component_id"])
		var bill := _register(cid)
		var questions := DataDB.get_bill_questions(bill)
		assert_eq(questions.size(), 8, "%s should have 8 questions" % cid)
		for q: Dictionary in questions:
			var pleased: Array = q.get("pleases_boosters", [])
			assert_true(pleased.has(str(component["owner"])), "%s: '%s' should please its owner" % [cid, q.get("text", "")])
		DataDB.clear_runtime()


func test_every_component_has_a_cue_for_each_style() -> void:
	for component: Dictionary in DataDB.bill_components:
		var cid := str(component["component_id"])
		var bill := _register(cid)
		for suit in SUITS:
			assert_eq(DataDB.get_bill_player_cue_lines(bill, suit, "attack", "Support").size(), 5, "%s player %s" % [cid, suit])
			assert_eq(DataDB.get_bill_opponent_cue_lines(bill, "", suit, "attack").size(), 5, "%s opponent %s" % [cid, suit])
		DataDB.clear_runtime()


func test_every_component_has_two_staff_lines_and_a_thought() -> void:
	var staff := {}
	var thoughts := {}
	for row: Dictionary in DataDB.transition_dialogue:
		for cid: Variant in (row.get("component_ids") if row.get("component_ids") is Array else []):
			if str(row.get("character_id")) == "PLAYER":
				thoughts[cid] = int(thoughts.get(cid, 0)) + 1
			else:
				staff[cid] = int(staff.get(cid, 0)) + 1
	for component: Dictionary in DataDB.bill_components:
		var cid := str(component["component_id"])
		assert_eq(int(staff.get(cid, 0)), 2, "%s staff lines" % cid)
		assert_eq(int(thoughts.get(cid, 0)), 1, "%s thought" % cid)


func test_component_lines_are_short_and_use_no_clock_words() -> void:
	var by_id := ComposedBill.index(DataDB.bill_components)
	var tables: Array = [DataDB.player_cues, DataDB.opponent_cues]
	for table: Array in tables:
		for row: Dictionary in table:
			var ids: Variant = row.get("component_ids")
			if not (ids is Array) or (ids as Array).is_empty():
				continue
			var phrase := str((by_id.get((ids as Array)[0], {}) as Dictionary).get("phrase", ""))
			for key: String in ["cue_1", "cue_2", "cue_3", "cue_4", "cue_5"]:
				var line := str(row.get(key, "")).replace(phrase, "")
				assert_lte(str(row.get(key, "")).split(" ").size(), 25, "too long: %s" % row.get(key))
				for word in CLOCK_WORDS:
					assert_false((" " + line.to_lower() + " ").contains(" " + word + " "), "clock word '%s' in: %s" % [word, row.get(key)])
