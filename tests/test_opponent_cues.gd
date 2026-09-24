extends GutTest
## OpponentCues.gd — the opponent's own twin of CardCues.gd, plus the
## suit-weighting it does before picking a line (CardCues never has to,
## since the player only ever has the one card in hand). Uses fake
## opponent_cues.json rows throughout (the real workbook has none yet — see
## tools/export_data.py's "Opponent Cues" entry), the same way
## test_visitor_selection.gd proves multi-ID sharing against fake
## visitor_questions.json rows rather than real data.
##
## Every for_move() call below passes suit_roll/other_suit_roll explicitly,
## so which suit gets drawn from is pinned rather than left to randf() — the
## same reason IntentRunner's own tests never let a real die decide.

var _cues_before: Array = []


func before_each() -> void:
	_cues_before = DataDB.opponent_cues.duplicate(true)


func after_each() -> void:
	DataDB.opponent_cues = _cues_before.duplicate(true)
	DataDB._build_lookups()


func test_falls_back_to_empty_when_nothing_is_written() -> void:
	DataDB.opponent_cues = []
	DataDB._build_lookups()
	var cue := OpponentCues.for_move(
		{"opp_id": "OP_NONE", "suit_1": "Earnest"}, "attack", "ST02", 1, 0.0)
	assert_eq(cue["text"], "")
	assert_eq(cue["line_id"], "")


func test_draws_from_the_general_pool_by_suit_when_no_bespoke_line_exists() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "General Earnest attack line."},
	]
	DataDB._build_lookups()
	# 0.0 lands in the suit_1 bucket (below PRIMARY_THRESHOLD).
	var cue := OpponentCues.for_move(
		{"opp_id": "OP_ANY", "suit_1": "Earnest"}, "attack", "ST02", 1, 0.0)
	assert_eq(cue["text"], "General Earnest attack line.")


func test_a_bespoke_line_wins_over_the_general_pool_for_the_opponent_it_names() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "General Earnest attack line."},
		{"cue_id": "OC02", "suit": "Earnest", "verb": "attack", "opponent_ids": ["OP03"],
			"cue_1": "OP03's own line."},
	]
	DataDB._build_lookups()

	var named := OpponentCues.for_move({"opp_id": "OP03", "suit_1": "Earnest"}, "attack", "ST02", 1, 0.0)
	assert_eq(named["text"], "OP03's own line.")

	# Someone else with the same suit still draws from the general pool —
	# the bespoke row is never blended in for them. A bespoke hit skips the
	# suit roll entirely, so this only needs to prove the fallback still
	# reaches the general pool.
	var other := OpponentCues.for_move({"opp_id": "OP99", "suit_1": "Earnest"}, "attack", "ST02", 1, 0.0)
	assert_eq(other["text"], "General Earnest attack line.")


func test_a_bespoke_row_can_name_several_opponents_at_once() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "gain", "opponent_ids": ["OP01", "OP02"],
			"cue_1": "Shared line for OP01 and OP02."},
	]
	DataDB._build_lookups()

	var first := OpponentCues.for_move({"opp_id": "OP01", "suit_1": "Divisive"}, "gain", "ST02", 1, 0.0)
	var second := OpponentCues.for_move({"opp_id": "OP02", "suit_1": "Divisive"}, "gain", "ST02", 1, 0.0)
	assert_eq(first["text"], "Shared line for OP01 and OP02.")
	assert_eq(second["text"], "Shared line for OP01 and OP02.")


func test_the_verb_picks_a_different_pool_than_the_suit_alone() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "Attack line."},
		{"cue_id": "OC02", "suit": "Earnest", "verb": "gain", "opponent_ids": [],
			"cue_1": "Gain line."},
	]
	DataDB._build_lookups()

	var opponent := {"opp_id": "OP_ANY", "suit_1": "Earnest"}
	assert_eq(OpponentCues.for_move(opponent, "attack", "ST02", 1, 0.0)["text"], "Attack line.")
	assert_eq(OpponentCues.for_move(opponent, "gain", "ST02", 1, 0.0)["text"], "Gain line.")


func test_the_same_moment_always_picks_the_same_line() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "Line one.", "cue_2": "Line two.", "cue_3": "Line three.",
			"cue_4": "Line four.", "cue_5": "Line five."},
	]
	DataDB._build_lookups()

	var opponent := {"opp_id": "OP_ANY", "suit_1": "Earnest"}
	var first := OpponentCues.for_move(opponent, "attack", "ST02", 3, 0.0)
	var second := OpponentCues.for_move(opponent, "attack", "ST02", 3, 0.0)
	assert_eq(first["text"], second["text"])
	assert_eq(first["line_id"], second["line_id"])


func test_blank_cue_cells_are_dropped_not_counted_as_lines() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "block", "opponent_ids": [],
			"cue_1": "Only one line written.", "cue_2": "", "cue_3": ""},
	]
	DataDB._build_lookups()

	var opponent := {"opp_id": "OP_ANY", "suit_1": "Earnest"}
	for turn in range(1, 10):
		var cue := OpponentCues.for_move(opponent, "block", "ST02", turn, 0.0)
		assert_eq(cue["text"], "Only one line written.")


# ---------------------------------------------------------------------------
# Suit weighting: 55% suit_1, 30% suit_2, 10% suit_3, 5% some other suit
# ---------------------------------------------------------------------------

func test_a_low_roll_picks_the_opponents_primary_suit() -> void:
	var opponent := {"suit_1": "Earnest", "suit_2": "Emotional", "suit_3": "Appeal"}
	assert_eq(OpponentCues._suit_for_move(opponent, 0.0, 0.0), "Earnest")
	assert_eq(OpponentCues._suit_for_move(opponent, 0.54, 0.0), "Earnest")


func test_the_next_band_picks_the_secondary_suit() -> void:
	var opponent := {"suit_1": "Earnest", "suit_2": "Emotional", "suit_3": "Appeal"}
	assert_eq(OpponentCues._suit_for_move(opponent, 0.55, 0.0), "Emotional")
	assert_eq(OpponentCues._suit_for_move(opponent, 0.84, 0.0), "Emotional")


func test_the_next_band_after_that_picks_the_tertiary_suit() -> void:
	var opponent := {"suit_1": "Earnest", "suit_2": "Emotional", "suit_3": "Appeal"}
	assert_eq(OpponentCues._suit_for_move(opponent, 0.85, 0.0), "Appeal")
	assert_eq(OpponentCues._suit_for_move(opponent, 0.94, 0.0), "Appeal")


func test_the_top_five_percent_picks_a_suit_outside_the_opponents_own_three() -> void:
	var opponent := {"suit_1": "Earnest", "suit_2": "Emotional", "suit_3": "Appeal"}
	var picked := OpponentCues._suit_for_move(opponent, 0.95, 0.0)
	assert_true(["Data Driven", "Divisive", "Duplicitous"].has(picked),
		"should be one of the three suits not tagged to this opponent")
	picked = OpponentCues._suit_for_move(opponent, 0.999, 0.0)
	assert_true(["Data Driven", "Divisive", "Duplicitous"].has(picked))


func test_the_other_suit_roll_picks_uniformly_among_the_three_outsiders() -> void:
	var opponent := {"suit_1": "Earnest", "suit_2": "Emotional", "suit_3": "Appeal"}
	assert_eq(OpponentCues._other_suit(opponent, 0.0), "Data Driven")
	assert_eq(OpponentCues._other_suit(opponent, 0.4), "Divisive")
	assert_eq(OpponentCues._other_suit(opponent, 0.9), "Duplicitous")


func test_for_move_actually_uses_the_weighted_suit_not_just_suit_1() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Emotional", "verb": "attack", "opponent_ids": [],
			"cue_1": "Emotional attack line."},
	]
	DataDB._build_lookups()
	var opponent := {"opp_id": "OP_ANY", "suit_1": "Earnest", "suit_2": "Emotional", "suit_3": "Appeal"}
	# 0.6 lands in the suit_2 band, which is Emotional for this opponent.
	var cue := OpponentCues.for_move(opponent, "attack", "ST02", 1, 0.6)
	assert_eq(cue["text"], "Emotional attack line.")
