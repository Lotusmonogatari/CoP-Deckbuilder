extends GutTest
## Saving and loading a run (SaveManager + GameState.to_save()/load_save()).
## Writes to a scratch file in user://, never the player's real save.

const PATH := "user://test_savegame.json"

var _saved_run: Dictionary = {}


func before_each() -> void:
	_saved_run = GameState.to_save()
	SaveManager.delete_save(PATH)


func after_each() -> void:
	SaveManager.delete_save(PATH)
	GameState.load_save(_saved_run)
	GameState.awaiting_new_game = false
	GameState.mid_stage = false


func _a_run_in_progress() -> void:
	GameState.start_new_run("PC02")
	GameState.xp = 123
	GameState.meta["Funds"] = 4567
	GameState.deck.assign(GameState.deck.slice(0, 5))
	GameState.inventory = {"SH04": 2}
	GameState.pending_stage_bonuses = {"ENERGY": 1}
	GameState.booster_standing["BO03"] = 71
	GameState.staff_hired = {"Media Spokesperson": {"staff_id": "SF08", "tier": 2}}
	GameState.staff_fired = {"SF09": true}
	GameState.levels_unlocked.assign(["LV02"])
	GameState.level_last_completed_at = {"LV01": 1}
	GameState.levels_completed_count = 1
	GameState.town_hall_active = true
	GameState.steering_committee_active = false
	GameState.funding_frozen_active = true
	GameState.stage_type_results = {"ST02": {"wins": 3, "losses": 1}}
	GameState.lifetime_gaffes = 27
	GameState.stages_lost_to_gaffes = 2
	GameState.gaffe_penalty_applied = true


func test_a_run_comes_back_exactly_as_it_was_saved() -> void:
	_a_run_in_progress()
	var before := GameState.to_save()
	assert_true(SaveManager.save_game(PATH))

	GameState.start_new_run("PC01")
	assert_ne(GameState.xp, 123, "sanity: the run really was reset")

	assert_true(SaveManager.load_game(PATH))
	assert_eq(GameState.to_save(), before)
	assert_eq(GameState.protagonist_id, "PC02")
	assert_eq(DataDB.player.get("player_id"), "PC02", "the chosen protagonist is back in play")


func test_whole_numbers_stay_whole_numbers() -> void:
	# Plain JSON turns every number into a decimal; a level_last_completed_at
	# of 1.0 or an inventory count of 2.0 would break comparisons later.
	_a_run_in_progress()
	SaveManager.save_game(PATH)
	SaveManager.load_game(PATH)
	assert_eq(typeof(GameState.xp), TYPE_INT)
	assert_eq(typeof(GameState.inventory["SH04"]), TYPE_INT)
	assert_eq(typeof(GameState.level_last_completed_at["LV01"]), TYPE_INT)


func test_typed_lists_stay_typed() -> void:
	_a_run_in_progress()
	SaveManager.save_game(PATH)
	SaveManager.load_game(PATH)
	assert_true(GameState.deck.is_typed(), "the deck is still an Array[String]")
	assert_eq(GameState.deck.size(), 5)


func test_a_level_in_progress_resumes_at_the_same_stage() -> void:
	_a_run_in_progress()
	var level := BattleSetup.expand_level(DataDB.levels[0])
	var runner := LevelRunner.new(level)
	GameState.begin_level(runner)
	if runner.stage_count() < 2:
		pass_test("the first level has one stage; nothing to resume into")
		return
	runner.finish_stage(LevelRunner.WON, 7, ["BO01"])
	SaveManager.save_game(PATH)

	GameState.start_new_run("PC01")
	SaveManager.load_game(PATH)
	assert_true(GameState.is_in_level())
	assert_eq(GameState.level_runner.index, 1)
	assert_eq(GameState.level_runner.results.keys(), runner.results.keys())
	assert_eq(GameState.level_runner.current_stage(), runner.current_stage(),
		"the same opponents as were dealt, not a fresh draw")
	GameState.end_level()


func test_no_save_loads_nothing() -> void:
	assert_false(SaveManager.load_game(PATH))


func test_a_damaged_file_is_ignored_not_fatal() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	var xp := GameState.xp
	assert_false(SaveManager.load_game(PATH))
	assert_eq(GameState.xp, xp, "the run in memory is untouched")


func test_a_save_from_a_newer_build_is_left_alone() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveManager.VERSION + 1, "run": {}}))
	file.close()
	var was_enabled := SaveManager.enabled
	assert_false(SaveManager.load_game(PATH))
	assert_false(SaveManager.enabled, "and nothing will overwrite it")
	SaveManager.enabled = was_enabled


func test_a_save_missing_newer_fields_still_loads() -> void:
	# A save from an older build has fewer fields; the rest start fresh.
	var run := GameState.to_save()
	run.erase("segment_favorability")
	run["xp"] = 99
	GameState.load_save(run)
	assert_eq(GameState.xp, 99)
	assert_false(GameState.segment_favorability.is_empty())


func test_autosave_waits_while_a_stage_is_being_fought() -> void:
	# The tests run with SaveManager switched off; this checks the guard, not
	# a file.
	GameState.mid_stage = true
	var was := SaveManager.enabled
	SaveManager.enabled = true
	var real_exists := SaveManager.has_save()
	SaveManager.autosave()
	assert_eq(SaveManager.has_save(), real_exists, "no save written mid-stage")
	SaveManager.enabled = was
