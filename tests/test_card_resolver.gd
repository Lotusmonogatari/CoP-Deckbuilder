extends GutTest
## Tests for the card arithmetic: affinity, rounding, and what affinity is
## deliberately NOT allowed to touch.


func test_affinity_multiplies_the_support_gain() -> void:
	var card := TestFixtures.card({"self_plus": 5})
	var effect := CardResolver.resolve(card, {"affinity": 1.2})
	assert_eq(effect["self_plus"], 6, "5 x 1.2 = 6")


func test_affinity_multiplies_the_opponent_loss() -> void:
	# The real case: C13 Present the Stats, -3, in a committee where Data
	# Driven is worth 1.3. That's 3.9, which rounds up to 4.
	var card := TestFixtures.card({"opp_minus": 3, "suit": "Data Driven"})
	var effect := CardResolver.resolve(card, {"affinity": 1.3})
	assert_eq(effect["opp_minus"], 4, "3 x 1.3 = 3.9, which rounds to 4")


func test_exact_halves_round_up() -> void:
	# C05 Impassioned Speech, +5, in a Town Hall where Emotional is 1.3.
	# That's exactly 6.5 — the case where "round half up" earns its keep.
	var card := TestFixtures.card({"self_plus": 5, "suit": "Emotional"})
	var effect := CardResolver.resolve(card, {"affinity": 1.3})
	assert_eq(effect["self_plus"], 7, "6.5 rounds up to 7, not down to 6")


func test_round_half_up_handles_negatives() -> void:
	# Godot's own round() would give -3 here. Ours gives -2, which is what
	# "round half up" means.
	assert_eq(CardResolver.round_half_up(-2.5), -2, "-2.5 rounds up to -2")
	assert_eq(CardResolver.round_half_up(2.5), 3, "2.5 rounds up to 3")
	assert_eq(CardResolver.round_half_up(2.4), 2)
	assert_eq(CardResolver.round_half_up(-2.6), -3)


func test_guard_is_not_multiplied_by_affinity() -> void:
	# C21 Iridescent Answer, guard 5, in a press conference where Duplicitous
	# is only worth 0.7. The guard still has to be 5.
	var card := TestFixtures.card({"guard": 5, "suit": "Duplicitous"})
	var effect := CardResolver.resolve(card, {"affinity": 0.7})
	assert_eq(effect["guard"], 5, "a bad room does not weaken your defence")


func test_draw_and_gaffe_are_not_multiplied() -> void:
	var card := TestFixtures.card({"draw": 2, "gaffe": 3})
	var effect := CardResolver.resolve(card, {"affinity": 1.3})
	assert_eq(effect["draw"], 2, "drawing two cards is drawing two cards")
	assert_eq(effect["gaffe"], 3, "a stage cannot make you more or less gaffe-prone")


func test_a_neutral_stage_changes_nothing() -> void:
	var card := TestFixtures.card({"self_plus": 4, "opp_minus": 2})
	var effect := CardResolver.resolve(card, {"affinity": 1.0})
	assert_eq(effect["self_plus"], 4)
	assert_eq(effect["opp_minus"], 2)


func test_missing_affinity_is_treated_as_neutral() -> void:
	var card := TestFixtures.card({"self_plus": 4})
	var effect := CardResolver.resolve(card, {})
	assert_eq(effect["self_plus"], 4, "no multiplier given means no change")


# ---------------------------------------------------------------------------
# Which slice of the audience a card is aimed at
# ---------------------------------------------------------------------------

func test_an_untargeted_card_counts_the_whole_room() -> void:
	var card := TestFixtures.card({"target_segment": "Any", "target_segment_id": null})
	assert_eq(CardResolver.segment_share(card, TestFixtures.stage()), 1.0)


func test_a_targeted_card_reads_its_share_of_the_audience() -> void:
	var card := TestFixtures.card({"target_segment": "Loyalists", "target_segment_id": "SG02"})
	# The test stage's audience is 60% loyalists.
	assert_eq(CardResolver.segment_share(card, TestFixtures.stage()), 0.6)


func test_a_segment_absent_from_the_stage_is_zero() -> void:
	var card := TestFixtures.card({"target_segment": "Donors", "target_segment_id": "SG04"})
	assert_eq(CardResolver.segment_share(card, TestFixtures.stage()), 0.0)


# ---------------------------------------------------------------------------
# Special effects
# ---------------------------------------------------------------------------

func test_a_bonus_fires_when_the_audience_is_big_enough() -> void:
	# C09 Party Unity: "+2 if Loyalists >= 50%." The stage is 60% loyalists.
	var card := TestFixtures.card({
		"self_plus": 3,
		"target_segment_id": "SG02",
		"special": "bonus_if_target_segment_ge_50",
		"special_value": 2,
	})
	var effect := CardResolver.resolve(card, {"affinity": 1.0, "segment_share": 0.6})
	assert_eq(effect["self_plus"], 5, "3 plus the 2-point bonus")
	assert_true(effect["flags"].get("special_triggered", false))


func test_a_bonus_stays_silent_when_the_audience_is_too_small() -> void:
	var card := TestFixtures.card({
		"self_plus": 3,
		"special": "bonus_if_target_segment_ge_50",
		"special_value": 2,
	})
	var effect := CardResolver.resolve(card, {"affinity": 1.0, "segment_share": 0.1})
	assert_eq(effect["self_plus"], 3, "no bonus below the 50% line")
	assert_false(effect["flags"].get("special_triggered", false))


func test_doubling_happens_after_affinity() -> void:
	# C06 Tearful Appeal: "Gain 4; doubled if Constituents >= 50%."
	# With a 1.1 multiplier that's 4.4 -> 4, then doubled to 8.
	var card := TestFixtures.card({
		"self_plus": 4,
		"suit": "Emotional",
		"special": "double_if_target_segment_ge_50",
	})
	var effect := CardResolver.resolve(card, {"affinity": 1.1, "segment_share": 0.7})
	assert_eq(effect["self_plus"], 8, "4 x 1.1 = 4.4 -> 4, doubled = 8")


func test_a_reputation_bonus_reads_the_players_standing() -> void:
	# C04 Return to First Principles: "+2 more if Kanban >= 60."
	var card := TestFixtures.card({
		"self_plus": 6,
		"special": "bonus_if_kanban_ge_60",
		"special_value": 2,
	})
	assert_eq(CardResolver.resolve(card, {"affinity": 1.0, "kanban": 70})["self_plus"], 8)
	assert_eq(CardResolver.resolve(card, {"affinity": 1.0, "kanban": 59})["self_plus"], 6)


func test_a_refutation_hits_harder_when_the_opponent_has_stumbled() -> void:
	# C15 Pursue the Contradiction: "-6; -2 more if opponent gaffe > 0."
	var card := TestFixtures.card({
		"opp_minus": 6,
		"special": "bonus_opp_minus_if_opp_gaffe",
		"special_value": 2,
	})
	assert_eq(CardResolver.resolve(card, {"affinity": 1.0, "opponent_gaffe": 1})["opp_minus"], 8)
	assert_eq(CardResolver.resolve(card, {"affinity": 1.0, "opponent_gaffe": 0})["opp_minus"], 6)


func test_groundwork_leaves_a_bonus_for_the_next_card() -> void:
	# C11 Groundwork sets the bonus up...
	var groundwork := TestFixtures.card({
		"self_plus": 2,
		"special": "buff_next_card_this_turn",
		"special_value": 2,
	})
	var effect := CardResolver.resolve(groundwork, {"affinity": 1.0})
	assert_eq(effect["flags"].get("next_card_bonus", 0), 2)

	# ...and the next card collects it, on top of its own affinity.
	var follow_up := TestFixtures.card({"self_plus": 5})
	var boosted := CardResolver.resolve(follow_up, {"affinity": 1.2, "next_card_bonus": 2})
	assert_eq(boosted["self_plus"], 8, "5 x 1.2 = 6, plus the flat 2 = 8")


func test_an_unknown_special_leaves_the_card_alone() -> void:
	# A typo in the workbook should make the card play as its plain numbers,
	# not crash a battle.
	var card := TestFixtures.card({"self_plus": 3, "special": "not_a_real_effect"})
	var effect := CardResolver.resolve(card, {"affinity": 1.0})
	assert_eq(effect["self_plus"], 3)


func test_every_known_special_key_is_handled() -> void:
	# Guards against adding a key to the list and forgetting to implement it.
	for key: String in SpecialEffects.KNOWN_KEYS:
		var card := TestFixtures.card({"self_plus": 4, "special": key, "special_value": 1})
		var effect := CardResolver.resolve(card, {"affinity": 1.0, "segment_share": 1.0, "kanban": 99, "opponent_gaffe": 1})
		assert_true(effect["flags"].get("special_triggered", false),
			"'%s' is in KNOWN_KEYS but does nothing" % key)
