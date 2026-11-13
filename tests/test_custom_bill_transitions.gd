extends GutTest
## The stages that exist only in custom (patron, sponsored, drafted) bill levels
## now have transitions (2026-11-13, Cameron): Patron Visit ST263, Member Visit
## ST260 and Lobbyist Trade ST262. Only hired staff speak; with none hired the
## player's own thought plays. Convince Your Colleague (ST261) has none.

const STAGES := ["ST263", "ST260", "ST262"]


func _resolve(stage_id: String, hired: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return StageTransition.resolve(DataDB.get_stage(stage_id), DataDB.transition_cast,
		DataDB.transition_backgrounds, DataDB.transition_dialogue, rng, hired, 0, "", "", [], -1, {}, {})


func test_the_three_stages_show_a_transition_and_the_convince_fight_does_not() -> void:
	for stage_id: String in STAGES:
		assert_true(StageTransition.should_show(DataDB.get_stage(stage_id)), stage_id)
	assert_false(StageTransition.should_show(DataDB.get_stage("ST261")))


func test_a_hired_staff_member_speaks_and_nobody_else_does() -> void:
	for stage_id: String in STAGES:
		var result := _resolve(stage_id, ["SF01"])
		assert_false(result.is_empty(), stage_id)
		for speaker: Dictionary in result["speakers"]:
			assert_eq(StageTransition.character_kind(str(speaker["character_id"])), "staff", stage_id)


func test_with_no_staff_the_players_own_thought_plays() -> void:
	for stage_id: String in STAGES:
		var result := _resolve(stage_id, [])
		assert_false(result.is_empty(), stage_id)
		assert_true((result["speakers"] as Array).is_empty(), stage_id)
		assert_false(str(result.get("thought", "")).is_empty(), "%s has a thought" % stage_id)


func test_each_has_a_transition_background() -> void:
	var seen := {}
	for row: Dictionary in DataDB.transition_backgrounds:
		seen[str(row.get("stage_id", ""))] = true
	for stage_id: String in STAGES:
		assert_true(seen.has(stage_id), stage_id)
