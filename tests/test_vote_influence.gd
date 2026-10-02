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


## Per-party scope (2026-10-02): "Applies To Parties" narrows a row to one
## or more party_ids. A blank/empty list is unscoped — it counts for every
## party, including the default "" a caller passes when it isn't checking
## on behalf of anyone in particular.

func test_an_unscoped_row_counts_for_any_party() -> void:
	var triggers := [{"variable": "Reputation", "enabled": "Yes", "threshold": 85, "applies_to_parties": []}]
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT02"))
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT04"))
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85))


func test_a_scoped_row_only_counts_for_the_named_party() -> void:
	var triggers := [{
		"variable": "Reputation", "enabled": "Yes", "threshold": 85,
		"applies_to_parties": ["PT02"],
	}]
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT02"))
	# Reputation is high enough, but this row has nothing to say about PT04,
	# and there's no other enabled row either — so the gate never passes.
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT04"))


func test_a_scoped_row_can_name_more_than_one_party() -> void:
	var triggers := [{
		"variable": "Reputation", "enabled": "Yes", "threshold": 85,
		"applies_to_parties": ["PT02", "PT04"],
	}]
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT02"))
	assert_true(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT04"))
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 90}, {}, 85, "PT05"))


func test_a_scoped_row_that_fails_its_threshold_fails_only_for_the_party_it_names() -> void:
	var triggers := [{
		"variable": "Reputation", "enabled": "Yes", "threshold": 85,
		"applies_to_parties": ["PT02"],
	}]
	# PT02 is named and Reputation falls short — that row's own bar isn't
	# cleared, so PT02 fails even though no other row is in play.
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 50}, {}, 85, "PT02"))
	# PT04 was never gated by this row at all, so Reputation being low
	# doesn't touch it either — but with nothing else enabled for PT04, it
	# still never passes (no enabled row actually applies to it).
	assert_false(VoteInfluence.gate_passed(triggers, {"Reputation": 50}, {}, 85, "PT04"))


func test_a_global_row_and_a_scoped_row_combine_per_party() -> void:
	var triggers := [
		{"variable": "Reputation", "enabled": "Yes", "threshold": 85, "applies_to_parties": []},
		{"variable": "Party support", "enabled": "Yes", "threshold": 85, "applies_to_parties": ["PT02"]},
	]
	var meta := {"Reputation": 90, "Party support": 90}
	# PT02 must clear BOTH the global row and its own scoped row.
	assert_true(VoteInfluence.gate_passed(triggers, meta, {}, 85, "PT02"))
	# PT04 only has to clear the global row — the scoped one doesn't apply to it.
	assert_true(VoteInfluence.gate_passed(triggers, meta, {}, 85, "PT04"))
	# Drop Party support: PT02 now fails its own scoped row; PT04 is untouched by it.
	meta["Party support"] = 50
	assert_false(VoteInfluence.gate_passed(triggers, meta, {}, 85, "PT02"))
	assert_true(VoteInfluence.gate_passed(triggers, meta, {}, 85, "PT04"))
