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
# The wording did not change
# ---------------------------------------------------------------------------
# These are the exact sentences the outcome panel showed before the move. If
# one of them fails, a line was reworded by accident rather than on purpose —
# which is the one thing this whole change must not do.

func test_the_outcome_panel_still_reads_as_it_did() -> void:
	var expected := {
		"outcome.carried": "Carried",
		"outcome.defeated": "Defeated",
		"outcome.no_decision": "No decision",
		"outcome.conference_over": "Conference over",
		"outcome.close": "Close",
		"outcome.back_to_office": "Back to the Office",
		"outcome.next_stage": "On to the next stage",
		"outcome.no_rewards": "This stage has no rewards set yet.",
		"outcome.sign_off_unwritten": "That is the end of it.",
	}
	for key: String in expected.keys():
		assert_eq(Text.say(key), str(expected[key]), key)


func test_the_sentences_with_numbers_still_read_as_they_did() -> void:
	assert_eq(Text.say("outcome.ahead", {"count": 3}),
		"You start 3 ahead at the floor debate.")
	assert_eq(Text.say("outcome.behind", {"count": 2}),
		"You start 2 behind at the floor debate.")
	assert_eq(Text.say("outcome.pleased", {"names": "The Harbour Union"}),
		"Pleased: The Harbour Union.")
	assert_eq(Text.say("outcome.xp", {"count": 12}), "12 XP")
	assert_eq(Text.say("outcome.sign_off_named", {"level": "Bill on the Floor"}),
		"Bill on the Floor is behind you.")


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


# ---------------------------------------------------------------------------
# Stage 2: the notices and the narration
# ---------------------------------------------------------------------------
# The same discipline as above — these are the exact sentences the screen
# showed before the move, so a line cannot be reworded by accident.

func test_the_turn_notices_still_read_as_they_did() -> void:
	assert_eq(Text.say("battle.passed"),
		"You said nothing. One less energy this turn.")
	assert_eq(Text.say("battle.declined"),
		"You let that one go. The room cools.")
	assert_eq(Text.say("battle.no_stage"), "There is no stage to play here.")


func test_the_narration_clauses_still_read_as_they_did() -> void:
	var expected := {
		"narration.nothing_through": "nothing got through",
		"narration.nothing_to_take": "the attack found nothing to take",
		"narration.they": "They",
		"narration.them_generic": "them",
		"narration.their_generic": "their",
		"narration.a_member": "a member",
	}
	for key: String in expected.keys():
		assert_eq(Text.say(key), str(expected[key]), key)

	assert_eq(Text.say("narration.absorbed", {"count": 4}),
		"your guard absorbed 4")
	assert_eq(Text.say("narration.guard_built", {"count": 3}),
		"developed 3 guard")
	assert_eq(Text.say("narration.their_named", {"name": "Ito"}), "Ito's")
	assert_eq(Text.say("narration.waited", {"who": "Ito"}), "Ito waited.")
	assert_eq(Text.say("narration.sentence", {"who": "Ito", "clauses": "a, b"}),
		"Ito: a, b.")


func test_the_two_won_over_clauses_stay_different() -> void:
	# The player's reads "4 seats won over"; the opponent's reads "won over
	# 4 seats". Collapsing them onto one key silently reworded the
	# opponent's line, and the suite caught it — so it is pinned here.
	assert_eq(Text.say("narration.won_over", {"amount": "4 seats"}),
		"4 seats won over")
	assert_eq(Text.say("narration.won_over_them", {"amount": "4 seats"}),
		"won over 4 seats")


func test_the_gaffe_clause_counts_properly() -> void:
	assert_eq(Text.say("narration.gaffe", {"count": 1}), "1 gaffe on your record")
	assert_eq(Text.say("narration.gaffe", {"count": 2}), "2 gaffes on your record")
	assert_eq(Text.say("narration.short", {"count": 1}), ", 1 point short of the next")
	assert_eq(Text.say("narration.short", {"count": 3}), ", 3 points short of the next")


# ---------------------------------------------------------------------------
# Stage 3: the room brief
# ---------------------------------------------------------------------------
# The brief is assembled from templates now, so these check the SENTENCES it
# produces for a real stage, not just that the rows exist.

func test_the_room_brief_reads_as_it_did() -> void:
	var stage := {
		"turn_limit": 15, "energy_per_turn": 3, "gaffe_limit": 5,
		"hand_size": 5, "win_threshold": 51, "bar_unit": "Seats",
	}
	var lines := StageBrief.how_this_room_works(stage)

	assert_eq(lines[0], "How this room works")
	assert_has(lines, "• Turns — 15. Running out of them is a loss.")
	assert_has(lines, "• Energy — 3 a turn, back in full when you end the turn.")
	assert_has(lines, "• Gaffes — 5 ends the stage at once.")
	assert_has(lines, "• Your hand — drawn back up to 5 at the end of every turn.")
	assert_has(lines, "• Winning — 51 seats.")


func test_the_brief_explains_a_pool_of_energy() -> void:
	# The sentence a playtest asked for: a policy study only refills energy
	# when it is spent, so it looked finite.
	var stage := {"energy_mode": "pool", "energy_pool": 6, "turn_limit": 0}
	var lines := StageBrief.how_this_room_works(stage)
	assert_has(lines, "• Turns — no limit. It ends when the questions run out.")

	var energy := ""
	for line: String in lines:
		if line.begins_with("• Energy"):
			energy = line
	assert_string_contains(energy, "6 for the whole thing")
	assert_string_contains(energy, "spend them as a budget")


func test_each_kind_of_room_says_how_winning_works() -> void:
	assert_eq(Text.say("brief.winning.score"),
		"there is nothing to reach. However high the support gets by the end "
		+ "is the result, and later stages draw on it.")
	assert_eq(Text.say("brief.winning.reset", {"count": 51, "unit": "seats"}),
		"51 seats wins the argument in front of you. The next one starts "
		+ "again from nothing, gaffes included.")
	assert_eq(Text.say("brief.winning.single", {"count": 51, "unit": "seats"}),
		"51 seats.")
