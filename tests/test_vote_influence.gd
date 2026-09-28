extends GutTest
## VoteInfluence.gate_passed(): the Floor Vote influence swing's own gate.
## Fabricated data throughout, same discipline as test_floor_vote_engine.gd.

func test_no_rows_at_all_never_passes() -> void:
	assert_false(VoteInfluence.gate_passed([], {"Reputation": 100}, {}, 85))


func test_every_row_disabled_never_passes_even_at_a_perfect_score() -> void:
	var triggers := [{"variable": "Reputation", "enabled": "No", "threshold": 85}]
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 100}, {}, 85))


func test_one_enabled_row_at_or_above_its_threshold_passes() -> void:
	var triggers := [{"variable": "Reputation", "enabled": "Yes", "threshold": 85}]
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 85}, {}, 85))


func test_one_enabled_row_below_its_threshold_fails() -> void:
	var triggers := [{"variable": "Reputation", "enabled": "Yes", "threshold": 85}]
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 84}, {}, 85))


func test_a_blank_threshold_cell_falls_back_to_the_default() -> void:
	var triggers := [{"variable": "Reputation", "enabled": "Yes", "threshold": null}]
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 85}, {}, 85))
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 84}, {}, 85))


func test_every_enabled_row_must_clear_its_own_bar_one_failure_fails_the_whole_gate() -> void:
	var triggers := [
		{"variable": "Reputation", "enabled": "Yes", "threshold": 85},
		{"variable": "Party support", "enabled": "Yes", "threshold": 85},
	]
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 99, "Party support": 84}, {}, 85))


func test_a_booster_id_reads_from_booster_standing_not_meta() -> void:
	var triggers := [{"variable": "BO02", "enabled": "Yes", "threshold": 85}]
	assert_true(VoteInfluence.gate_passed(triggers, {}, {"BO02": 90}, 85))
	assert_false(VoteInfluence.gate_passed(triggers, {}, {"BO02": 10}, 85))


func test_a_missing_variable_reads_as_zero_and_fails() -> void:
	var triggers := [{"variable": "BO99", "enabled": "Yes", "threshold": 85}]
	assert_false(VoteInfluence.gate_passed(triggers, {}, {}, 85))
