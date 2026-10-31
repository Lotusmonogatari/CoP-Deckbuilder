extends GutTest
## The Training Session Coupon (SH21, 2026-10-15): using it in the Office
## starts a free Rhetoric Training draw at its Free Card Tier; learning costs
## nothing and the coupon is spent when the draw starts.

func before_each() -> void:
	GameState.start_new_run("PC01")


func test_the_coupon_is_a_real_shop_item_with_a_tier() -> void:
	var item := DataDB.get_shop_item("SH21")
	assert_false(item.is_empty())
	assert_not_null(item.get("free_card_tier"))


func test_using_it_starts_a_free_draw_and_learning_costs_nothing() -> void:
	var tier := int(DataDB.get_shop_item("SH21")["free_card_tier"])
	if GameState._unowned_cards_at_tier(tier).is_empty():
		pending("no unowned card at the coupon's tier")
		return
	GameState.inventory = {}
	GameState.add_item("SH21")
	var xp_before := GameState.xp
	var funds_before := int(GameState.meta["Funds"])
	var result := GameState.use_item_in_office("SH21")
	assert_true(result["ok"])
	assert_true(result["opens_draw"])
	assert_eq(GameState.item_count("SH21"), 0)
	var card_id := str(GameState.card_draw["card_id"])
	var learned := GameState.learn_offered_card()
	assert_true(learned["ok"])
	assert_true(GameState.owned_cards.has(card_id))
	assert_eq(GameState.xp, xp_before)
	assert_eq(int(GameState.meta["Funds"]), funds_before)
	assert_true(GameState.card_draw.is_empty())


func test_it_is_refused_and_kept_when_no_card_is_left_at_its_tier() -> void:
	var tier := int(DataDB.get_shop_item("SH21")["free_card_tier"])
	for id in GameState._unowned_cards_at_tier(tier):
		GameState.owned_cards.append(id)
	GameState.inventory = {}
	GameState.add_item("SH21")
	var result := GameState.use_item_in_office("SH21")
	assert_false(result["ok"])
	assert_eq(GameState.item_count("SH21"), 1)


func test_a_new_run_starts_with_the_protagonist_s_starting_items() -> void:
	# The Player tab's Starting Items (2026-10-30) alone: the old Balance
	# lever is no longer read (Cameron, 2026-10-31).
	var want: Dictionary = (DataDB.player.get("starting_items", {}) as Dictionary).duplicate()
	want["SH21"] = int(want.get("SH21", 0))
	GameState.start_new_run(str(DataDB.player.get("player_id")))
	assert_gt(int(want["SH21"]), 0, "every protagonist starts with a coupon")
	for item_id: String in want:
		assert_eq(GameState.item_count(item_id), int(want[item_id]), item_id)


func test_every_protagonist_lists_starting_items_the_shop_has() -> void:
	for protagonist: Dictionary in DataDB.protagonists:
		var items: Variant = protagonist.get("starting_items")
		assert_true(items is Dictionary and (items as Dictionary).has("SH21"),
			"%s starts with a coupon" % protagonist.get("player_id"))
		for item_id: String in (items as Dictionary):
			assert_false(DataDB.get_shop_item(item_id).is_empty(), item_id)


func test_the_coupon_is_not_sold_in_the_marketplace() -> void:
	assert_eq(str(DataDB.get_shop_item("SH21").get("in_marketplace")), "No")
