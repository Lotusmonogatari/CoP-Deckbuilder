extends GutTest
## The four main characters (data/player.json) and choosing one.

var _saved_run: Dictionary = {}


func before_each() -> void:
	_saved_run = GameState.to_save()


func after_each() -> void:
	GameState.load_save(_saved_run)


func test_there_are_four_protagonists_with_unique_ids() -> void:
	assert_eq(DataDB.protagonists.size(), 4)
	var ids: Array = DataDB.protagonists.map(func(p: Dictionary) -> String: return str(p["player_id"]))
	for id: String in ids:
		assert_eq(ids.count(id), 1, "%s is listed once" % id)


func test_the_default_protagonist_is_in_play_until_one_is_chosen() -> void:
	assert_false(DataDB.get_protagonist("PC01").is_empty())


func test_choosing_a_protagonist_puts_them_in_play() -> void:
	assert_true(GameState.start_new_run("PC03"))
	assert_eq(DataDB.player.get("player_id"), "PC03")
	assert_eq(GameState.protagonist_id, "PC03")


func test_an_unknown_protagonist_changes_nothing() -> void:
	GameState.start_new_run("PC02")
	assert_false(GameState.start_new_run("PC99"))
	assert_eq(DataDB.player.get("player_id"), "PC02")


func test_a_new_run_starts_every_number_again() -> void:
	GameState.xp = 500
	GameState.inventory = {"SH04": 3}
	GameState.start_new_run("PC01")
	assert_eq(GameState.xp, 0)
	assert_true(GameState.inventory.is_empty())
	assert_false(GameState.awaiting_new_game)


func test_the_caucus_is_named_for_the_chosen_protagonists_party() -> void:
	GameState.start_new_run("PC01")
	var party := str(DataDB.player.get("party", ""))
	assert_eq(BattleSetup.fill_tokens("{party} Caucus"), "%s Caucus" % party)
	# PC02 has no party yet, so the stage is just "Caucus".
	GameState.start_new_run("PC02")
	assert_eq(BattleSetup.fill_tokens("{party} Caucus"), "Caucus")


func test_the_cue_speaker_is_the_chosen_protagonist() -> void:
	GameState.start_new_run("PC04")
	assert_eq(CardCues.speaker(), "PC04")
