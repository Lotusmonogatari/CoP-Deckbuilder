extends GutTest
## Lead organizations of an event (2026-11-21, Cameron): at most two, named in the event's own text; a passive effect never makes a
## lead. The column is read by EventLeads, the exporter checks it, and the event card shows each lead with its icon.


func test_at_most_two_leads_with_no_repeats_or_blanks() -> void:
	assert_eq(EventLeads.of({"lead_organizations": ["BO01", "BO02", "BO03"]}), ["BO01", "BO02"] as Array[String], "the third is dropped")
	assert_eq(EventLeads.of({"lead_organizations": ["BO01", "BO01", " ", "BO02"]}), ["BO01", "BO02"] as Array[String])
	assert_eq(EventLeads.of({"lead_organizations": null}), [] as Array[String], "a blank cell gives none")
	assert_eq(EventLeads.of({}), [] as Array[String])


func test_a_name_counts_only_when_the_events_own_text_has_it() -> void:
	var event := {"title": "A Bank Asks", "flavor": "The Financial Industry Association wants a roundtable."}
	assert_true(EventLeads.names_in_text(event, "financial industry association"), "case does not matter")
	assert_false(EventLeads.names_in_text(event, "Taxpayers' Alliance"))
	assert_false(EventLeads.names_in_text(event, ""))


func test_every_lead_in_the_data_exists_and_is_named_in_its_events_text() -> void:
	var known := {}
	for booster: Dictionary in DataDB.boosters:
		known[str(booster.get("booster_id", ""))] = str(booster.get("name_en", ""))
	var with_leads := 0
	for event: Dictionary in DataDB.events:
		var raw: Variant = event.get("lead_organizations")
		var count := (raw as Array).size() if raw is Array else 0
		assert_lte(count, EventLeads.MAX, str(event.get("event_id", "")) + ": at most two leads")
		for id: String in EventLeads.of(event):
			assert_true(known.has(id), "%s: %s is an organization" % [event.get("event_id", ""), id])
			assert_true(EventLeads.names_in_text(event, str(known.get(id, ""))), "%s: %s is named in its own text" % [event.get("event_id", ""), id])
			with_leads += 1
	assert_gt(with_leads, 0, "some events have leads")


func test_the_event_card_shows_each_lead_with_its_icon() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	await get_tree().process_frame
	office._present_event("EV02", false)
	var panel := office.get_node("EventPanel") as Overlay
	assert_not_null(panel.find_child("EventLead_BO19", true, false), "the Buddhist Temples Association leads EV02")
	office._present_event("EV03", false)
	assert_eq(panel.find_children("EventLead_*", "", true, false).size(), 0, "an event with no lead shows none")
