extends GutTest
## P19 (2026-11-25, Cameron): tools/economy_map.py re-implements the dues and wage formulas in Python to price the standard week. This runs the
## real PartyDues and StaffLoyalty on the same inputs (design/economy/economy_week.json, written by the tool) and fails if the two disagree,
## so a change to either side that is not mirrored shows up here.

const WEEK_FILE := "res://design/economy/economy_week.json"


func _week() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WEEK_FILE))
	assert_true(parsed is Dictionary, "economy_week.json is readable (run python3 tools/economy_map.py)")
	return parsed if parsed is Dictionary else {}


func test_the_weeks_dues_equal_the_real_party_dues() -> void:
	var week := _week()
	var cfg := PartyDues.settings(DataDB.balance)
	for name: String in ["standard", "early"]:
		var w: Dictionary = week[name]
		assert_eq(PartyDues.week_dues(cfg, int(w["party_support"]), int(week["funds_earned"])), int(w["dues"]), "%s week dues" % name)


func test_the_weeks_wages_equal_the_real_wage_formula() -> void:
	var week := _week()
	assert_eq(float(DataDB.balance.get("staff_wage_percent", 0)), float(week["wage_percent"]), "the same wage percent")
	for name: String in ["standard", "early"]:
		var w: Dictionary = week[name]
		var total := 0
		for invested: Variant in w["invested"]:
			total += StaffLoyalty.wage(int(invested), false)
		assert_eq(total, int(w["wages"]), "%s week wages" % name)


func test_the_dues_settings_the_tool_read_are_the_games() -> void:
	var week := _week()
	var cfg := PartyDues.settings(DataDB.balance)
	var tool: Dictionary = week["dues_balance"]
	for key: String in ["base", "support_start", "support_step", "step_amount", "max_per_week"]:
		assert_eq(int(tool[key]), int(cfg[key]), "dues %s" % key)
	assert_eq(float(tool["reward_percent"]), float(cfg["reward_percent"]), "dues share percent")
