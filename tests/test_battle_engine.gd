extends GutTest
## Tests for the battle engine: the turn loop, block, gaffes, the deck, and
## every way a stage can end.


## A few lines of our own, for the checks that need to see a sentence
## ASSEMBLED rather than just to know which ending was reached.
##
## Deliberately not the workbook's wording: these tests are about the engine
## putting the right number and the right unit into the right sentence, and
## pinning Cameron's phrasing here would mean a reword of his broke the
## suite. Everywhere else the fixtures pass no table at all, so a reason
## comes back as its key and the check reads as "which ending was this".
const CLOSING_WORDS := {
	"outcome.reason.closed_on": "{stage} closed on {closing}.",
	"outcome.reason.percent_of_room": "{count} per cent",
	"outcome.reason.amount_of_unit": "{count} {unit}",
}


func _start_with_words(overrides: Dictionary = {}) -> BattleEngine:
	var config := TestFixtures.battle_config(overrides)
	config["strings"] = CLOSING_WORDS
	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "setup failed: %s" % [engine.setup_problems])
	return engine


func _start(overrides: Dictionary = {}) -> BattleEngine:
	var engine := BattleEngine.new()
	var ready := engine.setup(TestFixtures.battle_config(overrides))
	assert_true(ready, "setup failed: %s" % [engine.setup_problems])
	return engine


## Puts a specific card in hand, so a test doesn't depend on the shuffle.
func _force_into_hand(engine: BattleEngine, card_id: String) -> void:
	if not engine.state.hand.has(card_id):
		engine.state.hand.append(card_id)


## The usual card table with one more card in it.
func _cards_with(card: Dictionary) -> Dictionary:
	var cards: Dictionary = TestFixtures.battle_config()["cards"]
	cards[str(card["card_id"])] = card
	return cards


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


func test_guard_is_spent_by_what_it_stops_not_by_the_clock() -> void:
	# It used to be wiped at the end of every turn whether or not it had been
	# needed. Now only an attack takes it — here the opponent's 5 takes all 5.
	var engine := _start()
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")
	engine.end_turn()

	assert_eq(engine.state.block, 0, "their attack of 5 took the whole bank")


func test_unspent_energy_does_not_carry_over() -> void:
	var engine := _start()
	_force_into_hand(engine, "GAIN3")
	engine.play_card("GAIN3")        # so the turn is not a pass
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
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.gaffe_limit")


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
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.time_")


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
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.fell_below")


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
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.survived")


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
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.committee_against")


# ---------------------------------------------------------------------------
# The caucus: one pool of energy, and a score rather than a win
# ---------------------------------------------------------------------------
# Two rules that only the caucus uses. Energy is handed out once for the
# whole stage instead of each turn, so spending it is a budget rather than a
# rhythm; and there is no threshold to cross, so how high the support gets
# IS the result.

func _caucus(overrides: Dictionary = {}) -> Dictionary:
	var stage := TestFixtures.stage({
		"stage_id": "PT_S3",
		"energy_mode": "pool",
		"energy_pool": 5,
		"win_mode": "score",
		"turn_limit": 3,
		"bar_max": 100,
		"player_start": 40,
		"opp_start": 40,
	})
	stage.erase("win_threshold")
	var base := {"stage": stage, "opponent": TestFixtures.opponent([["block", 1]])}
	base.merge(overrides, true)
	return base


func test_a_pool_stage_starts_with_the_whole_pool() -> void:
	var engine := _start(_caucus())
	assert_eq(engine.state.energy, 5, "all five at once, not three a turn")


func test_pool_energy_is_not_refilled_between_turns() -> void:
	# The whole point: spend it when you like, and when it is gone the
	# remaining turns are empty.
	var engine := _start(_caucus())
	_force_into_hand(engine, "GAIN3")
	engine.play_card("GAIN3")        # so the turn is not a pass
	engine.state.energy = 2

	engine.end_turn()
	assert_eq(engine.state.energy, 2, "what was left is what you still have")


func test_a_spent_pool_stays_spent() -> void:
	var engine := _start(_caucus())
	engine.state.energy = 0
	_force_into_hand(engine, "GAIN3")

	engine.end_turn()
	assert_eq(engine.state.energy, 0)
	assert_false(engine.play_card("GAIN3")["ok"], "nothing can be played with an empty pool")


func test_ordinary_stages_still_refill_every_turn() -> void:
	# The pool must not leak into every other stage.
	var engine := _start()
	_force_into_hand(engine, "GAIN3")
	engine.play_card("GAIN3")        # so the turn is not a pass
	engine.state.energy = 0

	engine.end_turn()
	assert_eq(engine.state.energy, 3, "a normal stage refills")


func test_a_scored_stage_does_not_end_early_on_support() -> void:
	# Crossing some support total must not cut the stage short: the player is
	# trying to get as high as possible in the turns they have.
	var engine := _start(_caucus())
	engine.state.bar.player_gains(55)   # far past any ordinary threshold

	assert_false(engine.state.is_over(), "there is no threshold to cross")


func test_a_scored_stage_completes_at_the_turn_limit() -> void:
	var engine := _start(_caucus())
	for _index in 3:
		engine.end_turn()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win", "running out of turns is how it ends, not a loss")


func test_the_score_is_the_support_reached() -> void:
	var engine := _start(_caucus())
	engine.state.bar.player_gains(12)   # 40 -> 52
	for _index in 3:
		engine.end_turn()

	assert_eq(engine.state.player_score(), 52)
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.closed_on")


func test_a_scored_stage_can_still_be_lost_on_gaffes() -> void:
	# Scored does not mean consequence-free.
	var engine := _start(_caucus({"deck": ["GAFFE2", "GAFFE2", "GAFFE2"]}))
	engine.state.gaffe = engine.state.gaffe_limit - 1
	_force_into_hand(engine, "GAFFE2")

	engine.play_card("GAFFE2")
	assert_eq(engine.state.outcome, "loss")
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.gaffe_limit")


func test_the_turn_limit_switch_does_not_override_a_scored_stage() -> void:
	# Whatever rules.json says about running out of turns, a scored stage
	# ends by being scored.
	var engine := _start(_caucus({
		"rules": TestFixtures.rules({"turn_limit_outcome": "loss"}),
	}))
	for _index in 3:
		engine.end_turn()

	assert_eq(engine.state.outcome, "win")


# ---------------------------------------------------------------------------
# Several opponents in one stage
# ---------------------------------------------------------------------------
# Two shapes, and the difference matters.
#
#   "reset"       the committee. Three separate arguments. Beat one and
#                 everything starts fresh against the next.
#   "continuous"  the floor debate. Five opponents sharing one seat count
#                 and one clock. Beat one and the next inherits the room.

func _three_in_a_row(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"stage": TestFixtures.stage({
			"stage_id": "PT_S1",
			"sequence_mode": "reset",
			"bar_max": 100, "win_threshold": 60,
			"player_start": 40, "opp_start": 40,
			"turn_limit": 6, "gaffe_limit": 5,
		}),
		"opponents": [
			{"opp_id": "A", "name": "First", "intent_pattern": [["block", 1]]},
			{"opp_id": "B", "name": "Second", "intent_pattern": [["block", 1]]},
			{"opp_id": "C", "name": "Third", "intent_pattern": [["block", 1]]},
		],
	}
	base.merge(overrides, true)
	return base


func test_a_sequenced_stage_starts_against_the_first_opponent() -> void:
	var engine := _start(_three_in_a_row())
	assert_eq(engine.current_opponent()["name"], "First")
	assert_eq(engine.state.opponent_index, 0)
	assert_eq(engine.state.opponent_count, 3)


func test_beating_one_opponent_brings_on_the_next() -> void:
	var engine := _start(_three_in_a_row())
	engine.state.bar.player_gains(20)      # 40 -> 60, the threshold
	engine._check_outcome()

	assert_false(engine.state.is_over(), "the stage is not over, only the bout")
	assert_eq(engine.current_opponent()["name"], "Second")
	assert_eq(engine.state.opponent_index, 1)


func test_everything_resets_between_bouts() -> void:
	var engine := _start(_three_in_a_row())
	engine.state.gaffe = 3
	engine.state.block = 7
	engine.state.energy = 0
	engine.state.turn = 4
	engine.state.bar.player_gains(20)
	engine._check_outcome()

	assert_eq(engine.state.gaffe, 0, "gaffes are forgotten")
	assert_eq(engine.state.block, 0, "guard is gone")
	assert_eq(engine.state.energy, 3, "a fresh turn's energy")
	assert_eq(engine.state.turn, 1, "the clock starts again")
	assert_eq(engine.state.bar.player, 40, "support starts level again")
	assert_eq(engine.state.bar.opponent, 40)
	assert_eq(engine.state.hand.size(), 5, "and a fresh hand")


func test_beating_the_last_opponent_wins_the_stage() -> void:
	var engine := _start(_three_in_a_row())

	for bout in 3:
		assert_false(engine.state.is_over(), "still going after %d bout(s)" % bout)
		engine.state.bar.player_gains(20)
		engine._check_outcome()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win")
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.all_argued_down")


func test_losing_one_bout_loses_the_whole_stage() -> void:
	var engine := _start(_three_in_a_row())
	engine.state.gaffe = engine.state.gaffe_limit
	engine._check_outcome()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss", "there is no second chance at a bout")


func test_each_opponent_brings_their_own_pattern() -> void:
	var engine := _start(_three_in_a_row({
		"opponents": [
			{"opp_id": "A", "name": "First", "intent_pattern": [["attack", 3]]},
			{"opp_id": "B", "name": "Second", "intent_pattern": [["block", 9]]},
		],
	}))
	assert_eq(engine.current_intent(), {"verb": "attack", "value": 3})

	engine.state.bar.player_gains(20)
	engine._check_outcome()
	assert_eq(engine.current_intent(), {"verb": "block", "value": 9},
		"the new opponent argues their own way")


# --- the floor debate's shape ----------------------------------------------

func _five_on_the_floor(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"stage": TestFixtures.stage({
			"stage_id": "PT_S4",
			"sequence_mode": "continuous",
			"bar_max": 101, "win_threshold": 51,
			"player_start": 40, "opp_start": 40,
			"turn_limit": 20, "gaffe_limit": 6,
		}),
		"opponents": [
			{"opp_id": "F1", "name": "One", "intent_pattern": [["block", 1]]},
			{"opp_id": "F2", "name": "Two", "intent_pattern": [["block", 1]]},
		],
	}
	base.merge(overrides, true)
	return base


func test_arguing_an_opponent_down_to_nothing_brings_on_the_next() -> void:
	var engine := _start(_five_on_the_floor())
	engine.state.bar.opponent_loses(40)      # their seats all go
	engine._check_outcome()

	assert_false(engine.state.is_over())
	assert_eq(engine.current_opponent()["name"], "Two", "the next one steps in")


func test_a_new_debater_means_a_fresh_vote() -> void:
	# The difference from the committee: the house divides again, but YOU do
	# not get a fresh start. Your record and the clock follow you in.
	var engine := _start(_five_on_the_floor())
	engine.state.bar.player_gains(8)         # 40 -> 48
	engine.state.gaffe = 2
	engine.state.turn = 5
	engine.state.bar.opponent_loses(40)
	engine._check_outcome()

	assert_eq(engine.state.bar.player, 40, "the vote starts again for the new debater")
	assert_eq(engine.state.bar.opponent, 40, "and so does theirs")
	assert_eq(engine.state.gaffe, 2, "but your record is still your record")
	assert_eq(engine.state.turn, 5, "and the clock keeps running")
	assert_true(engine.state.bar.totals_balance(),
		"the house still adds up to %d" % engine.state.bar.maximum)


func test_your_hand_and_deck_follow_you_to_the_next_debater() -> void:
	# Unlike a committee bout, which deals you a clean deck.
	var engine := _start(_five_on_the_floor())
	engine.state.hand.assign(["GAIN3"])
	engine.state.discard.assign(["GUARD5", "ATTACK3"])

	engine.state.bar.opponent_loses(40)
	engine._check_outcome()

	assert_eq(engine.state.hand, ["GAIN3"] as Array[String], "the same hand")
	assert_eq(engine.state.discard.size(), 2, "and what you have already spent is still spent")


func test_the_threshold_ends_the_debater_not_the_stage() -> void:
	# The bug Cameron caught: reaching the number with four debaters still
	# waiting used to carry the bill on the spot.
	var engine := _start(_five_on_the_floor())
	engine.state.bar.player_gains(11)        # 40 -> 51, the threshold
	engine._check_outcome()

	assert_false(engine.state.is_over(), "there are four more people to get through")
	assert_eq(engine.current_opponent()["name"], "Two", "the next debater rises")


func test_beating_the_last_debater_at_the_threshold_carries_the_bill() -> void:
	var engine := _start(_five_on_the_floor())
	for _index in 2:
		engine.state.bar.player_gains(11)
		engine._check_outcome()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win")
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.all_argued_down")


func test_beating_the_last_opponent_without_a_majority_still_wins() -> void:
	var engine := _start(_five_on_the_floor())
	for _index in 2:
		engine.state.bar.opponent_loses(engine.state.bar.opponent)
		engine._check_outcome()

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "win", "there is nobody left to argue with")


# ---------------------------------------------------------------------------
# The press conference: a fixed hand, and one card per question
# ---------------------------------------------------------------------------
# Not a battle with turns so much as an interview. Six cards at the start and
# no more unless a card says otherwise. Each reporter's question takes one
# card to answer, and answering in the suit the question invites pleases the
# organisation behind it, which the floor debate later draws on.

func _press(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"stage": TestFixtures.stage({
			"stage_id": "PT_S2",
			"draw_mode": "none",
			"opening_hand": 6,
			"bar_max": 100, "win_threshold": 55,
			"player_start": 45, "opp_start": 45,
			"gaffe_limit": 4,
			"questions": [
				{"id": "Q1", "text": "First question.",
				 "prefers_suit": "Data Driven", "pleases_booster": "BO08"},
				{"id": "Q2", "text": "Second question.",
				 "prefers_suit": "Earnest", "pleases_booster": "BO03"},
			],
		}),
		"opponent": TestFixtures.opponent([["block", 1]]),
		"deck": ["GAIN3", "GAIN3", "ATTACK3", "GUARD5", "GAFFE2", "DRAW2",
				 "GAIN3", "ATTACK3"],
	}
	base.merge(overrides, true)
	return base


func test_a_press_conference_deals_its_opening_hand() -> void:
	var engine := _start(_press())
	assert_eq(engine.state.hand.size(), 6, "six, not the usual five")


func test_a_press_conference_never_deals_more() -> void:
	var engine := _start(_press())
	engine.state.hand.clear()

	engine.end_turn()
	assert_eq(engine.state.hand.size(), 0,
		"no top-up at the start of a turn: what you were dealt is what you have")


func test_a_card_that_draws_still_works_in_a_press_conference() -> void:
	# "You only draw if a card says so" - so cards must still be able to.
	var engine := _start(_press())
	engine.state.hand.assign(["DRAW2"])

	engine.play_card("DRAW2")
	assert_eq(engine.state.hand.size(), 2, "the card drew its two")


func test_ordinary_stages_still_deal_a_fresh_hand() -> void:
	var engine := _start()
	# Discarded rather than deleted: clearing the hand outright would destroy
	# the cards and leave nothing in the deck to top up from, which would
	# make this pass or fail for the wrong reason.
	engine.state.discard.assign(engine.state.discard + engine.state.hand)
	engine.state.hand.clear()

	engine.end_turn()
	assert_eq(engine.state.hand.size(), 5, "a normal stage tops up")


func test_the_first_question_is_waiting_at_the_start() -> void:
	var engine := _start(_press())
	assert_eq(engine.current_question()["id"], "Q1")
	assert_eq(engine.questions_remaining(), 2)


func test_answering_moves_on_to_the_next_question() -> void:
	var engine := _start(_press())
	engine.state.hand.assign(["GAIN3"])

	engine.play_card("GAIN3")
	assert_eq(engine.current_question()["id"], "Q2", "one card, one question")
	assert_eq(engine.questions_remaining(), 1)


func test_answering_in_the_suit_invited_pleases_that_organisation() -> void:
	# ATTACK3 is Data Driven, which is what the first question invites.
	var engine := _start(_press())
	engine.state.hand.assign(["ATTACK3"])

	engine.play_card("ATTACK3")
	assert_true(engine.pleased_boosters().has("BO08"),
		"the organisation behind that question is pleased")


func test_answering_in_the_wrong_suit_pleases_nobody() -> void:
	# GAIN3 is Earnest; the first question invites Data Driven.
	var engine := _start(_press())
	engine.state.hand.assign(["GAIN3"])

	engine.play_card("GAIN3")
	assert_eq(engine.pleased_boosters().size(), 0)


func test_running_out_of_questions_ends_the_conference() -> void:
	var engine := _start(_press())
	engine.state.hand.assign(["GAIN3", "GAIN3"])

	engine.play_card("GAIN3")
	assert_false(engine.state.is_over(), "one question left")

	engine.play_card("GAIN3")
	assert_true(engine.state.is_over(), "and now none")
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.concludes")


func test_running_out_of_cards_ends_the_conference_too() -> void:
	# With nothing left to answer with, there is no conference to continue.
	var engine := _start(_press())
	engine.state.hand.assign(["GAIN3"])
	engine.state.deck.clear()
	engine.state.discard.clear()

	engine.play_card("GAIN3")
	assert_true(engine.state.is_over())


func test_a_press_conference_can_still_be_lost_on_gaffes() -> void:
	var engine := _start(_press())
	engine.state.gaffe = engine.state.gaffe_limit - 1
	engine.state.hand.assign(["GAFFE2"])

	engine.play_card("GAFFE2")
	assert_eq(engine.state.outcome, "loss")


# --- with nobody sitting opposite ------------------------------------------
# The real press conference has no opponent at all: the reporters' questions
# are the whole of the opposition. Everything above still has to hold when
# there is nobody there to take a turn.

func _press_alone(overrides: Dictionary = {}) -> Dictionary:
	var base := _press({"opponent": {}, "opponents": []})
	base.merge(overrides, true)
	return base


func test_a_press_conference_starts_with_nobody_opposite() -> void:
	var engine := BattleEngine.new()
	var ok := engine.setup(TestFixtures.battle_config(_press_alone()))

	assert_true(ok, "a conference with no opponent is not a broken stage")
	assert_eq(Array(engine.setup_problems), [], "and it complains about nothing")
	assert_eq(engine.state.opponent_count, 0)


func test_any_other_stage_still_needs_somebody_to_argue_with() -> void:
	# The empty-opponent case is allowed only because the questions replace
	# them. A stage with neither is still a mistake.
	var engine := BattleEngine.new()
	var config := TestFixtures.battle_config(_press_alone())
	(config["stage"] as Dictionary).erase("questions")

	assert_false(engine.setup(config))


func test_ending_a_turn_with_nobody_opposite_is_not_an_attack() -> void:
	# Nobody is sitting there to act. The tone still falls, but that is the
	# cost of declining the question — not somebody taking a swing at you.
	var config := _press_alone()
	(config["stage"] as Dictionary)["decline_tone_cost"] = 0
	var engine := _start(config)
	var before := engine.state.bar.player

	var result := engine.end_turn()

	assert_true(result.get("ok", false), "the turn ends rather than crashing")
	assert_eq(str(result["intent"]["verb"]), "none", "nobody acted")
	assert_eq(engine.state.bar.player, before, "so nothing was taken off you")


func test_ending_a_turn_keeps_the_hand_you_cannot_replace() -> void:
	# The usual rule throws the rest of the hand away at the end of a turn.
	# In a conference that never draws, that would end it on the spot.
	var engine := _start(_press_alone())
	var held := engine.state.hand.size()

	engine.end_turn()
	assert_eq(engine.state.hand.size(), held, "every card is still in hand")
	assert_false(engine.state.is_over(), "so the conference carries on")


func test_ending_a_turn_refills_the_energy() -> void:
	var engine := _start(_press_alone())
	engine.state.hand.assign(["GAIN3", "GAIN3"])
	engine.play_card("GAIN3")        # answered, so the turn is not a pass
	engine.state.energy = 0

	engine.end_turn()
	assert_eq(engine.state.energy, engine.state.energy_per_turn,
		"otherwise a hand you cannot afford to play is a dead end")


func test_good_press_tone_does_not_cut_the_questions_short() -> void:
	# Walking out early because the tone happened to be good would skip the
	# questions still to come, and the answers are the point of the stage.
	var engine := _start(_press_alone())
	engine.state.bar.player = engine.state.bar.threshold + 10

	engine.end_turn()
	assert_false(engine.state.is_over(), "the reporters are not finished")


func test_the_press_tone_is_a_single_bar() -> void:
	# Not a shared pool: there is no opposing side holding the rest of it.
	var engine := _start(_press_alone())
	assert_eq(engine.state.bar.model, BarModel.Model.SINGLE)


# ---------------------------------------------------------------------------
# Passing: a turn spent saying nothing
# ---------------------------------------------------------------------------
# Standing up and declining to argue is a real choice, sometimes the right
# one, but it should never be the free one — or the best play in a tight spot
# would be to keep quiet and let the clock run.

func test_ending_a_turn_having_played_nothing_costs_you_energy() -> void:
	var engine := _start()

	var result := engine.end_turn()
	assert_true(result["passed"], "the turn was a pass")
	assert_eq(engine.state.energy, 2, "next turn is one short")


func test_playing_anything_at_all_avoids_the_penalty() -> void:
	var engine := _start()
	_force_into_hand(engine, "GAIN3")
	engine.play_card("GAIN3")

	var result := engine.end_turn()
	assert_false(result["passed"])
	assert_eq(engine.state.energy, 3, "a full allowance")


func test_a_free_card_still_counts_as_saying_something() -> void:
	# The count is of cards played, not energy spent — a card can cost
	# nothing, and a pool stage can leave energy unspent quite legitimately.
	var engine := _start({"cards": _cards_with(
		TestFixtures.card({"card_id": "FREE", "cost": 0, "self_plus": 1}))})
	_force_into_hand(engine, "FREE")
	engine.play_card("FREE")

	assert_false(engine.end_turn()["passed"])
	assert_eq(engine.state.energy, 3)


func test_the_penalty_does_not_follow_you_into_the_turn_after() -> void:
	var engine := _start()
	engine.end_turn()                        # passed: next turn is short
	assert_eq(engine.state.energy, 2)

	_force_into_hand(engine, "GAIN3")
	engine.play_card("GAIN3")
	engine.end_turn()
	assert_eq(engine.state.energy, 3, "one quiet turn is not a running debt")


func test_passing_twice_is_short_twice() -> void:
	var engine := _start()
	engine.end_turn()
	assert_eq(engine.state.energy, 2)
	engine.end_turn()
	assert_eq(engine.state.energy, 2, "short again, not shorter")


func test_the_penalty_cannot_take_energy_below_nothing() -> void:
	var engine := _start({
		"stage": TestFixtures.stage({"energy_per_turn": 1}),
		"rules": TestFixtures.rules({"pass_energy_penalty": 5}),
	})

	engine.end_turn()
	assert_eq(engine.state.energy, 0, "nothing, rather than a negative allowance")


func test_a_pool_stage_pays_out_of_the_pool() -> void:
	# There is no refill in a caucus to take the energy off, so it comes out
	# of what is left straight away. That makes passing a permanent cut
	# rather than a lost turn, which is the only version that bites there.
	var engine := _start(_caucus())
	assert_eq(engine.state.energy, 5)

	engine.end_turn()
	assert_eq(engine.state.energy, 4, "one off the pool, and it does not come back")


func test_the_penalty_can_be_switched_off() -> void:
	var engine := _start({"rules": TestFixtures.rules({"pass_energy_penalty": 0})})

	engine.end_turn()
	assert_eq(engine.state.energy, 3, "passing is free when Cameron says it is")


func test_passing_declines_the_question_in_front_of_you() -> void:
	# In a press conference the round IS the question, and every card you
	# could play would answer it — so passing is the only way to duck one.
	var engine := _start(_press_alone())
	var asked := engine.questions_remaining()
	var pleased := engine.pleased_boosters().size()

	engine.end_turn()

	assert_eq(engine.questions_remaining(), asked - 1, "the next reporter speaks")
	assert_eq(engine.pleased_boosters().size(), pleased, "and nobody was pleased by silence")


func test_answering_a_question_is_not_passing() -> void:
	var engine := _start(_press_alone())
	engine.state.hand.assign(["GAIN3", "GAIN3"])

	engine.play_card("GAIN3")
	assert_false(engine.end_turn()["passed"])


func test_the_last_question_cannot_be_declined_twice() -> void:
	# Passing after the reporters have finished must not push the index past
	# the end of the list.
	var engine := _start(_press_alone())
	engine.state.question_index = engine.questions_remaining() + engine.state.question_index

	engine.end_turn()
	assert_eq(engine.questions_remaining(), 0)


# ---------------------------------------------------------------------------
# Guard, as a bank
# ---------------------------------------------------------------------------
# Not a shield that has to be up at the right moment: a bank that stacks to a
# cap, stays until something takes it, and is the first thing spent when
# either side is attacked.

func test_guard_is_still_there_next_turn() -> void:
	# An opponent who guards rather than attacks, so nothing takes it.
	var engine := _start({"opponent": TestFixtures.opponent([["block", 1]])})
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")

	engine.end_turn()
	assert_eq(engine.state.block, 5, "a quiet turn spent guarding is not wasted")


func test_guard_stacks_up_to_the_cap() -> void:
	var engine := _start()
	engine.state.guard_cap = 5

	_force_into_hand(engine, "GUARD5")
	var first := engine.play_card("GUARD5")
	assert_eq(first["applied"]["guard"], 5)

	_force_into_hand(engine, "GUARD5")
	var second := engine.play_card("GUARD5")
	assert_eq(engine.state.block, 5, "held at the cap")
	assert_eq(second["applied"]["guard"], 0,
		"and it reports what actually fitted, not what the card said")


func test_an_attack_spends_the_guard_it_meets() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["attack", 3]])})
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")

	var turn := engine.end_turn()
	assert_eq(turn["opponent"]["damage"], 0, "fully absorbed")
	assert_eq(engine.state.block, 2, "and three of the five were spent doing it")


func test_the_opponents_guard_stops_the_player() -> void:
	# The half that never worked: their "Guarding" intent was decoration.
	var engine := _start({"opponent": TestFixtures.opponent([["block", 4]])})
	engine.end_turn()                      # they guard 4
	assert_eq(engine.state.opponent_block, 4)

	_force_into_hand(engine, "ATTACK3")
	var result := engine.play_card("ATTACK3")

	assert_eq(int(result["applied"]["guard_stopped"]), 3, "their guard took it all")
	assert_eq(int(result["applied"]["opponent_lost"]), 0, "so none of their people moved")
	assert_eq(engine.state.opponent_block, 1, "and three of their four were spent")


func test_an_attack_bigger_than_their_guard_gets_through() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["block", 1]])})
	engine.end_turn()

	_force_into_hand(engine, "ATTACK3")
	var result := engine.play_card("ATTACK3")

	assert_eq(int(result["applied"]["guard_stopped"]), 1)
	assert_gt(int(result["applied"]["opponent_lost"]), 0, "the rest landed")
	assert_eq(engine.state.opponent_block, 0, "their guard is spent")


func test_the_opponents_guard_also_stacks_to_the_cap() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["block", 4]])})
	engine.state.guard_cap = 5

	engine.end_turn()
	engine.end_turn()
	assert_eq(engine.state.opponent_block, 5, "4 then 4 again, held at 5")


func test_a_new_committee_bout_clears_both_banks() -> void:
	# Beating somebody should not leave you holding their guard, or yours.
	var engine := _start({
		"stage": TestFixtures.stage({
			"stage_id": "PT_S1", "sequence_mode": "reset", "win_threshold": 45,
		}),
		"opponents": [
			{"opp_id": "A", "name": "A", "intent_pattern": [["block", 1]]},
			{"opp_id": "B", "name": "B", "intent_pattern": [["block", 1]]},
		],
	})
	engine.state.block = 5
	engine.state.opponent_block = 5
	engine.state.bar.player = 45
	engine._check_outcome()

	assert_eq(engine.state.opponent_index, 1, "the next one stepped up")
	assert_eq(engine.state.block, 0)
	assert_eq(engine.state.opponent_block, 0)


func test_the_guard_cap_comes_from_the_rules_file() -> void:
	var engine := _start({"rules": TestFixtures.rules({"guard_cap": 2})})
	_force_into_hand(engine, "GUARD5")
	engine.play_card("GUARD5")

	assert_eq(engine.state.block, 2, "Cameron's number, not a number in the code")


# ---------------------------------------------------------------------------
# Declining a reporter's question
# ---------------------------------------------------------------------------
# Energy is nearly worthless in a press conference, so the ordinary pass cost
# meant a player could duck every awkward question and walk out with the tone
# untouched and a clean record. A playtest found exactly that.

func test_declining_cools_the_room() -> void:
	var config := _press_alone()
	(config["stage"] as Dictionary)["decline_tone_cost"] = 3
	var engine := _start(config)
	var tone := engine.state.bar.player

	engine.end_turn()
	assert_eq(engine.state.bar.player, tone - 3, "silence costs you the room")
	assert_eq(engine.state.declined_questions, 1)


func test_declining_pleases_nobody() -> void:
	var engine := _start(_press_alone())
	engine.end_turn()
	assert_true(engine.pleased_boosters().is_empty(),
		"the organisation that asked is not pleased by silence")


func test_ducking_every_question_is_no_longer_free() -> void:
	# The exploit, in one test: five questions declined used to finish with
	# the tone exactly where it started.
	var config := _press_alone()
	(config["stage"] as Dictionary)["decline_tone_cost"] = 3
	var engine := _start(config)
	var tone := engine.state.bar.player

	var guard := 0
	while not engine.state.is_over() and guard < 12:
		guard += 1
		engine.end_turn()

	assert_true(engine.state.is_over())
	assert_lt(engine.state.bar.player, tone, "the room is colder than it started")
	assert_gt(engine.state.declined_questions, 0)


func test_the_closing_line_says_the_conference_concluded() -> void:
	# One question a turn now, so answering both takes two turns. A second
	# card in the same turn plays, but no reporter is waiting for it.
	var engine := _start(_press_alone())
	engine.state.hand.assign(["GAIN3", "GAIN3", "GAIN3"])
	engine.play_card("GAIN3")
	engine.end_turn()
	engine.play_card("GAIN3")

	assert_true(engine.state.is_over())
	# Named from the stage: a study session and a lobbyist meeting also run
	# on questions and neither of them is a press conference.
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.concludes")


func test_the_closing_line_counts_what_went_unanswered() -> void:
	var engine := _start(_press_alone())
	engine.end_turn()                    # one declined
	engine.state.hand.assign(["GAIN3", "GAIN3"])
	engine.play_card("GAIN3")            # the last one answered

	assert_true(engine.state.is_over())
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.unanswered")


func test_the_decline_cost_can_be_switched_off() -> void:
	var config := _press_alone()
	(config["stage"] as Dictionary)["decline_tone_cost"] = 0
	var engine := _start(config)
	var tone := engine.state.bar.player

	engine.end_turn()
	assert_eq(engine.state.bar.player, tone, "free when Cameron says it is free")
	assert_eq(engine.state.declined_questions, 1, "but still recorded")


# ---------------------------------------------------------------------------
# What a card will actually do here
# ---------------------------------------------------------------------------
# The printed number is not the outcome: affinity moves the support numbers,
# and in some rooms a number does nothing at all. A playtest reported this as
# a card not working, which is what happens when a screen shows a promise the
# rules do not keep.

func test_the_preview_shows_the_room_not_the_card() -> void:
	# ATTACK3 is Data Driven, worth 1.1 on the floor: 3 x 1.1 = 3.3 -> 3.
	var engine := _start()
	var effect := engine.preview(TestFixtures.card({
		"card_id": "BIG", "self_plus": 10, "suit": "Data Driven",
	}))
	assert_eq(int(effect["self_plus"]), 11, "ten becomes eleven in this room")


func test_a_card_that_does_nothing_here_says_so() -> void:
	# An attack in a press conference: there is nobody whose support it
	# reduces, so every number on the card is inert.
	var engine := _start(_press_alone())
	var effect := engine.preview(TestFixtures.card({
		"card_id": "ATK", "opp_minus": 4,
	}))

	assert_false(bool(effect["opp_minus_counts"]), "nobody to reduce")
	assert_true(bool(effect["does_nothing"]))


func test_a_guard_card_does_nothing_where_nobody_attacks() -> void:
	var engine := _start(_press_alone())
	var effect := engine.preview(TestFixtures.card({"card_id": "G", "guard": 5}))

	assert_false(bool(effect["guard_counts"]), "no reporter takes a swing at you")
	assert_true(bool(effect["does_nothing"]))


func test_a_card_that_still_works_is_not_marked_useless() -> void:
	var engine := _start(_press_alone())
	var effect := engine.preview(TestFixtures.card({
		"card_id": "MIX", "self_plus": 3, "opp_minus": 4,
	}))

	assert_false(bool(effect["does_nothing"]), "the gain still counts")
	assert_false(bool(effect["opp_minus_counts"]), "even though half of it does not")


func test_everything_counts_in_an_ordinary_battle() -> void:
	var engine := _start()
	var effect := engine.preview(TestFixtures.card({
		"card_id": "MIX", "self_plus": 3, "opp_minus": 4, "guard": 2,
	}))

	assert_true(bool(effect["opp_minus_counts"]))
	assert_true(bool(effect["guard_counts"]))
	assert_false(bool(effect["does_nothing"]))


func test_a_card_that_only_gaffes_is_not_called_useless() -> void:
	# It does something — something bad. Calling it useless produced a card
	# reading "Gaffe +1. Nothing this card does counts in this room.", which
	# contradicts itself and hides a real cost behind a dimmed face.
	var engine := _start()
	var effect := engine.preview(TestFixtures.card({"card_id": "OOPS", "gaffe": 2}))
	assert_false(bool(effect["does_nothing"]),
		"doing something bad is still doing something")


# ---------------------------------------------------------------------------
# Telling the screen what changed underneath the player
# ---------------------------------------------------------------------------
# A card that finishes a debater changes the whole room, and the screen only
# found out by noticing the name had changed. Cameron read the resulting
# sentence — "3 seats won over — 1 point short" — as a failure, when in fact
# he had just beaten opponent four.

func test_a_card_that_finishes_a_debater_says_so() -> void:
	var engine := _start(_five_on_the_floor())
	engine.state.bar.player = 50          # one short of the 51 threshold
	engine.state.bar.undecided = 11
	engine.state.hand = ["GAIN3"]
	engine.state.energy = 3

	var result := engine.play_card("GAIN3")

	assert_true(result.has("bout_won"), "the card ended the bout; the screen has to know")
	assert_eq(result["bout_won"]["finished"], "One")
	assert_eq(result["bout_won"]["next"], "Two", "and who rises in their place")
	assert_eq(result["bout_won"]["remaining"], 1)


func test_a_card_that_does_not_finish_a_debater_reports_no_bout() -> void:
	var engine := _start(_five_on_the_floor())
	engine.state.hand = ["GAIN3"]
	engine.state.energy = 3

	var result := engine.play_card("GAIN3")
	assert_false(result.has("bout_won"))


func test_ending_a_turn_reports_a_bout_finished_by_the_clock() -> void:
	var engine := _start(_five_on_the_floor())
	engine.state.bar.opponent_loses(40)   # nobody left on their benches

	var result := engine.end_turn()
	assert_eq(result["bout_won"]["finished"], "One")


# ---------------------------------------------------------------------------
# What a card will cost you, before you spend it
# ---------------------------------------------------------------------------

func test_a_preview_says_a_card_will_answer_the_question() -> void:
	# Every card answers, including one whose numbers do nothing here. A
	# draw-1 card was spent in a playtest on the assumption it was free.
	var engine := _start(_press())
	var effect := engine.preview(TestFixtures.card({"card_id": "D1", "draw": 1}))
	assert_true(bool(effect["answers_question"]))


func test_a_preview_outside_a_press_conference_answers_nothing() -> void:
	var engine := _start()
	var effect := engine.preview(TestFixtures.card({"card_id": "D1", "draw": 1}))
	assert_false(bool(effect["answers_question"]))


func test_the_last_question_answered_leaves_nothing_to_answer() -> void:
	var engine := _start(_press())
	while not engine.current_question().is_empty():
		engine.state.question_index += 1

	var effect := engine.preview(TestFixtures.card({"card_id": "D1", "draw": 1}))
	assert_false(bool(effect["answers_question"]))


func test_a_card_records_who_it_won_over() -> void:
	var engine := _start()
	engine.state.hand = ["GAIN3"]
	engine.state.energy = 3

	var result := engine.play_card("GAIN3")
	var split: Dictionary = result["applied"]["gain_split"]

	assert_true(split.has("from_undecided"), "the screen needs the breakdown, not just a total")
	assert_true(split.has("from_other_side"))


# ---------------------------------------------------------------------------
# The four specials the 2026-09-21 card slate introduced
# ---------------------------------------------------------------------------

func test_piercing_ignores_guard_without_spending_it() -> void:
	# The distinction that matters: a pierced guard is bypassed, not removed.
	# Subtracting it for real would let one card strip protection it never
	# claimed to take.
	var engine := _start({"opponent": TestFixtures.opponent([["block", 1]])})
	engine.state.opponent_block = 5

	var card := TestFixtures.card({
		"card_id": "PIERCE", "opp_minus": 4,
		"special": "pierce_guard", "special_value": 3,
	})
	engine._cards["PIERCE"] = card
	engine.state.hand = ["PIERCE"]
	engine.state.energy = 3

	var result := engine.play_card("PIERCE")
	var applied: Dictionary = result["applied"]

	assert_eq(applied["guard_pierced"], 3, "three of the five were ignored")
	assert_eq(applied["guard_stopped"], 2, "the other two still stopped what they could")
	assert_eq(applied["opponent_lost"], 2, "so two of the four got through")
	assert_eq(engine.state.opponent_block, 3,
		"the pierced three are still theirs; only the two that worked were spent")


func test_piercing_more_than_they_have_is_not_a_bonus() -> void:
	var engine := _start({"opponent": TestFixtures.opponent([["block", 1]])})
	engine.state.opponent_block = 1

	var card := TestFixtures.card({
		"card_id": "PIERCE", "opp_minus": 3,
		"special": "pierce_guard", "special_value": 9,
	})
	engine._cards["PIERCE"] = card
	engine.state.hand = ["PIERCE"]
	engine.state.energy = 3

	var result := engine.play_card("PIERCE")
	assert_eq(result["applied"]["guard_pierced"], 1, "you cannot pierce guard they do not have")
	assert_eq(result["applied"]["opponent_lost"], 3, "and the whole attack lands")


func test_a_clean_record_pays_off() -> void:
	var engine := _start()
	var card := TestFixtures.card({
		"card_id": "CLEAN", "self_plus": 5,
		"special": "bonus_if_self_gaffe_0", "special_value": 2,
	})

	engine.state.gaffe = 0
	assert_eq(engine.preview(card)["self_plus"], 7, "5 plus the 2 for a clean record")

	engine.state.gaffe = 1
	assert_eq(engine.preview(card)["self_plus"], 5, "one slip and the bonus is gone")


func test_trailing_the_opponent_pays_off() -> void:
	var engine := _start()
	var card := TestFixtures.card({
		"card_id": "BEHIND", "self_plus": 3,
		"special": "bonus_if_behind", "special_value": 3,
	})

	engine.state.bar.player = 30
	engine.state.bar.opponent = 50
	assert_eq(engine.preview(card)["self_plus"], 6, "behind, so the comeback fires")

	engine.state.bar.player = 50
	engine.state.bar.opponent = 50
	assert_eq(engine.preview(card)["self_plus"], 3,
		"level pegging is not behind — a comeback card that fires when even fires nearly always")

	engine.state.bar.player = 60
	assert_eq(engine.preview(card)["self_plus"], 3, "and ahead is certainly not behind")


func test_a_discount_makes_the_next_card_cheaper() -> void:
	var engine := _start()
	var opener := TestFixtures.card({
		"card_id": "QUIET", "cost": 1, "self_plus": 2,
		"special": "discount_next_card_this_turn", "special_value": 1,
	})
	engine._cards["QUIET"] = opener
	engine.state.hand = ["QUIET", "GAIN3"]
	engine.state.energy = 3

	engine.play_card("QUIET")
	assert_eq(engine.state.next_card_discount, 1)
	assert_eq(engine.card_cost(engine._cards["GAIN3"]), 0,
		"a cost-1 card is free while the discount is up")

	engine.play_card("GAIN3")
	assert_eq(engine.state.next_card_discount, 0, "and the discount is spent by the card using it")


func test_a_discount_cannot_pay_you_to_play() -> void:
	var engine := _start()
	engine.state.next_card_discount = 5
	var card := TestFixtures.card({"card_id": "FREE2", "cost": 1})
	assert_eq(engine.card_cost(card), 0, "floored at nothing, never negative")


func test_a_discount_does_not_survive_the_turn() -> void:
	var engine := _start()
	engine.state.next_card_discount = 1
	engine.end_turn()
	assert_eq(engine.state.next_card_discount, 0)


# ---------------------------------------------------------------------------
# The stage levers Cameron's Levels Design Scheme introduced
# ---------------------------------------------------------------------------

func _questions_stage(overrides: Dictionary = {}) -> Dictionary:
	var base := _press_alone()
	var stage: Dictionary = (base["stage"] as Dictionary).duplicate(true)
	stage.merge(overrides, true)
	base["stage"] = stage
	return base


func test_a_turn_presents_one_question_however_many_cards_you_play() -> void:
	# Before this, three energy could burn through three reporters in a
	# single turn. A conference is paced by the room, not by your hand.
	var engine := _start(_questions_stage({"questions_per_turn": 1}))
	var before := engine.questions_remaining()

	engine.state.hand.assign(["GAIN3", "GAIN3"])
	engine.state.energy = 3
	engine.play_card("GAIN3")
	engine.play_card("GAIN3")

	assert_eq(engine.questions_remaining(), before - 1,
		"the second card played, but no reporter was waiting for it")


func test_a_study_session_asks_two_a_turn() -> void:
	var engine := _start(_questions_stage({"questions_per_turn": 2}))
	var before := engine.questions_remaining()

	engine.state.hand.assign(["GAIN3", "GAIN3"])
	engine.state.energy = 3
	engine.play_card("GAIN3")
	engine.play_card("GAIN3")

	assert_eq(engine.questions_remaining(), before - 2)


func test_a_question_left_hanging_at_the_end_of_a_turn_is_declined() -> void:
	# Playing a card that is not an answer must not be a way to duck a
	# reporter for free now that a turn can hold more cards than questions.
	var engine := _start(_questions_stage({
		"questions_per_turn": 2, "decline_tone_cost": 3,
	}))
	# A card held back: a conference ends the moment the player has nothing
	# left to say, and this one is not finished.
	engine.state.hand.assign(["GAIN3", "GUARD5"])
	engine.state.energy = 1

	engine.play_card("GAIN3")        # answers the first of the turn's two
	engine.end_turn()

	assert_eq(engine.state.declined_questions, 1, "the second went unanswered")


func test_a_gaffe_costs_double_in_an_ambush() -> void:
	var engine := _start(_questions_stage({"gaffe_multiplier": 2}))
	engine.state.hand.assign(["GAFFE2"])
	engine.state.energy = 3

	engine.play_card("GAFFE2")
	assert_eq(engine.state.gaffe, 4, "two on the card, four in this room")


func test_an_apology_is_not_worth_less_in_a_hard_room() -> void:
	# Only a gaffe gained is doubled. Multiplying a reduction would make
	# the ambush easier to clean up in than an ordinary conference.
	var engine := _start(_questions_stage({"gaffe_multiplier": 2}))
	engine.state.gaffe = 3
	engine._apply_effect({"gaffe": -2}, -1)
	assert_eq(engine.state.gaffe, 1)


func test_ducking_a_question_ends_an_ambush() -> void:
	var engine := _start(_questions_stage({
		"decline_ends_stage": true, "decline_tone_cost": 0,
	}))
	engine.end_turn()               # played nothing, so the question is ducked

	assert_true(engine.state.is_over())
	assert_eq(engine.state.outcome, "loss")
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.walked_away")


func test_a_lobbyists_interest_cools_every_turn() -> void:
	var engine := _start(_questions_stage({
		"affinity_decay": 5, "decline_tone_cost": 0,
	}))
	var before := engine.state.bar.player
	engine.state.hand.assign(["GAIN3", "GUARD5"])
	engine.state.energy = 1
	engine.play_card("GAIN3")       # +3 on the bar
	engine.end_turn()               # then 5 off, whatever was said

	assert_eq(engine.state.bar.player, before + 3 - 5,
		"the clock is working against you")


func test_a_town_hall_keeps_the_clock_but_refreshes_the_energy() -> void:
	# Neither of the other two modes does this: "reset" would wipe the
	# gaffes you have earned, "continuous" would leave you empty-handed in
	# front of somebody who has not heard you speak yet.
	var engine := _start({
		"stage": TestFixtures.stage({
			"stage_id": "TOWNHALL", "sequence_mode": "stream",
			"win_threshold": 45, "turn_limit": 12,
		}),
		"opponents": [
			{"opp_id": "A", "name": "A farmer", "intent_pattern": [["block", 1]]},
			{"opp_id": "B", "name": "A shopkeeper", "intent_pattern": [["block", 1]]},
		],
	})

	engine.state.gaffe = 2
	engine.state.turn = 6
	engine.state.energy = 0
	engine.state.bar.player = 45
	engine._check_outcome()

	assert_eq(engine.current_opponent()["name"], "A shopkeeper", "the queue moved on")
	assert_eq(engine.state.gaffe, 2, "your record follows you down the queue")
	assert_eq(engine.state.turn, 6, "and so does the clock")
	assert_eq(engine.state.energy, engine.state.energy_per_turn,
		"but the next person gets your full attention")


# ---------------------------------------------------------------------------
# The ending is named from the stage
# ---------------------------------------------------------------------------
# Three kinds of stage are scored — the caucus, the town hall and the TV
# debate — and all three used to close by announcing they were a caucus.

func _scored_stage(overrides: Dictionary = {}) -> Dictionary:
	var stage := TestFixtures.stage({
		"stage_id": "SCORED", "name_en": "TV Debate",
		"win_mode": "score", "turn_limit": 1,
		"bar_unit": "Press tone", "bar_max": 100,
		"player_start": 40, "opp_start": 40,
	})
	stage.merge(overrides, true)
	return {"stage": stage}


func test_a_scored_stage_closes_in_its_own_name() -> void:
	var engine := _start(_scored_stage())
	engine.end_turn()

	assert_true(engine.state.is_over())
	assert_string_contains(engine.state.outcome_reason, "outcome.reason.closed_on")
	assert_false(engine.state.outcome_reason.to_lower().contains("caucus"),
		"a TV debate is not a caucus: %s" % engine.state.outcome_reason)


func test_a_scored_stage_closes_in_its_own_units() -> void:
	# "34 support" on a press tone bar was how the wrong unit showed up.
	var engine := _start_with_words(_scored_stage())
	engine.end_turn()
	assert_string_contains(engine.state.outcome_reason, "press tone",
		"the TV debate should close on its own unit: %s" % engine.state.outcome_reason)


func test_a_stage_counted_as_a_share_still_closes_on_a_share() -> void:
	var engine := _start_with_words(_scored_stage({
		"name_en": "Party Caucus", "bar_as_percent": true,
	}))
	engine.end_turn()
	assert_string_contains(engine.state.outcome_reason, "per cent",
		"a caucus is counted as a share: %s" % engine.state.outcome_reason)
	assert_string_contains(engine.state.outcome_reason, "Party Caucus closed on")


# ---------------------------------------------------------------------------
# A stage says what kind of bar it wants
# ---------------------------------------------------------------------------

func test_a_stage_can_declare_its_own_bar() -> void:
	# THE BUG THIS EXISTS FOR. The model used to be picked by matching the
	# literal IDs "ST04" and "ST06", which the six levels never have: they
	# generate theirs from the type and the sequence. The TV debate was
	# therefore a room full of undecided people with a bar labelled "Press
	# tone", for three versions, until a playtest screenshot caught it.
	assert_eq(BarModel.for_stage({"stage_id": "TV_DEBATE_2", "bar_model": "single"}),
		BarModel.Model.SINGLE)
	assert_eq(BarModel.for_stage({"stage_id": "ANYTHING", "bar_model": "survival"}),
		BarModel.Model.SURVIVAL)
	assert_eq(BarModel.for_stage({"stage_id": "ANYTHING", "bar_model": "shared_pool"}),
		BarModel.Model.SHARED_POOL)


func test_a_stage_that_says_nothing_is_still_guessed_at() -> void:
	# The workbook's own stages carry no bar_model column, so the old rules
	# have to keep working for them.
	assert_eq(BarModel.for_stage({"stage_id": "ST04"}), BarModel.Model.SINGLE)
	assert_eq(BarModel.for_stage({"stage_id": "ST06"}), BarModel.Model.SURVIVAL)
	assert_eq(BarModel.for_stage({"stage_id": "ST02"}), BarModel.Model.SHARED_POOL)
	assert_eq(BarModel.for_stage({"stage_id": "X", "questions": [{"id": "Q1"}]}),
		BarModel.Model.SINGLE, "questions still make a press conference")


func test_the_tv_debate_in_the_data_is_one_bar() -> void:
	var tv: Dictionary = DataDB.stage_types.get("tv_debate", {})
	assert_false(tv.is_empty(), "there is a tv_debate stage type")
	assert_eq(BarModel.for_stage(tv), BarModel.Model.SINGLE,
		"a TV debate is press tone, not a room of people")

	var bar := BarModel.create(
		BarModel.for_stage(tv), 100, 0, 40, 40, func() -> int: return 0)
	assert_eq(bar.undecided, 0, "no undecided pile on a single bar")
	assert_eq(bar.opponent, 0, "and nobody opposite holding a headcount")
