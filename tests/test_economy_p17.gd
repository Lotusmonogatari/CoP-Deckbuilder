extends GutTest
## The economy pass (P17, 2026-11-24, Cameron): the 8,000円-and-20-XP hour, the dues limit, Funds earned counted before the Funds limit,
## and the 10% wage. What the pass must never do: put Funds where there were none.

var _funds_before := 0
var _week_before := 0
var _calendar_before: Dictionary = {}


func before_each() -> void:
	_funds_before = int(GameState.meta.get("Funds", 0))
	_week_before = GameState.week_funds_earned
	_calendar_before = GameState.calendar.duplicate()


func after_each() -> void:
	GameState.meta["Funds"] = _funds_before
	GameState.week_funds_earned = _week_before
	GameState.calendar = _calendar_before


func _zero_before() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/p17_zero_funds_before.json"))


# --- nothing that paid 0 or blank Funds pays Funds now ------------------------------------------------------------------

func test_no_room_that_paid_no_funds_pays_funds_now() -> void:
	for stage_id: Variant in _zero_before()["stages"]:
		var stage := DataDB.get_stage(str(stage_id))
		var raw: Variant = stage.get("win_delta_yen")
		assert_true(raw == null or int(raw) == 0, "%s still pays no Funds" % stage_id)


func test_no_level_that_paid_no_funds_bonus_pays_one_now() -> void:
	for level_id: Variant in _zero_before()["levels"]:
		var level := DataDB.get_level(str(level_id))
		var bonus: Variant = level.get("bonus_win_range_yen")
		var paid := bonus is Dictionary and (int((bonus as Dictionary).get("max", 0)) > 0 or int((bonus as Dictionary).get("min", 0)) > 0)
		assert_false(paid, "%s still pays no Funds bonus" % level_id)


func test_a_room_pays_hours_times_the_standard_times_its_factor() -> void:
	# Committee: 4 hours, the Standard band (1.0): 32,000円 and 80 XP. Media Ambush: 1 hour at Easy (0.8): 6,000円 and 16 XP (rounded).
	var committee := DataDB.get_stage("ST01")   # Special Committee, 4 hours
	assert_eq(int(committee["time_units"]), 4)
	assert_eq(int(committee["win_delta_yen"]) % 1000, 0, "Funds are in whole thousands")
	assert_between(float(int(committee["win_delta_yen"])) / 4.0, 6400.0, 10000.0, "Funds per hour sits between 0.8 and 1.25 of 8,000円")
	assert_between(float(int(committee["win_delta_xp"])) / 4.0, 16.0, 25.0, "XP per hour sits between 0.8 and 1.25 of 20")


func test_a_tier_one_level_bonus_is_ten_percent_and_tier_two_twenty_five_of_its_rooms() -> void:
	for level: Dictionary in DataDB.levels:
		var tier := int(level.get("tier", 0))
		var rooms_xp := 0
		for slot in range(1, 11):
			var raw: Variant = level.get("stage_%d" % slot)
			var stage := DataDB.get_stage("" if raw == null else str(raw))
			if not stage.is_empty() and stage.get("win_delta_xp") != null:
				rooms_xp += int(stage["win_delta_xp"])
		var bonus: Variant = level.get("bonus_win_range_xp")
		if tier == 0:
			assert_true(bonus == null, "%s: tier 0 has no XP bonus" % level["level_id"])
		elif rooms_xp > 0:
			var share := 0.10 if tier == 1 else 0.25
			var expected := roundi(rooms_xp * share)
			assert_true(bonus is Dictionary, "%s has an XP bonus" % level["level_id"])
			if bonus is Dictionary:
				assert_eq(int((bonus as Dictionary)["min"]), expected, "%s: XP bonus min" % level["level_id"])
				assert_eq(int((bonus as Dictionary)["max"]), expected, "%s: XP bonus max (min = max)" % level["level_id"])


# --- dues --------------------------------------------------------------------------------------------------------------------

func test_dues_never_exceed_the_weekly_limit() -> void:
	var cfg := PartyDues.settings(DataDB.balance)
	assert_eq(int(cfg["max_per_week"]), 90000)
	for support in [0, 40, 55, 70, 100]:
		for earned in [0, 100000, 260000, 1000000, 5000000]:
			assert_lte(PartyDues.week_dues(cfg, support, earned, 0), 90000, "support %d, earned %d" % [support, earned])
	assert_eq(PartyDues.week_dues(cfg, 70, 260000, 0), 90000, "the middle week of the review: 99,000円 held at the limit")
	assert_eq(PartyDues.week_dues(cfg, 40, 260000, 0), 89000, "the early week: 50,000 + 15% of 260,000 is under the limit")
	assert_true(PartyDues.is_capped(cfg, 70, 260000))
	assert_false(PartyDues.is_capped(cfg, 40, 260000))


func test_the_national_awareness_relief_still_lowers_dues_under_the_limit() -> void:
	var cfg := PartyDues.settings(DataDB.balance)
	assert_eq(PartyDues.week_dues(cfg, 70, 260000, 50000), 40000, "capped at 90,000 first, then 50,000 off")
	assert_eq(PartyDues.week_dues(cfg, 40, 0, 500000), 0, "never below 0")


func test_no_limit_means_no_cap() -> void:
	var cfg := PartyDues.settings({"dues_limit_cap_percent": 0, "dues_reward_percent": 15, "dues_step_amount": 5000})
	assert_eq(PartyDues.week_dues(cfg, 70, 260000, 0), 99000)


func test_dues_count_the_funds_earned_above_the_funds_limit() -> void:
	# A player sitting at the Funds limit who earns 50,000円 still adds 15% of it (7,500円) to the week's dues.
	GameState.calendar = {"week": 2, "phase": "work", "hours": 8}   # a weekday
	GameState.meta["Funds"] = int(GameState._sanban_row("Funds").get("max", 100000))   # the Funds limit
	GameState.week_funds_earned = 0
	var banked_before := int(GameState.meta["Funds"])
	GameState._apply_meta_reward("Funds", 50000)
	assert_eq(int(GameState.meta["Funds"]), banked_before, "nothing more can be banked at the limit")
	assert_eq(GameState.week_funds_earned, 50000, "but all 50,000円 count as earned")
	var cfg := PartyDues.settings(DataDB.balance)
	assert_eq(PartyDues.week_dues(cfg, 40, GameState.week_funds_earned, 0) - PartyDues.base_dues(cfg, 40, 0), 7500)


func test_a_spend_or_a_weekend_win_does_not_count_as_earned() -> void:
	GameState.calendar = {"week": 2, "phase": "work", "hours": 8}
	GameState.week_funds_earned = 0
	GameState.meta["Funds"] = 50000
	GameState._apply_meta_reward("Funds", -10000)
	assert_eq(GameState.week_funds_earned, 0, "a cost is not earnings")
	GameState.calendar = {"week": 2, "phase": WeekCalendar.WEEKEND, "hours": 0}
	GameState._apply_meta_reward("Funds", 20000)
	assert_eq(GameState.week_funds_earned, 0, "weekend Funds do not count toward dues")


# --- wages and prices --------------------------------------------------------------------------------------------------------

func test_wages_are_ten_percent_of_what_is_invested() -> void:
	assert_eq(int(DataDB.balance.get("staff_wage_percent")), 10)
	for invested in [30000, 40000, 130000]:
		assert_eq(StaffLoyalty.wage(invested, false), invested / 10, "wage of %d" % invested)


func test_the_commission_items_and_event_costs_are_the_new_prices() -> void:
	assert_eq(int(DataDB.get_shop_item("SH01")["cost_yen"]), 12000)
	assert_eq(int(DataDB.get_shop_item("SH02")["cost_yen"]), 24000)
	assert_eq(int(DataDB.get_shop_item("SH03")["cost_yen"]), 24000)
	for pair: Array in [["EV03", 10000], ["EV05", 15000], ["EV06", 20000], ["EV31", 6000], ["EV35", 10000], ["EV04", 100000]]:
		assert_eq(int(GameState.get_event(str(pair[0]))["cost_funds"]), int(pair[1]), "%s costs %d" % pair)
