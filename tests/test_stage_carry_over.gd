extends GutTest
## What the briefing says resets between opponents has to match the engine.

func test_a_single_opponent_stage_has_nothing_to_say() -> void:
	assert_eq(StageCarryOver.between_opponents({"sequence_mode": "single"}), {})
	assert_eq(StageCarryOver.between_opponents({"sequence_mode": "reset", "opponents": [{}]}), {})


func test_a_committee_resets_everything() -> void:
	var got := StageCarryOver.between_opponents({"sequence_mode": "reset", "opponents": [{}, {}]})
	assert_eq(got["resets"].size(), 6)
	assert_eq(got["carries"].size(), 0)


func test_a_town_hall_refills_energy_but_carries_gaffes_and_turns() -> void:
	var got := StageCarryOver.between_opponents({"sequence_mode": "stream", "opponents": [{}, {}, {}]})
	assert_true(got["resets"].has("energy"))
	assert_true(got["carries"].has("gaffes"))
	assert_true(got["carries"].has("turns"))


func test_a_continuous_stage_only_restarts_support() -> void:
	var got := StageCarryOver.between_opponents({"sequence_mode": "continuous", "opponent_count": {"min": 2, "max": 2}})
	assert_eq(got["resets"], ["support"])
	assert_eq(got["carries"].size(), 5)


func test_every_real_multi_opponent_stage_says_something() -> void:
	for stage: Dictionary in DataDB.stages:
		if str(stage.get("mode")) != "Combat":
			continue
		# A stage listing several opponents must cycle through them (2026-10-10:
		# ST19 and ST21 were "single" and only ever fought the first).
		if StageCarryOver.opponent_total(stage) > 1:
			assert_false(StageCarryOver.between_opponents(stage).is_empty(), str(stage.get("stage_id")))
