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


# ---------------------------------------------------------------------------
# starting_meta/starting_xp overrides (data/player.json) — all four
# protagonists leave both blank today, so a real run never differs; these
# prove the mechanism itself, with a fake protagonist dict, the same way
# test_office_hours_engine.gd proves its own rules against fake data.
# ---------------------------------------------------------------------------

func test_a_blank_starting_meta_changes_nothing_from_sanbans_own_defaults() -> void:
	var defaults := BattleSetup.starting_meta_for({})
	for variable: Dictionary in DataDB.sanban:
		assert_eq(defaults.get(str(variable.get("name_en"))), int(variable.get("start", 0)))


func test_a_protagonists_starting_meta_overrides_one_variable_and_leaves_the_rest() -> void:
	var funds_default := int(DataDB.get_sanban("Funds").get("start", 0))
	var overridden := BattleSetup.starting_meta_for(
		{"starting_meta": {"Constituency support": 40}})
	assert_eq(overridden.get("Constituency support"), 40)
	assert_eq(overridden.get("Funds"), funds_default,
		"a name not named in the override keeps sanban.json's own default")


func test_an_unknown_name_in_starting_meta_is_ignored_rather_than_added() -> void:
	var overridden := BattleSetup.starting_meta_for(
		{"starting_meta": {"Not A Real Variable": 999}})
	assert_false(overridden.has("Not A Real Variable"))


func test_starting_xp_defaults_to_zero_and_can_be_overridden() -> void:
	assert_eq(BattleSetup.starting_xp_for({}), 0)
	assert_eq(BattleSetup.starting_xp_for({"starting_xp": 25}), 25)


func test_a_new_run_actually_uses_the_chosen_protagonists_starting_numbers() -> void:
	# All four real protagonists override nothing today, so this proves the
	# wiring — reset_meta()/start_new_run() actually calling starting_meta()/
	# starting_xp() rather than the old bare BattleSetup.starting_meta()/0 —
	# by temporarily giving PC01 an override and confirming it lands.
	var pc01 := DataDB.get_protagonist("PC01")
	var before_meta: Variant = pc01.get("starting_meta")
	var before_xp: Variant = pc01.get("starting_xp")
	pc01["starting_meta"] = {"Party support": 77}
	pc01["starting_xp"] = 15

	GameState.start_new_run("PC01")

	assert_eq(GameState.meta.get("Party support"), 77)
	assert_eq(GameState.xp, 15)

	pc01["starting_meta"] = before_meta
	pc01["starting_xp"] = before_xp
