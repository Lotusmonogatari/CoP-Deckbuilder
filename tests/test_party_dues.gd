extends GutTest
## Party dues (2026-10-23): the formula, the overdue penalties, and a week end
## in the real GameState.

var _cfg := PartyDues.settings({})
var _funds_before := 0
var _support_before := 0
var _owned_before: Array = []
var _balance_before := 0
var _earned_before := 0
var _calendar_before: Dictionary = {}
var _standing_before: Dictionary = {}
var _party_before: Dictionary = {}


func before_each() -> void:
	_funds_before = int(GameState.meta.get("Funds", 0))
	_support_before = int(GameState.meta.get("Party support", 0))
	_owned_before = GameState.owned_modifiers.duplicate()
	_balance_before = GameState.dues_balance
	_earned_before = GameState.week_funds_earned
	_calendar_before = GameState.calendar.duplicate()
	_standing_before = GameState.booster_standing.duplicate(true)
	_party_before = GameState.party_standing.duplicate(true)
	GameState.dues_balance = 0
	GameState.week_funds_earned = 0
	GameState.calendar = WeekCalendar.fresh()


func after_each() -> void:
	GameState.meta["Funds"] = _funds_before
	GameState.meta["Party support"] = _support_before
	GameState.owned_modifiers.assign(_owned_before)
	GameState.dues_balance = _balance_before
	GameState.week_funds_earned = _earned_before
	GameState.calendar = _calendar_before
	GameState.booster_standing = _standing_before
	GameState.party_standing = _party_before


func test_base_dues_rise_50000_for_each_15_points_above_40() -> void:
	assert_eq(PartyDues.base_dues(_cfg, 40), 100000)
	assert_eq(PartyDues.base_dues(_cfg, 54), 100000, "14 above 40 is not a full step")
	assert_eq(PartyDues.base_dues(_cfg, 55), 150000)
	assert_eq(PartyDues.base_dues(_cfg, 70), 200000)
	assert_eq(PartyDues.base_dues(_cfg, 100), 300000, "100 is four steps")
	assert_eq(PartyDues.base_dues(_cfg, 10), 100000, "below 40 adds nothing")


func test_weekday_rewards_add_30_percent() -> void:
	assert_eq(PartyDues.week_dues(_cfg, 40, 400000), 100000 + 120000)


func test_national_awareness_can_cut_the_base() -> void:
	assert_eq(PartyDues.base_dues(_cfg, 40, 100000), 0)
	assert_eq(PartyDues.base_dues(_cfg, 40, 250000), 0, "never below nothing")


func test_settling_pays_what_funds_allow_and_keeps_the_rest() -> void:
	assert_eq(PartyDues.settle(200000, 500000), {"paid": 200000, "owed": 0})
	assert_eq(PartyDues.settle(200000, 50000), {"paid": 50000, "owed": 150000})


func test_overdue_penalties_grow_by_1_5_per_100000() -> void:
	assert_eq(PartyDues.overdue_penalties(_cfg, 0), {})
	var small := PartyDues.overdue_penalties(_cfg, 50000)
	assert_eq(small["hq"], 20)
	assert_eq(small["selection"], 5)
	assert_eq(small["other_parties"], 5)
	assert_eq(small["party_support"], 10)
	var one_step := PartyDues.overdue_penalties(_cfg, 100000)
	assert_eq(one_step["hq"], 30, "20 x 1.5")
	var two_steps := PartyDues.overdue_penalties(_cfg, 200000)
	assert_eq(two_steps["hq"], 45, "20 x 2.25")


func test_party_backings_are_those_triggered_by_a_party_tier_organization() -> void:
	var found := PartyDues.party_backings(["M11", "M20", "M17"], DataDB.modifiers, DataDB.boosters)
	assert_true(found.has("M11"), "Party Headquarters")
	assert_true(found.has("M17"), "Party Faction")
	assert_false(found.has("M20"), "Chamber of Commerce is not a party body")


func test_a_week_end_with_enough_funds_pays_in_full() -> void:
	GameState.meta["Funds"] = 400000
	GameState.meta["Party support"] = 40
	GameState.week_funds_earned = 200000
	var report := GameState._settle_dues()
	assert_eq(report["total"], 160000)
	assert_eq(report["paid"], 160000)
	assert_eq(int(GameState.meta["Funds"]), 240000)
	assert_eq(GameState.dues_balance, 0)
	assert_eq(GameState.week_funds_earned, 0)
	assert_false(report["penalized"])


func test_a_short_week_rolls_over_and_costs_the_party_its_backings() -> void:
	GameState.meta["Funds"] = 20000
	GameState.meta["Party support"] = 40
	GameState.booster_standing["BO01"] = 50
	GameState.booster_standing["BO32"] = 50
	GameState.owned_modifiers.append("M11")
	var report := GameState._settle_dues()
	assert_eq(report["paid"], 20000)
	assert_eq(report["owed"], 80000)
	assert_eq(GameState.dues_balance, 80000)
	assert_true(report["penalized"])
	assert_eq(int(GameState.meta["Funds"]), 0)
	assert_eq(int(GameState.meta["Party support"]), 30, "-10")
	assert_eq(int(GameState.booster_standing["BO01"]), 30, "-20")
	assert_lte(int(GameState.booster_standing["BO32"]), 45, "-5, and the Standing Links to Party HQ can take a little more")
	assert_false(GameState.owned_modifiers.has("M11"), "the party's backing is withdrawn")
	assert_true((report["withdrawn"] as Array).size() >= 1)


func test_the_carried_balance_is_added_next_week() -> void:
	GameState.dues_balance = 80000
	GameState.meta["Party support"] = 40
	GameState.meta["Funds"] = 500000
	var report := GameState._settle_dues()
	assert_eq(report["total"], 180000)
	assert_eq(GameState.dues_balance, 0)


func test_weekday_funds_count_toward_dues_and_weekend_funds_do_not() -> void:
	GameState._record_meta_change({"Funds": 1000})
	assert_eq(GameState.week_funds_earned, 1000)
	GameState.calendar = {"week": 0, "phase": "weekend", "hours": 0}
	GameState._record_meta_change({"Funds": 5000})
	assert_eq(GameState.week_funds_earned, 1000)
	GameState._record_meta_change({"Funds": -3000})
	assert_eq(GameState.week_funds_earned, 1000, "spending is not earning")


func test_dues_are_saved_with_the_run() -> void:
	GameState.dues_balance = 12345
	GameState.week_funds_earned = 678
	var saved := GameState.to_save()
	assert_eq(int(saved["dues_balance"]), 12345)
	assert_eq(int(saved["week_funds_earned"]), 678)
