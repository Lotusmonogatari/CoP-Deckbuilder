extends GutTest
## The higher-tier non-combat levels (LV102-LV113, 2026-11-09) follow the
## schematic: a Tier 1 level has 2 stages and a Tier 2 level has 3, every
## stage is a Non-combat room, pay per hour stays near the Tier 0 rate, and
## nothing runs longer than the work week.

const FIRST := 102
const LAST := 113


func _levels() -> Array:
	return DataDB.levels.filter(func(l: Dictionary) -> bool:
		var n := int(str(l.get("level_id", "LV0")).substr(2))
		return n >= FIRST and n <= LAST)


func _sum(level: Dictionary, key: String) -> int:
	var total := 0
	for i in range(1, 11):
		var stage := DataDB.get_stage(str(level.get("stage_%d" % i, "")))
		if not stage.is_empty():
			total += int(stage.get(key, 0) if stage.get(key) != null else 0)
	return total


func test_twelve_levels_exist() -> void:
	assert_eq(_levels().size(), 12)


func test_stage_counts_follow_tier() -> void:
	for level: Dictionary in _levels():
		var count := 0
		for i in range(1, 11):
			var stage := DataDB.get_stage(str(level.get("stage_%d" % i, "")))
			if not stage.is_empty():
				count += 1
				assert_eq(str(stage.get("mode", "")), "Non-combat", "%s stage %d" % [level["level_id"], i])
		assert_eq(count, 2 if int(level["tier"]) == 1 else 3, str(level["level_id"]))


func test_pay_per_hour_stays_near_tier_zero() -> void:
	for level: Dictionary in _levels():
		var hours := _sum(level, "time_units")
		var rate := float(_sum(level, "win_delta_xp")) / maxf(hours, 1.0)
		assert_between(rate, 20.0, 25.0, "%s XP per hour" % level["level_id"])
		assert_between(hours, 5, 12, "%s hours" % level["level_id"])


func test_higher_tiers_are_gated_and_priced() -> void:
	for level: Dictionary in _levels():
		var hidden := str(level.get("needs_discovery", "")) == "Yes"
		var seasonal := level.get("seasons") != null
		assert_true(hidden or seasonal, "%s is gated" % level["level_id"])
		assert_gt(int(level["unlock_cost_vacant"]), 0, "%s has a price" % level["level_id"])


func test_level_list_split_knows_non_combat_levels() -> void:
	var stages := {}
	for stage: Dictionary in DataDB.stages:
		stages[str(stage["stage_id"])] = stage
	assert_true(Ledger.level_is_non_combat(DataDB.get_level("LV86"), stages), "Office Hours")
	assert_true(Ledger.level_is_non_combat(DataDB.get_level("LV103"), stages), "District Tour")
	assert_false(Ledger.level_is_non_combat(DataDB.get_level("LV01"), stages), "a combat level")
