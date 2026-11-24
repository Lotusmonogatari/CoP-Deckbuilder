extends GutTest
## The Codex and the reference desk in the run (P18, 2026-11-24): Browse the Shelves, sealed / new / read, first-read XP once (also across
## a save), each way a document is found, who the desk offers and what it charges, the tip and the Room file, and old saves.

var _real_documents: Array
var _real_lines: Array


func before_each() -> void:
	DataDB.clear_runtime()
	_real_documents = DataDB.library_documents
	_real_lines = DataDB.venue_lines
	DataDB.library_documents = [
		{"doc_id": "LD91", "category": "party_platform", "order": 1, "title": "Start paper", "unlock": "start", "note": null},
		{"doc_id": "LD92", "category": "party_platform", "order": 2, "title": "Own party paper", "unlock": "own_party", "party": "", "note": null},
		{"doc_id": "LD93", "category": "ne3", "order": 1, "title": "Line paper", "unlock": "line", "note": null},
		{"doc_id": "LD94", "category": "history", "order": 1, "title": "Law paper", "unlock": "law", "unlock_value": "BI01 passed", "note": null},
		{"doc_id": "LD95", "category": "history", "order": 2, "title": "Hidden", "unlock": "start", "note": "DRAFT: placeholder"},
	]
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	GameState.meta["Funds"] = 50000


func after_each() -> void:
	DataDB.library_documents = _real_documents
	DataDB.venue_lines = _real_lines
	GameState.office_location = Offices.CAPITOL


func _next_day() -> void:
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	GameState.spend_hours(8)


func test_browse_the_shelves_is_built_and_the_library_draws_its_two_tabs() -> void:
	assert_eq(GameState.activity_refusal("VA02"), "", "Browse the Shelves can be used")
	assert_true(VenueRules.is_built(GameState.venue_activity("VA02")))
	assert_true(VenueRules.is_built(GameState.venue_activity("VA18")))
	assert_true(LibraryController.draws("VN02"), "the Library is drawn by the Codex screen")
	assert_false(LibraryController.draws("VN08"), "the shrine is not")


func test_a_start_document_is_found_at_new_game_and_the_others_are_sealed() -> void:
	assert_eq(GameState.codex_state("LD91"), "new")
	assert_eq(GameState.codex_state("LD93"), "sealed")
	assert_eq(GameState.codex_state("LD94"), "sealed")
	assert_eq(GameState.codex_state("LD95"), "sealed", "a placeholder is never found by the start rule: it is hidden")
	assert_false(GameState.codex_find("LD95"), "and nothing else finds it either")


func test_the_players_own_party_document_is_found_at_the_start() -> void:
	var party_id := GameState._player_party_id()
	assert_ne(party_id, "", "the protagonist has a party")
	DataDB.library_documents[1]["party"] = party_id
	GameState.start_new_run("PC01")
	assert_eq(GameState.codex_state("LD92"), "new", "found at New Game, not yet read")


func test_reading_clears_new_and_pays_xp_once_even_across_a_reload() -> void:
	var xp := GameState.xp
	assert_eq(GameState.codex_read("LD91"), 5, "the first read pays codex_first_read_xp")
	assert_eq(GameState.xp, xp + 5)
	assert_eq(GameState.codex_state("LD91"), "read")
	assert_eq(GameState.codex_read("LD91"), 0, "a second read pays nothing")
	assert_eq(GameState.xp, xp + 5)
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.codex_state("LD91"), "read", "the read mark is saved")
	assert_eq(GameState.codex_read("LD91"), 0, "and it pays nothing after a reload")


func test_a_venue_line_finds_its_document_once() -> void:
	for row: Dictionary in DataDB.venue_lines:
		if str(row.get("line_id", "")) == "VL001":
			row["unlocks_doc"] = "LD93"
	var entry := GameState.venue_day("VN01")
	(entry["dealt"] as Array)[0] = {"line_id": "VL001", "hint": {}}
	GameState.venue_visit("VN01")
	var heard := GameState.venue_hear_next("VN01")
	assert_eq(str(heard["unlocked"]), "Line paper", "the pop-up is told the title")
	assert_eq(GameState.codex_state("LD93"), "new")
	assert_false(GameState.codex_find("LD93"), "finding it again changes nothing")


func test_a_law_result_finds_its_document() -> void:
	assert_eq(GameState.codex_state("LD94"), "sealed")
	GameState.statute_book.append({"bill_id": "BI01", "passed": false})
	GameState.codex_sync_laws()
	assert_eq(GameState.codex_state("LD94"), "sealed", "BI01 failed does not find a 'passed' document")
	GameState.statute_book.clear()
	GameState.statute_book.append({"bill_id": "BI01", "passed": true})
	GameState.codex_sync_laws()
	assert_eq(GameState.codex_state("LD94"), "new")


func test_the_desk_offers_only_rooms_with_a_favored_suit_in_levels_on_offer() -> void:
	var rooms := GameState.desk_rooms()
	assert_gt(rooms.size(), 0, "something is on offer")
	var offered := {}
	for level: Dictionary in GameState.levels_on_offer():
		offered[str(level.get("level_id", ""))] = true
	for room: Dictionary in rooms:
		assert_true(offered.has(str(room["level_id"])), "%s is in a level on offer" % room["stage_id"])
		var suit: Variant = DataDB.get_stage(str(room["stage_id"])).get("favored_suit")
		assert_true(suit != null and not str(suit).is_empty(), "%s has a favored suit" % room["stage_id"])


func test_the_desk_costs_two_hours_once_a_day_and_adds_a_tip_and_a_room_file() -> void:
	var room: Dictionary = GameState.desk_rooms()[0]
	var left := GameState.work_hours_left()
	var done := GameState.do_research(str(room["stage_id"]), str(room["level_id"]))
	assert_true(bool(done["ok"]))
	assert_eq(GameState.work_hours_left(), left - 2, "two hours")
	assert_eq((done["reading"] as Array).size(), 6, "all six styles are read")
	assert_eq(GameState.desk_refusal(), Text.say("venue.refuse_limit"), "once a day")
	assert_false(bool(GameState.do_research(str(room["stage_id"]), str(room["level_id"]))["ok"]))
	var tip := {}
	for held: Dictionary in GameState.tips_held():
		if str(held["target"]) == str(room["stage_id"]):
			tip = held
	assert_eq(str(tip.get("where", "")), "library", "the tip's source is the Library")
	assert_eq(str(tip.get("suit", "")), str(DataDB.get_stage(str(room["stage_id"])).get("favored_suit", "")), "the tip is the room's favored suit")
	assert_true(GameState.room_file_ids().has(str(room["stage_id"])), "the Room file is in the Codex")
	_next_day()
	assert_eq(GameState.desk_refusal(), "", "tomorrow the desk is open again")
	var again := GameState.do_research(str(room["stage_id"]), str(room["level_id"]))
	assert_true(bool(again["ok"]))
	assert_eq(GameState.tips_held().filter(func(t: Dictionary) -> bool: return str(t["target"]) == str(room["stage_id"])).size(), 1, "the tip is refreshed, not doubled")


func test_the_desk_is_greyed_with_its_reason_when_the_hours_are_short() -> void:
	GameState.calendar = {"week": 2, "phase": "work", "hours": 39}
	assert_eq(GameState.desk_refusal(), Text.say("venue.refuse_hours"))
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}
	assert_ne(GameState.desk_refusal(), "")


func test_the_room_file_goes_the_day_its_tip_does() -> void:
	var room: Dictionary = GameState.desk_rooms()[0]
	GameState.do_research(str(room["stage_id"]), str(room["level_id"]))
	assert_eq(GameState.codex_unread_count(), 2, "the start paper and the Room file are new")
	for tip: Dictionary in GameState.held_tips:
		tip["day"] = int(tip["day"]) - 14   # the tip is 14 days old
	assert_false(GameState.room_file_ids().has(str(room["stage_id"])), "the tip lasted 14 days; the file is gone")
	assert_eq(GameState.codex_unread_count(), 1, "and no longer counts as unread")


func test_a_room_file_never_pays_xp() -> void:
	var room: Dictionary = GameState.desk_rooms()[0]
	GameState.do_research(str(room["stage_id"]), str(room["level_id"]))
	var xp := GameState.xp
	GameState.room_file_read(str(room["stage_id"]))
	assert_eq(GameState.xp, xp)
	assert_true(bool(GameState.room_file(str(room["stage_id"])).get("read", false)))


func test_the_room_file_and_codex_survive_a_save_and_an_old_save_keeps_only_the_start_documents() -> void:
	var room: Dictionary = GameState.desk_rooms()[0]
	GameState.do_research(str(room["stage_id"]), str(room["level_id"]))
	GameState.codex_read("LD91")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.codex_state("LD91"), "read")
	assert_true(GameState.room_file_ids().has(str(room["stage_id"])), "the Room file is back")
	var old := saved.duplicate(true)
	old.erase("codex_found")
	old.erase("room_files")
	old["held_tips"] = []
	GameState.start_new_run("PC01")
	GameState.load_save(old)
	assert_eq(GameState.codex_state("LD91"), "new", "an old save has the start document found, unread")
	assert_eq(GameState.codex_state("LD93"), "sealed")
	assert_eq(GameState.room_file_ids().size(), 0, "and no Room files")


func test_a_new_run_forgets_the_old_runs_documents() -> void:
	GameState.codex_find("LD93")
	GameState.start_new_run("PC01")
	assert_eq(GameState.codex_state("LD93"), "sealed")
