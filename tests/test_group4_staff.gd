extends GutTest
## Group 4 of P14b (2026-11-20): Staff Assignments, the staff profile and Rhetoric Training on the shared frame. Every hired
## person has a card; Confirm is fixed in the frame's foot; the profile is cards with Fire last; a held coaching coupon is
## named on the Rhetoric Training tab.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""
	GameState.meta["Funds"] = 1000000


func after_each() -> void:
	UiStyle.trying = ""


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func _hire_one_of_each_role() -> Array[String]:
	var ids: Array[String] = []
	var seen := {}
	for candidate: Dictionary in DataDB.staff:
		var role := str(candidate.get("role", ""))
		if seen.has(role):
			continue
		seen[role] = true
		if GameState.hire_staff(str(candidate.get("staff_id", ""))).is_empty() or true:
			if not GameState.hired_member(str(candidate.get("staff_id", ""))).is_empty():
				ids.append(str(candidate.get("staff_id", "")))
	return ids


func test_every_hired_person_has_an_assignment_card_in_every_style() -> void:
	var ids := _hire_one_of_each_role()
	assert_gt(ids.size(), 0, "someone was hired")
	# The first week gives no tasks (the ramp starts later), so move to week 3 and draw today's tasks now.
	GameState.calendar = {"week": 3, "phase": "work", "hours": 0}
	GameState.staff_day_key = -1
	GameState.staff_ensure_day()
	assert_gt(GameState.staff_day_pool.size(), 0, "there are tasks to give out")
	for style: String in STYLES:
		UiStyle.trying = style
		var office := _office()
		await get_tree().process_frame
		office._show_staff_assignments()
		var panel := office.get_node("AssignmentsPanel") as Overlay
		assert_true(panel.visible and panel.has_frame(), style + ": on the frame")
		for id: String in ids:
			assert_not_null(panel.find_child("StaffCard_" + id, true, false), "%s: a card for %s" % [style, id])
		var confirm := panel.find_child("ConfirmDayButton", true, false)
		assert_not_null(confirm, style + ": Confirm exists")
		assert_eq(confirm.get_parent().name, "FrameFooter", style + ": Confirm is fixed in the foot")
		office.queue_free()
		await get_tree().process_frame


func test_the_profile_is_cards_with_fire_last() -> void:
	var ids := _hire_one_of_each_role()
	var office := _office()
	await get_tree().process_frame
	office._show_staff_profile(ids[0])
	var panel := office.get_node("StaffProfilePanel") as Overlay
	assert_true(panel.has_frame())
	for name: String in ["StaffIdentityCard", "StaffLoyaltyCard", "StaffTiersCard", "StaffActionsCard"]:
		assert_not_null(panel.find_child(name, true, false), name + " is on the profile")
	var fire := panel.find_child("ProfileFireButton", true, false) as Button
	assert_not_null(fire)
	var column := fire.get_parent()
	assert_eq(column.get_child(column.get_child_count() - 1), fire, "Fire is the last button")


func test_a_held_coupon_is_named_on_the_rhetoric_tab() -> void:
	var coupon := ""
	for item: Dictionary in DataDB.shop:
		if item.get("free_card_tier") != null:
			coupon = str(item.get("item_id", ""))
	assert_false(coupon.is_empty(), "the data has a coupon")
	var office := _office()
	await get_tree().process_frame
	var panel := office.get_node("ManagementPanel") as Overlay
	# The run starts with some coupons (or none): the note is there exactly when one is held.
	GameState.inventory.erase(coupon)
	office._show_management_tab("rhetoric")
	assert_null(panel.find_child("CouponNote_" + coupon, true, false), "no note while none is held")
	GameState.add_item(coupon, 1)
	office._show_management_tab("rhetoric")
	assert_not_null(panel.find_child("CouponNote_" + coupon, true, false), "named once one is held")
