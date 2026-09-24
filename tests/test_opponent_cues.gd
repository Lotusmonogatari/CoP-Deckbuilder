extends GutTest
## OpponentCues.gd — the opponent's own twin of CardCues.gd. Uses fake
## opponent_cues.json rows throughout (the real workbook has none yet — see
## tools/export_data.py's "Opponent Cues" entry), the same way
## test_visitor_selection.gd proves multi-ID sharing against fake
## visitor_questions.json rows rather than real data.

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
		{"opp_id": "OP_NONE", "suit_1": "Earnest"}, "attack", "ST02", 1)
	assert_eq(cue["text"], "")
	assert_eq(cue["line_id"], "")


func test_draws_from_the_general_pool_by_suit_when_no_bespoke_line_exists() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "General Earnest attack line."},
	]
	DataDB._build_lookups()
	var cue := OpponentCues.for_move(
		{"opp_id": "OP_ANY", "suit_1": "Earnest"}, "attack", "ST02", 1)
	assert_eq(cue["text"], "General Earnest attack line.")


func test_a_bespoke_line_wins_over_the_general_pool_for_the_opponent_it_names() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "General Earnest attack line."},
		{"cue_id": "OC02", "suit": "Earnest", "verb": "attack", "opponent_ids": ["OP03"],
			"cue_1": "OP03's own line."},
	]
	DataDB._build_lookups()

	var named := OpponentCues.for_move({"opp_id": "OP03", "suit_1": "Earnest"}, "attack", "ST02", 1)
	assert_eq(named["text"], "OP03's own line.")

	# Someone else with the same suit still draws from the general pool —
	# the bespoke row is never blended in for them.
	var other := OpponentCues.for_move({"opp_id": "OP99", "suit_1": "Earnest"}, "attack", "ST02", 1)
	assert_eq(other["text"], "General Earnest attack line.")


func test_a_bespoke_row_can_name_several_opponents_at_once() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "gain", "opponent_ids": ["OP01", "OP02"],
			"cue_1": "Shared line for OP01 and OP02."},
	]
	DataDB._build_lookups()

	var first := OpponentCues.for_move({"opp_id": "OP01", "suit_1": "Divisive"}, "gain", "ST02", 1)
	var second := OpponentCues.for_move({"opp_id": "OP02", "suit_1": "Divisive"}, "gain", "ST02", 1)
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
	assert_eq(OpponentCues.for_move(opponent, "attack", "ST02", 1)["text"], "Attack line.")
	assert_eq(OpponentCues.for_move(opponent, "gain", "ST02", 1)["text"], "Gain line.")


func test_the_same_moment_always_picks_the_same_line() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OC01", "suit": "Earnest", "verb": "attack", "opponent_ids": [],
			"cue_1": "Line one.", "cue_2": "Line two.", "cue_3": "Line three.",
			"cue_4": "Line four.", "cue_5": "Line five."},
	]
	DataDB._build_lookups()

	var opponent := {"opp_id": "OP_ANY", "suit_1": "Earnest"}
	var first := OpponentCues.for_move(opponent, "attack", "ST02", 3)
	var second := OpponentCues.for_move(opponent, "attack", "ST02", 3)
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
		var cue := OpponentCues.for_move(opponent, "block", "ST02", turn)
		assert_eq(cue["text"], "Only one line written.")
