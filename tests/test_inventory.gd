extends GutTest
## GameState's inventory (design/proposals/inventory.md): buying from the
## Supplies shop, Stack Caps and per-level Purchase Limits, and using an item
## in the Office (queued for the next stage or level) or during a stage.
## Uses the real Shop-tab rows, so a workbook change that breaks a rule shows
## up here too:
##   SH01 Commission Policy Research  Now, pool "BO01|BO02 +1", limit 1/level
##   SH04 Coffee                      Stage, "ENERGY +1"
##   SH20 Extra Draw                  Level, "DRAW +1", cap 2, limit 2/level
##   SH09 Blue Profile                No for both places, no Grants

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
	}
	GameState.inventory = {}
	GameState.shop_bought_this_level = {}
	GameState.pending_stage_bonuses = {}
	GameState.pending_level_bonuses = {}
	GameState.level_bonuses = {}
	GameState.xp = 10000
	GameState.meta["Funds"] = 900000


func after_each() -> void:
	GameState.inventory = _saved["inventory"]
	GameState.shop_bought_this_level = _saved["bought"]
	GameState.pending_stage_bonuses = _saved["pending_stage"]
	GameState.pending_level_bonuses = _saved["pending_level"]
	GameState.level_bonuses = _saved["level"]
	GameState.xp = _saved["xp"]
	GameState.meta = _saved["meta"]
	GameState.booster_standing = _saved["standing"]


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
