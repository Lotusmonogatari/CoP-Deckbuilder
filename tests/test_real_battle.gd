extends GutTest
## Plays real battles, on the real data, through the real setup path.
##
## Every other test file uses hand-written fixtures on purpose, so that
## rebalancing a card can't break the test suite. This one is the opposite,
## and it exists to catch a different class of problem: the wiring between
## the workbook and the rules engine.
##
## Fixtures would never notice a column renamed in the spreadsheet, an
## opponent removed, or a module step pointing at a stage that no longer
## exists. These tests would.
##
## They are deliberately loose about numbers. They assert that Module 01's
## floor debate can be set up and played to a finish — not that it takes any
## particular number of turns, which is a balance question and yours to
## change freely.

const MODULE := "MOD01"
const FLOOR_DEBATE_STEP := 4
const COMMITTEE_STEP := 2


func before_all() -> void:
	assert_true(DataDB.is_loaded(), "the game data loaded")
	assert_eq(DataDB.errors.size(), 0,
		"the data has no errors: %s" % [DataDB.errors])


# ---------------------------------------------------------------------------
# Setting a battle up from the workbook
# ---------------------------------------------------------------------------

func test_module_01s_floor_debate_can_be_set_up() -> void:
	var config := BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP)
	assert_false(config.is_empty(), "the module step was found")

	var stage: Dictionary = config["stage"]
	assert_eq(stage["stage_id"], "ST02")
	assert_eq(stage["bar_max"], 101, "the house has 101 seats")
	assert_eq(stage["win_threshold"], 51, "a majority is 51")

	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "the battle starts: %s" % [engine.setup_problems])
	assert_eq(engine.state.hand.size(), stage["hand_size"])
	assert_eq(engine.state.energy, stage["energy_per_turn"])


func test_the_starter_deck_comes_from_the_workbook() -> void:
	var deck := BattleSetup.starter_deck()
	assert_gt(deck.size(), 0, "there are Starter-tier cards")

	# Nothing here is invented: every card in the deck is a real card.
	for card_id: String in deck:
		var card := DataDB.get_card(card_id)
		assert_false(card.is_empty(), "%s is a real card" % card_id)
		assert_eq(card["tier"], "Starter", "%s is a starter card" % card_id)


func test_every_module_step_can_be_set_up() -> void:
	# The check that would catch a module row pointing at something deleted.
	for row: Dictionary in DataDB.get_module_steps(MODULE):
		if row.get("mode") != "Combat":
			continue   # office hours is not a battle

		var seq := int(row["seq"])
		var config := BattleSetup.from_row(row)
		assert_false(config.is_empty(), "step %d built a config" % seq)

		var engine := BattleEngine.new()
		assert_true(engine.setup(config),
			"step %d (%s) starts: %s" % [seq, row.get("stage_id"), engine.setup_problems])


func test_the_committee_stage_gets_its_members() -> void:
	var config := BattleSetup.for_module_step(MODULE, COMMITTEE_STEP)
	assert_true(config.has("committee_members"), "members were fetched")
	assert_gt((config["committee_members"] as Array).size(), 0)

	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "%s" % [engine.setup_problems])
	assert_true(engine.state.is_committee_stage())


# ---------------------------------------------------------------------------
# Playing one through
# ---------------------------------------------------------------------------

## Plays a whole battle with a simple strategy: spend all the energy you can
## each turn, then end the turn. Returns the finished state.
func _play_out(config: Dictionary, max_turns: int = 40) -> BattleState:
	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "%s" % [engine.setup_problems])

	var safety := 0
	while not engine.state.is_over() and safety < max_turns:
		safety += 1

		# Play whatever is affordable, cheapest first, until nothing is.
		var played_something := true
		while played_something and not engine.state.is_over():
			played_something = false
			for card_id: String in engine.state.hand.duplicate():
				var card := DataDB.get_card(card_id)
				if int(card.get("cost", 0)) <= engine.state.energy:
					if engine.play_card(card_id).get("ok", false):
						played_something = true
						break

		if not engine.state.is_over():
			engine.end_turn()

	assert_lt(safety, max_turns, "the battle finished rather than running forever")
	return engine.state


func test_a_floor_debate_plays_to_a_finish() -> void:
	var state := _play_out(BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP))

	assert_true(state.is_over(), "the battle ended")
	assert_true(["win", "loss", "retry"].has(state.outcome),
		"with a real outcome, not '%s'" % state.outcome)
	assert_false(state.outcome_reason.is_empty(), "and a reason a player could read")


func test_the_seats_still_add_up_after_a_whole_battle() -> void:
	# The shared pool's one unbreakable rule, checked against real data after
	# a full game rather than a handful of operations.
	var state := _play_out(BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP))

	assert_not_null(state.bar)
	assert_true(state.bar.totals_balance(),
		"player %d + opponent %d + undecided %d should be %d"
			% [state.bar.player, state.bar.opponent, state.bar.undecided, state.bar.maximum])


func test_a_battle_can_be_won() -> void:
	# Stacked in the player's favour so the win path is genuinely exercised,
	# rather than assuming it works because the loss path does.
	var config := BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP)
	var stage: Dictionary = (config["stage"] as Dictionary).duplicate(true)
	stage["player_start"] = 50      # one seat short of a majority
	config["stage"] = stage

	var state := _play_out(config)
	assert_eq(state.outcome, "win", state.outcome_reason)


func test_a_battle_can_be_lost_on_gaffes() -> void:
	var config := BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP)
	var stage: Dictionary = (config["stage"] as Dictionary).duplicate(true)
	stage["gaffe_limit"] = 1        # the very first gaffe ends it
	config["stage"] = stage

	# A deck of nothing but gaffe-prone cards, so one is certain to be played.
	config["deck"] = ["C17", "C17", "C17", "C21", "C21", "C22"]

	var state := _play_out(config)
	assert_eq(state.outcome, "loss")
	assert_string_contains(state.outcome_reason, "gaffe")


func test_the_opponent_actually_does_something() -> void:
	# OP03 has no pattern of their own yet, so this also proves the default
	# from rules.json reaches a real battle rather than only the fixtures.
	var config := BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP)
	var engine := BattleEngine.new()
	engine.setup(config)

	assert_true(engine.used_default_intent_pattern,
		"OP03 has no pattern yet, so the shared default is in use")

	var intent := engine.current_intent()
	assert_true(IntentRunner.KNOWN_VERBS.has(intent["verb"]),
		"the opponent intends something real: %s" % [intent])
	assert_false(IntentRunner.describe(intent).is_empty(),
		"and it can be put into words for the player")


# ---------------------------------------------------------------------------
# The playtest level's caucus, on its real data
# ---------------------------------------------------------------------------
# The engine tests prove the pool and the scoring rules in isolation. These
# prove the actual stage in data/playtest_level.json is wired to use them,
# and that the score it produces really does reach the floor debate.

func _playtest_stage(stage_id: String) -> Dictionary:
	for stage: Dictionary in DataDB.playtest_level.get("stages", []):
		if stage.get("stage_id") == stage_id:
			return stage
	return {}


func test_the_caucus_stage_hands_out_one_pool_of_energy() -> void:
	var engine := BattleEngine.new()
	assert_true(engine.setup(BattleSetup.for_playtest_stage(_playtest_stage("PT_S3"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.energy, 5, "five for the whole debate")
	assert_eq(engine.state.energy_mode, "pool")

	engine.state.energy = 1
	engine.end_turn()
	assert_eq(engine.state.energy, 1, "and no more arrive with the new turn")


func test_the_caucus_is_scored_rather_than_won() -> void:
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(_playtest_stage("PT_S3")))

	# Push the support far past anything that could count as a threshold.
	engine.state.bar.player_gains(50)
	assert_false(engine.state.is_over(), "no total ends the caucus early")

	for _index in 4:
		if not engine.state.is_over():
			engine.end_turn()

	assert_true(engine.state.is_over(), "it ends when the turns run out")
	assert_eq(engine.state.outcome, "win", "running out of turns is not a loss here")
	assert_string_contains(engine.state.outcome_reason, "caucus closed".to_lower())


func test_a_good_caucus_reaches_the_floor_debate() -> void:
	# The whole reason the caucus is scored: a strong showing there should be
	# worth something later. This follows one score all the way through.
	var runner := LevelRunner.new(DataDB.playtest_level)
	runner.finish_stage(LevelRunner.WON)            # committee
	runner.finish_stage(LevelRunner.WON)            # press conference
	runner.finish_stage(LevelRunner.WON, 80)        # caucus, scored 80

	var stage := runner.current_stage()
	assert_eq(stage["stage_id"], "PT_S4", "now on the floor debate")

	var buffs := runner.carried_buffs()
	assert_gt(int(buffs["support_bonus"]), 0, "the caucus score is worth something")

	var config := BattleSetup.for_playtest_stage(stage, buffs)
	var engine := BattleEngine.new()
	assert_true(engine.setup(config), "%s" % [engine.setup_problems])

	var base := int(stage["player_start"])
	assert_eq(engine.state.bar.player, base + int(buffs["support_bonus"]),
		"the floor debate starts that much further ahead")


func test_a_weak_caucus_costs_nothing_at_the_floor() -> void:
	var runner := LevelRunner.new(DataDB.playtest_level)
	runner.finish_stage(LevelRunner.WON)
	runner.finish_stage(LevelRunner.WON)
	runner.finish_stage(LevelRunner.WON, 20)        # a poor caucus

	var stage := runner.current_stage()
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(stage, runner.carried_buffs()))

	assert_eq(engine.state.bar.player, int(stage["player_start"]),
		"a bad caucus is worth nothing, not a penalty")


# ---------------------------------------------------------------------------
# The playtest level's committee and floor debate, on their real data
# ---------------------------------------------------------------------------

func test_the_committee_lines_up_three_opponents() -> void:
	var engine := BattleEngine.new()
	assert_true(engine.setup(BattleSetup.for_playtest_stage(_playtest_stage("PT_S1"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.opponent_count, 3)
	assert_eq(engine.opponent_caption(), "1 of 3")
	assert_false(engine.state.is_committee_stage(),
		"three ordinary arguments, not the per-member voting model")


func test_winning_a_committee_bout_starts_the_next_one_clean() -> void:
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(_playtest_stage("PT_S1")))

	engine.state.gaffe = 4
	engine.state.bar.player_gains(engine.state.bar.threshold - engine.state.bar.player)
	engine._check_outcome()

	assert_false(engine.state.is_over(), "two opponents still to go")
	assert_eq(engine.opponent_caption(), "2 of 3")
	assert_eq(engine.state.gaffe, 0, "a clean slate for the next argument")


func test_the_floor_debate_lines_up_five_opponents() -> void:
	var engine := BattleEngine.new()
	assert_true(engine.setup(BattleSetup.for_playtest_stage(_playtest_stage("PT_S4"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.opponent_count, 5)
	assert_eq(engine.state.bar.maximum, 101, "the house still has 101 seats")
	assert_eq(engine.state.bar.threshold, 51, "and a majority is still 51")


func test_the_floor_debate_keeps_one_room_across_its_opponents() -> void:
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(_playtest_stage("PT_S4")))

	engine.state.bar.player_gains(5)
	var seats := engine.state.bar.player
	engine.state.turn = 7

	engine.state.bar.opponent_loses(engine.state.bar.opponent)
	engine._check_outcome()

	assert_eq(engine.opponent_caption(), "2 of 5")
	assert_eq(engine.state.bar.player, seats, "your seats survive the change")
	assert_eq(engine.state.turn, 7, "and so does the clock")
	assert_true(engine.state.bar.totals_balance())


func test_a_whole_floor_debate_can_be_played_out() -> void:
	var state := _play_out(BattleSetup.for_playtest_stage(_playtest_stage("PT_S4")), 60)
	assert_true(state.is_over())
	assert_true(state.bar.totals_balance(), "the house still adds up at the end")
