extends GutTest
## The Marketplace on the shared frame (P13, 2026-11-20). The buy list is MarketModel's data drawn by MarketView: every
## item the old Supplies rows offered is still offered with the same price, description and reason, one card shape for
## all of them, the reason in red with Buy greyed when it cannot be bought, the three tabs keep their old node names, and a
## "You have" card holds what you carry.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""


func _price(item: Dictionary) -> String:
	return "price of " + str(item.get("item_id", ""))


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_every_item_the_old_rows_offered_is_still_offered_with_the_same_words() -> void:
	for tab: String in [Items.PERSONAL, Items.OFFICE_INVENTORY]:
		var offered := MarketModel.items(tab, {"price_text": _price})
		assert_gt(offered.size(), 0, tab + " has items on offer")
		for row: Dictionary in offered:
			var item := DataDB.get_shop_item(str(row["item_id"]))
			assert_eq(Items.inventory_tab(item), tab, "under its own tab")
			assert_null(item.get("card_tier"), "no card session in the Marketplace")
			assert_eq(row["title"], Text.say("shop.item_title", {"name": item.get("name", row["item_id"]), "price": _price(item)})
				if not GameState.item_is_promised(str(row["item_id"])) else row["title"], "the title line")
			assert_eq(row["description"], str(item.get("description", "")), "what it does, as the Shop tab says")


func test_a_funds_short_item_says_so_and_a_sold_out_one_is_marked() -> void:
	GameState.meta["Funds"] = 0
	GameState.shop_bought_this_level["SH14"] = 2
	var rows := {}
	for row: Dictionary in MarketModel.items(Items.PERSONAL, {"price_text": _price}):
		rows[row["item_id"]] = row
	assert_true(rows.has("SH14"), "the sold-out item is still listed")
	assert_true(bool(rows["SH14"]["out_of_stock"]))
	assert_eq(rows["SH14"]["refusal"], Text.say("shop.out_of_stock"))
	assert_ne(str(rows["SH01"]["refusal"]), "", "no Funds: a reason is given")


func test_an_item_at_the_carrying_limit_says_you_cannot_carry_more() -> void:
	GameState.add_item("SH15", 3)
	var row := MarketModel.row(DataDB.get_shop_item("SH15"), {"price_text": _price})
	assert_eq(row["refusal"], Text.say("shop.stack_full"))


func test_a_card_with_no_reason_has_a_working_buy_and_one_with_a_reason_is_greyed_in_red() -> void:
	var look := OfficeFrameStyles.look()
	var bought: Array[String] = []
	var ok := {"item_id": "SH01", "icon": "SH01", "title": "Thing — 5円", "description": "Does a thing.", "refusal": "", "out_of_stock": false}
	var card := MarketView.item_card(look, ok, func(id: String) -> void: bought.append(id))
	add_child_autofree(card)
	assert_eq(card.name, "Supply_SH01")
	var buy := card.find_child("Buy", true, false) as Button
	assert_false(buy.disabled)
	assert_null(card.find_child("ItemRefusal", true, false), "no reason line when it can be bought")
	buy.pressed.emit()
	assert_eq(bought, ["SH01"] as Array[String])

	var no := ok.duplicate()
	no["refusal"] = "Insufficient Funds"
	var greyed := MarketView.item_card(look, no, func(id: String) -> void: bought.append(id))
	add_child_autofree(greyed)
	var buy2 := greyed.find_child("Buy", true, false) as Button
	assert_true(buy2.disabled, "greyed")
	assert_eq(buy2.text, Text.say("shop.buy"))
	var why := greyed.find_child("ItemRefusal", true, false) as Label
	assert_eq(why.text, "Insufficient Funds")
	assert_eq(why.get_theme_color("font_color"), look["down"], "the reason is in the style's red")
	assert_eq(bought.size(), 1, "a greyed Buy runs nothing")


func test_a_sold_out_card_is_dimmed() -> void:
	var card := MarketView.item_card(OfficeFrameStyles.look(), {"item_id": "SH01", "icon": "SH01", "title": "T", "description": "D",
		"refusal": "Out of Stock", "out_of_stock": true}, Callable())
	autofree(card)
	assert_lt(card.modulate.a, 1.0)


func test_the_screen_keeps_its_three_tabs_under_their_old_names_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var office := _office()
		await get_tree().process_frame
		office._market_tab = Items.PERSONAL
		office._show_marketplace()
		var panel := office.get_node("InventoryPanel") as Overlay
		for node: String in ["PersonalTab", "OfficeTab", "StylesTab"]:
			assert_not_null(panel.find_child(node, true, false), "%s: %s" % [style, node])
		assert_not_null(panel.find_child("MarketHeld", true, false), style + ": the You have card")
		assert_not_null(panel.find_child("Supply_SH01", true, false), style + ": an item card")
		office.queue_free()
		await get_tree().process_frame


func test_the_chips_are_funds_against_the_limit_and_xp() -> void:
	var chips := MarketModel.chips()
	assert_eq(chips[0], Text.say("shop.funds_limit", {"yen_funds": int(GameState.meta.get("Funds", 0)), "yen_limit": GameState.funds_limit()}))
	assert_eq(chips[1], Text.say("office.xp", {"count": GameState.xp}))


func test_the_funds_limit_note_shows_only_at_the_limit() -> void:
	var office := _office()
	await get_tree().process_frame
	GameState.meta["Funds"] = 0
	office._show_marketplace()
	assert_null(office.find_child("MarketLimitNote", true, false), "no note below the limit")
	GameState.meta["Funds"] = GameState.funds_limit()
	office._show_marketplace()
	assert_not_null(office.find_child("MarketLimitNote", true, false), "the note shows at the limit")


func test_the_styles_tab_has_one_card_per_style() -> void:
	var office := _office()
	await get_tree().process_frame
	office._market_tab = "Styles"
	office._show_marketplace()
	var panel := office.get_node("InventoryPanel") as Overlay
	for style: String in UiStyles.ALL:
		assert_not_null(panel.find_child("StyleCard_" + style, true, false), style + " has a card")


func test_tapping_a_tab_changes_what_is_listed() -> void:
	var office := _office()
	await get_tree().process_frame
	office._market_tab = Items.PERSONAL
	office._show_marketplace()
	var panel := office.get_node("InventoryPanel") as Overlay
	(panel.find_child("StylesTab", true, false) as Button).pressed.emit()
	assert_not_null(panel.find_child("StyleCard_woodblock", true, false), "the Styles tab opened")
	(panel.find_child("PersonalTab", true, false) as Button).pressed.emit()
	assert_null(panel.find_child("StyleCard_woodblock", true, false), "and Personal brought the items back")
