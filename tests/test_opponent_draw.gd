extends GutTest
## Stage opponents are a random draw from the stage's eligible pool, not
## always the lowest IDs (Cameron, 2026-10-07). Real data throughout.


func _ids(opponents: Array) -> Array:
	var ids: Array = []
	for opponent: Dictionary in opponents:
		ids.append(str(opponent.get("opp_id", "")))
	return ids


func test_a_single_opponent_stage_draws_from_the_whole_pool() -> void:
	var pool := _ids(BattleSetup.eligible_opponents("ST06"))
	assert_gt(pool.size(), 1, "ST06 has more than one eligible opponent")
	var seen := {}
	for i in 300:
		var drawn := BattleSetup._opponents_for("LVNONE", "ST06", 1, 1)
		assert_eq(drawn.size(), 1)
		var id := str((drawn[0] as Dictionary).get("opp_id", ""))
		assert_has(pool, id, "only someone eligible is ever drawn")
		seen[id] = true
	assert_gt(seen.size(), 1, "it is not always the same person")


func test_a_sequence_is_distinct_eligible_and_varies() -> void:
	var pool := _ids(BattleSetup.eligible_opponents("ST05"))
	var count := 3
	var lineups := {}
	for i in 200:
		var drawn := _ids(BattleSetup._opponents_for("LVNONE", "ST05", 1, count))
		assert_eq(drawn.size(), count)
		for id: String in drawn:
			assert_has(pool, id)
		var unique := {}
		for id: String in drawn:
			unique[id] = true
		assert_eq(unique.size(), count, "nobody is fought twice in one stage")
		lineups[str(drawn)] = true
	assert_gt(lineups.size(), 1, "the line-up is not always the same")


func test_the_players_own_name_is_still_never_drawn() -> void:
	var player_name := str(DataDB.player.get("name_en", "")).strip_edges()
	if player_name.is_empty():
		pending("no protagonist chosen in this test run")
		return
	for i in 100:
		for opponent: Dictionary in BattleSetup._opponents_for("LVNONE", "ST02", 1, 2):
			assert_ne(str(opponent.get("name", "")).strip_edges(), player_name)
