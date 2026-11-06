extends GutTest
## A stage with several opponents can be picked up at the next opponent after
## one is defeated (Cameron, 2026-11-06): the engine writes a checkpoint, and
## a fresh engine set up from the same stage restores it.


func _config(mode: String) -> Dictionary:
	return TestFixtures.battle_config({
		"stage": TestFixtures.stage({
			"stage_id": "PT_S1", "sequence_mode": mode,
			"bar_max": 100, "win_threshold": 60,
			"player_start": 40, "opp_start": 40,
			"turn_limit": 6, "gaffe_limit": 5,
		}),
		"opponents": [
			{"opp_id": "A", "name": "First", "intent_pattern": [["block", 1]]},
			{"opp_id": "B", "name": "Second", "intent_pattern": [["block", 1]]},
			{"opp_id": "C", "name": "Third", "intent_pattern": [["block", 1]]},
		],
	})


func _engine(mode: String) -> BattleEngine:
	var engine := BattleEngine.new()
	assert_true(engine.setup(_config(mode)), "setup failed: %s" % [engine.setup_problems])
	return engine


func _beat_first(engine: BattleEngine) -> void:
	engine.state.bar.player_gains(20)
	engine._check_outcome()


func test_no_checkpoint_before_anyone_is_defeated() -> void:
	assert_true(_engine("reset").checkpoint().is_empty())


func test_no_checkpoint_when_the_stage_has_one_opponent() -> void:
	var config := TestFixtures.battle_config()
	var engine := BattleEngine.new()
	engine.setup(config)
	assert_true(engine.checkpoint().is_empty())


func test_a_committee_resumes_at_the_next_opponent() -> void:
	var first := _engine("reset")
	_beat_first(first)
	var saved := first.checkpoint()
	assert_false(saved.is_empty())

	var second := _engine("reset")
	second.restore_checkpoint(saved)
	assert_eq(second.current_opponent()["name"], "Second")
	assert_eq(second.state.opponent_index, 1)
	assert_eq(second.state.turn, 1)
	assert_eq(second.state.bar.player, 40, "a fresh bout starts level")


func test_a_floor_debate_keeps_its_gaffes_hand_and_guard() -> void:
	var first := _engine("continuous")
	first.state.gaffe = 2
	first.state.block = 3
	first.state.turn = 3
	_beat_first(first)
	var saved := first.checkpoint()

	var second := _engine("continuous")
	second.restore_checkpoint(saved)
	assert_eq(second.state.opponent_index, 1)
	assert_eq(second.state.gaffe, 2, "gaffes follow you in")
	assert_eq(second.state.block, 3, "guard follows you in")
	assert_eq(second.state.turn, 3, "the clock follows you in")
	assert_eq(second.state.hand, first.state.hand, "and so does the hand")
	assert_eq(second.state.bar.player, 40, "support starts again")


func test_the_checkpoint_survives_a_save_file_round_trip() -> void:
	var first := _engine("continuous")
	first.state.pleased_boosters.append("BO01")
	first.state.booster_tally = {"BO01": 2}
	_beat_first(first)
	var through_json: Variant = JSON.to_native(JSON.from_native(first.checkpoint()))

	var second := _engine("continuous")
	second.restore_checkpoint(through_json as Dictionary)
	assert_eq(second.state.pleased_boosters, ["BO01"])
	assert_eq(int(second.state.booster_tally.get("BO01", 0)), 2)


func test_no_checkpoint_once_the_stage_is_over() -> void:
	var engine := _engine("reset")
	for bout in 3:
		_beat_first(engine)
	assert_true(engine.state.is_over())
	assert_true(engine.checkpoint().is_empty())


func test_the_run_saves_and_loads_its_checkpoint() -> void:
	GameState.stage_checkpoint = {"key": "L1:0:ST01", "item_bonuses": {"ENERGY": 1}, "engine": {"opponent_index": 1}}
	var saved := GameState.to_save()
	GameState.stage_checkpoint = {}
	GameState.load_save(saved)
	assert_eq(str(GameState.stage_checkpoint.get("key", "")), "L1:0:ST01")
	GameState.stage_checkpoint = {}
