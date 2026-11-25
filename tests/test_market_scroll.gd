extends GutTest
## The Marketplace keeps the player's place after a purchase (a tester's idea, 2026-11-24: "when purchasing an item don't spring back to the
## top of the page"): drawn again on the same tab it is scrolled where it was; a new tab starts at the top.


func _scroll_of(office: Node) -> ScrollContainer:
	return (office.get_node("InventoryPanel") as Overlay).find_child("FrameScroll", true, false) as ScrollContainer


func test_a_redraw_after_a_purchase_keeps_the_scroll_and_a_new_tab_starts_at_the_top() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 90000
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	office._show_marketplace()
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := _scroll_of(office)
	var room := int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page)
	assert_gt(room, 300, "the list is long enough to scroll")
	scroll.scroll_vertical = 300
	office._after_spending("", office._show_marketplace)   # what a purchase does: redraw the screen
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_scroll_of(office).scroll_vertical, 300, "still where the player was")
	office._on_market_tab(Items.OFFICE_INVENTORY)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_scroll_of(office).scroll_vertical, 0, "a new tab starts at the top")
