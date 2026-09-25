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
##   SH27/28/29 Purchase Random Tier 1/2/3 Card  effect on purchase, not
##                                    held/Used at all — see card_tier
##   SH13/14   Unlock Tier 1/2 Level  same shape, see level_tier
##   SH15/16/17 Unlock Random Tier 1/2/3 Card  reuses buy_random_card(), the
##                                    same card_tier column SH27-29 use, XP
##                                    instead of Yen
##   SH18      Unlock New Staff Recruitment Tier  same shape, see
##                                    unlocks_recruitment_tier
##   SH19      Increase Office Funds Cap  same shape, see funds_cap_increase

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
		"owned_cards": GameState.owned_cards.duplicate(),
		"levels_unlocked": GameState.levels_unlocked.duplicate(),
		"staff_recruitment_tier": GameState.staff_recruitment_tier,
		"funds_cap_bonus": GameState.funds_cap_bonus,
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
	GameState.owned_cards = _saved["owned_cards"]
	GameState.levels_unlocked = _saved["levels_unlocked"]
	GameState.staff_recruitment_tier = _saved["staff_recruitment_tier"]
	GameState.funds_cap_bonus = _saved["funds_cap_bonus"]


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


# ---------------------------------------------------------------------------
# Purchase Random Tier N Card (SH27/28/29) — effect on purchase, no inventory
# ---------------------------------------------------------------------------
# The real bug this guards: these three had Use In Office/Stage both blank
# ("No") and no Grants, so a bought one only ever sat in the inventory
# refusing "This can't be used here." Their own Description already said
# "takes effect immediately" — buy_random_card() is that effect, standing
# apart from every other Supplies item, which is bought first and Used later.

func test_buying_a_random_card_grants_one_of_the_right_tier_immediately() -> void:
	GameState.owned_cards = []
	var funds := int(GameState.meta["Funds"])
	var result := GameState.buy_random_card("SH28")   # Tier 2

	assert_true(result["ok"])
	assert_eq(GameState.owned_cards.size(), 1)
	var card := DataDB.get_card(GameState.owned_cards[0])
	assert_eq(int(card.get("tier")), 2)
	assert_eq(int(GameState.meta["Funds"]), funds - int(DataDB.get_shop_item("SH28")["cost_yen"]))
	assert_string_contains(result["message"], str(card.get("name_en")))


func test_a_random_card_purchase_never_repeats_an_owned_card() -> void:
	GameState.owned_cards = []
	var tier_1_ids: Array[String] = []
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == 1:
			tier_1_ids.append(str(card["card_id"]))
	# Own every Tier 1 card but one, so the purchase has exactly one
	# possible outcome and repeating it would be immediately visible.
	for card_id: String in tier_1_ids.slice(1):
		GameState.owned_cards.append(card_id)

	var result := GameState.buy_random_card("SH27")   # Tier 1

	assert_true(result["ok"])
	assert_true(GameState.owned_cards.has(tier_1_ids[0]),
		"the one card left unowned is the only one this purchase could grant")
	assert_eq(GameState.owned_cards.size(), tier_1_ids.size())


func test_owning_every_card_of_a_tier_refuses_the_purchase() -> void:
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == 3 and not GameState.owned_cards.has(card["card_id"]):
			GameState.owned_cards.append(str(card["card_id"]))
	var funds := int(GameState.meta["Funds"])

	var result := GameState.buy_random_card("SH29")   # Tier 3

	assert_false(result["ok"])
	assert_eq(int(GameState.meta["Funds"]), funds, "a refusal never spends anything")


# ---------------------------------------------------------------------------
# Unlock Tier N Level (SH13/14) — same on-purchase shape as random cards
# ---------------------------------------------------------------------------

func test_buying_a_random_level_unlock_opens_one_of_the_right_tier() -> void:
	GameState.levels_unlocked = []
	var xp := GameState.xp

	var result := GameState.buy_random_level("SH14")   # Tier 2

	assert_true(result["ok"])
	assert_eq(GameState.levels_unlocked.size(), 1)
	var level := DataDB.get_level(GameState.levels_unlocked[0])
	assert_eq(int(level.get("tier")), 2)
	assert_lt(GameState.xp, xp, "SH14 costs XP, not Yen")


func test_every_level_of_a_tier_already_open_refuses_the_purchase() -> void:
	for level: Dictionary in DataDB.levels:
		var level_id := str(level.get("level_id", ""))
		if int(level.get("tier", -1)) == 1 and not GameState.levels_unlocked.has(level_id):
			GameState.levels_unlocked.append(level_id)

	var result := GameState.buy_random_level("SH13")   # Tier 1

	assert_false(result["ok"])


# ---------------------------------------------------------------------------
# Unlock Random Tier N Card (SH15/16/17) — same buy_random_card() effect as
# SH27/28/29, just XP-costed instead of Yen. No new code: their own Card
# Tier column is all that was missing.
# ---------------------------------------------------------------------------

func test_buying_a_random_card_unlock_costs_xp_not_yen() -> void:
	GameState.owned_cards = []
	var xp := GameState.xp
	var funds := int(GameState.meta["Funds"])

	var result := GameState.buy_random_card("SH16")   # Tier 2

	assert_true(result["ok"])
	assert_eq(GameState.owned_cards.size(), 1)
	var card := DataDB.get_card(GameState.owned_cards[0])
	assert_eq(int(card.get("tier")), 2)
	assert_lt(GameState.xp, xp, "SH16 costs XP, not Yen")
	assert_eq(int(GameState.meta["Funds"]), funds, "SH16 does not touch Funds")


# ---------------------------------------------------------------------------
# Unlock New Staff Recruitment Tier (SH18)
# ---------------------------------------------------------------------------

func test_buying_a_recruitment_tier_raises_it_by_one() -> void:
	GameState.staff_recruitment_tier = 0
	var result := GameState.buy_staff_recruitment_tier("SH18")

	assert_true(result["ok"])
	assert_eq(GameState.staff_recruitment_tier, 1)


func test_a_maxed_recruitment_tier_refuses_the_purchase() -> void:
	var highest := 0
	for candidate: Dictionary in DataDB.staff:
		highest = maxi(highest, int(candidate.get("highest_tier", 0)))
	GameState.staff_recruitment_tier = highest

	var result := GameState.buy_staff_recruitment_tier("SH18")
	assert_false(result["ok"])


func test_a_candidate_above_the_unlocked_tier_cannot_be_hired() -> void:
	GameState.staff_recruitment_tier = 0
	var tier_2_candidate: Dictionary = {}
	for candidate: Dictionary in DataDB.staff:
		if int(candidate.get("highest_tier", 0)) == 2:
			tier_2_candidate = candidate
			break
	assert_false(tier_2_candidate.is_empty(), "the fixture needs a real Tier 2 candidate")
	assert_ne(GameState.hire_staff(str(tier_2_candidate["staff_id"])), "")


# ---------------------------------------------------------------------------
# Increase Office Funds Cap (SH19)
# ---------------------------------------------------------------------------

func _funds_row() -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == "Funds":
			return row
	return {}


func test_buying_a_funds_cap_increase_raises_the_effective_cap() -> void:
	GameState.funds_cap_bonus = 0
	var base_max := int(_funds_row().get("max", 0))
	var result := GameState.buy_funds_cap("SH19")

	assert_true(result["ok"])
	assert_eq(GameState.funds_cap_bonus, 100000)

	# The raised cap is real, not just the counter: Funds can now go past
	# the base sanban.json max.
	GameState.meta["Funds"] = 0
	GameState._move_meta("Funds", base_max + 2000000)
	assert_eq(int(GameState.meta["Funds"]), base_max + 100000,
		"the ceiling itself moved by the purchased amount")
