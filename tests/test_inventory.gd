extends GutTest
## GameState's inventory (design/proposals/inventory.md): buying from the
## Supplies shop, Stack Caps and per-level Purchase Limits, and using an item
## in the Office (queued for the next stage or level) or during a stage.
## Uses the real Shop-tab rows, so a workbook change that breaks a rule shows
## up here too:
##   SH01 Commission Policy Research  Now, "TIER:Party +1", limit 1/level,
##                                    +1 more once Policy Research Assistant
##                                    reaches Tier 2 (Party tier is BO01/BO02)
##   SH04 Coffee                      Stage, "ENERGY +1"
##   SH20 Extra Draw                  Level, "DRAW +1", cap 2, limit 2/level
##   SH09 Blue Profile                No for both places, no Grants
##   SH25 Host National Booster Dinner  Now, Player Choice, "TIER:National +2"

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = {
		"inventory": GameState.inventory.duplicate(),
		"bought": GameState.shop_bought_this_level.duplicate(),
		"pending_stage": GameState.pending_stage_bonuses.duplicate(),
		"pending_level": GameState.pending_level_bonuses.duplicate(),
		"level": GameState.level_bonuses.duplicate(),
		"xp": GameState.xp,
		"meta": GameState.meta.duplicate(true),
		"standing": GameState.booster_standing.duplicate(true),
		"staff_hired": GameState.staff_hired.duplicate(true),
	}
	GameState.inventory = {}
	GameState.shop_bought_this_level = {}
	GameState.pending_stage_bonuses = {}
	GameState.pending_level_bonuses = {}
	GameState.level_bonuses = {}
	GameState.xp = 10000
	GameState.meta["Funds"] = 900000
	GameState.staff_hired = {}


func after_each() -> void:
	GameState.inventory = _saved["inventory"]
	GameState.shop_bought_this_level = _saved["bought"]
	GameState.pending_stage_bonuses = _saved["pending_stage"]
	GameState.pending_level_bonuses = _saved["pending_level"]
	GameState.level_bonuses = _saved["level"]
	GameState.xp = _saved["xp"]
	GameState.meta = _saved["meta"]
	GameState.booster_standing = _saved["standing"]
	GameState.staff_hired = _saved["staff_hired"]


# ---------------------------------------------------------------------------
# Buying
# ---------------------------------------------------------------------------

func test_buying_spends_the_price_and_adds_one() -> void:
	var funds := int(GameState.meta["Funds"])
	assert_eq(GameState.buy_shop_item("SH04"), "")
	assert_eq(GameState.item_count("SH04"), 1)
	assert_eq(int(GameState.meta["Funds"]), funds - 10000, "Coffee costs 10000 Yen")


func test_a_purchase_limit_runs_out_and_resets_when_the_level_concludes() -> void:
	assert_eq(GameState.buy_shop_item("SH01"), "")
	assert_eq(GameState.buy_shop_item("SH01"), Text.say("shop.out_of_stock"))
	GameState._conclude_level_items()   # what finish_stage() does as a level ends, won or lost
	assert_eq(GameState.buy_shop_item("SH01"), "", "a new level, a new stock")


func test_the_stack_cap_stops_a_purchase() -> void:
	GameState.inventory["SH20"] = 2
	assert_eq(GameState.buy_shop_item("SH20"), Text.say("shop.stack_full"))


# ---------------------------------------------------------------------------
# Using in the Office
# ---------------------------------------------------------------------------

func test_a_now_item_used_in_the_office_moves_one_booster_from_its_pool() -> void:
	GameState.inventory["SH01"] = 1
	GameState.booster_standing["BO01"] = 50
	GameState.booster_standing["BO02"] = 50
	assert_true(GameState.use_item_in_office("SH01")["ok"])
	var moved := int(GameState.booster_standing["BO01"]) + int(GameState.booster_standing["BO02"]) - 100
	assert_eq(moved, 1)
	assert_eq(GameState.item_count("SH01"), 0)


func test_a_tier_pool_only_ever_moves_a_booster_of_that_tier() -> void:
	# SH01's Grants is "TIER:Party +1" — Party is BO01/BO02 only; nothing
	# outside that tier should ever move.
	for _i in 20:
		GameState.inventory["SH01"] = 1
		GameState.booster_standing["BO01"] = 50
		GameState.booster_standing["BO02"] = 50
		GameState.booster_standing["BO03"] = 50   # Constituency — not in the pool
		GameState.use_item_in_office("SH01")
		assert_eq(int(GameState.booster_standing["BO03"]), 50)


func test_hiring_the_named_staff_at_tier_2_layers_the_bonus_on_top() -> void:
	# SH01's Bonus 2 Role/Min Tier/Amount: Policy Research Assistant, Tier 2,
	# +1 — added to the base "TIER:Party +1", reaching +2, whichever Party
	# booster the base effect happens to land on.
	GameState.staff_hired["Policy Research Assistant"] = {"staff_id": "SF01", "tier": 2}
	GameState.inventory["SH01"] = 1
	GameState.booster_standing["BO01"] = 50
	GameState.booster_standing["BO02"] = 50
	GameState.use_item_in_office("SH01")
	var moved := int(GameState.booster_standing["BO01"]) + int(GameState.booster_standing["BO02"]) - 100
	assert_eq(moved, 2, "base +1, Tier 2 bonus +1 more")


func test_hiring_the_staff_at_only_tier_1_does_not_reach_the_tier_2_bonus() -> void:
	# Bonus 1 Amount is 0 for SH01 — Tier 1 alone changes nothing.
	GameState.staff_hired["Policy Research Assistant"] = {"staff_id": "SF01", "tier": 1}
	GameState.inventory["SH01"] = 1
	GameState.booster_standing["BO01"] = 50
	GameState.booster_standing["BO02"] = 50
	GameState.use_item_in_office("SH01")
	var moved := int(GameState.booster_standing["BO01"]) + int(GameState.booster_standing["BO02"]) - 100
	assert_eq(moved, 1)


func test_hiring_a_different_role_does_not_trigger_the_bonus() -> void:
	GameState.staff_hired["Media Spokesperson"] = {"staff_id": "SF08", "tier": 2}
	GameState.inventory["SH01"] = 1
	GameState.booster_standing["BO01"] = 50
	GameState.booster_standing["BO02"] = 50
	GameState.use_item_in_office("SH01")
	var moved := int(GameState.booster_standing["BO01"]) + int(GameState.booster_standing["BO02"]) - 100
	assert_eq(moved, 1)


# ---------------------------------------------------------------------------
# Player Choice — SH25/26 ("Host a dinner for a player-selected group")
# ---------------------------------------------------------------------------

func test_a_player_choice_item_asks_for_a_choice_before_doing_anything() -> void:
	GameState.inventory["SH25"] = 1
	var result := GameState.use_item_in_office("SH25")
	assert_false(result.get("ok", true))
	assert_true(result.get("needs_choice", false))
	assert_eq(GameState.item_count("SH25"), 1, "nothing taken until a choice is actually made")


func test_a_player_choice_item_moves_exactly_the_chosen_booster() -> void:
	# SH25 is TIER:National — pick one specific National booster and confirm
	# only THAT one moved, never a random other member of the tier.
	GameState.inventory["SH25"] = 1
	GameState.booster_standing["BO05"] = 50
	GameState.booster_standing["BO08"] = 50
	var result := GameState.use_item_in_office("SH25", "BO08")
	assert_true(result.get("ok", false))
	assert_eq(int(GameState.booster_standing["BO08"]), 52, "SH25's own +2")
	assert_eq(int(GameState.booster_standing["BO05"]), 50, "not the chosen one — untouched")
	assert_eq(GameState.item_count("SH25"), 0)


func test_choice_options_lists_every_booster_of_the_items_tier() -> void:
	var item := DataDB.get_shop_item("SH25")
	var options := DataDB.choice_options(item)
	var ids: Array = []
	for booster: Dictionary in options:
		ids.append(booster.get("booster_id"))
	assert_eq(ids, DataDB.boosters_for_tier("National").map(
		func(b: Dictionary) -> String: return str(b.get("booster_id"))))
	assert_gt(ids.size(), 1, "sanity: National has more than one booster to choose from")


func test_a_stage_item_used_in_the_office_waits_for_the_next_stage_only() -> void:
	GameState.inventory["SH04"] = 1
	GameState.use_item_in_office("SH04")
	assert_eq(GameState.take_item_bonuses_for_stage(), {"ENERGY": 1})
	assert_eq(GameState.take_item_bonuses_for_stage(), {}, "spent by the first stage that asks")


func test_a_level_item_used_in_the_office_lasts_every_stage_of_the_next_level() -> void:
	GameState.inventory["SH20"] = 1
	GameState.use_item_in_office("SH20")
	assert_eq(GameState.take_item_bonuses_for_stage(), {}, "nothing until the level begins")

	GameState.begin_level(LevelRunner.new({"stages": [{"seq": 1}]}))
	assert_eq(GameState.take_item_bonuses_for_stage(), {"DRAW": 1})
	assert_eq(GameState.take_item_bonuses_for_stage(), {"DRAW": 1}, "and the stage after")
	GameState._conclude_level_items()
	assert_eq(GameState.take_item_bonuses_for_stage(), {}, "gone when the level concludes")
	GameState.end_level()


func test_an_item_marked_no_for_the_office_is_refused_and_kept() -> void:
	GameState.inventory["SH09"] = 1
	var result := GameState.use_item_in_office("SH09")
	assert_false(result["ok"])
	assert_eq(GameState.item_count("SH09"), 1)


# ---------------------------------------------------------------------------
# Using during a stage
# ---------------------------------------------------------------------------

func _engine() -> BattleEngine:
	var stage := DataDB.get_stage("ST02").duplicate(true)
	stage["opponents"] = [DataDB.get_opponents_for_stage("ST02")[0]]
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(stage))
	return engine


func test_a_stage_item_used_mid_stage_lands_now_and_is_taken() -> void:
	var engine := _engine()
	GameState.inventory["SH04"] = 2
	var energy := engine.state.energy
	assert_true(GameState.use_item_in_stage("SH04", engine)["ok"])
	assert_eq(engine.state.energy, energy + 1)
	assert_eq(GameState.item_count("SH04"), 1)


func test_a_refused_use_mid_stage_does_not_take_the_item() -> void:
	var engine := _engine()
	GameState.inventory["SH04"] = 2
	GameState.use_item_in_stage("SH04", engine)
	var second := GameState.use_item_in_stage("SH04", engine)
	assert_false(second["ok"], "Uses Per Turn is 1")
	assert_eq(GameState.item_count("SH04"), 1, "the refused one is still held")


func test_a_level_item_used_mid_stage_also_covers_the_rest_of_the_level() -> void:
	var engine := _engine()
	GameState.inventory["SH20"] = 1
	GameState.use_item_in_stage("SH20", engine)
	assert_eq(GameState.take_item_bonuses_for_stage(), {"DRAW": 1})
