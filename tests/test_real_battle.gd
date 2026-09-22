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

## 2026-09-22 workbook: the old Modules sheet (MOD01, with numbered steps) is
## gone — a level's stages are levels.json's own flat stage_1..stage_10 now.
## LV06 and LV09 are two of the 30 real levels that happen to carry the two
## stage shapes these tests care about: a floor debate (ST02) and a committee
## (ST01). Picked for what they contain, not because either is special.
const FLOOR_DEBATE_LEVEL := "LV06"
const FLOOR_DEBATE_STAGE := "ST02"
const COMMITTEE_LEVEL := "LV09"
const COMMITTEE_STAGE := "ST01"


## Every battle in this file is set up through here, so the shuffle is the
## same on every run.
##
## Without a fixed seed these tests deal a different hand each time: a
## failure could not be reproduced and a pass would guarantee nothing. The
## number itself is arbitrary.
const SHUFFLE_SEED := 20260919


func _setup(engine: BattleEngine, config: Dictionary) -> bool:
	config["seed"] = SHUFFLE_SEED
	return engine.setup(config)


func before_all() -> void:
	assert_true(DataDB.is_loaded(), "the game data loaded")
	assert_eq(DataDB.errors.size(), 0,
		"the data has no errors: %s" % [DataDB.errors])


# ---------------------------------------------------------------------------
# Setting a battle up from the workbook
# ---------------------------------------------------------------------------

func test_a_real_levels_floor_debate_can_be_set_up() -> void:
	var config := BattleSetup.for_level_stage(FLOOR_DEBATE_LEVEL, FLOOR_DEBATE_STAGE)
	assert_false(config.is_empty(), "the level's stage was found")

	var stage: Dictionary = config["stage"]
	assert_eq(stage["stage_id"], "ST02")
	assert_eq(stage["bar_max"], 101, "the house has 101 seats")
	assert_eq(stage["win_threshold"], 51, "a majority is 51")

	var engine := BattleEngine.new()
	assert_true(_setup(engine, config), "the battle starts: %s" % [engine.setup_problems])
	assert_eq(engine.state.hand.size(), stage["hand_size"])
	assert_eq(engine.state.energy, stage["energy_per_turn"])


func test_the_starter_deck_comes_from_the_workbook() -> void:
	var deck := BattleSetup.starter_deck()
	assert_gt(deck.size(), 0, "there are Starter-tier cards")

	# Nothing here is invented: every card in the deck is a real card.
	for card_id: String in deck:
		var card := DataDB.get_card(card_id)
		assert_false(card.is_empty(), "%s is a real card" % card_id)
		assert_eq(card["tier"], Ledger.OPENING_TIER, "%s is an opening-tier card" % card_id)


func test_every_real_level_can_be_set_up() -> void:
	# The check that would catch a level naming a stage that no longer
	# exists, or a combat stage nothing is eligible to fight.
	var checked := 0
	for level: Dictionary in DataDB.levels:
		var expanded := BattleSetup.expand_level(level)
		for stage: Dictionary in expanded.get("stages", []):
			if str(stage.get("mode", "")) != "Combat":
				continue   # office hours is not a battle
			checked += 1

			var config := BattleSetup.for_playtest_stage(stage)
			assert_false(config.is_empty(), "%s's %s built a config"
				% [level.get("level_id"), stage.get("stage_id")])

			var engine := BattleEngine.new()
			assert_true(_setup(engine, config),
				"%s's %s starts: %s" % [level.get("level_id"), stage.get("stage_id"), engine.setup_problems])

	assert_gt(checked, 0, "there are combat stages across the real levels to check")


func test_a_committee_stage_gets_its_members() -> void:
	var config := BattleSetup.for_level_stage(COMMITTEE_LEVEL, COMMITTEE_STAGE)
	assert_true(config.has("committee_members"), "members were fetched")
	assert_gt((config["committee_members"] as Array).size(), 0)

	var engine := BattleEngine.new()
	assert_true(_setup(engine, config), "%s" % [engine.setup_problems])
	assert_true(engine.state.is_committee_stage())


# ---------------------------------------------------------------------------
# Playing one through
# ---------------------------------------------------------------------------

## Plays a whole battle with a simple strategy: spend all the energy you can
## each turn, then end the turn. Returns the finished state.
func _play_out(config: Dictionary, max_turns: int = 40) -> BattleState:
	var engine := BattleEngine.new()
	assert_true(_setup(engine, config), "%s" % [engine.setup_problems])

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
	var state := _play_out(BattleSetup.for_level_stage(FLOOR_DEBATE_LEVEL, FLOOR_DEBATE_STAGE))

	assert_true(state.is_over(), "the battle ended")
	assert_true(["win", "loss", "retry"].has(state.outcome),
		"with a real outcome, not '%s'" % state.outcome)
	assert_false(state.outcome_reason.is_empty(), "and a reason a player could read")


func test_the_seats_still_add_up_after_a_whole_battle() -> void:
	# The shared pool's one unbreakable rule, checked against real data after
	# a full game rather than a handful of operations.
	var state := _play_out(BattleSetup.for_level_stage(FLOOR_DEBATE_LEVEL, FLOOR_DEBATE_STAGE))

	assert_not_null(state.bar)
	assert_true(state.bar.totals_balance(),
		"player %d + opponent %d + undecided %d should be %d"
			% [state.bar.player, state.bar.opponent, state.bar.undecided, state.bar.maximum])


func test_a_battle_can_be_won() -> void:
	# Stacked in the player's favour so the win path is genuinely exercised,
	# rather than assuming it works because the loss path does.
	var config := BattleSetup.for_level_stage(FLOOR_DEBATE_LEVEL, FLOOR_DEBATE_STAGE)
	var stage: Dictionary = (config["stage"] as Dictionary).duplicate(true)
	stage["player_start"] = 50      # one seat short of a majority
	config["stage"] = stage

	var state := _play_out(config)
	assert_eq(state.outcome, "win", state.outcome_reason)


func test_a_battle_can_be_lost_on_gaffes() -> void:
	var config := BattleSetup.for_level_stage(FLOOR_DEBATE_LEVEL, FLOOR_DEBATE_STAGE)
	var stage: Dictionary = (config["stage"] as Dictionary).duplicate(true)
	stage["gaffe_limit"] = 1        # the very first gaffe ends it
	config["stage"] = stage

	# A deck of nothing but gaffe-prone cards, so one is certain to be played.
	config["deck"] = ["C17", "C17", "C17", "C21", "C21", "C22"]

	var state := _play_out(config)
	assert_eq(state.outcome, "loss")
	assert_string_contains(state.outcome_reason, "gaffe")


func test_the_opponent_actually_does_something() -> void:
	# The opponent this level's floor debate dynamically picks (the lowest
	# opp_id eligible for ST02 — see BattleSetup._opponent_for()) carries
	# their own intent_*_range columns, which DataDB.get_opponent() turns
	# into a real pattern. If that stopped working, this is where it would
	# show up: the opponent would quietly fall back to the shared default
	# and play like everybody else.
	var config := BattleSetup.for_level_stage(FLOOR_DEBATE_LEVEL, FLOOR_DEBATE_STAGE)
	var engine := BattleEngine.new()
	_setup(engine, config)

	assert_false(engine.used_default_intent_pattern,
		"a real opponent's own ranges are used, so the shared default is not needed")
	assert_false((config["opponent"]["intent_pattern"] as Array).is_empty(),
		"and a real pattern was built from their ranges")

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
	assert_true(_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S3"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.energy, 5, "five for the whole debate")
	assert_eq(engine.state.energy_mode, "pool")

	engine.state.hand.assign(["C01"])
	engine.play_card("C01")          # so the turn is not a pass
	engine.state.energy = 1
	engine.end_turn()
	assert_eq(engine.state.energy, 1, "and no more arrive with the new turn")


func test_the_caucus_is_scored_rather_than_won() -> void:
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S3")))

	# Push the support far past anything that could count as a threshold.
	engine.state.bar.player_gains(50)
	assert_false(engine.state.is_over(), "no total ends the caucus early")

	for _index in 4:
		if not engine.state.is_over():
			engine.end_turn()

	assert_true(engine.state.is_over(), "it ends when the turns run out")
	assert_eq(engine.state.outcome, "win", "running out of turns is not a loss here")
	# Named from the stage, not from the word "caucus": three kinds of stage
	# are scored, and this line used to claim all three were caucuses.
	var stage := _playtest_stage("PT_S3")
	assert_string_contains(engine.state.outcome_reason,
		"%s closed on" % stage.get("name_en", ""))


func test_a_good_caucus_reaches_the_floor_debate() -> void:
	# The whole reason the caucus is scored: a strong showing there should be
	# worth something later. This follows one score all the way through.
	var runner := LevelRunner.new(DataDB.playtest_level)
	runner.finish_stage(LevelRunner.WON)            # committee
	runner.finish_stage(LevelRunner.WON, 50)        # press conference, flat
	runner.finish_stage(LevelRunner.WON, 80)        # caucus, scored 80

	var stage := runner.current_stage()
	assert_eq(stage["stage_id"], "PT_S4", "now on the floor debate")

	var buffs := runner.carried_buffs()
	assert_gt(int(buffs["support_bonus"]), 0, "the caucus score is worth something")

	var config := BattleSetup.for_playtest_stage(stage, buffs)
	var engine := BattleEngine.new()
	assert_true(_setup(engine, config), "%s" % [engine.setup_problems])

	var base := int(stage["player_start"])
	assert_eq(engine.state.bar.player, base + int(buffs["support_bonus"]),
		"the floor debate starts that much further ahead")


func test_a_weak_caucus_costs_nothing_at_the_floor() -> void:
	var runner := LevelRunner.new(DataDB.playtest_level)
	runner.finish_stage(LevelRunner.WON)
	runner.finish_stage(LevelRunner.WON, 50)        # press conference, flat
	runner.finish_stage(LevelRunner.WON, 20)        # a poor caucus

	var stage := runner.current_stage()
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(stage, runner.carried_buffs()))

	assert_eq(engine.state.bar.player, int(stage["player_start"]),
		"a bad caucus is worth nothing, not a penalty")


func test_a_bad_press_conference_costs_seats_at_the_floor() -> void:
	# The caucus forgives a poor showing; the press does not. This is the
	# difference between the two stages' tone_effects, on the real data.
	var runner := LevelRunner.new(DataDB.playtest_level)
	runner.finish_stage(LevelRunner.WON)
	runner.finish_stage(LevelRunner.WON, 20)        # tone 20: thirty below
	runner.finish_stage(LevelRunner.WON, 50)        # caucus, flat

	var stage := runner.current_stage()
	var buffs := runner.carried_buffs()
	assert_lt(int(buffs["support_bonus"]), 0, "a bad conference is a real debuff")

	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(stage, buffs))

	assert_lt(engine.state.bar.player, int(stage["player_start"]),
		"the floor debate starts that much further behind")


func test_a_good_press_conference_is_worth_seats_and_reputation() -> void:
	# Both halves of what the tone is for, from the one number.
	var press := _playtest_stage("PT_S2")

	assert_eq(LevelRunner.score_to_support(press, 70), 2,
		"twenty above the baseline is two seats")
	assert_eq(LevelRunner.score_to_support(press, 30), -2,
		"and twenty below costs two")
	assert_eq(LevelRunner.score_to_support(press, 45), 0,
		"falling just short costs nothing")

	var moved := MetaRules.apply_score_effects(
		{"Reputation": 50}, press, 70, DataDB.sanban)
	assert_eq(int(moved["applied"].get("Reputation", 0)), 4,
		"twenty above the baseline, at five points each, is four reputation")


# ---------------------------------------------------------------------------
# The playtest level's committee and floor debate, on their real data
# ---------------------------------------------------------------------------

func test_the_committee_lines_up_three_opponents() -> void:
	var engine := BattleEngine.new()
	assert_true(_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S1"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.opponent_count, 3)
	assert_eq(engine.opponent_caption(), "1 of 3")
	assert_false(engine.state.is_committee_stage(),
		"three ordinary arguments, not the per-member voting model")


func test_winning_a_committee_bout_starts_the_next_one_clean() -> void:
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S1")))

	engine.state.gaffe = 4
	engine.state.bar.player_gains(engine.state.bar.threshold - engine.state.bar.player)
	engine._check_outcome()

	assert_false(engine.state.is_over(), "two opponents still to go")
	assert_eq(engine.opponent_caption(), "2 of 3")
	assert_eq(engine.state.gaffe, 0, "a clean slate for the next argument")


func test_the_floor_debate_lines_up_five_opponents() -> void:
	var engine := BattleEngine.new()
	assert_true(_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S4"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.opponent_count, 5)
	assert_eq(engine.state.bar.maximum, 101, "the house still has 101 seats")
	assert_eq(engine.state.bar.threshold, 55,
		"55 to end the debater in front of you, not 55 to carry the bill")


func test_each_floor_debater_gets_their_own_division() -> void:
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S4")))

	var opened_on := engine.state.bar.player
	engine.state.bar.player_gains(5)
	engine.state.gaffe = 3
	engine.state.turn = 7

	engine.state.bar.opponent_loses(engine.state.bar.opponent)
	engine._check_outcome()

	assert_eq(engine.opponent_caption(), "2 of 5")
	assert_eq(engine.state.bar.player, opened_on, "the house divides again from the start")
	assert_eq(engine.state.gaffe, 3, "but your record follows you in")
	assert_eq(engine.state.turn, 7, "and so does the clock")
	assert_true(engine.state.bar.totals_balance())


func test_a_whole_floor_debate_can_be_played_out() -> void:
	var state := _play_out(BattleSetup.for_playtest_stage(_playtest_stage("PT_S4")), 60)
	assert_true(state.is_over())
	assert_true(state.bar.totals_balance(), "the house still adds up at the end")


# ---------------------------------------------------------------------------
# The playtest level's press conference, on its real data
# ---------------------------------------------------------------------------

func test_the_press_conference_deals_its_six_cards() -> void:
	var engine := BattleEngine.new()
	assert_true(_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S2"))),
		"%s" % [engine.setup_problems])

	assert_eq(engine.state.hand.size(), 6, "six cards to open with")
	assert_eq(engine.state.draw_mode, "none", "and no more after that")


func test_the_press_conference_has_its_questions_ready() -> void:
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S2")))

	assert_eq(engine.questions_remaining(), 5)
	assert_eq(engine.question_caption(), "Question 1 of 5")
	assert_false(str(engine.current_question().get("text", "")).is_empty(),
		"and the first one has something to ask")


func test_answering_every_question_ends_the_press_conference() -> void:
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S2")))

	var cards := BattleSetup.card_table()
	var guard := 0
	while not engine.state.is_over() and guard < 20:
		guard += 1
		if engine.state.hand.is_empty():
			break
		# Whatever is affordable, but nothing that would fill the gaffe
		# meter: this checks the questions run out, not that a careless
		# answer can end a conference early. That it can is tested in
		# test_battle_engine.gd.
		var answered := false
		for card_id: String in engine.state.hand.duplicate():
			var card: Dictionary = cards.get(card_id, {})
			if engine.state.gaffe + int(card.get("gaffe", 0)) >= engine.state.gaffe_limit:
				continue
			if engine.play_card(card_id).get("ok", false):
				answered = true
				break
		if not answered:
			engine.end_turn()

	assert_true(engine.state.is_over(), "the conference finished")
	assert_eq(engine.state.outcome, "win", "it is not a stage you lose on points")
	assert_eq(engine.questions_remaining(), 0, "because every question was answered")


func test_answering_in_the_invited_suit_pleases_the_press() -> void:
	# Deliberately not hardcoding which suit: the pairing of question to suit
	# is placeholder data Cameron is expected to change, and this should keep
	# testing the mechanism rather than his current choices.
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S2")))

	var question := engine.current_question()
	var wanted := str(question["prefers_suit"])

	var answer := ""
	for card: Dictionary in DataDB.get_cards_by_tier(Ledger.OPENING_TIER):
		if str(card.get("suit", "")) == wanted:
			answer = str(card["card_id"])
			break
	assert_false(answer.is_empty(), "a Starter card answers in %s" % wanted)

	engine.state.hand.assign([answer])
	engine.play_card(answer)

	assert_true(engine.pleased_boosters().has(question["pleases_booster"]),
		"answering in the suit invited pleases the people who asked")


func test_every_question_can_be_answered_in_the_suit_it_invites() -> void:
	# A question inviting a suit no Starter card has would be unanswerable
	# without it being obvious from the data. This catches that on Cameron's
	# next edit rather than in a playtest.
	var suits: Array[String] = []
	for card: Dictionary in DataDB.get_cards_by_tier(Ledger.OPENING_TIER):
		suits.append(str(card.get("suit", "")))

	for question: Dictionary in _playtest_stage("PT_S2").get("questions", []):
		assert_true(suits.has(str(question.get("prefers_suit", ""))),
			"%s invites %s, and no Starter card is that suit"
				% [question.get("id"), question.get("prefers_suit")])


func test_answering_well_carries_the_press_into_the_floor_debate() -> void:
	# The whole point of the stage: who you please in front of the cameras
	# is meant to be standing behind you on the floor three stages later.
	var runner := LevelRunner.new(DataDB.playtest_level)
	while int(runner.current_stage().get("seq", 0)) < 2:
		runner.finish_stage("win", 0, [])

	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(runner.current_stage()))

	# One Starter card of each suit, so every question can be answered the
	# way it asks to be.
	var by_suit := {
		"Earnest": "C01", "Emotional": "C06", "Appeal": "C10",
		"Data Driven": "C13", "Divisive": "C17", "Duplicitous": "C21",
	}

	var expected: Array[String] = []
	var guard := 0
	while not engine.state.is_over() and guard < 20:
		guard += 1
		var question := engine.current_question()
		if question.is_empty():
			break
		var card_id := str(by_suit.get(str(question.get("prefers_suit", "")), ""))
		assert_false(card_id.is_empty(),
			"no opening-tier card answers in %s" % question.get("prefers_suit"))

		# The answer, plus one card held back: a conference ends the moment
		# the player has nothing left to say, and this one is not finished.
		engine.state.hand.assign([card_id, "C02"])
		engine.state.energy = engine.state.energy_per_turn
		if engine.play_card(card_id).get("ok", false):
			expected.append(str(question.get("pleases_booster", "")))

		# One question a turn: the next reporter does not speak until this
		# turn is over. Ending it here answers each question in its own turn
		# rather than racing through the lot on the opening hand.
		if not engine.state.is_over() and engine.questions_remaining() > 0:
			engine.end_turn()

	assert_eq(engine.questions_remaining(), 0, "every question got an answer")

	# Through the level, not just out of the engine.
	runner.finish_stage(engine.state.outcome, engine.state.bar.player,
		engine.pleased_boosters())
	while int(runner.current_stage().get("seq", 0)) < 4 and not runner.is_finished():
		runner.finish_stage("win", 0, [])

	var carried: Array = runner.carried_buffs()["boosters"]
	for booster_id: String in expected:
		assert_true(carried.has(booster_id),
			"%s was pleased at the conference and should reach the floor" % booster_id)


# ---------------------------------------------------------------------------
# Who is in the room
# ---------------------------------------------------------------------------

func test_a_playtest_stage_borrows_the_room_it_is_modelled_on() -> void:
	# The playtest stages carry no audience mix of their own. Rather than
	# invent percentages, each borrows the canon stage it already names in
	# affinity_stage_id — the playtest press conference is modelled on ST04,
	# so it gets ST04's room.
	var press := BattleSetup.with_audience(_playtest_stage("PT_S2"))
	var mix: Dictionary = press.get("segment_mix", {})

	assert_false(mix.is_empty(), "the conference has a room")
	assert_eq(mix, DataDB.get_stage("ST04")["segment_mix"], "and it is ST04's")


func test_every_playtest_stage_has_somebody_in_the_room() -> void:
	for stage: Dictionary in DataDB.playtest_level["stages"]:
		var borrowed := BattleSetup.with_audience(stage)
		var mix: Dictionary = borrowed.get("segment_mix", {})
		assert_false(mix.is_empty(), "%s has an audience" % stage.get("stage_id"))

		# 2026-09-22 workbook: a canon stage's audience can include a
		# "% Other" share (pct_other) that isn't a segments.json row, the
		# same one DataDB.gd's own cross-check now counts — see its note.
		var total := float(borrowed.get("pct_other", 0.0))
		for share: float in mix.values():
			total += share
		assert_almost_eq(total, 1.0, 0.001,
			"%s's audience adds up to the whole room" % stage.get("stage_id"))


func test_a_stage_with_its_own_room_keeps_it() -> void:
	var declared := {"SG01": 1.0}
	var stage := _playtest_stage("PT_S2").duplicate(true)
	stage["segment_mix"] = declared

	assert_eq(BattleSetup.with_audience(stage)["segment_mix"], declared,
		"a stage that says who is in the room is not overruled")


func test_the_audience_reaches_the_cards() -> void:
	# The whole point of filling the mix in: a card aimed at one part of the
	# room used to read that audience as nought per cent of it.
	var engine := BattleEngine.new()
	_setup(engine, BattleSetup.for_playtest_stage(_playtest_stage("PT_S2")))

	# C21 Iridescent Answer is aimed at the Press, and a press conference is
	# mostly press.
	var share := CardResolver.segment_share(DataDB.get_card("C21"), engine._stage)
	assert_gt(share, 0.5, "the room is mostly who this card is aimed at")


# ---------------------------------------------------------------------------
# Standing with the organisations
# ---------------------------------------------------------------------------

func test_every_organisation_starts_level_with_the_player() -> void:
	GameState.reset_booster_standing()

	assert_eq(GameState.booster_standing.size(), DataDB.boosters.size(),
		"all ten of them")
	for booster: Dictionary in DataDB.boosters:
		assert_eq(int(GameState.booster_standing[booster["booster_id"]]),
			int(DataDB.booster_standing["start"]))


func test_pleasing_an_organisation_raises_your_standing_with_it() -> void:
	GameState.reset_booster_standing()
	var before := int(GameState.booster_standing["BO08"])

	GameState.begin_level(LevelRunner.new(DataDB.playtest_level))
	GameState.finish_stage("win", 50, ["BO08"])

	var step := int(DataDB.booster_standing["per_please"])
	assert_eq(int(GameState.booster_standing["BO08"]), before + step)
	assert_eq(int(GameState.last_booster_change["BO08"]), step, "and it says so")
	assert_eq(int(GameState.booster_standing["BO03"]), before,
		"nobody else was pleased")

	GameState.end_level()


func test_standing_is_held_between_levels() -> void:
	# Unlike the pleased list, which lasts one level. This is what makes who
	# you please in front of the cameras worth anything later.
	GameState.reset_booster_standing()

	GameState.begin_level(LevelRunner.new(DataDB.playtest_level))
	GameState.finish_stage("win", 50, ["BO08"])
	GameState.end_level()
	var after_one := int(GameState.booster_standing["BO08"])

	GameState.begin_level(LevelRunner.new(DataDB.playtest_level))
	assert_eq(int(GameState.booster_standing["BO08"]), after_one,
		"a new level does not wipe the slate")
	assert_true(GameState.last_booster_change.is_empty(),
		"though what changed last time is no longer news")

	GameState.end_level()
	GameState.reset_booster_standing()


func test_standing_cannot_run_past_its_ceiling() -> void:
	GameState.reset_booster_standing()
	GameState.booster_standing["BO08"] = int(DataDB.booster_standing["max"])

	GameState.begin_level(LevelRunner.new(DataDB.playtest_level))
	GameState.finish_stage("win", 50, ["BO08"])

	assert_eq(int(GameState.booster_standing["BO08"]),
		int(DataDB.booster_standing["max"]))
	assert_false(GameState.last_booster_change.has("BO08"),
		"and nothing is reported as having moved when nothing did")

	GameState.end_level()
	GameState.reset_booster_standing()
