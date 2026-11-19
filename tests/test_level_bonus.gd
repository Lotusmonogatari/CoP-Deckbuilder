extends GutTest
## A level's end-of-level bonus, previewed in the briefing (2026-11-19, Cameron): the preview reads the data,
## scales Funds and XP by the Campaign Pressure, and every payout lands inside it.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = {
		"meta": GameState.meta.duplicate(true), "standing": GameState.booster_standing.duplicate(true),
		"xp": GameState.xp, "xp_gained": GameState.last_xp_gained, "difficulty": GameState.difficulty,
		"links": DataDB.standing_links, "owned": GameState.owned_modifiers.duplicate(),
		"cap": GameState.funds_cap_bonus,
	}


func after_each() -> void:
	GameState.meta = _saved["meta"].duplicate(true)
	GameState.booster_standing = _saved["standing"].duplicate(true)
	GameState.xp = _saved["xp"]
	GameState.last_xp_gained = _saved["xp_gained"]
	GameState.difficulty = _saved["difficulty"]
	DataDB.standing_links = _saved["links"]
	GameState.owned_modifiers.assign(_saved["owned"])
	GameState.funds_cap_bonus = _saved["cap"]


func _level(level_id: String) -> Dictionary:
	return DataDB.get_level(level_id)


# --- the columns ---------------------------------------------------------------

func test_an_organizations_column_and_back() -> void:
	assert_eq(LevelBonus.column_for("BO05"), "win_delta_bo05")
	assert_eq(LevelBonus.org_for("win_delta_bo05"), "BO05")
	assert_eq(LevelBonus.org_for("win_delta_bo32"), "BO32")


func test_other_columns_are_not_organizations() -> void:
	for column in ["win_delta_xp", "win_delta_yen", "bonus_win_range_xp", "level_id", "stage_1"]:
		assert_eq(LevelBonus.org_for(column), "", column)


func test_a_range_cell_reads_as_min_and_max() -> void:
	assert_eq(LevelBonus.range_of({"min": 2, "max": 5}), {"min": 2, "max": 5})
	assert_eq(LevelBonus.range_of({"min": 4, "max": 4}), {"min": 4, "max": 4})
	assert_eq(LevelBonus.range_of({"min": 4, "max": 1}), {"min": 4, "max": 4}, "a max below the min counts as the min")


func test_a_blank_or_odd_cell_is_no_range() -> void:
	assert_eq(LevelBonus.range_of(null), {})
	assert_eq(LevelBonus.range_of("lots"), {})
	assert_eq(LevelBonus.range_of({}), {})


func test_a_chip_range_carries_the_sign_on_the_low_end() -> void:
	assert_eq(LevelBonus.chip_numbers(2, 4), {"low": "+2", "high": "4"})
	assert_eq(LevelBonus.chip_numbers(0, 3), {"low": "0", "high": "3"})
	assert_eq(LevelBonus.chip_numbers(-2, -1), {"low": "-2", "high": "-1"})


# --- the preview ---------------------------------------------------------------

func test_the_preview_reads_the_levels_own_columns() -> void:
	# LV11 (Meeting with Student Organizers) as it stands in the data.
	var level := _level("LV11")
	var bonus := LevelBonus.preview(level, Difficulty.STANDARD, DataDB.balance_base)
	var meta: Dictionary = bonus["meta"]
	assert_eq(meta["Reputation"], LevelBonus.range_of(level["bonus_win_range_reputation"]))
	assert_eq(meta["Party support"], LevelBonus.range_of(level["bonus_win_range_party_support"]))
	assert_eq(meta["Funds"], LevelBonus.range_of(level["bonus_win_range_yen"]), "Standard pays the Funds as written")
	assert_eq(meta[BriefingSummary.XP], LevelBonus.range_of(level["bonus_win_range_xp"]))
	var ids: Array = []
	for org: Dictionary in bonus["orgs"]:
		ids.append(org["id"])
		var cell: Dictionary = level[LevelBonus.column_for(str(org["id"]))]
		assert_eq(int(org["min"]), int(cell["min"]))
		assert_eq(int(org["max"]), int(cell["max"]))
	assert_eq(ids, ["BO03", "BO11", "BO29"])


func test_funds_and_xp_follow_the_campaign_pressure_and_nothing_else_does() -> void:
	var level := _level("LV11")
	var standard := LevelBonus.preview(level, Difficulty.STANDARD, DataDB.balance_base)
	var relaxed := LevelBonus.preview(level, Difficulty.RELAXED, DataDB.balance_base)
	var harder := LevelBonus.preview(level, Difficulty.HARDER, DataDB.balance_base)
	assert_gt(int(relaxed["meta"]["Funds"]["max"]), int(standard["meta"]["Funds"]["max"]))
	assert_lt(int(harder["meta"]["Funds"]["max"]), int(standard["meta"]["Funds"]["max"]))
	assert_eq(relaxed["meta"]["Funds"]["max"],
		Difficulty.payout(int(level["bonus_win_range_yen"]["max"]), DataDB.balance_base, Difficulty.RELAXED))
	assert_gt(int(relaxed["meta"][BriefingSummary.XP]["max"]), int(standard["meta"][BriefingSummary.XP]["max"]))
	for name in ["Reputation", "Party support"]:
		assert_eq(relaxed["meta"][name], standard["meta"][name], "%s is not scaled" % name)
	assert_eq(relaxed["orgs"], standard["orgs"], "organization standing is not scaled")


func test_a_level_with_no_bonus_previews_nothing() -> void:
	var found := 0
	for level: Dictionary in DataDB.levels:
		var bonus := LevelBonus.preview(level, Difficulty.STANDARD, DataDB.balance_base)
		if LevelBonus.is_empty(bonus):
			found += 1
			assert_true((bonus["meta"] as Dictionary).is_empty())
			assert_true((bonus["orgs"] as Array).is_empty())
	assert_gt(found, 0, "some levels pay no bonus")
	assert_true(LevelBonus.is_empty(LevelBonus.preview({}, Difficulty.STANDARD, DataDB.balance_base)))


func test_a_range_that_can_only_pay_zero_is_left_out() -> void:
	var level := {"bonus_win_range_reputation": {"min": 0, "max": 0}, "bonus_win_range_yen": {"min": 0, "max": 0},
		"win_delta_bo05": {"min": 0, "max": 0}, "win_delta_bo06": {"min": 0, "max": 2}}
	var bonus := LevelBonus.preview(level, Difficulty.STANDARD, DataDB.balance_base)
	assert_true((bonus["meta"] as Dictionary).is_empty())
	assert_eq((bonus["orgs"] as Array).size(), 1)
	assert_eq(bonus["orgs"][0]["id"], "BO06")


func test_the_real_data_has_the_counts_the_outline_gave() -> void:
	var with_meta := 0
	var with_orgs := 0
	for level: Dictionary in DataDB.levels:
		var bonus := LevelBonus.preview(level, Difficulty.STANDARD, DataDB.balance_base)
		if not (bonus["meta"] as Dictionary).is_empty():
			with_meta += 1
		if not (bonus["orgs"] as Array).is_empty():
			with_orgs += 1
	assert_eq(with_meta, 74, "levels that pay a meter or XP bonus")
	assert_eq(with_orgs, 69, "levels that pay organization standing")


# --- the honesty check: a payout never leaves its preview ---------------------------

func test_every_payout_lands_inside_its_preview() -> void:
	# The preview promises nothing a payout can break. Standing links (an organization moving another) and
	# owned backings are not previewed, so they are switched off here; the Funds ceiling is lifted too (the
	# rooms' rewards are shown uncapped as well, and LV80's bonus alone is bigger than the ceiling);
	# everything else is the real payout.
	DataDB.standing_links = []
	GameState.owned_modifiers.clear()
	GameState.funds_cap_bonus = 10000000
	var checked := 0
	for tier: String in Difficulty.TIERS:
		GameState.difficulty = tier
		for level: Dictionary in DataDB.levels:
			var bonus := LevelBonus.preview(level, tier, DataDB.balance_base)
			if LevelBonus.is_empty(bonus):
				continue
			for roll in 12:
				_pay_and_check(level, bonus, tier)
				checked += 1
	assert_gt(checked, 1000, "a good many payouts were checked")


func _pay_and_check(level: Dictionary, bonus: Dictionary, tier: String) -> void:
	var where := "%s at %s" % [level.get("level_id"), tier]
	for name: String in ["Constituency support", "Reputation", "Party support"]:
		GameState.meta[name] = 50
	GameState.meta["Funds"] = 0
	GameState.xp = 0
	GameState.last_xp_gained = 0
	var before_standing := {}
	for org: Dictionary in bonus["orgs"]:
		GameState.booster_standing[str(org["id"])] = 50
		before_standing[str(org["id"])] = 50

	GameState._apply_level_bonus_win(level)

	var meta: Dictionary = bonus["meta"]
	for name: String in ["Constituency support", "Reputation", "Party support", "Funds"]:
		var got := int(GameState.meta[name]) - (0 if name == "Funds" else 50)
		_expect_inside(got, meta.get(name, {"min": 0, "max": 0}), "%s, %s" % [where, name])
	_expect_inside(GameState.xp, meta.get(BriefingSummary.XP, {"min": 0, "max": 0}), "%s, XP" % where)
	for org: Dictionary in bonus["orgs"]:
		var got := int(GameState.booster_standing[str(org["id"])]) - 50
		_expect_inside(got, org, "%s, %s" % [where, org["id"]])


func _expect_inside(got: int, bounds: Dictionary, what: String) -> void:
	if got < int(bounds["min"]) or got > int(bounds["max"]):
		fail_test("%s paid %d, outside %d to %d" % [what, got, int(bounds["min"]), int(bounds["max"])])
