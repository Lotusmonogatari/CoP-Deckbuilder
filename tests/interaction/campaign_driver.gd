class_name CampaignDriver
extends Node
## Real clicks through the Campaign Office (P20 phase B, 2026-11-26): District office -> Step out -> Campaign Office -> Fundraising calls
## (hours, XP, fund and capital move; a result card) -> Outreach letters (pick an organization) -> the Staff tab (hire) -> Donate to your
## campaign under Step out. Then a week with a phase banner due: two pages, each shown once.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _go_to(phase: String) -> void:
	for week in range(1, 400):
		GameState.calendar = {"week": week, "phase": "work", "hours": 0}
		var info := GameState.election_phase()
		if str(info["phase"]) == phase and bool(info["player_runs"]):
			return


func _run() -> void:
	DataDB.balance["overheard_every"] = 0
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT
	GameState.dated_events_done = ["EV47"]
	GameState.open_venue("VN10")
	GameState.campaign_howto_seen = true
	GameState.xp = 1000
	GameState.meta["Funds"] = 200000
	GameState.campaign_capital = 400
	GameState.campaign_fund = 900000
	# A mustering week, so the banner pages are not due yet (they were shown).
	_go_to("mustering")
	GameState.campaign_banners_shown = ["%s:announcement" % GameState.election_phase()["cycle_id"]]
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	await _open_office()
	var office := get_tree().current_scene
	var donate := office.find_child("DonateButton", true, false) as Button
	_expect(donate != null and donate.visible, "Donate to your campaign shows at the District office once the Campaign Office is open")
	await _click(office.find_child("StepOutButton", true, false))
	var map := office.get_node("VenueMapPanel") as Overlay
	var go := map.find_child("Venue_VN10", true, false) as Button
	_expect(go != null and not go.disabled, "the Campaign Office is on the District map and open")
	await _press(go)
	var venue := office.get_node("VenuePanel") as Overlay
	_expect(venue.find_child("CampaignStatusCard", true, false) != null, "the Campaign Office opens with its status card")
	_expect(venue.find_child("ActionsTab", true, false) != null and venue.find_child("StaffTab", true, false) != null and venue.find_child("VanTab", true, false) != null,
		"three tabs: Actions, Staff, Van")
	var hours := GameState.work_hours_left()
	await _press(venue.find_child("Do_campaign_fundraise", true, false))
	var result := office.get_node("CampaignResultPanel") as Overlay
	_expect(result.visible, "a result card tells what the action did")
	_expect(GameState.work_hours_left() == hours - 4 and GameState.xp == 900 and GameState.campaign_capital == 500,
		"four hours and 100 XP spent; the XP became campaign capital")
	_expect(GameState.campaign_fund == 900000 + 60000, "Mustering pays half again: the fund gained 60,000円")
	await _click(result.find_child("Back", true, false))
	venue = office.get_node("VenuePanel") as Overlay
	await _press(venue.find_child("Do_campaign_letters", true, false))
	var pick := venue.find_child("LettersTo_BO18", true, false) as Button
	_expect(pick != null, "letters ask which organization")
	var before := int(GameState.booster_standing.get("BO18", 0))
	await _press(pick)
	_expect(int(GameState.booster_standing.get("BO18", 0)) > before, "the chosen organization's standing rose")
	_expect(GameState.campaign_actions_week == 2, "two actions this week")
	await _click((office.get_node("CampaignResultPanel") as Overlay).find_child("Back", true, false))
	venue = office.get_node("VenuePanel") as Overlay
	var third := venue.find_child("Do_campaign_mailings", true, false) as Button
	_expect(third != null and third.disabled, "a third action is greyed: the weekly limit")
	await _click(venue.find_child("StaffTab", true, false))
	var hire := venue.find_child("Hire_CS01", true, false) as Button
	_expect(hire != null and not hire.disabled, "Hire is available")
	await _press(hire)
	_expect(not GameState.campaign_member("CS01").is_empty() and GameState.campaign_capital == 410, "the organizer is hired for 150 capital (400 + 100 + 60 - 150)")
	await _click(venue.find_child("Back", true, false))
	await _click(map.find_child("Back", true, false))
	var funds := int(GameState.meta["Funds"])
	await _click(office.find_child("DonateButton", true, false))
	var card := office.get_node("CampaignDonatePanel") as Overlay
	await _click(card.find_child("Donate_10000", true, false))
	_expect(int(GameState.meta["Funds"]) == funds - 10000, "Funds left by the donated amount")
	await _click(card.find_child("Back", true, false))
	# A banner week: the announcement's two pages, shown once.
	_go_to("announcement")
	GameState.campaign_banners_shown = []
	await _open_office()
	office = get_tree().current_scene
	var banner := office.get_node("CampaignBannerPanel") as Overlay
	_expect(banner.visible, "the announcement banner shows when the Office opens that week")
	await _click(banner.find_child("Confirm", true, false))
	_expect(banner.visible, "a second page follows: Mustering the War Campaign")
	await _click(banner.find_child("Confirm", true, false))
	_expect(not banner.visible and not GameState.campaign_banners_shown.is_empty(), "the banner is shown once and remembered")
	_finish()


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


## Presses a button that may sit below the fold of a scrolling screen (a tap there needs a scroll first, which other tests cover).
func _press(control: Variant) -> void:
	if not (control is Button):
		_failures.append("a button this test needed does not exist")
		return
	(control as Button).pressed.emit()
	await get_tree().create_timer(0.4).timeout


func _click(control: Variant) -> void:
	if not (control is Control):
		_failures.append("a control this test needed does not exist")
		return
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * (control as Control).get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)


func _finish() -> void:
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("CAMPAIGN TEST: PASS")
		get_tree().quit(0)
	else:
		print("CAMPAIGN TEST: FAIL")
		for failure: String in _failures:
			print("  X " + failure)
		get_tree().quit(1)
