extends GutTest
## What is not open while the player is at one office (P14b, 2026-11-21): read from the data's Location tags, so it is true of
## whichever office the player stands in, and nothing is listed for a kind with nothing tagged for the other office.


func test_only_the_kinds_that_belong_to_the_other_office_are_listed() -> void:
	var levels := [{"location": "District"}, {"location": "Either"}]
	var events := [{"location": "Either"}]
	var visitors := [{"location": "Capitol"}]
	assert_eq(ClosedHere.kinds(Offices.CAPITOL, levels, events, visitors), [ClosedHere.LEVELS] as Array[String], "at the Capitol: a District level is closed; nothing else is tagged District")
	assert_eq(ClosedHere.kinds(Offices.DISTRICT, levels, events, visitors), [ClosedHere.VISITORS] as Array[String], "in the District: a Capitol visitor is closed")


func test_a_blank_or_either_location_closes_nothing() -> void:
	assert_eq(ClosedHere.kinds(Offices.CAPITOL, [{"location": null}, {}], [{"location": "Either"}], []), [] as Array[String])


func test_the_real_data_lists_something_at_each_office() -> void:
	DataDB.clear_runtime()
	for office: String in [Offices.CAPITOL, Offices.DISTRICT]:
		var kinds := ClosedHere.kinds(office, DataDB.levels, DataDB.events, DataDB.visitors)
		assert_gt(kinds.size(), 0, office + ": something is closed there")


func test_the_moved_card_names_the_speaker_and_what_is_closed() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.hire_staff(str(DataDB.staff[0].get("staff_id", "")))
	GameState.office_location = Offices.CAPITOL
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	await get_tree().process_frame
	office._show_moved_card(str(DataDB.events[0].get("event_id", "")))
	var panel := office.get_node("MovedPanel") as Overlay
	assert_true(panel.visible and panel.has_card())
	assert_eq((panel.find_child("TagText", true, false) as Label).text, Text.say("popup.tag_moved"))
	assert_not_null(panel.find_child("MovedSpeech", true, false), "the primary staff member speaks")
	assert_not_null(panel.find_child("MovedContinueButton", true, false))
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	panel._input(event)
	assert_true(panel.visible, "it must be answered")
