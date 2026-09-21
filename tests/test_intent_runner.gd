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
	assert_eq(IntentRunner.describe({"verb": "block", "value": 5}), "Guarding · 5")
	assert_eq(IntentRunner.describe({"verb": "lean_down", "value": 8}), "Pressuring · −8")


# ---------------------------------------------------------------------------
# Ranges
# ---------------------------------------------------------------------------
# A move may be written as a verb and a range to roll between, inclusive at
# both ends. Cameron's five patterns, 2026-09-21.

## A roller that hands back a fixed answer, so a test can say what was rolled.
func _fixed(value: int) -> Callable:
	return func(low: int, high: int) -> int: return clampi(value, low, high)


## A roller that walks a list, so a test can script a sequence of rolls.
func _scripted(values: Array) -> Callable:
	var index := [0]
	return func(low: int, high: int) -> int:
		var value: int = values[index[0] % values.size()]
		index[0] += 1
		return clampi(value, low, high)


func test_a_range_is_rolled_between_its_ends() -> void:
	var runner := IntentRunner.new([["attack", 1, 6]], _fixed(4))
	var move := runner.advance()
	assert_eq(move["verb"], "attack")
	assert_eq(move["value"], 4)
	assert_eq(move["min"], 1, "and it says what was possible")
	assert_eq(move["max"], 6)


func test_a_range_never_lands_outside_its_ends() -> void:
	# Over many draws with the real generator, not a scripted one.
	var runner := IntentRunner.new([["attack", 2, 5]])
	for _index in 200:
		var value: int = runner.advance()["value"]
		assert_between(value, 2, 5)


func test_a_fixed_move_keeps_its_plain_shape() -> void:
	# No min or max on a move that has no range: the battle and the screen
	# both read the absence as "this is exactly what happens".
	var runner := IntentRunner.new([["attack", 6]])
	assert_eq(runner.advance(), {"verb": "attack", "value": 6})


func test_the_ends_are_included() -> void:
	var low := IntentRunner.new([["attack", 3, 7]], _fixed(3))
	assert_eq(low.advance()["value"], 3)
	var high := IntentRunner.new([["attack", 3, 7]], _fixed(7))
	assert_eq(high.advance()["value"], 7)


# ---------------------------------------------------------------------------
# The zero rule
# ---------------------------------------------------------------------------
# A move that comes out at zero is not taken. The opponent steps to the next
# move and does that instead, rather than spending a turn guarding nothing.

func test_a_flat_zero_move_is_never_taken() -> void:
	# Pattern 4: attack 5 / gain 0-2 / block 0. That opponent never guards.
	var runner := IntentRunner.new(
		[["attack", 5], ["gain", 0, 2], ["block", 0]], _fixed(2))

	var verbs: Array[String] = []
	for _index in 12:
		verbs.append(str(runner.advance()["verb"]))

	assert_false(verbs.has("block"), "the block is worth nothing, so it never happens")
	assert_true(verbs.has("attack"))
	assert_true(verbs.has("gain"))


func test_a_range_that_rolls_zero_gives_way_to_the_next_move() -> void:
	var runner := IntentRunner.new(
		[["block", 0, 2], ["attack", 4]], _scripted([0]))

	# The block rolled nothing, so the attack happens in its place.
	assert_eq(runner.peek()["verb"], "attack")
	assert_eq(runner.advance()["value"], 4)


func test_no_move_ever_comes_out_at_nothing() -> void:
	var runner := IntentRunner.new([["attack", 0, 6], ["gain", 2, 4], ["block", 1, 3]])
	for _index in 300:
		assert_ne(int(runner.advance()["value"]), 0)


func test_a_pattern_of_nothing_but_zeros_waits_rather_than_hanging() -> void:
	# Nothing in the game can do this. The bound is what keeps it safe to add
	# patterns later without one of them locking the game up.
	var runner := IntentRunner.new([["block", 0], ["gain", 0]])
	assert_eq(runner.advance(), {"verb": "none", "value": 0})
	assert_false(runner.is_valid(), "and the data check refuses it up front")
	assert_string_contains(runner.problems()[0], "never act")


func test_the_skipped_moves_are_used_up() -> void:
	# Pattern 4 again: once the block is stepped over, the cycle comes back
	# round to the attack rather than retrying the block next turn.
	var runner := IntentRunner.new(
		[["attack", 5], ["gain", 1], ["block", 0]], _fixed(1))
	assert_eq(runner.advance()["verb"], "attack")
	assert_eq(runner.advance()["verb"], "gain")
	assert_eq(runner.advance()["verb"], "attack", "the block was stepped over, not queued")


# ---------------------------------------------------------------------------
# When the roll happens
# ---------------------------------------------------------------------------
# At peek, once, and held. Rolling later would let the screen announce a verb
# the opponent then does not use.

func test_peeking_rolls_once_however_often_the_screen_asks() -> void:
	var rolls := [0]
	var counting := func(low: int, _high: int) -> int:
		rolls[0] += 1
		return low + 1
	var runner := IntentRunner.new([["attack", 1, 6]], counting)

	for _index in 10:
		runner.peek()
	assert_eq(rolls[0], 1, "ten repaints, one roll")


func test_what_was_shown_is_what_happens() -> void:
	var runner := IntentRunner.new(
		[["block", 0, 2], ["attack", 1, 6]], _scripted([0, 5]))
	var shown := runner.peek()
	var done := runner.advance()
	assert_eq(shown, done, "the verb and the number both hold")


func test_head_count_is_not_a_lie() -> void:
	# C12 reveals the move after next. That move must then be the one that
	# happens, rather than being rolled again when it comes round.
	var runner := IntentRunner.new(
		[["attack", 1, 6], ["gain", 1, 6]], _scripted([2, 5, 1]))
	var revealed := runner.peek_ahead()
	runner.advance()
	assert_eq(runner.peek(), revealed, "what Head Count showed is what arrives")


func test_reloading_a_battle_does_not_restore_a_stale_roll() -> void:
	var runner := IntentRunner.new([["attack", 1, 6]], _fixed(3))
	runner.peek()
	runner.set_position(0)
	assert_eq(runner.peek()["value"], 3, "rolled again for the position it was put at")


func test_the_same_seed_plays_the_same_way_twice() -> void:
	var first := _rolled_sequence(4242)
	var second := _rolled_sequence(4242)
	assert_eq(first, second)
	assert_ne(first, _rolled_sequence(99), "and a different seed does not")


func _rolled_sequence(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var runner := IntentRunner.new(
		[["attack", 1, 6], ["gain", 1, 6], ["block", 0, 2]],
		func(low: int, high: int) -> int: return rng.randi_range(low, high))

	var out: Array = []
	for _index in 20:
		var move := runner.advance()
		out.append("%s%d" % [move["verb"], move["value"]])
	return out


# ---------------------------------------------------------------------------
# What the player reads, for a range
# ---------------------------------------------------------------------------

func test_a_range_is_described_as_a_range() -> void:
	assert_eq(IntentRunner.describe(
		{"verb": "attack", "value": 4, "min": 1, "max": 6}), "Attacking · −1 to −6")
	assert_eq(IntentRunner.describe(
		{"verb": "gain", "value": 3, "min": 2, "max": 4}), "Gaining · +2 to +4")
	assert_eq(IntentRunner.describe(
		{"verb": "lean_down", "value": 2, "min": 1, "max": 3}), "Pressuring · −1 to −3")


func test_a_described_range_never_promises_a_zero() -> void:
	# A "block 0 to 2" cannot actually come out at 0 — a zero would have been
	# stepped over and something else shown instead — so saying "0 to 2"
	# would promise an outcome that cannot happen.
	assert_eq(IntentRunner.describe(
		{"verb": "block", "value": 1, "min": 0, "max": 2}), "Guarding · 1 to 2")


func test_a_range_with_one_value_left_reads_as_one_number() -> void:
	assert_eq(IntentRunner.describe(
		{"verb": "gain", "value": 1, "min": 0, "max": 1}), "Gaining · +1")


func test_waiting_is_still_waiting() -> void:
	assert_eq(IntentRunner.describe({"verb": "none", "value": 0}), "Waiting")


# ---------------------------------------------------------------------------
# The patterns that are actually in the game
# ---------------------------------------------------------------------------

func test_every_pattern_in_the_data_can_be_played() -> void:
	var checked := 0

	for level: Variant in DataDB.levels:
		for stage: Variant in (level as Dictionary).get("stages", []):
			for opponent: Variant in (stage as Dictionary).get("opponents", []):
				var row: Dictionary = opponent
				var pattern: Variant = row.get("intent_pattern")
				assert_not_null(pattern, "%s has no pattern" % row.get("name", "?"))
				var runner := IntentRunner.new(pattern)
				assert_true(runner.is_valid(), "%s: %s"
					% [row.get("name", "?"), ", ".join(Array(runner.problems()))])
				checked += 1

	for opp_id: String in DataDB.intent_patterns.keys():
		var runner := IntentRunner.new(DataDB.intent_patterns[opp_id])
		assert_true(runner.is_valid(), "%s: %s"
			% [opp_id, ", ".join(Array(runner.problems()))])
		checked += 1

	assert_gt(checked, 20, "every opponent in every level, plus the nine MPs")
