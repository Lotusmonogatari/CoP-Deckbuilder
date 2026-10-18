extends GutTest
## Special Levels (2026-10-18): the Town Hall and Steering Committee crisis
## triggers start a countdown on the game clock; the level then sits at the top
## of the level list, and is forced in after the next ordinary level.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = {
		"meta": GameState.meta.duplicate(true), "runner": GameState.level_runner,
		"mid": GameState.mid_stage, "stakeholders": DataDB.party_stakeholders,
		"delay": DataDB.balance.get("special_level_delay"),
	}
	DataDB.party_stakeholders = []
	DataDB.balance["special_level_delay"] = 5
	GameState.reset_crisis_triggers()


func after_each() -> void:
	GameState.meta = _saved["meta"].duplicate(true)
	GameState.level_runner = _saved["runner"]
	GameState.mid_stage = _saved["mid"]
	DataDB.party_stakeholders = _saved["stakeholders"]
	DataDB.balance["special_level_delay"] = _saved["delay"]
	GameState.reset_crisis_triggers()


func _ordinary_level(stage_count: int) -> void:
	var stages: Array = []
	for i in stage_count:
		stages.append({"seq": i + 1, "stage_id": "ST02", "name_en": "S%d" % i,
			"opponents": [{"opp_id": "A"}]})
	GameState.begin_level(LevelRunner.new({"level_id": "TEST", "stages": stages}))


func test_the_real_data_has_one_special_level_per_trigger() -> void:
	assert_eq(SpecialLevels.level_for("Town Hall", DataDB.levels).get("level_id"), "LV83")
	assert_eq(SpecialLevels.level_for("Steering Committee", DataDB.levels).get("level_id"), "LV84")
	for level: Dictionary in DataDB.levels:
		if SpecialLevels.is_special(level):
			var expanded := BattleSetup.expand_level(level)
			assert_true(LevelRunner.new(expanded).is_valid(), "%s should start" % level.get("level_id"))


func test_a_special_level_is_due_only_after_the_delay_has_run() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 50
	_ordinary_level(8)
	GameState.finish_stage(LevelRunner.WON)   # clock 1; countdown starts here
	assert_true(GameState.due_special_levels().is_empty())
	for i in 4:
		GameState.finish_stage(LevelRunner.WON)
	assert_true(GameState.due_special_levels().is_empty(), "four more units is not five")
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.due_special_levels(), ["Town Hall"])


func test_both_come_due_town_hall_first() -> void:
	var armed := {"Steering Committee": {"armed_at": 0}, "Town Hall": {"armed_at": 0}}
	assert_eq(SpecialLevels.due(armed, 5, 5), ["Town Hall", "Steering Committee"])
	assert_eq(SpecialLevels.due(armed, 4, 5), [])


func test_a_due_special_level_is_forced_after_the_next_ordinary_level() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	_ordinary_level(1)
	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.special_forced)
	var forced := GameState.take_forced_special()
	assert_eq(forced.get("level_id"), "LV83")
	assert_false(GameState.special_forced, "taking it forgets the order")
	assert_true(GameState.take_forced_special().is_empty())


func test_a_special_level_that_is_not_yet_due_is_not_forced() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 9}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	_ordinary_level(1)
	GameState.finish_stage(LevelRunner.WON)
	assert_false(GameState.special_forced)
	assert_true(GameState.special_levels.has("Town Hall"))


func test_playing_a_special_level_clears_it_win_or_lose_and_forces_nothing() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}, "Steering Committee": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 50
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV83")))
	GameState.begin_level(runner)
	while not runner.is_finished():
		GameState.finish_stage(LevelRunner.LOST)
	assert_false(GameState.special_levels.has("Town Hall"))
	assert_true(GameState.special_levels.has("Steering Committee"), "the other one waits")
	assert_false(GameState.special_forced, "only an ordinary level forces one in")


func test_abandoning_a_special_level_leaves_it_waiting() -> void:
	GameState.special_levels = {"Town Hall": {"armed_at": 0}}
	GameState.time_units = 10
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV83"))))
	GameState.abandon_level()
	assert_true(GameState.special_levels.has("Town Hall"))


func test_the_special_level_state_is_saved() -> void:
	assert_true("special_levels" in GameState._SAVED_FIELDS)
	assert_true("special_forced" in GameState._SAVED_FIELDS)
