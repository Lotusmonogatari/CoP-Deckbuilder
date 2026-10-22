extends GutTest
## Whipping the vote (2026-10-22): Party support spent for extra votes from the
## player's own party. Prices: base 10, three times that against the party.


func _bill() -> Dictionary:
	return {
		"level_id": "LV_TEST", "bill_name": "Test Bill", "bill_description": "x",
		"favorability_delta_supportive": 3, "favorability_delta_opposed": -2, "favorability_delta_neutral": 0,
		"positions": [
			{"party_id": "PT01", "party_name": "Frontier Party", "votes_yes": 8, "votes_no": 2,
				"votes_abstain": 0, "disposition": "Supportive", "cue_text": "x"},
			{"party_id": "PT02", "party_name": "Keizaijiyuutou", "votes_yes": 1, "votes_no": 9,
				"votes_abstain": 0, "disposition": "Opposed", "cue_text": "x"},
		],
	}


func _engine() -> FloorVoteEngine:
	var engine := FloorVoteEngine.new()
	assert_true(engine.setup({"bill": _bill(), "player_party": "Frontier Party"}))
	return engine


func test_a_vote_with_the_party_costs_the_base_and_against_it_triples() -> void:
	assert_eq(VoteWhip.unit_cost("Supportive", "Yes", 10, 3), 10)
	assert_eq(VoteWhip.unit_cost("Supportive", "No", 10, 3), 30)
	assert_eq(VoteWhip.unit_cost("Supportive", "Abstain", 10, 3), 30)
	assert_eq(VoteWhip.unit_cost("Opposed", "No", 10, 3), 10)
	assert_eq(VoteWhip.unit_cost("Opposed", "Yes", 10, 3), 30)
	assert_eq(VoteWhip.unit_cost("Neutral", "Yes", 10, 3), 10, "a neutral party has no position to go against")


func test_the_most_that_can_be_whipped_respects_the_floor_the_seats_and_the_cap() -> void:
	assert_eq(VoteWhip.max_whips(10, 60, 30, 9, 3), 3, "affordable 3, capped at 3")
	assert_eq(VoteWhip.max_whips(10, 45, 30, 9, 3), 1, "only 15 spare: one whip")
	assert_eq(VoteWhip.max_whips(30, 60, 30, 9, 3), 1, "30 each against the party")
	assert_eq(VoteWhip.max_whips(10, 60, 30, 2, 3), 2, "only two seats left")
	assert_eq(VoteWhip.max_whips(10, 29, 30, 9, 3), 0, "below the floor already")


func test_a_whip_moves_seats_from_the_players_party_to_the_pick() -> void:
	var engine := _engine()
	engine.set_whips(2)
	var result := engine.choose("No")
	assert_eq(result["whips_applied"], 2)
	# Frontier: 8 Yes 2 No. The player's own seat moves Yes to No, then two more.
	var totals: Dictionary = result["totals"]
	var plain: Dictionary = _engine().choose("No")["totals"]
	assert_eq(int(totals["No"]) - int(plain["No"]), 2)
	assert_eq(int(plain["Yes"]) - int(totals["Yes"]), 2)


func test_a_whip_stops_when_the_party_has_no_one_left_outside_the_pick() -> void:
	var engine := _engine()
	engine.set_whips(99)
	var result := engine.choose("Yes")
	# Frontier holds 2 No votes outside Yes.
	assert_eq(result["whips_applied"], 2)


func test_whip_capacity_counts_the_seats_outside_the_pick() -> void:
	var engine := _engine()
	assert_eq(engine.whip_capacity("Yes"), 2, "the party's two No votes")
	assert_eq(engine.whip_capacity("No"), 7, "eight Yes, minus the player's own seat that moves")


func test_the_preview_includes_the_whips_without_touching_the_vote() -> void:
	var engine := _engine()
	var plain: Dictionary = engine.preview("No")["totals"]
	engine.set_whips(2)
	var whipped: Dictionary = engine.preview("No")["totals"]
	assert_eq(int(whipped["No"]) - int(plain["No"]), 2)
	assert_eq(engine.whips_applied(), 0, "a preview does not vote")


func test_spending_party_support_respects_the_floor() -> void:
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.meta["Party support"] = 55
	assert_false(GameState.spend_party_support(30, "x"), "that would leave 25, under the floor of 30")
	assert_eq(int(GameState.meta["Party support"]), 55, "nothing was spent")
	assert_true(GameState.spend_party_support(20, "whipping a vote"))
	assert_eq(int(GameState.meta["Party support"]), 35)
	GameState.load_save(saved)
