extends GutTest
## Sponsored and custom bills are carried at the Capitol only (2026-11-21, Cameron). The office comes from the bill-level
## templates' Location; the levels list hides the section and the Draft a Bill button elsewhere and says why; the rules refuse
## a sponsored bill or a draft started from the other office.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""
	GameState.meta["Funds"] = 1000000
	GameState.xp = 100000
	GameState.calendar = {"week": 3, "phase": "work", "hours": 0}


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_the_bills_belong_to_the_capitol_by_the_templates() -> void:
	assert_eq(PatronLevel.office(), Offices.CAPITOL)


func test_a_drafted_bill_is_refused_at_the_district_with_the_reason_and_allowed_at_the_capitol() -> void:
	GameState.office_location = Offices.DISTRICT
	var refusal := GameState.draft_refusal([])
	assert_eq(refusal, Text.say("travel.refuse_elsewhere_capitol"), "at the District it says to go to the Capitol")
	GameState.office_location = Offices.CAPITOL
	assert_ne(GameState.draft_refusal([]), Text.say("travel.refuse_elsewhere_capitol"), "at the Capitol that is not the reason")


func test_a_sponsored_bill_cannot_be_started_from_the_district() -> void:
	GameState.office_location = Offices.DISTRICT
	var id := str(DataDB.patron_bills[0].get("patron_bill_id", ""))
	assert_false(GameState.start_patron_level(id), "refused")
	assert_eq(GameState.last_level_start_refusal, Text.say("travel.refuse_elsewhere_capitol"))
	assert_false(GameState.is_in_level(), "no level began")
	assert_eq(str((GameState.patron_requests.get(id, {}) as Dictionary).get("status", "")), "", "the request is untouched")


func test_the_levels_list_shows_bills_at_the_capitol_and_a_note_at_the_district() -> void:
	var office := _office()
	await get_tree().process_frame
	GameState.office_location = Offices.CAPITOL
	office._show_levels()
	var panel := office.get_node("LevelsPanel") as Overlay
	assert_not_null(panel.find_child("DraftBillButton", true, false), "the Draft a Bill button at the Capitol")
	assert_null(panel.find_child("BillsElsewhere", true, false), "no note there")
	GameState.office_location = Offices.DISTRICT
	office._show_levels()
	assert_null(panel.find_child("DraftBillButton", true, false), "no Draft a Bill button in the District")
	assert_not_null(panel.find_child("BillsElsewhere", true, false), "a note says where bills are carried")
	assert_eq(panel.find_children("Request_*", "", true, false).size(), 0, "no sponsored bills in the District")
