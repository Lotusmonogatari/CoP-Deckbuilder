extends GutTest
## Office Management on the shared frame (P13, 2026-11-20). Two tabs (Staff, Your deck; Rhetoric Training moved to the Speech Coach venue in P16); the Staff tab
## shows one card for every hired person (so the staff count always equals the cards shown), one dashed row for every open
## place, and the Staff Assignments button fixed under it; the deck and training bodies are the old ones in cards.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 1000000
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""


func _hire_some() -> int:
	# Two places per role, and the recruitment tier that lets a second, higher candidate be hired.
	GameState.staff_slot_buys = 1
	GameState.staff_recruitment_tier = 2
	var hired := 0
	var roles := Ledger.staff_roles(DataDB.staff)
	for i in roles.size():
		var candidates := DataDB.get_staff_by_role(str(roles[i]))
		for j in (2 if i == 0 else 1):
			if j < candidates.size() and GameState.hire_staff(str(candidates[j].get("staff_id", ""))) == "":
				hired += 1
	return hired


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_the_staff_count_equals_the_people_listed() -> void:
	var hired := _hire_some()
	assert_gt(hired, 0, "the fixture hired people")
	var model := StaffRosterModel.build()
	var listed := 0
	for role: Dictionary in model["roles"]:
		listed += (role["people"] as Array).size()
	assert_eq(listed, hired)
	assert_eq(int(model["hired_total"]), listed)
	assert_eq(model["staff_count"], Text.say("office.staff_count_of", {"count": listed, "total": model["roles"].size() * GameState.staff_slots()}))


func test_open_places_are_the_places_not_filled() -> void:
	_hire_some()
	for role: Dictionary in StaffRosterModel.build()["roles"]:
		assert_eq(int(role["open"]), GameState.staff_slots() - (role["people"] as Array).size(), str(role["role"]))


func test_a_person_shows_what_the_old_row_showed_and_a_tag_by_place() -> void:
	_hire_some()
	var first_role: Dictionary = StaffRosterModel.build()["roles"][0]
	var people: Array = first_role["people"]
	assert_eq(people.size(), 2, "two places filled in the first role")
	var staff_id := str(people[0]["staff_id"])
	var candidate := DataDB.get_staff(staff_id)
	var hired := GameState.hired_member(staff_id)
	assert_eq(people[0]["line"], Text.say("office.staff_hired", {"name": candidate.get("name", staff_id), "tier": int(hired.get("tier", 0)),
		"highest": int(candidate.get("highest_tier", 0))}), "name and rank, as the old row wrote them")
	assert_eq(people[0]["summary"], StaffLoyaltyView.summary(staff_id), "Loyalty word and wage")
	assert_eq(people[0]["tag"], Text.say("office.staff_primary_tag"))
	assert_eq(people[1]["tag"], Text.say("office.staff_second_tag"))


func test_every_hired_person_has_a_card_and_every_open_place_a_row_in_every_style() -> void:
	_hire_some()
	for style: String in STYLES:
		UiStyle.trying = style
		var model := StaffRosterModel.build()
		var taps: Array = []
		var cards := StaffRosterView.cards(model, {"profile": func(id: String) -> void: taps.append("p:" + id),
			"hire": func(role: String) -> void: taps.append("h:" + role)})
		var holder := VBoxContainer.new()
		add_child_autofree(holder)
		for card: Control in cards:
			holder.add_child(card)
		var open_total := 0
		for role: Dictionary in model["roles"]:
			open_total += int(role["open"])
		assert_eq(holder.find_children("StaffCard_*", "", true, false).size(), int(model["hired_total"]), style + ": a card for each person")
		assert_eq(holder.find_children("HireSlot_*", "Button", true, false).size(), open_total, style + ": a row for each open place")
		var person: Dictionary = model["roles"][0]["people"][0]
		(holder.find_child(str(person["node"]), true, false) as Button).pressed.emit()
		var role_name := ""
		for role: Dictionary in model["roles"]:
			if int(role["open"]) > 0:
				role_name = str(role["role"])
				break
		assert_ne(role_name, "", "some role has an open place")
		(holder.find_child("HireSlot_%s_0" % role_name.replace(" ", "_"), true, false) as Button).pressed.emit()
		assert_eq(taps, ["p:" + str(person["staff_id"]), "h:" + role_name], style + ": taps reach their handlers")


func test_the_screen_has_two_tabs_a_staff_assignments_button_and_three_chips() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_management()
	var panel := office.get_node("ManagementPanel") as Overlay
	for tab: String in ["staff", "deck"]:
		assert_not_null(panel.find_child("FrameTab_" + tab, true, false), tab + " tab")
	assert_null(panel.find_child("FrameTab_rhetoric", true, false), "Rhetoric Training is no longer a tab (P16: the Speech Coach venue)")
	var footer := panel.find_child("StaffAssignmentsButton", true, false) as Button
	assert_not_null(footer, "Staff Assignments is the fixed button")
	assert_eq(panel.find_child("FrameChips", true, false).get_child_count(), 3, "Funds, XP and the deck count")
	assert_not_null(panel.find_child("StaffSummary", true, false))


func test_the_deck_tab_confirms_only_a_deck_that_can_be_taken_in() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_deck()
	var panel := office.get_node("ManagementPanel") as Overlay
	assert_not_null(panel.find_child("DeckCard", true, false), "the cards you own")
	var refusal: String = office._deck_refusal()
	assert_eq(panel.find_child("DeckConfirmButton", true, false) != null, refusal.is_empty(), "Confirm shows only while the deck is legal")
	if refusal.is_empty():
		(panel.find_child("DeckConfirmButton", true, false) as Button).pressed.emit()
		assert_false(panel.visible, "taking the deck in closes the screen, as it did")


func test_the_speech_coachs_page_has_a_card_for_every_session() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_rhetoric_training()
	var panel := office.get_node("ManagementPanel") as Overlay
	var sessions := 0
	for item: Dictionary in DataDB.shop:
		if item.get("card_tier") != null:
			sessions += 1
			assert_not_null(panel.find_child("Training_" + str(item.get("item_id", "")), true, false))
	assert_gt(sessions, 0)
	assert_eq(panel.find_children("TrainingCard_*", "", true, false).size(), sessions)


func test_each_tab_builds_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var office := _office()
		await get_tree().process_frame
		for tab: String in ["staff", "deck"]:
			office._on_management_tab(tab)
			assert_true((office.get_node("ManagementPanel") as Overlay).visible, "%s: %s opens" % [style, tab])
		office.queue_free()
		await get_tree().process_frame
