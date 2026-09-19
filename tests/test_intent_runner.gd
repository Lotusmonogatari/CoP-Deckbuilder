extends GutTest
## Tests for the opponent's scripted moves.


func test_the_pattern_plays_in_order() -> void:
	var runner := IntentRunner.new([["attack", 6], ["gain", 4], ["block", 5]])

	assert_eq(runner.advance(), {"verb": "attack", "value": 6})
	assert_eq(runner.advance(), {"verb": "gain", "value": 4})
	assert_eq(runner.advance(), {"verb": "block", "value": 5})


func test_the_pattern_starts_over_at_the_end() -> void:
	var runner := IntentRunner.new([["attack", 6], ["gain", 4]])

	runner.advance()
	runner.advance()
	assert_eq(runner.advance(), {"verb": "attack", "value": 6}, "back round to the start")
	assert_eq(runner.advance(), {"verb": "gain", "value": 4})


func test_peeking_does_not_use_the_move_up() -> void:
	# The player sees next turn's move at the top of every turn, which must
	# not make the opponent skip it.
	var runner := IntentRunner.new([["attack", 6], ["gain", 4]])

	assert_eq(runner.peek(), {"verb": "attack", "value": 6})
	assert_eq(runner.peek(), {"verb": "attack", "value": 6}, "peeking twice shows the same move")
	assert_eq(runner.advance(), {"verb": "attack", "value": 6})


func test_looking_one_move_further_ahead() -> void:
	# What C12 Head Count buys you.
	var runner := IntentRunner.new([["attack", 6], ["gain", 4], ["block", 5]])

	assert_eq(runner.peek_ahead(), {"verb": "gain", "value": 4})
	runner.advance()
	assert_eq(runner.peek_ahead(), {"verb": "block", "value": 5})


func test_looking_ahead_wraps_round_too() -> void:
	var runner := IntentRunner.new([["attack", 6], ["gain", 4]])
	runner.advance()
	assert_eq(runner.peek_ahead(), {"verb": "attack", "value": 6})


func test_a_single_move_pattern_repeats_forever() -> void:
	var runner := IntentRunner.new([["attack", 5]])
	for _index in 5:
		assert_eq(runner.advance()["value"], 5)


# ---------------------------------------------------------------------------
# Saving and restoring
# ---------------------------------------------------------------------------

func test_the_position_survives_a_save() -> void:
	var runner := IntentRunner.new([["attack", 6], ["gain", 4], ["block", 5]])
	runner.advance()
	runner.advance()
	assert_eq(runner.position(), 2)

	var restored := IntentRunner.new([["attack", 6], ["gain", 4], ["block", 5]])
	restored.set_position(runner.position())
	assert_eq(restored.peek(), {"verb": "block", "value": 5},
		"reloading mid-battle keeps the opponent's rhythm")


func test_an_out_of_range_position_is_wrapped() -> void:
	var runner := IntentRunner.new([["attack", 6], ["gain", 4]])
	runner.set_position(5)
	assert_eq(runner.peek(), {"verb": "gain", "value": 4}, "5 wraps to 1 in a two-move pattern")


# ---------------------------------------------------------------------------
# Rejecting bad patterns
# ---------------------------------------------------------------------------

func test_a_good_pattern_is_accepted() -> void:
	assert_true(IntentRunner.new([["attack", 6], ["block", 5]]).is_valid())


func test_an_empty_pattern_is_rejected() -> void:
	var runner := IntentRunner.new([])
	assert_false(runner.is_valid())
	assert_string_contains(runner.problems()[0], "no intent pattern")


func test_an_unknown_verb_is_rejected() -> void:
	# Better to refuse to start the battle than to have the opponent stand
	# there doing nothing for eight turns.
	var runner := IntentRunner.new([["attack", 6], ["filibuster", 3]])
	assert_false(runner.is_valid())
	assert_string_contains(runner.problems()[0], "filibuster")


func test_a_malformed_move_is_rejected() -> void:
	var runner := IntentRunner.new([["attack"]])
	assert_false(runner.is_valid())
	assert_string_contains(runner.problems()[0], "verb and a number")


func test_every_verb_the_battle_understands_is_accepted() -> void:
	for verb: String in IntentRunner.KNOWN_VERBS:
		assert_true(IntentRunner.new([[verb, 3]]).is_valid(), "'%s' should be valid" % verb)


# ---------------------------------------------------------------------------
# What the player reads
# ---------------------------------------------------------------------------

func test_moves_are_described_in_plain_words() -> void:
	assert_eq(IntentRunner.describe({"verb": "attack", "value": 6}), "Attacking · −6")
	assert_eq(IntentRunner.describe({"verb": "gain", "value": 4}), "Gaining · +4")
	assert_eq(IntentRunner.describe({"verb": "block", "value": 5}), "Defending · 5")
	assert_eq(IntentRunner.describe({"verb": "lean_down", "value": 8}), "Pressuring · −8")
