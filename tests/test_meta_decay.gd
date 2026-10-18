extends GutTest
## Reputation and Constituency support settle back each level (Sanban tab,
## Decay Percent; 2026-10-18).

func test_the_sanban_tab_gives_the_two_climbing_values_a_decay() -> void:
	for variable: Dictionary in DataDB.sanban:
		var name := str(variable["name_en"])
		if name == "Reputation" or name == "Constituency support":
			assert_gt(float(variable["decay_percent"]), 0.0, name)
		else:
			assert_null(variable.get("decay_percent"), "%s has none" % name)


func test_a_level_end_settles_a_maxed_value_back_and_leaves_funds_alone() -> void:
	GameState.start_new_run("PC02")
	var starts := BattleSetup.starting_meta_for(DataDB.player)
	GameState.meta["Reputation"] = 100
	GameState.meta["Constituency support"] = 100
	GameState.meta["Funds"] = 12345
	GameState._apply_meta_decay()
	var expected := BoosterStanding.decayed_percent(100, int(starts["Reputation"]), 6.0)
	assert_eq(int(GameState.meta["Reputation"]), expected)
	assert_lt(int(GameState.meta["Reputation"]), 100)
	assert_eq(int(GameState.meta["Funds"]), 12345)
	assert_string_contains(GameState.last_meta_cause["Reputation"][0]["cause"], "settling back")


func test_a_value_at_its_start_does_not_move() -> void:
	GameState.start_new_run("PC02")
	var starts := BattleSetup.starting_meta_for(DataDB.player)
	GameState.meta["Reputation"] = int(starts["Reputation"])
	GameState._apply_meta_decay()
	assert_eq(int(GameState.meta["Reputation"]), int(starts["Reputation"]))
