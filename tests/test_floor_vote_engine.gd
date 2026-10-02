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


# ---------------------------------------------------------------------------
# Influence swing (2026-09-28)
# ---------------------------------------------------------------------------

func _passing_triggers() -> Array:
	return [{"variable": "Reputation", "enabled": "Yes", "threshold": 85}]


func test_with_no_triggers_configured_the_gate_never_passes_and_nothing_swings() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party", "meta": {"Reputation": 100}})
	var result := engine.choose("No")
	assert_false(result["influence_gate_passed"])
	# Same totals as the plain reallocation test above: only 1 seat moved.
	assert_eq(int(result["totals"]["No"]), 12)


func test_below_threshold_the_gate_fails_even_with_triggers_configured() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 84}, "triggers": _passing_triggers(),
	})
	var result := engine.choose("No")
	assert_false(result["influence_gate_passed"])


func test_every_enabled_trigger_must_clear_its_own_threshold() -> void:
	var triggers := [
		{"variable": "Reputation", "enabled": "Yes", "threshold": 85},
		{"variable": "Party support", "enabled": "Yes", "threshold": 85},
	]
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90, "Party support": 84},  # one short
		"triggers": triggers,
	})
	var result := engine.choose("No")
	assert_false(result["influence_gate_passed"])


func test_gate_passes_when_every_enabled_trigger_clears_its_threshold() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 85}, "triggers": _passing_triggers(),
	})
	var result := engine.choose("No")
	assert_true(result["influence_gate_passed"])


func test_a_disabled_row_is_not_counted_toward_the_gate() -> void:
	var triggers := [{"variable": "Reputation", "enabled": "No", "threshold": 85}]
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 0}, "triggers": triggers,
	})
	# A disabled row can't hold the gate closed, but with nothing else
	# enabled either, "any_enabled" is false and the gate still doesn't pass.
	var result := engine.choose("No")
	assert_false(result["influence_gate_passed"])


func test_a_booster_standing_can_be_a_trigger_variable_too() -> void:
	var triggers := [{"variable": "BO02", "enabled": "Yes", "threshold": 85}]
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"booster_standing": {"BO02": 90}, "triggers": triggers,
	})
	var result := engine.choose("No")
	assert_true(result["influence_gate_passed"])


func test_the_swing_moves_seats_out_of_a_non_aligned_partys_assumed_bucket() -> void:
	# Keizaijiyuutou's assumed majority is No (9 of 10); the player votes
	# Yes. With the gate open and 0 resistance, every one of Keizaijiyuutou's
	# No seats is swingable.
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
		"default_resistance": 0,
	})
	var result := engine.choose("Yes")
	var keizai: Dictionary = result["positions"][1]
	assert_eq(int(keizai["votes_no"]), 0)
	assert_eq(int(keizai["votes_yes"]), 10)


func test_resistance_caps_how_many_seats_can_swing() -> void:
	# Keizaijiyuutou has 10 seats total; 70% resistance leaves 3 swingable
	# (floor(10 * 0.30) = 3).
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
		"default_resistance": 70,
	})
	var result := engine.choose("Yes")
	var keizai: Dictionary = result["positions"][1]
	assert_eq(int(keizai["votes_no"]), 6)   # 9, minus 3 swung
	assert_eq(int(keizai["votes_yes"]), 4)  # 1, plus 3 swung


func test_a_partys_own_resistance_overrides_the_flat_default() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
		"default_resistance": 0,
		"resistance_by_party": {"Keizaijiyuutou": 100},   # fully swing-proof
	})
	var result := engine.choose("Yes")
	var keizai: Dictionary = result["positions"][1]
	assert_eq(int(keizai["votes_no"]), 9)   # unchanged


func test_a_party_already_aligned_with_the_pick_is_never_touched_by_the_swing() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
		"default_resistance": 0,
	})
	var result := engine.choose("Yes")
	# Frontier's assumed majority is already Yes — the player's own pick — so
	# neither the 1-seat reallocation nor the swing touches it at all.
	var frontier: Dictionary = result["positions"][0]
	assert_eq(int(frontier["votes_yes"]), 8)
	assert_eq(int(frontier["votes_no"]), 2)


func test_outcome_flipped_by_influence_is_false_when_the_swing_doesnt_change_pass_fail() -> void:
	# Both parties are already Yes-majority here, so the gate opening
	# doesn't move anything — the bill was passing before the swing and
	# still is after it.
	var bill := _bill({"positions": [
		{"party_id": "PT01", "party_name": "Frontier Party",
			"votes_yes": 8, "votes_no": 2, "votes_abstain": 0, "disposition": "Supportive"},
		{"party_id": "PT02", "party_name": "Keizaijiyuutou",
			"votes_yes": 6, "votes_no": 4, "votes_abstain": 0, "disposition": "Neutral"},
	]})
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": bill, "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
	})
	var result := engine.choose("Yes")
	assert_true(result["passed"])
	assert_false(result["outcome_flipped_by_influence"])


func test_outcome_flipped_by_influence_is_true_when_the_swing_turns_a_loss_into_a_win() -> void:
	# Without any swing this fails (9 Yes vs 11 No, per the shared fixture).
	# With the gate open and 0 resistance, Keizaijiyuutou's whole 9 No seats
	# swing to Yes, turning it into a landslide win.
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
		"default_resistance": 0,
	})
	var result := engine.choose("Yes")
	assert_true(result["passed"])
	assert_true(result["outcome_flipped_by_influence"])


func test_outcome_flipped_by_influence_stays_false_when_the_gate_never_passes() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": _bill(), "player_party": "Frontier Party"})
	var result := engine.choose("Yes")
	assert_false(result["influence_gate_passed"])
	assert_false(result["outcome_flipped_by_influence"])


func test_choosing_twice_reports_the_same_influence_flags_both_times() -> void:
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": _passing_triggers(),
		"default_resistance": 0,
	})
	var first := engine.choose("Yes")
	var second := engine.choose("No")   # ignored — already resolved
	assert_eq(first["outcome_flipped_by_influence"], second["outcome_flipped_by_influence"])
	assert_eq(first["influence_gate_passed"], second["influence_gate_passed"])


func test_a_scoped_trigger_only_swings_the_party_it_names() -> void:
	# Named by the scoped trigger below, by party_id (PT02 is Keizaijiyuutou
	# in the shared fixture) — Country Initiative (PT03) is never named.
	var triggers := [{
		"variable": "Reputation", "enabled": "Yes", "threshold": 85,
		"applies_to_parties": ["PT02"],
	}]
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": triggers,
		"default_resistance": 0,
	})
	var result := engine.choose("Yes")

	# Keizaijiyuutou's assumed majority (No) isn't the picked bucket (Yes),
	# and the trigger names it directly, so its whole 9 No seats swing.
	var keizaijiyuutou: Dictionary = result["positions"][1]
	assert_eq(int(keizaijiyuutou["votes_yes"]), 10)
	assert_eq(int(keizaijiyuutou["votes_no"]), 0)

	# Country Initiative's assumed majority (Abstain) also isn't Yes, but
	# the trigger never names it — so even with the gate open elsewhere,
	# its 5 Abstain seats stay exactly where they were.
	var country_initiative: Dictionary = result["positions"][2]
	assert_eq(int(country_initiative["votes_abstain"]), 5)
	assert_eq(int(country_initiative["votes_yes"]), 0)

	assert_true(result["influence_gate_passed"])


func test_a_scoped_trigger_that_names_no_eligible_party_never_swings_anyone() -> void:
	var triggers := [{
		"variable": "Reputation", "enabled": "Yes", "threshold": 85,
		"applies_to_parties": ["PT99"],   # not a real party in this bill
	}]
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": _bill(), "player_party": "Frontier Party",
		"meta": {"Reputation": 90}, "triggers": triggers,
		"default_resistance": 0,
	})
	var result := engine.choose("Yes")
	assert_false(result["influence_gate_passed"])
	# Same as the no-triggers-configured case: no swing happened at all.
	assert_eq(int(result["totals"]["Yes"]), 9)
	assert_eq(int(result["totals"]["No"]), 11)
