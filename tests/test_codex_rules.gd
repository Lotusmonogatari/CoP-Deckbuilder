extends GutTest
## The Codex and reference desk, the pure rules (P18, 2026-11-24): hidden placeholders, categories and order, each way a document is
## found, sealed / new / read, XP once, neighbours, the reading bands and the Room files.

var _docs := [
	{"doc_id": "LD01", "category": "party_platform", "order": 1, "title": "A", "unlock": "own_party", "party": "CP01", "note": null},
	{"doc_id": "LD02", "category": "party_platform", "order": 2, "title": "B", "unlock": "start", "party": null, "note": null},
	{"doc_id": "LD03", "category": "ne3", "order": 1, "title": "N", "unlock": "line", "note": null},
	{"doc_id": "LD04", "category": "history", "order": 1, "title": "H", "unlock": "law", "unlock_value": "BI07 passed", "note": null},
	{"doc_id": "LD05", "category": "history", "order": 2, "title": "Placeholder", "unlock": "start", "note": "DRAFT: placeholder"},
]


func test_a_placeholder_row_is_hidden_from_players() -> void:
	assert_true(Codex.is_draft(_docs[4]))
	assert_false(Codex.is_draft(_docs[0]))
	assert_eq(Codex.visible(_docs).size(), 4)
	assert_eq(Codex.in_category(_docs, "history").size(), 1, "the draft is not in its category")


func test_categories_come_in_order_and_an_empty_one_is_left_out() -> void:
	assert_eq(Codex.categories(_docs, true), ["room_file", "party_platform", "ne3", "history"] as Array[String])
	assert_eq(Codex.categories(_docs, false), ["party_platform", "ne3", "history"] as Array[String], "no Room files: no Room files heading")
	var only_draft := [_docs[4]]
	assert_eq(Codex.categories(only_draft, false).size(), 0, "a category with only a placeholder does not show")


func test_documents_in_a_category_follow_their_order() -> void:
	var ids := Codex.in_category(_docs, "party_platform").map(func(d: Dictionary) -> String: return str(d["doc_id"]))
	assert_eq(ids, ["LD01", "LD02"])


func test_start_and_own_party_documents_are_found_at_the_start() -> void:
	assert_eq(Codex.found_at_start(_docs, "CP01"), ["LD01", "LD02"] as Array[String], "start rows plus the player's own party's platform (a hidden placeholder is never found)")
	assert_eq(Codex.found_at_start(_docs, "CP02"), ["LD02"] as Array[String], "another party's platform stays sealed")


func test_a_law_document_is_found_when_the_bill_has_that_result() -> void:
	assert_eq(Codex.found_by_laws(_docs, {"BI07": "failed"}).size(), 0)
	assert_eq(Codex.found_by_laws(_docs, {"BI07": "passed"}), ["LD04"] as Array[String])
	assert_eq(Codex.found_by_laws(_docs, {}).size(), 0)


func test_sealed_new_and_read_states_and_xp_once() -> void:
	var found := {}
	assert_eq(Codex.state_of(found, "LD03"), "sealed")
	found = Codex.with_found(found, "LD03", 12)
	assert_eq(Codex.state_of(found, "LD03"), "new")
	assert_eq(int(found["LD03"]["day"]), 12)
	assert_eq(Codex.with_found(found, "LD03", 30)["LD03"]["day"], 12, "found once: the first day stays")
	assert_eq(Codex.unread_count(_docs, found), 1)
	var first := Codex.with_read(found, "LD03")
	assert_true(bool(first["first"]), "the first read pays")
	found = first["found"]
	assert_eq(Codex.state_of(found, "LD03"), "read")
	assert_false(bool(Codex.with_read(found, "LD03")["first"]), "never again")
	assert_false(bool(Codex.with_read({}, "LD03")["first"]), "a sealed document cannot be read")
	assert_eq(Codex.unread_count(_docs, found), 0)


func test_the_reader_moves_within_a_category_and_stops_at_each_end() -> void:
	var ids := ["LD01", "LD02"]
	assert_eq(Codex.neighbours(ids, "LD01"), {"previous": "", "next": "LD02"})
	assert_eq(Codex.neighbours(ids, "LD02"), {"previous": "LD01", "next": ""})
	assert_eq(Codex.neighbours(["X"], "X"), {"previous": "", "next": ""})


func test_the_band_words_for_every_multiplier_in_the_data() -> void:
	assert_eq(Codex.band_for(0.5), {"id": "weakest", "meter": 1})
	assert_eq(Codex.band_for(0.7), {"id": "weak", "meter": 2})
	assert_eq(Codex.band_for(1.0), {"id": "neutral", "meter": 3})
	assert_eq(Codex.band_for(1.3), {"id": "strong", "meter": 4})
	assert_eq(Codex.band_for(1.5), {"id": "strongest", "meter": 5})
	assert_eq(Codex.band_for(1.4)["id"], "strongest", "the edge: 1.4 or more")
	assert_eq(Codex.band_for(1.15)["id"], "strong")
	assert_eq(Codex.band_for(0.86)["id"], "neutral")
	assert_eq(Codex.band_for(0.6)["id"], "weak")


func test_a_reading_lists_six_styles_best_first() -> void:
	var affinity := [
		{"element": "Earnest", "multipliers": {"ST01": 0.7}}, {"element": "Emotional", "multipliers": {"ST01": 0.5}},
		{"element": "Appeal", "multipliers": {"ST01": 1.0}}, {"element": "Data Driven", "multipliers": {"ST01": 1.5}},
		{"element": "Divisive", "multipliers": {"ST01": 1.0}}, {"element": "Duplicitous", "multipliers": {"ST01": 1.3}}]
	var rows := Codex.reading("ST01", affinity)
	assert_eq(rows.map(func(r: Dictionary) -> String: return str(r["suit"])), ["Data Driven", "Duplicitous", "Appeal", "Divisive", "Earnest", "Emotional"])
	assert_eq(rows.map(func(r: Dictionary) -> String: return str(r["band"])), ["strongest", "strong", "neutral", "neutral", "weak", "weakest"])
	assert_eq(Codex.reading("ST99", affinity)[0]["band"], "neutral", "a room with no entry reads neutral")


func test_a_room_file_lasts_exactly_as_long_as_its_tip() -> void:
	var tips := [{"kind": "stage_suit", "target": "ST01", "suit": "Data Driven", "where": "library", "day": 5}]
	var store := Codex.with_room_file({}, "ST01", 5, "LV03", [{"suit": "Data Driven", "band": "strongest"}])
	assert_eq(Codex.room_file_ids(store, tips), ["ST01"] as Array[String])
	assert_eq(Codex.room_files_unread(store, tips), 1, "new until read")
	store = Codex.room_file_read(store, "ST01")
	assert_eq(Codex.room_files_unread(store, tips), 0)
	assert_eq(Codex.room_file_ids(store, []).size(), 0, "the tip is gone, so the file is gone")
	assert_eq(Codex.pruned(store, []).size(), 0)
	assert_eq(Codex.pruned(store, tips).size(), 1)
	var again := Codex.with_room_file(store, "ST01", 9, "LV03", [])
	assert_eq(int(again["ST01"]["day"]), 9, "researching again refreshes the date")
	assert_true(bool(again["ST01"]["read"]), "and keeps the read mark")
	var other_tip := [{"kind": "opponent_suit", "target": "ST01", "suit": "X", "where": "gardens", "day": 1}]
	assert_eq(Codex.room_file_ids(store, other_tip).size(), 0, "only a stage tip keeps a Room file")
