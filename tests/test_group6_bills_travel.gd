extends GutTest
## Group 6 of P14b (2026-11-20): the Travel page and its bottom sheet, Draft a Bill, a bill to carry, the law detail, the party
## detail and one tile for each promise.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""
	GameState.meta["Funds"] = 1000000
	GameState.xp = 100000


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_the_travel_page_has_a_button_for_every_way_the_player_can_go() -> void:
	GameState.add_item("SH42", 1)
	var office := _office()
	await get_tree().process_frame
	office._show_travel_page()
	var panel := office.get_node("TravelPagePanel") as Overlay
	assert_true(panel.has_frame(), "the page is on the frame")
	assert_not_null(panel.find_child("TravelHereCard", true, false))
	assert_not_null(panel.find_child("TravelDestinationCard", true, false))
	for mode: String in GameState.travel_modes():
		assert_not_null(panel.find_child("TravelPageMode_" + mode, true, false), "a button for " + mode)


func test_a_mode_opens_the_bottom_sheet_with_the_way_to_the_page() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_travel()
	var sheet := office.get_node("TravelPanel") as Overlay
	assert_true(sheet.visible and sheet.has_card(), "the confirm is a pop-up card")
	assert_not_null(sheet.find_child("AllTripsButton", true, false), "the way to the Travel page")
	(sheet.find_child("AllTripsButton", true, false) as Button).pressed.emit()
	assert_true((office.get_node("TravelPagePanel") as Overlay).visible, "All trips opens the page")


func test_the_law_detail_wears_its_outcome_as_the_tag() -> void:
	var office := _office()
	await get_tree().process_frame
	var law := {"bill_id": str(DataDB.floor_votes.keys()[0]), "passed": true, "yes": 58, "no": 40, "abstain": 3, "player_vote": "Yes",
		"requirement": "Majority", "yes_needed": 51}
	office._show_law(law)
	var panel := office.get_node("LawPanel") as Overlay
	assert_true(panel.has_card())
	assert_eq((panel.find_child("TagText", true, false) as Label).text, Text.say("record.law_marker_passed"))
	law["passed"] = false
	office._show_law(law)
	assert_eq((panel.find_child("TagText", true, false) as Label).text, Text.say("record.law_marker_failed"))


func test_the_party_detail_has_its_band_seats_allies_and_rivals() -> void:
	var office := _office()
	await get_tree().process_frame
	var party: Dictionary = DataDB.parties[2]
	office._show_party_detail(str(party["party_id"]))
	var panel := office.get_node("PartyDetailPanel") as Overlay
	assert_true(panel.has_frame())
	assert_eq((panel.find_child("PartyBand", true, false) as ColorRect).color, PartyDisplay.color_for(party), "the band is the party colour")
	assert_not_null(panel.find_child("PartyAllies", true, false))
	assert_not_null(panel.find_child("PartyRivals", true, false))


func test_draft_a_bill_fixes_its_button_and_lists_each_chosen_part() -> void:
	var office := _office()
	await get_tree().process_frame
	var ids: Array = []
	for component: Dictionary in DataDB.bill_components:
		if ids.size() < 2:
			ids.append(str(component.get("component_id", "")))
	office._draft_ids = ids
	office._open_draft()
	var panel := office.get_node("DraftPanel") as Overlay
	assert_true(panel.has_frame())
	for id: String in ids:
		assert_not_null(panel.find_child("DraftRemove_" + id, true, false), "a remove button for " + id)
	assert_eq(panel.find_child("DraftGoButton", true, false).get_parent().name, "FrameFooter", "Draft is fixed in the foot")


func test_each_promise_has_a_tile() -> void:
	var office := _office()
	await get_tree().process_frame
	GameState.promises = [{"id": "PRA", "who": "Visitor A", "what": "", "due": GameState.time_units + 6},
		{"id": "PRB", "who": "Visitor B", "what": "", "due": GameState.time_units + 40}]
	office._show_promises()
	var panel := office.get_node("PromisesPanel") as Overlay
	for id: String in ["PRA", "PRB"]:
		assert_not_null(panel.find_child("PromiseTile_" + id, true, false), "a tile for " + id)
		assert_not_null(panel.find_child("Keep_" + id, true, false), "its Keep button")
