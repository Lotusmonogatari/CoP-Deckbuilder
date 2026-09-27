extends GutTest
## GameState.reset_booster_standing(): standing.json's own "start_by_booster"
## table (2026-09-28) lets an organisation start somewhere other than the
## flat "start" — GameState is an autoload, so these tests put it back the
## way they found it.

var _standing_before: Dictionary = {}
var _change_before: Dictionary = {}
var _booster_standing_data_before: Dictionary = {}


func before_each() -> void:
	_standing_before = GameState.booster_standing.duplicate(true)
	_change_before = GameState.last_booster_change.duplicate(true)
	_booster_standing_data_before = DataDB.booster_standing.duplicate(true)


func after_each() -> void:
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.last_booster_change = _change_before.duplicate(true)
	DataDB.booster_standing = _booster_standing_data_before.duplicate(true)


func test_a_booster_with_no_override_starts_at_the_flat_default() -> void:
	DataDB.booster_standing = {"start": 50, "start_by_booster": {}}
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 50)


func test_a_booster_named_in_the_table_starts_at_its_own_value() -> void:
	DataDB.booster_standing = {"start": 50, "start_by_booster": {"BO01": 70}}
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 70)


func test_every_other_booster_still_falls_back_to_the_flat_default() -> void:
	DataDB.booster_standing = {"start": 50, "start_by_booster": {"BO01": 70}}
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO02"]), 50)


func test_a_missing_table_falls_back_to_the_flat_default_for_everyone() -> void:
	DataDB.booster_standing = {"start": 50}
	GameState.reset_booster_standing()
	assert_eq(int(GameState.booster_standing["BO01"]), 50)
