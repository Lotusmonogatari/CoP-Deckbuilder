extends GutTest
## GameState.reset_booster_standing(): a booster row's own "starting_standing"
## (the workbook's Boosters tab, "Starting Standing" column, 2026-09-28) lets
## an organisation start somewhere other than booster_standing.json's flat
## "start" — GameState is an autoload, so these tests put it back the way
## they found it.

var _standing_before: Dictionary = {}
var _change_before: Dictionary = {}
var _boosters_before: Array = []
var _booster_standing_data_before: Dictionary = {}


func before_each() -> void:
	_standing_before = GameState.booster_standing.duplicate(true)
	_change_before = GameState.last_booster_change.duplicate(true)
	_boosters_before = DataDB.boosters.duplicate(true)
	_booster_standing_data_before = DataDB.booster_standing.duplicate(true)
	DataDB.booster_standing = {"start": 50}


func after_each() -> void:
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.last_booster_change = _change_before.duplicate(true)
	DataDB.boosters = _boosters_before.duplicate(true)
	DataDB.booster_standing = _booster_standing_data_before.duplicate(true)


func test_a_booster_with_a_blank_column_starts_at_the_flat_default() -> void:
	DataDB.boosters = [{"booster_id": "BO01", "starting_standing": null}]
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 50)


func test_a_booster_with_its_own_value_starts_there_instead() -> void:
	DataDB.boosters = [{"booster_id": "BO01", "starting_standing": 70}]
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 70)


func test_each_booster_reads_its_own_column_independently() -> void:
	DataDB.boosters = [
		{"booster_id": "BO01", "starting_standing": 70},
		{"booster_id": "BO02", "starting_standing": null},
	]
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 70)
	assert_eq(int(GameState.booster_standing["BO02"]), 50)


func test_a_missing_column_key_falls_back_to_the_flat_default_too() -> void:
	DataDB.boosters = [{"booster_id": "BO01"}]
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 50)
