extends GutTest
## Tests for the level runner: the thing that walks you through a level's
## stages and carries what each one produced into the next.


func _level(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"level_id": "TEST",
		"stages": [
			{"seq": 1, "name_en": "First", "opponents": [{"opp_id": "A"}]},
			{"seq": 2, "name_en": "Second", "opponents": [{"opp_id": "B"}]},
			{"seq": 3, "name_en": "Third", "opponents": [{"opp_id": "C"}],
			 "carries_buffs_from": [1, 2]},
		],
	}
	base.merge(overrides, true)
	return base


func _runner(overrides: Dictionary = {}) -> LevelRunner:
	return LevelRunner.new(_level(overrides))


# ---------------------------------------------------------------------------
# Order
# ---------------------------------------------------------------------------

func test_a_level_starts_on_its_first_stage() -> void:
	var runner := _runner()
	assert_eq(runner.current_stage()["name_en"], "First")
	assert_eq(runner.stage_count(), 3)
	assert_false(runner.is_finished())


func test_stages_are_played_in_seq_order_however_they_are_listed() -> void:
	# Order comes from the seq number, not from where a stage happens to sit
	# in the file, so reordering the file cannot silently reorder the level.
	var runner := _runner({"stages": [
		{"seq": 3, "name_en": "Third", "opponents": [{"opp_id": "C"}]},
		{"seq": 1, "name_en": "First", "opponents": [{"opp_id": "A"}]},
		{"seq": 2, "name_en": "Second", "opponents": [{"opp_id": "B"}]},
	]})

	assert_eq(runner.current_stage()["name_en"], "First")
	runner.finish_stage(LevelRunner.WON)
	assert_eq(runner.current_stage()["name_en"], "Second")
	runner.finish_stage(LevelRunner.WON)
	assert_eq(runner.current_stage()["name_en"], "Third")


func test_winning_every_stage_wins_the_level() -> void:
	var runner := _runner()
	for _index in 3:
		runner.finish_stage(LevelRunner.WON)

	assert_true(runner.is_finished())
	assert_eq(runner.outcome(), LevelRunner.WON)


func test_losing_a_stage_ends_the_level_there() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON)
	runner.finish_stage(LevelRunner.LOST)

	assert_true(runner.is_finished(), "the level is over")
	assert_eq(runner.outcome(), LevelRunner.LOST)


func test_nothing_moves_once_the_level_is_over() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.LOST)
	var before := runner.index

	runner.finish_stage(LevelRunner.WON)
	assert_eq(runner.index, before, "finishing a stage after the end does nothing")


## Stand-in wording, so these tests check the COUNTING rather than Cameron's
## phrasing. The real sentences are pinned once, in test_text.gd.
const RUNNER_WORDS := {
	"caption.stage": "{number}/{total}",
	"carried.went_well": "{name} well +{count}",
	"carried.went_badly": "{name} badly -{count}",
	"carried.pleased": "pleased {names}",
	"carried.nothing": "nothing carried",
	"reward.by_finish": "{name} above {baseline}, 1 per {per}",
	"reward.head_start": "head start 1 per {per} above {baseline}",
	"reward.standing": "standing",
}


func _words() -> Phrase:
	return Phrase.new(RUNNER_WORDS)


func test_the_progress_caption_reads_correctly() -> void:
	var runner := _runner()
	assert_eq(runner.progress_caption(_words()), "1/3")
	runner.finish_stage(LevelRunner.WON)
	assert_eq(runner.progress_caption(_words()), "2/3")


func test_the_caption_does_not_overrun_at_the_end() -> void:
	var runner := _runner()
	for _index in 3:
		runner.finish_stage(LevelRunner.WON)
	assert_eq(runner.progress_caption(_words()), "3/3", "not '4/3'")


# ---------------------------------------------------------------------------
# What stages leave behind
# ---------------------------------------------------------------------------

func test_a_stage_that_asks_for_nothing_carries_nothing() -> void:
	var runner := _runner()
	var buffs := runner.carried_buffs()
	assert_eq(buffs["support_bonus"], 0)
	assert_eq(buffs["boosters"], [])


func test_a_good_score_earlier_becomes_a_head_start_later() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON, 70)     # stage 1, scored 70
	runner.finish_stage(LevelRunner.WON)         # stage 2

	# Stage 3 draws on both. 70 is 20 above halfway, worth 2.
	assert_eq(runner.carried_buffs()["support_bonus"], 2)


func test_a_poor_score_is_worth_nothing_rather_than_a_penalty() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON, 30)
	runner.finish_stage(LevelRunner.WON)

	assert_eq(runner.carried_buffs()["support_bonus"], 0,
		"a bad caucus should not actively punish you")


func test_pleased_organisations_are_carried_forward() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON, 0, ["BO08"])
	runner.finish_stage(LevelRunner.WON, 0, ["BO03", "BO05"])

	var carried: Array = runner.carried_buffs()["boosters"]
	assert_eq(carried.size(), 3)
	for booster_id: String in ["BO08", "BO03", "BO05"]:
		assert_true(carried.has(booster_id), "%s carried forward" % booster_id)


func test_the_same_organisation_is_not_counted_twice() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON, 0, ["BO08"])
	runner.finish_stage(LevelRunner.WON, 0, ["BO08"])

	assert_eq((runner.carried_buffs()["boosters"] as Array).size(), 1)


func test_only_the_named_stages_are_carried() -> void:
	# Stage 2 asks for nothing, so stage 1's score must not reach it.
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON, 90)
	assert_eq(runner.carried_buffs()["support_bonus"], 0,
		"stage 2 did not ask to carry anything")


func test_carried_buffs_are_described_in_plain_words() -> void:
	var runner := _runner()
	runner.finish_stage(LevelRunner.WON, 80, ["BO08"])
	runner.finish_stage(LevelRunner.WON)

	var description := runner.describe_carried_buffs({}, _words())
	assert_string_contains(description, "First",
		"and says WHICH stage went well, not just that something did")
	assert_string_contains(description, "+3")
	assert_string_contains(description, "BO08")
	assert_true(runner.anything_carried(),
		"and says so without the screen having to read the sentence")


func test_nothing_carried_says_so_rather_than_being_blank() -> void:
	assert_eq(_runner().describe_carried_buffs({}, _words()), "nothing carried")
	assert_false(_runner().anything_carried(),
		"THE BUG THIS COVERS: the screens used to work this out by checking "
		+ "whether the sentence began with the word Nothing")


# ---------------------------------------------------------------------------
# Rejecting a broken level
# ---------------------------------------------------------------------------

func test_a_good_level_is_accepted() -> void:
	assert_true(_runner().is_valid())


func test_a_level_with_no_stages_is_rejected() -> void:
	var runner := _runner({"stages": []})
	assert_false(runner.is_valid())
	assert_string_contains(runner.problems()[0], "no stages")


func test_two_stages_claiming_the_same_position_are_rejected() -> void:
	var runner := _runner({"stages": [
		{"seq": 1, "opponents": [{"opp_id": "A"}]},
		{"seq": 1, "opponents": [{"opp_id": "B"}]},
	]})
	assert_false(runner.is_valid())
	assert_string_contains(runner.problems()[0], "seq 1")


func test_a_stage_with_nothing_pushing_back_is_rejected() -> void:
	var runner := _runner({"stages": [{"seq": 1, "opponents": []}]})
	assert_false(runner.is_valid())
	assert_string_contains(runner.problems()[0], "neither opponents nor questions")


func test_a_press_conference_needs_questions_rather_than_opponents() -> void:
	# The press conference has no opponent: the reporters' questions are what
	# pushes back. A stage with questions and nobody to debate is correct.
	var runner := _runner({"stages": [
		{"seq": 1, "opponents": [], "questions": [{"id": "Q1"}]},
	]})
	assert_true(runner.is_valid(), "%s" % [runner.problems()])


# ---------------------------------------------------------------------------
# The real playtest level
# ---------------------------------------------------------------------------

func test_the_playtest_level_on_disk_is_usable() -> void:
	# Catches a typo in data/playtest_level.json before it reaches a player.
	var runner := LevelRunner.new(DataDB.playtest_level)
	assert_true(runner.is_valid(), "%s" % [runner.problems()])
	assert_eq(runner.stage_count(), 4, "hub, then four stages")


func test_the_playtest_level_can_be_walked_end_to_end() -> void:
	var runner := LevelRunner.new(DataDB.playtest_level)
	var names: Array[String] = []

	while not runner.is_finished():
		names.append(str(runner.current_stage().get("name_en")))
		runner.finish_stage(LevelRunner.WON, 60)

	assert_eq(runner.outcome(), LevelRunner.WON)
	# The caucus is named after the player's party, resolved by DataDB when
	# the level loads — so this reads whatever party.json settles on rather
	# than a fixed string.
	assert_eq(names, ["Committee", "Press Conference",
		"%s Caucus" % DataDB.player.get("party", ""), "Parliament Floor Debate"])


func test_a_stage_knows_whether_anybody_carries_its_score() -> void:
	# A stage whose score nobody draws on must not tell the player it was
	# worth something later.
	var runner := LevelRunner.new(DataDB.playtest_level)

	assert_false(runner.score_is_carried_from(1), "nothing carries the committee")
	assert_true(runner.score_is_carried_from(2), "the floor carries the press conference")
	assert_true(runner.score_is_carried_from(3), "and the caucus")
	assert_false(runner.score_is_carried_from(4), "nothing comes after the floor")


# ---------------------------------------------------------------------------
# What a stage is worth
# ---------------------------------------------------------------------------
# Shared by the briefing before a level and the result panel after a stage,
# so the promise and the receipt cannot disagree.

func test_a_stage_reports_the_rewards_it_carries() -> void:
	# 2026-09-22: win_delta_kanban/win_delta_kaban were renamed
	# win_delta_reputation/win_delta_yen.
	var stage := {
		"win_delta_jiban": 4, "win_delta_reputation": -2,
		"win_delta_yen": 0, "win_delta_party_support": 3,
	}
	var rewards := LevelRunner.win_rewards(stage)

	assert_eq(rewards["Constituency support"], 4)
	assert_eq(rewards["Reputation"], -2, "a penalty is a reward that goes the other way")
	assert_eq(rewards["Party support"], 3)
	assert_false(rewards.has("Funds"), "a variable this stage does not touch is not news")


func test_a_stage_with_no_numbers_set_says_so_rather_than_showing_zeroes() -> void:
	# Every playtest stage is in this state on purpose, waiting on Cameron.
	# Four zeroes would read as "this level is worthless".
	assert_true(LevelRunner.rewards_are_unset({
		"win_delta_jiban": 0, "win_delta_reputation": 0,
		"win_delta_yen": 0, "win_delta_party_support": 0, "win_delta_xp": 0,
	}))


func test_a_stage_with_any_number_set_is_not_unset() -> void:
	assert_false(LevelRunner.rewards_are_unset({"win_delta_yen": 1}))
	assert_false(LevelRunner.rewards_are_unset({"win_delta_xp": 20}))
	assert_false(LevelRunner.rewards_are_unset({"tone_effects": {"baseline": 50}}),
		"a stage whose worth depends on its score is not an empty one")


func test_a_variable_reward_is_described_rather_than_forecast() -> void:
	# Cameron asked the briefing for static values. What a press conference
	# is worth depends on the tone it closes on, so a number here would be a
	# guess presented as a promise.
	var lines := LevelRunner.variable_rewards({
		"tone_effects": {"baseline": 50, "support_per_points": 10,
			"meta": {"Reputation": 5}},
	}, _words())
	var joined := "\n".join(lines)

	assert_string_contains(joined, "Reputation")
	assert_string_contains(joined, "1 per 5")
	assert_string_contains(joined, "head start")


func test_the_real_playtest_stages_have_reward_slots_waiting() -> void:
	# The slots exist in the data with zeroes in them, so the moment a
	# number stops being 0 it lands without any code change.
	for stage: Dictionary in DataDB.playtest_level.get("stages", []):
		assert_true(stage.has("win_delta_jiban"),
			"%s needs a slot for Cameron's numbers" % stage.get("stage_id"))
		assert_true(stage.has("xp_reward"),
			"%s needs an XP slot" % stage.get("stage_id"))
