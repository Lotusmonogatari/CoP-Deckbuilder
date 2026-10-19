extends GutTest
## BillAssist and its two uses (2026-10-19): members a visit won over (a
## guaranteed seat for the player's pick, no gate, no resistance) and lobbyist
## work against the player; plus the Office ticker story each leaves behind.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")


func after_each() -> void:
	DataDB.clear_runtime()
	GameState.load_save(_saved)
	DataDB.clear_runtime()


func _bill() -> Dictionary:
	return {"bill_id": "TB", "bill_name": "Test", "favorability_delta_supportive": 0, "favorability_delta_opposed": 0,
		"favorability_delta_neutral": 0, "positions": [
		{"party_id": "PA", "party_name": "Alpha", "votes_yes": 40, "votes_no": 0, "votes_abstain": 0, "disposition": "Supportive"},
		{"party_id": "PB", "party_name": "Beta", "votes_yes": 0, "votes_no": 5, "votes_abstain": 1, "disposition": "Opposed"},
		{"party_id": "PC", "party_name": "Gamma", "votes_yes": 2, "votes_no": 8, "votes_abstain": 3, "disposition": "Opposed"},
	]}


func _totals(config: Dictionary, choice: String = "Yes") -> Dictionary:
	config["bill"] = _bill()
	var engine := FloorVoteEngine.new()
	assert_true(engine.setup(config))
	return engine.choose(choice)


func test_the_record_adds_and_totals() -> void:
	var assist := BillAssist.empty()
	assert_true(BillAssist.is_empty(assist))
	BillAssist.add(assist, "won_over", "PT04", 1)
	BillAssist.add(assist, "won_over", "PT04", 1)
	BillAssist.add(assist, "worked_against", "PT02", 2)
	BillAssist.add(assist, "won_over", "", 3)
	BillAssist.add(assist, "won_over", "PT02", 0)
	assert_eq(BillAssist.total(assist, "won_over"), 2)
	assert_eq(BillAssist.total(assist, "worked_against"), 2)
	assert_false(BillAssist.is_empty(assist))


func test_a_member_won_over_is_a_seat_with_no_gate_and_no_resistance() -> void:
	var plain := _totals({"player_party": "Alpha"})
	var helped := _totals({"player_party": "Alpha", "assist": {"won_over": {"PB": 1}}})
	assert_eq(helped["totals"]["Yes"], int(plain["totals"]["Yes"]) + 1)
	assert_false(helped["influence_gate_passed"], "the gate never opened; the seat came anyway")


func test_seats_come_from_the_larger_bucket_outside_the_pick() -> void:
	var result := _totals({"player_party": "Alpha", "assist": {"won_over": {"PC": 2}}})
	for position: Dictionary in result["positions"]:
		if position["party_id"] == "PC":
			assert_eq(position["votes_no"], 6, "No was the larger bucket (8 against 3)")
			assert_eq(position["votes_abstain"], 3)
			assert_eq(position["votes_yes"], 4)


func test_a_party_with_nothing_outside_the_pick_gives_nothing() -> void:
	var plain := _totals({"player_party": "Alpha"})
	var helped := _totals({"player_party": "Alpha", "assist": {"won_over": {"PA": 3}}})
	assert_eq(helped["totals"]["Yes"], plain["totals"]["Yes"])


func test_more_seats_than_a_party_has_are_capped() -> void:
	var result := _totals({"player_party": "Alpha", "assist": {"won_over": {"PB": 99}}})
	for position: Dictionary in result["positions"]:
		if position["party_id"] == "PB":
			assert_eq(position["votes_yes"], 6)
			assert_eq(position["votes_no"], 0)


func test_lobbyists_take_seats_from_the_pick_after_the_swing() -> void:
	var plain := _totals({"player_party": "Alpha"})
	var worked := _totals({"player_party": "Alpha", "assist": {"worked_against": {"PA": 3}}})
	assert_eq(worked["totals"]["Yes"], int(plain["totals"]["Yes"]) - 3)
	assert_eq(worked["totals"]["No"], int(plain["totals"]["No"]) + 3)
	var abstain_pick := _totals({"player_party": "Alpha", "assist": {"worked_against": {"PB": 1}}}, "Abstain")
	for position: Dictionary in abstain_pick["positions"]:
		if position["party_id"] == "PB":
			assert_eq(position["votes_abstain"], 0)
			assert_eq(position["votes_no"], 6)


func test_a_won_member_can_flip_a_bill_and_counts_as_influence() -> void:
	var short := _bill()
	short["positions"][0]["votes_yes"] = 48
	short["positions"].append({"party_id": "PD", "party_name": "Delta", "votes_yes": 0, "votes_no": 34, "votes_abstain": 0, "disposition": "Opposed"})
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": short.duplicate(true), "player_party": "Alpha"})
	var alone := engine.choose("Yes")
	assert_false(alone["passed"])
	var assisted := FloorVoteEngine.new()
	assisted.setup({"bill": short.duplicate(true), "player_party": "Alpha", "assist": {"won_over": {"PB": 3, "PC": 1}}})
	var result := assisted.choose("Yes")
	assert_true(result["passed"])
	assert_true(result["outcome_flipped_by_influence"])


func test_the_preview_includes_the_assist() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Alpha", "assist": {"won_over": {"PB": 2}}})
	var plain := FloorVoteEngine.new()
	plain.setup({"bill": _bill(), "player_party": "Alpha"})
	assert_eq(engine.preview("Yes")["totals"]["Yes"], int(plain.preview("Yes")["totals"]["Yes"]) + 2)


func test_news_runs_for_a_while_and_feeds_the_ticker() -> void:
	GameState.record_news("visit_success")
	assert_true(GameState.active_news().has("visit_success"))
	assert_true(GameState.ticker_facts().has("news:visit_success"))
	var rows := [
		{"condition_type": "news", "condition_target": "visit_success", "text_en": "Sources say {player} worked hard."},
		{"condition_type": "news", "condition_target": "lobbyist_work", "text_en": "Lobbyists."},
		{"condition_type": "always", "text_en": "Always."},
	]
	var lines := OfficeTicker.eligible_lines(rows, {}, {}, "Kenshin Sako", GameState.ticker_facts())
	assert_eq(lines, ["Sources say Kenshin Sako worked hard.", "Always."])
	GameState.time_units += int(DataDB.balance["news_ticker_units"]) + 1
	assert_false(GameState.active_news().has("visit_success"), "the story ends")
	assert_eq(OfficeTicker.eligible_lines(rows, {}, {}, "K", GameState.ticker_facts()), ["Always."])


func test_the_real_ticker_has_a_line_for_each_story() -> void:
	var seen := {}
	for row: Dictionary in DataDB.office_ticker:
		if row["condition_type"] == "news":
			seen[row["condition_target"]] = str(row["text_en"])
	assert_true(seen.has("visit_success"))
	assert_true(seen.has("lobbyist_work"))
	assert_true(str(seen["visit_success"]).contains("{player}"))


func test_a_patron_vote_turns_the_assist_into_news_and_spends_it() -> void:
	GameState.booster_standing["BO05"] = 55
	assert_true(GameState.start_patron_level("PB051"))
	GameState.add_won_over("PT04", 1)
	GameState.add_worked_against("PT02", 1)
	while GameState.level_runner.current_stage().get("mode", "") != "Vote":
		GameState.finish_stage(LevelRunner.WON)
	var level_id := str(GameState.patron_runtime["level"]["level_id"])
	var engine := FloorVoteEngine.new()
	assert_true(engine.setup({"bill": DataDB.get_floor_vote(level_id), "player_party": str(DataDB.player.get("party", "")),
			"assist": GameState.bill_assist}))
	var result := engine.choose("Yes")
	GameState.record_floor_vote(engine.bill(), result, "Yes")
	assert_true(GameState.active_news().has("visit_success"))
	assert_true(GameState.active_news().has("lobbyist_work"))
	assert_true(BillAssist.is_empty(GameState.bill_assist), "spent with the vote")


func test_the_assist_and_the_news_survive_a_save() -> void:
	GameState.add_won_over("PT04", 2)
	GameState.record_news("lobbyist_work")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(BillAssist.total(GameState.bill_assist, "won_over"), 2)
	assert_true(GameState.active_news().has("lobbyist_work"))
