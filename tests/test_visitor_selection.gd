extends GutTest
## BattleSetup's visitor-selection functions (design/proposals/office_hours.md
## §1.3) — the direct twins of eligible_opponents()/_opponents_for(), same
## dynamic-by-default pick, same pin file. Tested mainly against the real
## template visitor (VI01, eligible for ST07 — see data/visitors.json) the
## same way the opponent equivalents are only really exercised through real
## level data rather than synthetic multi-candidate fixtures; a level_visitor
## _overrides.json pin is exercised once, directly, since it's new code.

var _overrides_before: Array = []


func before_each() -> void:
	_overrides_before = DataDB.level_visitor_overrides.duplicate(true)


func after_each() -> void:
	DataDB.level_visitor_overrides = _overrides_before.duplicate(true)


func test_eligible_visitors_finds_the_real_template_visitor_for_st07() -> void:
	var found := BattleSetup.eligible_visitors("ST07")
	var ids: Array = []
	for v: Dictionary in found:
		ids.append(v.get("visitor_id"))
	assert_true(ids.has("VI01"))


func test_eligible_visitors_is_empty_for_a_stage_no_visitor_names() -> void:
	# ST04 (Press Conference) is a Combat stage; no visitor today names it.
	assert_eq(BattleSetup.eligible_visitors("ST04"), [])


func test_visitors_for_with_count_one_picks_the_lowest_eligible_id() -> void:
	var chosen := BattleSetup._visitors_for("LVTEST", "ST07", 1, 1)
	assert_eq(chosen.size(), 1)
	assert_eq(chosen[0].get("visitor_id"), "VI01")


func test_visitors_for_a_stage_with_no_eligible_pool_is_empty() -> void:
	assert_eq(BattleSetup._visitors_for("LVTEST", "ST04", 1, 1), [])


func test_question_for_visitor_returns_one_of_the_visitors_real_questions() -> void:
	var question := BattleSetup._question_for_visitor("VI01")
	assert_eq(question.get("visitor_id"), "VI01")
	assert_false(str(question.get("question_text", "")).is_empty())


func test_question_for_visitor_with_no_questions_returns_empty() -> void:
	assert_eq(BattleSetup._question_for_visitor("NOT_A_REAL_VISITOR_ID"), {})


func test_a_level_visitor_override_pin_is_honoured() -> void:
	DataDB.level_visitor_overrides = [
		{"level_id": "LVTEST", "slot": 1, "visitor_id": "VI01"},
	]
	var pinned := BattleSetup._resolve_visitor_pin("LVTEST", "ST07", 1)
	assert_eq(pinned.get("visitor_id"), "VI01")


func test_a_pin_naming_someone_ineligible_for_the_stage_falls_back() -> void:
	# VI01 is eligible for ST07, not ST04 — a pin trying to seat them in a
	# room their own "stages" list does not name should be refused, the
	# same as _resolve_pin()'s own behaviour for opponents.
	DataDB.level_visitor_overrides = [
		{"level_id": "LVTEST", "slot": 1, "visitor_id": "VI01"},
	]
	var pinned := BattleSetup._resolve_visitor_pin("LVTEST", "ST04", 1)
	assert_eq(pinned, {})


func test_a_pin_naming_an_unknown_visitor_falls_back() -> void:
	DataDB.level_visitor_overrides = [
		{"level_id": "LVTEST", "slot": 1, "visitor_id": "VI99"},
	]
	var pinned := BattleSetup._resolve_visitor_pin("LVTEST", "ST07", 1)
	assert_eq(pinned, {})


# ---------------------------------------------------------------------------
# expand_level() wiring — the real end-to-end shape a Non-combat stage gets
# ---------------------------------------------------------------------------

func test_expand_level_attaches_visitors_with_a_drawn_question_for_a_non_combat_stage() -> void:
	var level := {"level_id": "LVTEST", "stage_1": "ST07"}
	var expanded := BattleSetup.expand_level(level)
	var stage: Dictionary = expanded["stages"][0]

	assert_eq(stage.get("opponents"), [])
	assert_eq(stage.get("committee_members"), [])
	var drawn: Array = stage.get("visitors", [])
	assert_eq(drawn.size(), 1)
	assert_eq(drawn[0].get("visitor_id"), "VI01")
	assert_false((drawn[0].get("question", {}) as Dictionary).is_empty(),
		"the drawn visitor should already carry its own drawn question")


func test_expand_level_gives_a_combat_stage_an_empty_visitors_list() -> void:
	var level := {"level_id": "LVTEST", "stage_1": "ST02"}
	var expanded := BattleSetup.expand_level(level)
	var stage: Dictionary = expanded["stages"][0]
	assert_eq(stage.get("visitors"), [])
