extends GutTest
## Fixes from the 2026-11 audit (audit/edge_cases.md E-01 to E-06).

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")


func _config(overrides: Dictionary = {}) -> Dictionary:
	var runner := LevelRunner.new(BattleSetup.expand_level({"level_id": "LVT", "stage_1": "ST02"}))
	var stage: Dictionary = (runner.current_stage() as Dictionary).duplicate(true)
	for key: String in overrides:
		stage[key] = overrides[key]
	var config := BattleSetup.for_playtest_stage(stage, runner.carried_buffs(), GameState.meta)
	config["seed"] = 5
	return config


# E-01: a fight that could never end is refused.
func test_a_blank_win_threshold_or_bar_size_is_refused() -> void:
	for field: String in ["win_threshold", "bar_max"]:
		var engine := BattleEngine.new()
		assert_false(engine.setup(_config({field: null})), "%s blank" % field)
		assert_true(str(engine.setup_problems).contains(field))


# E-02: blank numbers read as their defaults instead of raising an error.
func test_blank_energy_hand_gaffe_and_card_cost_do_not_error() -> void:
	var engine := BattleEngine.new()
	assert_true(engine.setup(_config({"energy_per_turn": null, "hand_size": null, "gaffe_limit": null})))
	assert_eq(engine.state.energy_per_turn, 3)
	assert_eq(engine.state.hand_size, 5)
	assert_eq(engine.state.gaffe_limit, 5)
	assert_eq(engine.card_cost({"cost": null}), 0)


# E-03: reading a newer-version side file leaves saving on.
func test_a_newer_backup_file_does_not_switch_saving_off() -> void:
	var path := "user://audit_newer_backup.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 99, "run": {"xp": 1}}))
	file.close()
	var before := SaveManager.enabled
	assert_false(SaveManager.load_game(path))
	assert_eq(SaveManager.last_problem, "newer")
	assert_eq(SaveManager.enabled, before, "saving stays as it was")
	DirAccess.remove_absolute(path)


# E-05 and E-06: a loaded save is put right.
func test_a_healthy_run_is_left_alone_by_the_load_check() -> void:
	assert_eq(GameState.sanitize_loaded_run(), 0)


func test_the_load_check_repairs_ranges_the_clock_and_the_deck() -> void:
	GameState.meta["Reputation"] = 9999
	GameState.meta["Funds"] = 5000000000
	GameState.booster_standing["BO01"] = -40
	GameState.xp = -5
	GameState.time_units = -9
	GameState.deck = ["C23"]
	var changed := GameState.sanitize_loaded_run()
	assert_gte(changed, 6)
	assert_eq(int(GameState.meta["Reputation"]), 100)
	assert_eq(int(GameState.meta["Funds"]), int(DataDB.get_sanban("Funds").get("max", 0)))
	assert_eq(int(GameState.booster_standing["BO01"]), 0)
	assert_eq(GameState.xp, 0)
	assert_eq(GameState.time_units, 0)
	assert_eq(GameState.deck.size(), GameState.deck_size(), "the deck is refilled to its size")


func test_funds_above_the_current_cap_are_kept() -> void:
	# A lowered cap must never take back what the player holds (MetaRules.clamp_meta).
	GameState.meta["Funds"] = GameState.funds_limit() + 1
	GameState.sanitize_loaded_run()
	assert_eq(int(GameState.meta["Funds"]), GameState.funds_limit() + 1)


func test_a_text_standing_in_a_save_is_not_loaded() -> void:
	var run := GameState.to_save()
	(run["booster_standing"] as Dictionary)["BO01"] = "high"
	var fresh := int(GameState.booster_standing["BO01"])
	GameState.load_save(run)
	assert_eq(int(GameState.booster_standing["BO01"]), fresh)
	assert_true(GameState.booster_standing["BO01"] is int or GameState.booster_standing["BO01"] is float)


# F-25: the button outline colour follows the protagonist without a per-frame check.
func test_the_outline_colour_follows_the_protagonist_and_layout_does_not_run_every_frame() -> void:
	assert_false(Layout.is_processing(), "Layout needs no frame")
	DataDB.use_protagonist("PC03")
	var party_three := Layout._outline_party
	DataDB.use_protagonist("PC01")
	assert_ne(Layout._outline_party, party_three, "a different party colour after switching protagonist")
