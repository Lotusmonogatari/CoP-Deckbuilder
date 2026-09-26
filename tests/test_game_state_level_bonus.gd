extends GutTest
## GameState._apply_level_bonus_win()'s booster loop: every booster in
## data/boosters.json gets a chance at its own win_delta_boNN column, not a
## hardcoded 16 (2026-09-27 simplification — see
## design/proposals/code_simplification_plan.md, item B2). GameState is an
## autoload, so these tests put it back the way they found it.

var _standing_before: Dictionary = {}
var _change_before: Dictionary = {}
var _boosters_before: Array = []


func before_each() -> void:
	_standing_before = GameState.booster_standing.duplicate(true)
	_change_before = GameState.last_booster_change.duplicate(true)
	_boosters_before = DataDB.boosters.duplicate(true)


func after_each() -> void:
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.last_booster_change = _change_before.duplicate(true)
	DataDB.boosters = _boosters_before.duplicate(true)


## A booster past the old hardcoded range(1, 17) — the actual point of this
## simplification (B2). Proves the loop reaches whatever DataDB.boosters
## holds, not a number baked into GameState.gd. BO99 rather than BO17:
## BO17/BO18 are real boosters since the 2026-09-26 pull (Member of
## Parliament / Constituency Voters), and appending a second, fake "BO17"
## alongside the real one made the loop apply this test's own win_delta_bo17
## twice — once per row sharing that ID.
func test_a_booster_past_the_old_hardcoded_sixteen_still_gets_its_column() -> void:
	DataDB.boosters.append({"booster_id": "BO99", "name_en": "Test Booster"})
	GameState.booster_standing["BO99"] = 50
	GameState._apply_level_bonus_win({"win_delta_bo99": {"min": 4, "max": 4}})
	assert_eq(int(GameState.booster_standing["BO99"]), 54)


## A flat delta (not a range) for every real booster moves every real
## booster — proves the loop reaches all of DataDB.boosters, not a fixed
## count baked into the function.
func test_every_real_booster_gets_its_own_column_read() -> void:
	var level := {}
	for booster: Dictionary in DataDB.boosters:
		var booster_id := str(booster.get("booster_id", ""))
		level["win_delta_" + booster_id.to_lower()] = {"min": 3, "max": 3}
		GameState.booster_standing[booster_id] = 50

	GameState._apply_level_bonus_win(level)

	for booster: Dictionary in DataDB.boosters:
		var booster_id := str(booster.get("booster_id", ""))
		assert_eq(int(GameState.booster_standing[booster_id]), 53,
			"%s should have moved" % booster_id)


## A level that names no win_delta_bo* columns moves nothing — the loop
## reads real data, it does not invent a reward.
func test_a_level_with_no_booster_columns_moves_nothing() -> void:
	for booster: Dictionary in DataDB.boosters:
		GameState.booster_standing[str(booster.get("booster_id", ""))] = 50

	GameState._apply_level_bonus_win({})

	for booster: Dictionary in DataDB.boosters:
		assert_eq(int(GameState.booster_standing[str(booster.get("booster_id", ""))]), 50)
