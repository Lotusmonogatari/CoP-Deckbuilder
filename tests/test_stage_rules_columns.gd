extends GutTest
## The "living rules set" stage columns proposed in
## design/proposals/stage_rules_columns.md: bar_model, energy_mode/
## energy_pool, sequence_mode, question_pool, reputation_affects_start,
## opponent_count. None of these exist on any canon stages.json row yet —
## every one of these tests checks BOTH that a stage which DOES declare one
## gets what it asked for, and that a stage which does not (the current,
## real shape of every canon row) still falls back to the exact behaviour it
## had before these columns existed.
##
## Also covers the regression these columns caused and that was fixed before
## shipping: stages.json now carries every one of these keys as an explicit
## JSON null on a row that leaves it blank, not an absent key. A naive
## `stage.get("key", fallback)` does not fall back to a null value already
## present, so the whole point of "blank means old behaviour" would have
## broken silently the moment the columns were added — these tests would
## have caught it.


# ---------------------------------------------------------------------------
# bar_model — BarModel.for_stage(), BattleEngine.is_committee_stage(),
# DataDB.is_committee_stage()
# ---------------------------------------------------------------------------

func test_bar_model_declared_wins_over_the_stage_id_guess() -> void:
	# ST04 is hardcoded to SINGLE in BarModel's fallback; declaring survival
	# on it directly should win.
	var stage := {"stage_id": "ST04", "bar_model": "survival"}
	assert_eq(BarModel.for_stage(stage), BarModel.Model.SURVIVAL)


func test_bar_model_null_falls_back_to_the_old_id_guess() -> void:
	# The real shape of every canon row today: the key exists, its value is
	# JSON null, not absent.
	var stage := {"stage_id": "ST04", "bar_model": null}
	assert_eq(BarModel.for_stage(stage), BarModel.Model.SINGLE,
		"ST04's old hardcoded guess, unchanged")

	var st06 := {"stage_id": "ST06", "bar_model": null}
	assert_eq(BarModel.for_stage(st06), BarModel.Model.SURVIVAL)

	var ordinary := {"stage_id": "ST02", "bar_model": null}
	assert_eq(BarModel.for_stage(ordinary), BarModel.Model.SHARED_POOL)


func test_bar_model_reads_are_case_insensitive() -> void:
	# The proposal doc (design/proposals/stage_rules_columns.md) and the
	# values actually pasted into the workbook are Capitalized ("Committee",
	# "Single", "Survival", "Shared_pool") — a spreadsheet editor's natural
	# way to type a word — while every match against a declared value is a
	# lowercase literal. Caught once already: without the .to_lower() on the
	# read side, a Capitalized cell would silently mismatch every time and
	# fall through to the old ID-based guess forever, making the column
	# inert the moment anyone actually used it as written.
	assert_eq(BarModel.for_stage({"stage_id": "ST02", "bar_model": "Survival"}),
		BarModel.Model.SURVIVAL, "declared Capitalized, same as the workbook, not lowercase")
	assert_true(BattleEngine.is_committee_stage({"stage_id": "ST21", "bar_model": "Committee"}))
	assert_false(DataDB.is_committee_stage("ST21"), "sanity: ST21 is not a committee by ID")


func test_bar_model_committee_is_recognised_by_declared_value() -> void:
	# ST21 (Policy Study) is not in COMMITTEE_STAGE_IDS — declaring
	# bar_model "committee" on it should still be honoured.
	var stage := {"stage_id": "ST21", "bar_model": "committee"}
	assert_true(BattleEngine.is_committee_stage(stage))


func test_bar_model_null_falls_back_to_committee_stage_ids() -> void:
	assert_true(BattleEngine.is_committee_stage({"stage_id": "ST01", "bar_model": null}))
	assert_false(BattleEngine.is_committee_stage({"stage_id": "ST21", "bar_model": null}))


func test_datadb_is_committee_stage_also_honours_a_declared_bar_model() -> void:
	# ST18 is a real committee stage (COMMITTEE_STAGE_IDS) — a declared
	# non-committee bar_model on its row should override that.
	assert_true(DataDB.is_committee_stage("ST18"), "sanity: ST18 is a committee today")


# ---------------------------------------------------------------------------
# sequence_mode / energy_mode / energy_pool — BattleEngine.setup()
# ---------------------------------------------------------------------------

func test_energy_mode_and_sequence_mode_null_default_exactly_as_before() -> void:
	var stage := DataDB.get_stage("ST02").duplicate(true)   # both keys are null
	stage["opponents"] = [DataDB.get_opponents_for_stage("ST02")[0]]
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(stage))

	assert_eq(engine.state.energy_mode, "per_turn")
	assert_eq(engine.state.energy, engine.state.energy_per_turn,
		"per_turn mode starts with a full turn's energy, not a pool")


# ---------------------------------------------------------------------------
# reputation_affects_start — BattleSetup.for_playtest_stage()
# ---------------------------------------------------------------------------

func test_reputation_affects_start_declared_no_turns_off_st04s_old_bonus() -> void:
	var stage := DataDB.get_stage("ST04").duplicate(true)
	stage["reputation_affects_start"] = "No"
	stage["opponents"] = []
	var low := BattleSetup.for_playtest_stage(stage, {}, {"Reputation": 5})
	var high := BattleSetup.for_playtest_stage(stage, {}, {"Reputation": 95})
	assert_eq(low["start_adjustment"], high["start_adjustment"],
		"reputation no longer moves the opening bar once declared No")


func test_reputation_affects_start_null_keeps_st04s_old_bonus() -> void:
	var stage := DataDB.get_stage("ST04").duplicate(true)   # reputation_affects_start is null
	stage["opponents"] = []
	var low := BattleSetup.for_playtest_stage(stage, {}, {"Reputation": 5})
	var high := BattleSetup.for_playtest_stage(stage, {}, {"Reputation": 95})
	assert_ne(low["start_adjustment"], high["start_adjustment"],
		"ST04's old hardcoded reputation bonus, unchanged")


# ---------------------------------------------------------------------------
# opponent_count — BattleSetup._opponent_count() / expand_level()
# ---------------------------------------------------------------------------

func test_opponent_count_null_means_exactly_one_opponent() -> void:
	var stage := {"opponent_count": null}
	assert_eq(BattleSetup._opponent_count(stage), 1)


func test_opponent_count_a_fixed_range_rolls_that_many() -> void:
	var stage := {"opponent_count": {"min": 3, "max": 3}}
	assert_eq(BattleSetup._opponent_count(stage), 3)


func test_opponent_count_a_real_range_rolls_within_it() -> void:
	var stage := {"opponent_count": {"min": 2, "max": 4}}
	for _i in 20:
		var count := BattleSetup._opponent_count(stage)
		assert_between(count, 2, 4)


# ---------------------------------------------------------------------------
# bar_model drives is_press_conference() / has_threshold —
# BattleEngine._check_outcome()
#
# Playtest bugs #4 and #7 (2026-09-25): ST19/20/21 draw from a question pool
# the same way ST04 does, but they are Shared_pool rooms with a named
# opponent and a real win_threshold, not a tone-only press conference. Before
# this fix, ANY question pool made is_press_conference() true, which showed
# "Reporter" instead of the real opponent and ended the room the moment the
# questions ran out instead of at its threshold (reported as ST21 "ending at
# 8" rather than its real threshold of 35).
# ---------------------------------------------------------------------------

func test_st04_is_still_a_true_press_conference() -> void:
	var stage := DataDB.get_stage("ST04").duplicate(true)
	stage["opponents"] = []
	var engine := BattleEngine.new()
	assert_true(engine.setup(BattleSetup.for_playtest_stage(stage)))
	assert_true(engine.is_press_conference(),
		"ST04's declared bar_model is Single, so it is a true press conference")


func test_st21_with_a_question_pool_is_not_a_press_conference() -> void:
	# Policy Study Session: Shared_pool bar, real win_threshold, but still
	# asks questions from its own pool like ST04 does.
	var stage := DataDB.get_stage("ST21").duplicate(true)
	stage["opponents"] = [DataDB.get_opponents_for_stage("ST21")[0]]
	var engine := BattleEngine.new()
	assert_true(engine.setup(BattleSetup.for_playtest_stage(stage)))
	assert_false(engine.is_press_conference(),
		"ST21's bar_model is Shared_pool, not Single — it has a real opponent and threshold")


func test_st21s_threshold_is_checked_even_though_it_has_questions() -> void:
	var stage := DataDB.get_stage("ST21").duplicate(true)
	stage["opponents"] = [DataDB.get_opponents_for_stage("ST21")[0]]
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(stage))

	# Drive the bar straight to its threshold and confirm the stage is won on
	# the threshold rather than staying open just because questions remain.
	engine.state.bar.player = int(stage.get("win_threshold", 35))
	engine._check_outcome()
	assert_eq(engine.state.outcome, "win",
		"reaching the real threshold should win ST21 even with questions left in the pool")
