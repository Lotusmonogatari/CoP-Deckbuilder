class_name MarketModel
extends RefCounted
## What the Marketplace's buy list shows (P13, 2026-11-20), as plain data: one dictionary for each item on offer under a
## tab, with its name and price, what it does and, when it cannot be bought, the rules' own reason. It applies the same
## filter and asks the same questions the old Supplies rows asked (Items, GameState), and says nothing they did not;
## MarketView only draws it.
##
## `helpers` carries "price_text", a Callable taking an item and returning its price as the Office writes it.


## The items on offer under `tab` (Items.PERSONAL or Items.OFFICE_INVENTORY), in the Shop tab's order.
static func items(tab: String, helpers: Dictionary) -> Array:
	var out: Array = []
	for item: Dictionary in DataDB.shop:
		# Card sessions live in Rhetoric Training, not here; an item marked "In Marketplace: No" (the Training Session
		# Coupon) is only ever given.
		if item.get("card_tier") == null and str(item.get("in_marketplace", "")).strip_edges().to_lower() != "no" \
				and GameState.item_offered(item) \
				and Items.inventory_tab(item) == tab \
				and not (Items.is_yes(item.get("unlocks_recruitment_tier")) and GameState.staff_recruitment_maxed()) \
				and not (item.get("deck_size_increase") != null and GameState.deck_expansion_maxed()) \
				and not (item.get("funds_cap_increase") != null and GameState.funds_cap_maxed()) \
				and not (GameState.is_staff_slot_item(item) and GameState.staff_slots_maxed()):
			out.append(row(item, helpers))
	return out


## One item: its id, name, title line, description, price, refusal and whether it is sold out for this level.
static func row(item: Dictionary, helpers: Dictionary) -> Dictionary:
	var item_id := str(item.get("item_id", ""))
	var price_text: String = (helpers["price_text"] as Callable).call(item)
	var title := Text.say("shop.item_title", {"name": item.get("name", item_id), "price": price_text})
	# An item a promise owes says so (2026-10-31).
	if GameState.item_is_promised(item_id):
		title = Text.say("shop.promised", {"title": title})
	var bought := int(GameState.shop_bought_this_level.get(item_id, 0))
	var refusal := Items.buy_refusal(item, GameState.item_count(item_id), bought,
		GameState.xp, int(GameState.meta.get("Funds", 0)), Text.phrase(), GameState.funds_limit(), GameState.funds_cap_item_name())
	if refusal.is_empty() and GameState.is_staff_slot_item(item):
		refusal = GameState.staff_slot_refusal(item)
	return {"item_id": item_id, "name": str(item.get("name", item_id)), "price": price_text, "title": title,
		"description": str(item.get("description", "")), "refusal": refusal,
		"out_of_stock": Items.is_out_of_stock(item, bought), "icon": InventoryPanel.icon_name(item)}


## The two chips on the top bar: Funds against the limit, and XP.
static func chips() -> Array[String]:
	return [Text.say("shop.funds_limit", {"yen_funds": int(GameState.meta.get("Funds", 0)), "yen_limit": GameState.funds_limit()}),
		Text.say("office.xp", {"count": GameState.xp})]
