extends GutTest
## Group 1 of P14 (2026-11-20): the Office's pop-ups are one card with a kind tag. Each shows the same words as before, a
## Decision! card (a calendar event) is never priced or bought, an arranged event's step count comes from its options, and
## the pop-ups that must be answered still cannot be dismissed.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func _tag(panel: Overlay) -> String:
	var label := panel.find_child("TagText", true, false) as Label
	return "" if label == null else label.text


func _event_with(trigger: String) -> String:
	for event: Dictionary in DataDB.events:
		if str(event.get("trigger", "")) == trigger and not EventEngine.choices_for(DataDB.event_choices, str(event.get("event_id", ""))).is_empty():
			return str(event.get("event_id", ""))
	return ""


func test_an_arranged_events_step_count_is_read_from_its_options() -> void:
	var options := [{"hosted_id": "H", "step": 1}, {"hosted_id": "H", "step": 2}, {"hosted_id": "H", "step": 3},
		{"hosted_id": "G", "step": 1}]
	assert_eq(HostedEvent.step_count(options, "H"), 3)
	assert_eq(HostedEvent.step_count(options, "G"), 1)
	assert_eq(HostedEvent.step_count(options, "none"), 0)
	assert_eq(HostedEvent.step_count(DataDB.event_options, str(DataDB.hosted_events[0].get("hosted_id", ""))) > 0, true)


func test_a_decision_card_has_the_decision_tag_and_nothing_to_buy() -> void:
	var id := _event_with("Dated")
	if id.is_empty():
		pending("the data has no Dated event with choices")
		return
	for style: String in STYLES:
		UiStyle.trying = style
		var office := _office()
		await get_tree().process_frame
		office._present_event(id, false)
		var panel := office.get_node("EventPanel") as Overlay
		assert_true(panel.visible and panel.has_card(), style + ": the event is a pop-up card")
		assert_eq(_tag(panel), Text.say("popup.tag_decision"), style + ": DECISION! tag")
		for node: Node in panel.find_children("*", "", true, false):
			var lower := str(node.name).to_lower()
			assert_false(lower.contains("buy") or lower.contains("price"), "%s: %s is not a purchase" % [style, node.name])
		for button: Node in panel.find_children("EventChoice_*", "Button", true, false):
			assert_false((button as Button).text.contains("円") and (button as Button).text.contains("Buy"), "no buy button")
		office.queue_free()
		await get_tree().process_frame


func test_every_other_event_is_something_comes_up() -> void:
	var id := _event_with("Random")
	if id.is_empty():
		pending("the data has no Random event with choices")
		return
	var office := _office()
	await get_tree().process_frame
	office._present_event(id, true)
	assert_eq(_tag(office.get_node("EventPanel") as Overlay), Text.say("popup.tag_scenario"))


func test_an_event_card_cannot_be_dismissed_and_its_choices_keep_their_names() -> void:
	var id := _event_with("Dated")
	if id.is_empty():
		pending("the data has no Dated event with choices")
		return
	var office := _office()
	await get_tree().process_frame
	office._present_event(id, false)
	var panel := office.get_node("EventPanel") as Overlay
	for choice: Dictionary in EventEngine.choices_for(DataDB.event_choices, id):
		assert_not_null(panel.find_child("EventChoice_" + str(choice.get("choice", "")), true, false), "a button for each choice")
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	panel._input(event)
	assert_true(panel.visible, "a pop-up that must be answered stays")


func test_the_meta_line_names_the_day_office_and_hours() -> void:
	var id := _event_with("Dated")
	if id.is_empty():
		pending("the data has no Dated event")
		return
	var event := GameState.get_event(id)
	assert_eq(EventsModel.pop_meta(event).count("·"), 2, "day · office · hours")


func test_promises_week_over_and_broken_each_carry_their_kind_tag() -> void:
	var office := _office()
	await get_tree().process_frame
	GameState.promises = [{"id": "P1", "who": "Visitor A", "what": "", "due": GameState.time_units + 5}]
	office._show_promises()
	assert_eq(_tag(office.get_node("PromisesPanel") as Overlay), Text.say("popup.tag_promises"))
	GameState.promises_broken_unseen = [{"id": "P2", "who": "Visitor A"}]
	office._show_broken_promises_if_any()
	assert_eq(_tag(office.get_node("PromisesPanel") as Overlay), Text.say("popup.tag_broken"))
