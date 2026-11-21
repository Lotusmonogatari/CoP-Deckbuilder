extends GutTest
## Group 5 of P14b (2026-11-20): Your Deck, the card offer, the card look and the inventory's item sheet. The deck's suit chips
## add up to the deck being built; the switch lists only the deck or the whole collection; the card pop-ups and the item sheet
## are pop-up cards.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_the_suit_chips_add_up_to_the_deck_being_built() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_deck()
	var panel := office.get_node("ManagementPanel") as Overlay
	var flow := panel.find_child("DeckSuits", true, false)
	assert_not_null(flow, "the suit chips are there")
	var total := 0
	for chip: Node in flow.get_children():
		var words := (chip.find_child("ChipText", true, false) as Label).text
		total += int(words.split(" ")[-1])
	assert_eq(total, office._draft_deck.size(), "the counts add up to the cards chosen")


func test_the_switch_lists_the_deck_or_the_whole_collection() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_deck()
	var panel := office.get_node("ManagementPanel") as Overlay
	assert_eq(panel.find_children("ViewCard_*", "Button", true, false).size(), GameState.owned_cards.size(), "the collection by default")
	office._on_deck_view("deck")
	assert_eq(panel.find_children("ViewCard_*", "Button", true, false).size(), office._draft_deck.size(), "only the deck")
	office._on_deck_view("all")
	assert_eq(panel.find_children("ViewCard_*", "Button", true, false).size(), GameState.owned_cards.size())


func test_the_card_look_is_a_pop_up_card() -> void:
	var office := _office()
	await get_tree().process_frame
	var id := str(GameState.owned_cards[0])
	office._show_card_look(id)
	var panel := office.get_node("CardLookPanel") as Overlay
	assert_true(panel.visible and panel.has_card())
	assert_eq((panel.find_child("CardTitle", true, false) as Label).text.to_lower(), str(DataDB.get_card(id).get("name_en", "")).to_lower())


func test_an_item_opens_as_a_bottom_sheet_with_close() -> void:
	var item := str(DataDB.shop[0].get("item_id", ""))
	GameState.add_item(item, 1)
	var panel := InventoryPanel.new()
	add_child_autofree(panel)
	await get_tree().process_frame
	panel.show_item(item)
	assert_true(panel.has_card(), "the details are a pop-up card")
	assert_not_null(panel.find_child("Back", true, false), "Close is the card's own way out")
