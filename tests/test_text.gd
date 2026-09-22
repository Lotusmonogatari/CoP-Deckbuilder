extends GutTest
## The lines the game says, and the table they now come from.
##
## Cameron writes the wording in the Text tab of the design workbook. These
## tests cover the lookup itself, and — more importantly — check that moving
## a line out of the code did not quietly reword it.

func test_the_table_loaded() -> void:
	assert_gt(DataDB.strings.size(), 0,
		"strings.json should have come out of the workbook's Text tab")


func test_a_line_comes_back_as_written() -> void:
	assert_eq(Text.say("outcome.carried"), "Carried")


func test_a_placeholder_is_filled_in() -> void:
	assert_eq(Text.say("outcome.closed", {"stage": "Party Caucus"}),
		"Party Caucus closed")


func test_a_missing_key_does_not_crash() -> void:
	# It shows the key instead, which is ugly and obvious. The exporter
	# refuses to write the file while the code asks for a key the sheet has
	# not got, so this should only ever be seen mid-edit.
	assert_eq(Text.say("nothing.like.this"), "nothing.like.this")


func test_has_reports_whether_a_line_exists() -> void:
	assert_true(Text.has("outcome.carried"))
	assert_false(Text.has("nothing.like.this"))


# ---------------------------------------------------------------------------
# Plurals
# ---------------------------------------------------------------------------

func test_a_count_of_one_picks_the_singular() -> void:
	# The sheet carries .one and .other as two plain rows rather than one
	# row with a clever separator in it.
	DataDB.strings["spec.thing.one"] = "{count} thing"
	DataDB.strings["spec.thing.other"] = "{count} things"

	assert_eq(Text.say("spec.thing", {"count": 1}), "1 thing")
	assert_eq(Text.say("spec.thing", {"count": 3}), "3 things")
	assert_eq(Text.say("spec.thing", {"count": 0}), "0 things")

	DataDB.strings.erase("spec.thing.one")
	DataDB.strings.erase("spec.thing.other")


func test_one_wording_serves_both_where_that_is_right() -> void:
	# Most lines read the same either way and should not need two rows.
	DataDB.strings["spec.flat"] = "{count} XP"
	assert_eq(Text.say("spec.flat", {"count": 1}), "1 XP")
	assert_eq(Text.say("spec.flat", {"count": 9}), "9 XP")
	DataDB.strings.erase("spec.flat")


# ---------------------------------------------------------------------------
# The wording did not change by accident
# ---------------------------------------------------------------------------
# tests/wording_snapshot.json holds every line as it read the last time
# somebody deliberately accepted a change. One test covers all of them.
#
# A CODE change that quietly alters what the player reads fails here, naming
# the line. A wording change Cameron makes on purpose is recorded with
#
#     python3 tools/export_data.py --accept-wording
#
# and git then shows exactly what he changed. This is what the long lists of
# hand-typed sentences here used to do — one test does it for all 200 lines,
# and Cameron can clear it himself with one command.

func test_every_line_reads_as_it_was_last_accepted() -> void:
	var file := FileAccess.open("res://tests/wording_snapshot.json", FileAccess.READ)
	assert_not_null(file, "tests/wording_snapshot.json should be checked in")
	if file == null:
		return

	var recorded: Dictionary = JSON.parse_string(file.get_as_text())
	assert_gt(recorded.size(), 0, "the snapshot should not be empty")

	var drifted: Array[String] = []
	for key: String in recorded.keys():
		if not DataDB.strings.has(key):
			drifted.append("%s is gone from the Text tab" % key)
		elif str(DataDB.strings[key]) != str(recorded[key]):
			drifted.append("%s now reads \"%s\" (was \"%s\")"
				% [key, DataDB.strings[key], recorded[key]])
	for key: String in DataDB.strings.keys():
		if not recorded.has(key):
			drifted.append("%s is new" % key)

	assert_eq(drifted.size(), 0,
		"wording changed without being accepted:\n  " + "\n  ".join(drifted)
		+ "\n\nIf those were your edits, run: "
		+ "python3 tools/export_data.py --accept-wording")


# ---------------------------------------------------------------------------
# How the sentences are put together
# ---------------------------------------------------------------------------
# These check COMPOSITION rather than wording: that a plural picks the right
# row, that two clauses which read differently stay different, and that the
# brief's bullets are assembled from their parts. Each uses stand-in wording
# so Cameron can reword the real lines without any of them failing.

func test_the_two_won_over_clauses_stay_different() -> void:
	# The player's reads "4 seats won over"; the opponent's reads "won over
	# 4 seats". Collapsing them onto one key silently reworded the
	# opponent's line, and the suite caught it — so they are kept apart.
	assert_ne(Text.say("narration.won_over", {"amount": "4 seats"}),
		Text.say("narration.won_over_them", {"amount": "4 seats"}),
		"the player's clause and the opponent's read differently")


func test_a_plural_clause_picks_the_right_row() -> void:
	var one := Text.say("narration.gaffe", {"count": 1})
	var many := Text.say("narration.gaffe", {"count": 2})
	assert_ne(one, many, "one gaffe and two should not read the same")
	assert_string_contains(one, "1")
	assert_string_contains(many, "2")


func test_a_card_effect_line_joins_its_parts() -> void:
	var effect := {"self_plus": 4, "opp_minus": 2, "guard": 1, "draw": 1, "gaffe": 1}
	var line := CardView.describe_effect(effect, {})
	for number: String in ["4", "2", "1"]:
		assert_string_contains(line, number)
	assert_gt(line.split(" ").size(), 5, "all five parts should be in the sentence")


func test_an_opponents_move_carries_its_number_and_its_range() -> void:
	var words := Text.phrase()
	assert_string_contains(IntentRunner.describe({"verb": "attack", "value": 6}, words), "6")
	var ranged := IntentRunner.describe(
		{"verb": "attack", "value": 4, "min": 1, "max": 6}, words)
	assert_string_contains(ranged, "1")
	assert_string_contains(ranged, "6")
	# A "block 0 to 2" can never come out at 0, so it must not advertise one.
	assert_false(IntentRunner.describe(
		{"verb": "block", "value": 1, "min": 0, "max": 2}, words).contains("0"))


# ---------------------------------------------------------------------------
# A level that ends badly now says so
# ---------------------------------------------------------------------------

func test_a_level_can_sign_off_on_a_loss() -> void:
	# THE BUG THIS COVERS. The panel only ever asked for win_text, so the
	# four loss lines written in levels.json had never once reached the
	# screen: a level ended badly in silence, and rewording the line changed
	# nothing at all.
	var with_loss_text: Array[Dictionary] = []
	for level: Dictionary in DataDB.levels:
		if not str(level.get("loss_text", "")).strip_edges().is_empty():
			with_loss_text.append(level)

	assert_gt(with_loss_text.size(), 0,
		"levels.json should still carry loss lines for this to matter")

	var level: Dictionary = with_loss_text[0]
	var runner := LevelRunner.new(level)
	GameState.begin_level(runner)
	# Stand at the last stage, which is where a level signs off.
	runner.index = runner.stage_count() - 1

	assert_eq(OutcomePresenter.sign_off("loss_text"),
		str(level.get("loss_text", "")).strip_edges(),
		"the level's own loss line should be what comes back")

	GameState.end_level()


func test_the_room_brief_covers_every_rule_of_the_room() -> void:
	# Each bullet must reach the screen carrying the stage's real number.
	# What the words around the number are is Cameron's.
	var stage := {
		"turn_limit": 15, "energy_per_turn": 3, "gaffe_limit": 5,
		"hand_size": 5, "win_threshold": 51, "bar_unit": "Seats",
	}
	var lines := StageBrief.how_this_room_works(stage)

	assert_eq(lines[0], Text.say("brief.heading"), "the heading comes first")
	var expected := {
		"brief.label.turns": "15",
		"brief.label.energy": "3",
		"brief.label.gaffes": "5",
		"brief.label.hand": "5",
		"brief.label.winning": "51",
	}
	for label_key: String in expected.keys():
		var found := ""
		for line: String in lines:
			if line.contains(Text.say(label_key)):
				found = line
		assert_ne(found, "", "the brief should have a %s line" % label_key)
		assert_string_contains(found, str(expected[label_key]))


func test_the_brief_explains_a_pool_of_energy() -> void:
	# The sentence a playtest asked for: a policy study only refills energy
	# when it is spent, so it looked finite.
	var stage := {"energy_mode": "pool", "energy_pool": 6, "turn_limit": 0}
	var lines := StageBrief.how_this_room_works(stage)

	var turns := ""
	var energy := ""
	for line: String in lines:
		if line.contains(Text.say("brief.label.turns")):
			turns = line
		if line.contains(Text.say("brief.label.energy")):
			energy = line

	assert_string_contains(turns, Text.say("brief.turns.none"),
		"a stage with no turn limit should say so rather than showing a 0")
	assert_string_contains(energy, "6")
	assert_ne(energy, Text.say("brief.energy.per_turn", {"count": 6}),
		"a pool is explained differently from an allowance each turn")


func test_each_kind_of_room_says_how_winning_works() -> void:
	# Three different rooms, three different explanations — and the two that
	# name a threshold carry its real number.
	var score := Text.say("brief.winning.score")
	var reset := Text.say("brief.winning.reset", {"count": 51, "unit": "seats"})
	var single := Text.say("brief.winning.single", {"count": 51, "unit": "seats"})

	assert_ne(score, reset)
	assert_ne(reset, single)
	assert_string_contains(reset, "51 seats")
	assert_string_contains(single, "51 seats")
	assert_false(score.contains("51"), "a scored room has nothing to reach")
