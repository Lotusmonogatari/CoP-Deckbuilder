extends GutTest
## The lobbyist's trade (influence building step C, 2026-10-19): the leverage
## rules, who the lobbyist is, the level it adds, and what a deal, a refusal
## or a failed meeting does to the bill and the vote.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.booster_standing["BO05"] = 75
	GameState.booster_standing["BO24"] = 40


func after_each() -> void:
	DataDB.clear_runtime()
	GameState.load_save(_saved)
	DataDB.clear_runtime()


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	return rng


func _levers() -> Dictionary:
	return DataDB.balance


func test_leverage_starts_from_standing_and_moves_with_answers() -> void:
	assert_eq(LobbyistTrade.starting_leverage(60, true, _levers()), 35)    # 15 + 20
	assert_eq(LobbyistTrade.starting_leverage(60, false, _levers()), 20)   # 15 + 5
	assert_eq(LobbyistTrade.starting_leverage(0, false, _levers()), 5)
	assert_eq(LobbyistTrade.after_answer(50, MpVisit.STRONG, _levers()), 65)
	assert_eq(LobbyistTrade.after_answer(50, MpVisit.MEDIUM, _levers()), 55)
	assert_eq(LobbyistTrade.after_answer(50, MpVisit.WEAK, _levers()), 40)
	assert_eq(LobbyistTrade.after_answer(95, MpVisit.STRONG, _levers()), 100, "capped")
	assert_eq(LobbyistTrade.after_answer(5, MpVisit.WEAK, _levers()), 0, "floored")


func test_leverage_is_a_budget() -> void:
	assert_eq(LobbyistTrade.total_cost(["donation", "help"], _levers()), 70)
	assert_false(LobbyistTrade.can_close([], 100, _levers()), "a deal needs a reward")
	assert_true(LobbyistTrade.can_close(["donation"], 20, _levers()))
	assert_false(LobbyistTrade.can_close(["donation", "help"], 69, _levers()))
	assert_true(LobbyistTrade.can_close(["donation", "help"], 70, _levers()))


func test_a_bill_can_never_be_traded_down_to_nothing() -> void:
	assert_eq(LobbyistTrade.drop_options(["A", "B"]), ["A", "B"])
	assert_eq(LobbyistTrade.drop_options(["A"]), [])


func test_refusal_costs_follow_the_kind_of_bill() -> void:
	assert_eq(LobbyistTrade.seats_lost("Favor", true, _levers()), 0)
	assert_eq(LobbyistTrade.seats_lost("Favor", false, _levers()), 0)
	assert_eq(LobbyistTrade.seats_lost("Flagship", true, _levers()), 2)
	assert_eq(LobbyistTrade.seats_lost("Flagship", false, _levers()), 1)


func test_the_lobbyist_speaks_for_an_organization_the_bill_hurts() -> void:
	var effects := [{"target": "BO05", "delta": 3}, {"target": "BO09", "delta": -2}, {"target": "BO15", "delta": -1}]
	var lobbyists := [
		{"opp_id": "L9", "affiliation": "BO09", "name": "Labor"},
		{"opp_id": "L15", "affiliation": "BO15", "name": "Tradition"},
		{"opp_id": "L5", "affiliation": "BO05", "name": "Chamber"},
	]
	var picked := LobbyistTrade.pick_lobbyist(effects, "BO05", "", lobbyists, {}, _rng())
	assert_eq(picked["org"], "BO09", "the most hurt organization with a representative")
	assert_eq(LobbyistTrade.pick_lobbyist(effects, "BO05", "BO09", lobbyists, {}, _rng())["org"], "BO15", "never the ally")
	assert_true(LobbyistTrade.pick_lobbyist([{"target": "BO30", "delta": -2}], "BO05", "", lobbyists, {}, _rng()).is_empty())


func test_the_component_they_ask_for_is_the_one_that_hurts_them_most() -> void:
	var by_id := {
		"A": {"loses": [{"target": "BO09", "delta": -1}]},
		"B": {"loses": [{"target": "BO09", "delta": -3}]},
		"C": {"loses": null},
	}
	assert_eq(LobbyistTrade.asked_component(["A", "B", "C"], by_id, "BO09"), "B")
	assert_eq(LobbyistTrade.asked_component(["A", "B", "C"], by_id, "BO99"), "")


func test_the_right_party_gets_the_help_and_the_hindrance() -> void:
	var ties := [
		{"party_id": "PT05", "booster_id": "BO05", "weight": 5.0},
		{"party_id": "PT03", "booster_id": "BO05", "weight": -2.0},
		{"party_id": "PT04", "booster_id": "BO05", "weight": 1.0},
	]
	var positions := [
		{"party_id": "PT05", "votes_yes": 20, "votes_no": 5, "votes_abstain": 0},
		{"party_id": "PT03", "votes_yes": 0, "votes_no": 27, "votes_abstain": 0},
		{"party_id": "PT04", "votes_yes": 5, "votes_no": 0, "votes_abstain": 0},
	]
	assert_eq(LobbyistTrade.party_for_org("BO05", ties, positions), "PT05", "best tied, with Yes seats to lose")
	assert_eq(LobbyistTrade.party_for_help("BO05", ties, positions), "PT05", "best tied, with seats outside Yes")
	positions[0]["votes_no"] = 0
	assert_eq(LobbyistTrade.party_for_help("BO05", ties, positions), "PT03", "PT05 is all Yes; PT03 has the seats")
	assert_eq(LobbyistTrade.party_for_org("BO99", [], positions), "PT05", "fallback: the party with the most Yes seats")
	assert_eq(LobbyistTrade.drop_costs("BO05", "BO05", "BO24", _levers()), [{"target": "BO05", "delta": -3}])
	assert_eq(LobbyistTrade.drop_costs("BO24", "BO05", "BO24", _levers()), [{"target": "BO24", "delta": -1}])
	assert_eq(LobbyistTrade.drop_costs("BO30", "BO05", "BO24", _levers()), [])


func test_the_template_adds_the_trade_stage_only_when_offered() -> void:
	var favor: Dictionary = {}
	for template: Dictionary in DataDB.bill_level_templates:
		if template["kind"] == "Favor":
			favor = template
	assert_eq(LevelTemplate.stages(favor, "ST16", "National", false, true), ["ST263", "ST16", "ST262", "ST23"])
	assert_eq(LevelTemplate.stages(favor, "ST16", "National", false, false), ["ST263", "ST16", "ST23"])


func _level_with_trade() -> String:
	# The first patron bill whose level has a lobbyist trade.
	for row: Dictionary in DataDB.patron_bills:
		var built := PatronLevel.register(str(row["patron_bill_id"]), [])
		if (built["level"] as Dictionary).has("trade"):
			return str(row["patron_bill_id"])
		DataDB.clear_runtime()
	return ""


func test_some_patron_bills_carry_a_trade_and_it_is_well_formed() -> void:
	var with_trade := 0
	for row: Dictionary in DataDB.patron_bills:
		var built := PatronLevel.register(str(row["patron_bill_id"]), [])
		var level: Dictionary = built["level"]
		if level.has("trade"):
			with_trade += 1
			var trade: Dictionary = level["trade"]
			var lobbyist := DataDB.get_opponent(str(trade["opp_id"]))
			assert_eq(lobbyist["affiliation"], trade["org"])
			assert_ne(trade["org"], row["organization"])
			assert_eq((trade["questions"] as Array).size(), 3)
			var runner := LevelRunner.new(BattleSetup.expand_level(level))
			assert_eq(runner.problems().size(), 0, str(runner.problems()))
			var ids: Array = []
			for stage: Dictionary in runner.stages:
				ids.append(stage["stage_id"])
			assert_true(ids.has("ST262"))
			assert_eq(ids.find("ST262"), ids.size() - 2, "just before the vote")
		DataDB.clear_runtime()
	assert_gt(with_trade, 10, "a good share of the patron bills have a lobbyist")


func _start_trade_level() -> String:
	var id := _level_with_trade()
	assert_ne(id, "")
	GameState.booster_standing[str(PatronLevel.patron_bill(id)["organization"])] = 80
	var row := PatronLevel.patron_bill(id)
	if row["kind"] == "Flagship":
		GameState.patron_requests[str(row["organization"]) .replace("BO", "PB") + "1"] = {}
	DataDB.clear_runtime()
	assert_true(GameState.start_patron_level(id))
	while str(GameState.level_runner.current_stage().get("stage_id", "")) != "ST262":
		GameState.finish_stage(LevelRunner.WON)
	return id


func test_a_deal_drops_the_component_and_pays_what_was_chosen() -> void:
	var id := _start_trade_level()
	var trade := GameState.current_trade()
	var ids: Array = (GameState.patron_requests[id]["components"] as Array).duplicate()
	var dropped := str(ids[0])
	GameState.meta["Funds"] = 20000   # below the starting Funds cap, so the gift lands in full
	var funds := int(GameState.meta["Funds"])
	var xp := GameState.xp
	var old_name := str(DataDB.get_bill(id)["bill_name"])
	var result := GameState.conclude_trade_deal(dropped, ["donation"], 50)
	assert_true(result["ok"])
	assert_eq(GameState.meta["Funds"], funds + int(DataDB.balance["trade_donation_funds"]))
	assert_eq(GameState.xp, xp + int(DataDB.balance["trade_donation_xp"]))
	var after: Array = GameState.patron_requests[id]["components"]
	assert_eq(after.size(), ids.size() - 1)
	assert_false(after.has(dropped))
	assert_eq(DataDB.component_ids_of(id), after, "the registry follows the bill")
	assert_ne(DataDB.get_bill(id)["bill_name"], old_name)
	var vote_stage: Dictionary = {}
	for stage: Dictionary in GameState.level_runner.stages:
		if stage["mode"] == "Vote":
			vote_stage = stage
	assert_eq(vote_stage["floor_vote"]["bill_name"], DataDB.get_bill(id)["bill_name"], "the vote stage carries the new bill")
	assert_true(bool(trade["done"]))
	assert_true(BillAssist.is_empty(GameState.bill_assist))


func test_a_deal_is_refused_when_it_costs_more_than_the_leverage() -> void:
	var id := _start_trade_level()
	var ids: Array = GameState.patron_requests[id]["components"]
	assert_false(GameState.conclude_trade_deal(str(ids[0]), ["donation", "help"], 69)["ok"])
	assert_false(GameState.conclude_trade_deal(str(ids[0]), [], 100)["ok"])
	assert_false(GameState.conclude_trade_deal("NOT_A_COMPONENT", ["donation"], 100)["ok"])
	assert_eq((GameState.patron_requests[id]["components"] as Array).size(), ids.size(), "nothing changed")
	assert_false(bool(GameState.current_trade()["done"]))


func test_help_adds_a_seat_to_the_bill_assist() -> void:
	var id := _start_trade_level()
	var ids: Array = GameState.patron_requests[id]["components"]
	var result := GameState.conclude_trade_deal(str(ids[0]), ["help"], 60)
	assert_true(result["ok"])
	assert_eq(BillAssist.total(GameState.bill_assist, "won_over"), 1)


func test_sentiment_and_favor_move_standing() -> void:
	var id := _start_trade_level()
	var org := str(GameState.current_trade()["org"])
	var before := int(GameState.booster_standing[org])
	var ids: Array = GameState.patron_requests[id]["components"]
	var result := GameState.conclude_trade_deal(str(ids[0]), ["sentiment", "party_favor"], 100)
	assert_true(result["ok"])
	assert_eq(int(GameState.booster_standing[org]), before + int(DataDB.balance["trade_sentiment_standing"]))
	var types: Array = []
	for gain: Dictionary in result["gains"]:
		types.append(gain["type"])
	assert_true(types.has("sentiment"))


func test_losing_a_patron_component_costs_the_patron() -> void:
	var id := _start_trade_level()
	var row := PatronLevel.patron_bill(id)
	var patron := str(row["organization"])
	var by_id := ComposedBill.index(DataDB.bill_components)
	var own: String = ""
	for component_id: Variant in GameState.patron_requests[id]["components"]:
		if by_id[str(component_id)]["owner"] == patron:
			own = str(component_id)
	assert_ne(own, "")
	var before := int(GameState.booster_standing[patron])
	assert_true(GameState.conclude_trade_deal(own, ["donation"], 100)["ok"])
	assert_eq(int(GameState.booster_standing[patron]), before - int(DataDB.balance["trade_patron_cost"]))


func test_meeting_without_a_deal_and_refusing_cost_seats_only_on_a_flagship() -> void:
	var id := _start_trade_level()
	var kind := str(PatronLevel.patron_bill(id)["kind"])
	var result := GameState.conclude_trade_without_deal(true)
	if kind == "Flagship":
		assert_eq(result["seats"], 2)
		assert_eq(BillAssist.total(GameState.bill_assist, "worked_against"), 2)
	else:
		assert_eq(result["seats"], 0)
		assert_true(BillAssist.is_empty(GameState.bill_assist))
	assert_true(bool(GameState.current_trade()["done"]))
	assert_eq(GameState.conclude_trade_without_deal(false)["seats"], 0, "settled once")


func test_a_flagship_trade_costs_one_seat_without_agreement() -> void:
	DataDB.balance["trade_favor_no_deal_seats"] = 0
	GameState.booster_standing["BO05"] = 75
	GameState.patron_requests["PB051"] = {"status": PatronRequests.PASSED, "components": ["CB051", "CB052"], "amended": false, "tries": 0}
	var built := PatronLevel.register("PB052", [])
	if not (built["level"] as Dictionary).has("trade"):
		pending("PB052 has no lobbyist in this data")
		return
	DataDB.clear_runtime()
	assert_true(GameState.start_patron_level("PB052"))
	assert_eq(GameState.conclude_trade_without_deal(false)["seats"], 1)
	assert_eq(BillAssist.total(GameState.bill_assist, "worked_against"), 1)


func test_a_lobbyist_story_runs_after_the_vote_when_they_worked_against_you() -> void:
	var id := _start_trade_level()
	GameState.add_worked_against("PT05", 1)
	while GameState.level_runner.current_stage().get("mode", "") != "Vote":
		GameState.finish_stage(LevelRunner.WON)
	var level_id := str(GameState.patron_runtime["level"]["level_id"])
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": DataDB.get_floor_vote(level_id), "player_party": str(DataDB.player.get("party", "")), "assist": GameState.bill_assist})
	GameState.record_floor_vote(engine.bill(), engine.choose("Yes"), "Yes")
	assert_true(GameState.active_news().has("lobbyist_work"))
	assert_true(id != "")


func test_the_trade_survives_save_and_load() -> void:
	_start_trade_level()
	var before := GameState.current_trade().duplicate(true)
	var saved := GameState.to_save()
	DataDB.clear_runtime()
	GameState.load_save(saved)
	assert_eq(GameState.current_trade()["opp_id"], before["opp_id"])
	assert_eq(str(GameState.level_runner.current_stage()["stage_id"]), "ST262")


func test_every_trade_on_offer_leaves_the_bill_carryable_and_never_passes_alone() -> void:
	var offered := 0
	for row: Dictionary in DataDB.patron_bills:
		var id := str(row["patron_bill_id"])
		var built := PatronLevel.register(id, [])
		var level: Dictionary = built["level"]
		if level.has("trade"):
			var trade: Dictionary = level["trade"]
			assert_gt((trade["drops"] as Array).size(), 0, id)
			for dropped: Variant in trade["drops"]:
				var rest: Array = (built["component_ids"] as Array).duplicate()
				rest.erase(dropped)
				assert_true(PatronLevel.carryable(PatronLevel.compose_ids(id, rest)), "%s without %s" % [id, dropped])
				offered += 1
		DataDB.clear_runtime()
	assert_gt(offered, 10)
