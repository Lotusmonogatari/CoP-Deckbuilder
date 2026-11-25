extends GutTest
## The office-supply items (Printer, Shredder, Flex-Work, Priority Inbox, Commendation Gift, Lunch Delivery) sit in the Marketplace's Office
## Inventory tab, not the Personal one (Cameron, 2026-11-25).

const OFFICE_ITEMS := ["SH36", "SH37", "SH38", "SH39", "SH40", "SH41"]


func test_the_six_office_items_are_office_inventory_items() -> void:
	for id: String in OFFICE_ITEMS:
		assert_eq(Items.inventory_tab(DataDB.get_shop_item(id)), Items.OFFICE_INVENTORY, id)


func test_the_marketplace_lists_them_under_office_inventory_and_not_under_personal() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	var office_ids: Array = MarketModel.items(Items.OFFICE_INVENTORY, {"price_text": func(_i: Dictionary) -> String: return ""}).map(func(m: Dictionary) -> String: return str(m["item"]["item_id"]) if m.has("item") else str(m.get("item_id", "")))
	var personal_ids: Array = MarketModel.items(Items.PERSONAL, {"price_text": func(_i: Dictionary) -> String: return ""}).map(func(m: Dictionary) -> String: return str(m["item"]["item_id"]) if m.has("item") else str(m.get("item_id", "")))
	for id: String in OFFICE_ITEMS:
		assert_true(office_ids.has(id), "%s is in Office Inventory" % id)
		assert_false(personal_ids.has(id), "%s is not in Personal Inventory" % id)
