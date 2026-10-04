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
##   SH14 Extra Draw                  Level, "DRAW +1", cap 2, limit 2/level
##   SHTEST_NOUSE (fixture, see before_each())  No for both places, no Grants
##   SH19 Host National Booster Dinner  Now, Player Choice, "TIER:National +2"
##   SHTEST_CARD1/2/3 (fixture, see before_each())  Rhetoric Training (Yen):
##                                    see the card, then learn it — never
##                                    held/Used at all — see card_tier. The
##                                    real Yen-cost rows (once SH27/28/29)
##                                    were removed from the Shop tab
##                                    2026-10-04 (only the XP route below
##                                    survives in real data), so these stand
##                                    in the same way SHTEST_LV1/2 do
##   SH09/10/11 Unlock Random Tier 1/2/3 Card  Rhetoric Training (XP), the
##                                    same card_tier column the fixture rows
##                                    use, XP instead of Yen
##   SH12      Unlock New Staff Recruitment Tier  same shape, see
##                                    unlocks_recruitment_tier
##   SH13      Increase Office Funds Cap  same shape, see funds_cap_increase

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
		"card_draw": GameState.card_draw.duplicate(true),
	}
	GameState.card_draw = {}
	GameState.inventory = {}
	GameState.shop_bought_this_level = {}
	GameState.pending_stage_bonuses = {}
	GameState.pending_level_bonuses = {}
	GameState.level_bonuses = {}
	GameState.xp = 10000
	GameState.meta["Funds"] = 900000
	GameState.staff_hired = {}
	# SH13/14 (Unlock Tier N Level) were removed from the Shop tab 2026-09-30
	# (defunct — nothing to sell). buy_random_level() itself is still real
	# code (kept, same "unused, not removed" precedent as office.new_cards),
	# so these two fixtures stand in for the removed rows to keep testing it.
	DataDB.shop.append({"item_id": "SHTEST_LV1", "name": "Test Unlock Tier 1 Level",
		"cost_xp": 40, "cost_yen": 0, "level_tier": 1})
	DataDB.shop.append({"item_id": "SHTEST_LV2", "name": "Test Unlock Tier 2 Level",
		"cost_xp": 40, "cost_yen": 0, "level_tier": 2})
	# SH09 (Blue Profile Package, the old cosmetic-via-Supplies idea) was
	# removed from the Shop tab once cosmetics got their own tab (Cosmetic
	# Packages, CPxx) — defunct the same way SH13/14 were. This fixture
	# stands in for its shape: Use In Office/Use In Stage both No, no Grants.
	DataDB.shop.append({"item_id": "SHTEST_NOUSE", "name": "Test No-Use Item",
		"cost_xp": 0, "cost_yen": 10000, "use_in_office": "No", "use_in_stage": "No"})
	# SH27/28/29 (Purchase Random Tier 1/2/3 Card, the Yen-cost Rhetoric
	# Training route) were removed from the Shop tab 2026-10-04 — only the
	# XP route (SH09/10/11) survives in real data. Fixtures stand in for the
	# removed rows the same way SHTEST_LV1/LV2 do, so the Yen-specific tests
	# (which check that Funds, not XP, is what moves) still have something
	# real to buy.
	DataDB.shop.append({"item_id": "SHTEST_CARD1", "name": "Test Tier 1 Card (Yen)",
		"cost_xp": 0, "cost_yen": 10000, "card_tier": 1})
	DataDB.shop.append({"item_id": "SHTEST_CARD2", "name": "Test Tier 2 Card (Yen)",
		"cost_xp": 0, "cost_yen": 20000, "card_tier": 2})
	DataDB.shop.append({"item_id": "SHTEST_CARD3", "name": "Test Tier 3 Card (Yen)",
		"cost_xp": 0, "cost_yen": 40000, "card_tier": 3})
	DataDB._shop_by_id = DataDB._index(DataDB.shop, "item_id")


func after_each() -> void:
	DataDB.shop = DataDB.shop.filter(
		func(i: Dictionary) -> bool: return str(i.get("item_id", "")).begins_with("SHTEST_") == false)
	DataDB._shop_by_id = DataDB._index(DataDB.shop, "item_id")
	GameState.card_draw = _saved["card_draw"]
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
	GameState.inventory["SH14"] = 2
	assert_eq(GameState.buy_shop_item("SH14"), Text.say("shop.stack_full"))


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


func test_a_random_grants_outcome_names_which_organisation_it_landed_on() -> void:
	# 2026-09-29, Cameron: a Commission item's random pick has to say which
	# organisation it actually favoured, not just move a number silently.
	GameState.inventory["SH01"] = 1
	var result := GameState.use_item_in_office("SH01")
	var bo01_name := str(DataDB.get_booster("BO01").get("name_en", "BO01"))
	var bo02_name := str(DataDB.get_booster("BO02").get("name_en", "BO02"))
	var message := str(result["message"])
	assert_true(message.contains(bo01_name) or message.contains(bo02_name),
		"the message should name whichever Party organisation was picked")
	assert_true(message.contains("+1"), "the message should carry the delta too")


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
# Player Choice — SH19/20 ("Host a dinner for a player-selected group")
# ---------------------------------------------------------------------------

func test_a_player_choice_item_asks_for_a_choice_before_doing_anything() -> void:
	GameState.inventory["SH19"] = 1
	var result := GameState.use_item_in_office("SH19")
	assert_false(result.get("ok", true))
	assert_true(result.get("needs_choice", false))
	assert_eq(GameState.item_count("SH19"), 1, "nothing taken until a choice is actually made")


func test_a_player_choice_item_moves_exactly_the_chosen_booster() -> void:
	# SH19 is TIER:National — pick one specific National booster and confirm
	# only THAT one moved, never a random other member of the tier.
	GameState.inventory["SH19"] = 1
	GameState.booster_standing["BO05"] = 50
	GameState.booster_standing["BO08"] = 50
	var result := GameState.use_item_in_office("SH19", "BO08")
	assert_true(result.get("ok", false))
	assert_eq(int(GameState.booster_standing["BO08"]), 52, "SH19's own +2")
	assert_eq(int(GameState.booster_standing["BO05"]), 50, "not the chosen one — untouched")
	assert_eq(GameState.item_count("SH19"), 0)


func test_choice_options_lists_every_booster_of_the_items_tier() -> void:
	var item := DataDB.get_shop_item("SH19")
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
	GameState.inventory["SH14"] = 1
	GameState.use_item_in_office("SH14")
	assert_eq(GameState.take_item_bonuses_for_stage(), {}, "nothing until the level begins")

	GameState.begin_level(LevelRunner.new({"stages": [{"seq": 1}]}))
	assert_eq(GameState.take_item_bonuses_for_stage(), {"DRAW": 1})
	assert_eq(GameState.take_item_bonuses_for_stage(), {"DRAW": 1}, "and the stage after")
	GameState._conclude_level_items()
	assert_eq(GameState.take_item_bonuses_for_stage(), {}, "gone when the level concludes")
	GameState.end_level()


func test_an_item_marked_no_for_the_office_is_refused_and_kept() -> void:
	GameState.inventory["SHTEST_NOUSE"] = 1
	var result := GameState.use_item_in_office("SHTEST_NOUSE")
	assert_false(result["ok"])
	assert_eq(GameState.item_count("SHTEST_NOUSE"), 1)


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
	GameState.inventory["SH14"] = 1
	GameState.use_item_in_stage("SH14", engine)
	assert_eq(GameState.take_item_bonuses_for_stage(), {"DRAW": 1})


# ---------------------------------------------------------------------------
# Rhetoric Training (SH09-11 XP, SHTEST_CARD1/2/3 Yen) — see the card, pay
# ---------------------------------------------------------------------------
# Cameron, 2026-09-27: a draw shows one random unowned card of its tier
# FIRST (nothing paid). It can be passed twice (1/3, 2/3); the third must be
# learned. Learning is the only thing that ends a draw.

func _learn(item_id: String) -> Dictionary:
	var offer := GameState.offer_random_card(item_id)
	if not offer["ok"]:
		return offer
	return GameState.learn_offered_card()


func test_seeing_a_card_costs_nothing_and_changes_nothing() -> void:
	GameState.owned_cards = []
	var funds := int(GameState.meta["Funds"])
	var offer := GameState.offer_random_card("SHTEST_CARD2")   # Tier 2, Yen

	assert_true(offer["ok"])
	assert_eq(int(DataDB.get_card(str(offer["card_id"])).get("tier")), 2)
	assert_eq(int(offer["look"]), 1)
	assert_eq(int(offer["looks"]), 3, "rules.json card_training_looks")
	assert_eq(int(GameState.meta["Funds"]), funds, "seeing it has cost nothing")
	assert_eq(GameState.owned_cards.size(), 0, "and it is not yours until you learn it")


func test_learning_the_offered_card_pays_grants_that_card_and_ends_the_draw() -> void:
	GameState.owned_cards = []
	var funds := int(GameState.meta["Funds"])
	var offer := GameState.offer_random_card("SHTEST_CARD2")
	var result := GameState.learn_offered_card()

	assert_true(result["ok"])
	assert_eq(GameState.owned_cards, [str(offer["card_id"])], "the card shown, not another draw")
	assert_eq(int(GameState.meta["Funds"]), funds - int(DataDB.get_shop_item("SHTEST_CARD2")["cost_yen"]))
	assert_string_contains(result["message"], str(DataDB.get_card(str(offer["card_id"])).get("name_en")))
	assert_true(GameState.card_draw.is_empty(), "learning starts a fresh draw next time")


func test_a_draw_can_be_passed_twice_and_the_third_card_must_be_learned() -> void:
	GameState.owned_cards = []
	var first := GameState.offer_random_card("SHTEST_CARD1")
	assert_true(GameState.can_pass_offered_card())
	var second := GameState.pass_offered_card()
	assert_eq(int(second["look"]), 2)
	assert_ne(str(second["card_id"]), str(first["card_id"]), "a pass shows a different card")
	var third := GameState.pass_offered_card()
	assert_eq(int(third["look"]), 3)
	assert_false(GameState.can_pass_offered_card(), "3/3 cannot be passed")
	assert_false(GameState.pass_offered_card()["ok"])
	assert_eq(str(GameState.card_draw["card_id"]), str(third["card_id"]), "and is still on offer")
	assert_eq(GameState.owned_cards.size(), 0, "passing never pays or grants anything")


func test_seeing_a_card_again_mid_draw_returns_the_same_card_not_a_reroll() -> void:
	GameState.owned_cards = []
	GameState.offer_random_card("SHTEST_CARD1")
	var passed := GameState.pass_offered_card()
	var again := GameState.offer_random_card("SHTEST_CARD2")   # even a different session
	assert_eq(str(again["card_id"]), str(passed["card_id"]))
	assert_eq(int(again["look"]), 2)


func test_a_draw_in_progress_survives_a_save_and_load() -> void:
	assert_true(GameState._SAVED_FIELDS.has("card_draw"),
		"so quitting the app with a card on screen does not reroll it")


func test_a_training_session_never_offers_an_owned_card() -> void:
	GameState.owned_cards = []
	var tier_1_ids: Array[String] = []
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == 1:
			tier_1_ids.append(str(card["card_id"]))
	# Own every Tier 1 card but one, so the offer has exactly one possible
	# outcome and repeating an owned card would be immediately visible.
	for card_id: String in tier_1_ids.slice(1):
		GameState.owned_cards.append(card_id)

	var offer := GameState.offer_random_card("SHTEST_CARD1")   # Tier 1
	assert_true(offer["ok"])
	assert_eq(str(offer["card_id"]), tier_1_ids[0])
	assert_false(GameState.can_pass_offered_card(), "nothing else of that tier to swap it for")


func test_owning_every_card_of_a_tier_refuses_the_session() -> void:
	for card: Dictionary in DataDB.cards:
		if int(card.get("tier", -1)) == 3 and not GameState.owned_cards.has(card["card_id"]):
			GameState.owned_cards.append(str(card["card_id"]))
	var funds := int(GameState.meta["Funds"])

	assert_false(GameState.offer_random_card("SHTEST_CARD3")["ok"])   # Tier 3
	assert_false(GameState.card_training_refusal("SHTEST_CARD3").is_empty(), "the Office greys the button")
	assert_eq(int(GameState.meta["Funds"]), funds, "a refusal never spends anything")
	assert_true(GameState.card_draw.is_empty(), "and no draw was started")


func test_an_xp_session_costs_xp_not_yen() -> void:
	GameState.owned_cards = []
	var xp := GameState.xp
	var funds := int(GameState.meta["Funds"])

	var result := _learn("SH10")   # Tier 2, XP

	assert_true(result["ok"])
	assert_eq(int(DataDB.get_card(GameState.owned_cards[0]).get("tier")), 2)
	assert_lt(GameState.xp, xp, "SH10 costs XP, not Yen")
	assert_eq(int(GameState.meta["Funds"]), funds, "SH10 does not touch Funds")


# ---------------------------------------------------------------------------
# Unlock Tier N Level (buy_random_level()) — same on-purchase shape as
# random cards. No shop.json row calls this any more (SH13/14 removed,
# see before_each's own note), so these use the injected fixtures.
# ---------------------------------------------------------------------------

func test_buying_a_random_level_unlock_opens_one_of_the_right_tier() -> void:
	GameState.levels_unlocked = []
	var xp := GameState.xp

	var result := GameState.buy_random_level("SHTEST_LV2")   # Tier 2

	assert_true(result["ok"])
	assert_eq(GameState.levels_unlocked.size(), 1)
	var level := DataDB.get_level(GameState.levels_unlocked[0])
	assert_eq(int(level.get("tier")), 2)
	assert_lt(GameState.xp, xp, "this fixture costs XP, not Yen")


func test_every_level_of_a_tier_already_open_refuses_the_purchase() -> void:
	for level: Dictionary in DataDB.levels:
		var level_id := str(level.get("level_id", ""))
		if int(level.get("tier", -1)) == 1 and not GameState.levels_unlocked.has(level_id):
			GameState.levels_unlocked.append(level_id)

	var result := GameState.buy_random_level("SHTEST_LV1")   # Tier 1

	assert_false(result["ok"])


# ---------------------------------------------------------------------------
# Unlock New Staff Recruitment Tier (SH12)
# ---------------------------------------------------------------------------

func test_buying_a_recruitment_tier_raises_it_by_one() -> void:
	GameState.staff_recruitment_tier = 0
	var result := GameState.buy_staff_recruitment_tier("SH12")

	assert_true(result["ok"])
	assert_eq(GameState.staff_recruitment_tier, 1)


func test_a_maxed_recruitment_tier_refuses_the_purchase() -> void:
	var highest := 0
	for candidate: Dictionary in DataDB.staff:
		highest = maxi(highest, int(candidate.get("highest_tier", 0)))
	GameState.staff_recruitment_tier = highest

	var result := GameState.buy_staff_recruitment_tier("SH12")
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
# Increase Office Funds Cap (SH13)
# ---------------------------------------------------------------------------

func _funds_row() -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == "Funds":
			return row
	return {}


## Redesigned 2026-10-04 (Cameron, from a playtest report: "the income...
## caps are not applied by default"). Before this, the EFFECTIVE cap with
## nothing purchased was already sanban.json's own flat max (1,000,000) —
## a fresh run sat at the full hard ceiling from the start, and every SH13
## purchase after that pushed the ceiling PAST 1,000,000 with nothing to
## stop it. Now rules.json's funds_starting_cap (100,000) is where a run
## actually starts, each SH13 purchase ratchets it up by its own
## funds_cap_increase, and the real sanban max is the one number no amount
## of purchases can ever cross — see GameState._sanban_row().
func test_buying_a_funds_cap_increase_raises_the_effective_cap() -> void:
	GameState.funds_cap_bonus = 0
	var starting_cap := int(DataDB.rules.get("funds_starting_cap", 100000))
	var hard_max := int(_funds_row().get("max", 0))

	# Nothing purchased yet: the effective cap is the starting cap, not the
	# hard ceiling — the bug itself.
	GameState.meta["Funds"] = 0
	GameState._move_meta("Funds", starting_cap + 2000000)
	assert_eq(int(GameState.meta["Funds"]), starting_cap,
		"with nothing purchased, Funds stops at the starting cap")

	var result := GameState.buy_funds_cap("SH13")
	assert_true(result["ok"])
	assert_eq(GameState.funds_cap_bonus, 100000)

	# The raised cap is real: Funds can now go further, but still well
	# under the hard ceiling.
	GameState.meta["Funds"] = 0
	GameState._move_meta("Funds", starting_cap + 2000000)
	assert_eq(int(GameState.meta["Funds"]), starting_cap + 100000,
		"the ceiling itself moved by the purchased amount")
	assert_lt(int(GameState.meta["Funds"]), hard_max,
		"sanity: nowhere near the hard ceiling yet")


func test_the_effective_cap_never_exceeds_the_hard_ceiling() -> void:
	var hard_max := int(_funds_row().get("max", 0))
	GameState.funds_cap_bonus = hard_max * 10   # absurdly large, on purpose
	assert_eq(int(GameState._sanban_row("Funds").get("max", 0)), hard_max,
		"no amount of purchased bonus pushes the effective cap past the real ceiling")


func test_buying_a_funds_cap_increase_is_refused_once_the_ceiling_is_reached() -> void:
	var starting_cap := int(DataDB.rules.get("funds_starting_cap", 100000))
	var hard_max := int(_funds_row().get("max", 0))
	GameState.funds_cap_bonus = hard_max - starting_cap   # already at the ceiling
	GameState.xp = 10000

	var result := GameState.buy_funds_cap("SH13")
	assert_false(result["ok"])
	assert_eq(result["message"], Text.say("shop.funds_cap_maxed"))
	assert_eq(GameState.funds_cap_bonus, hard_max - starting_cap, "refused — nothing changed")


# ---------------------------------------------------------------------------
# Default cap on consumables (Cameron, 2026-09-27)
# ---------------------------------------------------------------------------

func test_a_consumable_with_no_cap_of_its_own_stops_at_the_default() -> void:
	var coffee := DataDB.get_shop_item("SH04")
	assert_eq(Items.stack_cap(coffee), int(DataDB.get_rule("default_consumable_stack_cap")),
		"Coffee's own Stack Cap cell is blank")
	assert_eq(Items.buy_refusal(coffee, 5, 0, 0, 999999, Text.phrase()), Text.say("shop.stack_full"),
		"holding five, a sixth is refused")


func test_an_item_with_its_own_cap_keeps_it() -> void:
	assert_eq(Items.stack_cap(DataDB.get_shop_item("SH14")), 2, "Extra Draw's own cap, not the default")


func test_items_that_are_not_consumables_are_not_capped() -> void:
	for item_id: String in ["SHTEST_NOUSE", "SHTEST_CARD1", "SHTEST_LV1"]:
		assert_eq(Items.stack_cap(DataDB.get_shop_item(item_id)), 0,
			"%s is never held in the inventory, so it has no stack to cap" % item_id)
