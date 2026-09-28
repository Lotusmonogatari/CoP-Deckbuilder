extends GutTest
## The questions a room asks, and what answering one is worth.
##
## Cameron wrote 100 of them in the workbook — 20 for each of the five rooms
## that ask — and graded all six suits S, M or W on every one. A stage draws
## from the pool for its kind rather than naming its own, so a new question
## is one row in the spreadsheet.
##
## His rule, redesigned 2026-09-28: a STRONG answer boosts the card's own
## self_plus/opp_minus this round (and still pleases whoever asked, exactly
## as before), a MEDIUM one leaves it alone, and a WEAK one penalizes it
## this round. No tone cost at all any more — the old flat
## weak_answer_tone_cost and last turn's probability layer are both gone.

const GRADED := {
	"Earnest": "S", "Emotional": "M", "Appeal": "W",
	"Data Driven": "M", "Divisive": "M", "Duplicitous": "M",
}


## A room that asks questions: one a turn, and a bar to move.
##
## `config_overrides` merges into the top-level battle config rather than
## the stage — question_strong_multiplier/question_weak_multiplier live
## there (2026-09-28), since they're two numbers across every
## question-asking room, not per-stage ones. The three cards carry a real
## self_plus so a test can actually see the multiplier's effect — the old
## fixtures here all had self_plus: 0, which could never show one.
func _conference(overrides: Dictionary = {}, config_overrides: Dictionary = {}) -> BattleEngine:
	var stage := TestFixtures.stage({
		"win_mode": "score",
		"questions_per_turn": 1,
		"decline_tone_cost": 3,
		"player_start": 50,
	})
	stage.merge(overrides, true)

	var config := TestFixtures.battle_config({"stage": stage})
	config.merge(config_overrides, true)
	config["cards"] = {
		"STRONG": TestFixtures.card({"card_id": "STRONG", "suit": "Earnest", "cost": 1, "self_plus": 10}),
		"BLAND": TestFixtures.card({"card_id": "BLAND", "suit": "Emotional", "cost": 1, "self_plus": 10}),
		"WEAK": TestFixtures.card({"card_id": "WEAK", "suit": "Appeal", "cost": 1, "self_plus": 10}),
	}
	config["deck"] = ["STRONG", "BLAND", "WEAK", "STRONG", "BLAND", "WEAK"]

	var engine := BattleEngine.new()
	engine.setup(config)
	return engine


func _question(overrides: Dictionary = {}) -> Dictionary:
	var question := {
		"id": "Q01",
		"text": "Where do you stand?",
		"theme": "Position",
		"grades": GRADED.duplicate(),
		"pleases_boosters": ["BO08"],
	}
	question.merge(overrides, true)
	return question


# ---------------------------------------------------------------------------
# Strong, medium, weak
# ---------------------------------------------------------------------------

func test_a_strong_answer_boosts_the_cards_own_effect_and_pleases_the_organisation() -> void:
	var engine := _conference({"questions": [_question()]}, {"question_strong_multiplier": 1.3})
	var before := engine.state.bar.player
	var affinity_only := engine.affinity_for(TestFixtures.card({"suit": "Earnest"}))

	engine.play_card("STRONG")

	assert_has(engine.state.pleased_boosters, "BO08",
		"answering in a suit the question grades S still pleases whoever asked")
	assert_eq(engine.state.bar.player, before + CardResolver.round_half_up(10.0 * affinity_only * 1.3),
		"a strong answer's own self_plus is boosted 1.3x on top of stage affinity")


func test_a_medium_answer_is_unchanged_by_the_question() -> void:
	var engine := _conference({"questions": [_question()]}, {"question_strong_multiplier": 1.3, "question_weak_multiplier": 0.7})
	var before := engine.state.bar.player
	var affinity_only := engine.affinity_for(TestFixtures.card({"suit": "Emotional"}))

	engine.play_card("BLAND")

	assert_eq(engine.state.pleased_boosters.size(), 0, "nobody is pleased")
	assert_eq(engine.state.bar.player, before + CardResolver.round_half_up(10.0 * affinity_only),
		"a medium grade applies stage affinity only, no question multiplier")
	assert_eq(engine.state.weak_answers, 0)


func test_a_weak_answer_penalizes_the_cards_own_effect_and_pleases_nobody() -> void:
	var engine := _conference({"questions": [_question()]}, {"question_weak_multiplier": 0.7})
	var before := engine.state.bar.player
	var affinity_only := engine.affinity_for(TestFixtures.card({"suit": "Appeal"}))

	engine.play_card("WEAK")

	assert_eq(engine.state.pleased_boosters.size(), 0, "nobody is pleased")
	assert_eq(engine.state.bar.player, before + CardResolver.round_half_up(10.0 * affinity_only * 0.7),
		"a weak answer's own self_plus is penalized 0.7x on top of stage affinity")
	assert_eq(engine.state.weak_answers, 1, "and it is still counted")


func test_a_weak_answer_costs_no_tone_at_all() -> void:
	# The old flat weak_answer_tone_cost and last turn's probability layer
	# are both fully gone — a weak answer only ever touches the card's own
	# effect now, never a separate tone cost.
	var engine := _conference({"questions": [_question()], "weak_answer_tone_cost": 5},
		{"question_weak_multiplier": 0.7})
	var before := engine.state.bar.player

	engine.play_card("WEAK")

	assert_gt(engine.state.bar.player, before - 5,
		"a stage's own weak_answer_tone_cost is never read any more")


# ---------------------------------------------------------------------------
# The question multiplier composes with stage affinity, and only applies
# when there's actually a question on the floor (2026-09-28, Cameron).
# ---------------------------------------------------------------------------

func test_the_multiplier_composes_with_a_real_stage_affinity() -> void:
	# Data Driven is 1.3x at ST01 in the fixture affinity table — a
	# non-neutral number, so this proves the two multipliers stack rather
	# than one silently overriding the other.
	var stage := TestFixtures.stage({
		"stage_id": "ST01", "win_mode": "score", "questions_per_turn": 1, "player_start": 50,
		"questions": [_question({"grades": {
			"Earnest": "M", "Emotional": "M", "Appeal": "M",
			"Data Driven": "S", "Divisive": "M", "Duplicitous": "M",
		}})],
	})
	var config := TestFixtures.battle_config({"stage": stage})
	config["question_strong_multiplier"] = 1.3
	config["cards"] = {
		"CARD": TestFixtures.card({"card_id": "CARD", "suit": "Data Driven", "cost": 1, "self_plus": 10}),
	}
	config["deck"] = ["CARD"]

	var engine := BattleEngine.new()
	engine.setup(config)
	var before := engine.state.bar.player

	engine.play_card("CARD")

	assert_eq(engine.state.bar.player, before + CardResolver.round_half_up(10.0 * 1.3 * 1.3),
		"stage affinity (1.3x) and the question's own strong grade (1.3x) both apply")


func test_no_current_question_means_no_multiplier() -> void:
	# Ordinary Shared_pool rooms (no question pool at all) must play exactly
	# as they did before this mechanic existed.
	var config := TestFixtures.battle_config()
	config["question_strong_multiplier"] = 1.3
	config["question_weak_multiplier"] = 0.7

	var engine := BattleEngine.new()
	engine.setup(config)

	assert_eq(engine.question_multiplier_for(TestFixtures.card({"suit": "Earnest"})), 1.0,
		"no question on the floor means no question multiplier at all")


func test_a_question_that_names_one_suit_still_works() -> void:
	# The earlier hand-written questions named a single preferred suit
	# instead of grading all six. They must keep working: that suit reads as
	# strong and every other as medium.
	var engine := _conference({"questions": [{
		"id": "OLD", "text": "Your stance?",
		"prefers_suit": "Earnest", "pleases_boosters": ["BO03"],
	}]}, {"question_weak_multiplier": 0.7})
	var before := engine.state.bar.player
	var affinity_only := engine.affinity_for(TestFixtures.card({"suit": "Appeal"}))

	engine.play_card("WEAK")
	assert_eq(engine.state.bar.player, before + CardResolver.round_half_up(10.0 * affinity_only),
		"an ungraded suit reads as medium, so no question multiplier applies")
	assert_eq(engine.state.pleased_boosters.size(), 0)


# ---------------------------------------------------------------------------
# Drawing from the pool
# ---------------------------------------------------------------------------

func _pool(size: int) -> Array:
	var pool: Array = []
	for index in size:
		pool.append(_question({"id": "P%02d" % index}))
	return pool


func _asked(engine: BattleEngine) -> Array[String]:
	var ids: Array[String] = []
	for question: Dictionary in engine._questions:
		ids.append(str(question.get("id", "")))
	return ids


func _drawn(pool: Array, count: int, seed_value: int) -> Array[String]:
	var stage := TestFixtures.stage({
		"win_mode": "score", "questions_per_turn": 1, "questions_count": count,
	})
	var config := TestFixtures.battle_config({"stage": stage})
	config["question_pool"] = pool
	config["seed"] = seed_value

	var engine := BattleEngine.new()
	engine.setup(config)
	return _asked(engine)


func test_a_stage_draws_as_many_questions_as_it_asks_for() -> void:
	assert_eq(_drawn(_pool(20), 5, 1).size(), 5)
	assert_eq(_drawn(_pool(20), 4, 1).size(), 4)


func test_the_same_seed_asks_the_same_questions() -> void:
	assert_eq(_drawn(_pool(20), 5, 77), _drawn(_pool(20), 5, 77))


func test_a_different_seed_asks_different_questions() -> void:
	# The point of a pool: the same room twice is not the same interview.
	assert_ne(_drawn(_pool(20), 5, 1), _drawn(_pool(20), 5, 2))


func test_no_question_is_asked_twice_in_one_stage() -> void:
	for seed_value in range(1, 30):
		var asked := _drawn(_pool(20), 6, seed_value)
		var seen: Array[String] = []
		for id: String in asked:
			assert_false(seen.has(id), "%s was asked twice on seed %d" % [id, seed_value])
			seen.append(id)


func test_a_pool_smaller_than_the_stage_wants_is_used_whole() -> void:
	assert_eq(_drawn(_pool(3), 6, 1).size(), 3,
		"three questions asked rather than six, and no crash")


func test_a_stage_that_writes_its_own_questions_keeps_them() -> void:
	var stage := TestFixtures.stage({
		"win_mode": "score", "questions_per_turn": 1,
		"questions": [_question({"id": "MINE"})],
	})
	var config := TestFixtures.battle_config({"stage": stage})
	config["question_pool"] = _pool(20)

	var engine := BattleEngine.new()
	engine.setup(config)

	assert_eq(_asked(engine), ["MINE"] as Array[String],
		"a stage that names its own questions is not overruled by the pool")


# ---------------------------------------------------------------------------
# The writing that is actually in the workbook
# ---------------------------------------------------------------------------

func test_every_room_that_asks_has_a_pool() -> void:
	for stage_type: String in ["press_conference", "town_hall", "lobbyist_meeting",
			"policy_study", "media_ambush"]:
		var pool: Array = DataDB.questions.get(stage_type, [])
		assert_eq(pool.size(), 20, "%s should have 20 questions" % stage_type)


func test_every_question_grades_all_six_suits() -> void:
	var suits: Array[String] = []
	for suit: Dictionary in DataDB.suits:
		suits.append(str(suit.get("element", "")))

	for stage_type: String in DataDB.questions.keys():
		for question: Dictionary in DataDB.questions[stage_type]:
			var grades: Dictionary = question.get("grades", {})
			for suit: String in suits:
				assert_has(grades, suit,
					"%s does not grade %s" % [question.get("id"), suit])
				assert_true(["S", "M", "W"].has(str(grades.get(suit))),
					"%s grades %s as '%s'" % [question.get("id"), suit, grades.get(suit)])


func test_every_question_has_somebody_to_please_and_somebody_asking() -> void:
	# Both come from the workbook: the organisation from the Question Themes
	# tab, the reporter by rotation. A question with neither would be worth
	# nothing to answer well.
	var booster_ids: Array[String] = []
	for booster: Dictionary in DataDB.boosters:
		booster_ids.append(str(booster.get("booster_id", "")))

	for stage_type: String in DataDB.questions.keys():
		for question: Dictionary in DataDB.questions[stage_type]:
			var pleases: Array = question.get("pleases_boosters", [])
			assert_false(pleases.is_empty(),
				"%s names no organisation to please" % question.get("id"))
			for booster: String in pleases:
				assert_has(booster_ids, booster,
					"%s names an organisation that does not exist" % question.get("id"))
			assert_ne(str(question.get("asked_by", "")), "",
				"%s has nobody asking it" % question.get("id"))


func test_every_card_has_something_to_say() -> void:
	for card: Dictionary in DataDB.cards:
		var card_id := str(card.get("card_id", ""))
		var cues: Array = DataDB.card_cues.get(card_id, [])
		assert_eq(cues.size(), 5, "%s should have five cues" % card_id)
		for cue: String in cues:
			assert_lt(cue.split(" ").size(), 10,
				"'%s' is over the nine-word limit" % cue)
