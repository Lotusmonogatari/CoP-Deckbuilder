extends GutTest
## FloorVoteEngine.gd: the Yes/No/Abstain reallocation and favorability math
## for National Assembly Floor Voting (ST23). Fabricated data throughout,
## the same discipline test_office_notices.gd and test_opponent_cues.gd use
## for their own pure-logic files.

func _bill(overrides: Dictionary = {}) -> Dictionary:
	var bill := {
		"level_id": "LV_TEST",
		"bill_name": "Test Bill",
		"bill_description": "A bill about something.",
		"favorability_delta_supportive": 3,
		"favorability_delta_opposed": -2,
		"favorability_delta_neutral": 0,
		"positions": [
			{"party_id": "PT01", "party_name": "Frontier Party",
				"votes_yes": 8, "votes_no": 2, "votes_abstain": 0, "disposition": "Supportive",
				"cue_text": "We need every vote!"},
			{"party_id": "PT02", "party_name": "Keizaijiyuutou",
				"votes_yes": 1, "votes_no": 9, "votes_abstain": 0, "disposition": "Opposed",
				"cue_text": "This bill goes too far."},
			{"party_id": "PT03", "party_name": "Country Initiative",
				"votes_yes": 0, "votes_no": 0, "votes_abstain": 5, "disposition": "Neutral",
				"cue_text": "We'll wait and see."},
		],
	}
	for key: String in overrides:
		bill[key] = overrides[key]
	return bill


func test_setup_fails_with_no_bill() -> void:
	var engine := FloorVoteEngine.new()
	assert_false(engine.setup({}))
	assert_true(engine.setup_problems.size() > 0)


func test_setup_fails_when_the_players_own_party_has_no_position() -> void:
	var engine := FloorVoteEngine.new()
	assert_false(engine.setup({"bill": _bill(), "player_party": "Five Point Independents"}))


func test_setup_succeeds_with_a_real_bill_and_party() -> void:
	var engine := FloorVoteEngine.new()
	assert_true(engine.setup({"bill": _bill(), "player_party": "Frontier Party"}))
	assert_eq(engine.positions().size(), 3)


func test_majority_bucket_reads_the_biggest_pile() -> void:
	assert_eq(FloorVoteEngine.majority_bucket({"votes_yes": 8, "votes_no": 2, "votes_abstain": 0}), "Yes")
	assert_eq(FloorVoteEngine.majority_bucket({"votes_yes": 1, "votes_no": 9, "votes_abstain": 0}), "No")
	assert_eq(FloorVoteEngine.majority_bucket({"votes_yes": 0, "votes_no": 0, "votes_abstain": 5}), "Abstain")


func test_majority_bucket_ties_break_toward_yes_then_no() -> void:
	assert_eq(FloorVoteEngine.majority_bucket({"votes_yes": 4, "votes_no": 4, "votes_abstain": 4}), "Yes")
	assert_eq(FloorVoteEngine.majority_bucket({"votes_yes": 0, "votes_no": 4, "votes_abstain": 4}), "No")


func test_voting_with_your_own_partys_majority_changes_nothing() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	var result := engine.choose("Yes")
	var totals: Dictionary = result["totals"]
	# Frontier's own 8/2/0 is unchanged: the player's vote already matches
	# their party's assumed majority (Yes). Yes = 8 (Frontier) + 1
	# (Keizaijiyuutou); No = 2 (Frontier) + 9 (Keizaijiyuutou).
	assert_eq(totals["Yes"], 9)
	assert_eq(totals["No"], 11)
	assert_eq(totals["Abstain"], 5)


func test_voting_against_your_own_partys_majority_moves_one_seat() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	# Frontier's assumed majority is Yes (8 of 10) — voting No instead moves
	# exactly one seat from Frontier's Yes bucket into its No bucket.
	var result := engine.choose("No")
	var totals: Dictionary = result["totals"]
	assert_eq(totals["Yes"], 8)    # 9, minus the one seat that moved
	assert_eq(totals["No"], 12)    # 11, plus that same seat

	var frontier: Dictionary = result["positions"][0]
	assert_eq(int(frontier["votes_yes"]), 7)
	assert_eq(int(frontier["votes_no"]), 3)


func test_choosing_twice_only_resolves_once() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	engine.choose("No")
	var second := engine.choose("Yes")
	# The second call is a no-op: still reads the already-resolved result,
	# not a fresh reallocation from "Yes" this time.
	var frontier: Dictionary = second["positions"][0]
	assert_eq(int(frontier["votes_no"]), 3)


func test_passed_is_true_when_yes_outnumbers_no() -> void:
	# A different split from the shared fixture on purpose: _bill()'s own
	# Keizaijiyuutou opposes so heavily (1 yes to 9 no) that Yes can never
	# win there, which is exactly right for proving a FAILED vote below but
	# wrong for proving a PASSED one.
	var bill := _bill({"positions": [
		{"party_id": "PT01", "party_name": "Frontier Party",
			"votes_yes": 8, "votes_no": 2, "votes_abstain": 0, "disposition": "Supportive"},
		{"party_id": "PT02", "party_name": "Keizaijiyuutou",
			"votes_yes": 6, "votes_no": 4, "votes_abstain": 0, "disposition": "Neutral"},
	]})
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": bill, "player_party": "Frontier Party"})
	var result := engine.choose("Yes")
	assert_true(result["passed"])


func test_passed_is_false_when_no_outnumbers_yes() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	var result := engine.choose("No")
	assert_false(result["passed"])


func test_favorability_deltas_key_by_party_name_and_disposition() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	var result := engine.choose("Yes")
	var deltas: Dictionary = result["favorability_deltas"]
	assert_eq(int(deltas["Frontier Party"]), 3)
	assert_eq(int(deltas["Keizaijiyuutou"]), -2)
	assert_eq(int(deltas["Country Initiative"]), 0)


func test_favorability_deltas_apply_regardless_of_which_way_the_vote_goes() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	var result := engine.choose("No")
	var deltas: Dictionary = result["favorability_deltas"]
	# Keizaijiyuutou is Opposed on this bill regardless of the final tally —
	# its own delta doesn't depend on whether the bill passed.
	assert_eq(int(deltas["Keizaijiyuutou"]), -2)
