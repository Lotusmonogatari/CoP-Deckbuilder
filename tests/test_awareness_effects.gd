extends GutTest
## What name awareness does (2026-10-23): the Awareness Effects tab's seven rows.

var _effects: Array = []
var _awareness_before: Dictionary = {}
var _streaks_before: Dictionary = {}
var _inventory_before: Dictionary = {}
var _xp_before := 0
var _standing_before: Dictionary = {}
var _funds_before := 0
var _calendar_before: Dictionary = {}


func before_each() -> void:
	_effects = DataDB.awareness_effects
	_awareness_before = GameState.awareness.duplicate()
	_streaks_before = GameState.awareness_streaks.duplicate()
	_inventory_before = GameState.inventory.duplicate()
	_xp_before = GameState.xp
	_standing_before = GameState.booster_standing.duplicate(true)
	_funds_before = int(GameState.meta.get("Funds", 0))
	_calendar_before = GameState.calendar.duplicate()
	GameState.awareness_streaks = {}


func after_each() -> void:
	GameState.awareness = _awareness_before
	GameState.awareness_streaks = _streaks_before
	GameState.inventory = _inventory_before
	GameState.xp = _xp_before
	GameState.booster_standing = _standing_before
	GameState.meta["Funds"] = _funds_before
	GameState.calendar = _calendar_before


func test_the_tab_ships_the_seven_agreed_rows() -> void:
	assert_eq(_effects.size(), 7)


func test_conditions_read_at_least_and_at_most() -> void:
	var at_least := {"meter": "National", "condition": "At least", "threshold": 65}
	assert_true(AwarenessEffects.is_met(at_least, {"national": 65, "district": 0}))
	assert_false(AwarenessEffects.is_met(at_least, {"national": 64, "district": 0}))
	var at_most := {"meter": "District", "condition": "At most", "threshold": 50}
	assert_true(AwarenessEffects.is_met(at_most, {"national": 0, "district": 50}))
	assert_false(AwarenessEffects.is_met(at_most, {"national": 0, "district": 51}))


func test_national_80_takes_100000_off_the_dues() -> void:
	assert_eq(AwarenessEffects.dues_reduction(_effects, {"national": 80, "district": 0}), 100000)
	assert_eq(AwarenessEffects.dues_reduction(_effects, {"national": 79, "district": 0}), 0)


func test_national_65_starts_press_ambush_and_tv_rooms_five_ahead() -> void:
	var high := {"national": 65, "district": 0}
	for stage_id: String in ["ST04", "ST06", "ST19"]:
		assert_eq(AwarenessEffects.stage_start_bonus(_effects, high, stage_id), 5, stage_id)
	assert_eq(AwarenessEffects.stage_start_bonus(_effects, high, "ST02"), 0, "not a floor debate")
	assert_eq(AwarenessEffects.stage_start_bonus(_effects, {"national": 64, "district": 0}, "ST04"), 0)


func test_district_65_starts_town_halls_five_ahead() -> void:
	assert_eq(AwarenessEffects.stage_start_bonus(_effects, {"national": 0, "district": 65}, "ST05"), 5)
	assert_eq(AwarenessEffects.stage_start_bonus(_effects, {"national": 0, "district": 64}, "ST05"), 0)


func test_a_week_of_low_national_awareness_escalates() -> void:
	var low := {"national": 30, "district": 60}
	var streaks := {}
	for week in [1, 2, 3]:
		var result := AwarenessEffects.week_end(_effects, low, streaks)
		streaks = result["streaks"]
		var found := 0
		for entry: Dictionary in result["applied"]:
			if str((entry["effect"] as Dictionary)["effect_id"]) == "AE07":
				found = int(entry["amount"])
		assert_eq(found, -5 * week, "week %d" % week)
	var recovered := AwarenessEffects.week_end(_effects, {"national": 50, "district": 60}, streaks)
	assert_eq(int((recovered["streaks"] as Dictionary)["AE07"]), 0, "recovering resets the run")


func test_a_week_end_in_the_game_applies_the_penalties() -> void:
	GameState.calendar = {"week": 0, "phase": "weekend", "hours": 0}
	GameState.awareness = {"district": 20, "national": 30}
	GameState.xp = 100
	GameState.booster_standing["BO32"] = 60
	GameState.booster_standing["BO05"] = 60
	GameState.meta["Funds"] = 0
	var lines := GameState._apply_awareness_week_end()
	assert_eq(GameState.xp, 50, "district 25 or less: -50 XP")
	assert_lt(int(GameState.booster_standing["BO32"]), 60, "district 50 or less: the Selection Committee")
	assert_eq(int(GameState.booster_standing["BO05"]), 55, "national 40 or less: a National organization")
	assert_gt(lines.size(), 0)


func test_district_80_earns_a_free_training_coupon_at_week_end() -> void:
	GameState.awareness = {"district": 85, "national": 50}
	GameState.inventory.erase("SH21")
	GameState._apply_awareness_week_end()
	assert_eq(int(GameState.inventory.get("SH21", 0)), 1)


func test_high_national_awareness_lowers_the_dues_in_the_game() -> void:
	GameState.meta["Party support"] = 40
	GameState.awareness = {"district": 0, "national": 10}
	var before := int(GameState.dues_preview()["week_dues"])
	GameState.awareness = {"district": 0, "national": 85}
	assert_eq(int(GameState.dues_preview()["week_dues"]), before - 100000)
