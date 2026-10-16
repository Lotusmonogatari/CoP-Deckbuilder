extends GutTest
## The three snub items (2026-10-16): SH22 Attacking Op-Ed (Office only, -3,
## National organizations only), SH23 Leak a Memo (Office only, 100 XP, -4,
## Constituency organizations only), SH24 Public Rebuke (Office only, -5,
## Party Bodies only, once a level). Uses the real Shop-tab rows.

var _saved_standing: Dictionary
var _saved_inventory: Dictionary
var _saved_xp: int
var _saved_bought: Dictionary


func before_each() -> void:
	_saved_standing = GameState.booster_standing.duplicate(true)
	_saved_inventory = GameState.inventory.duplicate()
	_saved_xp = GameState.xp
	_saved_bought = GameState.shop_bought_this_level.duplicate()
	GameState.inventory = {}
	GameState.shop_bought_this_level = {}
	GameState.xp = 10000
	GameState.meta["Funds"] = 900000


func after_each() -> void:
	GameState.booster_standing = _saved_standing
	GameState.inventory = _saved_inventory
	GameState.xp = _saved_xp
	GameState.shop_bought_this_level = _saved_bought


func _engine() -> BattleEngine:
	var stage := DataDB.get_stage("ST02").duplicate(true)
	stage["opponents"] = [DataDB.get_opponents_for_stage("ST02")[0]]
	var engine := BattleEngine.new()
	engine.setup(BattleSetup.for_playtest_stage(stage))
	return engine


func test_leak_a_memo_costs_100_xp_and_nothing_else() -> void:
	var item := DataDB.get_shop_item("SH23")
	assert_eq(int(item.get("cost_xp")), 100)
	assert_eq(int(item.get("cost_yen", 0)), 0)


func test_leak_a_memo_lowers_exactly_the_chosen_constituency_organization_by_four() -> void:
	var ids := _tier_ids("Constituency")
	GameState.inventory["SH23"] = 1
	GameState.booster_standing[ids[0]] = 50
	GameState.booster_standing[ids[1]] = 50
	assert_true(GameState.use_item_in_office("SH23")["needs_choice"])
	var result := GameState.use_item_in_office("SH23", ids[1])
	assert_true(result["ok"])
	assert_eq(int(GameState.booster_standing[ids[1]]), 46)
	assert_eq(int(GameState.booster_standing[ids[0]]), 50)
	assert_eq(GameState.item_count("SH23"), 0)


func _tier_ids(tier: String) -> Array:
	return DataDB.boosters_for_tier(tier).map(func(b: Dictionary) -> String: return str(b.get("booster_id")))


func test_each_snub_offers_only_its_own_tier() -> void:
	for pair in [["SH22", "National"], ["SH23", "Constituency"], ["SH24", "Party"]]:
		var options := DataDB.choice_options(DataDB.get_shop_item(pair[0]))
		assert_gt(options.size(), 1, pair[0])
		for booster: Dictionary in options:
			assert_eq(str(booster.get("tier")), pair[1], pair[0])


func test_leak_a_memo_is_refused_during_a_stage() -> void:
	GameState.inventory["SH23"] = 1
	var result := GameState.use_item_in_stage("SH23", _engine(), _tier_ids("Constituency")[0])
	assert_false(result["ok"])
	assert_eq(GameState.item_count("SH23"), 1, "kept")


func test_attacking_op_ed_works_in_the_office_and_not_in_a_stage() -> void:
	var target: String = _tier_ids("National")[0]
	GameState.inventory["SH22"] = 2
	GameState.booster_standing[target] = 50
	assert_false(GameState.use_item_in_stage("SH22", _engine(), target)["ok"])
	assert_eq(int(GameState.booster_standing[target]), 50)
	var result := GameState.use_item_in_office("SH22", target)
	assert_true(result["ok"], str(result))
	assert_eq(int(GameState.booster_standing[target]), 47)
	assert_eq(GameState.item_count("SH22"), 1)


func test_a_snub_never_pushes_standing_below_zero() -> void:
	GameState.inventory["SH23"] = 1
	var target: String = _tier_ids("Constituency")[0]
	GameState.booster_standing[target] = 2
	GameState.use_item_in_office("SH23", target)
	assert_eq(int(GameState.booster_standing[target]), 0)


func test_public_rebuke_offers_only_party_bodies_and_takes_five() -> void:
	var options := DataDB.choice_options(DataDB.get_shop_item("SH24"))
	for booster: Dictionary in options:
		assert_eq(str(booster.get("tier")), "Party")
	assert_gt(options.size(), 0)
	GameState.inventory["SH24"] = 1
	GameState.booster_standing["BO01"] = 50
	assert_true(GameState.use_item_in_office("SH24", "BO01")["ok"])
	assert_eq(int(GameState.booster_standing["BO01"]), 45)


func test_public_rebuke_can_be_bought_once_a_level() -> void:
	assert_eq(GameState.buy_shop_item("SH24"), "")
	GameState.inventory = {}
	assert_ne(GameState.buy_shop_item("SH24"), "", "limit 1 per level")
