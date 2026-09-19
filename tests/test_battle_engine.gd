extends GutTest
## Tests for the battle engine: the turn loop, block, gaffes, the deck, and
## every way a stage can end.


func _start(overrides: Dictionary = {}) -> BattleEngine:
	var engine := BattleEngine.new()
	var ready := engine.setup(TestFixtures.battle_config(overrides))
	assert_true(ready, "setup failed: %s" % [engine.setup_problems])
	return engine


## Puts a specific card in hand, so a test doesn't depend on the shuffle.
func _force_into_hand(engine: BattleEngine, card_id: String) -> void:
	if not engine.state.hand.has(card_id):
		engine.state.hand.append(card_id)


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func test_a_battle_starts_with_a_full_hand_and_full_energy() -> void:
	var engine := _start()
	assert_eq(engine.state.hand.size(), 5, "the stage's hand size")
	assert_eq(engine.state.energy, 3, "the stage's energy per turn")
	assert_eq(engine.state.turn, 1)
	assert_false(engine.state.is_over())


func test_the_starting_support_comes_from_the_stage() -> void:
	var engine := _start()
	assert_eq(engine.state.bar.player, 40)
	assert_eq(engine.state.bar.opponent, 40)


func test_an_unpopular_bill_puts_the_opponent_further_ahead() -> void:
	var engine := _start({"bill_difficulty": 6})
	assert_eq(engine.state.bar.opponent, 46)
	assert_eq(engine.state.bar.player, 40, "the player is unaffected")


func test_reputation_shifts_the_players_start_in_a_press_stage() -> void:
	var engine := _start({"start_adjustment": -5})
	assert_eq(engine.state.bar.player, 35)


func test_a_battle_will_not_start_without_a_deck() -> void:
	var engine := BattleEngine.new()
	assert_false(engine.setup(TestFixtures.battle_config({"deck": []})))
	assert_string_contains(engine.setup_problems[0], "no deck")


func test_an_opponent_with_no_pattern_falls_back_to_the_default() -> void:
	# This is the state every opponent in the workbook is in today. Rather
	# than being unplayable, they borrow the shared pattern from rules.json.
	var engine := BattleEngine.new()
	var ready := engine.setup(TestFixtures.battle_config({
		"opponent": {"opp_id": "OP03", "name": "Masato Maruyama", "intent_pattern": null},
	}))

	assert_true(ready, "the battle starts: %s" % [engine.setup_problems])
	assert_true(engine.used_default_intent_pattern, "and says it is using the default")
	assert_eq(engine.current_intent(), {"verb": "attack", "value": 6})


func test_an_opponents_own_pattern_beats_the_default() -> void:
	var engine := BattleEngine.new()
	engine.setup(TestFixtures.battle_config({
		"opponent": TestFixtures.opponent([["block", 9]]),
	}))

	assert_false(engine.used_default_intent_pattern, "this opponent brought their own")
	assert_eq(engine.current_intent(), {"verb": "block", "value": 9})


func test_a_battle_will_not_start_when_there_is_no_pattern_anywhere() -> void:
	# With no opponent pattern AND no default, there is genuinely nothing for
	# the opponent to do, and starting would be worse than refusing.
	var engine := BattleEngine.new()
	assert_false(engine.setup(TestFixtures.battle_config({
		"opponent": {"opp_id": "OP03", "name": "Masato Maruyama", "intent_pattern": null},
		"rules": TestFixtures.rules({"default_intent_pattern": null}),
	})))
	assert_string_contains(engine.setup_problems[0], "intent pattern")


func test_the_default_pattern_cycles_like_any_other() -> void:
	var engine := BattleEngine.new()
	engine.setup(TestFixtures.battle_config({
		"opponent": {"opp_id": "OP03", "name": "Masato Maruyama", "intent_pattern": null},
	}))

	assert_eq(engine.end_turn()["intent"], {"verb": "attack", "value": 6})
	assert_eq(engine.end_turn()["intent"], {"verb": "gain", "value": 4})
	assert_eq(engine.end_turn()["intent"], {"verb": "block", "value": 5})
	assert_eq(engine.end_turn()["intent"], {"verb": "attack", "value": 6}, "and round again")


func test_deck_ai_is_refused_with_a_readable_message() -> void:
	var engine := BattleEngine.new()
	assert_false(engine.setup(TestFixtures.battle_config({
		"rules": TestFixtures.rules({"opponent_engine": "deck_ai"}),
	})))
	assert_string_contains(engine.setup_problems[0], "not built yet")


func test_a_card_in_the_deck_but_not_in_the_data_is_caught() -> void:
	var engine := BattleEngine.new()
	assert_false(engine.setup(TestFixtures.battle_config({"deck": ["NOT_A_CARD"]})))
	assert_string_contains(engine.setup_problems[0], "NOT_A_CARD")


# ---------------------------------------------------------------------------
# Playing cards
# ---------------------------------------------------------------------------

func test_playing_a_card_costs_energy_and_moves_the_bar() -> void:
	var engine := _start()
	_force_into_hand(engine, "GAIN3")

	var result := engine.play_card("GAIN3")
	assert_true(result["ok"])
	assert_eq(engine.state.energy, 2, "one energy spent")
	assert_eq(engine.state.bar.player, 43)
	assert_true(engine.state.discard.has("GAIN3"), "the card went to the discard pile")


func test_a_card_cannot_be_played_without_the_energy_for_it() -> void:
	var engine := _start()
	_force_into_hand(engine, "GAIN3")
	engine.state.energy = 0

	var result := engine.play_card("GAIN3")
	assert_false(result["ok"])
	assert_string_contains(result["reason"], "not enough time")
	assert_eq(engine.state.bar.player, 40, "nothing happened")


func test_a_card_not_in_hand_cannot_be_played() -> void:
	var engine := _start()
	engine.state.hand.clear()
	assert_false(engine.play_card("GAIN3")["ok"])


func test_affinity_is_applied_when_a_card_is_played() -> void:
	# ATTACK3 is Data Driven, worth 1.1 on the floor: 3 x 1.1 = 3.3 -> 3.
	var engine := _start()
	_force_into_hand(engine, "ATTACK3")
	engine.play_card("ATTACK3")

	assert_eq(engine.state.bar.opponent, 37)
	assert_eq(engine.state.bar.undecided, 24, "the three went back to undecided")


# ---------------------------------------------------------------------------
# Block
# ---------------------------------------------------------------------------

func test_block_absorbs_an_attack() -> void:
	# The opponent attacks for 5; the player is holding 5 guard.
	var engine := _start()
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")
	assert_eq(engine.state.block, 5)

	var turn := engine.end_turn()
	assert_eq(turn["opponent"]["damage"], 0, "the attack was fully absorbed")
	assert_eq(engine.state.bar.player, 40)


func test_an_attack_bigger_than_the_block_gets_partly_through() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["attack", 8]])})
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")

	var turn := engine.end_turn()
	assert_eq(turn["opponent"]["absorbed"], 5)
	assert_eq(turn["opponent"]["damage"], 3, "8 minus 5 got through")
	assert_eq(engine.state.bar.player, 37)


func test_block_does_not_carry_into_the_next_turn() -> void:
	var engine := _start()
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")
	engine.end_turn()

	assert_eq(engine.state.block, 0, "guard is spent at the end of the turn either way")


func test_unspent_energy_does_not_carry_over() -> void:
	var engine := _start()
	engine.state.energy = 3
	engine.end_turn()
	assert_eq(engine.state.energy, 3, "refilled, not added to")


# ---------------------------------------------------------------------------
# Gaffes
# ---------------------------------------------------------------------------

func test_gaffes_accumulate() -> void:
	var engine := _start()
	_force_into_hand(engine, "GAFFE2")
	engine.play_card("GAFFE2")
	assert_eq(engine.state.gaffe, 2)


func test_the_gaffe_meter_never_goes_below_zero() -> void:
	# An apology on a clean record is wasted, not banked as credit.
	var engine := _start({
		"cards": {"APOLOGY": TestFixtures.card({"card_id": "APOLOGY", "gaffe": -3, "cost": 1})},
		"deck": ["APOLOGY", "APOLOGY"],
	})
	_force_into_hand(engine, "APOLOGY")
	engine.play_card("APOLOGY")
	assert_eq(engine.state.gaffe, 0)


func test_filling_the_gaffe_meter_loses_the_stage_immediately() -> void:
	var engine := _start()
	engine.state.gaffe = 4          # the test stage's limit is 6
	_force_into_hand(engine, "GAFFE2")

	engine.play_card("GAFFE2")
	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss")
	assert_string_contains(engine.state.outcome_reason, "gaffe meter")


func test_the_gaffe_warning_only_lights_at_one_from_the_end() -> void:
	# The brief is specific: the counter turns red only when one more gaffe
	# would end the stage, not before.
	var engine := _start()
	engine.state.gaffe = 4
	assert_false(engine.gaffe_is_critical(), "two away is not a warning")

	engine.state.gaffe = 5
	assert_true(engine.gaffe_is_critical(), "one away is")


# ---------------------------------------------------------------------------
# The deck
# ---------------------------------------------------------------------------

func test_drawing_a_card_adds_it_to_hand() -> void:
	var engine := _start()
	# Stocked by hand rather than relying on the shuffle, so the numbers below
	# are exact rather than "whatever happened to be dealt".
	engine.state.deck.assign(["GAIN3", "GAIN3", "GAIN3"])
	engine.state.hand.assign(["DRAW2"])

	engine.play_card("DRAW2")
	assert_eq(engine.state.hand.size(), 2, "DRAW2 left hand and two cards came in")
	assert_eq(engine.state.deck.size(), 1, "two came off the top of the deck")


func test_a_card_that_draws_cannot_deal_itself_back() -> void:
	# The deck is empty, so the draw has to reshuffle. The card being played
	# must not be part of that reshuffle — being handed back the card you just
	# played would be baffling.
	var engine := _start()
	engine.state.deck.clear()
	engine.state.discard.assign(["GAIN3"])
	engine.state.hand.assign(["DRAW2"])

	engine.play_card("DRAW2")
	assert_false(engine.state.hand.has("DRAW2"), "the played card did not come back")
	assert_true(engine.state.discard.has("DRAW2"), "it is in the discard pile")
	assert_true(engine.state.hand.has("GAIN3"), "the one card available was drawn")


func test_the_discard_pile_is_reshuffled_when_the_deck_runs_out() -> void:
	var engine := _start()
	# Empty the deck, and put something in the discard to shuffle back in.
	engine.state.deck.clear()
	engine.state.discard.assign(["GAIN3", "ATTACK3"])
	_force_into_hand(engine, "DRAW2")

	engine.play_card("DRAW2")
	assert_eq(engine.state.discard.size(), 1, "only the card just played")
	assert_true(engine.state.hand.has("GAIN3") or engine.state.hand.has("ATTACK3"))


func test_drawing_from_nothing_at_all_is_harmless() -> void:
	# Every card is already in hand. Drawing should stop, not loop forever.
	var engine := _start()
	engine.state.deck.clear()
	engine.state.discard.clear()
	_force_into_hand(engine, "DRAW2")

	engine.play_card("DRAW2")
	assert_false(engine.state.is_over(), "the battle carried on")


func test_the_same_seed_deals_the_same_hand() -> void:
	var first := _start({"seed": 999})
	var second := _start({"seed": 999})
	assert_eq(first.state.hand, second.state.hand, "a fixed seed makes battles repeatable")


# ---------------------------------------------------------------------------
# Ending the turn
# ---------------------------------------------------------------------------

func test_the_hand_is_discarded_at_the_end_of_the_turn() -> void:
	var engine := _start()
	engine.end_turn()
	assert_eq(engine.state.hand.size(), 5, "a fresh hand was drawn")
	assert_eq(engine.state.turn, 2)


func test_the_hand_can_be_kept_instead() -> void:
	# The other setting of the discard_hand_end_of_turn switch.
	var engine := _start({"rules": TestFixtures.rules({"discard_hand_end_of_turn": false})})
	var kept: Array = engine.state.hand.duplicate()

	engine.end_turn()
	for card_id: String in kept:
		assert_true(engine.state.hand.has(card_id), "%s stayed in hand" % card_id)


func test_the_opponent_acts_on_its_intent() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["gain", 6]])})
	engine.end_turn()
	assert_eq(engine.state.bar.opponent, 46)


func test_the_intent_shown_is_the_one_that_happens() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["attack", 5], ["gain", 4]])})

	assert_eq(engine.current_intent(), {"verb": "attack", "value": 5})
	engine.end_turn()
	assert_eq(engine.current_intent(), {"verb": "gain", "value": 4}, "now showing next turn's")


# ---------------------------------------------------------------------------
# Winning and losing
# ---------------------------------------------------------------------------

func test_reaching_the_threshold_wins() -> void:
	var engine := _start()
	engine.state.bar.player_gains(10)   # 40 -> 50
	_force_into_hand(engine, "GAIN3")

	engine.play_card("GAIN3")
	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win")


func test_the_opponent_cannot_win_on_support_by_default() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["gain", 20]])})
	engine.state.bar.opponent_gains(10)   # 40 -> 50, one short

	engine.end_turn()   # the opponent gains 20 more, well past 51
	assert_true(engine.state.bar.opponent >= 51)
	assert_false(engine.state.is_over(), "the switch says it can only win on the clock")


func test_the_opponent_can_win_on_support_when_the_switch_is_on() -> void:
	var engine := _start({
		"opponent": TestFixtures.opponent([["gain", 20]]),
		"rules": TestFixtures.rules({"opponent_can_win_by_threshold": true}),
	})
	engine.state.bar.opponent_gains(10)

	engine.end_turn()
	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss")


func test_running_out_of_turns_loses_by_default() -> void:
	var engine := _start({"stage": TestFixtures.stage({"turn_limit": 2})})
	engine.end_turn()
	engine.end_turn()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss")
	assert_string_contains(engine.state.outcome_reason, "Time ran out")


func test_running_out_of_turns_can_hand_it_to_whoever_is_ahead() -> void:
	var engine := _start({
		"stage": TestFixtures.stage({"turn_limit": 1}),
		"opponent": TestFixtures.opponent([["block", 1]]),
		"rules": TestFixtures.rules({"turn_limit_outcome": "highest_support_wins"}),
	})
	engine.state.bar.player_gains(5)   # 45 against 40

	engine.end_turn()
	assert_eq(engine.state.outcome, "win")


func test_running_out_of_turns_can_call_for_a_retry() -> void:
	var engine := _start({
		"stage": TestFixtures.stage({"turn_limit": 1}),
		"opponent": TestFixtures.opponent([["block", 1]]),
		"rules": TestFixtures.rules({"turn_limit_outcome": "tie_retry"}),
	})
	engine.end_turn()
	assert_eq(engine.state.outcome, "retry")


func test_nothing_more_can_be_played_once_the_stage_is_over() -> void:
	var engine := _start()
	engine.state.outcome = "win"
	_force_into_hand(engine, "GAIN3")

	assert_false(engine.play_card("GAIN3")["ok"])
	assert_false(engine.end_turn()["ok"])


# ---------------------------------------------------------------------------
# The TV debate, which is survived rather than won
# ---------------------------------------------------------------------------

func _tv_debate(overrides: Dictionary = {}) -> Dictionary:
	var stage := TestFixtures.stage({
		"stage_id": "ST06",
		"bar_max": 100, "win_threshold": 50, "turn_limit": 2,
		"player_start": 50, "opp_start": 50,
	})
	var base := {"stage": stage, "opponent": TestFixtures.opponent([["block", 1]])}
	base.merge(overrides, true)
	return base


func test_slipping_below_the_line_loses_the_tv_debate() -> void:
	var engine := _start(_tv_debate({"opponent": TestFixtures.opponent([["attack", 1]])}))
	engine.end_turn()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss")
	assert_string_contains(engine.state.outcome_reason, "below the line")


func test_staying_on_the_line_is_survivable() -> void:
	var engine := _start(_tv_debate())
	engine.end_turn()
	assert_false(engine.state.is_over(), "exactly on the threshold is not below it")


func test_surviving_to_the_end_wins_the_tv_debate() -> void:
	# The general turn-limit switch says "loss", but survival overrides it:
	# lasting the distance IS the win here.
	var engine := _start(_tv_debate({"rules": TestFixtures.rules({"turn_limit_outcome": "loss"})}))
	engine.end_turn()
	engine.end_turn()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win")
	assert_string_contains(engine.state.outcome_reason, "Survived")


# ---------------------------------------------------------------------------
# A committee battle, end to end
# ---------------------------------------------------------------------------

func _committee_battle() -> BattleEngine:
	return _start({
		"stage": TestFixtures.stage({
			"stage_id": "ST01", "mode": "Combat", "bar_unit": "Members",
			"bar_max": null, "win_threshold": null, "turn_limit": 6,
			"player_start": null, "opp_start": null, "gaffe_limit": 5,
		}),
		"opponent": TestFixtures.opponent([["lean_down", 8]]),
		"committee_members": [
			TestFixtures.committee_member("Member A"),
			TestFixtures.committee_member("Member B"),
			TestFixtures.committee_member("Member C"),
			TestFixtures.committee_member("Member D", "Against"),
		],
	})


func test_a_committee_stage_sets_up_member_tiles_instead_of_a_bar() -> void:
	var engine := _committee_battle()
	assert_true(engine.state.is_committee_stage())
	assert_null(engine.state.bar)
	assert_eq(engine.state.committee.size(), 4)
	assert_eq(engine.state.committee.majority_needed(), 3)


func test_a_committee_stage_needs_its_members() -> void:
	var engine := BattleEngine.new()
	assert_false(engine.setup(TestFixtures.battle_config({
		"stage": TestFixtures.stage({"stage_id": "ST01"}),
		"committee_members": [],
	})))
	assert_string_contains(engine.setup_problems[0], "members")


func test_a_card_moves_the_member_it_is_aimed_at() -> void:
	var engine := _committee_battle()
	_force_into_hand(engine, "GAIN3")

	engine.play_card("GAIN3", 0)
	assert_eq(engine.state.committee.members[0]["lean"], 53, "50 plus 3")
	assert_eq(engine.state.committee.members[1]["lean"], 50, "the others are untouched")


func test_both_halves_of_a_cards_persuasion_go_into_one_member() -> void:
	# In a committee there is no separate opponent bar, so "gain 3, opponent
	# -3" is six points of persuasion aimed at one person.
	var engine := _start({
		"stage": TestFixtures.stage({"stage_id": "ST01", "turn_limit": 6}),
		"opponent": TestFixtures.opponent([["lean_down", 8]]),
		"committee_members": [
			TestFixtures.committee_member("A"), TestFixtures.committee_member("B"),
			TestFixtures.committee_member("C"),
		],
		"cards": {"BOTH": TestFixtures.card({
			"card_id": "BOTH", "self_plus": 3, "opp_minus": 3, "cost": 1,
		})},
		"deck": ["BOTH", "BOTH"],
	})
	_force_into_hand(engine, "BOTH")

	engine.play_card("BOTH", 0)
	assert_eq(engine.state.committee.members[0]["lean"], 56)


func test_the_chair_pushes_a_member_back_at_the_end_of_the_turn() -> void:
	var engine := _committee_battle()
	_force_into_hand(engine, "GAIN3")
	engine.play_card("GAIN3", 0)   # Member A to 53, the highest in play

	engine.end_turn()
	assert_eq(engine.state.committee.members[0]["lean"], 45, "53 minus the chair's 8")


func test_locking_a_majority_wins_the_committee() -> void:
	var engine := _committee_battle()
	engine.state.committee.persuade(0, 20)
	engine.state.committee.persuade(1, 20)
	_force_into_hand(engine, "GAIN3")

	# The third member is at 50; 16 more locks them. Push them over directly,
	# then play a card so the engine re-checks the outcome.
	engine.state.committee.persuade(2, 13)
	engine.play_card("GAIN3", 2)

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win")


func test_losing_a_reachable_majority_ends_the_stage() -> void:
	var engine := _committee_battle()
	_force_into_hand(engine, "GAIN3")

	# One member is already Against. Lose a second and three For is gone.
	engine.state.committee.persuade(0, -20)
	engine.play_card("GAIN3", 1)

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss")
	assert_string_contains(engine.state.outcome_reason, "no longer possible")
