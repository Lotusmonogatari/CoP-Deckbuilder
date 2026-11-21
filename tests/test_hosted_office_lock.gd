extends GutTest
## The dinner is locked to the Capitol and the walking tour to the District (2026-11-21, Cameron). The lock is the Hosted Events
## tab's Location; the item that starts the event is refused, with the reason, at the other office, in the rules and on the
## Use button.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 1000000
	GameState.xp = 100000
	GameState.calendar = {"week": 3, "phase": "work", "hours": 0}


func _item_for(hosted_id: String) -> Dictionary:
	return DataDB.get_shop_item(str(GameState.get_hosted_event(hosted_id).get("item_id", "")))


func test_the_data_puts_the_dinner_at_the_capitol_and_the_tour_in_the_district() -> void:
	assert_eq(Offices.normalize(GameState.get_hosted_event("HE02").get("location")), Offices.CAPITOL, "the dinner")
	assert_eq(Offices.normalize(GameState.get_hosted_event("HE01").get("location")), Offices.DISTRICT, "the walking tour")


func test_the_pure_rule_refuses_only_at_the_other_office() -> void:
	var dinner := {"location": "Capitol"}
	assert_eq(Items.office_refusal(dinner, Offices.CAPITOL, "the Capitol"), "", "at home")
	assert_ne(Items.office_refusal(dinner, Offices.DISTRICT, "the Capitol"), "", "away")
	assert_eq(Items.office_refusal({"location": null}, Offices.DISTRICT, "x"), "", "a blank location means anywhere")
	assert_eq(Items.office_refusal({"location": "Either"}, Offices.CAPITOL, "x"), "")
	assert_eq(Items.office_refusal({}, Offices.CAPITOL, "x"), "", "no event, no lock")


func test_the_refusal_names_the_office_it_belongs_to() -> void:
	GameState.office_location = Offices.DISTRICT
	var refusal := GameState.item_office_refusal(_item_for("HE02"))
	assert_true(refusal.contains(TravelText.place_name(Offices.CAPITOL)), "the dinner says it is hosted at the Capitol: " + refusal)
	GameState.office_location = Offices.CAPITOL
	assert_eq(GameState.item_office_refusal(_item_for("HE02")), "", "the dinner is fine at the Capitol")
	assert_ne(GameState.item_office_refusal(_item_for("HE01")), "", "the walking tour is refused at the Capitol")
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.item_office_refusal(_item_for("HE01")), "", "and fine in the District")


func test_using_the_wrong_item_is_refused_in_the_rules_and_keeps_the_item() -> void:
	var tour := _item_for("HE01")
	var id := str(tour.get("item_id", ""))
	GameState.add_item(id, 1)
	GameState.office_location = Offices.CAPITOL
	var held := GameState.item_count(id)
	var result := GameState.use_item_in_office(id, "")
	assert_false(bool(result.get("ok", false)) or bool(result.get("needs_choice", false)), "refused before it asks who to host")
	assert_eq(GameState.item_count(id), held, "the item is kept")
	assert_true(GameState.hosted_session.is_empty(), "no evening began")


func test_the_use_button_is_greyed_with_the_reason_at_the_wrong_office() -> void:
	var tour := _item_for("HE01")
	var id := str(tour.get("item_id", ""))
	GameState.add_item(id, 1)
	GameState.office_location = Offices.CAPITOL
	var panel := InventoryPanel.new()
	add_child_autofree(panel)
	await get_tree().process_frame
	assert_ne(panel._refusal(id, tour), "", "the Use button has a reason")
	GameState.office_location = Offices.DISTRICT
	assert_eq(panel._refusal(id, tour), "", "no reason in the District")
