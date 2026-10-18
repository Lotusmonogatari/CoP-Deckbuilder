extends GutTest
## Optional durations on the game clock (2026-10-18): a Shop item whose effects
## last N units, and a bought backing that lapses after N units.

var _saved := {}
var _item_row: Dictionary


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")
	_item_row = DataDB.get_shop_item("SH15").duplicate(true)   # +1 energy, normally for a level


func after_each() -> void:
	DataDB.get_shop_item("SH15")["duration_units"] = null
	GameState.load_save(_saved)


func _as_timed(units: int) -> void:
	DataDB.get_shop_item("SH15")["duration_units"] = units


func test_a_timed_item_used_in_the_office_runs_until_its_units_are_up() -> void:
	_as_timed(10)
	GameState.add_item("SH15", 1)
	GameState.time_units = 100
	var used := GameState.use_item_in_office("SH15")
	assert_true(used["ok"])
	GameState.time_units = 105
	assert_eq(int(GameState.take_item_bonuses_for_stage().get("ENERGY", 0)), 1, "still running")
	assert_eq(int(GameState.take_item_bonuses_for_stage().get("ENERGY", 0)), 1, "runs across stages, not once")
	GameState.time_units = 110
	assert_eq(int(GameState.take_item_bonuses_for_stage().get("ENERGY", 0)), 0, "ten units later it is over")
	assert_true(GameState.timed_bonuses.is_empty(), "and forgotten")


func test_a_timed_item_does_not_use_up_the_levels_pending_buffs() -> void:
	_as_timed(10)
	GameState.add_item("SH15", 1)
	GameState.use_item_in_office("SH15")
	assert_true(GameState.pending_level_bonuses.is_empty())
	assert_true(GameState.pending_stage_bonuses.is_empty())


func test_an_item_with_no_duration_units_behaves_as_before() -> void:
	GameState.add_item("SH15", 1)
	GameState.use_item_in_office("SH15")
	assert_eq(int(GameState.pending_level_bonuses.get("ENERGY", 0)), 1)
	assert_true(GameState.timed_bonuses.is_empty())


func test_the_timing_line_for_a_timed_item_names_no_number() -> void:
	_as_timed(10)
	var line := Items.timing_line(DataDB.get_shop_item("SH15"), Items.OFFICE, Text.phrase())
	assert_eq(line, Text.say("item.timing.timed_next"))
	assert_false(line.contains("10"))


func test_a_backing_with_duration_units_lapses_and_can_be_bought_again() -> void:
	var mod_id := "M33"
	var row := DataDB.get_modifier(mod_id)
	row["duration_units"] = 8
	GameState.owned_modifiers.append(mod_id)
	GameState.modifier_expires[mod_id] = GameState.time_units + 8
	GameState.begin_level(LevelRunner.new({"level_id": "TEST", "stages": [
		{"seq": 1, "stage_id": "ST02", "mode": "Combat", "time_units": 7},
		{"seq": 2, "stage_id": "ST02", "mode": "Combat", "time_units": 1}]}))
	GameState.finish_stage(LevelRunner.WON)
	assert_true(GameState.owned_modifiers.has(mod_id), "seven units in, still backing you")
	GameState.finish_stage(LevelRunner.WON)
	assert_false(GameState.owned_modifiers.has(mod_id), "eight units in, it lapses")
	assert_false(GameState.modifier_expires.has(mod_id))
	var alerted := false
	for alert: Dictionary in GameState.pending_trigger_alerts:
		if alert.get("kind") == "backing_lapsed":
			alerted = true
			assert_ne(str(alert.get("name", "")), "")
	assert_true(alerted)
	row["duration_units"] = null


func test_a_backing_with_no_duration_is_permanent() -> void:
	assert_eq(ModifierEffects.duration_units({"duration_units": null}), 0)
	assert_eq(ModifierEffects.duration_units({}), 0)
	assert_eq(ModifierEffects.duration_units({"duration_units": 12}), 12)


func test_the_new_state_is_saved() -> void:
	assert_true("timed_bonuses" in GameState._SAVED_FIELDS)
	assert_true("modifier_expires" in GameState._SAVED_FIELDS)
