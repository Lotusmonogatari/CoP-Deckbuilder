extends GutTest
## Gating half of the bill levels behind events and hosting (2026-10-23).

var _discovered_before: Array = []
var _calendar_before: Dictionary = {}
var _inventory_before: Dictionary = {}
var _units_before := 0


func before_each() -> void:
	_discovered_before = GameState.discovered_levels.duplicate()
	_calendar_before = GameState.calendar.duplicate()
	_inventory_before = GameState.inventory.duplicate()
	_units_before = GameState.time_units
	GameState.discovered_levels = []
	GameState.calendar = WeekCalendar.fresh()


func after_each() -> void:
	GameState.discovered_levels.assign(_discovered_before)
	GameState.calendar = _calendar_before
	GameState.inventory = _inventory_before
	GameState.time_units = _units_before


func _bill_levels_by_tier() -> Dictionary:
	var by_tier := {}
	for level: Dictionary in DataDB.levels:
		var has_bill := false
		for slot in range(1, 11):
			if str(level.get("stage_%d" % slot, "")).begins_with("BI"):
				has_bill = true
		if has_bill:
			var tier := int(level.get("tier", 0))
			if not by_tier.has(tier):
				by_tier[tier] = []
			by_tier[tier].append(level)
	return by_tier


func test_half_of_each_tiers_bill_levels_are_gated() -> void:
	var by_tier := _bill_levels_by_tier()
	for tier: int in by_tier.keys():
		var all: Array = by_tier[tier]
		var gated := 0
		for level: Dictionary in all:
			if str(level.get("needs_discovery", "")) == "Yes":
				gated += 1
		assert_eq(gated, all.size() / 2, "tier %d gates half (rounded down) of %d" % [tier, all.size()])


func test_every_gated_level_can_be_reached() -> void:
	var by_event := {}
	for row: Dictionary in DataDB.event_choices:
		if row.get("unlocks_level") != null:
			by_event[str(row["unlocks_level"])] = true
	for level: Dictionary in DataDB.levels:
		if str(level.get("needs_discovery", "")) != "Yes":
			continue
		var id := str(level["level_id"])
		var hosted: Variant = level.get("host_org")
		assert_true(by_event.has(id) or (hosted != null and str(hosted) != ""), "%s has a way in" % id)


func test_hosting_reveals_one_hidden_level_at_a_time() -> void:
	assert_eq(GameState.reveal_by_hosting("BO05"), "Special Economic Zones Act")
	assert_eq(GameState.reveal_by_hosting("BO05"), "Integrated Resort Act")
	assert_eq(GameState.reveal_by_hosting("BO05"), "Yezo–China Trade Normalization Act")
	assert_eq(GameState.reveal_by_hosting("BO05"), "", "nothing left to reveal for BO05")
	assert_eq(GameState.reveal_by_hosting("BO15"), "", "an organization with none")


func test_the_dinner_takes_four_hours_and_can_reveal_a_bill() -> void:
	GameState.inventory["SH19"] = 1
	var result := GameState.use_item_in_office("SH19", "BO16")
	assert_true(result["ok"])
	assert_eq(int(GameState.calendar["hours"]), 4)
	assert_true(str(result["message"]).contains("Grid Resilience") or str(result["message"]).contains("Carbon Levy") or str(result["message"]).contains("Digital"), result["message"])
	assert_eq(GameState.discovered_levels.size(), 1)


func test_a_gathering_is_refused_when_the_week_is_full() -> void:
	GameState.calendar = {"week": 0, "phase": "work", "hours": 40}
	GameState.inventory["SH20"] = 1
	assert_false(GameState.use_item_in_office("SH20", "BO07")["ok"])
	assert_eq(int(GameState.inventory["SH20"]), 1, "nothing used")


func test_a_gathering_must_fit_the_weekend_hours_left() -> void:
	GameState.calendar = {"week": 0, "phase": "weekend", "hours": 6}
	GameState.inventory["SH20"] = 1
	assert_false(GameState.use_item_in_office("SH20", "BO07")["ok"])
	GameState.calendar = {"week": 0, "phase": "weekend", "hours": 4}
	assert_true(GameState.use_item_in_office("SH20", "BO07")["ok"])


func test_the_new_short_levels_fit_a_weekend_day() -> void:
	for level_id: String in ["LV88", "LV89", "LV90", "LV91", "LV92", "LV93"]:
		var level := DataDB.get_level(level_id)
		assert_eq(str(level["weekend_ok"]), "Yes", level_id)
		assert_lte(GameState.level_hours(level), 4, level_id)


func test_every_festival_variant_seats_ten_distinct_constituents() -> void:
	for level_id: String in ["LV87", "LV92", "LV93"]:
		var expanded := BattleSetup.expand_level(DataDB.get_level(level_id))
		var visitors: Array = ((expanded["stages"] as Array)[0] as Dictionary).get("visitors", [])
		assert_eq(visitors.size(), 10, level_id)
		var seen := {}
		for visitor: Dictionary in visitors:
			seen[str(visitor["visitor_id"])] = true
			assert_false((visitor.get("question", {}) as Dictionary).is_empty())
		assert_eq(seen.size(), 10, level_id)
