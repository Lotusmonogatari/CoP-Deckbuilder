extends GutTest
## OfficeHoursEngine.gd — pure, headless, no DataDB. Every fixture below
## hands setup() the exact shape BattleSetup.expand_level() produces for a
## Non-combat stage's "visitors" list, so these tests would catch a shape
## mismatch between the two files as readily as a logic bug in this one.


func _visitor(id: String, correct := "A", reward := [{"target": "BO01", "delta": 1}],
		penalty := [{"target": "BO01", "delta": -1}]) -> Dictionary:
	return {
		"visitor_id": id,
		"reward": reward,
		"penalty": penalty,
		"question": {
			"question_id": "VQ_%s" % id,
			"correct_choice": correct,
			"response_right": "Glad you agree.",
			"response_wrong": "Hm, not quite.",
			"reaction_right": "Nods.",
			"reaction_wrong": "Frowns.",
		},
	}


# ---------------------------------------------------------------------------
# setup()
# ---------------------------------------------------------------------------

func test_setup_with_no_visitors_fails_with_a_readable_problem() -> void:
	var engine := OfficeHoursEngine.new()
	assert_false(engine.setup({"visitors": []}))
	assert_string_contains(engine.setup_problems[0], "no visitors")


func test_setup_with_a_visitor_missing_its_question_fails() -> void:
	var engine := OfficeHoursEngine.new()
	var broken := _visitor("VI01")
	broken["question"] = {}
	assert_false(engine.setup({"visitors": [broken]}))
	assert_string_contains(engine.setup_problems[0], "VI01")


func test_setup_with_real_visitors_succeeds() -> void:
	var engine := OfficeHoursEngine.new()
	assert_true(engine.setup({"visitors": [_visitor("VI01")]}))
	assert_eq(engine.setup_problems.size(), 0)


# ---------------------------------------------------------------------------
# current_visitor() / current_question() / is_finished() / counts
# ---------------------------------------------------------------------------

func test_current_visitor_and_question_are_the_first_one() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01"), _visitor("VI02")]})
	assert_eq(engine.current_visitor().get("visitor_id"), "VI01")
	assert_eq(engine.current_question().get("question_id"), "VQ_VI01")
	assert_false(engine.is_finished())
	assert_eq(engine.visitor_count(), 2)
	assert_eq(engine.visitor_index(), 0)


func test_is_finished_only_after_every_visitor_is_advanced_past() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01"), _visitor("VI02")]})
	engine.answer("A")
	engine.advance()
	assert_false(engine.is_finished())
	engine.answer("A")
	engine.advance()
	assert_true(engine.is_finished())


func test_advance_once_finished_does_nothing_and_does_not_throw() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01")]})
	engine.answer("A")
	engine.advance()
	assert_true(engine.is_finished())
	engine.advance()
	assert_true(engine.is_finished())


# ---------------------------------------------------------------------------
# answer() — the correct-choice / wrong-choice split
# ---------------------------------------------------------------------------

func test_answering_correctly_returns_the_right_response_and_reward_only() -> void:
	var engine := OfficeHoursEngine.new()
	var v := _visitor("VI01", "B", [{"target": "BO01", "delta": 1}], [{"target": "BO01", "delta": -2}])
	engine.setup({"visitors": [v]})

	var result := engine.answer("B")
	assert_true(result["correct"])
	assert_eq(result["response_text"], "Glad you agree.")
	assert_eq(result["reaction"], "Nods.")
	assert_eq(result["reward"], [{"target": "BO01", "delta": 1}])
	assert_eq(result["penalty"], [])


func test_answering_case_insensitively_still_counts_as_correct() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01", "B")]})
	assert_true(engine.answer("b")["correct"])


func test_answering_any_wrong_letter_returns_the_wrong_response_and_penalty_only() -> void:
	for wrong_letter in ["A", "C", "D"]:
		var engine := OfficeHoursEngine.new()
		var v := _visitor("VI01", "B", [{"target": "BO01", "delta": 1}], [{"target": "BO01", "delta": -2}])
		engine.setup({"visitors": [v]})

		var result := engine.answer(wrong_letter)
		assert_false(result["correct"], "letter %s should be wrong" % wrong_letter)
		assert_eq(result["response_text"], "Hm, not quite.")
		assert_eq(result["reaction"], "Frowns.")
		assert_eq(result["reward"], [])
		assert_eq(result["penalty"], [{"target": "BO01", "delta": -2}])


func test_a_visitor_with_no_reward_or_penalty_produces_empty_lists_not_broken_ones() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01", "A", [], [])]})
	assert_eq(engine.answer("A")["reward"], [])

	var engine2 := OfficeHoursEngine.new()
	engine2.setup({"visitors": [_visitor("VI01", "A", [], [])]})
	assert_eq(engine2.answer("Z")["penalty"], [])


func test_answering_the_already_finished_engine_returns_empty() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01")]})
	engine.answer("A")
	engine.advance()
	assert_eq(engine.answer("A"), {})


# ---------------------------------------------------------------------------
# outcome()
# ---------------------------------------------------------------------------

func test_outcome_after_a_mixed_run_reports_the_right_counts_and_lists() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [
		_visitor("VI01", "A", [{"target": "BO01", "delta": 1}], [{"target": "BO01", "delta": -1}]),
		_visitor("VI02", "A", [{"target": "BO02", "delta": 2}], [{"target": "BO02", "delta": -2}]),
		_visitor("VI03", "A", [{"target": "BO03", "delta": 3}], [{"target": "BO03", "delta": -3}]),
	]})

	engine.answer("A")   # VI01 correct
	engine.advance()
	engine.answer("Z")   # VI02 wrong
	engine.advance()
	engine.answer("A")   # VI03 correct
	engine.advance()

	var outcome := engine.outcome()
	assert_eq(outcome["visited"], 3)
	assert_eq(outcome["correct"], 2)
	assert_eq(outcome["rewards"], [{"target": "BO01", "delta": 1}, {"target": "BO03", "delta": 3}])
	assert_eq(outcome["penalties"], [{"target": "BO02", "delta": -2}])


func test_outcome_mid_run_only_covers_visitors_actually_answered() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_visitor("VI01"), _visitor("VI02")]})
	engine.answer("A")
	# advance() not called yet — only one visitor has actually been answered.
	var outcome := engine.outcome()
	assert_eq(outcome["visited"], 1)
	assert_eq(outcome["correct"], 1)


# ---------------------------------------------------------------------------
# Dilemma questions (2026-10-16): every choice carries its own effects
# ---------------------------------------------------------------------------

func _dilemma_visitor() -> Dictionary:
	var visitor := _visitor("VI01", "A", [{"target": "BO01", "delta": 9}], [{"target": "BO01", "delta": -9}])
	var question: Dictionary = visitor["question"]
	question["effects_a"] = [{"target": "BO06", "delta": 3}, {"target": "BO04", "delta": -1}]
	question["effects_b"] = [{"target": "BO04", "delta": 2}, {"target": "BO06", "delta": -2}]
	question["effects_c"] = [{"target": "BO23", "delta": -3}]
	question["response_b"] = "Their own reply."
	question["reaction_b"] = "Their own reaction."
	return visitor


func test_a_dilemma_choice_applies_its_own_effects_not_the_visitors() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_dilemma_visitor()]})
	var result := engine.answer("B")
	assert_eq(result["effects"], [{"target": "BO04", "delta": 2}, {"target": "BO06", "delta": -2}])
	assert_eq(result["response_text"], "Their own reply.")
	assert_eq(result["reaction"], "Their own reaction.")


func test_a_dilemma_choice_that_nets_below_zero_is_not_a_win() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_dilemma_visitor()]})
	assert_true(engine.answer("A")["correct"], "+3 -1 is a net gain")
	engine.advance()
	var again := OfficeHoursEngine.new()
	again.setup({"visitors": [_dilemma_visitor()]})
	assert_false(again.answer("C")["correct"], "-3 is a net setback")


func test_a_choice_without_its_own_effects_falls_back_to_the_old_reward_or_penalty() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_dilemma_visitor()]})
	var result := engine.answer("D")
	assert_eq(result["effects"], [{"target": "BO01", "delta": -9}], "D has no effects of its own: the penalty")


func test_outcome_collects_every_choices_effects() -> void:
	var engine := OfficeHoursEngine.new()
	engine.setup({"visitors": [_dilemma_visitor(), _dilemma_visitor()]})
	engine.answer("A")
	engine.advance()
	engine.answer("C")
	engine.advance()
	var outcome := engine.outcome()
	assert_eq(outcome["effects"].size(), 3)
	assert_eq(outcome["correct"], 1)


func test_every_real_dilemma_question_gives_all_four_choices_effects() -> void:
	for question: Dictionary in DataDB.visitor_questions:
		var any_effects := false
		for letter in ["a", "b", "c", "d"]:
			var own: Variant = question.get("effects_%s" % letter)
			any_effects = any_effects or (own is Array and not (own as Array).is_empty())
		if not any_effects:
			continue
		for letter in ["a", "b", "c", "d"]:
			var own: Variant = question.get("effects_%s" % letter)
			assert_true(own is Array and not (own as Array).is_empty(),
				"%s choice %s has no effects" % [question["question_id"], letter])
			assert_false(str(question.get("response_%s" % letter, "")).strip_edges().is_empty(),
				"%s choice %s has no response" % [question["question_id"], letter])
