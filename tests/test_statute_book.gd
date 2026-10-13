extends GutTest
## The statute book and Law Effects (2026-10-12, Phase 2 of the legislation
## plan). Pure rules first, then GameState with fake Law Effects rows
## injected into DataDB, the same way test_player_cues.gd works.

var _effects_before: Array = []


func before_each() -> void:
	_effects_before = DataDB.law_effects.duplicate(true)
	GameState.start_new_run(str(DataDB.player.get("player_id", "PC02")))


func after_each() -> void:
	DataDB.law_effects = _effects_before.duplicate(true)


func _result(passed: bool) -> Dictionary:
	return {"passed": passed, "totals": {"Yes": 60 if passed else 30, "No": 30 if passed else 60, "Abstain": 11}}


# --- pure -------------------------------------------------------------------

func test_an_entry_records_the_vote() -> void:
	var law := StatuteBook.entry({"bill_id": "BI01"}, _result(true), "yes", "LV31", 4)
	assert_eq(law["bill_id"], "BI01")
	assert_true(law["passed"])
	assert_eq(law["yes"], 60)
	assert_eq(law["player_vote"], "Yes")
	assert_eq(law["enacted_at"], 4)


func test_effects_match_bill_outcome_and_timing() -> void:
	var rows := [
		{"bill_id": "BI01", "outcome": "Passed", "timing": null},
		{"bill_id": "BI01", "outcome": "Passed", "timing": "Each level"},
		{"bill_id": "BI01", "outcome": "Failed", "timing": null},
		{"bill_id": "BI02", "outcome": "Passed", "timing": null},
	]
	assert_eq(StatuteBook.effects_for(rows, "BI01", true, StatuteBook.ONCE).size(), 1)
	assert_eq(StatuteBook.effects_for(rows, "BI01", true, StatuteBook.EACH_LEVEL).size(), 1)
	assert_eq(StatuteBook.effects_for(rows, "BI01", false, StatuteBook.ONCE).size(), 1)


func test_ongoing_effects_skip_the_level_that_passed_the_law() -> void:
	var rows := [{"bill_id": "BI01", "outcome": "Passed", "timing": "Each level"}]
	var book := [{"bill_id": "BI01", "passed": true, "enacted_at": 4}]
	assert_eq(StatuteBook.ongoing_effects(book, rows, 5).size(), 0,
		"the level that held the vote does not also pay the ongoing effect")
	assert_eq(StatuteBook.ongoing_effects(book, rows, 6).size(), 1)
	assert_eq(StatuteBook.ongoing_effects(book, rows, 9).size(), 1)


func test_meta_columns_read_past_blank_cells() -> void:
	var deltas := StatuteBook.meta_deltas({"reputation": 3, "funds": null, "party_support": 0})
	assert_eq(deltas, {"Reputation": 3})


# --- GameState ----------------------------------------------------------------

func test_recording_a_vote_applies_its_once_effects() -> void:
	DataDB.law_effects = [
		{"law_id": "LW01", "bill_id": "BI01", "outcome": "Passed", "timing": null,
			"effects": [{"target": "BO28", "delta": 4}], "reputation": 2},
		{"law_id": "LW02", "bill_id": "BI01", "outcome": "Failed", "timing": null,
			"effects": null, "reputation": -9},
	]
	var standing_before := int(GameState.booster_standing.get("BO28", 0))
	var rep_before := int(GameState.meta.get("Reputation", 0))
	GameState.record_floor_vote({"bill_id": "BI01"}, _result(true), "Yes")
	assert_eq(GameState.statute_book.size(), 1)
	assert_eq(int(GameState.booster_standing.get("BO28", 0)), standing_before + 4)
	assert_eq(int(GameState.meta.get("Reputation", 0)), rep_before + 2,
		"only the Passed row applies")


func test_a_bill_is_never_recorded_twice() -> void:
	DataDB.law_effects = [{"law_id": "LW01", "bill_id": "BI01", "outcome": "Passed",
		"timing": null, "effects": null, "reputation": 2}]
	var rep_before := int(GameState.meta.get("Reputation", 0))
	GameState.record_floor_vote({"bill_id": "BI01"}, _result(true), "Yes")
	GameState.record_floor_vote({"bill_id": "BI01"}, _result(true), "Yes")
	assert_eq(GameState.statute_book.size(), 1)
	assert_eq(int(GameState.meta.get("Reputation", 0)), rep_before + 2)


func test_the_book_survives_a_save_and_load() -> void:
	GameState.record_floor_vote({"bill_id": "BI01"}, _result(false), "No")
	var saved := GameState.to_save()
	GameState.start_new_run(str(DataDB.player.get("player_id", "PC02")))
	assert_eq(GameState.statute_book.size(), 0)
	GameState.load_save(saved)
	assert_eq(GameState.statute_book.size(), 1)
	assert_eq(GameState.law_statuses(), {"BI01": "failed"})


func test_a_new_run_clears_the_book() -> void:
	GameState.record_floor_vote({"bill_id": "BI01"}, _result(true), "Yes")
	GameState.start_new_run(str(DataDB.player.get("player_id", "PC02")))
	assert_eq(GameState.statute_book.size(), 0)


# --- the "law" condition ------------------------------------------------------

func test_a_law_condition_checks_the_statute_book() -> void:
	var row := {"condition_type": "law", "condition_target": "BI01", "condition_op": "passed"}
	assert_false(OfficeNotices.condition_met(row, {}, {}, {}))
	assert_true(OfficeNotices.condition_met(row, {}, {}, {"BI01": "passed"}))
	assert_false(OfficeNotices.condition_met(row, {}, {}, {"BI01": "failed"}))
	var ticker := OfficeTicker.eligible_lines([row.merged({"text_en": "It passed."})], {}, {}, "",
		{"BI01": "passed"})
	assert_eq(ticker, ["It passed."] as Array[String])


# --- party-tier lean (2026-10-13) ---------------------------------------------

func test_party_tier_follows_the_players_party_lean() -> void:
	assert_eq(StatuteBook.party_tier_delta("Supportive", true, 3, 1), 3, "a backed bill passing pleases")
	assert_eq(StatuteBook.party_tier_delta("Opposed", true, 3, 1), -3, "an opposed bill passing annoys")
	assert_eq(StatuteBook.party_tier_delta("Opposed", false, 3, 1), 1, "an opposed bill failing pleases, smaller")
	assert_eq(StatuteBook.party_tier_delta("Supportive", false, 3, 1), -1, "a backed bill failing annoys, smaller")
	assert_eq(StatuteBook.party_tier_delta("Neutral", true, 3, 1), 0, "a neutral party moves nothing")
	assert_eq(StatuteBook.party_tier_delta("", true, 3, 1), 0, "no stance moves nothing")


func test_party_headquarters_and_faction_answer_to_the_players_party() -> void:
	# BI01: Frontier Party (PC02's party) is Opposed; Yezo Heritage Party is Supportive.
	var frontier := GameState.own_party_id()
	var dispo := ""
	for position: Dictionary in DataDB.floor_votes["BI01"]["positions"]:
		if str(position["party_id"]) == frontier:
			dispo = str(position["disposition"])
	var before := int(GameState.booster_standing.get("BO01", 50))
	GameState.record_floor_vote(DataDB.get_bill("BI01"), {"passed": true, "totals": {"Yes": 60, "No": 30, "Abstain": 11}}, "Yes")
	var moved := int(GameState.booster_standing.get("BO01", 50)) - before
	var expected := StatuteBook.party_tier_delta(dispo, true, int(DataDB.balance.get("law_lean_party_tier_pass_delta", 0)), 1)
	assert_ne(expected, 0, "the real bill has a stance for this party")
	assert_eq(moved, expected, "Party Headquarters moved with the party's lean")
	assert_eq(int(GameState.booster_standing.get("BO02", 50)) - int(DataDB.get_booster("BO02").get("starting_standing", 30) if DataDB.get_booster("BO02").get("starting_standing") != null else 30), expected, "Party Faction moves with it")
